import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/responsive.dart';

class StatsSection extends StatelessWidget {
  final int focusMinutesToday;

  const StatsSection({super.key, required this.focusMinutesToday});

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService.instance.watchTasks(),
      builder: (context, taskSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService.instance.watchHabits(),
          builder: (context, habitSnap) {
            final tasks = taskSnap.data ?? [];
            final habits = habitSnap.data ?? [];

            final tasksDone = tasks.where((t) => t['done'] == true).length;
            final totalTasks = tasks.length;

            final today = _todayString();
            final habitsDone = habits.where((h) {
              final dates = (h['completedDates'] as List<dynamic>?) ?? [];
              return dates.contains(today);
            }).length;
            final totalHabits = habits.length;

            final streak = DatabaseService.instance.computeStreak(habits);

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
              crossAxisSpacing: Spacing.md,
              mainAxisSpacing: Spacing.md,
              childAspectRatio: Responsive.isMobile(context) ? 1.38 : 1.55,
              children: [
                _StatCard(
                  value: '$tasksDone/$totalTasks',
                  label: 'Tasks Done',
                  icon: LucideIcons.checkSquare,
                  progress: totalTasks > 0 ? tasksDone / totalTasks : 0,
                  color: AppTheme.tertiary,
                ),
                _StatCard(
                  value: '$habitsDone/$totalHabits',
                  label: 'Habits',
                  icon: LucideIcons.activity,
                  progress: totalHabits > 0 ? habitsDone / totalHabits : 0,
                  color: AppTheme.success,
                ),
                _StatCard(
                  value: '${focusMinutesToday}m',
                  label: 'Focus Today',
                  icon: LucideIcons.timer,
                  progress: (focusMinutesToday / 120).clamp(0, 1).toDouble(),
                  color: AppTheme.primary,
                ),
                _StatCard(
                  value: '$streak',
                  label: 'Day Streak',
                  icon: LucideIcons.flame,
                  progress: (streak / 30).clamp(0, 1).toDouble(),
                  color: AppTheme.warning,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final double progress;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: Spacing.cardPadding,
        decoration: AppTheme.cardDecoration(color: AppTheme.surfaceContainer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: color),
                const Spacer(),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0, 1),
                    strokeWidth: 3,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
