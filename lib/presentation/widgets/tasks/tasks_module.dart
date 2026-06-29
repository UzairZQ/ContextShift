import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_spacing.dart';
import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../motion/wonderous_motion.dart';
import 'widgets/add_task_sheet.dart';
import 'widgets/task_list.dart';
import 'widgets/task_stats.dart';

class TasksModule extends StatefulWidget {
  const TasksModule({super.key});

  static void showAddTaskSheet(
    BuildContext context, {
    String? initialTitle,
    String? initialPriority,
    List<String>? initialSubtasks,
  }) => AddTaskSheet.show(
    context,
    initialTitle: initialTitle,
    initialPriority: initialPriority,
    initialSubtasks: initialSubtasks,
  );

  @override
  State<TasksModule> createState() => _TasksModuleState();
}

class _TasksModuleState extends State<TasksModule> {
  Stream<List<Map<String, dynamic>>>? _tasksStream;

  @override
  void initState() {
    super.initState();
    _tasksStream = DatabaseService.instance.watchTasks();
    DatabaseService.instance.logEvent(
      eventType: 'screen_open',
      module: 'tasks',
    );
  }

  void _openAddTaskSheet() {
    AddTaskSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.lg),
          Container(
            width: double.infinity,
            decoration: AppTheme.cardDecoration(
              color: AppTheme.surfaceContainer.withValues(alpha: 0.6),
            ),
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WonderousReveal(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.checkSquare,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Active Intentions',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _openAddTaskSheet,
                        icon: const Icon(
                          LucideIcons.plus,
                          color: AppTheme.primary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                WonderousReveal(
                  delay: const Duration(milliseconds: 80),
                  child: TaskStats(stream: _tasksStream),
                ),
                const SizedBox(height: 20),
                WonderousReveal(
                  delay: const Duration(milliseconds: 140),
                  child: TaskList(stream: _tasksStream),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 92),
        ],
      ),
    );
  }
}
