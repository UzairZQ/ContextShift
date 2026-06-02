import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';

class HabitProgress extends StatelessWidget {
  final int doneCount;
  final int total;

  const HabitProgress({
    super.key,
    required this.doneCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's progress",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '$doneCount / $total',
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
              value: total == 0 ? 0 : doneCount / total,
              backgroundColor: AppTheme.surface,
              valueColor: const AlwaysStoppedAnimation(
                AppTheme.primary,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
