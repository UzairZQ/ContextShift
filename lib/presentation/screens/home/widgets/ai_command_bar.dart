import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
      return AppTheme.primary.withValues(alpha: 0.8);
    }
    if (widget.isOnline) {
      return widget.isProcessing
          ? AppTheme.primary
          : AppTheme.primary.withValues(alpha: 0.6);
    }
    return AppTheme.warning.withValues(alpha: 0.85);
  }

  String get _hintText {
    if (!widget.hasCheckedStatus) return 'Checking JARVIS status...';
    return widget.isOnline ? 'Tell JARVIS what to do...' : widget.offlineHint;
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
    );
    if (!widget.hasCheckedStatus) {
      return base.copyWith(fontStyle: FontStyle.italic);
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'jarvis_bar',
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.only(top: Spacing.xl),
          padding: EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: 4),
          decoration: AppTheme.glassmorphism(
            tint: AppTheme.surfaceHighest,
            borderRadius: 999,
          ),
          child: TextField(
            controller: widget.controller,
            enabled: true,
            textInputAction: TextInputAction.send,
            style: const TextStyle(color: AppTheme.onSurface),
            decoration: InputDecoration(
          icon: Icon(
            _leadingIcon,
            color: _leadingColor,
            size: 20,
          ),
          hintText: _hintText,
          hintStyle: _hintStyle,
          border: InputBorder.none,
          suffixIcon: widget.isProcessing
              ? const Padding(
                  padding: EdgeInsets.all(Spacing.md),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                )
              : Semantics(
                  label: 'Send command',
                  child: IconButton(
                    onPressed: _handleSend,
                    icon: Icon(
                      widget.isOnline
                          ? LucideIcons.send
                          : LucideIcons.wifiOff,
                      color: widget.isOnline
                          ? AppTheme.primary
                          : AppTheme.warning.withValues(alpha: 0.9),
                      size: 18,
                    ),
                  ),
                ),
        ),
        onSubmitted: (_) => _handleSend(),
          ),
        ),
      ),
    );
  }
}
