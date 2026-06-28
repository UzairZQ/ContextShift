import 'package:flutter/material.dart';

import '../../../core/ai_service.dart';
import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../shared/context_shift_primitives.dart';
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
              const DashHeader(),
              const SizedBox(height: 24),
              InsightCard(
                insight: _weeklyInsight,
                isLoading: _isLoadingInsight,
              ),
              const SizedBox(height: 14),
              StatsGrid(focusMinutes: _focusMinutes),
              const SizedBox(height: 16),
              const ContextSectionLabel(text: 'Rhythm field'),
              const SizedBox(height: 12),
              const ActivityHeatmap(),
              const SizedBox(height: 24),
              const ContextSectionLabel(text: 'Recent commands'),
              const SizedBox(height: 12),
              const CommandHistory(),
              const SizedBox(height: 24),
              const ContextSectionLabel(text: 'Mood context'),
              const SizedBox(height: 12),
              const MoodTrend(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
