import 'dart:convert';

import '../database/database_service.dart';
import '../database/schema.dart';

class ContextProvider {
  ContextProvider._();
  static final ContextProvider instance = ContextProvider._();

  static const int _maxContextCharacters = 6000;

  Future<Map<String, Object?>> buildGenUiContext({int? conversationId}) async {
    final snapshot = await DatabaseService.instance.buildContextSnapshot();
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
    final snapshot = await DatabaseService.instance.buildContextSnapshot();
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
        'Never claim an action succeeded unless you return that action.',
      )
      ..writeln('Return one JSON object only with this shape:')
      ..writeln(
        '{"response":"human answer","actions":[{"type":"add_task|add_habit|add_note|start_focus|show_dynamic_card","params":{}}]}',
      )
      ..writeln('Current local context:')
      ..writeln(jsonEncode(snapshot));

    if (recentHistory.isNotEmpty) {
      buffer.writeln('Recent conversation:');
      for (final message in recentHistory) {
        buffer.writeln('${message.role}: ${message.content}');
      }
    }

    buffer.writeln('User: $userMessage');
    final prompt = buffer.toString();
    if (prompt.length <= _maxContextCharacters) return prompt;
    return prompt.substring(prompt.length - _maxContextCharacters);
  }
}
