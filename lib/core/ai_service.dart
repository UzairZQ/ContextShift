import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'ai/context_provider.dart';
import 'local_llm/gemma_service.dart';
import 'services/feature_manager.dart';

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

/// Singleton AI service — fully offline, Gemma-first.
///
/// Explicit commands ("add task buy milk") are parsed deterministically for
/// instant feedback. Everything else goes straight to the on-device model
/// with retrieval-ranked context; there are no canned reply paths while a
/// model is available.
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
    final trimmed = command.trim();
    debugPrint('AI Command — processing locally: "$trimmed"');

    // Deterministic fast path for unambiguous, explicitly phrased commands.
    final direct = _parseExplicitCommand(trimmed, userName);
    if (direct != null) return direct;

    // Everything else: on-device model with full context.
    if (!FeatureManager.instance.isE2bAvailable) {
      return AiCommandResult(
        actions: const [],
        response:
            'The on-device model is not installed yet. Download JARVIS in '
            'Settings to unlock full understanding.',
      );
    }

    if (!GemmaService.instance.isModelLoaded) {
      await GemmaService.instance.loadBestAvailableModel(
        timeout: const Duration(seconds: 60),
      );
    }

    final prompt = await ContextProvider.instance.build(
      userMessage: trimmed,
      conversationId: conversationId,
    );
    var raw = await GemmaService.instance.generate(
      prompt,
      maxTokens: 512,
      temperature: 0.35,
      topK: 32,
      timeout: const Duration(seconds: 40),
    );
    var parsed = _extractResultJson(raw);
    if (parsed == null) {
      debugPrint('[AiService] First pass returned invalid JSON, repairing');
      raw = await GemmaService.instance.generate(
        _repairPrompt(trimmed, raw),
        maxTokens: 400,
        temperature: 0.1,
        timeout: const Duration(seconds: 30),
      );
      parsed = _extractResultJson(raw);
    }

    if (parsed != null) {
      final actions =
          (parsed['actions'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(AiAction.fromJson)
              .where((a) => a.type.isNotEmpty)
              .toList() ??
          const <AiAction>[];
      final response = (parsed['response'] as String?)?.trim() ?? '';
      if (response.isNotEmpty || actions.isNotEmpty) {
        return AiCommandResult(
          actions: actions,
          response: response.isEmpty ? 'Done.' : response,
        );
      }
    }

    // Model answered but not in the JSON envelope — treat the raw text as a
    // plain conversational reply rather than inventing a scripted one.
    final fallbackText = raw.trim();
    if (fallbackText.isNotEmpty) {
      return AiCommandResult(actions: const [], response: fallbackText);
    }
    throw const GemmaException(
      code: GemmaErrorCode.unknown,
      message: 'JARVIS returned an empty command response.',
    );
  }

  // ── Deterministic explicit-command parsing ─────────────────

  AiCommandResult? _parseExplicitCommand(String command, String userName) {
    final lower = command.toLowerCase();

    final taskMatch = RegExp(
      r'^(?:add (?:a )?task|create (?:a )?task|new task|todo|remind me(?: to)?)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(command);
    if (taskMatch != null) {
      final title = _cleanPayload(taskMatch.group(1)!);
      if (title.isEmpty) return null;
      return AiCommandResult(
        actions: [
          AiAction(
            type: 'add_task',
            params: {'title': title, 'priority': _detectPriority(lower)},
          ),
        ],
        response: 'Added "$title" to your tasks.',
      );
    }

    final focusMatch = RegExp(
      r'^(?:start )?(?:focus|deep work|pomodoro)(?:\s+for)?(?:\s+(\d+)\s*(?:min|minutes?)?)?$',
      caseSensitive: false,
    ).firstMatch(command);
    if (focusMatch != null) {
      final minutes = int.tryParse(focusMatch.group(1) ?? '') ?? 25;
      return AiCommandResult(
        actions: [
          AiAction(type: 'start_focus', params: {'duration_minutes': minutes}),
        ],
        response: 'Focus mode armed. $minutes-minute session ready.',
        greetingUpdate: 'Deep focus mode, $userName.',
      );
    }

    final habitMatch = RegExp(
      r'^(?:add (?:a )?habit|new habit|track)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(command);
    if (habitMatch != null) {
      final name = _cleanPayload(habitMatch.group(1)!);
      if (name.isEmpty) return null;
      return AiCommandResult(
        actions: [
          AiAction(type: 'add_habit', params: {'name': name, 'icon': ''}),
        ],
        response: 'Now tracking "$name" as a daily habit.',
      );
    }

    final noteMatch = RegExp(
      r'^(?:add (?:a )?note|note|remember|write down|jot down)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(command);
    if (noteMatch != null) {
      final content = _cleanPayload(noteMatch.group(1)!);
      if (content.isEmpty) return null;
      return AiCommandResult(
        actions: [
          AiAction(type: 'add_note', params: {'content': content}),
        ],
        response: 'Saved to your notes.',
      );
    }

    return null;
  }

  String _cleanPayload(String value) {
    return value
        .replaceFirst(RegExp(r'^(to|that|the)\s+', caseSensitive: false), '')
        .trim();
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

  // ── Model output parsing ───────────────────────────────────

  Map<String, dynamic>? _extractResultJson(String text) {
    final candidate = _firstJsonObject(text);
    if (candidate == null) return null;
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  String? _firstJsonObject(String text) {
    final start = text.indexOf('{');
    if (start == -1) return null;
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < text.length; i++) {
      final char = text[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;
      if (char == '{') depth++;
      if (char == '}') {
        depth--;
        if (depth == 0) return text.substring(start, i + 1);
      }
    }
    return null;
  }

  String _repairPrompt(String command, String invalidOutput) {
    final clipped = invalidOutput.length > 700
        ? invalidOutput.substring(0, 700)
        : invalidOutput;
    return 'Your previous answer was not a valid JSON object.\n'
        'Return exactly one JSON object, no Markdown:\n'
        '{"response":"human answer","actions":[{"type":"add_task|add_habit|add_note|start_focus","params":{}}]}\n'
        'Use an empty actions array for pure conversation.\n\n'
        'User request: $command\n\nInvalid output:\n$clipped';
  }

  // ── AI Insight ─────────────────────────────────────────────

  Future<String> fetchInsight({
    required String userName,
    Map<String, dynamic>? stats,
  }) async {
    final now = DateTime.now();
    final insightKey = jsonEncode({
      'user': userName,
      'timeWindow': now.hour ~/ 4,
      'stats': stats ?? const <String, dynamic>{},
      'model': GemmaService.instance.isModelLoaded,
    });
    if (_cachedInsight != null && _cachedInsightKey == insightKey) {
      return _cachedInsight!;
    }

    var insight = _localInsight(userName, stats ?? const {});
    if (GemmaService.instance.isModelLoaded) {
      try {
        insight = await _gemmaInsight(userName, stats ?? const {}, insight);
      } catch (error) {
        debugPrint('[AiService] Gemma insight failed, using template: $error');
      }
    }
    _cachedInsight = insight;
    _cachedInsightKey = insightKey;
    return insight;
  }

  Future<String> _gemmaInsight(
    String userName,
    Map<String, dynamic> stats,
    String fallback,
  ) async {
    final prompt =
        'You are JARVIS, the on-device productivity guide in ContextShift.\n'
        'Write one or two short sentences of practical insight for $userName '
        'based on these daily stats. Be specific to the numbers, warm, and '
        'action-oriented. No lists, no Markdown, no greeting.\n'
        'Stats: ${jsonEncode(stats)}\n'
        'Local time: ${DateTime.now().hour}:00\nInsight:';
    final raw = await GemmaService.instance.generate(
      prompt,
      maxTokens: 96,
      temperature: 0.7,
      topK: 40,
      timeout: const Duration(seconds: 12),
    );
    final cleaned = raw.replaceAll(RegExp(r'[*#`>]'), '').trim();
    if (cleaned.length < 12) return fallback;
    return cleaned.length > 220 ? '${cleaned.substring(0, 217)}...' : cleaned;
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
}
