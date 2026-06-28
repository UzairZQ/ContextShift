import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/ai_service.dart';
import '../../../core/ai/action_executor.dart';
import '../../../core/ai/generated_ui_action_mapper.dart';
import '../../../core/ai/jarvis_intent_router.dart';
import '../../../core/app_spacing.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../../core/genui/genui_runtime.dart';
import '../../../core/genui/widget_node.dart';
import '../../../core/local_llm/gemma_service.dart';
import '../../../core/local_llm/model_tier.dart';
import '../../../core/responsive.dart';
import '../../../core/services/feature_manager.dart';
import '../../../features/onboarding/widgets/model_download_screen.dart';
import '../../widgets/focus/focus_module.dart';
import '../../widgets/habits/habit_module.dart';
import '../../widgets/tasks/tasks_module.dart';
import '../ai_dashboard/ai_dashboard_screen.dart';
import '../chat/chat_screen.dart';
import '../journal/journal_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/home_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  int _previousIndex = 0;
  String _greeting = '';
  String? _aiInsight;
  String? _aiResponse;
  bool _isProcessingCommand = false;
  bool _isLoadingInsight = true;
  bool _isAutoWarmingJarvis = false;
  int _focusMinutesToday = 0;
  String? _todayMood;
  String? _activeSurfaceRawA2ui;

  final TextEditingController _commandController = TextEditingController();
  JarvisGenUiRuntime? _homeGenUiRuntime;
  late final AnimationController _responseAnimController;

  @override
  void initState() {
    super.initState();
    _responseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    GemmaService.instance.statusRevision.addListener(_refreshJarvisStatus);
    _computeGreeting();
    _loadInitialData();
    unawaited(_maybeWarmVerifiedJarvis());
  }

  @override
  void dispose() {
    GemmaService.instance.statusRevision.removeListener(_refreshJarvisStatus);
    _homeGenUiRuntime?.dispose();
    _responseAnimController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  void _refreshJarvisStatus() {
    if (mounted) setState(() {});
  }

  JarvisGenUiRuntime get _homeGenUiRuntimeInstance {
    return _homeGenUiRuntime ??= JarvisGenUiRuntime();
  }

  Future<void> _maybeWarmVerifiedJarvis() async {
    if (_isAutoWarmingJarvis || GemmaService.instance.isModelLoaded) return;
    if (!FeatureManager.instance.hasVerifiedModel) return;

    final model = FeatureManager.instance.resolveBestModelDef();
    if (model == null) return;

    debugPrint(
      '[HomeScreen] Auto-warming verified JARVIS model: ${model.modelId}',
    );
    if (mounted) setState(() => _isAutoWarmingJarvis = true);
    try {
      await GemmaService.instance
          .loadModel(model)
          .timeout(const Duration(seconds: 60));
      debugPrint('[HomeScreen] Verified JARVIS model warmed successfully');
    } catch (error, stackTrace) {
      debugPrint('[HomeScreen] Auto-warm JARVIS failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) setState(() => _isAutoWarmingJarvis = false);
    }
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
    } catch (error, stackTrace) {
      debugPrint('[HomeScreen] Failed to load AI insight: $error');
      debugPrintStack(stackTrace: stackTrace);
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

    try {
      final intentDecision = await JarvisIntentRouter.instance.classify(
        message: command,
      );
      debugPrint(
        '[HomeScreen] Intent=${intentDecision.intent} '
        'fromModel=${intentDecision.fromModel} '
        'reason=${intentDecision.reason}',
      );

      if (intentDecision.intent != JarvisIntent.action &&
          !FeatureManager.instance.isE2bAvailable &&
          !FeatureManager.instance.isE4bAvailable) {
        if (!mounted) return;
        _openModelDownload();
        return;
      }

      if (intentDecision.intent == JarvisIntent.chat) {
        debugPrint(
          '[HomeScreen] Opening JARVIS chat. '
          'modelLoaded=${GemmaService.instance.isModelLoaded}, '
          'e2b=${FeatureManager.instance.isE2bAvailable}, '
          'e4b=${FeatureManager.instance.isE4bAvailable}',
        );
        if (!mounted) return;
        await _pushChat(initialMessage: command);
        _commandController.clear();
        return;
      }

      _commandController.clear();
      if (mounted) setState(() => _isProcessingCommand = true);
      bool navigatedByAction = false;

      if (intentDecision.intent == JarvisIntent.genui) {
        await _ensureJarvisReadyForHome(command);
        final generation = await _homeGenUiRuntimeInstance.generate(
          userMessage: command,
          timeout: const Duration(seconds: 45),
        );

        final response = generation.text.isEmpty
            ? 'I shaped that into an interactive view.'
            : generation.text;
        await DatabaseService.instance.saveAiCommand(
          command: command,
          response: response,
          actions: [
            {'type': 'a2ui_surface', 'surface_ids': generation.surfaceIds},
          ],
        );
        if (!mounted) return;
        setState(() {
          _aiResponse = response;
          _activeSurfaceRawA2ui =
              generation.surfaceIds.isEmpty || generation.rawA2ui.trim().isEmpty
              ? null
              : generation.rawA2ui;
          _currentIndex = 0;
        });
        _responseAnimController.forward(from: 0);
        _showResponseSnackBar(response);
        return;
      }

      final result = await AiService.instance.processCommand(
        command: command,
        userName: DatabaseService.instance.firstName,
      );

      if (!mounted) return;

      for (final action in result.actions) {
        await _executeAction(
          action,
          onNavigated: () => navigatedByAction = true,
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
        if (result.greetingUpdate != null) {
          _greeting = result.greetingUpdate!;
        }
        if (!navigatedByAction) {
          _currentIndex = 0;
        }
      });
      _responseAnimController.forward(from: 0);
      _showResponseSnackBar(result.response);

      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _aiResponse = null);
      });
    } catch (error, stackTrace) {
      debugPrint('[HomeScreen] JARVIS command failed: $error');
      debugPrintStack(stackTrace: stackTrace);
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
  }) async {
    switch (action.type) {
      case 'add_task':
        await ActionExecutor.instance.executeAll([action]);
        break;
      case 'add_habit':
        await ActionExecutor.instance.executeAll([action]);
        break;
      case 'add_note':
        await ActionExecutor.instance.executeAll([action]);
        break;
      case 'start_focus':
        await ActionExecutor.instance.executeAll([action]);
        break;
      case 'navigate':
        const tabMap = {
          'home': 0,
          'tasks': 1,
          'habits': 2,
          'focus': 3,
          'journal': 4,
          'notes': 4,
          'mood': 4,
        };
        final tab = action.params['tab'] as String?;
        if (tab == 'chat' || tab == 'jarvis') {
          await _pushChat();
          onNavigated();
        } else if (tab != null && tabMap.containsKey(tab)) {
          _switchTab(tabMap[tab]!);
          onNavigated();
        }
        break;
    }
  }

  Future<void> _ensureJarvisReadyForHome(String message) async {
    debugPrint(
      '[HomeScreen] Loading downloaded model before generation. '
      'messageLength=${message.length}',
    );
    try {
      await GemmaService.instance.loadBestAvailableModel();
    } on GemmaException catch (error) {
      if (error.code == GemmaErrorCode.modelNotInstalled) _openModelDownload();
      rethrow;
    }
  }

  void _showResponseSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              LucideIcons.radio,
              color: AppTheme.intelligence,
              size: 18,
            ),
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
        backgroundColor: AppTheme.surfaceHigh.withValues(alpha: 0.96),
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
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
    DatabaseService.instance.logEvent(
      eventType: 'tab_tap',
      module: ['home', 'tasks', 'habits', 'focus', 'journal'][index],
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
        backgroundColor: AppTheme.surfaceHigh.withValues(alpha: 0.96),
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
    Navigator.of(
      context,
    ).push(SmoothPageRoute(builder: (_) => const AiDashboardScreen()));
  }

  void _openProfile() {
    Navigator.of(
      context,
    ).push(SmoothPageRoute(builder: (_) => const SettingsScreen()));
  }

  Future<void> _openChat() async {
    final text = _commandController.text.trim();
    await _pushChat(initialMessage: text.isNotEmpty ? text : null);
    _commandController.clear();
  }

  Future<void> _openEmptyChat() async {
    debugPrint('[HomeScreen] Opening empty JARVIS chat from floating button');
    try {
      debugPrint('[HomeScreen] Pushing stable ChatScreen route...');
      await Navigator.of(context).push<void>(
        SmoothPageRoute<void>(
          settings: const RouteSettings(name: 'jarvis_chat_fab'),
          builder: (_) {
            debugPrint('[HomeScreen] Building stable ChatScreen route');
            return const ChatScreen(
              startNewOnOpen: true,
              enableInputHero: false,
            );
          },
        ),
      );
      debugPrint('[HomeScreen] Stable ChatScreen route closed');
    } catch (error, stackTrace) {
      debugPrint('[HomeScreen] Failed to open stable chat route: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat screen could not open. Check debug logs.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pushChat({
    String? initialMessage,
    bool startNewOnOpen = false,
    bool enableInputHero = true,
  }) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: Motion.heroFlight,
        reverseTransitionDuration: Motion.smoothScreenReverse,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChatScreen(
            initialMessage: initialMessage,
            startNewOnOpen: startNewOnOpen,
            enableInputHero: enableInputHero,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Motion.smoothEnter,
            reverseCurve: Motion.smoothExit,
          );
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved);
          final scale = Tween<double>(begin: 0.968, end: 1).animate(curved);
          return ScaleTransition(
            scale: scale,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  Future<void> _handleHomeSurfaceAction(WidgetAction action) async {
    final aiAction = GeneratedUiActionMapper.toAiAction(action);
    if (aiAction == null) {
      final message = GeneratedUiActionMapper.continuationMessage(action);
      if (message != null && message.isNotEmpty) {
        await _pushChat(initialMessage: message);
      }
      return;
    }
    await ActionExecutor.instance.executeAll([aiAction]);
    if (!mounted) return;
    _showResponseSnackBar('Done');
  }

  Widget _buildBody() {
    return switch (_currentIndex) {
      0 => RefreshIndicator(
        onRefresh: _loadInitialData,
        child: HomeTab(
          greeting: _greeting,
          commandController: _commandController,
          isJarvisOnline: GemmaService.instance.isModelLoaded,
          hasCheckedJarvisStatus: true,
          isProcessingCommand: _isProcessingCommand,
          offlineHint: _isAutoWarmingJarvis
              ? 'Warming up JARVIS...'
              : FeatureManager.instance.hasVerifiedModel
              ? 'JARVIS will wake up automatically'
              : FeatureManager.instance.isE2bAvailable ||
                    FeatureManager.instance.isE4bAvailable
              ? 'Initialize JARVIS in Manage AI'
              : 'Download JARVIS to chat',
          aiResponse: _aiResponse,
          responseAnimation: _responseAnimController,
          isLoadingInsight: _isLoadingInsight,
          aiInsight: _aiInsight,
          focusMinutesToday: _focusMinutesToday,
          todayMood: _todayMood,
          activeSurfaceRawA2ui: _activeSurfaceRawA2ui,
          onOpenDashboard: _openDashboard,
          onOpenProfile: _openProfile,
          onOpenChat: _openChat,
          onOpenTasks: () => _switchTab(1),
          onOpenHabits: () => _switchTab(2),
          onOpenFocus: () => _switchTab(3),
          onOpenJournal: () => _switchTab(4),
          onSurfaceAction: (action) =>
              unawaited(_handleHomeSurfaceAction(action)),
          onSubmitCommand: _processCommand,
          onSelectMood: _saveMood,
          onDismissResponse: () {
            if (mounted) setState(() => _aiResponse = null);
          },
        ),
      ),
      1 => const TasksModule(),
      2 => const HabitModule(),
      3 => const FocusTimerModule(),
      4 => JournalScreen(todayMood: _todayMood, onSelectMood: _saveMood),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
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
                          'Download local model for JARVIS',
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
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context),
                ),
                child: ResponsiveWrapper(
                  maxWidth: 1000,
                  child: AnimatedSwitcher(
                    duration: Motion.smoothTab,
                    reverseDuration: Motion.smoothTab,
                    switchInCurve: Motion.smoothEnter,
                    switchOutCurve: Motion.smoothExit,
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[?currentChild, ...previousChildren],
                      );
                    },
                    transitionBuilder: (child, animation) {
                      final childKey = child.key;
                      final childIndex = childKey is ValueKey<int>
                          ? childKey.value
                          : _currentIndex;
                      final movingForward = _currentIndex > _previousIndex;
                      final isCurrent = childIndex == _currentIndex;
                      final movement = CurvedAnimation(
                        parent: animation,
                        curve: Motion.smoothEnter,
                        reverseCurve: Motion.smoothExit,
                      );
                      final offset = Tween<Offset>(
                        begin: Offset(
                          isCurrent
                              ? (movingForward ? 0.16 : -0.16)
                              : (movingForward ? -0.10 : 0.10),
                          0,
                        ),
                        end: Offset.zero,
                      ).animate(movement);
                      final scale = Tween<double>(
                        begin: isCurrent ? 0.97 : 0.99,
                        end: 1,
                      ).animate(movement);
                      return SlideTransition(
                        position: offset,
                        child: ScaleTransition(scale: scale, child: child),
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
          ],
        ),
      ),
      extendBody: true,
      floatingActionButton: _JarvisChatFab(onPressed: _openEmptyChat),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _currentIndex,
        onTap: _switchTab,
      ),
    );
  }

  Future<void> _openModelDownload() async {
    await Navigator.push(
      context,
      SmoothPageRoute(
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
    if (!mounted) return;
    setState(() {});
    unawaited(_maybeWarmVerifiedJarvis());
  }
}

class _JarvisChatFab extends StatelessWidget {
  final VoidCallback onPressed;

  const _JarvisChatFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm, right: Spacing.xs),
      child: Semantics(
        label: 'Open JARVIS chat',
        button: true,
        child: FloatingActionButton(
          heroTag: 'jarvis_chat_fab',
          onPressed: onPressed,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.primary,
          shape: const CircleBorder(),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceHighest.withValues(alpha: 0.94),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.36),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  LucideIcons.messageCircle,
                  size: 25,
                  color: AppTheme.primary,
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent,
                      border: Border.all(
                        color: AppTheme.surfaceHighest,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
