import 'package:flutter/foundation.dart';

import '../ai_service.dart';
import '../database/database_service.dart';
import '../services/focus_timer_controller.dart';

class ActionExecutionResult {
  final int? focusMinutes;
  final int executedCount;
  final int failedCount;
  final int ignoredCount;

  const ActionExecutionResult({
    this.focusMinutes,
    this.executedCount = 0,
    this.failedCount = 0,
    this.ignoredCount = 0,
  });

  bool get allSucceeded => failedCount == 0 && ignoredCount == 0;
}

class ActionExecutor {
  ActionExecutor._();
  static final ActionExecutor instance = ActionExecutor._();

  Future<ActionExecutionResult> executeAll(List<AiAction> actions) async {
    int? focusMinutes;
    var executedCount = 0;
    var failedCount = 0;
    var ignoredCount = actions.length > 8 ? actions.length - 8 : 0;

    for (final action in actions.take(8)) {
      try {
        switch (action.type) {
          case 'add_task':
            final title = _requiredText(action.params['title']);
            if (title == null) {
              throw const FormatException('Task title missing');
            }
            final priority = _priority(action.params['priority']);
            final due = _requiredText(action.params['due']) ?? 'Today';
            final subtasks = _subtasks(action.params['subtasks']);
            late final bool wasAdded;
            if (action.params['dedupe_existing'] == true) {
              wasAdded = await DatabaseService.instance.addTaskIfAbsent(
                title: title,
                priority: priority,
                due: due,
                subtasks: subtasks,
              );
            } else {
              await DatabaseService.instance.addTask(
                title: title,
                priority: priority,
                due: due,
                subtasks: subtasks,
              );
              wasAdded = true;
            }
            if (!wasAdded) {
              ignoredCount++;
              continue;
            }
          case 'add_habit':
            final name = _requiredText(action.params['name']);
            if (name == null) {
              throw const FormatException('Habit name missing');
            }
            await DatabaseService.instance.addHabit(
              name: name,
              icon: _requiredText(action.params['icon']) ?? '✨',
            );
          case 'add_note':
            final content = _requiredText(action.params['content']);
            if (content == null) {
              throw const FormatException('Note content missing');
            }
            await DatabaseService.instance.addNote(content: content);
          case 'start_focus':
            final raw = action.params['duration_minutes'];
            final minutes = raw is num ? raw.toInt().clamp(5, 180) : 25;
            final timer = FocusTimerController.instance;
            if (timer.state.value.hasActiveSession) {
              throw StateError('A focus session is already active');
            }
            timer.updateSession('Focus', minutes);
            await timer.start();
            focusMinutes = minutes;
          default:
            throw UnsupportedError('Unknown action type: ${action.type}');
        }
        executedCount++;
      } catch (error, stackTrace) {
        failedCount++;
        debugPrint('[ActionExecutor] ${action.type} failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    return ActionExecutionResult(
      focusMinutes: focusMinutes,
      executedCount: executedCount,
      failedCount: failedCount,
      ignoredCount: ignoredCount,
    );
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
