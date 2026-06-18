import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';

class AiResponseCard extends StatelessWidget {
  final Animation<double> animation;
  final String message;
  final VoidCallback onDismiss;

  const AiResponseCard({
    super.key,
    required this.animation,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: Semantics(
          label: 'AI Response',
          child: Container(
            margin: EdgeInsets.only(bottom: Spacing.lg),
            padding: Spacing.cardPadding,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles,
                    color: AppTheme.primary, size: 18),
                SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                        color: AppTheme.onSurface, fontSize: 14),
                  ),
                ),
                Semantics(
                  label: 'Dismiss response',
                  child: IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(
                      LucideIcons.x,
                      size: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: HitTarget.icon,
                      minHeight: HitTarget.icon,
                    ),
                    padding: EdgeInsets.zero,
                    splashRadius: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
