import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../database/database_service.dart';
import '../database/schema.dart';
import 'jarvis_memory_service.dart';

class ContextProvider {
  ContextProvider._();
  static final ContextProvider instance = ContextProvider._();

  static const int _maxContextCharacters = 6000;

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

    return <String, Object?>{
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
    final history = conversationId == null
        ? const <MessageTableData>[]
        : await DatabaseService.instance.getMessages(conversationId);

    final recentHistory = history
        .where((message) => message.content.trim().isNotEmpty)
        .toList()
        .reversed
        .take(8)
        .toList()
        .reversed;

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
            memory,
            mode: 'action',
          ),
        ),
      )
      ..writeln('Jarvis memory:')
      ..writeln(jsonEncode(memory));

    if (recentHistory.isNotEmpty) {
      buffer.writeln('Recent conversation:');
      for (final message in recentHistory) {
        buffer.writeln('${message.role}: ${message.content}');
      }
    }

    buffer.writeln('User: $userMessage');
    final prompt = buffer.toString();
    _debugPromptContext(
      mode: 'action',
      snapshot: _selectSnapshotForMessage(
        fullSnapshot,
        userMessage,
        memory,
        mode: 'action',
      ),
      recentCount: recentHistory.length,
      memory: memory,
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
    final history = conversationId == null
        ? const <MessageTableData>[]
        : await DatabaseService.instance.getMessages(conversationId);

    final recentHistory = history
        .where((message) => message.content.trim().isNotEmpty)
        .toList()
        .reversed
        .take(6)
        .toList()
        .reversed;
    final selectedSnapshot = _selectSnapshotForMessage(
      fullSnapshot,
      userMessage,
      memory,
      mode: 'chat',
    );
    final state = memory['conversationState'];
    final alreadyGreeted =
        state is Map && state['alreadyGreeted'] == true ||
        history.any((message) => message.role == 'assistant');

    final buffer = StringBuffer()
      ..writeln('You are JARVIS, the private on-device guide in ContextShift.')
      ..writeln('Reply naturally, warmly, concisely, and with useful context.')
      ..writeln(
        'Write complete sentences. Avoid Markdown formatting, asterisks, headings, and unfinished lists in plain chat.',
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
        'If the user asks what you can do, build, generate, or whether you can make cards, explain that JARVIS can chat, use local context, create app actions, and generate structured cards/surfaces such as plans, schedules, workout cards, study blocks, habit dashboards, task checklists, trackers, comparisons, routines, forms, and decision views.',
      )
      ..writeln(
        'Use provided profile, memories, tasks, habits, notes, mood, focus data, and conversation summary when relevant.',
      )
      ..writeln(
        'Do not claim to remember anything outside the provided context.',
      )
      ..writeln('Current local context:')
      ..writeln(jsonEncode(selectedSnapshot))
      ..writeln('Jarvis memory:')
      ..writeln(jsonEncode(memory));

    if (recentHistory.isNotEmpty) {
      buffer.writeln('Recent conversation:');
      for (final message in recentHistory) {
        buffer.writeln('${message.role}: ${message.content}');
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
      memory: memory,
    );
    return _fitPrompt(prompt);
  }

  Map<String, Object?> _selectSnapshotForMessage(
    Map<String, Object?> snapshot,
    String userMessage,
    Map<String, Object?> memory, {
    required String mode,
  }) {
    final lower = userMessage.toLowerCase();
    final state = memory['conversationState'];
    final topic = state is Map ? state['currentTopic']?.toString() ?? '' : '';
    final selected = <String, Object?>{'profile': snapshot['profile']};

    bool mentions(RegExp pattern) =>
        pattern.hasMatch(lower) || pattern.hasMatch(topic);
    final wantsOverview =
        mode == 'generate' &&
        mentions(
          RegExp(
            r'\b(dashboard|overview|summary|stats|metrics|report|everything|all)\b',
          ),
        );
    final includeEverything = lower.trim().isEmpty || wantsOverview;
    final wantsTasks =
        includeEverything ||
        mentions(RegExp(r'\b(task|todo|priority|deadline)\b'));
    final wantsHabits =
        includeEverything || mentions(RegExp(r'\b(habit|routine|streak)\b'));
    final wantsNotes =
        includeEverything ||
        mentions(RegExp(r'\b(note|journal|mood|feel|reflect)\b'));
    final wantsFocus =
        includeEverything ||
        mentions(
          RegExp(
            r'\b(focus|deep work|pomodoro|session|study|workout|exercise|training)\b',
          ),
        );

    if (wantsTasks) selected['tasks'] = snapshot['tasks'];
    if (wantsHabits) selected['habits'] = snapshot['habits'];
    if (wantsNotes) {
      selected['recent_note'] = snapshot['recent_note'];
      selected['recent_notes'] = snapshot['recent_notes'];
      selected['today_mood'] = snapshot['today_mood'];
    }
    if (wantsFocus) {
      selected['focus_minutes_today'] = snapshot['focus_minutes_today'];
    }
    if (includeEverything) {
      selected['recent_commands'] = snapshot['recent_commands'];
      selected['recent_events'] = snapshot['recent_events'];
    }
    return selected;
  }

  void _debugPromptContext({
    required String mode,
    required Map<String, Object?> snapshot,
    required int recentCount,
    required Map<String, Object?> memory,
  }) {
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
