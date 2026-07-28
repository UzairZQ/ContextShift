import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';
import '../jarvis_home_status.dart';

class AiCommandBar extends StatefulWidget {
  final TextEditingController controller;
  final JarvisHomeStatus status;
  final bool isProcessing;
  final ValueChanged<String> onSubmit;
  final VoidCallback onVoiceInput;

  const AiCommandBar({
    super.key,
    required this.controller,
    required this.status,
    required this.isProcessing,
    required this.onSubmit,
    required this.onVoiceInput,
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
    return switch (widget.status) {
      JarvisHomeStatus.checking ||
      JarvisHomeStatus.waking => LucideIcons.loaderCircle,
      JarvisHomeStatus.downloadRequired => LucideIcons.downloadCloud,
      JarvisHomeStatus.standby => LucideIcons.cpu,
      JarvisHomeStatus.ready => LucideIcons.sparkles,
    };
  }

  Color get _leadingColor {
    if (widget.status == JarvisHomeStatus.downloadRequired) {
      return AppTheme.warning.withValues(alpha: 0.85);
    }
    if (widget.status == JarvisHomeStatus.ready) {
      return widget.isProcessing
          ? AppTheme.intelligence
          : AppTheme.intelligence.withValues(alpha: 0.68);
    }
    return AppTheme.intelligence.withValues(alpha: 0.8);
  }

  String get _hintText {
    return switch (widget.status) {
      JarvisHomeStatus.checking => 'Checking JARVIS status...',
      JarvisHomeStatus.downloadRequired => 'Download JARVIS to chat',
      JarvisHomeStatus.standby => 'Send a message to wake JARVIS',
      JarvisHomeStatus.waking => 'Loading JARVIS into memory...',
      JarvisHomeStatus.ready => 'Generate a card, plan, tracker...',
    };
  }

  TextStyle get _hintStyle {
    final warning = widget.status == JarvisHomeStatus.downloadRequired;
    final base = TextStyle(
      color: !warning
          ? AppTheme.onSurfaceVariant.withValues(alpha: 0.4)
          : AppTheme.warning.withValues(alpha: 0.75),
      fontStyle: warning ? FontStyle.italic : FontStyle.normal,
      fontSize: widget.status == JarvisHomeStatus.ready ? 13 : 12,
      height: 1.15,
    );
    return base;
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
            color:
                (widget.status == JarvisHomeStatus.downloadRequired
                        ? AppTheme.warning
                        : AppTheme.intelligence)
                    .withValues(alpha: 0.2),
          ),
        ),
        child: TextField(
          controller: widget.controller,
          enabled: true,
          maxLines: 1,
          textAlignVertical: TextAlignVertical.center,
          textInputAction: TextInputAction.send,
          style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
          decoration: InputDecoration(
            icon: Icon(_leadingIcon, color: _leadingColor, size: 20),
            hintText: _hintText,
            hintStyle: _hintStyle,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: InputBorder.none,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: widget.isProcessing ? null : widget.onVoiceInput,
                  tooltip: 'Dictate a message',
                  icon: const Icon(LucideIcons.mic, size: 18),
                  color: AppTheme.onSurfaceVariant,
                ),
                if (widget.isProcessing)
                  const Padding(
                    padding: EdgeInsets.all(Spacing.md),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.intelligence,
                      ),
                    ),
                  )
                else
                  Semantics(
                    label: 'Send command',
                    child: IconButton(
                      onPressed: _handleSend,
                      icon: Icon(
                        widget.status != JarvisHomeStatus.downloadRequired
                            ? LucideIcons.sparkles
                            : LucideIcons.downloadCloud,
                        color:
                            widget.status != JarvisHomeStatus.downloadRequired
                            ? AppTheme.intelligence
                            : AppTheme.warning.withValues(alpha: 0.9),
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          onSubmitted: (_) => _handleSend(),
        ),
      ),
    );
  }
}
