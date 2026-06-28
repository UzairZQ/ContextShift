import '../genui/widget_node.dart';
import '../ai_service.dart';

class GeneratedUiActionMapper {
  GeneratedUiActionMapper._();

  static AiAction? toAiAction(WidgetAction action) {
    final params = Map<String, dynamic>.from(action.params);
    return switch (action.action) {
      'create_task' => AiAction(
        type: 'add_task',
        params: {
          'title': _text(params['title']) ?? _text(params['message']),
          'priority': _priority(params['priority']),
        },
      ),
      'create_habit' => AiAction(
        type: 'add_habit',
        params: {
          'name': _text(params['name']) ?? _text(params['title']),
          'icon': _text(params['icon']) ?? '',
        },
      ),
      'create_note' => AiAction(
        type: 'add_note',
        params: {
          'content':
              _text(params['content']) ??
              _text(params['message']) ??
              _text(params['title']),
        },
      ),
      'start_focus' => AiAction(
        type: 'start_focus',
        params: {'duration_minutes': _duration(params['duration_minutes'])},
      ),
      'add_task' ||
      'add_habit' ||
      'add_note' ||
      'start_focus' => AiAction(type: action.action, params: params),
      _ => null,
    };
  }

  static String? continuationMessage(WidgetAction action) {
    return _text(action.params['message']) ?? _text(action.params['title']);
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _priority(Object? value) {
    return switch (value) {
      'high' => 'high',
      'low' => 'low',
      _ => 'normal',
    };
  }

  static int _duration(Object? value) {
    if (value is num) return value.toInt().clamp(5, 180);
    return 25;
  }
}
