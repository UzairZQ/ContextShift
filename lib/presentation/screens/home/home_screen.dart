import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/ai_service.dart';
import '../../../core/app_spacing.dart';
import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../../core/local_llm/model_tier.dart';
import '../../../core/responsive.dart';
import '../../../core/services/feature_manager.dart';
import '../../../features/onboarding/widgets/model_download_screen.dart';
import '../../widgets/focus/focus_module.dart';
import '../../widgets/habits/habit_module.dart';
import '../../widgets/notes/notes_module.dart';
import '../../widgets/tasks/tasks_module.dart';
import '../ai_dashboard/ai_dashboard_screen.dart';
import '../guest_profile/guest_profile_screen.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/home_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  static const List<String> _defaultModuleOrder = [
    'TasksModule',
    'HabitModule',
    'FocusTimerModule',
    'NotesModule',
  ];

  int _currentIndex = 0;
  String _greeting = '';
  String? _aiInsight;
  String? _aiResponse;
  bool _isProcessingCommand = false;
  bool _isLoadingInsight = true;
  int _focusMinutesToday = 0;
  String? _todayMood;
  Map<String, dynamic>? _generativeCardPayload;
  List<String> _moduleOrder = _defaultModuleOrder;
  String _layoutRefresher = '';

  final TextEditingController _commandController = TextEditingController();
  late final AnimationController _responseAnimController;

  @override
  void initState() {
    super.initState();
    _responseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _computeGreeting();
    _loadInitialData();
  }

  @override
  void dispose() {
    _responseAnimController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  void _computeGreeting() {
    final hour = DateTime.now().hour;
    final name = DatabaseService.instance.firstName;
    if (hour < 5) {
      _greeting = 'Still going, $name?\nRest is part of the grind.';
    } else if (hour < 12) {
      _greeting = 'Good morning, $name.\nLet\'s make today count.';
    } else if (hour < 17) {
      _greeting = 'Afternoon focus, $name.\nStay in the zone.';
    } else {
      _greeting = 'Evening review, $name.\nReflect and plan ahead.';
    }
  }

  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      DatabaseService.instance.getTodayFocusMinutes(),
      DatabaseService.instance.getTodayMood(),
    ]);

    if (!mounted) return;
    setState(() {
      _focusMinutesToday = results[0] as int;
      _todayMood = results[1] as String?;
    });

    _loadAiInsight();
  }

  Future<void> _loadAiInsight() async {
    if (mounted) setState(() => _isLoadingInsight = true);
    try {
      final stats = await DatabaseService.instance.buildInsightStats();
      final insight = await AiService.instance.fetchInsight(
        userName: DatabaseService.instance.firstName,
        stats: stats,
      );
      if (!mounted) return;
      setState(() {
        _aiInsight = insight;
        _isLoadingInsight = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiInsight =
            'Continue your streak, ${DatabaseService.instance.firstName}!';
        _isLoadingInsight = false;
      });
    }
  }

  Future<void> _processCommand(String command) async {
    if (command.trim().isEmpty) return;
    _commandController.clear();
    if (mounted) setState(() => _isProcessingCommand = true);
    bool navigatedByAction = false;
    Map<String, dynamic>? nextGenerativeCardPayload;

    try {
      final result = await AiService.instance.processCommand(
        command: command,
        userName: DatabaseService.instance.firstName,
      );

      if (!mounted) return;

      for (final action in result.actions) {
        await _executeAction(
          action,
          onNavigated: () => navigatedByAction = true,
          onGenerativeCard: (payload) {
            nextGenerativeCardPayload = payload;
          },
        );
      }

      await DatabaseService.instance.saveAiCommand(
        command: command,
        response: result.response,
        actions: result.actions
            .map((a) => {'type': a.type, ...a.params})
            .toList(),
      );

      if (!mounted) return;
      setState(() {
        _aiResponse = result.response;
        _generativeCardPayload = nextGenerativeCardPayload;
        if (result.greetingUpdate != null) {
          _greeting = result.greetingUpdate!;
        }
        if (result.layoutOrder != null && result.layoutOrder!.isNotEmpty) {
          _moduleOrder = result.layoutOrder!;
          _layoutRefresher = DateTime.now().toIso8601String();
          if (!navigatedByAction) _currentIndex = 0;
        }
      });
      _responseAnimController.forward(from: 0);
      _showResponseSnackBar(result.response);

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _aiResponse = null);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'JARVIS had trouble with that request. Try again in a moment.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessingCommand = false);
    }
  }

  Future<void> _executeAction(
    AiAction action, {
    required VoidCallback onNavigated,
    required ValueChanged<Map<String, dynamic>> onGenerativeCard,
  }) async {
    switch (action.type) {
      case 'add_task':
        await DatabaseService.instance.addTask(
          title: action.params['title'] ?? '',
          priority: action.params['priority'] ?? 'normal',
        );
        break;
      case 'add_habit':
        await DatabaseService.instance.addHabit(
          name: action.params['name'] ?? '',
          icon: action.params['icon'] ?? '✨',
        );
        break;
      case 'add_note':
        await DatabaseService.instance.addNote(
          content: action.params['content'] ?? '',
        );
        break;
      case 'start_focus':
        break;
      case 'show_dynamic_card':
        if (action.params.containsKey('card')) {
          onGenerativeCard(
            Map<String, dynamic>.from(action.params['card'] as Map),
          );
        }
        break;
      case 'navigate':
        const tabMap = {
          'home': 0,
          'tasks': 1,
          'habits': 2,
          'focus': 3,
          'notes': 4,
        };
        final tab = action.params['tab'] as String?;
        if (tab != null && tabMap.containsKey(tab)) {
          _switchTab(tabMap[tab]!);
          onNavigated();
        }
        break;
    }
  }

  void _showResponseSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.sparkles, color: AppTheme.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 110, left: 24, right: 24),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _switchTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    DatabaseService.instance.logEvent(
      eventType: 'tab_tap',
      module: ['home', 'tasks', 'habits', 'focus', 'notes'][index],
    );
  }

  Future<void> _saveMood(String mood) async {
    if (mounted) setState(() => _todayMood = mood);
    await DatabaseService.instance.saveMood(mood);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.heart, color: Colors.pinkAccent, size: 18),
            const SizedBox(width: 12),
            Text(
              'Mood logged: $mood',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.pinkAccent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 110, left: 24, right: 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AiDashboardScreen()),
    );
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GuestProfileScreen()),
    );
  }

  void _handleGenerativeCardAction() {
    final module = _generativeCardPayload?['action_module'] as String?;
    if (module == 'FocusTimerModule') {
      _switchTab(3);
    } else if (module == 'TasksModule') {
      _switchTab(1);
    }
  }

  Widget _buildBody() {
    return switch (_currentIndex) {
      0 => RefreshIndicator(
          onRefresh: _loadInitialData,
          child: HomeTab(
            greeting: _greeting,
            commandController: _commandController,
            isJarvisOnline: true,
            hasCheckedJarvisStatus: true,
            isProcessingCommand: _isProcessingCommand,
            offlineHint: '',
            aiResponse: _aiResponse,
            responseAnimation: _responseAnimController,
            isLoadingInsight: _isLoadingInsight,
            aiInsight: _aiInsight,
            focusMinutesToday: _focusMinutesToday,
            todayMood: _todayMood,
            moduleOrder: _moduleOrder,
            layoutRefresher: _layoutRefresher,
            generativeCardPayload: _generativeCardPayload,
            onOpenDashboard: _openDashboard,
            onGenerativeCardAction: _handleGenerativeCardAction,
            onSubmitCommand: _processCommand,
            onSelectMood: _saveMood,
            onDismissResponse: () {
            if (mounted) setState(() => _aiResponse = null);
          },
          onLogout: _handleLogout,
          isAuthGuest: DatabaseService.instance.isGuest,
        ),
      ),
      1 => const TasksModule(),
      2 => const HabitModule(),
      3 => const FocusTimerModule(),
      4 => const NotesModule(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (!FeatureManager.instance.isE2bAvailable &&
              !FeatureManager.instance.isE4bAvailable)
            GestureDetector(
              onTap: _openModelDownload,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.sm,
                ),
                color: AppTheme.warning.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.downloadCloud,
                      size: 16,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: Spacing.sm),
                    const Expanded(
                      child: Text(
                        'Download AI model for JARVIS features',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppTheme.warning,
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                ),
                child: ResponsiveWrapper(
                  maxWidth: 1000,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_currentIndex),
                      child: _buildBody(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: _switchTab,
      ),
    );
  }

  void _openModelDownload() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModelDownloadScreen(
          model: ModelDefinition.e2b,
          isOnboarding: false,
          onComplete: () {
            Navigator.pop(context);
            setState(() {
              FeatureManager.instance.setE2bDownloaded(true);
            });
          },
        ),
      ),
    );
  }
}
