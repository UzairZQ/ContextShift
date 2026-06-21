import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/ai_service.dart';
import '../../../core/ai/action_executor.dart';
import '../../../core/app_spacing.dart';
import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/schema.dart';
import '../../../core/genui/safe_renderer.dart';
import '../../../core/genui/action_bus.dart';
import '../../../core/genui/genui_runtime.dart';
import '../../../core/genui/widget_node.dart';
import '../../../core/local_llm/gemma_service.dart';
import '../../../core/responsive.dart';
import '../../../core/services/feature_manager.dart';
import '../../widgets/generative_card_module.dart';
import '../../widgets/genui/a2ui_surface_card.dart';
import '../../widgets/motion/wonderous_motion.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;
  final int? conversationId;

  const ChatScreen({super.key, this.initialMessage, this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late final JarvisGenUiRuntime _genUiRuntime;
  bool _isProcessing = false;

  int? _activeConversationId;
  List<ConversationTableData> _conversations = [];
  List<MessageTableData> _messages = [];
  StreamSubscription? _messagesSub;
  StreamSubscription<WidgetAction>? _genUiActionSub;

  @override
  void initState() {
    super.initState();
    _genUiRuntime = JarvisGenUiRuntime();
    _activeConversationId = widget.conversationId;
    _genUiActionSub = GenUiActionBus.instance.actions.listen(
      _handleGenUiAction,
    );
    _loadConversations().then((_) {
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        _sendMessage(widget.initialMessage!);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSub?.cancel();
    _genUiActionSub?.cancel();
    _genUiRuntime.dispose();
    super.dispose();
  }

  Future<void> _handleGenUiAction(WidgetAction action) async {
    final type = switch (action.action) {
      'create_task' => 'add_task',
      'create_habit' => 'add_habit',
      'create_note' => 'add_note',
      'start_focus' => 'start_focus',
      _ => action.action,
    };
    const executableActions = {
      'add_task',
      'add_habit',
      'add_note',
      'start_focus',
    };
    if (!executableActions.contains(type)) {
      final message =
          action.params['message']?.toString().trim().isNotEmpty == true
          ? action.params['message'].toString()
          : 'The generated UI action was "${action.action}" with '
                'context ${jsonEncode(action.params)}.';
      await _sendMessage(message);
      return;
    }
    await ActionExecutor.instance.executeAll([
      AiAction(type: type, params: action.params),
    ]);
    if (!mounted) return;
    _showMessage('Done');
  }

  Future<void> _loadConversations() async {
    try {
      final convs = await DatabaseService.instance.getAllConversations();
      if (!mounted) return;
      setState(() => _conversations = convs);

      final isNewPrompt = widget.initialMessage?.trim().isNotEmpty ?? false;
      if (!isNewPrompt && _activeConversationId == null && convs.isNotEmpty) {
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
    _messagesSub = DatabaseService.instance
        .watchMessages(_activeConversationId!)
        .listen((msgs) {
          if (!mounted) return;
          setState(() => _messages = msgs);
          _scrollToBottom();
        });
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
    _messageController.clear();

    if (_activeConversationId == null) {
      await _startNewConversation();
    }

    if (!mounted || _activeConversationId == null) return;

    setState(() => _isProcessing = true);

    try {
      await DatabaseService.instance.addMessage(
        conversationId: _activeConversationId!,
        role: 'user',
        content: message,
      );

      final isDirectCommand = AiService.instance.isCommandQuery(message);
      String response;
      String? widgetJson;

      final localSmallTalk = _localSmallTalkResponse(message);
      if (localSmallTalk != null) {
        response = localSmallTalk;
        widgetJson = null;
      } else if (isDirectCommand) {
        final result = await AiService.instance.processCommand(
          command: message,
          userName: DatabaseService.instance.firstName,
          conversationId: _activeConversationId,
        );
        final execution = await ActionExecutor.instance.executeAll(
          result.actions,
        );
        response = result.response;
        widgetJson = execution.generatedCard == null
            ? _encodeWidgetPayload(result)
            : jsonEncode(execution.generatedCard);
      } else {
        await _ensureJarvisReadyForChat(message);
        final generation = await _genUiRuntime.generate(
          userMessage: message,
          conversationId: _activeConversationId,
          timeout: const Duration(seconds: 45),
        );
        response = generation.text.isEmpty
            ? 'I shaped that into an interactive view.'
            : generation.text;
        widgetJson =
            generation.surfaceIds.isEmpty || generation.rawA2ui.trim().isEmpty
            ? null
            : jsonEncode(generation.toPersistenceJson());
      }

      await DatabaseService.instance.addMessage(
        conversationId: _activeConversationId!,
        role: 'assistant',
        content: response,
        widgetJson: widgetJson,
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

  String? _localSmallTalkResponse(String message) {
    final cleaned = message
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    const greetings = {
      'hi',
      'hello',
      'hey',
      'yo',
      'hi jarvis',
      'hello jarvis',
      'hey jarvis',
      'how are you',
      'hi how are you',
      'hello how are you',
      'hey how are you',
      'how are you jarvis',
    };
    if (!greetings.contains(cleaned)) return null;
    final name = DatabaseService.instance.firstName;
    return "I'm here, $name. Ready when you are. Tell me what you want to clear, plan, or focus on next.";
  }

  Future<void> _ensureJarvisReadyForChat(String message) async {
    if (GemmaService.instance.isModelLoaded) return;

    final model = FeatureManager.instance.resolveBestModelDef();
    if (model == null) {
      throw const GemmaException(
        code: GemmaErrorCode.modelNotInstalled,
        message: 'No local JARVIS model is marked as downloaded.',
      );
    }

    debugPrint(
      '[ChatScreen] Chat blocked because model is downloaded but not loaded. '
      'model=${model.modelId}, messageLength=${message.length}',
    );
    throw GemmaException(
      code: GemmaErrorCode.modelNotLoaded,
      message:
          'JARVIS is downloaded, but the local model is not active yet. '
          'Restart the app once so it can activate safely.',
      detail:
          'Model ID: ${model.modelId}. '
          'GemmaService.isInitialized=${GemmaService.instance.isInitialized}',
    );
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

  String? _encodeWidgetPayload(AiCommandResult result) {
    for (final action in result.actions) {
      if (action.type != 'show_dynamic_card') continue;
      final card = action.params['card'];
      if (card is Map) {
        try {
          return jsonEncode(Map<String, dynamic>.from(card));
        } catch (error, stackTrace) {
          debugPrint('[ChatScreen] Failed to encode GenUI payload: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBackButton = Navigator.of(context).canPop();
    final hasActiveConv = _activeConversationId != null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.background, AppTheme.surfaceLow],
        ),
      ),
      child: SafeArea(
        top: !showBackButton,
        bottom: false,
        child: Column(
          children: [
            if (showBackButton)
              _buildHeader(context, hasActiveConv)
            else
              SizedBox(height: MediaQuery.of(context).padding.top + Spacing.lg),
            Expanded(
              child: hasActiveConv
                  ? _buildChatView(context)
                  : _buildConversationList(context),
            ),
            if (hasActiveConv) _buildInputBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool hasActiveConv) {
    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.xs,
        right: Spacing.lg,
        top: Spacing.sm,
        bottom: Spacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppTheme.onSurface),
            onPressed: () => Navigator.pop(context),
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
            _GlassButton(
              icon: LucideIcons.messageSquarePlus,
              label: 'Start a chat',
              onTap: _startNewConversation,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: Spacing.sm,
      ),
      itemCount: _conversations.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
      itemBuilder: (context, index) {
        final conv = _conversations[index];
        final isActive = conv.id == _activeConversationId;
        return _ConversationTile(
          conversation: conv,
          isActive: isActive,
          onTap: () => _selectConversation(conv.id),
          onDelete: () => _deleteConversation(conv.id),
        );
      },
    );
  }

  Widget _buildChatView(BuildContext context) {
    if (_messages.isEmpty && !_isProcessing) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.sparkles,
              size: 48,
              color: AppTheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Ask me anything',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'I can help with tasks, habits, focus, and more',
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
          decoration: AppTheme.glassmorphism(
            tint: AppTheme.surfaceHighest,
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
              _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
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

    return widget.conversationId == null
        ? Hero(
            tag: 'jarvis_bar',
            createRectTween: (begin, end) =>
                MaterialRectArcTween(begin: begin, end: end),
            child: bar,
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
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? Border.all(color: AppTheme.primary.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.messageSquare,
              size: 18,
              color: isActive ? AppTheme.primary : AppTheme.onSurfaceVariant,
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
              maxWidth: MediaQuery.of(context).size.width * 0.8,
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
        return GenerativeCardModule(
          cardData: card,
          onAction: () =>
              onWidgetAction(card['action_label'] as String? ?? 'Continue'),
        );
      }
      debugPrint(
        '[ChatScreen] Ignoring non-object GenUI payload: ${decoded.runtimeType}',
      );
    } catch (error, stackTrace) {
      debugPrint('[ChatScreen] Invalid stored GenUI JSON: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    return SafeRenderer.buildFallbackWidget(
      'This older interactive response could not be displayed.',
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
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassButton({
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
        decoration: AppTheme.glassmorphism(
          tint: AppTheme.primary,
          opacity: 0.15,
          borderRadius: 999,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.primary),
            const SizedBox(width: Spacing.sm),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primary,
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
