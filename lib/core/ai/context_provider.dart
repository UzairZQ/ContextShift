import 'dart:convert';

import '../database/database_service.dart';
import '../database/schema.dart';
import 'jarvis_memory_service.dart';

class ContextProvider {
  ContextProvider._();
  static final ContextProvider instance = ContextProvider._();

  static const int _maxContextCharacters = 6000;

  Future<Map<String, Object?>> buildGenUiContext({int? conversationId}) async {
    final snapshot = _jsonSafeMap(
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
    final recent = history
        .where((message) => message.content.trim().isNotEmpty)
        .toList()
        .reversed
        .take(6)
        .toList()
        .reversed
        .map(
          (message) => <String, Object?>{
            'role': message.role,
            'content': message.content,
          },
        )
        .toList(growable: false);

    return <String, Object?>{
      'app': 'ContextShift',
      'localSnapshot': snapshot,
      'jarvisMemory': memory,
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
    final snapshot = _jsonSafeMap(
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
      ..writeln(jsonEncode(snapshot))
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
    return _fitPrompt(prompt);
  }

  Future<String> buildChat({
    required String userMessage,
    int? conversationId,
  }) async {
    final snapshot = _jsonSafeMap(
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
        .take(10)
        .toList()
        .reversed;

    final buffer = StringBuffer()
      ..writeln('You are JARVIS, the private on-device guide in ContextShift.')
      ..writeln('Reply naturally, warmly, concisely, and with useful context.')
      ..writeln(
        'Use provided profile, memories, tasks, habits, notes, mood, focus data, and conversation summary when relevant.',
      )
      ..writeln(
        'Do not claim to remember anything outside the provided context.',
      )
      ..writeln('Current local context:')
      ..writeln(jsonEncode(snapshot))
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
    return _fitPrompt(prompt);
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
