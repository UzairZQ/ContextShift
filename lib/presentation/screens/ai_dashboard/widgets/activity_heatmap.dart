import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';
import '../../../shared/context_shift_primitives.dart';

class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService.instance.watchHabits(),
      builder: (context, snapshot) {
        final habits = snapshot.data ?? [];
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

        return ContextPanel(
          padding: const EdgeInsets.all(20),
          accent: AppTheme.intelligence,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last 28 days',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'behavior wins',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  const cols = 28;
                  const spacing = 3.0;
                  final boxSize =
                      ((constraints.maxWidth - ((cols - 1) * spacing)) / cols)
                          .clamp(4.0, 14.0);

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: List.generate(cols, (index) {
                      final day = now.subtract(
                        Duration(days: (cols - 1) - index),
                      );
                      final dayStr = DatabaseService.dateKey(day);
                      final count = dailyCounts[dayStr] ?? 0;

                      double opacity = 0.05;
                      if (count > 0 && habits.isNotEmpty) {
                        opacity = 0.2 + (count / habits.length * 0.8);
                        if (opacity > 1.0) opacity = 1.0;
                      }

                      return Container(
                        width: boxSize,
                        height: boxSize,
                        decoration: BoxDecoration(
                          color: count > 0
                              ? AppTheme.intelligence.withValues(alpha: opacity)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: count > 0
                              ? [
                                  BoxShadow(
                                    color: AppTheme.intelligence.withValues(
                                      alpha: opacity * 0.4,
                                    ),
                                    blurRadius: 4,
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
      },
    );
  }
}
