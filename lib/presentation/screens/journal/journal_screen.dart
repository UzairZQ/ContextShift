import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/app_spacing.dart';
import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../widgets/motion/wonderous_motion.dart';
import '../../widgets/notes/notes_module.dart';
import '../home/widgets/mood_checkin.dart';

class JournalScreen extends StatelessWidget {
  final String? todayMood;
  final ValueChanged<String> onSelectMood;

  const JournalScreen({
    super.key,
    required this.todayMood,
    required this.onSelectMood,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          WonderousReveal(child: _JournalHeader(todayMood: todayMood)),
          const SizedBox(height: 16),
          WonderousReveal(
            delay: const Duration(milliseconds: 80),
            child: MoodCheckIn(selectedMood: todayMood, onSelect: onSelectMood),
          ),
          const SizedBox(height: 16),
          WonderousReveal(
            delay: const Duration(milliseconds: 140),
            child: const _RecentMoodStrip(),
          ),
          const SizedBox(height: 8),
          WonderousReveal(
            delay: const Duration(milliseconds: 200),
            child: const NotesModule(),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 92),
        ],
      ),
    );
  }
}

class _JournalHeader extends StatelessWidget {
  final String? todayMood;

  const _JournalHeader({required this.todayMood});

  @override
  Widget build(BuildContext context) {
    return CinematicFloat(
      travel: const Offset(0, -4),
      scaleDelta: 0.006,
      child: PointerTilt(
        maxTilt: 0.032,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surfaceContainer.withValues(alpha: 0.9),
                AppTheme.surfaceHigh.withValues(alpha: 0.74),
                AppTheme.warning.withValues(alpha: 0.18),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.warning.withValues(alpha: 0.14),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Row(
            children: [
              CinematicPulse(
                minScale: 0.94,
                maxScale: 1.1,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.warning.withValues(alpha: 0.2),
                    border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.34),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.warning.withValues(alpha: 0.22),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.bookOpen,
                    color: AppTheme.warning,
                    size: 25,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Journal',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      todayMood == null
                          ? 'Log the day, save the useful pieces.'
                          : 'Mood logged. Keep the thread of today.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant.withValues(
                          alpha: 0.78,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentMoodStrip extends StatelessWidget {
  const _RecentMoodStrip();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService.instance.watchMoods(days: 7),
      builder: (context, snapshot) {
        final moods = snapshot.data ?? const <Map<String, dynamic>>[];
        if (moods.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Text(
                'Last check-ins',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              ...moods
                  .take(5)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        entry['mood'] as String? ?? '•',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
