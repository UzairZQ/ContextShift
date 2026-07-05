import 'dart:convert';

import '../ai_service.dart';

class ScheduleCardTaskConverter {
  ScheduleCardTaskConverter._();

  static List<AiAction> actionsFromA2ui(String rawA2ui) {
    final timeline = _timelineFromA2ui(rawA2ui);
    return timeline
        .where((item) => item.title.isNotEmpty)
        .take(8)
        .map(
          (item) => AiAction(
            type: 'add_task',
            params: {
              'title': item.title,
              'priority': 'normal',
              if (item.time.isNotEmpty && item.time.toLowerCase() != 'next')
                'due': item.time,
              if (item.detail.isNotEmpty)
                'subtasks': [
                  {'title': item.detail, 'completed': false},
                ],
            },
          ),
        )
        .toList(growable: false);
  }

  static List<_ScheduleTaskDraft> _timelineFromA2ui(String rawA2ui) {
    try {
      final decoded = jsonDecode(_jsonPayload(rawA2ui));
      if (decoded is! List) return const [];
      final drafts = <_ScheduleTaskDraft>[];
      for (final message in decoded.whereType<Map>()) {
        final update = message['updateComponents'];
        if (update is! Map) continue;
        final components = update['components'];
        if (components is! List) continue;
        for (final component in components.whereType<Map>()) {
          if (component['component'] != 'Timeline') continue;
          final items = component['items'];
          if (items is! List) continue;
          drafts.addAll(
            items.whereType<Map>().map(
              (item) => _ScheduleTaskDraft(
                time: _text(item['time']),
                title: _text(item['title']),
                detail: _text(item['detail'] ?? item['body']),
              ),
            ),
          );
        }
      }
      return drafts;
    } catch (_) {
      return const [];
    }
  }

  static String _jsonPayload(String raw) {
    final trimmed = raw.trim();
    final fenced = RegExp(
      r'^```(?:json)?\s*([\s\S]*?)\s*```$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    return fenced?.group(1)?.trim() ?? trimmed;
  }

  static String _text(Object? value) =>
      value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
}

class _ScheduleTaskDraft {
  final String time;
  final String title;
  final String detail;

  const _ScheduleTaskDraft({
    required this.time,
    required this.title,
    required this.detail,
  });
}
