import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';

class AiInsightsModule extends StatelessWidget {
  final int adaptations;
  final String insightText;

  const AiInsightsModule({
    super.key,
    this.adaptations = 12,
    this.insightText = "Based on your patterns, Focus Timer is most used at 9AM",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text("AI Insight", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(insightText, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text("Adapted layouts $adaptations times this month", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}
