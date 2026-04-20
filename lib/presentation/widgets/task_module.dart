import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../core/firebase_service.dart';

class TasksModule extends StatefulWidget {
  const TasksModule({super.key});

  @override
  State<TasksModule> createState() => _TasksModuleState();

  static void showAddTaskSheet(BuildContext context, {String? initialTitle, String? initialPriority, List<String>? initialSubtasks}) {
    String priority = initialPriority ?? 'normal';
    final newTaskController = TextEditingController(text: initialTitle);
    final subtaskController = TextEditingController();
    List<String> subtasks = initialSubtasks ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Task', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: newTaskController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Priority', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: ['normal', 'medium', 'high'].map((p) {
                  final isSelected = priority == p;
                  Color pColor = p == 'high' ? AppTheme.primary : (p == 'medium' ? Colors.amber : Colors.blue);
                  return GestureDetector(
                    onTap: () => setSheetState(() => priority = p),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? pColor.withValues(alpha: 0.2) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? pColor : Colors.transparent),
                      ),
                      child: Text(
                        p.toUpperCase(),
                        style: TextStyle(color: isSelected ? pColor : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Subtasks', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              ...subtasks.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(LucideIcons.cornerDownRight, size: 12, color: Colors.white24),
                    const SizedBox(width: 8),
                    Text(s, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              )),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: subtaskController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Add a subtask...',
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isEmpty) return;
                        setSheetState(() {
                          subtasks.add(val.trim());
                          subtaskController.clear();
                        });
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (subtaskController.text.trim().isEmpty) return;
                      setSheetState(() {
                        subtasks.add(subtaskController.text.trim());
                        subtaskController.clear();
                      });
                    },
                    icon: const Icon(LucideIcons.plusCircle, size: 18, color: AppTheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final title = newTaskController.text.trim();
                    if (title.isEmpty) return;
                    
                    // Map String subtasks to Map structure expected by FirebaseService
                    final mappedSubtasks = subtasks.map((s) => {'title': s, 'completed': false}).toList();
                    
                    await FirebaseService.instance.addTask(
                      title: title,
                      priority: priority,
                      subtasks: mappedSubtasks,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TasksModuleState extends State<TasksModule> {
  Stream<List<Map<String, dynamic>>>? _tasksStream;

  @override
  void initState() {
    super.initState();
    _tasksStream = FirebaseService.instance.watchTasks();
    FirebaseService.instance.logEvent(eventType: 'screen_open', module: 'tasks');
  }

  void _showAddTaskSheet() {
    TasksModule.showAddTaskSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.6),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.checkSquare, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Active Intentions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _showAddTaskSheet,
                icon: const Icon(LucideIcons.plus, color: AppTheme.primary),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTaskStats(),
          const SizedBox(height: 20),
          _buildTaskList(),
        ],
      ),
    );
  }

  Widget _buildTaskStats() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final tasks = snapshot.data!;
        final done = tasks.where((t) => t['done'] == true).length;
        final total = tasks.length;
        final progress = total == 0 ? 0.0 : done / total;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$done of $total missions completed',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.surfaceHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 6,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No pending missions. JARVIS is proud.',
                style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
              ),
            ),
          );
        }

        final tasks = snapshot.data!;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tasks.length > 5 ? 5 : tasks.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _TaskItem(task: tasks[index]),
        );
      },
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Map<String, dynamic> task;

  const _TaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDone = task['done'] as bool? ?? false;
    final priority = task['priority'] as String? ?? 'normal';
    final pColor = priority == 'urgent' ? AppTheme.error : (priority == 'high' ? AppTheme.primary : AppTheme.onSurfaceVariant);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? Colors.transparent : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: GestureDetector(
          onTap: () => FirebaseService.instance.toggleTask(task['id'], !isDone),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isDone ? AppTheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDone ? AppTheme.primary : AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: isDone
                ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                : null,
          ),
        ),
        title: Text(
          task['title'],
          style: TextStyle(
            color: isDone ? AppTheme.onSurfaceVariant.withValues(alpha: 0.5) : AppTheme.onSurface,
            decoration: isDone ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: pColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
