import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';

class AiCommandBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isOnline;
  final bool isProcessing;
  final bool hasCheckedStatus;
  final String offlineHint;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onTap;
  final VoidCallback? onMicTap;

  const AiCommandBar({
    super.key,
    required this.controller,
    required this.isOnline,
    required this.isProcessing,
    required this.hasCheckedStatus,
    required this.offlineHint,
    required this.onSubmit,
    this.onTap,
    this.onMicTap,
  });

  @override
  State<AiCommandBar> createState() => _AiCommandBarState();
}

class _AiCommandBarState extends State<AiCommandBar> {
  void _handleSend() {
    final value = widget.controller.text.trim();
    if (value.isEmpty) return;
    widget.onSubmit(value);
  }

  IconData get _leadingIcon {
    if (!widget.hasCheckedStatus) return LucideIcons.loaderCircle;
    return widget.isOnline ? LucideIcons.audioLines : LucideIcons.cpu;
  }

  Color get _leadingColor {
    if (!widget.hasCheckedStatus) {
      return AppTheme.intelligence.withValues(alpha: 0.8);
    }
    if (widget.isOnline) {
      return widget.isProcessing
          ? AppTheme.intelligence
          : AppTheme.intelligence.withValues(alpha: 0.68);
    }
    return AppTheme.onSurfaceVariant.withValues(alpha: 0.7);
  }

  String get _hintText {
    if (!widget.hasCheckedStatus) return 'Checking JARVIS status...';
    return widget.isOnline
        ? 'Ask JARVIS, or build a card...'
        : widget.offlineHint;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.only(left: Spacing.lg, right: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHighest.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppTheme.intelligence.withValues(
              alpha: widget.isOnline ? 0.2 : 0.1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(_leadingIcon, color: _leadingColor, size: 19),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: true,
                maxLines: 1,
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.send,
                style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  hintText: _hintText,
                  hintStyle: TextStyle(
                    color: AppTheme.onSurfaceVariant.withValues(
                      alpha: widget.isOnline ? 0.45 : 0.6,
                    ),
                    fontSize: 13,
                    height: 1.15,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            if (widget.onMicTap != null && !widget.isProcessing)
              Semantics(
                label: 'Voice mode',
                button: true,
                child: IconButton(
                  onPressed: widget.onMicTap,
                  icon: const Icon(
                    LucideIcons.mic,
                    color: AppTheme.onSurfaceVariant,
                    size: 18,
                  ),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(38, 38),
                  ),
                  tooltip: 'Talk to JARVIS',
                ),
              ),
            const SizedBox(width: 2),
            widget.isProcessing
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.intelligence,
                      ),
                    ),
                  )
                : Semantics(
                    label: 'Send to JARVIS',
                    button: true,
                    child: GestureDetector(
                      onTap: _handleSend,
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: widget.isOnline
                              ? AppTheme.primaryGradient
                              : null,
                          color: widget.isOnline
                              ? null
                              : AppTheme.surfaceBright,
                        ),
                        child: Icon(
                          LucideIcons.arrowUp,
                          color: widget.isOnline
                              ? AppTheme.background
                              : AppTheme.onSurfaceVariant,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
