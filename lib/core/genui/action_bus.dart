import 'dart:async';

import 'widget_node.dart';

class GenUiActionBus {
  GenUiActionBus._();
  static final GenUiActionBus instance = GenUiActionBus._();

  final _controller = StreamController<WidgetAction>.broadcast();

  Stream<WidgetAction> get actions => _controller.stream;

  void emit(WidgetAction action) {
    if (action.action.trim().isNotEmpty) {
      _controller.add(action);
    }
  }
}
