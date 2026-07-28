import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../database/database_service.dart';
import '../database/schema.dart';
import 'context_snapshot_retriever.dart';
import 'jarvis_memory_service.dart';

class ContextProvider {
  ContextProvider._();
  static final ContextProvider instance = ContextProvider._();

  // Keep the prompt comfortably below the E2B context ceiling after system
  // instructions and tokenizer overhead are included.
  static const int _maxContextCharacters = 4200;
  static const int _maxGenUiContextCharacters = 3200;

  Future<Map<String, Object?>> buildGenUiContext({
    int? conversationId,
    required String userMessage,
  }) async {
    final fullSnapshot = _jsonSafeMap(
      await DatabaseService.instance.buildContextSnapshot(),
    );
    final memory = _jsonSafeMap(
      await JarvisMemoryService.instance.buildMemoryContext(
        conversationId: conversationId,
      ),
    );
    final compactMemory = _compactForPrompt(memory) as Map<String, Object?>;
    final history = conversationId == null
        ? const <MessageTableData>[]
        : await DatabaseService.instance.getRecentMessages(
            conversationId,
            limit: 2,
          );
    final recent = history
        .where((message) => message.content.trim().isNotEmpty)
        .map(
          (message) => <String, Object?>{
            'role': message.role,
            'content': _clipForPrompt(message.content, 180),
          },
        )
        .toList(growable: false);

    final selectedSnapshot =
        _compactForPrompt(
              _selectSnapshotForMessage(
                fullSnapshot,
                userMessage,
                compactMemory,
                mode: 'generate',
              ),
            )
            as Map<String, Object?>;
    _debugPromptContext(
      mode: 'generate',
      snapshot: selectedSnapshot,
      recentCount: recent.length,
      memory: compactMemory,
    );

    final context = <String, Object?>{
      'app': 'ContextShift',
      'localSnapshot': selectedSnapshot,
      'jarvisMemory': compactMemory,
      'recentConversation': recent,
      'allowedActionContext': {
        'create_task': ['title', 'priority'],
        'create_habit': ['name'],
        'create_note': ['content'],
        'start_focus': ['duration_minutes'],
        'continue_conversation': ['message'],
      },
    };
    return _fitGenUiContext(context);
  }

  Future<String> build({
    required String userMessage,
    int? conversationId,
  }) async {
    final fullSnapshot = _jsonSafeMap(
      await DatabaseService.instance.buildContextSnapshot(),
    );
    final memory = _jsonSafeMap(
      await JarvisMemoryService.instance.buildMemoryContext(
        conversationId: conversationId,
      ),
    );
    final compactMemory = _compactForPrompt(memory) as Map<String, Object?>;
    final history = conversationId == null
        ? const <MessageTableData>[]
        : await DatabaseService.instance.getRecentMessages(
            conversationId,
            limit: 8,
          );

    final recentHistory = history
        .where((message) => message.content.trim().isNotEmpty)
        .take(8);

    final buffer = StringBuffer()
      ..writeln('You are JARVIS, the private on-device guide in ContextShift.')
      ..writeln('Be concise, grounded, warm, and action-oriented.')
      ..writeln(
        'Use the user profile, memories, tasks, habits, notes, mood, focus data, and conversation summary as context.',
      )
      ..writeln(
        'Do not pretend to remember facts that are not in the provided context. If context is missing, ask one useful question.',
      )
      ..writeln(
        'Never claim an action succeeded unless you return that action.',
      )
      ..writeln('Return one JSON object only with this shape:')
      ..writeln(
        '{"response":"human answer","actions":[{"type":"add_task|add_habit|add_note|start_focus","params":{}}]}',
      )
      ..writeln('Current local context:')
      ..writeln(
        jsonEncode(
          _selectSnapshotForMessage(
            fullSnapshot,
            userMessage,
            compactMemory,
            mode: 'action',
          ),
        ),
      )
      ..writeln('Jarvis memory:')
      ..writeln(jsonEncode(compactMemory));

    if (recentHistory.isNotEmpty) {
      buffer.writeln('Recent conversation:');
      for (final message in recentHistory) {
        buffer.writeln(
          '${message.role}: ${_clipForPrompt(message.content, 300)}',
        );
      }
    }

    buffer.writeln('User: $userMessage');
    final prompt = buffer.toString();
    _debugPromptContext(
      mode: 'action',
      snapshot: _selectSnapshotForMessage(
        fullSnapshot,
        userMessage,
        compactMemory,
        mode: 'action',
      ),
      recentCount: recentHistory.length,
      memory: compactMemory,
    );
    return _fitPrompt(prompt);
  }

  Future<String> buildChat({
    required String userMessage,
    int? conversationId,
  }) async {
    final fullSnapshot = _jsonSafeMap(
      await DatabaseService.instance.buildContextSnapshot(),
    );
    final memory = _jsonSafeMap(
      await JarvisMemoryService.instance.buildMemoryContext(
        conversationId: conversationId,
      ),
    );
    final compactMemory = _compactForPrompt(memory) as Map<String, Object?>;
    final history = conversationId == null
        ? const <MessageTableData>[]
        : await DatabaseService.instance.getRecentMessages(
            conversationId,
            limit: 6,
          );

    final recentHistory = history
        .where((message) => message.content.trim().isNotEmpty)
        .take(6);
    final selectedSnapshot = _selectSnapshotForMessage(
      fullSnapshot,
      userMessage,
      compactMemory,
      mode: 'chat',
    );
    final state = compactMemory['conversationState'];
    final alreadyGreeted =
        state is Map && state['alreadyGreeted'] == true ||
        history.any((message) => message.role == 'assistant');

    final buffer = StringBuffer()
      ..writeln('You are JARVIS, the private on-device guide in ContextShift.')
      ..writeln(
        'Reply like a helpful product companion, not a command parser or status bot.',
      )
      ..writeln(
        'Answer the latest user message directly. Do not repeat a previous assistant answer unless the user explicitly asks for it.',
      )
      ..writeln(
        'Use natural length for the request: one sentence for simple questions, or a few short paragraphs or a compact list for analysis.',
      )
      ..writeln(
        'Write complete sentences. Avoid heavy Markdown, asterisks, headings, and unfinished lists in plain chat.',
      )
      ..writeln(
        'Never introduce yourself as a generic large language model. Speak as JARVIS inside ContextShift.',
      )
      ..writeln(
        alreadyGreeted
            ? 'This conversation is already underway. Do not greet, reintroduce yourself, or restart the conversation.'
            : 'This may be the first assistant reply in the conversation; a brief natural greeting is allowed.',
      )
      ..writeln(
        'Only explain capabilities when the user explicitly asks what you can or cannot do. If the user says build, generate, create, or make, treat it as a request and either act on it or ask one focused clarifying question instead of listing capabilities.',
      )
      ..writeln(
        'Use provided profile, memories, tasks, habits, notes, mood, focus data, and conversation summary when relevant.',
      )
      ..writeln(
        'Do not claim to remember anything outside the provided context.',
      )
      ..writeln(
        'If the user asks about habits, tasks, focus, mood, or notes, mention concrete names, counts, or status from Current local context when available.',
      )
      ..writeln(
        'If the user asks what you changed or optimized, only claim changes that actually happened in this turn or the recent conversation. Otherwise explain that you have not changed anything yet and offer a useful next step.',
      )
      ..writeln(
        'Resolve references such as this task, that habit, it, or the previous message from Recent conversation and Current local context. If the reference is genuinely ambiguous, ask one concise clarifying question instead of changing the subject.',
      )
      ..writeln(
        'Do not answer with vague progress phrases like "I am analyzing" unless you immediately include the concrete result.',
      )
      ..writeln('Current local context:')
      ..writeln(jsonEncode(selectedSnapshot))
      ..writeln('Jarvis memory:')
      ..writeln(jsonEncode(compactMemory));

    if (recentHistory.isNotEmpty) {
      buffer.writeln('Recent conversation:');
      for (final message in recentHistory) {
        buffer.writeln(
          '${message.role}: ${_clipForPrompt(message.content, 300)}',
        );
      }
    }

    buffer
      ..writeln('User: $userMessage')
      ..writeln('JARVIS:');
    final prompt = buffer.toString();
    _debugPromptContext(
      mode: 'chat',
      snapshot: selectedSnapshot,
      recentCount: recentHistory.length,
      memory: compactMemory,
    );
    return _fitPrompt(prompt);
  }

  Map<String, Object?> _selectSnapshotForMessage(
    Map<String, Object?> snapshot,
    String userMessage,
    Map<String, Object?> memory, {
    required String mode,
  }) {
    final state = memory['conversationState'];
    final topic = state is Map ? state['currentTopic']?.toString() ?? '' : '';
    return ContextSnapshotRetriever.select(
      snapshot: snapshot,
      query: userMessage,
      topic: topic,
      mode: mode,
    );
  }

  void _debugPromptContext({
    required String mode,
    required Map<String, Object?> snapshot,
    required int recentCount,
    required Map<String, Object?> memory,
  }) {
    if (!kDebugMode) return;
    final state = memory['conversationState'];
    debugPrint(
      '[ContextProvider] mode=$mode recent=$recentCount '
      'snapshotKeys=${snapshot.keys.join(',')} '
      'hasSummary=${(memory['conversationSummary']?.toString().trim().isNotEmpty ?? false)} '
      'state=$state',
    );
  }

  String _fitPrompt(String prompt) {
    if (prompt.length <= _maxContextCharacters) return prompt;
    const marker = '\n--- Older context truncated ---\n';
    const headChars = 1400;
    final tailChars = _maxContextCharacters - headChars - marker.length;
    return prompt.substring(0, headChars) +
        marker +
        prompt.substring(prompt.length - tailChars);
  }

  Map<String, Object?> _fitGenUiContext(Map<String, Object?> context) {
    if (jsonEncode(context).length <= _maxGenUiContextCharacters) {
      return context;
    }

    final snapshot = context['localSnapshot'];
    final memory = context['jarvisMemory'];
    final recent = context['recentConversation'];
    final compactSnapshot = <String, Object?>{};
    if (snapshot is Map) {
      for (final key in [
        'profile',
        'tasks',
        'habits',
        'today_mood',
        'focus_minutes_today',
        'recent_note',
      ]) {
        if (snapshot.containsKey(key)) {
          compactSnapshot[key] = _compactForPrompt(snapshot[key]);
        }
      }
    }

    final compactMemory = <String, Object?>{};
    if (memory is Map) {
      for (final key in [
        'conversationState',
        'conversationSummary',
        'lastGeneratedCardType',
      ]) {
        if (memory.containsKey(key)) {
          compactMemory[key] = _compactForPrompt(memory[key]);
        }
      }
    }

    final compact = <String, Object?>{
      'app': 'ContextShift',
      'localSnapshot': compactSnapshot,
      'jarvisMemory': compactMemory,
      'recentConversation': recent is List ? recent.take(1).toList() : const [],
      'allowedActionContext': context['allowedActionContext'],
    };
    if (jsonEncode(compact).length <= _maxGenUiContextCharacters) {
      debugPrint(
        '[ContextProvider] Compacted GenUI context from '
        '${jsonEncode(context).length} to ${jsonEncode(compact).length} chars',
      );
      return compact;
    }

    // Keep the prompt valid JSON even when a user has unusually large local
    // data. The model can still generate a useful card from the request.
    final minimal = <String, Object?>{
      'app': 'ContextShift',
      'localSnapshot': {
        if (compactSnapshot['profile'] != null)
          'profile': compactSnapshot['profile'],
        if (compactSnapshot['today_mood'] != null)
          'today_mood': compactSnapshot['today_mood'],
        if (compactSnapshot['focus_minutes_today'] != null)
          'focus_minutes_today': compactSnapshot['focus_minutes_today'],
      },
      'jarvisMemory': const <String, Object?>{},
      'recentConversation': const <Object?>[],
      'allowedActionContext': context['allowedActionContext'],
    };
    debugPrint(
      '[ContextProvider] Reduced GenUI context to minimal payload '
      '(${jsonEncode(minimal).length} chars)',
    );
    return minimal;
  }

  Map<String, Object?> _jsonSafeMap(Map<String, Object?> value) {
    return _jsonSafe(value) as Map<String, Object?>;
  }

  Object? _compactForPrompt(Object? value) {
    if (value is String) return _clipForPrompt(value, 220);
    if (value is Map) {
      return value.map<String, Object?>(
        (key, mapValue) =>
            MapEntry(key.toString(), _compactForPrompt(mapValue)),
      );
    }
    if (value is Iterable) {
      return value.take(4).map(_compactForPrompt).toList(growable: false);
    }
    return value;
  }

  String _clipForPrompt(String value, int maxLength) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= maxLength) return cleaned;
    return '${cleaned.substring(0, maxLength - 3).trim()}...';
  }

  Object? _jsonSafe(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      return value.map<String, Object?>(
        (key, mapValue) => MapEntry(key.toString(), _jsonSafe(mapValue)),
      );
    }
    if (value is Iterable) {
      return value.map(_jsonSafe).toList(growable: false);
    }
    return value.toString();
  }
}
