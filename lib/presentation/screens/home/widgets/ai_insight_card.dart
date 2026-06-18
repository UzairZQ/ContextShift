import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';

class AiInsightCard extends StatelessWidget {
  final String? insight;
  final bool isLoading;
  final VoidCallback onTap;

  const AiInsightCard({
    super.key,
    required this.insight,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AI Insight, tap to open dashboard',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.surfaceHigh,
                AppTheme.surfaceHigh.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.sparkles,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  SizedBox(width: Spacing.sm),
                  Text(
                    'AI Insight',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ],
              ),
              SizedBox(height: Spacing.md),
              isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : Text(
                      insight ?? 'Tap to view your AI dashboard.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                AppTheme.onSurface.withValues(alpha: 0.9),
                          ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
