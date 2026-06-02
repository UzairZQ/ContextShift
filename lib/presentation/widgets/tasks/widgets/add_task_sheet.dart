import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/firebase_service.dart';

class AddTaskSheet extends StatefulWidget {
  final String? initialTitle;
  final String? initialPriority;
  final List<String>? initialSubtasks;

  const AddTaskSheet({
    super.key,
    this.initialTitle,
    this.initialPriority,
    this.initialSubtasks,
  });

  static void show(
    BuildContext context, {
    String? initialTitle,
    String? initialPriority,
    List<String>? initialSubtasks,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddTaskSheet(
        initialTitle: initialTitle,
        initialPriority: initialPriority,
        initialSubtasks: initialSubtasks,
      ),
    );
  }

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  static const List<String> _priorities = ['normal', 'medium', 'high'];

  late final TextEditingController _titleController;
  late final TextEditingController _subtaskController;
  late String _priority;
  late List<String> _subtasks;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _subtaskController = TextEditingController();
    _priority = widget.initialPriority ?? 'normal';
    _subtasks = List<String>.from(widget.initialSubtasks ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _addSubtask(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _subtasks.add(trimmed);
      _subtaskController.clear();
    });
  }

  Color _priorityColor(String p) {
    if (p == 'high') return AppTheme.primary;
    if (p == 'medium') return Colors.amber;
    return Colors.blue;
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    await FirebaseService.instance.addTask(
      title: title,
      priority: _priority,
      subtasks: _subtasks
          .map((s) => {'title': s, 'completed': false})
          .toList(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (ctx, setSheetState) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Task',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
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
              const Text(
                'Priority',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final isSelected = _priority == p;
                  final pColor = _priorityColor(p);
                  return GestureDetector(
                    onTap: () => setSheetState(() => _priority = p),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? pColor.withValues(alpha: 0.2)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? pColor : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        p.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? pColor : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Subtasks',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ..._subtasks.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.cornerDownRight,
                        size: 12,
                        color: Colors.white24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Add a subtask...',
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _addSubtask,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _addSubtask(_subtaskController.text),
                    icon: const Icon(
                      LucideIcons.plusCircle,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Task',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
