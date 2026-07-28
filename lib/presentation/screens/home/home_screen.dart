import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/ai_service.dart';
import '../../../core/ai/action_executor.dart';
import '../../../core/ai/context_provider.dart';
import '../../../core/ai/generated_ui_action_mapper.dart';
import '../../../core/ai/schedule_card_task_converter.dart';
import '../../../core/app_spacing.dart';
import '../../../core/app_routes.dart';
import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/schema.dart';
import '../../../core/genui/genui_runtime.dart';
import '../../../core/genui/widget_node.dart';
import '../../../core/local_llm/gemma_service.dart';
import '../../../core/local_llm/model_tier.dart';
import '../../../core/responsive.dart';
import '../../../core/services/feature_manager.dart';
import '../../../features/onboarding/widgets/model_download_screen.dart';
import '../../widgets/focus/focus_module.dart';
import '../../widgets/genui/schedule_card_editor.dart';
import '../../widgets/habits/habit_module.dart';
import '../../widgets/tasks/tasks_module.dart';
import '../../widgets/voice/voice_input_overlay.dart';
import '../ai_dashboard/ai_dashboard_screen.dart';
import '../chat/chat_screen.dart';
import '../journal/journal_screen.dart';
import '../settings/settings_screen.dart';
import 'jarvis_home_status.dart';
import 'widgets/floating_nav_bar.dart';
import 'widgets/home_tab.dart';

class HomeScreen extends StatefulWidget {
  final bool hideWordmark;

  const HomeScreen({super.key, this.hideWordmark = false});

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
  bool _hasCheckedJarvisStatus =
      FeatureManager.instance.hasInitializationResult;
  int _focusMinutesToday = 0;
  String? _todayMood;
  String? _activeSurfaceRawA2ui;
  String? _activeSurfaceSource;
  String? _activeSurfaceFallbackReason;
  int? _activeSurfaceElapsedMs;
  SavedGeneratedCardTableData? _savedGeneratedCard;
  final Set<String> _tasksAddedSurfaceKeys = <String>{};

  final TextEditingController _commandController = TextEditingController();
  JarvisGenUiRuntime? _homeGenUiRuntime;
  StreamSubscription<List<SavedGeneratedCardTableData>>? _savedCardSub;
  late final AnimationController _responseAnimController;

  @override
  void initState() {
    super.initState();
    _responseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    GemmaService.instance.statusRevision.addListener(_refreshJarvisStatus);
    FeatureManager.instance.statusRevision.addListener(_refreshJarvisStatus);
    _computeGreeting();
    _watchSavedGeneratedCard();
    _loadInitialData();
  }

  @override
  void dispose() {
    GemmaService.instance.statusRevision.removeListener(_refreshJarvisStatus);
    FeatureManager.instance.statusRevision.removeListener(_refreshJarvisStatus);
    _savedCardSub?.cancel();
    _homeGenUiRuntime?.dispose();
    _responseAnimController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  void _refreshJarvisStatus() {
    if (!mounted) return;
    setState(() {
      _hasCheckedJarvisStatus = FeatureManager.instance.hasInitializationResult;
    });
  }

  JarvisGenUiRuntime get _homeGenUiRuntimeInstance {
    return _homeGenUiRuntime ??= JarvisGenUiRuntime();
  }

  JarvisHomeStatus get _jarvisStatus => resolveJarvisHomeStatus(
    hasCheckedAvailability: _hasCheckedJarvisStatus,
    isDownloaded: FeatureManager.instance.isE2bAvailable,
    isLoading: GemmaService.instance.isModelLoading,
    isLoaded: GemmaService.instance.isModelLoaded,
  );

  void _watchSavedGeneratedCard() {
    _savedCardSub = DatabaseService.instance.watchSavedGeneratedCards().listen(
      (cards) {
        if (!mounted) return;
        setState(() {
          _savedGeneratedCard = cards.isEmpty ? null : cards.first;
        });
      },
      onError: (error, stackTrace) {
        debugPrint('[HomeScreen] Saved card stream failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      },
    );
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
    try {
      final results = await Future.wait([
        DatabaseService.instance.getTodayFocusMinutes(),
        DatabaseService.instance.getTodayMood(),
      ]);

      if (!mounted) return;
      setState(() {
        _focusMinutesToday = results[0] as int;
        _todayMood = results[1] as String?;
      });

      unawaited(_loadAiInsight());
    } catch (error, stackTrace) {
      debugPrint('[HomeScreen] Failed to load initial data: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _isLoadingInsight = false);
    }
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
      _commandController.clear();
      if (mounted) setState(() => _isProcessingCommand = true);

      if (_looksLikeHomeDirectAction(command)) {
        final result = await AiService.instance.processCommand(
          command: command,
          userName: DatabaseService.instance.firstName,
        );
        final actionResult = await ActionExecutor.instance.executeAll(
          result.actions,
        );
        final response = actionResult.failedCount > 0
            ? 'I could not complete that action. Please check the details and try again.'
            : actionResult.ignoredCount > 0
            ? 'That item is already in your workspace.'
            : result.response;
        await DatabaseService.instance.saveAiCommand(
          command: command,
          response: response,
          actions: result.actions
              .map((action) => {'type': action.type, 'params': action.params})
              .toList(growable: false),
        );
        if (!mounted) return;
        setState(() {
          _aiResponse = response;
          _activeSurfaceRawA2ui = null;
          _activeSurfaceSource = null;
          _activeSurfaceFallbackReason = null;
          _activeSurfaceElapsedMs = null;
          _currentIndex = 0;
        });
        _responseAnimController.forward(from: 0);
        return;
      }

      await _ensureJarvisReadyForHome(command);
      if (!_looksLikeHomeCardRequest(command)) {
        final response = await _generateHomeChatReply(command);
        await DatabaseService.instance.saveAiCommand(
          command: command,
          response: response,
          actions: const [],
        );
        if (!mounted) return;
        setState(() {
          _aiResponse = response;
          _activeSurfaceRawA2ui = null;
          _activeSurfaceSource = null;
          _activeSurfaceFallbackReason = null;
          _activeSurfaceElapsedMs = null;
          _currentIndex = 0;
        });
        _responseAnimController.forward(from: 0);
        return;
      }

      final generation = await _homeGenUiRuntimeInstance.generate(
        userMessage: command,
        timeout: const Duration(seconds: 38),
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
        _activeSurfaceSource = generation.source.name;
        _activeSurfaceFallbackReason = generation.fallbackReason;
        _activeSurfaceElapsedMs = generation.elapsed.inMilliseconds;
        _currentIndex = 0;
      });
      _responseAnimController.forward(from: 0);
      _showResponseSnackBar(response);
    } catch (error, stackTrace) {
      if (error is GemmaException &&
          error.code == GemmaErrorCode.modelNotInstalled) {
        if (mounted) unawaited(_openModelDownload());
        return;
      }
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

  Future<void> _ensureJarvisReadyForHome(String message) async {
    debugPrint(
      '[HomeScreen] Loading downloaded model before JARVIS response. '
      'messageLength=${message.length}',
    );
    await GemmaService.instance.loadBestAvailableModel();
  }

  bool _looksLikeHomeCardRequest(String command) {
    final lower = command.toLowerCase().trim();
    if (RegExp(
      r'\b(card|widget|surface|dashboard|tracker|comparison|compare|form)\b',
    ).hasMatch(lower)) {
      return true;
    }
    if (RegExp(r'\b(generate|build|make|create|design)\b').hasMatch(lower)) {
      return RegExp(
        r'\b(plan|schedule|timeline|workout|study|routine|checklist|task list|todo list|time block)\b',
      ).hasMatch(lower);
    }
    return false;
  }

  bool _looksLikeHomeDirectAction(String command) {
    return RegExp(
      r'^(add task|todo|remind me|create task|start focus|focus|add habit|new habit|track habit|note|remember|write down|jot down)\b',
      caseSensitive: false,
    ).hasMatch(command.trim());
  }

  Future<String> _generateHomeChatReply(String command) async {
    final prompt = [
      await ContextProvider.instance.buildChat(userMessage: command),
      'Do not output JSON or UI markup in plain chat.',
      'Answer naturally and directly.',
      'Finish the final sentence before stopping.',
    ].join('\n');
    final response = await GemmaService.instance.generate(
      prompt,
      maxTokens: GemmaService.naturalChatOutputTokens,
      temperature: GemmaService.naturalTemperature,
      topK: GemmaService.naturalTopK,
      topP: GemmaService.naturalTopP,
      timeout: const Duration(seconds: 45),
    );
    final trimmed = response.trim();
    if (trimmed.isEmpty) {
      throw const GemmaException(
        code: GemmaErrorCode.unknown,
        message: 'JARVIS returned an empty home response.',
      );
    }
    return trimmed;
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
    final previousIndex = _currentIndex;
    setState(() => _currentIndex = index);
    if (previousIndex == 3 || index == 0) {
      unawaited(_refreshFocusMinutes());
    }
    DatabaseService.instance.logEvent(
      eventType: 'tab_tap',
      module: ['home', 'tasks', 'habits', 'focus', 'journal'][index],
    );
  }

  Future<void> _refreshFocusMinutes() async {
    final focusMinutes = await DatabaseService.instance.getTodayFocusMinutes();
    if (!mounted) return;
    setState(() => _focusMinutesToday = focusMinutes);
  }

  Future<void> _saveMood(String mood) async {
    final previousMood = _todayMood;
    if (mounted) setState(() => _todayMood = mood);
    try {
      await DatabaseService.instance.saveMood(mood);
    } catch (error, stackTrace) {
      debugPrint('[HomeScreen] Failed to save mood: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _todayMood = previousMood);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your mood. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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

  Future<void> _openVoiceInput() async {
    final transcript = await VoiceInputOverlay.show(
      context,
      initialText: _commandController.text,
    );
    if (!mounted || transcript == null || transcript.trim().isEmpty) return;
    _commandController.clear();
    await _pushChat(
      initialMessage: transcript.trim(),
      startNewOnOpen: true,
      initialMessageDraftOnly: true,
    );
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
            return const ChatScreen(startNewOnOpen: true);
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
          content: Text('Chat screen could not open. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pushChat({
    String? initialMessage,
    bool startNewOnOpen = false,
    bool initialGenerateMode = false,
    bool initialMessageDraftOnly = false,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          initialMessage: initialMessage,
          startNewOnOpen: startNewOnOpen,
          initialGenerateMode: initialGenerateMode,
          initialMessageDraftOnly: initialMessageDraftOnly,
        ),
      ),
    );
  }

  Future<void> _handleHomeSurfaceAction(WidgetAction action) async {
    try {
      if (action.action == 'save_card') {
        await _saveGeneratedCard(action);
        return;
      }
      if (action.action == 'edit_schedule_times') {
        await _editScheduleTimes(action);
        return;
      }
      if (action.action == 'add_schedule_to_tasks') {
        await _addScheduleToTasks(action);
        return;
      }

      final aiAction = GeneratedUiActionMapper.toAiAction(action);
      if (aiAction == null) {
        final message = GeneratedUiActionMapper.continuationMessage(action);
        if (message != null && message.isNotEmpty) {
          await _pushChat(
            initialMessage: message,
            initialGenerateMode: action.action == 'continue_conversation',
            initialMessageDraftOnly: action.action == 'continue_conversation',
          );
        }
        return;
      }
      final result = await ActionExecutor.instance.executeAll([aiAction]);
      if (!mounted) return;
      _showResponseSnackBar(
        result.allSucceeded
            ? 'Done'
            : 'I could not complete that action. Please check the request and try again.',
      );
    } catch (error, stackTrace) {
      debugPrint('[HomeScreen] GenUI action failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        _showResponseSnackBar(
          'I could not complete that card action. Try again.',
        );
      }
    }
  }

  Future<void> _saveGeneratedCard(WidgetAction action) async {
    final rawA2ui = _textParam(action, 'rawA2ui');
    if (rawA2ui == null) {
      _showResponseSnackBar('This card could not be saved.');
      return;
    }
    if (_savedGeneratedCard?.rawA2ui == rawA2ui) {
      _showResponseSnackBar('Already saved on Home');
      return;
    }
    await DatabaseService.instance.saveGeneratedCard(
      title: _textParam(action, 'title') ?? 'Generated card',
      domain: _textParam(action, 'domain') ?? 'card',
      rawA2ui: rawA2ui,
      source: _textParam(action, 'source'),
      fallbackReason: _textParam(action, 'fallbackReason'),
      elapsedMs: _intParam(action, 'elapsedMs'),
    );
    if (!mounted) return;
    setState(() {
      _activeSurfaceRawA2ui = null;
      _activeSurfaceSource = null;
      _activeSurfaceFallbackReason = null;
      _activeSurfaceElapsedMs = null;
    });
    _showResponseSnackBar('Saved to Home');
  }

  Future<void> _editScheduleTimes(WidgetAction action) async {
    final rawA2ui = _textParam(action, 'rawA2ui');
    if (rawA2ui == null) {
      _showResponseSnackBar('This schedule could not be edited.');
      return;
    }
    final updatedRaw = await ScheduleCardEditor.editTimes(
      context: context,
      rawA2ui: rawA2ui,
    );
    if (updatedRaw == null || !mounted) return;

    final savedCard = _savedGeneratedCard;
    if (savedCard != null && savedCard.rawA2ui == rawA2ui) {
      await DatabaseService.instance.saveGeneratedCard(
        title: savedCard.title,
        domain: savedCard.domain,
        rawA2ui: updatedRaw,
        source: savedCard.source,
        fallbackReason: savedCard.fallbackReason,
        elapsedMs: savedCard.elapsedMs,
        originalPrompt: savedCard.originalPrompt,
      );
    } else {
      setState(() {
        _activeSurfaceRawA2ui = updatedRaw;
        _activeSurfaceSource = _textParam(action, 'source');
        _activeSurfaceFallbackReason = _textParam(action, 'fallbackReason');
        _activeSurfaceElapsedMs = _intParam(action, 'elapsedMs');
      });
    }
    if (!mounted) return;
    _showResponseSnackBar('Schedule updated');
  }

  Future<void> _addScheduleToTasks(WidgetAction action) async {
    final rawA2ui = _textParam(action, 'rawA2ui');
    if (rawA2ui == null) {
      _showResponseSnackBar('This schedule could not be converted to tasks.');
      return;
    }
    final actions = ScheduleCardTaskConverter.actionsFromA2ui(rawA2ui);
    if (actions.isEmpty) {
      _showResponseSnackBar('No schedule blocks were found to add.');
      return;
    }
    final result = await ActionExecutor.instance.executeAll(actions);
    if (!mounted) return;
    if (result.failedCount == 0) {
      setState(() => _tasksAddedSurfaceKeys.add(rawA2ui));
    }
    _showResponseSnackBar(_taskActionMessage(result, actions.length));
  }

  String _taskActionMessage(ActionExecutionResult result, int requested) {
    if (result.failedCount == 0 && result.executedCount == 0) {
      return 'Those schedule blocks are already in Tasks';
    }
    if (result.failedCount == 0 && result.ignoredCount > 0) {
      return 'Added ${result.executedCount}; the rest were already in Tasks';
    }
    if (result.allSucceeded) {
      return 'Added $requested schedule block${requested == 1 ? '' : 's'} to Tasks';
    }
    if (result.executedCount > 0) {
      return 'Added ${result.executedCount} of $requested schedule blocks to Tasks';
    }
    return 'I could not add those schedule blocks to Tasks.';
  }

  Future<void> _deleteSavedGeneratedCard(int id) async {
    try {
      await DatabaseService.instance.deleteSavedGeneratedCard(id);
    } catch (error, stackTrace) {
      debugPrint('[HomeScreen] Saved card deletion failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) _showResponseSnackBar('Could not remove this card.');
      return;
    }
    if (!mounted) return;
    _showResponseSnackBar('Removed from Home');
  }

  void _dismissTemporaryGeneratedCard() {
    setState(() {
      _activeSurfaceRawA2ui = null;
      _activeSurfaceSource = null;
      _activeSurfaceFallbackReason = null;
      _activeSurfaceElapsedMs = null;
    });
    _showResponseSnackBar('Card dismissed');
  }

  String? _textParam(WidgetAction action, String key) {
    final value = action.params[key];
    if (value is! String) return null;
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  int? _intParam(WidgetAction action, String key) {
    final value = action.params[key];
    return value is num ? value.round() : null;
  }

  Widget _buildBody() {
    final temporarySurface = _activeSurfaceRawA2ui;
    final showingTemporarySurface = temporarySurface != null;
    final displayedSavedCard = showingTemporarySurface
        ? null
        : _savedGeneratedCard;

    return switch (_currentIndex) {
      0 => RefreshIndicator(
        onRefresh: _loadInitialData,
        child: HomeTab(
          greeting: _greeting,
          hideWordmark: widget.hideWordmark,
          commandController: _commandController,
          isJarvisOnline: GemmaService.instance.isModelLoaded,
          jarvisStatus: _jarvisStatus,
          isProcessingCommand: _isProcessingCommand,
          aiResponse: _aiResponse,
          responseAnimation: _responseAnimController,
          isLoadingInsight: _isLoadingInsight,
          aiInsight: _aiInsight,
          focusMinutesToday: _focusMinutesToday,
          todayMood: _todayMood,
          activeSurfaceTitle: displayedSavedCard?.title,
          activeSurfaceRawA2ui: temporarySurface ?? displayedSavedCard?.rawA2ui,
          activeSurfaceSource: showingTemporarySurface
              ? _activeSurfaceSource
              : displayedSavedCard?.source,
          activeSurfaceFallbackReason: showingTemporarySurface
              ? _activeSurfaceFallbackReason
              : displayedSavedCard?.fallbackReason,
          activeSurfaceElapsedMs: showingTemporarySurface
              ? _activeSurfaceElapsedMs
              : displayedSavedCard?.elapsedMs,
          hiddenActionNames:
              _tasksAddedSurfaceKeys.contains(
                temporarySurface ?? displayedSavedCard?.rawA2ui,
              )
              ? const {'add_schedule_to_tasks'}
              : const {},
          onDeleteActiveSurface: displayedSavedCard == null
              ? (temporarySurface == null
                    ? null
                    : _dismissTemporaryGeneratedCard)
              : () =>
                    unawaited(_deleteSavedGeneratedCard(displayedSavedCard.id)),
          onOpenDashboard: _openDashboard,
          onOpenProfile: _openProfile,
          onOpenVoiceInput: () => unawaited(_openVoiceInput()),
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
            if (_jarvisStatus == JarvisHomeStatus.downloadRequired)
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
                child: ResponsiveWrapper(maxWidth: 1000, child: _buildBody()),
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
