import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/app_spacing.dart';
import '../../../core/app_theme.dart';

class ScheduleCardEditor {
  ScheduleCardEditor._();

  static Future<String?> editTimes({
    required BuildContext context,
    required String rawA2ui,
  }) async {
    final parsed = _parse(rawA2ui);
    if (parsed == null) return null;
    final timeline = parsed.timeline;
    final edited = await showModalBottomSheet<List<_TimelineDraft>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _ScheduleTimeSheet(items: timeline),
    );
    if (edited == null) return null;
    return parsed.rebuild(edited);
  }

  static _ParsedScheduleCard? _parse(String rawA2ui) {
    try {
      final source = rawA2ui.trim();
      final jsonText = source.startsWith('```')
          ? source
                .replaceFirst(RegExp(r'^```json\s*'), '')
                .replaceFirst(RegExp(r'\s*```$'), '')
                .trim()
          : source;
      final decoded = jsonDecode(jsonText);
      if (decoded is! List) return null;
      final messages = decoded
          .whereType<Map>()
          .map((item) => Map<String, Object?>.from(item))
          .toList();
      for (final message in messages) {
        final update = message['updateComponents'];
        if (update is! Map) continue;
        final components = update['components'];
        if (components is! List) continue;
        for (final component in components.whereType<Map>()) {
          if (component['component'] != 'Timeline') continue;
          final items = component['items'];
          if (items is! List) continue;
          return _ParsedScheduleCard(
            messages: messages,
            timelineComponent: component,
            timeline: items
                .whereType<Map>()
                .map(
                  (item) => _TimelineDraft(
                    time: _text(item['time']),
                    title: _text(item['title']),
                    detail: _text(item['detail']),
                  ),
                )
                .toList(),
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
}

class _ParsedScheduleCard {
  final List<Map<String, Object?>> messages;
  final Map timelineComponent;
  final List<_TimelineDraft> timeline;

  const _ParsedScheduleCard({
    required this.messages,
    required this.timelineComponent,
    required this.timeline,
  });

  String rebuild(List<_TimelineDraft> edited) {
    timelineComponent['items'] = edited
        .map(
          (item) => {
            'time': item.time.trim().isEmpty ? 'Next' : item.time.trim(),
            'title': item.title.trim().isEmpty ? 'Block' : item.title.trim(),
            if (item.detail.trim().isNotEmpty) 'detail': item.detail.trim(),
          },
        )
        .toList();
    const encoder = JsonEncoder.withIndent('  ');
    return '```json\n${encoder.convert(messages)}\n```';
  }
}

class _TimelineDraft {
  final String time;
  final String title;
  final String detail;

  const _TimelineDraft({
    required this.time,
    required this.title,
    required this.detail,
  });
}

class _ScheduleTimeSheet extends StatefulWidget {
  final List<_TimelineDraft> items;

  const _ScheduleTimeSheet({required this.items});

  @override
  State<_ScheduleTimeSheet> createState() => _ScheduleTimeSheetState();
}

class _ScheduleTimeSheetState extends State<_ScheduleTimeSheet> {
  late final List<TextEditingController> _timeControllers;
  late final List<TextEditingController> _titleControllers;
  late final List<TextEditingController> _detailControllers;

  @override
  void initState() {
    super.initState();
    _timeControllers = widget.items
        .map((item) => TextEditingController(text: item.time))
        .toList();
    _titleControllers = widget.items
        .map((item) => TextEditingController(text: item.title))
        .toList();
    _detailControllers = widget.items
        .map((item) => TextEditingController(text: item.detail))
        .toList();
  }

  @override
  void dispose() {
    for (final controller in [
      ..._timeControllers,
      ..._titleControllers,
      ..._detailControllers,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: Spacing.lg,
          right: Spacing.lg,
          top: Spacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit schedule',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'Adjust the time blocks before saving the card.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: Spacing.md),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: Spacing.md),
                  itemBuilder: (context, index) => _TimeBlockEditor(
                    timeController: _timeControllers[index],
                    titleController: _titleControllers[index],
                    detailController: _detailControllers[index],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          List.generate(
                            widget.items.length,
                            (index) => _TimelineDraft(
                              time: _timeControllers[index].text,
                              title: _titleControllers[index].text,
                              detail: _detailControllers[index].text,
                            ),
                          ),
                        );
                      },
                      child: const Text('Update card'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeBlockEditor extends StatelessWidget {
  final TextEditingController timeController;
  final TextEditingController titleController;
  final TextEditingController detailController;

  const _TimeBlockEditor({
    required this.timeController,
    required this.titleController,
    required this.detailController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 104,
                child: _EditorField(
                  controller: timeController,
                  label: 'Time',
                  hint: '9-10 AM',
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: _EditorField(
                  controller: titleController,
                  label: 'Block',
                  hint: 'Study German',
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          _EditorField(
            controller: detailController,
            label: 'Detail',
            hint: 'What should happen in this block?',
          ),
        ],
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _EditorField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppTheme.onSurface, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        hintStyle: TextStyle(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.38),
        ),
        filled: true,
        fillColor: AppTheme.surfaceHigh.withValues(alpha: 0.7),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppTheme.warning),
        ),
      ),
    );
  }
}
