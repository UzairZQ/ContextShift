import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import 'task_item.dart';

class TaskList extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>>? stream;

  const TaskList({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No pending tasks. Your day has breathing room.',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
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
          itemBuilder: (context, index) => TaskItem(task: tasks[index]),
        );
      },
    );
  }
}
