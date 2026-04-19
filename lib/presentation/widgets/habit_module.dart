import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../core/firebase_service.dart';
import '../../core/responsive.dart';

class HabitModule extends StatefulWidget {
  const HabitModule({super.key});

  @override
  State<HabitModule> createState() => _HabitModuleState();
}

class _HabitModuleState extends State<HabitModule> {
  Stream<List<Map<String, dynamic>>>? _habitsStream;
  final _nameController = TextEditingController();

  static const _icons = ['🧘', '💪', '📚', '💧', '🏃', '🌙', '✍️', '🥗'];

  @override
  void initState() {
    super.initState();
    _habitsStream = FirebaseService.instance.watchHabits();
    FirebaseService.instance.logEvent(eventType: 'screen_open', module: 'habits');
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

  void _showAddHabitSheet() {
    String selectedIcon = _icons[0];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: ResponsiveWrapper(
            maxWidth: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Habit', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _icons.map((icon) => GestureDetector(
                    onTap: () => setSheetState(() => selectedIcon = icon),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedIcon == icon
                            ? AppTheme.primary.withValues(alpha: 0.2)
                            : AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedIcon == icon ? AppTheme.primary : Colors.transparent,
                        ),
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 22)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Habit name (e.g. Morning Run)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;
                      _nameController.clear();
                      await FirebaseService.instance.addHabit(name: name, icon: selectedIcon);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Add Habit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
              onPressed: _showAddHabitSheet,
              icon: const Icon(LucideIcons.plus, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildHabitContent(),
      ],
    );
  }

  Widget _buildHabitContent() {
    final today = _todayString();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _habitsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
            ),
          );
        }
        final habits = snapshot.data ?? [];
        if (habits.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.activity, color: Colors.white24, size: 48),
                  const SizedBox(height: 12),
                  const Text('No habits yet', style: TextStyle(color: Colors.white38)),
                  const SizedBox(height: 6),
                  const Text('Tap + to track your first habit',
                      style: TextStyle(color: Colors.white24, fontSize: 13)),
                ],
              ),
            ),
          );
        }
        final doneCount = habits.where((h) {
          final completedDates = (h['completedDates'] as List<dynamic>?) ?? [];
          return completedDates.contains(today);
        }).length;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              _HabitHeatmap(habits: habits),
              // Progress bar
              Container(
                margin: const EdgeInsets.only(bottom: 20, top: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Today's progress", style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('$doneCount / ${habits.length}',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: habits.isEmpty ? 0 : doneCount / habits.length,
                        backgroundColor: AppTheme.surface,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 550) {
                    // iPad / Tablet Grid Layout
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: 100, // Fixed height for habit tiles in grid
                      ),
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final h = habits[index];
                        final completedDates = (h['completedDates'] as List<dynamic>?) ?? [];
                        final isDone = completedDates.contains(today);
                        return _HabitTile(
                          habit: h,
                          isDoneToday: isDone,
                          onToggle: (val) => FirebaseService.instance.toggleHabitToday(h['id'], val),
                        );
                      },
                    );
                  }
                  
                  // Mobile List Layout
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final h = habits[index];
                      final completedDates = (h['completedDates'] as List<dynamic>?) ?? [];
                      final isDone = completedDates.contains(today);
                      return _HabitTile(
                        habit: h,
                        isDoneToday: isDone,
                        onToggle: (val) => FirebaseService.instance.toggleHabitToday(h['id'], val),
                      );
                    },
                  );
                },
              ),
            ],
        );
      },
    );
  }
}

class _HabitTile extends StatelessWidget {
  final Map<String, dynamic> habit;
  final bool isDoneToday;
  final ValueChanged<bool> onToggle;

  const _HabitTile({
    required this.habit,
    required this.isDoneToday,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!isDoneToday),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDoneToday
              ? Colors.green.withValues(alpha: 0.1)
              : AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDoneToday
                ? Colors.green.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Text(habit['icon'] ?? '✅', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    habit['name'] ?? '',
                    style: TextStyle(
                      color: isDoneToday ? Colors.white60 : Colors.white,
                      fontSize: 15,
                      decoration: isDoneToday ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.white38,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _buildMiniHeatmap(),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDoneToday ? Colors.green.withValues(alpha: 0.25) : Colors.transparent,
                border: Border.all(
                  color: isDoneToday ? Colors.green : Colors.white24,
                  width: 2,
                ),
              ),
              child: isDoneToday
                  ? const Icon(LucideIcons.check, color: Colors.green, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniHeatmap() {
    final now = DateTime.now();
    final completedDates = (habit['completedDates'] as List<dynamic>?) ?? [];
    
    return Row(
      children: List.generate(7, (index) {
        final day = now.subtract(Duration(days: 6 - index));
        final dayStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final isCompleted = completedDates.contains(dayStr);
        
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted 
                ? AppTheme.primary 
                : Colors.white.withValues(alpha: 0.1),
            border: isCompleted ? null : Border.all(color: Colors.white10),
          ),
        );
      }),
    );
  }
}

class _HabitHeatmap extends StatelessWidget {
  final List<Map<String, dynamic>> habits;

  const _HabitHeatmap({required this.habits});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final Map<String, int> dailyCounts = {};

    for (var h in habits) {
      final dates = (h['completedDates'] as List<dynamic>?) ?? [];
      for (var d in dates) {
        if (d is String) {
          dailyCounts[d] = (dailyCounts[d] ?? 0) + 1;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Activity History", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              Text("Last 28 Days", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 4.0;
              final boxSize = (constraints.maxWidth - (27 * spacing)) / 28;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(28, (index) {
                  final day = now.subtract(Duration(days: 27 - index));
                  final dayStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final count = dailyCounts[dayStr] ?? 0;
                  
                  double opacity = 0.05;
                  if (count > 0) {
                    opacity = 0.2 + (count / habits.length * 0.8);
                    if (opacity > 1.0) opacity = 1.0;
                  }

                  return Container(
                    width: boxSize.clamp(4, 12),
                    height: boxSize.clamp(4, 12),
                    decoration: BoxDecoration(
                      color: count > 0 ? AppTheme.primary.withValues(alpha: opacity) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: count > 0 ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: opacity * 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ] : null,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
