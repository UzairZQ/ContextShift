import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../core/firebase_service.dart';
import '../../core/ai_service.dart';

/// Full-screen AI Dashboard — accessed from home insight card or header icon
class AiDashboardScreen extends StatefulWidget {
  const AiDashboardScreen({super.key});

  @override
  State<AiDashboardScreen> createState() => _AiDashboardScreenState();
}

class _AiDashboardScreenState extends State<AiDashboardScreen> {
  String? _weeklyInsight;
  bool _isLoadingInsight = true;
  int _focusMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      AiService.instance.fetchInsight(
        userName: FirebaseService.instance.firstName,
      ),
      FirebaseService.instance.getTodayFocusMinutes(),
    ]);

    if (mounted) {
      setState(() {
        _weeklyInsight = results[0] as String;
        _focusMinutes = results[1] as int;
        _isLoadingInsight = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildInsightCard(),
              const SizedBox(height: 20),
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildActivityHeatmap(),
              const SizedBox(height: 24),
              _buildCommandHistory(),
              const SizedBox(height: 24),
              _buildMoodTrend(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceHigh,
              ),
              child: const Icon(
                LucideIcons.arrowLeft,
                size: 18,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ContextShift',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                'Neural Intelligence Report',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.12),
            AppTheme.surfaceHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Analysis',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoadingInsight
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                )
              : Text(
                  _weeklyInsight ?? 'No insight available.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.onSurface,
                        height: 1.5,
                      ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.instance.watchTasks(),
      builder: (context, taskSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseService.instance.watchHabits(),
          builder: (context, habitSnap) {
            final tasks = taskSnap.data ?? [];
            final habits = habitSnap.data ?? [];
            final tasksDone = tasks.where((t) => t['done'] == true).length;
            final streak = FirebaseService.instance.computeStreak(habits);

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _DashStatCard(
                  value: '$tasksDone',
                  label: 'Tasks Completed',
                  sublabel: 'All time',
                  icon: LucideIcons.checkCircle,
                  color: Colors.blue,
                ),
                _DashStatCard(
                  value: '${_focusMinutes}m',
                  label: 'Focus Today',
                  sublabel: 'Deep work',
                  icon: LucideIcons.timer,
                  color: AppTheme.primary,
                ),
                _DashStatCard(
                  value: '$streak',
                  label: 'Day Streak',
                  sublabel: 'Consistency',
                  icon: LucideIcons.flame,
                  color: AppTheme.warning,
                ),
                _DashStatCard(
                  value: '${habits.length}',
                  label: 'Active Habits',
                  sublabel: 'Tracking',
                  icon: LucideIcons.activity,
                  color: AppTheme.success,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActivityHeatmap() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.instance.watchHabits(),
      builder: (context, snapshot) {
        final habits = snapshot.data ?? [];
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
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.cardDecoration(color: AppTheme.surfaceContainer),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activity Heatmap',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Last 28 Days',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  const cols = 28;
                  const spacing = 3.0;
                  final boxSize =
                      ((constraints.maxWidth - ((cols - 1) * spacing)) / cols)
                          .clamp(4.0, 14.0);

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: List.generate(cols, (index) {
                      final day = now.subtract(Duration(days: (cols - 1) - index));
                      final dayStr =
                          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                      final count = dailyCounts[dayStr] ?? 0;

                      double opacity = 0.05;
                      if (count > 0 && habits.isNotEmpty) {
                        opacity = 0.2 + (count / habits.length * 0.8);
                        if (opacity > 1.0) opacity = 1.0;
                      }

                      return Container(
                        width: boxSize,
                        height: boxSize,
                        decoration: BoxDecoration(
                          color: count > 0
                              ? AppTheme.primary.withValues(alpha: opacity)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: count > 0
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primary
                                        .withValues(alpha: opacity * 0.4),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommandHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Command History', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseService.instance.watchAiCommands(limit: 5),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration:
                    AppTheme.cardDecoration(color: AppTheme.surfaceContainer),
                child: Text(
                  'No commands yet.\nTry the AI command bar on the home screen.',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.map((cmd) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: AppTheme.cardDecoration(
                    color: AppTheme.surfaceContainer,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.terminal,
                            size: 14,
                            color: AppTheme.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '"${cmd['command'] ?? ''}"',
                              style: TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cmd['response'] ?? '',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMoodTrend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mood Trend', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseService.instance.watchMoods(days: 7),
          builder: (context, snapshot) {
            final moods = snapshot.data ?? [];

            if (moods.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration:
                    AppTheme.cardDecoration(color: AppTheme.surfaceContainer),
                child: Text(
                  'No mood data yet.\nLog your mood from the home screen.',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              );
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
                          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
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

// ─────────────────────────────────────────────────────────────

class _DashStatCard extends StatelessWidget {
  final String value;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;

  const _DashStatCard({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(color: AppTheme.surfaceContainer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
