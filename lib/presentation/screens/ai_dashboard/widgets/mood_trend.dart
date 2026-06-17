import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';

class MoodTrend extends StatelessWidget {
  const MoodTrend({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mood Trend',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService.instance.watchMoods(days: 7),
          builder: (context, snapshot) {
            final moods = snapshot.data ?? [];

            if (moods.isEmpty) {
              return const _EmptyMood();
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration:
                  AppTheme.cardDecoration(color: AppTheme.surfaceContainer),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: moods.reversed.take(7).map((m) {
                  final mood = m['mood'] as String? ?? '😐';
                  final date = m['date'] as String? ?? '';
                  final dayPart = date.length >= 10 ? date.substring(8) : '';

                  return Column(
                    children: [
                      Text(mood, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(
                        dayPart,
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyMood extends StatelessWidget {
  const _EmptyMood();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration(color: AppTheme.surfaceContainer),
      child: Text(
        'No mood data yet.\nLog your mood from the home screen.',
        style: TextStyle(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontSize: 14,
        ),
      ),
    );
  }
}
