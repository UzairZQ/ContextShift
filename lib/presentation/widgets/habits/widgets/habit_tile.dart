import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';

class HabitTile extends StatelessWidget {
  final Map<String, dynamic> habit;
  final bool isDoneToday;
  final ValueChanged<bool> onToggle;

  const HabitTile({
    super.key,
    required this.habit,
    required this.isDoneToday,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!isDoneToday),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDoneToday
              ? Colors.green.withValues(alpha: 0.1)
              : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDoneToday
                ? Colors.green.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Text(habit['icon'] ?? '✅', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    habit['name'] ?? '',
                    style: TextStyle(
                      color: isDoneToday ? Colors.white60 : Colors.white,
                      fontSize: 15,
                      decoration: isDoneToday
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: Colors.white38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _MiniHeatmap(completedDates: habit['completedDates']),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDoneToday
                    ? Colors.green.withValues(alpha: 0.25)
                    : Colors.transparent,
                border: Border.all(
                  color: isDoneToday ? Colors.green : Colors.white24,
                  width: 2,
                ),
              ),
              child: isDoneToday
                  ? const Icon(LucideIcons.check, color: Colors.green, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniHeatmap extends StatelessWidget {
  final dynamic completedDates;

  const _MiniHeatmap({required this.completedDates});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dates = (completedDates as List<dynamic>?) ?? [];

    return Row(
      children: List.generate(7, (index) {
        final day = now.subtract(Duration(days: 6 - index));
        final dayStr = DatabaseService.dateKey(day);
        final isCompleted = dates.contains(dayStr);

        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppTheme.primary
                : Colors.white.withValues(alpha: 0.1),
            border: isCompleted ? null : Border.all(color: Colors.white10),
          ),
        );
      }),
    );
  }
}
