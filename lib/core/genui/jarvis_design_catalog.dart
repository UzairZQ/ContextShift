import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app_spacing.dart';
import '../app_theme.dart';

class JarvisDesignCatalog {
  JarvisDesignCatalog._();

  static Catalog extend(Catalog base) {
    return base.copyWith(
      newItems: [
        heroPanel,
        insightCallout,
        metricTile,
        progressMeter,
        timeline,
        checklist,
        workoutBlock,
        comparisonTable,
        actionDock,
      ],
      systemPromptFragments: [
        ...base.systemPromptFragments,
        'ContextShift also provides a higher-level Jarvis design catalog. Use '
            'these components when the user asks for rich cards, plans, '
            'workouts, schedules, trackers, dashboards, comparisons, or '
            'decision support. Prefer these over manually nesting many basic '
            'widgets when they fit the job.',
        'Jarvis components available: HeroPanel for summary headers, '
            'InsightCallout for advice/warnings, MetricTile for dashboards, '
            'ProgressMeter for quantified progress, Timeline for schedules, '
            'Checklist for tasks or step plans, WorkoutBlock for exercise '
            'routines, ComparisonTable for options, and ActionDock for final '
            'actions.',
        'Compose multiple Jarvis components together for larger asks. Example: '
            'a full-body workout can use HeroPanel, WorkoutBlock sections, '
            'Checklist for warmup/cooldown, ProgressMeter for intensity, and '
            'ActionDock for saving or continuing.',
      ],
    );
  }

  static final heroPanel = CatalogItem(
    name: 'HeroPanel',
    dataSchema: ObjectSchema(
      description: 'A compact hero/header panel for generated views.',
      properties: {
        'title': _string('Primary title.'),
        'subtitle': _string('Short supporting copy.'),
        'eyebrow': _string('Small context label.'),
        'tone': _tone(),
      },
      required: ['title'],
    ),
    widgetBuilder: (context) {
      final data = _map(context.data);
      final tone = _toneColor(data['tone']);
      return _Panel(
        color: tone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_text(data['eyebrow']).isNotEmpty) ...[
              Text(
                _text(data['eyebrow']).toUpperCase(),
                style: TextStyle(
                  color: tone,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: Spacing.xs),
            ],
            Text(
              _text(data['title'], fallback: 'Generated view'),
              style: Theme.of(context.buildContext).textTheme.titleLarge
                  ?.copyWith(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (_text(data['subtitle']).isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                _text(data['subtitle']),
                style: const TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  static final insightCallout = CatalogItem(
    name: 'InsightCallout',
    dataSchema: ObjectSchema(
      description: 'A highlighted note, warning, coaching cue, or insight.',
      properties: {
        'title': _string('Callout title.'),
        'body': _string('One or two useful sentences.'),
        'tone': _tone(),
        'icon': _icon(),
      },
      required: ['body'],
    ),
    widgetBuilder: (context) {
      final data = _map(context.data);
      final tone = _toneColor(data['tone']);
      return _Panel(
        color: tone,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_iconData(data['icon']), color: tone, size: 20),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_text(data['title']).isNotEmpty)
                    Text(
                      _text(data['title']),
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Text(
                    _text(data['body']),
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  static final metricTile = CatalogItem(
    name: 'MetricTile',
    dataSchema: ObjectSchema(
      description: 'A dashboard metric or compact statistic.',
      properties: {
        'label': _string('Metric label.'),
        'value': _string('Metric value.'),
        'caption': _string('Short explanation or trend.'),
        'tone': _tone(),
        'icon': _icon(),
      },
      required: ['label', 'value'],
    ),
    widgetBuilder: (context) {
      final data = _map(context.data);
      final tone = _toneColor(data['tone']);
      return _Panel(
        color: tone,
        child: Row(
          children: [
            Icon(_iconData(data['icon']), color: tone, size: 22),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _text(data['value']),
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _text(data['label']),
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_text(data['caption']).isNotEmpty)
                    Text(
                      _text(data['caption']),
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  static final progressMeter = CatalogItem(
    name: 'ProgressMeter',
    dataSchema: ObjectSchema(
      description: 'A labeled horizontal progress or intensity meter.',
      properties: {
        'label': _string('Progress label.'),
        'value': NumberSchema(
          description: 'Current value between 0 and 1.',
          minimum: 0,
          maximum: 1,
        ),
        'caption': _string('Short caption.'),
        'tone': _tone(),
      },
      required: ['label', 'value'],
    ),
    widgetBuilder: (context) {
      final data = _map(context.data);
      final tone = _toneColor(data['tone']);
      final value = _number(data['value']).clamp(0, 1).toDouble();
      return _Panel(
        color: tone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _text(data['label']),
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${(value * 100).round()}%',
                  style: TextStyle(color: tone, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppTheme.surfaceHighest,
                color: tone,
              ),
            ),
            if (_text(data['caption']).isNotEmpty) ...[
              const SizedBox(height: Spacing.sm),
              Text(
                _text(data['caption']),
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );

  static final checklist = CatalogItem(
    name: 'Checklist',
    dataSchema: ObjectSchema(
      description: 'A list of checkable steps, tasks, cues, or requirements.',
      properties: {
        'title': _string('Checklist title.'),
        'items': _list(_checkItemSchema, 'Checklist items.'),
        'tone': _tone(),
      },
      required: ['title', 'items'],
    ),
    widgetBuilder: (context) {
      final data = _map(context.data);
      final tone = _toneColor(data['tone']);
      return _Panel(
        color: tone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PanelTitle(title: _text(data['title']), color: tone),
            const SizedBox(height: Spacing.sm),
            for (final item in _items(data['items']))
              _LineItem(
                icon: item['done'] == true
                    ? LucideIcons.checkCircle2
                    : LucideIcons.circle,
                color: tone,
                title: _text(item['title']),
                detail: _text(item['detail']),
              ),
          ],
        ),
      );
    },
  );

  static final timeline = CatalogItem(
    name: 'Timeline',
    dataSchema: ObjectSchema(
      description:
          'A time-based plan, agenda, schedule, itinerary, or routine.',
      properties: {
        'title': _string('Timeline title.'),
        'items': _list(_timelineItemSchema, 'Timeline items.'),
        'tone': _tone(),
      },
      required: ['title', 'items'],
    ),
    widgetBuilder: (context) {
      final data = _map(context.data);
      final tone = _toneColor(data['tone']);
      return _Panel(
        color: tone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PanelTitle(title: _text(data['title']), color: tone),
            const SizedBox(height: Spacing.sm),
            for (final item in _items(data['items']))
              _LineItem(
                icon: LucideIcons.clock3,
                color: tone,
                title: _text(item['title']),
                label: _text(item['time']),
                detail: _text(item['detail']),
              ),
          ],
        ),
      );
    },
  );

  static final workoutBlock = CatalogItem(
    name: 'WorkoutBlock',
    dataSchema: ObjectSchema(
      description:
          'A workout section with exercises, sets, reps, rest, or cues.',
      properties: {
        'title': _string('Workout block title.'),
        'focus': _string('Muscle group, intensity, or goal.'),
        'exercises': _list(_exerciseSchema, 'Exercises in this block.'),
        'tone': _tone(),
      },
      required: ['title', 'exercises'],
    ),
    widgetBuilder: (context) {
      final data = _map(context.data);
      final tone = _toneColor(data['tone']);
      return _Panel(
        color: tone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PanelTitle(
              title: _text(data['title']),
              caption: _text(data['focus']),
              color: tone,
              icon: LucideIcons.dumbbell,
            ),
            const SizedBox(height: Spacing.sm),
            for (final item in _items(data['exercises']))
              _LineItem(
                icon: LucideIcons.activity,
                color: tone,
                title: _text(item['name']),
                label: [
                  if (_text(item['sets']).isNotEmpty) _text(item['sets']),
                  if (_text(item['reps']).isNotEmpty) _text(item['reps']),
                  if (_text(item['duration']).isNotEmpty)
                    _text(item['duration']),
                ].join(' · '),
                detail: [
                  if (_text(item['rest']).isNotEmpty)
                    'Rest ${_text(item['rest'])}',
                  if (_text(item['cue']).isNotEmpty) _text(item['cue']),
                ].join(' · '),
              ),
          ],
        ),
      );
    },
  );

  static final comparisonTable = CatalogItem(
    name: 'ComparisonTable',
    dataSchema: ObjectSchema(
      description: 'A compact comparison of options, tradeoffs, or choices.',
      properties: {
        'title': _string('Comparison title.'),
        'columns': _list(_string('Column label.'), 'Column labels.'),
        'rows': _list(_comparisonRowSchema, 'Comparison rows.'),
        'tone': _tone(),
      },
      required: ['title', 'columns', 'rows'],
    ),
    widgetBuilder: (context) {
      final data = _map(context.data);
      final tone = _toneColor(data['tone']);
      final columns = _strings(data['columns']);
      return _Panel(
        color: tone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PanelTitle(title: _text(data['title']), color: tone),
            const SizedBox(height: Spacing.sm),
            if (columns.isNotEmpty)
              _ComparisonLine(cells: columns, color: tone, isHeader: true),
            for (final row in _items(data['rows']))
              _ComparisonLine(cells: _strings(row['cells']), color: tone),
          ],
        ),
      );
    },
  );

  static final actionDock = CatalogItem(
    name: 'ActionDock',
    dataSchema: ObjectSchema(
      description: 'A row/wrap of action buttons that dispatch app events.',
      properties: {
        'actions': _list(_actionSchema, 'Actions to show.'),
        'tone': _tone(),
      },
      required: ['actions'],
    ),
    widgetBuilder: (context) {
      final data = _map(context.data);
      final tone = _toneColor(data['tone']);
      return Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.sm,
        children: [
          for (final action in _items(data['actions']))
            ElevatedButton(
              onPressed: () => context.dispatchEvent(
                UserActionEvent(
                  name: _text(
                    action['event'],
                    fallback: 'continue_conversation',
                  ),
                  sourceComponentId: context.id,
                  context: {
                    if (_text(action['message']).isNotEmpty)
                      'message': _text(action['message']),
                    if (_text(action['title']).isNotEmpty)
                      'title': _text(action['title']),
                    if (_text(action['name']).isNotEmpty)
                      'name': _text(action['name']),
                    if (_text(action['content']).isNotEmpty)
                      'content': _text(action['content']),
                    if (_text(action['priority']).isNotEmpty)
                      'priority': _text(action['priority']),
                    if (_number(action['duration_minutes']) > 0)
                      'duration_minutes': _number(
                        action['duration_minutes'],
                      ).round(),
                  },
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: tone,
                foregroundColor: Colors.white,
              ),
              child: Text(_text(action['label'], fallback: 'Continue')),
            ),
        ],
      );
    },
  );
}

final _checkItemSchema = ObjectSchema(
  properties: {
    'title': _string('Item title.'),
    'detail': _string('Optional detail.'),
    'done': BooleanSchema(description: 'Whether the item is complete.'),
  },
  required: ['title'],
);

final _timelineItemSchema = ObjectSchema(
  properties: {
    'time': _string('Time range or sequence label.'),
    'title': _string('Item title.'),
    'detail': _string('Optional detail.'),
  },
  required: ['title'],
);

final _exerciseSchema = ObjectSchema(
  properties: {
    'name': _string('Exercise name.'),
    'sets': _string('Sets, e.g. 3 sets.'),
    'reps': _string('Reps, e.g. 8-10 reps.'),
    'duration': _string('Duration, e.g. 45 sec.'),
    'rest': _string('Rest interval.'),
    'cue': _string('Technique or coaching cue.'),
  },
  required: ['name'],
);

final _comparisonRowSchema = ObjectSchema(
  properties: {
    'cells': _list(_string('Cell text.'), 'Cells matching the columns.'),
  },
  required: ['cells'],
);

final _actionSchema = ObjectSchema(
  properties: {
    'label': _string('Button label.'),
    'event': StringSchema(
      description: 'App event name.',
      enumValues: [
        'create_task',
        'create_habit',
        'create_note',
        'start_focus',
        'continue_conversation',
      ],
    ),
    'title': _string('Optional title payload.'),
    'name': _string('Optional habit name payload.'),
    'content': _string('Optional note content payload.'),
    'priority': StringSchema(
      description: 'Optional task priority.',
      enumValues: ['low', 'normal', 'high'],
    ),
    'duration_minutes': NumberSchema(
      description: 'Optional focus duration in minutes.',
      minimum: 5,
      maximum: 180,
    ),
    'message': _string('Optional message payload.'),
  },
  required: ['label', 'event'],
);

StringSchema _string(String description) =>
    StringSchema(description: description, maxLength: 240);

StringSchema _tone() => StringSchema(
  description: 'Visual tone.',
  enumValues: ['primary', 'accent', 'success', 'warning', 'danger', 'neutral'],
);

StringSchema _icon() => StringSchema(
  description: 'Icon hint.',
  enumValues: [
    'sparkles',
    'calendar',
    'clock',
    'check',
    'activity',
    'dumbbell',
    'target',
    'warning',
    'info',
    'star',
  ],
);

ListSchema _list(Schema items, String description) => ListSchema(
  description: description,
  items: items,
  minItems: 1,
  maxItems: 12,
);

JsonMap _map(Object value) => value is JsonMap ? value : const {};

List<JsonMap> _items(Object? value) {
  if (value is! List) return const [];
  return value.whereType<JsonMap>().toList(growable: false);
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}

String _text(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

num _number(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

Color _toneColor(Object? value) {
  return switch (_text(value)) {
    'accent' => AppTheme.accent,
    'success' => AppTheme.success,
    'warning' => AppTheme.warning,
    'danger' => AppTheme.error,
    'neutral' => AppTheme.onSurfaceVariant,
    _ => AppTheme.primary,
  };
}

IconData _iconData(Object? value) {
  return switch (_text(value)) {
    'calendar' => LucideIcons.calendarDays,
    'clock' => LucideIcons.clock3,
    'check' => LucideIcons.checkCircle2,
    'activity' => LucideIcons.activity,
    'dumbbell' => LucideIcons.dumbbell,
    'target' => LucideIcons.target,
    'warning' => LucideIcons.triangleAlert,
    'info' => LucideIcons.info,
    'star' => LucideIcons.star,
    _ => LucideIcons.sparkles,
  };
}

class _Panel extends StatelessWidget {
  final Widget child;
  final Color color;

  const _Panel({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: Spacing.cardPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final String title;
  final String caption;
  final Color color;
  final IconData? icon;

  const _PanelTitle({
    required this.title,
    required this.color,
    this.caption = '',
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 18),
          const SizedBox(width: Spacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (caption.isNotEmpty)
                Text(
                  caption,
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LineItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String label;
  final String detail;

  const _LineItem({
    required this.icon,
    required this.color,
    required this.title,
    this.label = '',
    this.detail = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (label.isNotEmpty) ...[
                      const SizedBox(width: Spacing.sm),
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.75),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonLine extends StatelessWidget {
  final List<String> cells;
  final Color color;
  final bool isHeader;

  const _ComparisonLine({
    required this.cells,
    required this.color,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          for (final cell in cells)
            Expanded(
              child: Text(
                cell,
                style: TextStyle(
                  color: isHeader ? color : AppTheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
