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

  AiCommandResult({
    required this.actions,
    required this.response,
    this.greetingUpdate,
    this.layoutOrder,
  });

  factory AiCommandResult.fromJson(Map<String, dynamic> json) {
    return AiCommandResult(
      actions: (json['actions'] as List<dynamic>?)
              ?.map((a) => AiAction.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      response: json['response'] as String? ?? 'Done!',
      greetingUpdate: json['greeting_update'] as String?,
      layoutOrder: (json['layout_order'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
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
  }) async {
    try {
      final Map<String, dynamic> finalContext = Map.from(context ?? {});
      final backgroundData = await FirebaseService.instance.buildContextSnapshot();
      finalContext['background_data'] = backgroundData;

      final payload = jsonEncode({
        'command': command,
        'user_name': userName,
        'context': finalContext,
      });

      final response = await _postJsonWithFallback(
        paths: const ['/command', '/ai-command'],
        body: payload,
        timeout: const Duration(seconds: 45),
      );

      if (response.statusCode == 200) {
        return AiCommandResult.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception('Backend returned ${response.statusCode}');
    } catch (e) {
      debugPrint('AI Command — backend unavailable, using local fallback: $e');
      return _processLocally(command, userName, e is TimeoutException);
    }
  }

  AiCommandResult _processLocally(String command, String userName, bool isTimeout) {
    final lower = command.toLowerCase().trim();
    final fallbackResponse = isTimeout 
        ? "JARVIS is thinking deeply about this. I've saved it as a task for now so we don't lose it!"
        : "I'm having trouble connecting to JARVIS. I've added this to your tasks locally.";

    // ── Task patterns ──
    if (_matchesAny(lower, ['add task', 'todo', 'remind me', 'create task'])) {
      final title = _extractAfter(
        command,
        ['add task', 'todo', 'remind me to', 'remind me', 'create task'],
      );
      if (title.isNotEmpty) {
        return AiCommandResult(
          actions: [
            AiAction(
              type: 'add_task',
              params: {
                'title': title,
                'priority': _detectPriority(lower),
              },
            ),
          ],
          response: 'Added "$title" to your tasks.',
          layoutOrder: ['TasksModule', 'FocusTimerModule', 'HabitModule', 'NotesModule'],
        );
      } else {
        return AiCommandResult(
          actions: [],
          response: 'What task would you like to add?',
          layoutOrder: ['TasksModule', 'FocusTimerModule', 'HabitModule', 'NotesModule'],
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
      return AiCommandResult(
        actions: [
          AiAction(
            type: 'start_focus',
            params: {'duration_minutes': minutes},
          ),
        ],
        response: 'Focus mode activated. $minutes-minute session ready.',
        greetingUpdate: 'Deep focus mode, $userName.',
        layoutOrder: ['FocusTimerModule', 'TasksModule', 'NotesModule', 'HabitModule'],
      );
    }

    // ── Dynamic planning / advice patterns ──
    if (_matchesAny(lower, ['workout', 'exercise', 'routine', 'plan', 'planner', 'advice'])) {
      final isWorkout = _matchesAny(lower, ['workout', 'exercise']);
      final isPlanner = !isWorkout && _matchesAny(lower, ['plan', 'planner', 'routine']);
      final cardType = isWorkout ? 'workout' : (isPlanner ? 'planner' : 'advice');
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
                'task_payload': {'title': 'Do a 5 min mobility warm-up', 'priority': 'normal'}
              },
              {
                'text': '20 min main set',
                'task_payload': {'title': 'Complete a 20 min workout block', 'priority': 'high'}
              },
              {
                'text': '5 min cooldown',
                'task_payload': {'title': 'Finish with a 5 min cooldown', 'priority': 'normal'}
              },
            ]
          : [
              {
                'text': 'Pick the one outcome that matters most',
                'task_payload': {'title': 'Define the main outcome for today', 'priority': 'high'}
              },
              {
                'text': 'Break it into a 25 min sprint',
                'task_payload': {'title': 'Run one 25 min sprint on the main outcome', 'priority': 'normal'}
              },
              {
                'text': 'Capture the next step before you stop',
                'task_payload': {'title': 'Write down the next step before stopping', 'priority': 'normal'}
              },
            ];

      return AiCommandResult(
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
      final name = _extractAfter(
        command,
        ['add habit', 'track', 'new habit'],
      );
      if (name.isNotEmpty) {
        return AiCommandResult(
          actions: [
            AiAction(type: 'add_habit', params: {'name': name, 'icon': ''}),
          ],
          response: 'Now tracking "$name" as a daily habit.',
          layoutOrder: ['HabitModule', 'FocusTimerModule', 'TasksModule', 'NotesModule'],
        );
      } else {
        return AiCommandResult(
          actions: [],
          response: 'What habit would you like to build?',
          layoutOrder: ['HabitModule', 'FocusTimerModule', 'TasksModule', 'NotesModule'],
        );
      }
    }

    // ── Note patterns ──
    if (_matchesAny(lower, ['note', 'remember', 'write down', 'jot down'])) {
      final content = _extractAfter(
        command,
        ['note', 'remember', 'write down', 'jot down'],
      );
      if (content.isNotEmpty) {
        return AiCommandResult(
          actions: [
            AiAction(type: 'add_note', params: {'content': content}),
          ],
          response: 'Saved to your notes.',
          layoutOrder: ['NotesModule', 'FocusTimerModule', 'TasksModule', 'HabitModule'],
        );
      } else {
        return AiCommandResult(
          actions: [],
          response: 'What do you want to note down?',
          layoutOrder: ['NotesModule', 'FocusTimerModule', 'TasksModule', 'HabitModule'],
        );
      }
    }

    // ── Prioritize Module Display patterns ──
    if (_matchesAny(lower, ['show task', 'my task', 'open task', 'go to task'])) {
      return AiCommandResult(
        actions: [],
        response: 'Here are your tasks.',
        layoutOrder: ['TasksModule', 'FocusTimerModule', 'HabitModule', 'NotesModule'],
      );
    }
    if (_matchesAny(lower, ['show habit', 'my habit', 'open habit'])) {
      return AiCommandResult(
        actions: [],
        response: 'Here are your habits.',
        layoutOrder: ['HabitModule', 'TasksModule', 'FocusTimerModule', 'NotesModule'],
      );
    }
    if (_matchesAny(lower, ['show note', 'my note', 'open note'])) {
      return AiCommandResult(
        actions: [],
        response: 'Here are your notes.',
        layoutOrder: ['NotesModule', 'TasksModule', 'FocusTimerModule', 'HabitModule'],
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
      'stuck'
    ])) {
      if (_matchesAny(lower, ['overwhelmed', 'stressed', 'stuck', 'help'])) {
        return AiCommandResult(
          actions: [
            AiAction(
              type: 'show_dynamic_card',
              params: {
                'card': {
                  'title': 'Overwhelm Protocol',
                  'type': 'advice',
                  'description': 'Take a breath, $userName. I\'ve moved your Focus Timer and Tasks to the top. Just pick one thing.',
                  'list_items': [
                    {'text': 'Hide your phone', 'task_payload': null},
                    {'text': 'Start a 15 min focus block', 'task_payload': null},
                    {'text': 'Knock out one task from the top', 'task_payload': null}
                  ],
                  'action_label': 'Start 15min Block',
                  'action_module': 'FocusTimerModule'
                }
              },
            )
          ],
          response:
              'Take a breath, $userName. I\'ve built a quick protocol to get you back on track.',
          layoutOrder: ['GenerativeCardModule', 'FocusTimerModule', 'TasksModule', 'HabitModule', 'NotesModule'],
        );
      }
      final messages = [
        'You\'re already ahead by showing up, $userName. Keep pushing.',
        'Small steps still move you forward, $userName. Let\'s go.',
        'The compound effect of consistency is unstoppable, $userName.',
      ];
      return AiCommandResult(
        actions: [],
        response: messages[DateTime.now().second % messages.length],
      );
    }

    // ── Default: treat as a task if it was a real command ──
    if (lower.length > 5) {
      return AiCommandResult(
        actions: [
          AiAction(
            type: 'add_task',
            params: {'title': command.trim(), 'priority': 'normal'},
          ),
        ],
        response: fallbackResponse,
      );
    }

    return AiCommandResult(
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
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── AI Insight Fetching ────────────────────────────────────

  Future<String> fetchInsight({
    required String userName,
    Map<String, dynamic>? stats,
  }) async {
    // Fast fail if status check is not healthy
    final isOnline = await checkBackendStatus();
    if (!isOnline) {
      debugPrint('AI Insight — skipping fetch (JARVIS offline)');
      return _cachedInsight ?? _localInsight(userName);
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/ai-insight'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_name': userName,
              'stats': stats ?? {},
            }),
          )
          .timeout(const Duration(seconds: 35)); // Hardened to 35s for unreliable network/slow LLM

      if (response.statusCode == 200) {
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

  String get cachedInsight => _cachedInsight ?? '';

  Future<http.Response> _postJsonWithFallback({
    required List<String> paths,
    required String body,
    required Duration timeout,
  }) async {
    Object? lastError;

    for (final path in paths) {
      try {
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
      } catch (error) {
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
    result = result.replaceFirst(RegExp(r'^(to|that|the)\s+', caseSensitive: false), '');
    return result.trim();
  }

  String _detectPriority(String input) {
    if (input.contains('urgent') || input.contains('important') || input.contains('asap')) {
      return 'high';
    }
    if (input.contains('medium') || input.contains('soon')) return 'medium';
    return 'normal';
  }
}
