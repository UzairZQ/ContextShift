import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/responsive.dart';
import '../../../widgets/generative_card_module.dart';
import '../../../widgets/motion/wonderous_motion.dart';
import 'ai_command_bar.dart';
import 'ai_insight_card.dart';
import 'ai_response_card.dart';
import 'home_header.dart';
import 'thinking_card.dart';

class HomeTab extends StatelessWidget {
  final String greeting;
  final TextEditingController commandController;
  final bool isJarvisOnline;
  final bool hasCheckedJarvisStatus;
  final bool isProcessingCommand;
  final String offlineHint;
  final String? aiResponse;
  final Animation<double> responseAnimation;
  final bool isLoadingInsight;
  final String? aiInsight;
  final int focusMinutesToday;
  final String? todayMood;
  final Map<String, dynamic>? generativeCardPayload;
  final VoidCallback onOpenDashboard;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenHabits;
  final VoidCallback onOpenFocus;
  final VoidCallback onOpenJournal;
  final VoidCallback onGenerativeCardAction;
  final ValueChanged<String> onSubmitCommand;
  final ValueChanged<String> onSelectMood;
  final VoidCallback onDismissResponse;

  const HomeTab({
    super.key,
    required this.greeting,
    required this.commandController,
    required this.isJarvisOnline,
    required this.hasCheckedJarvisStatus,
    required this.isProcessingCommand,
    required this.offlineHint,
    required this.aiResponse,
    required this.responseAnimation,
    required this.isLoadingInsight,
    required this.aiInsight,
    required this.focusMinutesToday,
    required this.todayMood,
    required this.generativeCardPayload,
    required this.onOpenDashboard,
    required this.onOpenProfile,
    required this.onOpenChat,
    required this.onOpenTasks,
    required this.onOpenHabits,
    required this.onOpenFocus,
    required this.onOpenJournal,
    required this.onGenerativeCardAction,
    required this.onSubmitCommand,
    required this.onSelectMood,
    required this.onDismissResponse,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeHeader(
            isProcessingCommand: isProcessingCommand,
            isJarvisOnline: isJarvisOnline,
            onOpenDashboard: onOpenDashboard,
            onOpenProfile: onOpenProfile,
          ),
          const SizedBox(height: 14),
          WonderousReveal(
            begin: const Offset(0, 0.04),
            child: _HeroCommandPanel(
              greeting: greeting,
              commandController: commandController,
              isJarvisOnline: isJarvisOnline,
              hasCheckedJarvisStatus: hasCheckedJarvisStatus,
              isProcessingCommand: isProcessingCommand,
              offlineHint: offlineHint,
              onSubmitCommand: onSubmitCommand,
              onOpenChat: onOpenChat,
            ),
          ),
          const SizedBox(height: 14),
          if (aiResponse != null)
            AiResponseCard(
              animation: responseAnimation,
              message: aiResponse!,
              onDismiss: onDismissResponse,
            ),
          if (isProcessingCommand) const ThinkingCard(),
          _HomeSnapshotBuilder(
            focusMinutesToday: focusMinutesToday,
            todayMood: todayMood,
            onOpenTasks: onOpenTasks,
            onOpenHabits: onOpenHabits,
            onOpenFocus: onOpenFocus,
            onOpenJournal: onOpenJournal,
            onSelectMood: onSelectMood,
          ),
          if (generativeCardPayload != null) ...[
            const SizedBox(height: 14),
            WonderousReveal(
              delay: const Duration(milliseconds: 120),
              child: GenerativeCardModule(
                cardData: generativeCardPayload!,
                onAction: onGenerativeCardAction,
              ),
            ),
          ],
          const SizedBox(height: 14),
          WonderousReveal(
            delay: const Duration(milliseconds: 160),
            child: AiInsightCard(
              insight: aiInsight,
              isLoading: isLoadingInsight,
              onTap: onOpenDashboard,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 92),
        ],
      ),
    );
  }
}

class _HeroCommandPanel extends StatelessWidget {
  final String greeting;
  final TextEditingController commandController;
  final bool isJarvisOnline;
  final bool hasCheckedJarvisStatus;
  final bool isProcessingCommand;
  final String offlineHint;
  final ValueChanged<String> onSubmitCommand;
  final VoidCallback onOpenChat;

  const _HeroCommandPanel({
    required this.greeting,
    required this.commandController,
    required this.isJarvisOnline,
    required this.hasCheckedJarvisStatus,
    required this.isProcessingCommand,
    required this.offlineHint,
    required this.onSubmitCommand,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceContainer.withValues(alpha: 0.92),
            AppTheme.surfaceHigh.withValues(alpha: 0.72),
            AppTheme.primary.withValues(alpha: 0.18),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.14),
            blurRadius: 42,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -46,
            top: -42,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.18),
                    AppTheme.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -70,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.tertiary.withValues(alpha: 0.1),
                    AppTheme.tertiary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        greeting,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.16,
                              fontSize: Responsive.isMobile(context) ? 22 : 28,
                              letterSpacing: -0.55,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusPill(isOnline: isJarvisOnline),
                ],
              ),
              const SizedBox(height: 16),
              AiCommandBar(
                controller: commandController,
                isOnline: isJarvisOnline,
                isProcessing: isProcessingCommand,
                hasCheckedStatus: hasCheckedJarvisStatus,
                offlineHint: offlineHint,
                onSubmit: onSubmitCommand,
                onTap: onOpenChat,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isOnline;

  const _StatusPill({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: (isOnline ? AppTheme.success : AppTheme.warning).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (isOnline ? AppTheme.success : AppTheme.warning).withValues(
            alpha: 0.24,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? LucideIcons.zap : LucideIcons.wifiOff,
            size: 13,
            color: isOnline ? AppTheme.success : AppTheme.warning,
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Local' : 'Setup',
            style: TextStyle(
              color: isOnline ? AppTheme.success : AppTheme.warning,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSnapshotBuilder extends StatelessWidget {
  final int focusMinutesToday;
  final String? todayMood;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenHabits;
  final VoidCallback onOpenFocus;
  final VoidCallback onOpenJournal;
  final ValueChanged<String> onSelectMood;

  const _HomeSnapshotBuilder({
    required this.focusMinutesToday,
    required this.todayMood,
    required this.onOpenTasks,
    required this.onOpenHabits,
    required this.onOpenFocus,
    required this.onOpenJournal,
    required this.onSelectMood,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService.instance.watchTasks(),
      builder: (context, taskSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService.instance.watchHabits(),
          builder: (context, habitSnap) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseService.instance.watchNotes(),
              builder: (context, noteSnap) {
                final snapshot = _TodaySnapshot.from(
                  tasks: taskSnap.data ?? const <Map<String, dynamic>>[],
                  habits: habitSnap.data ?? const <Map<String, dynamic>>[],
                  notes: noteSnap.data ?? const <Map<String, dynamic>>[],
                  focusMinutesToday: focusMinutesToday,
                  todayMood: todayMood,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 60),
                      child: _NextMoveCard(
                        snapshot: snapshot,
                        onOpenTasks: onOpenTasks,
                        onOpenHabits: onOpenHabits,
                        onOpenFocus: onOpenFocus,
                        onOpenJournal: onOpenJournal,
                      ),
                    ),
                    const SizedBox(height: 14),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 100),
                      child: _GlanceGrid(
                        snapshot: snapshot,
                        onOpenTasks: onOpenTasks,
                        onOpenHabits: onOpenHabits,
                        onOpenFocus: onOpenFocus,
                        onOpenJournal: onOpenJournal,
                      ),
                    ),
                    const SizedBox(height: 14),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 140),
                      child: _MoodMicroCheckIn(
                        selectedMood: todayMood,
                        onSelect: onSelectMood,
                        onOpenJournal: onOpenJournal,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TodaySnapshot {
  final int pendingTasks;
  final int completedTasks;
  final int totalTasks;
  final int priorityTasks;
  final int habitsDone;
  final int totalHabits;
  final int focusMinutesToday;
  final int noteCount;
  final String? todayMood;

  const _TodaySnapshot({
    required this.pendingTasks,
    required this.completedTasks,
    required this.totalTasks,
    required this.priorityTasks,
    required this.habitsDone,
    required this.totalHabits,
    required this.focusMinutesToday,
    required this.noteCount,
    required this.todayMood,
  });

  factory _TodaySnapshot.from({
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> habits,
    required List<Map<String, dynamic>> notes,
    required int focusMinutesToday,
    required String? todayMood,
  }) {
    final today = _todayString();
    final completedTasks = tasks.where((task) => task['done'] == true).length;
    final priorityTasks = tasks.where((task) {
      final done = task['done'] == true;
      final priority = task['priority'] as String? ?? 'normal';
      return !done && (priority == 'high' || priority == 'urgent');
    }).length;
    final habitsDone = habits.where((habit) {
      final dates = (habit['completedDates'] as List<dynamic>?) ?? [];
      return dates.contains(today);
    }).length;

    return _TodaySnapshot(
      pendingTasks: tasks.length - completedTasks,
      completedTasks: completedTasks,
      totalTasks: tasks.length,
      priorityTasks: priorityTasks,
      habitsDone: habitsDone,
      totalHabits: habits.length,
      focusMinutesToday: focusMinutesToday,
      noteCount: notes.length,
      todayMood: todayMood,
    );
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  double get taskProgress => totalTasks == 0 ? 0 : completedTasks / totalTasks;

  double get habitProgress => totalHabits == 0 ? 0 : habitsDone / totalHabits;

  String get nextMoveTitle {
    if (priorityTasks > 0) return 'Clear the sharp edge first';
    if (pendingTasks > 0) return 'Pick one task and make it small';
    if (totalHabits > 0 && habitsDone < totalHabits) {
      return 'Keep the streak alive';
    }
    if (focusMinutesToday < 25) return 'Protect one focus block';
    if (todayMood == null) return 'Check in before the day runs away';
    if (noteCount == 0) return 'Capture one useful thought';
    return 'You are in good shape today';
  }

  String get nextMoveBody {
    if (priorityTasks > 0) {
      return '$priorityTasks high-priority ${priorityTasks == 1 ? 'task needs' : 'tasks need'} attention. Open Tasks and finish the smallest one.';
    }
    if (pendingTasks > 0) {
      return '$pendingTasks pending ${pendingTasks == 1 ? 'task' : 'tasks'}. JARVIS can help turn one into a clean next action.';
    }
    if (totalHabits > 0 && habitsDone < totalHabits) {
      return '${totalHabits - habitsDone} habit ${totalHabits - habitsDone == 1 ? 'check' : 'checks'} left today. Tiny wins still count.';
    }
    if (focusMinutesToday < 25) {
      return 'A 25-minute session is enough to shift the whole day. Start before the context leaks.';
    }
    if (todayMood == null) {
      return 'Mood is context. Log it once and JARVIS gets better at reading the day.';
    }
    if (noteCount == 0) {
      return 'Drop one note from today. It gives future-you a thread to pull.';
    }
    return 'No obvious fire. Review your journal or ask JARVIS what to optimize next.';
  }

  IconData get nextMoveIcon {
    if (priorityTasks > 0 || pendingTasks > 0) return LucideIcons.checkSquare;
    if (totalHabits > 0 && habitsDone < totalHabits) {
      return LucideIcons.activity;
    }
    if (focusMinutesToday < 25) return LucideIcons.timer;
    if (todayMood == null || noteCount == 0) return LucideIcons.bookOpen;
    return LucideIcons.sparkles;
  }
}

class _NextMoveCard extends StatelessWidget {
  final _TodaySnapshot snapshot;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenHabits;
  final VoidCallback onOpenFocus;
  final VoidCallback onOpenJournal;

  const _NextMoveCard({
    required this.snapshot,
    required this.onOpenTasks,
    required this.onOpenHabits,
    required this.onOpenFocus,
    required this.onOpenJournal,
  });

  @override
  Widget build(BuildContext context) {
    final action = _actionForSnapshot(snapshot);

    return PressableScale(
      onTap: action.$2,
      pressedScale: 0.965,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.12),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.34),
                    blurRadius: 34,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Icon(snapshot.nextMoveIcon, color: Colors.black, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Next move',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        LucideIcons.arrowUpRight,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    snapshot.nextMoveTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    snapshot.nextMoveBody,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.78),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    action.$1,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, VoidCallback) _actionForSnapshot(_TodaySnapshot snapshot) {
    if (snapshot.priorityTasks > 0 || snapshot.pendingTasks > 0) {
      return ('Open tasks', onOpenTasks);
    }
    if (snapshot.totalHabits > 0 &&
        snapshot.habitsDone < snapshot.totalHabits) {
      return ('Open habits', onOpenHabits);
    }
    if (snapshot.focusMinutesToday < 25) return ('Start focus', onOpenFocus);
    return ('Open journal', onOpenJournal);
  }
}

class _GlanceGrid extends StatelessWidget {
  final _TodaySnapshot snapshot;
  final VoidCallback onOpenTasks;
  final VoidCallback onOpenHabits;
  final VoidCallback onOpenFocus;
  final VoidCallback onOpenJournal;

  const _GlanceGrid({
    required this.snapshot,
    required this.onOpenTasks,
    required this.onOpenHabits,
    required this.onOpenFocus,
    required this.onOpenJournal,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
      crossAxisSpacing: Spacing.md,
      mainAxisSpacing: Spacing.md,
      childAspectRatio: Responsive.isMobile(context) ? 1.26 : 1.48,
      children: [
        _GlanceCard(
          label: 'Tasks',
          value: '${snapshot.pendingTasks}',
          detail: snapshot.pendingTasks == 1 ? 'pending task' : 'pending tasks',
          icon: LucideIcons.checkSquare,
          color: AppTheme.tertiary,
          progress: snapshot.taskProgress,
          onTap: onOpenTasks,
        ),
        _GlanceCard(
          label: 'Habits',
          value: '${snapshot.habitsDone}/${snapshot.totalHabits}',
          detail: snapshot.totalHabits == 0 ? 'none yet' : 'done today',
          icon: LucideIcons.activity,
          color: AppTheme.success,
          progress: snapshot.habitProgress,
          onTap: onOpenHabits,
        ),
        _GlanceCard(
          label: 'Focus',
          value: '${snapshot.focusMinutesToday}m',
          detail: 'deep work',
          icon: LucideIcons.timer,
          color: AppTheme.primary,
          progress: (snapshot.focusMinutesToday / 120).clamp(0, 1).toDouble(),
          onTap: onOpenFocus,
        ),
        _GlanceCard(
          label: 'Journal',
          value: snapshot.todayMood ?? '${snapshot.noteCount}',
          detail: snapshot.todayMood == null
              ? '${snapshot.noteCount} ${snapshot.noteCount == 1 ? 'note' : 'notes'}'
              : 'mood today',
          icon: LucideIcons.bookOpen,
          color: AppTheme.warning,
          progress: snapshot.todayMood == null ? 0 : 1,
          onTap: onOpenJournal,
        ),
      ],
    );
  }
}

class _GlanceCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
  final double progress;
  final VoidCallback onTap;

  const _GlanceCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.94,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const Spacer(),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0, 1),
                    strokeWidth: 3,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 23,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodMicroCheckIn extends StatelessWidget {
  static const List<String> _moods = ['😴', '😐', '🙂', '😊', '🔥'];

  final String? selectedMood;
  final ValueChanged<String> onSelect;
  final VoidCallback onOpenJournal;

  const _MoodMicroCheckIn({
    required this.selectedMood,
    required this.onSelect,
    required this.onOpenJournal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          PressableScale(
            onTap: onOpenJournal,
            pressedScale: 0.96,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.heart,
                  size: 18,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedMood == null ? 'Mood' : 'Mood $selectedMood',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          ..._moods.map(
            (mood) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _MoodDot(
                mood: mood,
                isSelected: mood == selectedMood,
                onTap: () => onSelect(mood),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodDot extends StatelessWidget {
  final String mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodDot({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.9,
      child: AnimatedContainer(
        duration: Motion.fast,
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Text(mood, style: TextStyle(fontSize: isSelected ? 21 : 18)),
      ),
    );
  }
}
