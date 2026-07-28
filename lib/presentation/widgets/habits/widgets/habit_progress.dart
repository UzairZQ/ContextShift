import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../shared/module_cards.dart';

class HabitProgress extends StatelessWidget {
  final int doneCount;
  final int buildTotal;
  final int protectedCount;
  final int reduceTotal;

  const HabitProgress({
    super.key,
    required this.doneCount,
    required this.buildTotal,
    required this.protectedCount,
    required this.reduceTotal,
  });

  @override
  Widget build(BuildContext context) {
    final total = buildTotal + reduceTotal;
    final wins = doneCount + protectedCount;
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: moduleCardDecoration(
        accent: AppTheme.success,
        borderRadius: 16,
        fill: AppTheme.surfaceHigh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's behavior signals",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '$wins / $total',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : wins / total,
              backgroundColor: AppTheme.surface,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _summaryText,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.72),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  String get _summaryText {
    final parts = <String>[];
    if (buildTotal > 0) {
      parts.add('$doneCount/$buildTotal build habits practiced');
    }
    if (reduceTotal > 0) {
      parts.add('$protectedCount/$reduceTotal reduce habits protected');
    }
    if (parts.isEmpty) {
      return 'Design a behavior, then make the first move tiny.';
    }
    return parts.join(' · ');
  }
}
