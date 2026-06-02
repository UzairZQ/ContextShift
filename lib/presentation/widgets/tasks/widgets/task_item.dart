import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/firebase_service.dart';

class TaskItem extends StatelessWidget {
  final Map<String, dynamic> task;

  const TaskItem({super.key, required this.task});

  Color get _priorityColor {
    final priority = task['priority'] as String? ?? 'normal';
    if (priority == 'urgent') return AppTheme.error;
    if (priority == 'high') return AppTheme.primary;
    return AppTheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final isDone = task['done'] as bool? ?? false;
    final pColor = _priorityColor;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.05),
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
                color: isDone
                    ? AppTheme.primary
                    : AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
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
            color: isDone
                ? AppTheme.onSurfaceVariant.withValues(alpha: 0.5)
                : AppTheme.onSurface,
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
