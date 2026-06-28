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
import '../../../core/ai/jarvis_intent_router.dart';
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
import '../../widgets/jarvis_hero.dart';
import '../../widgets/motion/wonderous_motion.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;
  final int? conversationId;
  final bool startNewOnOpen;
  final bool enableInputHero;

  const ChatScreen({
    super.key,
    this.initialMessage,
    this.conversationId,
    this.startNewOnOpen = false,
    this.enableInputHero = true,
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
  bool _speechReady = false;
  bool _isListening = false;
  String _dictationBaseText = '';
  String _conversationQuery = '';
  late final bool _forceComposer;
  bool _loggedFirstBuild = false;

  int? _activeConversationId;
  List<ConversationTableData> _conversations = [];
  List<MessageTableData> _messages = [];
  StreamSubscription? _messagesSub;
  StreamSubscription<WidgetAction>? _genUiActionSub;

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[ChatScreen] initState start. '
      'initialMessage=${widget.initialMessage?.trim().isNotEmpty == true}, '
      'conversationId=${widget.conversationId}, '
      'startNewOnOpen=${widget.startNewOnOpen}, '
      'enableInputHero=${widget.enableInputHero}',
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
        debugPrint('[ChatScreen] Sending initial message after load');
        _sendMessage(widget.initialMessage!);
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
    final aiAction = GeneratedUiActionMapper.toAiAction(action);
    if (aiAction == null) {
      final message =
          GeneratedUiActionMapper.continuationMessage(action) ??
          'The generated UI action was "${action.action}" with '
              'context ${jsonEncode(action.params)}.';
      await _sendMessage(message);
      return;
    }
    await ActionExecutor.instance.executeAll([aiAction]);
    if (!mounted) return;
    _showMessage('Done');
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
            setState(() => _messages = msgs);
            _scrollToBottom();
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

    setState(() => _isProcessing = true);

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

      final intentDecision = await JarvisIntentRouter.instance.classify(
        message: message,
        conversationId: _activeConversationId,
      );
      debugPrint(
        '[ChatScreen] Intent=${intentDecision.intent} '
        'fromModel=${intentDecision.fromModel} '
        'reason=${intentDecision.reason}',
      );
      String response;
      String? widgetJson;

      if (intentDecision.intent == JarvisIntent.action) {
        final result = await AiService.instance.processCommand(
          command: message,
          userName: DatabaseService.instance.firstName,
          conversationId: _activeConversationId,
        );
        await ActionExecutor.instance.executeAll(result.actions);
        response = result.response;
        debugPrint('[ChatScreen] Direct command response: $response');
        widgetJson = null;
      } else {
        await _ensureJarvisReadyForChat(message);
        switch (intentDecision.intent) {
          case JarvisIntent.chat:
            response = await _generatePlainJarvisReply(message);
            debugPrint('[ChatScreen] Plain JARVIS response: $response');
            widgetJson = null;
          case JarvisIntent.action:
            throw StateError(
              'Action intent should be handled before chat prep.',
            );
          case JarvisIntent.genui:
            final generation = await _genUiRuntimeInstance.generate(
              userMessage: message,
              conversationId: _activeConversationId,
              timeout: const Duration(seconds: 45),
            );
            response = generation.text.isEmpty
                ? 'I shaped that into an interactive view.'
                : generation.text;
            debugPrint(
              '[ChatScreen] GenUI JARVIS response: $response '
              'surfaces=${generation.surfaceIds}',
            );
            widgetJson =
                generation.surfaceIds.isEmpty ||
                    generation.rawA2ui.trim().isEmpty
                ? null
                : jsonEncode(generation.toPersistenceJson());
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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _ensureJarvisReadyForChat(String message) async {
    debugPrint(
      '[ChatScreen] Loading downloaded model before chat. '
      'messageLength=${message.length}',
    );
    await GemmaService.instance.loadBestAvailableModel();
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
      'Do not output JSON or UI markup.',
    ].join('\n');
    final response = await GemmaService.instance.generate(
      prompt,
      maxTokens: 80,
      temperature: 0.3,
      timeout: const Duration(seconds: 12),
    );
    final trimmed = response.trim();
    if (trimmed.isEmpty) {
      throw const GemmaException(
        code: GemmaErrorCode.unknown,
        message: 'JARVIS returned an empty chat response.',
      );
    }
    return trimmed;
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
    _dictationBaseText = '';
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
    if (status == stt.SpeechToText.notListeningStatus ||
        status == stt.SpeechToText.doneStatus) {
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
              _buildHeader(
                context,
                hasActiveConv,
                showBackButton: showBackButton,
              ),
              Expanded(
                child: hasActiveConv
                    ? _buildChatView(context)
                    : _buildConversationList(context),
              ),
              if (hasActiveConv) _buildInputBar(context),
            ],
          ),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.radio,
              size: 48,
              color: AppTheme.intelligence.withValues(alpha: 0.48),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'What should we untangle?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Drop the messy version. JARVIS will use your local context.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: Spacing.md,
      ),
      itemCount: _messages.length + (_isProcessing ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isProcessing) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.sm),
            child: _ThinkingBubble(),
          );
        }
        final msg = _messages[index];
        final isUser = msg.role == 'user';
        return WonderousReveal(
          key: ValueKey(msg.id),
          begin: Offset(isUser ? 0.08 : -0.08, 0.03),
          child: _MessageBubble(
            message: msg.content,
            isUser: isUser,
            timestamp: msg.createdAt,
            widgetJson: msg.widgetJson,
            onWidgetAction: (label) => _sendMessage(label),
          ),
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
          padding: EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: 4),
          decoration: AppTheme.contextPanel(
            color: AppTheme.surfaceHighest.withValues(alpha: 0.92),
            accent: _isListening ? AppTheme.accent : AppTheme.intelligence,
            borderRadius: 999,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  enabled: !_isProcessing,
                  textInputAction: TextInputAction.send,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Message JARVIS...',
                    hintStyle: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _sendMessage(null),
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
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.intelligence,
                      ),
                    )
                  : Semantics(
                      label: 'Send message',
                      child: IconButton(
                        onPressed: () => _sendMessage(null),
                        icon: const Icon(
                          LucideIcons.send,
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

    return widget.enableInputHero
        ? Hero(
            tag: JarvisHero.tag,
            createRectTween: JarvisHero.createRectTween,
            flightShuttleBuilder: JarvisHero.flightShuttleBuilder,
            transitionOnUserGestures: true,
            child: RepaintBoundary(child: bar),
          )
        : bar;
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationTableData conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.intelligence.withValues(alpha: 0.1)
              : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: AppTheme.intelligence.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.messageSquare,
              size: 18,
              color: isActive
                  ? AppTheme.intelligence
                  : AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.title,
                    style: TextStyle(
                      color: isActive
                          ? AppTheme.onSurface
                          : AppTheme.onSurfaceVariant,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(conversation.updatedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: AppTheme.error.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? widgetJson;
  final ValueChanged<String> onWidgetAction;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.timestamp,
    required this.widgetJson,
    required this.onWidgetAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: Spacing.xs, bottom: Spacing.xs),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width * (isUser ? 0.8 : 0.9),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.md,
            ),
            decoration: BoxDecoration(
              color: isUser
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: isUser ? const Radius.circular(4) : null,
                bottomLeft: !isUser ? const Radius.circular(4) : null,
              ),
              border: !isUser
                  ? Border.all(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.08),
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: isUser
                        ? AppTheme.onSurface
                        : AppTheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                if (!isUser && widgetJson != null) ...[
                  const SizedBox(height: Spacing.md),
                  _buildGeneratedContent(context),
                ],
              ],
            ),
          ),
          SizedBox(height: 2),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.sm),
            child: Text(
              _formatTime(timestamp),
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedContent(BuildContext context) {
    try {
      final decoded = jsonDecode(widgetJson!);
      if (decoded is Map) {
        final card = Map<String, dynamic>.from(decoded);
        if (card['format'] == 'a2ui-v0.9' && card['raw'] is String) {
          return A2uiSurfaceCard(
            rawA2ui: card['raw'] as String,
            onAction: (action) {
              GenUiActionBus.instance.emit(action);
            },
          );
        }
      }
      debugPrint(
        '[ChatScreen] Ignoring non-object GenUI payload: ${decoded.runtimeType}',
      );
    } catch (error, stackTrace) {
      debugPrint('[ChatScreen] Invalid stored GenUI JSON: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    return Text(
      'This older interactive response could not be displayed.',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppTheme.warning),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(
            20,
          ).copyWith(bottomLeft: const Radius.circular(4)),
          border: Border.all(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(index: 0),
            SizedBox(width: 4),
            _Dot(index: 1),
            SizedBox(width: 4),
            _Dot(index: 2),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int index;
  const _Dot({required this.index});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.index * 0.2,
          0.6 + widget.index * 0.2,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) => Opacity(
        opacity: _animation.value,
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppTheme.intelligence,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ContextChatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContextChatButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Spacing.xxl,
          vertical: Spacing.md,
        ),
        decoration: AppTheme.contextPanel(
          color: AppTheme.intelligence.withValues(alpha: 0.1),
          accent: AppTheme.intelligence,
          borderRadius: 999,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.intelligence),
            const SizedBox(width: Spacing.sm),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.intelligence,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
