import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
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

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Habits', style: Theme.of(context).textTheme.headlineMedium),
            IconButton.filled(
              onPressed: _openAddHabitSheet,
              icon: const Icon(LucideIcons.plus, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _HabitContent(stream: _habitsStream, today: _todayString()),
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
        final habits = snapshot.data ?? [];
        if (habits.isEmpty) {
          return const _HabitsEmptyState();
        }

        final doneCount = habits.where((h) {
          final completedDates = (h['completedDates'] as List<dynamic>?) ?? [];
          return completedDates.contains(today);
        }).length;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HabitHeatmap(habits: habits),
            HabitProgress(doneCount: doneCount, total: habits.length),
            _HabitGrid(habits: habits, today: today),
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
            onToggle: (val) =>
                DatabaseService.instance.toggleHabitToday(h['id'], val),
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
              mainAxisExtent: 100,
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
