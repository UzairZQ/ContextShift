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


  void _showAddTaskSheet() {
    String priority = 'normal';
    final subtaskController = TextEditingController();
    List<String> subtasks = [];

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
                    final title = _newTaskController.text.trim();
                    if (title.isEmpty) return;
                    await FirebaseService.instance.addTask(
                      title: title,
                      priority: priority,
                      subtasks: subtasks.map((s) => {'title': s, 'done': false}).toList(),
                    );
                    _newTaskController.clear();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Add Task'),
                ),
              ),
            ],
          ),
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
    final priority = task['priority'] ?? 'normal';
    final subtasks = (task['subtasks'] as List<dynamic>?) ?? [];

    Color priorityColor;
    if (priority == 'high') {
      priorityColor = AppTheme.primary;
    } else if (priority == 'medium') {
      priorityColor = Colors.amber;
    } else {
      priorityColor = Colors.blue;
    }

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
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: priority == 'high' && !isDone
                ? AppTheme.primary.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            ListTile(
              onTap: () => FirebaseService.instance.toggleTask(task['id'], !isDone),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: _buildCheckbox(isDone),
              title: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: priorityColor,
                      boxShadow: [
                        BoxShadow(
                          color: priorityColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task['title'] ?? '',
                      style: TextStyle(
                        color: isDone ? Colors.white38 : Colors.white,
                        fontSize: 15,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.white38,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: task['due'] != null ? Padding(
                padding: const EdgeInsets.only(top: 4, left: 16),
                child: Text(task['due'], style: const TextStyle(color: Colors.white24, fontSize: 11)),
              ) : null,
            ),
            if (subtasks.isNotEmpty && !isDone)
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 16, bottom: 12),
                child: Column(
                  children: List.generate(subtasks.length, (idx) {
                    final sub = subtasks[idx];
                    final subDone = sub['done'] == true;
                    return GestureDetector(
                      onTap: () {
                        final newSubtasks = List<Map<String, dynamic>>.from(
                          subtasks.map((s) => Map<String, dynamic>.from(s))
                        );
                        newSubtasks[idx]['done'] = !subDone;
                        FirebaseService.instance.updateTask(task['id'], {'subtasks': newSubtasks});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              subDone ? LucideIcons.checkSquare : LucideIcons.square,
                              size: 14,
                              color: subDone ? AppTheme.primary : Colors.white24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                sub['title'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subDone ? Colors.white24 : Colors.white60,
                                  decoration: subDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isDone) {
    return AnimatedContainer(
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
    );
  }
}
