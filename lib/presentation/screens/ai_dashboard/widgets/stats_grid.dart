import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';
import 'dash_stat_card.dart';

class StatsGrid extends StatelessWidget {
  final int focusMinutes;

  const StatsGrid({super.key, required this.focusMinutes});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService.instance.watchTasks(),
      builder: (context, taskSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService.instance.watchHabits(),
          builder: (context, habitSnap) {
            if (taskSnap.hasError || habitSnap.hasError) {
              return const Text(
                'Activity totals are temporarily unavailable.',
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              );
            }
            final tasks = taskSnap.data ?? [];
            final habits = habitSnap.data ?? [];
            final tasksDone = tasks.where((t) => t['done'] == true).length;
            final streak = DatabaseService.instance.computeStreak(habits);

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: MediaQuery.of(context).size.width < 380
                  ? 1.04
                  : 1.18,
              children: [
                DashStatCard(
                  value: '$tasksDone',
                  label: 'Tasks closed',
                  sublabel: 'All time',
                  icon: LucideIcons.checkCircle,
                  color: AppTheme.intelligence,
                ),
                DashStatCard(
                  value: '${focusMinutes}m',
                  label: 'Focus today',
                  sublabel: 'Deep work',
                  icon: LucideIcons.timer,
                  color: AppTheme.primary,
                ),
                DashStatCard(
                  value: '$streak',
                  label: 'Day streak',
                  sublabel: 'Consistency',
                  icon: LucideIcons.flame,
                  color: AppTheme.warning,
                ),
                DashStatCard(
                  value: '${habits.length}',
                  label: 'Active habits',
                  sublabel: 'Tracking',
                  icon: LucideIcons.activity,
                  color: AppTheme.success,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
