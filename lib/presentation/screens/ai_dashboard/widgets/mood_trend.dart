import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';
import '../../../shared/context_shift_primitives.dart';

class MoodTrend extends StatelessWidget {
  const MoodTrend({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService.instance.watchMoods(days: 7),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const ContextPanel(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Mood history is temporarily unavailable.',
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              );
            }
            final moods = snapshot.data ?? [];

            if (moods.isEmpty) {
              return const _EmptyMood();
            }

            return ContextPanel(
              padding: const EdgeInsets.all(20),
              accent: AppTheme.primary,
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
                          color: AppTheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
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
    return const ContextPanel(
      padding: EdgeInsets.all(24),
      child: Text(
        'No mood context yet.\nLog it once and your daily read gets sharper.',
        style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
      ),
    );
  }
}
