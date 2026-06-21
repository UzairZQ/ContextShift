import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

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

  bool _initialized = false;
  bool _modelLoaded = false;
  ModelTier? _activeModelTier;
  ModelDefinition? _activeModelDef;
  InferenceModel? _model;
  InferenceChat? _chat;

  bool get isInitialized => _initialized;
  bool get isModelLoaded => _modelLoaded;
  ModelTier? get activeModelTier => _activeModelTier;
  ModelDefinition? get activeModelDef => _activeModelDef;

  Future<void> init() async {
    if (_initialized) {
      debugPrint('[GemmaService] Already initialized, skipping');
      return;
    }

    debugPrint('[GemmaService] Initializing FlutterGemma...');
    try {
      await FlutterGemma.initialize();
      _initialized = true;
      debugPrint('[GemmaService] FlutterGemma initialized successfully');
    } catch (e, stack) {
      debugPrint('[GemmaService] FlutterGemma init failed: $e');
      debugPrint('[GemmaService]   Stack: $stack');
      _initialized = false;
      rethrow;
    }
  }

  Future<void> loadModel(ModelDefinition model) async {
    debugPrint('[GemmaService] Loading model: ${model.displayName}');
    debugPrint('[GemmaService]   Model ID: ${model.modelId}');
    debugPrint('[GemmaService]   Type: ${model.modelType}');
    debugPrint('[GemmaService]   Max tokens: ${model.maxTokens}');

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
        'backend=gpu, model=${model.modelId}, maxTokens=${model.maxTokens}',
      );
      _model = await FlutterGemma.getActiveModel(
        maxTokens: model.maxTokens,
        preferredBackend: PreferredBackend.gpu,
      );
      debugPrint('[GemmaService] Native getActiveModel complete');

      debugPrint('[GemmaService] Creating chat session...');
      _chat = InferenceChat(
        sessionCreator: () => _model!.createSession(),
        maxTokens: model.maxTokens,
        tokenBuffer: 500,
        modelType: model.modelType,
      );

      debugPrint('[GemmaService] Initializing chat session...');
      await _chat!.initSession();
      debugPrint('[GemmaService] Chat session initialized');

      _activeModelTier = model.tier;
      _activeModelDef = model;
      _modelLoaded = true;

      debugPrint(
        '[GemmaService] Model loaded successfully: ${model.displayName}',
      );
    } catch (e, stack) {
      debugPrint('[GemmaService] Failed to load model: $e');
      debugPrint('[GemmaService]   Stack: $stack');
      _modelLoaded = false;

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

  Future<void> _activateInstalledModel(ModelDefinition model) async {
    if (FlutterGemma.hasActiveModel()) {
      debugPrint('[GemmaService] FlutterGemma already has an active model');
      return;
    }

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
    Duration timeout = const Duration(seconds: 15),
  }) async {
    debugPrint('[GemmaService] Generate called');
    debugPrint(
      '[GemmaService]   Prompt: "${prompt.length > 100 ? '${prompt.substring(0, 100)}...' : prompt}"',
    );
    debugPrint('[GemmaService]   Max tokens: $maxTokens');
    debugPrint('[GemmaService]   Temperature: $temperature');

    if (!_modelLoaded || _chat == null) {
      throw GemmaException(
        code: GemmaErrorCode.modelNotLoaded,
        message: 'No model loaded. Call loadModel() first.',
      );
    }

    try {
      final message = Message(text: prompt, isUser: true);
      await _chat!.addQuery(message);

      final response = await _chat!.generateChatResponse().timeout(timeout);

      if (response is TextResponse) {
        final result = response.token;
        debugPrint(
          '[GemmaService] Generated response (${result.length} chars)',
        );
        return result;
      }

      debugPrint(
        '[GemmaService] Unexpected response type: ${response.runtimeType}',
      );
      return '';
    } on TimeoutException {
      debugPrint('[GemmaService] Generation timed out after $timeout');
      throw GemmaException(
        code: GemmaErrorCode.inferenceTimeout,
        message: 'Model took too long to respond (>${timeout.inSeconds}s)',
      );
    } catch (e, stack) {
      debugPrint('[GemmaService] Generation error: $e');
      debugPrint('[GemmaService]   Stack: $stack');

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
    return trimmed;
  }

  Stream<String> generateStream(
    String prompt, {
    int maxTokens = 512,
    double temperature = 0.1,
  }) async* {
    debugPrint('[GemmaService] Generate stream called');

    if (!_modelLoaded || _chat == null) {
      throw GemmaException(
        code: GemmaErrorCode.modelNotLoaded,
        message: 'No model loaded. Call loadModel() first.',
      );
    }

    try {
      final message = Message(text: prompt, isUser: true);
      await _chat!.addQuery(message);

      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is TextResponse) {
          yield response.token;
        }
      }
    } catch (e, stack) {
      debugPrint('[GemmaService] Stream generation error: $e');
      debugPrint('[GemmaService]   Stack: $stack');
      rethrow;
    }
  }

  Future<void> disposeModel() async {
    debugPrint('[GemmaService] Disposing model...');
    try {
      await _chat?.close();
      _chat = null;
      _model = null;
      _modelLoaded = false;
      _activeModelTier = null;
      _activeModelDef = null;
      debugPrint('[GemmaService] Model disposed');
    } catch (e, stack) {
      debugPrint('[GemmaService] Error disposing model: $e');
      debugPrint('[GemmaService]   Stack: $stack');
    }
  }

  Future<void> dispose() async {
    debugPrint('[GemmaService] Full dispose...');
    await disposeModel();
    _initialized = false;
    debugPrint('[GemmaService] Full dispose complete');
  }

  Future<void> clearChat() async {
    if (_chat != null) {
      debugPrint('[GemmaService] Clearing chat history');
      try {
        await _chat!.clearHistory();
        await _chat!.initSession();
      } catch (e, stack) {
        debugPrint('[GemmaService] Error clearing chat: $e');
        debugPrint('[GemmaService]   Stack: $stack');
      }
    }
  }
}
