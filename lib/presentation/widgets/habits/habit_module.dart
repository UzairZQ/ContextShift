import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../motion/wonderous_motion.dart';
import '../shared/module_cards.dart';
import 'widgets/add_habit_sheet.dart';
import 'widgets/habit_heatmap.dart';
import 'widgets/habit_progress.dart';
import 'widgets/habit_tile.dart';

class HabitModule extends StatefulWidget {
  const HabitModule({super.key});

  @override
  State<HabitModule> createState() => _HabitModuleState();
}

class _HabitModuleState extends State<HabitModule> {
  Stream<List<Map<String, dynamic>>>? _habitsStream;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _habitsStream = DatabaseService.instance.watchHabits();
    DatabaseService.instance.logEvent(
      eventType: 'screen_open',
      module: 'habits',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _openAddHabitSheet() {
    AddHabitSheet.show(context, nameController: _nameController);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        WonderousReveal(
          child: ModuleHeaderCard(
            title: 'Habits',
            subtitle: 'Build what helps. Protect what matters.',
            icon: LucideIcons.activity,
            accent: AppTheme.success,
            trailing: IconButton(
              tooltip: 'Add habit',
              onPressed: _openAddHabitSheet,
              icon: const Icon(LucideIcons.plus, color: AppTheme.success),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.success.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        WonderousReveal(
          delay: const Duration(milliseconds: 80),
          child: _HabitContent(
            stream: _habitsStream,
            today: DatabaseService.todayKey(),
          ),
        ),
      ],
    );
  }
}

class _HabitContent extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>>? stream;
  final String today;

  const _HabitContent({required this.stream, required this.today});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2,
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Behaviors are temporarily unavailable. Pull to try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          );
        }
        final habits = snapshot.data ?? [];
        if (habits.isEmpty) {
          return const _HabitsEmptyState();
        }

        final buildHabits = habits
            .where((h) => (h['kind'] ?? 'build') != 'reduce')
            .toList();
        final reduceHabits = habits
            .where((h) => h['kind'] == 'reduce')
            .toList();
        final doneCount = buildHabits.where((h) {
          final completedDates = (h['completedDates'] as List<dynamic>?) ?? [];
          return completedDates.contains(today);
        }).length;
        final protectedCount = reduceHabits.where((h) {
          final completedDates = (h['completedDates'] as List<dynamic>?) ?? [];
          return completedDates.contains(today);
        }).length;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WonderousReveal(
              delay: const Duration(milliseconds: 80),
              child: HabitHeatmap(habits: habits),
            ),
            WonderousReveal(
              delay: const Duration(milliseconds: 140),
              child: HabitProgress(
                doneCount: doneCount,
                buildTotal: buildHabits.length,
                protectedCount: protectedCount,
                reduceTotal: reduceHabits.length,
              ),
            ),
            WonderousReveal(
              delay: const Duration(milliseconds: 200),
              child: _HabitGrid(habits: habits, today: today),
            ),
          ],
        );
      },
    );
  }
}

class _HabitGrid extends StatelessWidget {
  final List<Map<String, dynamic>> habits;
  final String today;

  const _HabitGrid({required this.habits, required this.today});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 550;
        Widget itemBuilder(Map<String, dynamic> h) {
          final completedDates = (h['completedDates'] as List<dynamic>?) ?? [];
          final isDone = completedDates.contains(today);
          return HabitTile(
            habit: h,
            isDoneToday: isDone,
            onToggle: (val) => _toggleHabit(context, h['id'], val),
          );
        }

        if (isWide) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 148,
            ),
            itemCount: habits.length,
            itemBuilder: (context, index) => itemBuilder(habits[index]),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: habits.length,
          itemBuilder: (context, index) => itemBuilder(habits[index]),
        );
      },
    );
  }

  Future<void> _toggleHabit(
    BuildContext context,
    dynamic habitId,
    bool value,
  ) async {
    try {
      await DatabaseService.instance.toggleHabitToday(habitId, value);
    } catch (error, stackTrace) {
      debugPrint('[HabitModule] Toggle failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update behavior. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _HabitsEmptyState extends StatelessWidget {
  const _HabitsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.activity, color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No habits yet',
              style: TextStyle(color: Colors.white38),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap + to track your first habit',
              style: TextStyle(color: Colors.white24, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
