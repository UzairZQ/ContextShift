import 'package:flutter/material.dart';

import '../../core/app_spacing.dart';
import '../../core/app_theme.dart';
import 'widget_catalog.dart';
import 'widget_node.dart';

/// Error types that the [SafeRenderer] may encounter.
enum RenderError {
  emptyInput,
  invalidJson,
  invalidStructure,
  widgetNotAllowed,
  emptyOutput,
}

/// Result from rendering A2UI JSON.
class RenderResult {
  final Widget? widget;
  final RenderError? error;
  final String? errorMessage;

  RenderResult({this.widget, this.error, this.errorMessage});

  bool get isSuccess => widget != null && error == null;
  bool get isError => error != null;
}

/// Validates and renders A2UI JSON against the [WidgetCatalog].
/// Blocks unsafe widgets (WebView, PlatformView, etc.) and validates
/// all properties against each catalog entry's allowed list.
class SafeRenderer {
  final WidgetCatalog catalog;

  const SafeRenderer({required this.catalog});

  /// Parse and render a JSON string into a widget tree.
  RenderResult render(String jsonString, BuildContext context) {
    if (jsonString.trim().isEmpty) {
      return RenderResult(
        error: RenderError.emptyInput,
        errorMessage: 'Empty input received.',
      );
    }

    final node = WidgetNode.tryParse(jsonString);
    if (node == null) {
      return RenderResult(
        error: RenderError.invalidJson,
        errorMessage: 'Could not parse the response as valid JSON.',
      );
    }

    if (node.widget == 'SizedBox' && node.props.isEmpty) {
      return RenderResult(
        error: RenderError.emptyOutput,
        errorMessage: 'No content could be rendered.',
      );
    }

    final validationError = _validateNode(node);
    if (validationError != null) {
      return RenderResult(
        error: RenderError.widgetNotAllowed,
        errorMessage: validationError,
      );
    }

    try {
      final built = catalog.buildSingle(node, context);
      return RenderResult(widget: built);
    } catch (e, stack) {
      debugPrint('[SafeRenderer] build error: $e\n$stack');
      return RenderResult(
        error: RenderError.invalidStructure,
        errorMessage: 'Failed to build the UI: $e',
      );
    }
  }

  /// Recursively validate a node tree against the catalog.
  String? _validateNode(WidgetNode node) {
    if (!catalog.isAllowed(node.widget)) {
      return 'Widget "${node.widget}" is not in the allowed catalog. '
          'Allowed types: ${catalog.allowedTypes.join(", ")}';
    }

    final entry = catalog.get(node.widget)!;

    for (final key in node.props.keys) {
      if (!entry.allowedProps.contains(key)) {
        return 'Property "$key" is not allowed on widget "${node.widget}". '
            'Allowed: ${entry.allowedProps.join(", ")}';
      }
    }

    if (node.widget == 'WebView' ||
        node.widget == 'PlatformView' ||
        node.widget == 'iframe' ||
        node.widget == 'HtmlElementView') {
      return 'Widget "${node.widget}" is blocked for security reasons.';
    }

    for (final child in node.children) {
      final childError = _validateNode(child);
      if (childError != null) return childError;
    }

    return null;
  }

  /// Build a fallback text widget when rendering fails.
  static Widget buildFallbackWidget(String text) {
    return Container(
      padding: Spacing.cardPadding,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: AppTheme.warning.withValues(alpha: 0.8),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
