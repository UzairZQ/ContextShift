import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../core/firebase_service.dart';

class TasksModule extends StatefulWidget {
  const TasksModule({super.key});

  @override
  State<TasksModule> createState() => _TasksModuleState();
}

class _TasksModuleState extends State<TasksModule> {
  final _newTaskController = TextEditingController();
  Stream<List<Map<String, dynamic>>>? _tasksStream;

  @override
  void initState() {
    super.initState();
    _tasksStream = FirebaseService.instance.watchTasks();
    FirebaseService.instance.logEvent(eventType: 'screen_open', module: 'tasks');
  }

  @override
  void dispose() {
    _newTaskController.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final title = _newTaskController.text.trim();
    if (title.isEmpty) return;
    _newTaskController.clear();
    await FirebaseService.instance.addTask(title: title);
  }

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
              controller: _newTaskController,
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
              onSubmitted: (_) {
                _addTask();
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  _addTask();
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tasks', style: Theme.of(context).textTheme.headlineMedium),
            IconButton.filled(
              onPressed: _showAddTaskSheet,
              icon: const Icon(LucideIcons.plus, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTasksContent(),
      ],
    );
  }

  Widget _buildTasksContent() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _tasksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
            ),
          );
        }
        final tasks = snapshot.data ?? [];
        if (tasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.checkSquare, color: Colors.white24, size: 48),
                  const SizedBox(height: 12),
                  const Text('No tasks yet', style: TextStyle(color: Colors.white38)),
                  const SizedBox(height: 6),
                  const Text('Tap + to add your first task',
                      style: TextStyle(color: Colors.white24, fontSize: 13)),
                ],
              ),
            ),
          );
        }
        final done = tasks.where((t) => t['done'] == true).toList();
        final pending = tasks.where((t) => t['done'] != true).toList();
        return Column(
          children: [
            ...pending.map((t) => _TaskTile(task: t)),
            if (done.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Completed (${done.length})',
                    style: const TextStyle(color: Colors.white38, fontSize: 13)),
              ),
              ...done.map((t) => _TaskTile(task: t, isDimmed: true)),
            ]
          ],
        );
      },
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Map<String, dynamic> task;
  final bool isDimmed;

  const _TaskTile({required this.task, this.isDimmed = false});

  @override
  Widget build(BuildContext context) {
    final isDone = task['done'] == true;
    final isHighPriority = task['priority'] == 'high';

    return Dismissible(
      key: Key(task['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.red),
      ),
      onDismissed: (_) => FirebaseService.instance.deleteTask(task['id']),
      child: GestureDetector(
        onTap: () => FirebaseService.instance.toggleTask(task['id'], !isDone),
        child: AnimatedOpacity(
          opacity: isDimmed ? 0.5 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHighPriority && !isDone
                    ? AppTheme.primary.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                    border: Border.all(
                      color: isDone ? AppTheme.primary : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(LucideIcons.check, color: AppTheme.primary, size: 12)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'] ?? '',
                        style: TextStyle(
                          color: isDone ? Colors.white38 : Colors.white,
                          fontSize: 15,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.white38,
                        ),
                      ),
                      if (task['due'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (isHighPriority) ...[
                                const Icon(LucideIcons.flame, color: AppTheme.primary, size: 12),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                task['due'],
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
