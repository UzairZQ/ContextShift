import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';
import '../../shared/module_cards.dart';

class HabitHeatmap extends StatelessWidget {
  final List<Map<String, dynamic>> habits;

  const HabitHeatmap({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final Map<String, int> dailyCounts = {};

    for (var h in habits) {
      final dates = (h['completedDates'] as List<dynamic>?) ?? [];
      for (var d in dates) {
        if (d is String) {
          dailyCounts[d] = (dailyCounts[d] ?? 0) + 1;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: moduleCardDecoration(
        accent: AppTheme.success,
        borderRadius: 20,
        fill: AppTheme.surfaceHigh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Behavior History",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "practice + protected days",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 4.0;
              final boxSize = (constraints.maxWidth - (27 * spacing)) / 28;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(28, (index) {
                  final day = now.subtract(Duration(days: 27 - index));
                  final dayStr = DatabaseService.dateKey(day);
                  final count = dailyCounts[dayStr] ?? 0;

                  double opacity = 0.05;
                  if (count > 0) {
                    opacity = 0.2 + (count / habits.length * 0.8);
                    if (opacity > 1.0) opacity = 1.0;
                  }

                  return Container(
                    width: boxSize.clamp(4, 12),
                    height: boxSize.clamp(4, 12),
                    decoration: BoxDecoration(
                      color: count > 0
                          ? AppTheme.primary.withValues(alpha: opacity)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: count > 0
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withValues(
                                  alpha: opacity * 0.5,
                                ),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
