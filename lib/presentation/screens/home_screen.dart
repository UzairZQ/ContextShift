import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../core/firebase_service.dart';
import '../../core/ai_service.dart';
import '../../core/responsive.dart';
import '../widgets/task_module.dart';
import '../widgets/habit_module.dart';
import '../widgets/focus_module.dart';
import '../widgets/notes_module.dart';
import '../widgets/ai_dashboard_module.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  String _greeting = '';
  String? _aiInsight;
  String? _aiResponse;
  bool _isProcessingCommand = false;
  bool _isLoadingInsight = true;
  int _focusMinutesToday = 0;
  String? _todayMood;
  final _commandController = TextEditingController();
  late AnimationController _responseAnimController;
  
  // Default dynamic order
  List<String> _moduleOrder = [
    'TasksModule',
    'HabitModule',
    'FocusTimerModule',
    'NotesModule'
  ];
  String _layoutRefresher = '';

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

  void _computeGreeting() {
    final hour = DateTime.now().hour;
    final name = FirebaseService.instance.firstName;
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
    // Load all data in parallel
    final results = await Future.wait([
      FirebaseService.instance.getTodayFocusMinutes(),
      FirebaseService.instance.getTodayMood(),
      AiService.instance.fetchInsight(
        userName: FirebaseService.instance.firstName,
      ),
    ]);

    if (mounted) {
      setState(() {
        _focusMinutesToday = results[0] as int;
        _todayMood = results[1] as String?;
        _aiInsight = results[2] as String;
        _isLoadingInsight = false;
      });
    }
  }

  Future<void> _processCommand(String command) async {
    if (command.trim().isEmpty) return;
    setState(() => _isProcessingCommand = true);
    bool navigatedByAction = false;

    try {
      final result = await AiService.instance.processCommand(
        command: command,
        userName: FirebaseService.instance.firstName,
      );

      // Process each action
      for (final action in result.actions) {
        switch (action.type) {
          case 'add_task':
            await FirebaseService.instance.addTask(
              title: action.params['title'] ?? command,
              priority: action.params['priority'] ?? 'normal',
            );
            break;
          case 'add_habit':
            await FirebaseService.instance.addHabit(
              name: action.params['name'] ?? command,
              icon: action.params['icon'] ?? '✨',
            );
            break;
          case 'add_note':
            await FirebaseService.instance.addNote(
              content: action.params['content'] ?? command,
            );
            break;
          case 'start_focus':
            // We do not switch to the timer tab explicitly here,
            // because we want the user to see the dynamic home layout animate.
            break;
          case 'navigate':
            final tab = action.params['tab'] as String?;
            final tabMap = {'home': 0, 'tasks': 1, 'habits': 2, 'focus': 3, 'notes': 4};
            if (tab != null && tabMap.containsKey(tab) && mounted) {
              setState(() => _currentIndex = tabMap[tab]!);
              navigatedByAction = true;
            }
            break;
        }
      }

      // Save command history
      await FirebaseService.instance.saveAiCommand(
        command: command,
        response: result.response,
        actions: result.actions.map((a) => {'type': a.type, ...a.params}).toList(),
      );

      // Update UI
      if (mounted) {
        setState(() {
          _aiResponse = result.response;
          if (result.greetingUpdate != null) {
            _greeting = result.greetingUpdate!;
          }
          if (result.layoutOrder != null && result.layoutOrder!.isNotEmpty) {
            _moduleOrder = result.layoutOrder!;
            _layoutRefresher = DateTime.now().toIso8601String();
            // Ensure we are on the Home tab to see the dynamic layout,
            // unless the user specifically asked to navigate somewhere else.
            if (!navigatedByAction) _currentIndex = 0;
          }
        });
        _responseAnimController.forward(from: 0);

        // Show response snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.response),
            backgroundColor: AppTheme.surfaceBright,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
            duration: const Duration(seconds: 3),
          ),
        );

        // Clear response after delay
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _aiResponse = null);
        });
      }
    } catch (e) {
      debugPrint('Command processing error: $e');
    } finally {
      if (mounted) setState(() => _isProcessingCommand = false);
    }
  }

  Future<void> _saveMood(String mood) async {
    setState(() => _todayMood = mood);
    await FirebaseService.instance.saveMood(mood);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mood logged: $mood'),
          backgroundColor: AppTheme.surfaceBright,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void dispose() {
    _commandController.dispose();
    _responseAnimController.dispose();
    super.dispose();
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.horizontalPadding(context),
          ),
          child: ResponsiveWrapper(
            maxWidth: 1000,
            child: _buildBody(),
          ),
        ),
      ),
      extendBody: true,
      bottomNavigationBar: _buildFloatingNav(),
    );
  }

  Widget _buildBody() {
    return switch (_currentIndex) {
      0 => _buildHomeTab(),
      1 => const TasksModule(),
      2 => const HabitModule(),
      3 => const FocusTimerModule(),
      4 => const NotesModule(),
      _ => const SizedBox.shrink(),
    };
  }

  // ─────────────────────────────────────────────────────────────
  // HOME TAB — Dashboard
  // ─────────────────────────────────────────────────────────────

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          // Dynamic AI greeting
          Text(
            _greeting,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  fontSize: Responsive.isMobile(context) ? 20 : 24,
                ),
          ),
          _buildAICommandBar(),
          const SizedBox(height: 16),
          if (_aiResponse != null) _buildAIResponseCard(),
          _buildMoodCheckIn(),
          const SizedBox(height: 20),
          _buildStatsSection(),
          const SizedBox(height: 20),
          _buildAIInsightCard(),
          const SizedBox(height: 16),
          _buildDynamicModules(),
          const SizedBox(height: 120), // padding for floating nav
        ],
      ),
    );
  }

  Widget _buildDynamicModules() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutExpo,
      switchOutCurve: Curves.easeInExpo,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15), // Slide up from underneath
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey(_moduleOrder.join('-') + _layoutRefresher),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _moduleOrder.map((moduleName) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _getModuleWidget(moduleName),
          );
        }).toList(),
      ),
    );
  }

  Widget _getModuleWidget(String name) {
    switch (name) {
      case 'FocusTimerModule':
        return const FocusTimerModule();
      case 'TasksModule':
        return const TasksModule();
      case 'HabitModule':
        return const HabitModule();
      case 'NotesModule':
        return const NotesModule();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ContextShift',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        letterSpacing: -1,
                        fontWeight: FontWeight.w900,
                        fontSize: Responsive.isMobile(context) ? 28 : 36,
                      ),
                ),
                Text(
                  '${FirebaseService.instance.firstName}\'s Sanctuary',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: Responsive.isMobile(context) ? 10 : 12,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // AI Dashboard button
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AiDashboardScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceHigh,
                  ),
                  child: const Icon(
                    LucideIcons.barChart2,
                    size: 16,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Logout button
              GestureDetector(
                onTap: () => FirebaseService.instance.signOut(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.surfaceHigh,
                  ),
                  child: const Icon(
                    LucideIcons.logOut,
                    size: 16,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: _AIPulsar(isAnalyzing: _isProcessingCommand),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAICommandBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: AppTheme.glassmorphism(
        tint: AppTheme.surfaceHighest,
        borderRadius: 999,
      ),
      child: TextField(
        controller: _commandController,
        textInputAction: TextInputAction.send,
        style: const TextStyle(color: AppTheme.onSurface),
        decoration: InputDecoration(
          icon: Icon(
            LucideIcons.sparkles,
            color: _isProcessingCommand
                ? AppTheme.primary
                : AppTheme.primary.withValues(alpha: 0.6),
            size: 20,
          ),
          hintText: 'Tell JARVIS what to do...',
          hintStyle: TextStyle(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          suffixIcon: _isProcessingCommand
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: () {
                    final val = _commandController.text.trim();
                    if (val.isEmpty) return;
                    _processCommand(val);
                    _commandController.clear();
                    FocusScope.of(context).unfocus();
                  },
                  icon: const Icon(
                    LucideIcons.send,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ),
        ),
        onSubmitted: (val) {
          if (val.trim().isEmpty) return;
          _processCommand(val);
          _commandController.clear();
        },
      ),
    );
  }

  Widget _buildAIResponseCard() {
    return FadeTransition(
      opacity: _responseAnimController,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.sparkles, color: AppTheme.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _aiResponse!,
                style: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _aiResponse = null),
              child: const Icon(LucideIcons.x, size: 14, color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCheckIn() {
    final moods = ['😴', '😐', '🙂', '😊', '🔥'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(color: AppTheme.surfaceContainer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _todayMood != null ? 'Feeling $_todayMood today' : 'How are you feeling?',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moods.map((mood) {
              final isSelected = _todayMood == mood;
              return GestureDetector(
                onTap: () => _saveMood(mood),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    mood,
                    style: TextStyle(fontSize: isSelected ? 28 : 24),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.instance.watchTasks(),
      builder: (context, taskSnap) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseService.instance.watchHabits(),
          builder: (context, habitSnap) {
            final tasks = taskSnap.data ?? [];
            final habits = habitSnap.data ?? [];

            final tasksDone = tasks.where((t) => t['done'] == true).length;
            final totalTasks = tasks.length;

            final today = _todayString();
            final habitsDone = habits.where((h) {
              final dates = (h['completedDates'] as List<dynamic>?) ?? [];
              return dates.contains(today);
            }).length;
            final totalHabits = habits.length;

            final streak = FirebaseService.instance.computeStreak(habits);

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _StatCard(
                  value: '$tasksDone/$totalTasks',
                  label: 'Tasks Done',
                  icon: LucideIcons.checkSquare,
                  progress: totalTasks > 0 ? tasksDone / totalTasks : 0,
                  color: Colors.blue,
                ),
                _StatCard(
                  value: '$habitsDone/$totalHabits',
                  label: 'Habits',
                  icon: LucideIcons.activity,
                  progress: totalHabits > 0 ? habitsDone / totalHabits : 0,
                  color: AppTheme.success,
                ),
                _StatCard(
                  value: '${_focusMinutesToday}m',
                  label: 'Focus Today',
                  icon: LucideIcons.timer,
                  progress: (_focusMinutesToday / 120).clamp(0, 1).toDouble(),
                  color: AppTheme.primary,
                ),
                _StatCard(
                  value: '$streak',
                  label: 'Day Streak',
                  icon: LucideIcons.flame,
                  progress: (streak / 30).clamp(0, 1).toDouble(),
                  color: AppTheme.warning,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAIInsightCard() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AiDashboardScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.surfaceHigh,
              AppTheme.surfaceHigh.withValues(alpha: 0.8),
            ],
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
                const Icon(LucideIcons.sparkles, color: AppTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'AI Insight',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppTheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _isLoadingInsight
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : Text(
                    _aiInsight ?? 'Tap to view your AI dashboard.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.onSurface.withValues(alpha: 0.9),
                        ),
                  ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FLOATING GLASSMORPHIC BOTTOM NAV
  // ─────────────────────────────────────────────────────────────

  Widget _buildFloatingNav() {
    final items = [
      _NavItem(LucideIcons.layoutDashboard, 'Home'),
      _NavItem(LucideIcons.checkSquare, 'Tasks'),
      _NavItem(LucideIcons.activity, 'Habits'),
      _NavItem(LucideIcons.timer, 'Focus'),
      _NavItem(LucideIcons.stickyNote, 'Notes'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: AppTheme.glassmorphism(
          tint: AppTheme.surfaceHighest,
          opacity: 0.90,
          borderRadius: 999,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isActive = _currentIndex == i;

            return GestureDetector(
              onTap: () {
                setState(() => _currentIndex = i);
                FirebaseService.instance.logEvent(
                  eventType: 'tab_tap',
                  module: ['home', 'tasks', 'habits', 'focus', 'notes'][i],
                );
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  item.icon,
                  size: 24, // perfectly centered
                  color: isActive
                      ? AppTheme.primary
                      : AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final double progress;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(color: AppTheme.surfaceContainer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const Spacer(),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: progress.clamp(0, 1),
                  strokeWidth: 3,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _AIPulsar extends StatefulWidget {
  final bool isAnalyzing;
  const _AIPulsar({this.isAnalyzing = false});

  @override
  State<_AIPulsar> createState() => _AIPulsarState();
}

class _AIPulsarState extends State<_AIPulsar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void didUpdateWidget(_AIPulsar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnalyzing != oldWidget.isAnalyzing) {
      _controller.duration = widget.isAnalyzing
          ? const Duration(milliseconds: 500)
          : const Duration(seconds: 2);
      if (_controller.isAnimating) _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 12 + (16 * _controller.value),
                height: 12 + (16 * _controller.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary
                      .withValues(alpha: 0.7 * (1 - _controller.value)),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary,
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
