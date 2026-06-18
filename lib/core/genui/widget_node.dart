import 'dart:convert';

class WidgetNode {
  final String widget;
  final Map<String, dynamic> props;
  final List<WidgetNode> children;
  final WidgetAction? onTap;
  final WidgetAction? onAction;

  WidgetNode({
    required this.widget,
    this.props = const {},
    this.children = const [],
    this.onTap,
    this.onAction,
  });

  factory WidgetNode.fromJson(Map<String, dynamic> json) {
    return WidgetNode(
      widget: json['widget'] as String? ?? 'SizedBox',
      props: Map<String, dynamic>.from(json['props'] as Map? ?? {}),
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => WidgetNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      onTap: json['onTap'] != null
          ? WidgetAction.fromJson(json['onTap'] as Map<String, dynamic>)
          : null,
      onAction: json['onAction'] != null
          ? WidgetAction.fromJson(json['onAction'] as Map<String, dynamic>)
          : null,
    );
  }

  static WidgetNode? tryParse(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) return null;
      return WidgetNode.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}

class WidgetAction {
  final String action;
  final Map<String, dynamic> params;

  WidgetAction({required this.action, this.params = const {}});

  factory WidgetAction.fromJson(Map<String, dynamic> json) {
    return WidgetAction(
      action: json['action'] as String? ?? '',
      params: Map<String, dynamic>.from(json['params'] as Map? ?? {}),
    );
  }
}
