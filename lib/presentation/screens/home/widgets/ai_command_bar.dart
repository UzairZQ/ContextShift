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

  const AiCommandBar({
    super.key,
    required this.controller,
    required this.isOnline,
    required this.isProcessing,
    required this.hasCheckedStatus,
    required this.offlineHint,
    required this.onSubmit,
    this.onTap,
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
    if (!widget.hasCheckedStatus) return LucideIcons.loader2;
    return widget.isOnline ? LucideIcons.sparkles : LucideIcons.cloudOff;
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
    return AppTheme.warning.withValues(alpha: 0.85);
  }

  String get _hintText {
    if (!widget.hasCheckedStatus) return 'Checking JARVIS status...';
    return widget.isOnline
        ? 'Generate a card, plan, tracker...'
        : widget.offlineHint;
  }

  TextStyle get _hintStyle {
    final base = TextStyle(
      color: widget.isOnline
          ? AppTheme.onSurfaceVariant.withValues(alpha: 0.4)
          : (widget.hasCheckedStatus
                ? AppTheme.warning.withValues(alpha: 0.75)
                : AppTheme.onSurfaceVariant.withValues(alpha: 0.55)),
      fontStyle: (widget.isOnline || !widget.hasCheckedStatus)
          ? FontStyle.normal
          : FontStyle.italic,
      fontSize: widget.isOnline ? 13 : 12,
      height: 1.15,
    );
    if (!widget.hasCheckedStatus) {
      return base.copyWith(fontStyle: FontStyle.italic);
    }
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
            color: (widget.isOnline ? AppTheme.intelligence : AppTheme.warning)
                .withValues(alpha: widget.isOnline ? 0.18 : 0.22),
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
            suffixIcon: widget.isProcessing
                ? const Padding(
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
                : Semantics(
                    label: 'Send command',
                    child: IconButton(
                      onPressed: _handleSend,
                      icon: Icon(
                        widget.isOnline
                            ? LucideIcons.sparkles
                            : LucideIcons.wifiOff,
                        color: widget.isOnline
                            ? AppTheme.intelligence
                            : AppTheme.warning.withValues(alpha: 0.9),
                        size: 18,
                      ),
                    ),
                  ),
          ),
          onSubmitted: (_) => _handleSend(),
        ),
      ),
    );
  }
}
