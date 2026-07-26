import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_theme.dart';
import '../../../shared/context_shift_primitives.dart';

class InsightCard extends StatelessWidget {
  final String? insight;
  final bool isLoading;

  const InsightCard({
    super.key,
    required this.insight,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ContextPanel(
      padding: EdgeInsets.zero,
      color: AppTheme.surfaceHigh,
      accent: AppTheme.intelligence,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: const ContextFieldPainter(
                  color: AppTheme.intelligence,
                  opacity: 0.8,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.audioLines,
                        color: AppTheme.intelligence,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI analysis summary',
                        style: TextStyle(
                          color: AppTheme.intelligence,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.intelligence,
                          ),
                        )
                      : Text(
                          insight ?? 'No insight available.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppTheme.onSurface,
                                height: 1.5,
                              ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
