import 'package:flutter/foundation.dart';

import '../ai_service.dart';
import '../database/database_service.dart';

class ActionExecutionResult {
  final int? focusMinutes;

  const ActionExecutionResult({this.focusMinutes});
}

class ActionExecutor {
  ActionExecutor._();
  static final ActionExecutor instance = ActionExecutor._();

  Future<ActionExecutionResult> executeAll(List<AiAction> actions) async {
    int? focusMinutes;

    for (final action in actions.take(8)) {
      try {
        switch (action.type) {
          case 'add_task':
            final title = _requiredText(action.params['title']);
            if (title != null) {
              await DatabaseService.instance.addTask(
                title: title,
                priority: _priority(action.params['priority']),
                due: _requiredText(action.params['due']) ?? 'Today',
                subtasks: _subtasks(action.params['subtasks']),
              );
            }
          case 'add_habit':
            final name = _requiredText(action.params['name']);
            if (name != null) {
              await DatabaseService.instance.addHabit(
                name: name,
                icon: _requiredText(action.params['icon']) ?? '✨',
              );
            }
          case 'add_note':
            final content = _requiredText(action.params['content']);
            if (content != null) {
              await DatabaseService.instance.addNote(content: content);
            }
          case 'start_focus':
            final raw = action.params['duration_minutes'];
            final minutes = raw is num ? raw.toInt().clamp(5, 180) : 25;
            await DatabaseService.instance.startFocusSession(
              durationMinutes: minutes,
            );
            focusMinutes = minutes;
        }
      } catch (error, stackTrace) {
        debugPrint('[ActionExecutor] ${action.type} failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return ActionExecutionResult(focusMinutes: focusMinutes);
  }

  String? _requiredText(dynamic value) {
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty || text.length > 500) return null;
    return text;
  }

  String _priority(dynamic value) {
    return switch (value) {
      'high' => 'high',
      'low' => 'low',
      _ => 'normal',
    };
  }

  List<Map<String, dynamic>> _subtasks(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) {
          final title = _requiredText(item['title']);
          if (title == null) return null;
          return {'title': title, 'completed': item['completed'] == true};
        })
        .whereType<Map<String, dynamic>>()
        .take(8)
        .toList(growable: false);
  }
}
