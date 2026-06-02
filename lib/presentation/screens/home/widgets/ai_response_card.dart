import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    return FadeTransition(
      opacity: animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.sparkles, color: AppTheme.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                LucideIcons.x,
                size: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
