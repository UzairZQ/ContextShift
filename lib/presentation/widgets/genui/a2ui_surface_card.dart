import 'dart:async';

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

  const A2uiSurfaceCard({
    super.key,
    required this.rawA2ui,
    required this.onAction,
    this.source,
    this.fallbackReason,
    this.elapsedMs,
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
        _transport.addChunk(widget.rawA2ui);
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
    if (event.name == 'save_card' || event.name == 'edit_schedule_times') {
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
