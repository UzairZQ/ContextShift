import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'ai/context_provider.dart';
import 'local_llm/gemma_service.dart';

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

/// Singleton AI service — fully offline (keyword parser + on-device Gemma)
class AiService {
  AiService._();
  static final AiService instance = AiService._();

  String? _cachedInsight;
  String? _cachedInsightKey;

  // ── AI Command Processing ─────────────────────────────────

  Future<AiCommandResult> processCommand({
    required String command,
    required String userName,
    Map<String, dynamic>? context,
    int? conversationId,
  }) async {
    debugPrint('AI Command — processing locally: "$command"');
    return _processLocally(
      command,
      userName,
      false,
      conversationId: conversationId,
    );
  }

  Future<AiCommandResult> _processLocally(
    String command,
    String userName,
    bool isTimeout, {
    bool fromBackend = false,
    int? conversationId,
  }) async {
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

    // ── GemmaService fallback (on-device AI) ──
    if (GemmaService.instance.isModelLoaded) {
      try {
        debugPrint('[AiService] Trying GemmaService for: "$command"');
        final prompt = await ContextProvider.instance.build(
          userMessage: command,
          conversationId: conversationId,
        );
        final gemmaResponse = await GemmaService.instance.generate(
          prompt,
          maxTokens: 256,
          timeout: const Duration(seconds: 10),
        );

        // Try to parse as JSON
        final start = gemmaResponse.indexOf('{');
        final end = gemmaResponse.lastIndexOf('}');
        if (start != -1 && end != -1 && end > start) {
          final jsonStr = gemmaResponse.substring(start, end + 1);
          final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
          debugPrint('[AiService] GemmaService returned: $parsed');
          return build(
            actions:
                (parsed['actions'] as List<dynamic>?)
                    ?.map((a) => AiAction.fromJson(a as Map<String, dynamic>))
                    .toList() ??
                [],
            response: parsed['response'] as String? ?? 'Done!',
          );
        }
      } catch (e, stack) {
        debugPrint('[AiService] GemmaService fallback failed: $e');
        debugPrint('[AiService]   Stack: $stack');
      }
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

  // ── AI Insight (fully offline) ─────────────────────────────

  Future<String> fetchInsight({
    required String userName,
    Map<String, dynamic>? stats,
  }) async {
    final now = DateTime.now();
    final insightKey = jsonEncode({
      'user': userName,
      'timeWindow': now.hour ~/ 4,
      'stats': stats ?? const <String, dynamic>{},
    });
    if (_cachedInsight == null || _cachedInsightKey != insightKey) {
      _cachedInsight = _localInsight(userName, stats ?? const {});
      _cachedInsightKey = insightKey;
    }
    return _cachedInsight!;
  }

  bool get lastInsightFetchSucceeded => true;

  String get cachedInsight => _cachedInsight ?? '';

  String _localInsight(String userName, Map<String, dynamic> stats) {
    final openTasks = stats['open_tasks'] as int? ?? 0;
    final completedTasks = stats['completed_tasks'] as int? ?? 0;
    final totalHabits = stats['total_habits'] as int? ?? 0;
    final completedHabits = stats['completed_habits_today'] as int? ?? 0;
    final focusMinutes = stats['focus_minutes_today'] as int? ?? 0;

    if (openTasks >= 4 && completedTasks == 0) {
      return 'You have $openTasks open tasks. Pick one small win first, $userName, then reassess.';
    }
    if (totalHabits > 0 && completedHabits < totalHabits) {
      final remaining = totalHabits - completedHabits;
      return '$remaining habit${remaining == 1 ? '' : 's'} left today. A quick check-in can protect your momentum.';
    }
    if (focusMinutes >= 60) {
      return 'You have already logged $focusMinutes focused minutes today. Take a short recovery break before the next sprint.';
    }

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

  // ── Note Summarization (no-op stub, GemmaService can be wired later) ──

  Future<String?> summarizeNote(String content) async {
    debugPrint('[AiService] summarizeNote: no backend — returning null');
    return null;
  }

  /// Quick classifier — returns true if the input matches a known command pattern.
  /// Used to decide: process inline vs route to ChatScreen.
  bool isCommandQuery(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.length < 3) return false;
    return _matchesAny(lower, [
      'add task',
      'todo',
      'remind me',
      'create task',
      'focus',
      'study',
      'deep work',
      'pomodoro',
      'concentrate',
      'work session',
      'workout',
      'exercise',
      'routine',
      'plan',
      'planner',
      'advice',
      'add habit',
      'track',
      'new habit',
      'note',
      'remember',
      'write down',
      'jot down',
      'show task',
      'my task',
      'open task',
      'go to task',
      'show habit',
      'my habit',
      'open habit',
      'show note',
      'my note',
      'open note',
      'motivat',
      'inspir',
      'pep talk',
      'encourage',
      'overwhelmed',
      'stressed',
      'help',
      'stuck',
    ]);
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
