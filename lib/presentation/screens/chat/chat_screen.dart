import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/ai_service.dart';
import '../../../core/ai/action_executor.dart';
import '../../../core/ai/context_provider.dart';
import '../../../core/ai/generated_ui_action_mapper.dart';
import '../../../core/ai/jarvis_memory_service.dart';
import '../../../core/app_spacing.dart';
import '../../../core/app_runtime.dart';
import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/schema.dart';
import '../../../core/genui/action_bus.dart';
import '../../../core/genui/genui_runtime.dart';
import '../../../core/genui/widget_node.dart';
import '../../../core/local_llm/gemma_service.dart';
import '../../../core/responsive.dart';
import '../../widgets/genui/a2ui_surface_card.dart';
import '../../widgets/genui/schedule_card_editor.dart';
import '../../widgets/motion/wonderous_motion.dart';

part 'widgets/chat_widgets.dart';

enum _JarvisChatMode { chat, generate }

enum _JarvisBusyStage { idle, loadingModel, generatingSurface, thinking }

class ChatScreen extends StatefulWidget {
  final String? initialMessage;
  final int? conversationId;
  final bool startNewOnOpen;
  final bool initialGenerateMode;
  final bool initialMessageDraftOnly;

  const ChatScreen({
    super.key,
    this.initialMessage,
    this.conversationId,
    this.startNewOnOpen = false,
    this.initialGenerateMode = false,
    this.initialMessageDraftOnly = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _messageController = TextEditingController();
  final _conversationSearchController = TextEditingController();
  final _scrollController = ScrollController();
  final _speech = stt.SpeechToText();
  JarvisGenUiRuntime? _genUiRuntime;
  bool _isProcessing = false;
  _JarvisBusyStage _busyStage = _JarvisBusyStage.idle;
  bool _speechReady = false;
  bool _isListening = false;
  String _dictationBaseText = '';
  String _conversationQuery = '';
  _JarvisChatMode _mode = _JarvisChatMode.chat;
  late final bool _forceComposer;
  bool _loggedFirstBuild = false;
  bool _forceNextMessageAutoScroll = false;

  int? _activeConversationId;
  List<ConversationTableData> _conversations = [];
  List<MessageTableData> _messages = [];
  StreamSubscription? _messagesSub;
  StreamSubscription<WidgetAction>? _genUiActionSub;

  @override
  void initState() {
    super.initState();
    if (widget.initialGenerateMode) {
      _mode = _JarvisChatMode.generate;
    }
    debugPrint(
      '[ChatScreen] initState start. '
      'initialMessage=${widget.initialMessage?.trim().isNotEmpty == true}, '
      'conversationId=${widget.conversationId}, '
      'startNewOnOpen=${widget.startNewOnOpen}',
    );
    _forceComposer = widget.startNewOnOpen;
    _activeConversationId = widget.conversationId;
    _conversationSearchController.addListener(() {
      setState(() {
        _conversationQuery = _conversationSearchController.text.trim();
      });
    });
    _genUiActionSub = GenUiActionBus.instance.actions.listen(
      _handleGenUiAction,
    );
    _loadConversations().then((_) {
      debugPrint('[ChatScreen] Initial conversation load complete');
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        if (widget.initialMessageDraftOnly) {
          debugPrint('[ChatScreen] Drafting initial message after load');
          _setComposerText(widget.initialMessage!);
        } else {
          debugPrint('[ChatScreen] Sending initial message after load');
          _sendMessage(widget.initialMessage!);
        }
      }
    });
  }

  @override
  void dispose() {
    if (_speechReady) {
      _speech.stop();
    }
    _conversationSearchController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSub?.cancel();
    _genUiActionSub?.cancel();
    _genUiRuntime?.dispose();
    super.dispose();
  }

  JarvisGenUiRuntime get _genUiRuntimeInstance {
    return _genUiRuntime ??= JarvisGenUiRuntime();
  }

  Future<void> _handleGenUiAction(WidgetAction action) async {
    if (action.action == 'save_card') {
      await _saveGeneratedCard(action);
      return;
    }
    if (action.action == 'edit_schedule_times') {
      await _editScheduleTimes(action);
      return;
    }

    final aiAction = GeneratedUiActionMapper.toAiAction(action);
    if (aiAction == null) {
      final message =
          GeneratedUiActionMapper.continuationMessage(action) ??
          'The generated UI action was "${action.action}" with '
              'context ${jsonEncode(action.params)}.';
      if (action.action == 'continue_conversation' && mounted) {
        setState(() => _mode = _JarvisChatMode.generate);
        final editedMessage = await _showRefineSheet(message);
        if (editedMessage == null || editedMessage.trim().isEmpty) return;
        _setComposerText(editedMessage);
        _showMessage('Refine prompt is ready to edit');
        return;
      }
      await _sendMessage(message);
      return;
    }
    await ActionExecutor.instance.executeAll([aiAction]);
    if (!mounted) return;
    _showMessage('Done');
  }

  Future<void> _saveGeneratedCard(WidgetAction action) async {
    final rawA2ui = _textParam(action, 'rawA2ui');
    if (rawA2ui == null) {
      _showMessage('This card could not be saved.');
      return;
    }
    await DatabaseService.instance.saveGeneratedCard(
      title: _textParam(action, 'title') ?? 'Generated card',
      domain: _textParam(action, 'domain') ?? 'card',
      rawA2ui: rawA2ui,
      source: _textParam(action, 'source'),
      fallbackReason: _textParam(action, 'fallbackReason'),
      elapsedMs: _intParam(action, 'elapsedMs'),
    );
    if (!mounted) return;
    _showMessage('Saved to Home');
  }

  Future<void> _editScheduleTimes(WidgetAction action) async {
    final rawA2ui = _textParam(action, 'rawA2ui');
    if (rawA2ui == null || _activeConversationId == null) {
      _showMessage('This schedule could not be edited.');
      return;
    }
    final updatedRaw = await ScheduleCardEditor.editTimes(
      context: context,
      rawA2ui: rawA2ui,
    );
    if (updatedRaw == null || !mounted) return;
    await DatabaseService.instance.addMessage(
      conversationId: _activeConversationId!,
      role: 'assistant',
      content: 'I updated the schedule card locally.',
      widgetJson: jsonEncode({
        'format': 'a2ui-v0.9',
        'raw': updatedRaw,
        'source': _textParam(action, 'source') ?? 'gemma',
        'fallbackReason': _textParam(action, 'fallbackReason'),
        'elapsedMs': _intParam(action, 'elapsedMs'),
      }),
    );
    if (!mounted) return;
    _showMessage('Schedule updated');
  }

  String? _textParam(WidgetAction action, String key) {
    final value = action.params[key];
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  int? _intParam(WidgetAction action, String key) {
    final value = action.params[key];
    return value is num ? value.round() : null;
  }

  void _setComposerText(String text) {
    final trimmed = text.trim();
    _messageController.value = TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
  }

  Future<String?> _showRefineSheet(String basePrompt) {
    final extraController = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: Spacing.lg,
              right: Spacing.lg,
              top: Spacing.lg,
              bottom:
                  MediaQuery.of(sheetContext).viewInsets.bottom + Spacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refine card',
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  'Add anything JARVIS should consider before rebuilding it.',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                TextField(
                  controller: extraController,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 6,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: InputDecoration(
                    hintText:
                        'Example: make it simpler, add budget, use evening times...',
                    hintStyle: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.onSurfaceVariant.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.onSurfaceVariant.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final extra = extraController.text.trim();
                          final prompt = extra.isEmpty
                              ? basePrompt
                              : '$basePrompt\n\nExtra refinement context from the user:\n$extra';
                          Navigator.of(sheetContext).pop(prompt);
                        },
                        child: const Text('Add to composer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(extraController.dispose);
  }

  Future<void> _loadConversations() async {
    try {
      debugPrint('[ChatScreen] Loading conversations...');
      final convs = await DatabaseService.instance.getAllConversations();
      debugPrint('[ChatScreen] Loaded ${convs.length} conversations');
      if (!mounted) return;
      setState(() => _conversations = convs);

      final isNewPrompt = widget.initialMessage?.trim().isNotEmpty ?? false;
      if (!isNewPrompt &&
          !_forceComposer &&
          _activeConversationId == null &&
          convs.isNotEmpty) {
        _activeConversationId = convs.first.id;
        _watchMessages();
      }
    } catch (error, stackTrace) {
      debugPrint('[ChatScreen] Failed to load conversations: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      _showMessage('Your conversations could not be loaded.');
    }
  }

  void _watchMessages() {
    _messagesSub?.cancel();
    if (_activeConversationId == null) return;
    debugPrint('[ChatScreen] Watching messages for $_activeConversationId');
    _messagesSub = DatabaseService.instance
        .watchMessages(_activeConversationId!)
        .listen(
          (msgs) {
            if (!mounted) return;
            debugPrint(
              '[ChatScreen] Message stream update: ${msgs.length} messages',
            );
            final shouldAutoScroll =
                _forceNextMessageAutoScroll || _isNearMessageListBottom();
            _forceNextMessageAutoScroll = false;
            setState(() => _messages = msgs);
            if (shouldAutoScroll) {
              _scrollToBottom();
            }
          },
          onError: (error, stackTrace) {
            debugPrint('[ChatScreen] Message stream failed: $error');
            debugPrintStack(stackTrace: stackTrace);
          },
        );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isNearMessageListBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return position.maxScrollExtent - position.pixels <= 160;
  }

  Future<void> _selectConversation(int id) async {
    setState(() => _activeConversationId = id);
    _watchMessages();
  }

  Future<void> _startNewConversation() async {
    try {
      final conv = await DatabaseService.instance.createConversation(
        title: 'New Chat',
      );
      if (!mounted) return;
      setState(() {
        _conversations.insert(0, conv);
        _activeConversationId = conv.id;
        _messages = [];
      });
      _watchMessages();
    } catch (error, stackTrace) {
      debugPrint('[ChatScreen] Failed to create conversation: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) _showMessage('A new conversation could not be created.');
      rethrow;
    }
  }

  Future<void> _deleteConversation(int id) async {
    await DatabaseService.instance.deleteConversation(id);
    if (!mounted) return;
    setState(() {
      _conversations.removeWhere((c) => c.id == id);
      if (_activeConversationId == id) {
        _activeConversationId = _conversations.isNotEmpty
            ? _conversations.first.id
            : null;
        if (_activeConversationId != null) {
          _watchMessages();
        } else {
          _messages = [];
          _messagesSub?.cancel();
        }
      }
    });
  }

  Future<void> _sendMessage(String? text) async {
    final message = text ?? _messageController.text.trim();
    if (message.isEmpty) return;
    if (_isListening) {
      await _stopDictation();
    }
    _dictationBaseText = '';
    _messageController.clear();

    if (_activeConversationId == null) {
      await _startNewConversation();
    }

    if (!mounted || _activeConversationId == null) return;

    setState(() {
      _isProcessing = true;
      _busyStage = GemmaService.instance.isModelLoaded
          ? _nextBusyStage()
          : _JarvisBusyStage.loadingModel;
    });
    _forceNextMessageAutoScroll = true;

    try {
      debugPrint(
        '[ChatScreen] Send pressed. build=$appRuntimeBuild '
        'conversation=$_activeConversationId, message="$message"',
      );
      await DatabaseService.instance.addMessage(
        conversationId: _activeConversationId!,
        role: 'user',
        content: message,
      );

      String response;
      String? widgetJson;
      var turnMode = _mode == _JarvisChatMode.generate ? 'generate' : 'chat';
      String? generatedCardType;

      if (_mode == _JarvisChatMode.chat && _looksLikeDirectAction(message)) {
        turnMode = 'action';
        final result = await AiService.instance.processCommand(
          command: message,
          userName: DatabaseService.instance.firstName,
          conversationId: _activeConversationId,
        );
        await ActionExecutor.instance.executeAll(result.actions);
        response = result.response;
        debugPrint('[ChatScreen] Direct command response: $response');
        widgetJson = null;
      } else if (_mode == _JarvisChatMode.generate) {
        await _ensureJarvisReadyForChat(message);
        if (mounted) {
          setState(() => _busyStage = _JarvisBusyStage.generatingSurface);
        }
        final generation = await _genUiRuntimeInstance.generate(
          userMessage: message,
          conversationId: _activeConversationId,
          timeout: const Duration(seconds: 38),
        );
        response = generation.text.isEmpty
            ? 'I shaped that into an interactive view.'
            : generation.text;
        debugPrint(
          '[ChatScreen] GenUI JARVIS response: $response '
          'surfaces=${generation.surfaceIds}',
        );
        widgetJson =
            generation.surfaceIds.isEmpty || generation.rawA2ui.trim().isEmpty
            ? null
            : jsonEncode(generation.toPersistenceJson());
        generatedCardType = _detectGeneratedCardType(message);
      } else {
        final localReply = _localJarvisCapabilityReply(message);
        if (localReply != null) {
          response = localReply;
          widgetJson = null;
        } else {
          await _ensureJarvisReadyForChat(message);
          if (mounted) setState(() => _busyStage = _JarvisBusyStage.thinking);
          response = await _generatePlainJarvisReply(message);
          debugPrint('[ChatScreen] Plain JARVIS response: $response');
          widgetJson = null;
        }
      }

      await DatabaseService.instance.addMessage(
        conversationId: _activeConversationId!,
        role: 'assistant',
        content: response,
        widgetJson: widgetJson,
      );
      await JarvisMemoryService.instance.recordTurn(
        conversationId: _activeConversationId!,
        userMessage: message,
        assistantResponse: response,
        mode: turnMode,
        generatedCardType: generatedCardType,
      );
      if (!mounted) return;

      if (_conversations.any((c) => c.id == _activeConversationId)) {
        await DatabaseService.instance.renameConversation(
          _activeConversationId!,
          message.length > 40 ? '${message.substring(0, 40)}...' : message,
        );
      }
    } catch (error, stackTrace) {
      final diagnosticId = _diagnosticId();
      debugPrint(
        '[ChatScreen][$diagnosticId] Message send failed. '
        'conversation=$_activeConversationId, '
        'messageLength=${message.length}, '
        'modelLoaded=${GemmaService.instance.isModelLoaded}, '
        'activeModel=${GemmaService.instance.activeModelDef?.modelId}: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      final conversationId = _activeConversationId;
      if (conversationId != null) {
        try {
          await DatabaseService.instance.addMessage(
            conversationId: conversationId,
            role: 'assistant',
            content: _diagnosticMessage(error, diagnosticId),
          );
        } catch (persistenceError, persistenceStack) {
          debugPrint(
            '[ChatScreen] Failed to persist error response: $persistenceError',
          );
          debugPrintStack(stackTrace: persistenceStack);
        }
      }
      if (mounted) _showMessage('JARVIS could not complete that message.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _busyStage = _JarvisBusyStage.idle;
        });
      }
    }
  }

  Future<void> _ensureJarvisReadyForChat(String message) async {
    debugPrint(
      '[ChatScreen] Loading downloaded model before chat. '
      'messageLength=${message.length}',
    );
    await GemmaService.instance.loadBestAvailableModel();
  }

  _JarvisBusyStage _nextBusyStage() {
    return _mode == _JarvisChatMode.generate
        ? _JarvisBusyStage.generatingSurface
        : _JarvisBusyStage.thinking;
  }

  Future<String> _generatePlainJarvisReply(String message) async {
    debugPrint(
      '[ChatScreen] Generating plain JARVIS reply. '
      'messageLength=${message.length}, conversation=$_activeConversationId',
    );
    final prompt = [
      await ContextProvider.instance.buildChat(
        userMessage: message,
        conversationId: _activeConversationId,
      ),
      'Do not output JSON, UI markup, Markdown, bullets, headings, or asterisks.',
      'Finish the final sentence before stopping.',
    ].join('\n');
    final suppressGreeting = await _conversationAlreadyHasAssistant();
    final response = await GemmaService.instance.generate(
      prompt,
      maxTokens: 220,
      temperature: 0.3,
      timeout: const Duration(seconds: 18),
    );
    final trimmed = _cleanPlainJarvisReply(
      response,
      suppressGreeting: suppressGreeting,
    );
    if (trimmed.isEmpty) {
      throw const GemmaException(
        code: GemmaErrorCode.unknown,
        message: 'JARVIS returned an empty chat response.',
      );
    }
    return trimmed;
  }

  Future<bool> _conversationAlreadyHasAssistant() async {
    final conversationId = _activeConversationId;
    if (conversationId == null) return false;
    final messages = await DatabaseService.instance.getMessages(conversationId);
    return messages.any((message) => message.role == 'assistant');
  }

  String _cleanPlainJarvisReply(
    String response, {
    required bool suppressGreeting,
  }) {
    var cleaned = response.trim();
    while (cleaned.endsWith('*')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trimRight();
    }
    if (suppressGreeting) {
      cleaned = cleaned
          .replaceFirst(
            RegExp(
              r'^(hello|hi|hey|good morning|good afternoon|good evening),?\s+\w+[.!]?\s*',
              caseSensitive: false,
            ),
            '',
          )
          .replaceFirst(
            RegExp(r'^(hello|hi|hey)[.!]?\s+', caseSensitive: false),
            '',
          )
          .trimLeft();
    }
    return cleaned;
  }

  String? _detectGeneratedCardType(String message) {
    final lower = message.toLowerCase();
    if (RegExp(r'\b(workout|exercise|training|gym)\b').hasMatch(lower)) {
      return 'workout';
    }
    if (RegExp(r'\b(schedule|timeline|itinerary|calendar)\b').hasMatch(lower)) {
      return 'schedule';
    }
    if (RegExp(r'\b(dashboard|overview|stats|metrics)\b').hasMatch(lower)) {
      return 'dashboard';
    }
    if (RegExp(r'\b(compare|comparison|versus|vs)\b').hasMatch(lower)) {
      return 'comparison';
    }
    if (RegExp(r'\b(tracker|track|progress)\b').hasMatch(lower)) {
      return 'tracker';
    }
    if (RegExp(r'\b(checklist|steps|todo)\b').hasMatch(lower)) {
      return 'checklist';
    }
    if (RegExp(r'\b(form|input|survey)\b').hasMatch(lower)) {
      return 'form';
    }
    return 'card';
  }

  bool _looksLikeDirectAction(String message) {
    return RegExp(
      r'^(add task|todo|remind me|create task|start focus|focus \d+|add habit|new habit|track|note|remember|write down|jot down)\b',
      caseSensitive: false,
    ).hasMatch(message.trim());
  }

  String? _localJarvisCapabilityReply(String message) {
    final lower = message.toLowerCase().trim();
    final asksCapability = RegExp(
      r"\b(what can you|what do you|capabilities|can you (also )?(build|make|generate|create) (cards|widgets|screens|views|ui|surfaces))\b",
    ).hasMatch(lower);
    if (!asksCapability) return null;

    return 'Yes. I can chat, update your ContextShift data, and build generated cards when a visual structure helps.\n\n'
        'I can generate plans, schedules, workout cards, study blocks, habit dashboards, task checklists, trackers, comparisons, routines, forms, and decision views. I can also use your local tasks, habits, notes, mood, focus history, and recent conversation as context.\n\n'
        'Try: "build a 3-day workout plan", "make a dashboard for my habits", "create a study plan for tomorrow", or "compare these options as a card".';
  }

  String _diagnosticId() {
    return DateTime.now().millisecondsSinceEpoch.toRadixString(16);
  }

  String _diagnosticMessage(Object error, String diagnosticId) {
    final errorText = error.toString();
    final shortError = errorText.length > 240
        ? '${errorText.substring(0, 240)}...'
        : errorText;
    return 'JARVIS hit an error before it could answer.\n'
        'Diagnostic ID: $diagnosticId\n'
        '$shortError\n\n'
        'Please send this screen if it happens again.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatConversationDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  Future<void> _toggleDictation() async {
    if (_isProcessing) return;
    if (_isListening) {
      await _stopDictation();
      return;
    }
    await _startDictation();
  }

  Future<void> _startDictation() async {
    try {
      if (!_speechReady) {
        _speechReady = await _speech.initialize(
          onError: _handleSpeechError,
          onStatus: _handleSpeechStatus,
          options: [
            stt.SpeechToText.androidNoBluetooth,
            stt.SpeechToText.iosNoBluetooth,
          ],
        );
      }
      if (!_speechReady) {
        _showMessage('Dictation is not available on this device.');
        return;
      }

      _dictationBaseText = _messageController.text.trim();
      await _speech.listen(
        onResult: _handleSpeechResult,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          autoPunctuation: true,
          enableHapticFeedback: true,
          pauseFor: const Duration(seconds: 4),
          listenFor: const Duration(minutes: 2),
          cancelOnError: true,
        ),
      );
      if (!mounted) return;
      setState(() => _isListening = true);
    } catch (error, stackTrace) {
      debugPrint('[ChatScreen] Dictation failed to start: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) _showMessage('Dictation could not start.');
    }
  }

  Future<void> _stopDictation() async {
    if (_speechReady) await _speech.stop();
    if (!mounted) return;
    setState(() => _isListening = false);
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    if (!_isListening || _isProcessing) return;
    final words = result.recognizedWords.trim();
    final combined = [
      if (_dictationBaseText.isNotEmpty) _dictationBaseText,
      if (words.isNotEmpty) words,
    ].join(' ');
    _messageController.value = TextEditingValue(
      text: combined,
      selection: TextSelection.collapsed(offset: combined.length),
    );
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    debugPrint('[ChatScreen] Dictation error: $error');
    if (!mounted) return;
    setState(() => _isListening = false);
    if (error.permanent || error.errorMsg == 'error_permission') {
      _showMessage('Microphone permission is needed for dictation.');
    }
  }

  void _handleSpeechStatus(String status) {
    debugPrint('[ChatScreen] Dictation status: $status');
    if (!mounted) return;
    if ((status == stt.SpeechToText.notListeningStatus ||
            status == stt.SpeechToText.doneStatus) &&
        _isListening) {
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBackButton = Navigator.of(context).canPop();
    final hasActiveConv = _activeConversationId != null || _forceComposer;

    if (!_loggedFirstBuild) {
      _loggedFirstBuild = true;
      debugPrint(
        '[ChatScreen] First build. '
        'showBackButton=$showBackButton, hasActiveConv=$hasActiveConv, '
        'activeConversationId=$_activeConversationId, forceComposer=$_forceComposer',
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      resizeToAvoidBottomInset: true,
      drawer: _buildConversationDrawer(context),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, AppTheme.surfaceLow],
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              WonderousReveal(
                begin: const Offset(0, 0.04),
                child: _buildHeader(
                  context,
                  hasActiveConv,
                  showBackButton: showBackButton,
                ),
              ),
              if (hasActiveConv)
                WonderousReveal(
                  delay: const Duration(milliseconds: 80),
                  begin: const Offset(0, 0.04),
                  child: _buildModeSwitch(context),
                ),
              Expanded(
                child: hasActiveConv
                    ? _buildChatView(context)
                    : _buildConversationList(context),
              ),
              if (hasActiveConv)
                WonderousReveal(
                  delay: const Duration(milliseconds: 140),
                  begin: const Offset(0, 0.04),
                  child: _buildInputBar(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitch(BuildContext context) {
    Widget segment({
      required _JarvisChatMode mode,
      required IconData icon,
      required String label,
    }) {
      final selected = _mode == mode;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          child: GestureDetector(
            onTap: () {
              if (_mode == mode) return;
              setState(() => _mode = mode);
            },
            child: AnimatedContainer(
              duration: Motion.fast,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: selected
                    ? Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.24),
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? AppTheme.primary
                        : AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? AppTheme.onSurface
                            : AppTheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        0,
        Responsive.horizontalPadding(context),
        Spacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: AppTheme.contextPanel(
          color: AppTheme.surfaceHighest.withValues(alpha: 0.64),
          accent: AppTheme.primary,
          borderRadius: 999,
        ),
        child: Row(
          children: [
            segment(
              mode: _JarvisChatMode.chat,
              icon: LucideIcons.messageCircle,
              label: 'Chat',
            ),
            segment(
              mode: _JarvisChatMode.generate,
              icon: LucideIcons.sparkles,
              label: 'Generate',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool hasActiveConv, {
    required bool showBackButton,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: showBackButton ? Spacing.xs : Spacing.lg,
        right: Spacing.lg,
        top: Spacing.sm,
        bottom: Spacing.sm,
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: const Icon(
                LucideIcons.arrowLeft,
                color: AppTheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.intelligence.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.radio,
                color: AppTheme.intelligence,
                size: 20,
              ),
            ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'JARVIS',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (hasActiveConv)
            IconButton(
              icon: const Icon(
                LucideIcons.menu,
                color: AppTheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Conversation history',
            ),
          if (hasActiveConv)
            IconButton(
              icon: const Icon(
                LucideIcons.plus,
                color: AppTheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: _startNewConversation,
              tooltip: 'New conversation',
            ),
          IconButton(
            icon: const Icon(
              LucideIcons.trash2,
              color: AppTheme.error,
              size: 20,
            ),
            onPressed: _activeConversationId != null
                ? () => _deleteConversation(_activeConversationId!)
                : null,
            tooltip: 'Delete conversation',
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(BuildContext context) {
    final query = _conversationQuery.toLowerCase();
    final conversations = query.isEmpty
        ? _conversations
        : _conversations
              .where(
                (conv) =>
                    conv.title.toLowerCase().contains(query) ||
                    _formatConversationDate(
                      conv.updatedAt,
                    ).toLowerCase().contains(query),
              )
              .toList();

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.messageSquare,
              size: 48,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            _ContextChatButton(
              icon: LucideIcons.messageSquarePlus,
              label: 'Start a context thread',
              onTap: _startNewConversation,
            ),
          ],
        ),
      );
    }

    if (conversations.isEmpty) {
      return Center(
        child: Text(
          'No matching chats',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: Spacing.sm,
      ),
      itemCount: conversations.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
      itemBuilder: (context, index) {
        final conv = conversations[index];
        final isActive = conv.id == _activeConversationId;
        return _ConversationTile(
          conversation: conv,
          isActive: isActive,
          onTap: () async {
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              Navigator.of(context).pop();
            }
            await _selectConversation(conv.id);
          },
          onDelete: () => _deleteConversation(conv.id),
        );
      },
    );
  }

  Widget _buildConversationDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.surfaceLow,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.lg,
                Spacing.lg,
                Spacing.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.intelligence.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.radio,
                      color: AppTheme.intelligence,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      'Context threads',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.messageSquarePlus, size: 19),
                    color: AppTheme.intelligence,
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _startNewConversation();
                    },
                    tooltip: 'New conversation',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                decoration: AppTheme.contextPanel(
                  color: AppTheme.surfaceContainer,
                  accent: AppTheme.intelligence,
                  borderRadius: 14,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.search,
                      size: 17,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _conversationSearchController,
                        style: const TextStyle(color: AppTheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Search chats',
                          hintStyle: TextStyle(
                            color: AppTheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_conversationQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 16),
                        color: AppTheme.onSurfaceVariant,
                        onPressed: _conversationSearchController.clear,
                        tooltip: 'Clear search',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.md),
            Expanded(child: _buildConversationList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView(BuildContext context) {
    if (_messages.isEmpty && !_isProcessing) {
      final isGenerate = _mode == _JarvisChatMode.generate;
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context),
              Spacing.md,
              Responsive.horizontalPadding(context),
              Spacing.xl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: WonderousReveal(
                  delay: const Duration(milliseconds: 160),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGenerate ? LucideIcons.sparkles : LucideIcons.radio,
                        size: 48,
                        color: AppTheme.intelligence.withValues(alpha: 0.48),
                      ),
                      const SizedBox(height: Spacing.lg),
                      Text(
                        isGenerate
                            ? 'What should JARVIS build?'
                            : 'What should we untangle?',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        isGenerate
                            ? 'Ask for a card, plan, tracker, dashboard, or schedule.'
                            : 'Drop the messy version. JARVIS will use your local context.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      if (isGenerate) ...[
                        const SizedBox(height: Spacing.lg),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: Spacing.sm,
                          runSpacing: Spacing.sm,
                          children: [
                            _GeneratePromptChip(
                              label: 'Workout plan',
                              prompt: 'Build a workout plan card for tomorrow',
                              onSelected: _sendMessage,
                            ),
                            _GeneratePromptChip(
                              label: 'Habit dashboard',
                              prompt:
                                  'Generate a habit dashboard for this week',
                              onSelected: _sendMessage,
                            ),
                            _GeneratePromptChip(
                              label: 'Study schedule',
                              prompt:
                                  'Create a study schedule card for tomorrow',
                              onSelected: _sendMessage,
                            ),
                            _GeneratePromptChip(
                              label: 'Decision card',
                              prompt: 'Make a decision comparison card',
                              onSelected: _sendMessage,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: Spacing.md,
      ),
      itemCount: _messages.length + (_isProcessing ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isProcessing) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: _ThinkingBubble(stage: _busyStage),
          );
        }
        final msg = _messages[index];
        final isUser = msg.role == 'user';
        return _MessageBubble(
          key: ValueKey(msg.id),
          message: msg.content,
          isUser: isUser,
          timestamp: msg.createdAt,
          widgetJson: msg.widgetJson,
          onWidgetAction: (label) => _sendMessage(label),
        );
      },
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final bar = SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: Responsive.horizontalPadding(context),
          right: Responsive.horizontalPadding(context),
          bottom: Spacing.sm,
        ),
        child: Container(
          margin: EdgeInsets.only(bottom: Spacing.xs),
          padding: EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 8),
          decoration: AppTheme.contextPanel(
            color: AppTheme.surfaceHighest.withValues(alpha: 0.92),
            accent: _isListening ? AppTheme.accent : AppTheme.intelligence,
            borderRadius: 28,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 132),
                  child: Scrollbar(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isProcessing,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 5,
                      scrollPadding: const EdgeInsets.only(bottom: 120),
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: _mode == _JarvisChatMode.generate
                            ? 'Generate a card, plan, tracker...'
                            : 'Message JARVIS...',
                        hintStyle: TextStyle(
                          color: AppTheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _sendMessage(null),
                    ),
                  ),
                ),
              ),
              SizedBox(width: Spacing.sm),
              Semantics(
                label: _isListening ? 'Stop dictation' : 'Start dictation',
                toggled: _isListening,
                child: IconButton(
                  onPressed: _isProcessing ? null : _toggleDictation,
                  icon: Icon(
                    _isListening ? LucideIcons.micOff : LucideIcons.mic,
                    color: _isListening
                        ? AppTheme.accent
                        : AppTheme.onSurfaceVariant,
                    size: 18,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    backgroundColor: _isListening
                        ? AppTheme.accent.withValues(alpha: 0.12)
                        : Colors.transparent,
                  ),
                  tooltip: _isListening ? 'Stop dictation' : 'Dictate',
                ),
              ),
              SizedBox(width: Spacing.xs),
              _isProcessing
                  ? const SizedBox.square(
                      dimension: 36,
                      child: Center(
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.intelligence,
                          ),
                        ),
                      ),
                    )
                  : Semantics(
                      label: 'Send message',
                      child: IconButton(
                        onPressed: () => _sendMessage(null),
                        icon: Icon(
                          _mode == _JarvisChatMode.generate
                              ? LucideIcons.sparkles
                              : LucideIcons.send,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );

    return bar;
  }
}
