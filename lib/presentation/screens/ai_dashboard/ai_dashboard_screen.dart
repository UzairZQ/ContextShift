import 'package:flutter/material.dart';

import '../../../core/ai_service.dart';
import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../shared/context_shift_primitives.dart';
import '../../widgets/motion/wonderous_motion.dart';
import 'widgets/activity_heatmap.dart';
import 'widgets/command_history.dart';
import 'widgets/dash_header.dart';
import 'widgets/insight_card.dart';
import 'widgets/mood_trend.dart';
import 'widgets/stats_grid.dart';

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
    try {
      final stats = await DatabaseService.instance.buildInsightStats();
      final results = await Future.wait([
        AiService.instance.fetchInsight(
          userName: DatabaseService.instance.firstName,
          stats: stats,
        ),
        DatabaseService.instance.getTodayFocusMinutes(),
      ]);

      if (!mounted) return;
      setState(() {
        _weeklyInsight = results[0] as String;
        _focusMinutes = results[1] as int;
        _isLoadingInsight = false;
      });
    } catch (error, stackTrace) {
      debugPrint('[AiDashboardScreen] Load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _weeklyInsight =
            'Your local activity is ready. More analysis will appear after another check-in.';
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
              const WonderousReveal(child: DashHeader()),
              const SizedBox(height: 24),
              WonderousReveal(
                delay: const Duration(milliseconds: 80),
                child: InsightCard(
                  insight: _weeklyInsight,
                  isLoading: _isLoadingInsight,
                ),
              ),
              const SizedBox(height: 14),
              WonderousReveal(
                delay: const Duration(milliseconds: 140),
                child: StatsGrid(focusMinutes: _focusMinutes),
              ),
              const SizedBox(height: 16),
              const WonderousReveal(
                delay: Duration(milliseconds: 200),
                child: ContextSectionLabel(text: 'Rhythm field'),
              ),
              const SizedBox(height: 12),
              const WonderousReveal(
                delay: Duration(milliseconds: 240),
                child: ActivityHeatmap(),
              ),
              const SizedBox(height: 24),
              const WonderousReveal(
                delay: Duration(milliseconds: 280),
                child: ContextSectionLabel(text: 'Recent commands'),
              ),
              const SizedBox(height: 12),
              const WonderousReveal(
                delay: Duration(milliseconds: 320),
                child: CommandHistory(),
              ),
              const SizedBox(height: 24),
              const WonderousReveal(
                delay: Duration(milliseconds: 360),
                child: ContextSectionLabel(text: 'Mood context'),
              ),
              const SizedBox(height: 12),
              const WonderousReveal(
                delay: Duration(milliseconds: 400),
                child: MoodTrend(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
