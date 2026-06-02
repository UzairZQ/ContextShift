import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';

/// Result model for an AI command
class AiCommandResult {
  final List<AiAction> actions;
  final String response;
  final String? greetingUpdate;
  final List<String>? layoutOrder;
  final bool fromBackend;

  AiCommandResult({
    required this.actions,
    required this.response,
    this.greetingUpdate,
    this.layoutOrder,
    this.fromBackend = false,
  });

  factory AiCommandResult.fromJson(
    Map<String, dynamic> json, {
    bool fromBackend = false,
  }) {
    return AiCommandResult(
      actions:
          (json['actions'] as List<dynamic>?)
              ?.map((a) => AiAction.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      response: json['response'] as String? ?? 'Done!',
      greetingUpdate: json['greeting_update'] as String?,
      layoutOrder: (json['layout_order'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      fromBackend: fromBackend,
    );
  }
}

class AiAction {
  final String type;
  final Map<String, dynamic> params;

  AiAction({required this.type, required this.params});

  factory AiAction.fromJson(Map<String, dynamic> json) {
    return AiAction(
      type: json['type'] as String? ?? '',
      params: (json['params'] as Map<String, dynamic>?) ?? {},
    );
  }
}

/// Singleton AI service — offline-first with backend fallback
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  static const String _configuredBackendUrl = String.fromEnvironment(
    'AI_BACKEND_URL',
    defaultValue: '',
  );
  String? _cachedInsight;
  bool _lastInsightFetchSucceeded = false;
  DateTime? _lastSuccessfulBackendResponseAt;

  String get _backendUrl {
    if (_configuredBackendUrl.isNotEmpty) {
      return _configuredBackendUrl;
    }
    if (kIsWeb) return 'http://localhost:8000';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://localhost:8000';
      default:
        return 'http://localhost:8000';
    }
  }

  // ── AI Command Processing ─────────────────────────────────

  Future<AiCommandResult> processCommand({
    required String command,
    required String userName,
    Map<String, dynamic>? context,
  }) {
    return _performCommand(
      command: command,
      userName: userName,
      context: context,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint(
          'AI Command — overall command timeout, using local fallback',
        );
        return _processLocally(command, userName, true);
      },
    );
  }

  Future<AiCommandResult> _performCommand({
    required String command,
    required String userName,
    Map<String, dynamic>? context,
  }) async {
    debugPrint('AI Command — starting command: "$command"');
    try {
      final isBackendOnline = await checkBackendStatus();
      debugPrint('AI Command — backend status: $isBackendOnline');
      if (!isBackendOnline) {
        debugPrint(
          'AI Command — backend offline, using local fallback immediately',
        );
        return _processLocally(command, userName, true);
      }

      final Map<String, dynamic> finalContext = Map.from(context ?? {});
      final backgroundData = await _buildContextSnapshotWithTimeout();
      finalContext['background_data'] = backgroundData;

      final payload = jsonEncode({
        'command': command,
        'user_name': userName,
        'context': finalContext,
      });

      final response = await _postJsonWithFallback(
        paths: const ['/command', '/ai-command'],
        body: payload,
        timeout: const Duration(seconds: 10),
      );
      debugPrint('AI Command — backend returned status ${response.statusCode}');

      if (response.statusCode == 200) {
        _recordBackendSuccess();
        final parsed = AiCommandResult.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
          fromBackend: true,
        );
        if (_shouldUseLocalFallback(parsed)) {
          debugPrint(
            'AI Command — backend returned fallback copy, using local parser',
          );
          return _processLocally(command, userName, false, fromBackend: true);
        }
        return parsed;
      }
      throw Exception('Backend returned ${response.statusCode}');
    } catch (e, stack) {
      debugPrint('AI Command — backend unavailable, using local fallback: $e');
      debugPrint(stack.toString());
      return _processLocally(command, userName, e is TimeoutException);
    }
  }

  Future<Map<String, dynamic>> _buildContextSnapshotWithTimeout() async {
    try {
      return await FirebaseService.instance.buildContextSnapshot().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint(
            'AI Command — context snapshot timeout, using empty context',
          );
          return <String, dynamic>{};
        },
      );
    } catch (e, stack) {
      debugPrint('AI Command — context snapshot error: $e');
      debugPrint(stack.toString());
      return {};
    }
  }

  bool _shouldUseLocalFallback(AiCommandResult result) {
    if (result.actions.isNotEmpty) return false;

    final lower = result.response.toLowerCase();
    return lower.contains('timed out') ||
        lower.contains('trouble processing') ||
        lower.contains('help locally');
  }

  AiCommandResult _processLocally(
    String command,
    String userName,
    bool isTimeout, {
    bool fromBackend = false,
  }) {
    AiCommandResult build({
      required List<AiAction> actions,
      required String response,
      String? greetingUpdate,
      List<String>? layoutOrder,
    }) {
      return AiCommandResult(
        actions: actions,
        response: response,
        greetingUpdate: greetingUpdate,
        layoutOrder: layoutOrder,
        fromBackend: fromBackend,
      );
    }

    final lower = command.toLowerCase().trim();
    final fallbackResponse = isTimeout
        ? "JARVIS is thinking deeply about this. I've saved it as a task for now so we don't lose it!"
        : "I'm having trouble connecting to JARVIS. I've added this to your tasks locally.";

    // ── Task patterns ──
    if (_matchesAny(lower, ['add task', 'todo', 'remind me', 'create task'])) {
      final title = _extractAfter(command, [
        'add task',
        'todo',
        'remind me to',
        'remind me',
        'create task',
      ]);
      if (title.isNotEmpty) {
        return build(
          actions: [
            AiAction(
              type: 'add_task',
              params: {'title': title, 'priority': _detectPriority(lower)},
            ),
          ],
          response: 'Added "$title" to your tasks.',
          layoutOrder: [
            'TasksModule',
            'FocusTimerModule',
            'HabitModule',
            'NotesModule',
          ],
        );
      } else {
        return build(
          actions: [],
          response: 'What task would you like to add?',
          layoutOrder: [
            'TasksModule',
            'FocusTimerModule',
            'HabitModule',
            'NotesModule',
          ],
        );
      }
    }

    // ── Focus patterns ──
    if (_matchesAny(lower, [
      'focus',
      'study',
      'deep work',
      'pomodoro',
      'concentrate',
      'work session',
    ])) {
      int minutes = 25;
      final numMatch = RegExp(r'(\d+)\s*min').firstMatch(lower);
      if (numMatch != null) minutes = int.parse(numMatch.group(1)!);
      return build(
        actions: [
          AiAction(type: 'start_focus', params: {'duration_minutes': minutes}),
        ],
        response: 'Focus mode activated. $minutes-minute session ready.',
        greetingUpdate: 'Deep focus mode, $userName.',
        layoutOrder: [
          'FocusTimerModule',
          'TasksModule',
          'NotesModule',
          'HabitModule',
        ],
      );
    }

    // ── Dynamic planning / advice patterns ──
    if (_matchesAny(lower, [
      'workout',
      'exercise',
      'routine',
      'plan',
      'planner',
      'advice',
    ])) {
      final isWorkout = _matchesAny(lower, ['workout', 'exercise']);
      final isPlanner =
          !isWorkout && _matchesAny(lower, ['plan', 'planner', 'routine']);
      final cardType = isWorkout
          ? 'workout'
          : (isPlanner ? 'planner' : 'advice');
      final cardTitle = isWorkout
          ? 'Quick Workout Builder'
          : (isPlanner ? 'Adaptive Plan' : 'Jarvis Guidance');
      final cardDescription = isWorkout
          ? 'Built around your prompt, $userName. Tap any step to turn it into a task.'
          : (isPlanner
                ? 'Here is a focused structure based on what you asked for. Tap a step to add it to your backlog.'
                : 'A short action stack to help you move forward right now.');
      final listItems = isWorkout
          ? [
              {
                'text': '5 min mobility warm-up',
                'task_payload': {
                  'title': 'Do a 5 min mobility warm-up',
                  'priority': 'normal',
                },
              },
              {
                'text': '20 min main set',
                'task_payload': {
                  'title': 'Complete a 20 min workout block',
                  'priority': 'high',
                },
              },
              {
                'text': '5 min cooldown',
                'task_payload': {
                  'title': 'Finish with a 5 min cooldown',
                  'priority': 'normal',
                },
              },
            ]
          : [
              {
                'text': 'Pick the one outcome that matters most',
                'task_payload': {
                  'title': 'Define the main outcome for today',
                  'priority': 'high',
                },
              },
              {
                'text': 'Break it into a 25 min sprint',
                'task_payload': {
                  'title': 'Run one 25 min sprint on the main outcome',
                  'priority': 'normal',
                },
              },
              {
                'text': 'Capture the next step before you stop',
                'task_payload': {
                  'title': 'Write down the next step before stopping',
                  'priority': 'normal',
                },
              },
            ];

      return build(
        actions: [
          AiAction(
            type: 'show_dynamic_card',
            params: {
              'card': {
                'title': cardTitle,
                'type': cardType,
                'description': cardDescription,
                'list_items': listItems,
                'action_label': isWorkout ? 'Open Tasks' : 'Start Focus',
                'action_module': isWorkout ? 'TasksModule' : 'FocusTimerModule',
              },
            },
          ),
        ],
        response: 'I built a live card for that request.',
        layoutOrder: const [
          'GenerativeCardModule',
          'FocusTimerModule',
          'TasksModule',
          'HabitModule',
          'NotesModule',
        ],
      );
    }

    // ── Habit patterns ──
    if (_matchesAny(lower, ['add habit', 'track', 'new habit'])) {
      final name = _extractAfter(command, ['add habit', 'track', 'new habit']);
      if (name.isNotEmpty) {
        return build(
          actions: [
            AiAction(type: 'add_habit', params: {'name': name, 'icon': ''}),
          ],
          response: 'Now tracking "$name" as a daily habit.',
          layoutOrder: [
            'HabitModule',
            'FocusTimerModule',
            'TasksModule',
            'NotesModule',
          ],
        );
      } else {
        return build(
          actions: [],
          response: 'What habit would you like to build?',
          layoutOrder: [
            'HabitModule',
            'FocusTimerModule',
            'TasksModule',
            'NotesModule',
          ],
        );
      }
    }

    // ── Note patterns ──
    if (_matchesAny(lower, ['note', 'remember', 'write down', 'jot down'])) {
      final content = _extractAfter(command, [
        'note',
        'remember',
        'write down',
        'jot down',
      ]);
      if (content.isNotEmpty) {
        return build(
          actions: [
            AiAction(type: 'add_note', params: {'content': content}),
          ],
          response: 'Saved to your notes.',
          layoutOrder: [
            'NotesModule',
            'FocusTimerModule',
            'TasksModule',
            'HabitModule',
          ],
        );
      } else {
        return build(
          actions: [],
          response: 'What do you want to note down?',
          layoutOrder: [
            'NotesModule',
            'FocusTimerModule',
            'TasksModule',
            'HabitModule',
          ],
        );
      }
    }

    // ── Prioritize Module Display patterns ──
    if (_matchesAny(lower, [
      'show task',
      'my task',
      'open task',
      'go to task',
    ])) {
      return build(
        actions: [],
        response: 'Here are your tasks.',
        layoutOrder: [
          'TasksModule',
          'FocusTimerModule',
          'HabitModule',
          'NotesModule',
        ],
      );
    }
    if (_matchesAny(lower, ['show habit', 'my habit', 'open habit'])) {
      return build(
        actions: [],
        response: 'Here are your habits.',
        layoutOrder: [
          'HabitModule',
          'TasksModule',
          'FocusTimerModule',
          'NotesModule',
        ],
      );
    }
    if (_matchesAny(lower, ['show note', 'my note', 'open note'])) {
      return build(
        actions: [],
        response: 'Here are your notes.',
        layoutOrder: [
          'NotesModule',
          'TasksModule',
          'FocusTimerModule',
          'HabitModule',
        ],
      );
    }

    // ── Motivation / Support patterns ──
    if (_matchesAny(lower, [
      'motivat',
      'inspir',
      'pep talk',
      'encourage',
      'overwhelmed',
      'stressed',
      'help',
      'stuck',
    ])) {
      if (_matchesAny(lower, ['overwhelmed', 'stressed', 'stuck', 'help'])) {
        return build(
          actions: [
            AiAction(
              type: 'show_dynamic_card',
              params: {
                'card': {
                  'title': 'Overwhelm Protocol',
                  'type': 'advice',
                  'description':
                      'Take a breath, $userName. I\'ve moved your Focus Timer and Tasks to the top. Just pick one thing.',
                  'list_items': [
                    {'text': 'Hide your phone', 'task_payload': null},
                    {
                      'text': 'Start a 15 min focus block',
                      'task_payload': null,
                    },
                    {
                      'text': 'Knock out one task from the top',
                      'task_payload': null,
                    },
                  ],
                  'action_label': 'Start 15min Block',
                  'action_module': 'FocusTimerModule',
                },
              },
            ),
          ],
          response:
              'Take a breath, $userName. I\'ve built a quick protocol to get you back on track.',
          layoutOrder: [
            'GenerativeCardModule',
            'FocusTimerModule',
            'TasksModule',
            'HabitModule',
            'NotesModule',
          ],
        );
      }
      final messages = [
        'You\'re already ahead by showing up, $userName. Keep pushing.',
        'Small steps still move you forward, $userName. Let\'s go.',
        'The compound effect of consistency is unstoppable, $userName.',
      ];
      return build(
        actions: [],
        response: messages[DateTime.now().second % messages.length],
      );
    }

    // ── Default: treat as a task if it was a real command ──
    if (lower.length > 5) {
      return build(
        actions: [
          AiAction(
            type: 'add_task',
            params: {'title': command.trim(), 'priority': 'normal'},
          ),
        ],
        response: fallbackResponse,
      );
    }

    return build(
      actions: [],
      response:
          'Try: "add task buy groceries", "focus 25 min", "add habit morning run", or "note call mom"',
    );
  }

  // ── Health Check ──────────────────────────────────────────

  Future<bool> checkBackendStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$_backendUrl/health'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        _recordBackendSuccess();
        return true;
      }
    } catch (_) {
      // ignore
    }
    return _hasRecentBackendSuccess;
  }

  bool get _hasRecentBackendSuccess {
    final last = _lastSuccessfulBackendResponseAt;
    return last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 30);
  }

  void _recordBackendSuccess() {
    _lastSuccessfulBackendResponseAt = DateTime.now();
  }

  // ── AI Insight Fetching ────────────────────────────────────

  Future<String> fetchInsight({
    required String userName,
    Map<String, dynamic>? stats,
  }) async {
    _lastInsightFetchSucceeded = false;

    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/ai-insight'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_name': userName, 'stats': stats ?? {}}),
          )
          .timeout(
            const Duration(seconds: 35),
          ); // Hardened to 35s for unreliable network/slow LLM

      if (response.statusCode == 200) {
        _recordBackendSuccess();
        _lastInsightFetchSucceeded = true;
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final insight = data['insight'] as String;
        _cachedInsight = insight;
        return insight;
      }
      throw Exception('Status ${response.statusCode}');
    } catch (e) {
      debugPrint('AI Insight fetch error: $e');
      return _cachedInsight ?? _localInsight(userName);
    }
  }

  bool get lastInsightFetchSucceeded => _lastInsightFetchSucceeded;

  String get cachedInsight => _cachedInsight ?? '';

  Future<http.Response> _postJsonWithFallback({
    required List<String> paths,
    required String body,
    required Duration timeout,
  }) async {
    Object? lastError;

    for (final path in paths) {
      try {
        debugPrint('AI Command — trying backend path: $_backendUrl$path');
        final response = await http
            .post(
              Uri.parse('$_backendUrl$path'),
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(timeout);

        if (response.statusCode != 404) {
          return response;
        }
        lastError = Exception('Endpoint not found: $path');
      } catch (error, stack) {
        debugPrint('AI Command — backend path failed: $path');
        debugPrint(error.toString());
        debugPrint(stack.toString());
        lastError = error;
      }
    }

    throw lastError ?? Exception('Unable to reach AI backend');
  }

  String _localInsight(String userName) {
    final hour = DateTime.now().hour;
    if (hour < 10) {
      return 'Morning sessions have the highest completion rates. Start with your most important task, $userName.';
    } else if (hour < 14) {
      return 'Peak productivity window. Consider a focused sprint before the afternoon dip.';
    } else if (hour < 18) {
      return 'Review your progress so far. Close open loops before evening, $userName.';
    } else {
      return 'Wind down with a light habit check and plan tomorrow\'s top 3 priorities.';
    }
  }

  // ── Note Summarization ─────────────────────────────────────

  Future<String?> summarizeNote(String content) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/summarize'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'content': content}),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as Map<String, dynamic>)['summary']
            as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Summarize error: $e');
      return null;
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  bool _matchesAny(String input, List<String> patterns) {
    return patterns.any((p) => input.contains(p));
  }

  String _extractAfter(String input, List<String> prefixes) {
    String result = input;
    for (final prefix in prefixes) {
      final regex = RegExp(prefix, caseSensitive: false);
      final match = regex.firstMatch(result);
      if (match != null) {
        result = result.substring(match.end).trim();
        break;
      }
    }
    // Clean up common filler words
    result = result.replaceFirst(
      RegExp(r'^(to|that|the)\s+', caseSensitive: false),
      '',
    );
    return result.trim();
  }

  String _detectPriority(String input) {
    if (input.contains('urgent') ||
        input.contains('important') ||
        input.contains('asap')) {
      return 'high';
    }
    if (input.contains('medium') || input.contains('soon')) return 'medium';
    return 'normal';
  }
}
