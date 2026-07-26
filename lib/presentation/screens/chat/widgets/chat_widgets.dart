part of '../chat_screen.dart';

class _GeneratePromptChip extends StatelessWidget {
  final String label;
  final String prompt;
  final ValueChanged<String> onSelected;

  const _GeneratePromptChip({
    required this.label,
    required this.prompt,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(LucideIcons.sparkles, size: 14),
      label: Text(label),
      labelStyle: const TextStyle(
        color: AppTheme.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.22)),
      backgroundColor: AppTheme.surfaceHighest.withValues(alpha: 0.66),
      onPressed: () => onSelected(prompt),
    );
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
    super.key,
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
            source: card['source']?.toString(),
            fallbackReason: card['fallbackReason']?.toString(),
            elapsedMs: card['elapsedMs'] is num
                ? (card['elapsedMs'] as num).round()
                : null,
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
  final _JarvisBusyStage stage;

  const _ThinkingBubble({required this.stage});

  @override
  Widget build(BuildContext context) {
    final copy = switch (stage) {
      _JarvisBusyStage.loadingModel => (
        title: 'Loading JARVIS',
        body:
            'Bringing the local model into memory. First reply can take a moment.',
        icon: LucideIcons.cpu,
      ),
      _JarvisBusyStage.generatingSurface => (
        title: 'Building your card',
        body: 'Gemma is shaping a structured view for this request.',
        icon: LucideIcons.sparkles,
      ),
      _JarvisBusyStage.thinking || _JarvisBusyStage.idle => (
        title: 'Thinking locally',
        body: 'Using your on-device context to answer.',
        icon: LucideIcons.audioLines,
      ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(copy.icon, size: 17, color: AppTheme.intelligence),
                const SizedBox(width: Spacing.sm),
                Text(
                  copy.title,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                _Dot(index: 0),
                const SizedBox(width: 4),
                _Dot(index: 1),
                const SizedBox(width: 4),
                _Dot(index: 2),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              copy.body,
              style: TextStyle(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.72),
                fontSize: 12,
                height: 1.35,
              ),
            ),
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
