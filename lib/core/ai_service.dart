import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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

  static const _backendUrl = 'http://localhost:8000';
  String? _cachedInsight;

  // ── AI Command Processing ─────────────────────────────────

  Future<AiCommandResult> processCommand({
    required String command,
    required String userName,
    Map<String, dynamic>? context,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/ai-command'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'command': command,
              'user_name': userName,
              'context': context ?? {},
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return AiCommandResult.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception('Backend returned ${response.statusCode}');
    } catch (e) {
      debugPrint('AI Command — backend unavailable, using local: $e');
      return _processLocally(command, userName);
    }
  }

  AiCommandResult _processLocally(String command, String userName) {
    final lower = command.toLowerCase().trim();

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

    // ── Motivation patterns ──
    if (_matchesAny(lower, ['motivat', 'inspir', 'pep talk', 'encourage'])) {
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

    // ── Default: treat as a task ──
    if (lower.length > 3) {
      return AiCommandResult(
        actions: [
          AiAction(
            type: 'add_task',
            params: {'title': command.trim(), 'priority': 'normal'},
          ),
        ],
        response: 'Added "${command.trim()}" as a task!',
      );
    }

    return AiCommandResult(
      actions: [],
      response:
          'Try: "add task buy groceries", "focus 25 min", "add habit morning run", or "note call mom"',
    );
  }

  // ── AI Insight Fetching ────────────────────────────────────

  Future<String> fetchInsight({
    required String userName,
    Map<String, dynamic>? stats,
  }) async {
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
          .timeout(const Duration(seconds: 10));

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
          .timeout(const Duration(seconds: 10));
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
