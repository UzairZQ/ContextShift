import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import '../../../core/app_spacing.dart';
import '../../../core/app_theme.dart';
import '../../../core/genui/jarvis_design_catalog.dart';
import '../../../core/genui/widget_node.dart';

class A2uiSurfaceCard extends StatefulWidget {
  final String rawA2ui;
  final ValueChanged<WidgetAction> onAction;
  final String? source;
  final String? fallbackReason;
  final int? elapsedMs;
  final Set<String> hiddenActionNames;

  const A2uiSurfaceCard({
    super.key,
    required this.rawA2ui,
    required this.onAction,
    this.source,
    this.fallbackReason,
    this.elapsedMs,
    this.hiddenActionNames = const {},
  });

  @override
  State<A2uiSurfaceCard> createState() => _A2uiSurfaceCardState();
}

class _A2uiSurfaceCardState extends State<A2uiSurfaceCard> {
  late final Catalog _catalog;
  late final SurfaceController _controller;
  late final A2uiTransportAdapter _transport;
  late final Conversation _conversation;
  StreamSubscription<ConversationEvent>? _eventsSubscription;
  List<String> _surfaceIds = const [];
  Object? _error;

  @override
  void initState() {
    super.initState();
    _catalog = JarvisDesignCatalog.extend(BasicCatalogItems.asNoAssetCatalog());
    _controller = SurfaceController(catalogs: [_catalog]);
    _transport = A2uiTransportAdapter(onSend: (_) async {});
    _conversation = Conversation(
      controller: _controller,
      transport: _transport,
    );
    _eventsSubscription = _conversation.events.listen((event) {
      if (!mounted) return;
      switch (event) {
        case ConversationSurfaceAdded():
        case ConversationSurfaceRemoved():
          setState(() {
            _surfaceIds = _controller.activeSurfaceIds.toList(growable: false);
          });
        case ConversationError(:final error):
          setState(() => _error = error);
        default:
          break;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _transport.addChunk(_displayRawA2ui());
        _transport.addChunk('\n');
      } catch (error) {
        if (mounted) setState(() => _error = error);
      }
    });
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _conversation.dispose();
    _transport.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(
        'This generated view could not be restored.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppTheme.warning),
      );
    }
    if (_surfaceIds.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.source != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.xs),
            child: _GenerationSourceBadge(
              source: widget.source!,
              fallbackReason: widget.fallbackReason,
              elapsedMs: widget.elapsedMs,
            ),
          ),
        for (final surfaceId in _surfaceIds)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: Surface(
              surfaceContext: _controller.contextFor(surfaceId),
              actionDelegate: _JarvisActionDelegate(widget.onAction, widget),
            ),
          ),
      ],
    );
  }

  String _displayRawA2ui() {
    if (widget.hiddenActionNames.isEmpty) return widget.rawA2ui;
    try {
      final decoded = jsonDecode(_jsonPayload(widget.rawA2ui));
      if (decoded is! List) return widget.rawA2ui;
      final sanitized = decoded.map(_hideActionsInMessage).toList();
      return '```json\n${const JsonEncoder.withIndent('  ').convert(sanitized)}\n```';
    } catch (_) {
      return widget.rawA2ui;
    }
  }

  String _jsonPayload(String raw) {
    final trimmed = raw.trim();
    final fenced = RegExp(
      r'^```(?:json)?\s*([\s\S]*?)\s*```$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    return fenced?.group(1)?.trim() ?? trimmed;
  }

  Object? _hideActionsInMessage(Object? message) {
    if (message is! Map) return message;
    final map = Map<String, Object?>.from(message);
    final update = map['updateComponents'];
    if (update is! Map) return map;

    final updateMap = Map<String, Object?>.from(update);
    final components = updateMap['components'];
    if (components is! List) return map;

    final removedIds = <String>{};
    final nextComponents = <Object?>[];
    for (final component in components) {
      if (component is! Map || component['component'] != 'ActionDock') {
        nextComponents.add(component);
        continue;
      }

      final actionDock = Map<String, Object?>.from(component);
      final actions = actionDock['actions'];
      if (actions is! List) {
        nextComponents.add(actionDock);
        continue;
      }

      final visibleActions = actions
          .where((action) {
            if (action is! Map) return true;
            final event = action['event']?.toString();
            return event == null || !widget.hiddenActionNames.contains(event);
          })
          .toList(growable: false);

      if (visibleActions.isEmpty) {
        final id = actionDock['id']?.toString();
        if (id != null && id.isNotEmpty) removedIds.add(id);
        continue;
      }

      nextComponents.add({...actionDock, 'actions': visibleActions});
    }

    updateMap['components'] = removedIds.isEmpty
        ? nextComponents
        : _removeChildReferences(nextComponents, removedIds);
    return {...map, 'updateComponents': updateMap};
  }

  Object? _removeChildReferences(Object? value, Set<String> removedIds) {
    if (value is List) {
      return value
          .where((item) => item is! String || !removedIds.contains(item))
          .map((item) => _removeChildReferences(item, removedIds))
          .toList(growable: false);
    }
    if (value is Map) {
      return value.map<String, Object?>(
        (key, mapValue) => MapEntry(
          key.toString(),
          _removeChildReferences(mapValue, removedIds),
        ),
      );
    }
    return value;
  }
}

class _GenerationSourceBadge extends StatelessWidget {
  final String source;
  final String? fallbackReason;
  final int? elapsedMs;

  const _GenerationSourceBadge({
    required this.source,
    this.fallbackReason,
    this.elapsedMs,
  });

  @override
  Widget build(BuildContext context) {
    final isFallback = source == 'fallback';
    final color = isFallback ? AppTheme.warning : AppTheme.success;
    final seconds = elapsedMs == null
        ? null
        : (elapsedMs! / 1000).toStringAsFixed(1);
    final label = [
      isFallback ? 'Local fallback' : 'Gemma generated',
      if (seconds != null) '${seconds}s',
      if (isFallback && fallbackReason != null) fallbackReason!,
    ].join(' · ');

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _JarvisActionDelegate implements ActionDelegate {
  final ValueChanged<WidgetAction> onAction;
  final A2uiSurfaceCard widget;

  const _JarvisActionDelegate(this.onAction, this.widget);

  @override
  bool handleEvent(
    BuildContext context,
    UiEvent event,
    SurfaceContext genUiContext,
    Widget Function(SurfaceDefinition, Catalog, String, DataContext)
    buildWidget,
  ) {
    if (event is! UserActionEvent) return false;
    final params = Map<String, dynamic>.from(event.context);
    if (event.name == 'save_card' ||
        event.name == 'edit_schedule_times' ||
        event.name == 'add_schedule_to_tasks') {
      params.addAll({
        'rawA2ui': widget.rawA2ui,
        if (widget.source != null) 'source': widget.source,
        if (widget.fallbackReason != null)
          'fallbackReason': widget.fallbackReason,
        if (widget.elapsedMs != null) 'elapsedMs': widget.elapsedMs,
      });
    }
    onAction(WidgetAction(action: event.name, params: params));
    return true;
  }
}
