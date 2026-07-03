import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      label: 'AI analysis, tap to open dashboard',
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
            border: Border.all(
              color: AppTheme.intelligence.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.radio,
                    color: AppTheme.intelligence,
                    size: 18,
                  ),
                  SizedBox(width: Spacing.sm),
                  Text(
                    'AI analysis',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.intelligence,
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
                        color: AppTheme.intelligence,
                      ),
                    )
                  : Text(
                      insight ?? 'Tap to view your local pattern report.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
