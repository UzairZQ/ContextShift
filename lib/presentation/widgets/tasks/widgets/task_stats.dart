import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';

class TaskStats extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>>? stream;

  const TaskStats({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
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
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primary,
                ),
                minHeight: 6,
              ),
            ),
          ],
        );
      },
    );
  }
}
