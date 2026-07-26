import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../database/database_service.dart';
import '../database/schema.dart';
import 'context_retriever.dart';
import 'jarvis_memory_service.dart';

/// Builds prompts for the on-device model.
///
/// All variants share the same pipeline: retrieval-ranked local context
/// (tasks/habits/notes/memories), conversation memory, and recent turns,
/// assembled under a hard character budget by trimming the least valuable
/// sections first — never by cutting the prompt mid-JSON.
class ContextProvider {
  ContextProvider._();
  static final ContextProvider instance = ContextProvider._();

  static const int _maxContextCharacters = 6000;

  Future<Map<String, Object?>> buildGenUiContext({
    int? conversationId,
    required String userMessage,
  }) async {
    final retrieved = await ContextRetriever.instance.retrieve(
      query: userMessage,
      maxTasks: 5,
      maxHabits: 4,
      maxNotes: 3,
      maxMemories: 5,
    );
    final memory = await JarvisMemoryService.instance.buildMemoryContext(
      conversationId: conversationId,
    );
    final history = conversationId == null
        ? const <MessageTableData>[]
        : await DatabaseService.instance.getMessages(conversationId);
    final recent = history
        .where((message) => message.content.trim().isNotEmpty)
        .toList()
        .reversed
        .take(2)
        .toList()
        .reversed
        .map(
          (message) => <String, Object?>{
            'role': message.role,
            'content': _clip(message.content, 180),
          },
        )
        .toList(growable: false);

    _logContext('generate', retrieved, recent.length);

    return <String, Object?>{
      'app': 'ContextShift',
      'profile': _profileJson(),
      'localSnapshot': retrieved.toPromptJson(),
      'conversationSummary': _clip(
        memory['conversationSummary']?.toString() ?? '',
        400,
      ),
      'recentConversation': recent,
      'allowedActionContext': {
        'create_task': ['title', 'priority'],
        'create_habit': ['name'],
        'create_note': ['content'],
        'start_focus': ['duration_minutes'],
        'continue_conversation': ['message'],
      },
    };
  }

  /// Action-mode prompt: the model must answer with one JSON object that
  /// contains a human response plus zero or more app actions.
  Future<String> build({
    required String userMessage,
    int? conversationId,
  }) async {
    final parts = await _sharedParts(
      userMessage: userMessage,
      conversationId: conversationId,
      historyTurns: 6,
    );

    final rules = <String>[
      'You are JARVIS, the private on-device guide in ContextShift.',
      'Be concise, grounded, warm, and action-oriented.',
      'Ground every claim in the provided context. If context is missing, ask one useful question instead of guessing.',
      'Never claim an action succeeded unless you return that action.',
      'Return one JSON object only, no Markdown, with this exact shape:',
      '{"response":"human answer","actions":[{"type":"add_task|add_habit|add_note|start_focus","params":{}}]}',
      'params: add_task {"title","priority"(normal|medium|high)}, add_habit {"name"}, add_note {"content"}, start_focus {"duration_minutes"}.',
      'Use an empty actions array for pure conversation.',
    ];

    return _assemble(
      rules: rules,
      parts: parts,
      userMessage: userMessage,
      trailing: null,
    );
  }

  /// Plain conversational prompt.
  Future<String> buildChat({
    required String userMessage,
    int? conversationId,
  }) async {
    final parts = await _sharedParts(
      userMessage: userMessage,
      conversationId: conversationId,
      historyTurns: 6,
    );

    final alreadyGreeted = parts.alreadyGreeted;
    final rules = <String>[
      'You are JARVIS, the private on-device guide in ContextShift.',
      'Reply like a sharp, warm product companion, not a command parser or status bot.',
      'Answer the latest user message directly. Do not repeat a previous assistant answer unless asked.',
      'Use natural length: one sentence for simple questions, a few short paragraphs or a compact list for analysis.',
      'Write complete sentences. Avoid heavy Markdown, asterisks, and headings in plain chat.',
      'Never introduce yourself as a generic language model. Speak as JARVIS inside ContextShift.',
      alreadyGreeted
          ? 'The conversation is already underway. Do not greet or reintroduce yourself.'
          : 'This may be the first reply; a brief natural greeting is allowed.',
      'If asked what you can do: you chat with local context, execute app actions, and generate structured cards (plans, schedules, workouts, dashboards, trackers, comparisons, checklists, forms).',
      'When the user asks about their tasks, habits, focus, mood, or notes, cite concrete names, counts, or status from Local context.',
      'Do not claim to remember anything outside the provided context, and never invent progress you cannot see.',
    ];

    return _assemble(
      rules: rules,
      parts: parts,
      userMessage: userMessage,
      trailing: 'JARVIS:',
    );
  }

  // ── Shared assembly ─────────────────────────────────────────

  Future<_PromptParts> _sharedParts({
    required String userMessage,
    required int? conversationId,
    required int historyTurns,
  }) async {
    final retrieved = await ContextRetriever.instance.retrieve(
      query: userMessage,
    );
    final memory = await JarvisMemoryService.instance.buildMemoryContext(
      conversationId: conversationId,
    );
    final history = conversationId == null
        ? const <MessageTableData>[]
        : await DatabaseService.instance.getMessages(conversationId);

    final recentHistory = history
        .where((message) => message.content.trim().isNotEmpty)
        .toList()
        .reversed
        .take(historyTurns)
        .toList()
        .reversed
        .map((m) => (role: m.role, content: _clip(m.content, 300)))
        .toList(growable: false);

    final state = memory['conversationState'];
    final alreadyGreeted =
        (state is Map && state['alreadyGreeted'] == true) ||
        history.any((message) => message.role == 'assistant');

    _logContext('prompt', retrieved, recentHistory.length);

    return _PromptParts(
      retrieved: retrieved,
      summary: memory['conversationSummary']?.toString().trim() ?? '',
      state: state is Map ? Map<String, Object?>.from(state) : const {},
      history: recentHistory,
      alreadyGreeted: alreadyGreeted,
    );
  }

  String _assemble({
    required List<String> rules,
    required _PromptParts parts,
    required String userMessage,
    required String? trailing,
  }) {
    // Reduction stages, applied in order until the prompt fits.
    var historyTurns = parts.history.length;
    var summaryLimit = 700;
    var context = parts.retrieved.toPromptJson();
    var stage = 0;

    String render() {
      final buffer = StringBuffer();
      for (final rule in rules) {
        buffer.writeln(rule);
      }
      buffer
        ..writeln('User profile:')
        ..writeln(jsonEncode(_profileJson()))
        ..writeln('Local context:')
        ..writeln(jsonEncode(context));
      final summary = _clip(parts.summary, summaryLimit);
      if (summary.isNotEmpty) {
        buffer
          ..writeln('Conversation so far (summary):')
          ..writeln(summary);
      }
      final pending = parts.state['pendingQuestion']?.toString() ?? '';
      if (pending.isNotEmpty) {
        buffer.writeln('Open question you asked earlier: $pending');
      }
      final history = parts.history
          .skip(parts.history.length - historyTurns)
          .toList();
      if (history.isNotEmpty) {
        buffer.writeln('Recent conversation:');
        for (final message in history) {
          buffer.writeln('${message.role}: ${message.content}');
        }
      }
      buffer.writeln('User: $userMessage');
      if (trailing != null) buffer.writeln(trailing);
      return buffer.toString();
    }

    var prompt = render();
    while (prompt.length > _maxContextCharacters && stage < 5) {
      stage += 1;
      switch (stage) {
        case 1:
          summaryLimit = 320;
        case 2:
          historyTurns = historyTurns > 3 ? 3 : historyTurns;
        case 3:
          context = RetrievedContext(
            tasks: parts.retrieved.tasks.take(4).toList(),
            habits: parts.retrieved.habits.take(3).toList(),
            notes: parts.retrieved.notes.take(2).toList(),
            memories: parts.retrieved.memories.take(4).toList(),
            presence: parts.retrieved.presence,
            queryTerms: parts.retrieved.queryTerms,
          ).toPromptJson();
        case 4:
          historyTurns = historyTurns > 2 ? 2 : historyTurns;
          summaryLimit = 160;
        case 5:
          context = <String, Object?>{'today': parts.retrieved.presence};
      }
      prompt = render();
    }

    if (prompt.length > _maxContextCharacters) {
      // Last resort: keep instructions head + latest turns tail.
      const marker = '\n--- Older context truncated ---\n';
      const headChars = 1400;
      final tailChars = _maxContextCharacters - headChars - marker.length;
      prompt =
          prompt.substring(0, headChars) +
          marker +
          prompt.substring(prompt.length - tailChars);
    }
    return prompt;
  }

  Map<String, Object?> _profileJson() {
    final db = DatabaseService.instance;
    final interests = db.profileInterests;
    return <String, Object?>{
      'name': db.firstName,
      if (db.focusRole?.isNotEmpty ?? false) 'focusRole': db.focusRole,
      if (interests.isNotEmpty) 'interests': interests.take(4).toList(),
      if (db.windDownTime?.isNotEmpty ?? false) 'windDown': db.windDownTime,
    };
  }

  void _logContext(String mode, RetrievedContext retrieved, int recentCount) {
    debugPrint(
      '[ContextProvider] mode=$mode recent=$recentCount '
      'tasks=${retrieved.tasks.length} habits=${retrieved.habits.length} '
      'notes=${retrieved.notes.length} memories=${retrieved.memories.length} '
      'terms=${retrieved.queryTerms.take(8).join('|')}',
    );
  }

  String _clip(String value, int maxLength) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= maxLength) return cleaned;
    return '${cleaned.substring(0, maxLength - 3).trim()}...';
  }
}

class _PromptParts {
  final RetrievedContext retrieved;
  final String summary;
  final Map<String, Object?> state;
  final List<({String role, String content})> history;
  final bool alreadyGreeted;

  const _PromptParts({
    required this.retrieved,
    required this.summary,
    required this.state,
    required this.history,
    required this.alreadyGreeted,
  });
}
