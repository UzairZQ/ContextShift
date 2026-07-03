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
    final kind = habit['kind'] == 'reduce' ? 'reduce' : 'build';
    final isReduce = kind == 'reduce';
    final activeColor = isReduce ? AppTheme.warning : Colors.green;
    final cue = (habit['cue'] as String?)?.trim();
    final tinyStep = (habit['tinyStep'] as String?)?.trim();
    final reward = (habit['reward'] as String?)?.trim();
    final friction = (habit['friction'] as String?)?.trim();
    final strategy = isReduce
        ? [
            if (cue != null && cue.isNotEmpty) 'Trigger: $cue',
            if (tinyStep != null && tinyStep.isNotEmpty) 'Swap: $tinyStep',
            if (friction != null && friction.isNotEmpty) 'Friction: $friction',
          ]
        : [
            if (cue != null && cue.isNotEmpty) 'Cue: $cue',
            if (tinyStep != null && tinyStep.isNotEmpty) 'Tiny: $tinyStep',
            if (reward != null && reward.isNotEmpty) 'Reward: $reward',
          ];

    return GestureDetector(
      onTap: () => onToggle(!isDoneToday),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDoneToday
              ? activeColor.withValues(alpha: 0.1)
              : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDoneToday
                ? activeColor.withValues(alpha: 0.4)
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
                  Row(
                    children: [
                      _KindPill(
                        label: isReduce ? 'Reduce' : 'Build',
                        color: isReduce ? AppTheme.warning : AppTheme.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isReduce
                              ? (isDoneToday
                                    ? 'Protected today'
                                    : 'Protect today')
                              : (isDoneToday
                                    ? 'Practiced today'
                                    : 'Practice today'),
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant.withValues(
                              alpha: 0.62,
                            ),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    habit['name'] ?? '',
                    style: TextStyle(
                      color: isDoneToday
                          ? AppTheme.onSurface.withValues(alpha: 0.68)
                          : AppTheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (strategy.isNotEmpty) ...[
                    Text(
                      strategy.take(2).join(' · '),
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
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
                    ? activeColor.withValues(alpha: 0.25)
                    : Colors.transparent,
                border: Border.all(
                  color: isDoneToday ? activeColor : Colors.white24,
                  width: 2,
                ),
              ),
              child: isDoneToday
                  ? Icon(LucideIcons.check, color: activeColor, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _KindPill extends StatelessWidget {
  final String label;
  final Color color;

  const _KindPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
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
