import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';
import '../../shared/module_cards.dart';

class TaskItem extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskItem({super.key, required this.task});

  Color get _priorityColor {
    final priority = task['priority'] as String? ?? 'normal';
    if (priority == 'urgent') return AppTheme.error;
    if (priority == 'high') return AppTheme.primary;
    return AppTheme.onSurfaceVariant;
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove task?'),
        content: const Text(
          'This task will be removed from Active Intentions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return false;

    try {
      await DatabaseService.instance.deleteTask(task['id']);
      if (!context.mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task removed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('[TaskItem] Delete failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not remove task. Try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _toggle(BuildContext context, bool isDone) async {
    try {
      await DatabaseService.instance.toggleTask(task['id'], !isDone);
    } catch (error, stackTrace) {
      debugPrint('[TaskItem] Toggle failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update task. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task['done'] as bool? ?? false;
    final pColor = _priorityColor;
    final title = task['title']?.toString().trim();
    final due = (task['due'] as String? ?? '').trim();
    final subtasks = task['subtasks'] is List
        ? task['subtasks'] as List<dynamic>
        : const <dynamic>[];
    final firstSubtask = subtasks.whereType<Map>().isEmpty
        ? ''
        : (subtasks.whereType<Map>().first['title']?.toString() ?? '').trim();

    return Dismissible(
      key: ValueKey('task-${task['id']}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      child: Container(
        decoration: moduleCardDecoration(
          accent: pColor,
          borderRadius: 16,
          fill: AppTheme.surfaceHighest.withValues(alpha: 0.3),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            onLongPress: () => _confirmDelete(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: GestureDetector(
              onTap: () => _toggle(context, isDone),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDone ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDone
                        ? AppTheme.primary
                        : AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(
                        LucideIcons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title == null || title.isEmpty ? 'Untitled task' : title,
                  style: TextStyle(
                    color: isDone
                        ? AppTheme.onSurfaceVariant.withValues(alpha: 0.5)
                        : AppTheme.onSurface,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (due.isNotEmpty && due != 'Today' || firstSubtask.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      [
                        if (due.isNotEmpty && due != 'Today') due,
                        if (firstSubtask.isNotEmpty) firstSubtask,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant.withValues(
                          alpha: 0.62,
                        ),
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ),
              ],
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
        ),
      ),
    );
  }
}
