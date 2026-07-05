import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'ai/context_provider.dart';
import 'local_llm/gemma_service.dart';

/// Result model for an AI command
class AiCommandResult {
  final List<AiAction> actions;
  final String response;
  final String? greetingUpdate;

  AiCommandResult({
    required this.actions,
    required this.response,
    this.greetingUpdate,
  });
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
    int? conversationId,
  }) async {
    AiCommandResult build({
      required List<AiAction> actions,
      required String response,
      String? greetingUpdate,
    }) {
      return AiCommandResult(
        actions: actions,
        response: response,
        greetingUpdate: greetingUpdate,
      );
    }

    final lower = command.toLowerCase().trim();

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
        );
      } else {
        return build(actions: [], response: 'What task would you like to add?');
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
        );
      } else {
        return build(
          actions: [],
          response: 'What habit would you like to build?',
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
        );
      } else {
        return build(actions: [], response: 'What do you want to note down?');
      }
    }

    // ── Prioritize Module Display patterns ──
    if (_matchesAny(lower, [
      'show task',
      'my task',
      'open task',
      'go to task',
    ])) {
      return build(actions: [], response: 'Here are your tasks.');
    }
    if (_matchesAny(lower, ['show habit', 'my habit', 'open habit'])) {
      return build(actions: [], response: 'Here are your habits.');
    }
    if (_matchesAny(lower, ['show note', 'my note', 'open note'])) {
      return build(actions: [], response: 'Here are your notes.');
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
    if (!GemmaService.instance.isModelLoaded) {
      try {
        await GemmaService.instance.loadBestAvailableModel(
          timeout: const Duration(seconds: 45),
        );
      } catch (error, stack) {
        debugPrint('[AiService] GemmaService load failed: $error');
        debugPrint('[AiService]   Stack: $stack');
      }
    }

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

    return build(
      actions: [],
      response: isTimeout
          ? 'JARVIS is still initializing. Try again in a moment.'
          : 'JARVIS needs the local model ready before it can answer that.',
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
      return '$remaining behavior signal${remaining == 1 ? '' : 's'} still open today. Make the next move tiny.';
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
