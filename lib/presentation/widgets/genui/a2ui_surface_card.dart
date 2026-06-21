import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

import '../../../core/app_spacing.dart';
import '../../../core/app_theme.dart';
import '../../../core/genui/widget_node.dart';
import '../motion/wonderous_motion.dart';

class A2uiSurfaceCard extends StatefulWidget {
  final String rawA2ui;
  final ValueChanged<WidgetAction> onAction;

  const A2uiSurfaceCard({
    super.key,
    required this.rawA2ui,
    required this.onAction,
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
    _catalog = BasicCatalogItems.asNoAssetCatalog();
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
        for (final surfaceId in _surfaceIds)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: WonderousReveal(
              child: Surface(
                surfaceContext: _controller.contextFor(surfaceId),
                actionDelegate: _JarvisActionDelegate(widget.onAction),
              ),
            ),
          ),
      ],
    );
  }
}

class _JarvisActionDelegate implements ActionDelegate {
  final ValueChanged<WidgetAction> onAction;

  const _JarvisActionDelegate(this.onAction);

  @override
  bool handleEvent(
    BuildContext context,
    UiEvent event,
    SurfaceContext genUiContext,
    Widget Function(SurfaceDefinition, Catalog, String, DataContext)
    buildWidget,
  ) {
    if (event is! UserActionEvent) return false;
    onAction(
      WidgetAction(
        action: event.name,
        params: Map<String, dynamic>.from(event.context),
      ),
    );
    return true;
  }
}
