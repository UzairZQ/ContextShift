import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';

import '../services/feature_manager.dart';
import 'model_tier.dart';

enum GemmaErrorCode {
  modelNotLoaded,
  modelNotInstalled,
  inferenceTimeout,
  oomError,
  platformNotSupported,
  unknown,
}

class GemmaException implements Exception {
  final GemmaErrorCode code;
  final String message;
  final String? detail;

  const GemmaException({
    required this.code,
    required this.message,
    this.detail,
  });

  @override
  String toString() =>
      'GemmaException[$code]: $message${detail != null ? '\n  Detail: $detail' : ''}';
}

class GemmaService {
  GemmaService._();
  static final GemmaService instance = GemmaService._();

  // Keep generation policy in one place so chat, cards, and actions do not
  // accidentally use conflicting sampler settings.
  static const int naturalChatOutputTokens = 1536;
  static const int actionOutputTokens = 768;
  static const int structuredOutputTokens = 640;
  static const double naturalTemperature = 0.85;
  static const int naturalTopK = 40;
  static const double naturalTopP = 0.95;
  static const double structuredTemperature = 0.15;
  static const int structuredTopK = 8;
  static const double structuredTopP = 0.9;

  bool _initialized = false;
  Future<void>? _initFuture;
  Future<void>? _loadFuture;
  bool _modelLoaded = false;
  ModelTier? _activeModelTier;
  ModelDefinition? _activeModelDef;
  InferenceModel? _model;
  Future<void> _inferenceGate = Future<void>.value();
  final ValueNotifier<int> statusRevision = ValueNotifier<int>(0);

  bool get isModelLoaded => _modelLoaded;
  bool get isModelLoading => _loadFuture != null;
  ModelTier? get activeModelTier => _activeModelTier;
  ModelDefinition? get activeModelDef => _activeModelDef;

  Future<void> init() {
    if (_initialized) {
      debugPrint('[GemmaService] Already initialized, skipping');
      return Future<void>.value();
    }

    return _initFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    debugPrint('[GemmaService] Initializing FlutterGemma...');
    try {
      await FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()]);
      _initialized = true;
      debugPrint('[GemmaService] FlutterGemma initialized successfully');
    } catch (e, stack) {
      debugPrint('[GemmaService] FlutterGemma init failed: $e');
      debugPrint('[GemmaService]   Stack: $stack');
      _initialized = false;
      _initFuture = null;
      rethrow;
    }
  }

  Future<void> loadModel(ModelDefinition model) {
    final activeLoad = _loadFuture;
    if (activeLoad != null) return activeLoad;

    late final Future<void> trackedLoad;
    trackedLoad = _loadModel(model).whenComplete(() {
      if (identical(_loadFuture, trackedLoad)) {
        _loadFuture = null;
        _notifyStatusChanged();
      }
    });
    _loadFuture = trackedLoad;
    _notifyStatusChanged();
    return trackedLoad;
  }

  Future<void> _loadModel(ModelDefinition model) async {
    debugPrint('[GemmaService] Loading model: ${model.displayName}');
    debugPrint('[GemmaService]   Model ID: ${model.modelId}');
    debugPrint('[GemmaService]   Type: ${model.modelType}');
    debugPrint('[GemmaService]   Context tokens: ${model.contextTokens}');

    if (!_initialized) {
      debugPrint('[GemmaService] Not initialized, initializing first...');
      await init();
    }

    if (_modelLoaded && _activeModelTier == model.tier) {
      debugPrint(
        '[GemmaService] Model already loaded: ${model.displayName}, skipping',
      );
      return;
    }

    if (_modelLoaded) {
      debugPrint('[GemmaService] Switching models, disposing current...');
      await disposeModel();
    }

    try {
      final isInstalled = await FlutterGemma.isModelInstalled(model.modelId);
      if (!isInstalled) {
        throw GemmaException(
          code: GemmaErrorCode.modelNotInstalled,
          message:
              'Model ${model.displayName} is not installed. Download it first.',
          detail: 'Model ID: ${model.modelId}',
        );
      }

      await _activateInstalledModel(model);

      debugPrint('[GemmaService] Creating inference model...');
      debugPrint(
        '[GemmaService] Native getActiveModel start: '
        'backend=gpu, model=${model.modelId}, '
        'contextTokens=${model.contextTokens}',
      );
      _model = await FlutterGemma.getActiveModel(
        maxTokens: model.contextTokens,
        preferredBackend: PreferredBackend.gpu,
      );
      debugPrint('[GemmaService] Native getActiveModel complete');

      _activeModelTier = model.tier;
      _activeModelDef = model;
      _modelLoaded = true;
      _notifyStatusChanged();

      debugPrint(
        '[GemmaService] Model loaded successfully: ${model.displayName}',
      );
    } catch (e, stack) {
      debugPrint('[GemmaService] Failed to load model: $e');
      debugPrint('[GemmaService]   Stack: $stack');
      _modelLoaded = false;
      _notifyStatusChanged();

      if (e is GemmaException) rethrow;

      final errMsg = e.toString().toLowerCase();
      if (errMsg.contains('oom') || errMsg.contains('out of memory')) {
        throw GemmaException(
          code: GemmaErrorCode.oomError,
          message:
              'Model ${model.displayName} requires ${model.minRamFormatted} RAM. '
              'Your device may not have enough memory.',
          detail: e.toString(),
        );
      }

      throw GemmaException(
        code: GemmaErrorCode.unknown,
        message: 'Failed to load model ${model.displayName}',
        detail: e.toString(),
      );
    }
  }

  Future<void> loadBestAvailableModel({
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (isModelLoaded) return;

    // Model availability is restored through FlutterGemma, so make an
    // immediate user action safe even if it arrives before the post-frame
    // warm-up has completed.
    if (!_initialized) await init();
    await FeatureManager.instance.initialize();

    final model = FeatureManager.instance.resolveBestModelDef();
    if (model == null) {
      throw const GemmaException(
        code: GemmaErrorCode.modelNotInstalled,
        message: 'No local JARVIS model is marked as downloaded.',
      );
    }

    await loadModel(model).timeout(timeout);
  }

  Future<void> _activateInstalledModel(ModelDefinition model) async {
    debugPrint(
      '[GemmaService] Activating installed model metadata: ${model.modelId}',
    );
    await FlutterGemma.installModel(
      modelType: model.modelType,
      fileType: model.fileType,
    ).fromNetwork(model.downloadUrl, foreground: false).install();
    debugPrint('[GemmaService] Installed model metadata activated');
  }

  Future<String> generate(
    String prompt, {
    int maxTokens = 512,
    double temperature = 0.1,
    int topK = 1,
    double? topP,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final requestId = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    debugPrint('[GemmaService][$requestId] Generate called');
    if (kDebugMode) {
      debugPrint(
        '[GemmaService][$requestId]   Prompt: "${prompt.length > 220 ? '${prompt.substring(0, 220)}...' : prompt}"',
      );
    }
    debugPrint('[GemmaService][$requestId]   Max output tokens: $maxTokens');
    debugPrint('[GemmaService][$requestId]   Temperature: $temperature');
    debugPrint('[GemmaService][$requestId]   TopK: $topK');
    debugPrint(
      '[GemmaService][$requestId]   Active model: ${_activeModelDef?.modelId}, '
      'tier=$_activeModelTier, loaded=$_modelLoaded',
    );

    final model = _model;
    if (!_modelLoaded || model == null) {
      throw GemmaException(
        code: GemmaErrorCode.modelNotLoaded,
        message: 'No model loaded. Call loadModel() first.',
      );
    }

    final releaseSlot = await _acquireInferenceSlot(requestId);
    InferenceModelSession? session;
    try {
      _throwIfModelChanged(model, requestId);
      debugPrint('[GemmaService][$requestId] Opening one-shot session...');
      session = await model.openSession(
        temperature: temperature,
        topK: topK,
        topP: topP,
        maxOutputTokens: maxTokens,
      );
      debugPrint(
        '[GemmaService][$requestId] Session opened; sending prompt...',
      );
      await session.addQueryChunk(Message(text: prompt, isUser: true));
      debugPrint(
        '[GemmaService][$requestId] Waiting for native response '
        '(timeout=${timeout.inSeconds}s)...',
      );
      final result = await session.getResponse().timeout(timeout);
      debugPrint(
        '[GemmaService][$requestId] Generated response (${result.length} chars)',
      );
      if (kDebugMode) {
        debugPrint(
          '[GemmaService][$requestId] Response preview: '
          '${result.length > 1200 ? '${result.substring(0, 1200)}...' : result}',
        );
      }
      return result;
    } on TimeoutException {
      debugPrint(
        '[GemmaService][$requestId] Generation timed out after $timeout',
      );
      await session?.stopGeneration();
      throw GemmaException(
        code: GemmaErrorCode.inferenceTimeout,
        message: 'Model took too long to respond (>${timeout.inSeconds}s)',
      );
    } catch (e, stack) {
      debugPrint('[GemmaService][$requestId] Generation error: $e');
      debugPrint('[GemmaService][$requestId]   Stack: $stack');

      final errMsg = e.toString().toLowerCase();
      if (errMsg.contains('oom') || errMsg.contains('out of memory')) {
        throw GemmaException(
          code: GemmaErrorCode.oomError,
          message:
              'Out of memory during inference. Try a shorter prompt or restart the app.',
          detail: e.toString(),
        );
      }

      rethrow;
    } finally {
      try {
        await session?.close();
        debugPrint('[GemmaService][$requestId] Session closed');
      } catch (closeError, closeStack) {
        debugPrint(
          '[GemmaService][$requestId] Session close failed: $closeError',
        );
        debugPrintStack(stackTrace: closeStack);
      }
      releaseSlot();
    }
  }

  Future<String> runHealthCheck(ModelDefinition model) async {
    debugPrint('[GemmaService] Running health check for ${model.modelId}');
    await loadModel(model);
    final response = await generate(
      'Health check. Reply with exactly: OK',
      maxTokens: 32,
      temperature: 0,
      timeout: const Duration(seconds: 20),
    );
    final trimmed = response.trim();
    if (trimmed.isEmpty) {
      throw const GemmaException(
        code: GemmaErrorCode.unknown,
        message: 'Health check returned an empty response.',
      );
    }
    debugPrint('[GemmaService] Health check response: $trimmed');
    await clearChat();
    return trimmed;
  }

  Stream<String> generateStream(
    String prompt, {
    int maxTokens = 512,
    double temperature = 0.1,
    int topK = 1,
    double? topP,
    Duration timeout = const Duration(seconds: 45),
  }) async* {
    final requestId = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    debugPrint('[GemmaService][$requestId] Generate stream called');
    debugPrint('[GemmaService][$requestId]   Max output tokens: $maxTokens');

    final model = _model;
    if (!_modelLoaded || model == null) {
      throw GemmaException(
        code: GemmaErrorCode.modelNotLoaded,
        message: 'No model loaded. Call loadModel() first.',
      );
    }

    final releaseSlot = await _acquireInferenceSlot(requestId);
    InferenceModelSession? session;
    try {
      _throwIfModelChanged(model, requestId);
      session = await model.openSession(
        temperature: temperature,
        topK: topK,
        topP: topP,
        maxOutputTokens: maxTokens,
      );
      await session.addQueryChunk(Message(text: prompt, isUser: true));

      await for (final token in session.getResponseAsync().timeout(timeout)) {
        yield token;
      }
    } on TimeoutException {
      debugPrint(
        '[GemmaService][$requestId] Stream generation timed out after $timeout',
      );
      await session?.stopGeneration();
      throw GemmaException(
        code: GemmaErrorCode.inferenceTimeout,
        message: 'Model stream timed out (>${timeout.inSeconds}s)',
      );
    } catch (e, stack) {
      debugPrint('[GemmaService][$requestId] Stream generation error: $e');
      debugPrint('[GemmaService][$requestId]   Stack: $stack');
      final errMsg = e.toString().toLowerCase();
      if (errMsg.contains('oom') || errMsg.contains('out of memory')) {
        throw GemmaException(
          code: GemmaErrorCode.oomError,
          message:
              'Out of memory during streamed inference. Try a shorter prompt or restart the app.',
          detail: e.toString(),
        );
      }
      rethrow;
    } finally {
      try {
        await session?.close();
        debugPrint('[GemmaService][$requestId] Stream session closed');
      } catch (closeError, closeStack) {
        debugPrint(
          '[GemmaService][$requestId] Stream session close failed: $closeError',
        );
        debugPrintStack(stackTrace: closeStack);
      }
      releaseSlot();
    }
  }

  Future<void Function()> _acquireInferenceSlot(String requestId) async {
    final previous = _inferenceGate;
    final release = Completer<void>();
    _inferenceGate = previous.catchError((_) {}).then((_) => release.future);
    debugPrint('[GemmaService][$requestId] Waiting for inference slot...');
    await previous.catchError((_) {});
    debugPrint('[GemmaService][$requestId] Inference slot acquired');
    return () {
      if (!release.isCompleted) {
        release.complete();
        debugPrint('[GemmaService][$requestId] Inference slot released');
      }
    };
  }

  void _throwIfModelChanged(InferenceModel model, String requestId) {
    if (_modelLoaded && identical(_model, model)) return;
    debugPrint(
      '[GemmaService][$requestId] Model changed while waiting for inference; '
      'aborting stale request',
    );
    throw const GemmaException(
      code: GemmaErrorCode.modelNotLoaded,
      message: 'The local JARVIS model changed before inference started.',
    );
  }

  Future<void> disposeModel() async {
    debugPrint('[GemmaService] Disposing model...');
    final previousModel = _model;
    _model = null;
    _modelLoaded = false;
    _activeModelTier = null;
    _activeModelDef = null;
    _notifyStatusChanged();

    try {
      // Wait for current and already-queued sessions before releasing native
      // model memory. New requests see the unloaded state immediately.
      await _inferenceGate.catchError((_) {});
      await previousModel?.close();
      debugPrint('[GemmaService] Model disposed');
    } catch (e, stack) {
      debugPrint('[GemmaService] Error disposing model: $e');
      debugPrint('[GemmaService]   Stack: $stack');
    }
  }

  void _notifyStatusChanged() {
    statusRevision.value += 1;
  }

  Future<void> dispose() async {
    debugPrint('[GemmaService] Full dispose...');
    await disposeModel();
    _initialized = false;
    _initFuture = null;
    debugPrint('[GemmaService] Full dispose complete');
  }

  Future<void> clearChat() async {
    // Generation uses one-shot sessions, so there is no persistent native
    // history to clear. Keep this API for callers that reset a conversation.
    debugPrint('[GemmaService] No persistent chat history to clear');
  }
}
