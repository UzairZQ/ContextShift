import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../app_spacing.dart';
import '../app_theme.dart';
import 'action_bus.dart';
import 'widget_node.dart';

/// Result of building a widget from the catalog.
class BuildResult {
  final Widget? widget;
  final String? error;

  BuildResult({this.widget, this.error});
}

/// A registered widget type in the catalog — knows how to validate and build.
class CatalogEntry {
  final String type;
  final List<String> allowedProps;
  final Widget Function(WidgetNode node, BuildContext context) builder;

  const CatalogEntry({
    required this.type,
    this.allowedProps = const [],
    required this.builder,
  });
}

/// Registry of all safe, allowed widgets that the AI can generate.
/// Any widget type not in [entries] is rejected.
class WidgetCatalog {
  WidgetCatalog._();
  static final WidgetCatalog instance = WidgetCatalog._();

  final List<CatalogEntry> _entries = [];
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _registerDefaults();
    _initialized = true;
  }

  void _registerDefaults() {
    _entries.addAll([
      // ── Layout ──
      CatalogEntry(
        type: 'Column',
        allowedProps: [
          'crossAxisAlignment',
          'mainAxisAlignment',
          'mainAxisSize',
        ],
        builder: (node, ctx) => _buildColumn(node, ctx),
      ),
      CatalogEntry(
        type: 'Row',
        allowedProps: [
          'crossAxisAlignment',
          'mainAxisAlignment',
          'mainAxisSize',
        ],
        builder: (node, ctx) => _buildRow(node, ctx),
      ),
      CatalogEntry(
        type: 'Container',
        allowedProps: [
          'padding',
          'margin',
          'width',
          'height',
          'decoration',
          'borderRadius',
          'color',
        ],
        builder: (node, ctx) => _buildContainer(node, ctx),
      ),
      CatalogEntry(
        type: 'SizedBox',
        allowedProps: ['width', 'height'],
        builder: (node, _) => SizedBox(
          width: _prop<double>(node, 'width'),
          height: _prop<double>(node, 'height'),
        ),
      ),
      CatalogEntry(
        type: 'Padding',
        allowedProps: ['all', 'horizontal', 'vertical'],
        builder: (node, ctx) => Padding(
          padding: _parseEdgeInsets(node.props),
          child: _renderFirstChild(node, ctx),
        ),
      ),

      // ── Display ──
      CatalogEntry(
        type: 'Text',
        allowedProps: ['content', 'style', 'color', 'align'],
        builder: (node, _) => _buildText(node),
      ),
      CatalogEntry(
        type: 'Icon',
        allowedProps: ['icon', 'size', 'color'],
        builder: (node, _) => Icon(
          _parseIcon(_prop<String>(node, 'icon')),
          size: _prop<double>(node, 'size', 20),
          color: _parseColor(_prop<String>(node, 'color')),
        ),
      ),
      CatalogEntry(
        type: 'Divider',
        allowedProps: ['thickness', 'color'],
        builder: (node, _) => Divider(
          thickness: _prop<double>(node, 'thickness', 1),
          color:
              _parseColor(_prop<String>(node, 'color')) ??
              AppTheme.onSurfaceVariant.withValues(alpha: 0.1),
        ),
      ),
      CatalogEntry(
        type: 'Spacer',
        allowedProps: [],
        builder: (_, _) => const Spacer(),
      ),

      // ── Interactive ──
      CatalogEntry(
        type: 'Chip',
        allowedProps: ['label', 'color', 'icon', 'selected'],
        builder: (node, ctx) => _buildChip(node, ctx),
      ),
      CatalogEntry(
        type: 'Button',
        allowedProps: ['label', 'color', 'variant', 'icon'],
        builder: (node, ctx) => _buildButton(node, ctx),
      ),
      CatalogEntry(
        type: 'CircularProgressIndicator',
        allowedProps: ['strokeWidth', 'color'],
        builder: (node, _) => CircularProgressIndicator(
          strokeWidth: _prop<double>(node, 'strokeWidth', 3),
          color: _parseColor(_prop<String>(node, 'color')) ?? AppTheme.primary,
        ),
      ),

      // ── Lists ──
      CatalogEntry(
        type: 'ListView',
        allowedProps: ['spacing'],
        builder: (node, ctx) => _buildListView(node, ctx),
      ),
      CatalogEntry(
        type: 'GridView',
        allowedProps: ['crossAxisCount', 'spacing', 'childAspectRatio'],
        builder: (node, ctx) => _buildGridView(node, ctx),
      ),
      CatalogEntry(
        type: 'Wrap',
        allowedProps: ['spacing', 'runSpacing'],
        builder: (node, ctx) => _buildWrap(node, ctx),
      ),

      // ── Dialogs / Overlays ──
      CatalogEntry(
        type: 'BottomSheet',
        allowedProps: ['title', 'children'],
        builder: (node, ctx) => _buildBottomSheet(node, ctx),
      ),
      CatalogEntry(
        type: 'Dialog',
        allowedProps: ['title', 'content', 'confirmLabel', 'cancelLabel'],
        builder: (node, ctx) => _buildDialog(node, ctx),
      ),

      // ── Card ──
      CatalogEntry(
        type: 'Card',
        allowedProps: ['padding', 'borderRadius', 'color'],
        builder: (node, ctx) => _buildCard(node, ctx),
      ),
    ]);
  }

  void register(CatalogEntry entry) {
    _entries.add(entry);
  }

  CatalogEntry? get(String type) {
    return _entries.cast<CatalogEntry?>().firstWhere(
      (e) => e!.type == type,
      orElse: () => null,
    );
  }

  bool isAllowed(String type) => get(type) != null;

  List<String> get allowedTypes => _entries.map((e) => e.type).toList();

  // ── Builders ──

  Widget _buildColumn(WidgetNode node, BuildContext ctx) {
    return Column(
      crossAxisAlignment: _parseCrossAxisAlignment(
        _prop<String>(node, 'crossAxisAlignment'),
      ),
      mainAxisAlignment: _parseMainAxisAlignment(
        _prop<String>(node, 'mainAxisAlignment'),
      ),
      mainAxisSize: _prop<String>(node, 'mainAxisSize') == 'min'
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: _buildChildren(node.children, ctx),
    );
  }

  Widget _buildRow(WidgetNode node, BuildContext ctx) {
    return Row(
      crossAxisAlignment: _parseCrossAxisAlignment(
        _prop<String>(node, 'crossAxisAlignment'),
      ),
      mainAxisAlignment: _parseMainAxisAlignment(
        _prop<String>(node, 'mainAxisAlignment'),
      ),
      mainAxisSize: _prop<String>(node, 'mainAxisSize') == 'min'
          ? MainAxisSize.min
          : MainAxisSize.max,
      children: _buildChildren(node.children, ctx),
    );
  }

  Widget _buildContainer(WidgetNode node, BuildContext ctx) {
    return Container(
      padding: _parseEdgeInsets(node.props['padding'] as Map<String, dynamic>?),
      margin: _parseEdgeInsets(node.props['margin'] as Map<String, dynamic>?),
      width: _prop<double>(node, 'width'),
      height: _prop<double>(node, 'height'),
      decoration: BoxDecoration(
        color: _parseColor(_prop<String>(node, 'color')),
        borderRadius: _prop<double>(node, 'borderRadius') != null
            ? BorderRadius.circular(_prop<double>(node, 'borderRadius')!)
            : null,
      ),
      child: _renderFirstChild(node, ctx),
    );
  }

  Widget _buildText(WidgetNode node) {
    final styleStr = _prop<String>(node, 'style');
    TextStyle? style;
    switch (styleStr) {
      case 'titleLarge':
        style = const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurface,
        );
      case 'titleMedium':
        style = const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurface,
        );
      case 'bodyLarge':
        style = const TextStyle(fontSize: 15, color: AppTheme.onSurfaceVariant);
      case 'bodySmall':
        style = const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant);
      case 'label':
        style = const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurfaceVariant,
          letterSpacing: 0.5,
        );
      default:
        style = const TextStyle(fontSize: 14, color: AppTheme.onSurface);
    }

    final colorStr = _prop<String>(node, 'color');
    if (colorStr != null) {
      style = style.copyWith(color: _parseColor(colorStr));
    }

    return Text(
      _prop<String>(node, 'content') ?? '',
      style: style,
      textAlign: _parseAlign(_prop<String>(node, 'align')),
    );
  }

  Widget _buildChip(WidgetNode node, BuildContext ctx) {
    final label = _prop<String>(node, 'label') ?? '';
    final color = _parseColor(_prop<String>(node, 'color')) ?? AppTheme.primary;
    final iconName = _prop<String>(node, 'icon');
    final selected = _prop<bool>(node, 'selected') ?? false;

    return Padding(
      padding: const EdgeInsets.only(right: Spacing.sm, bottom: Spacing.sm),
      child: GestureDetector(
        onTap: node.onTap != null
            ? () => _handleAction(node.onTap!, ctx)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.2)
                : AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(999),
            border: selected
                ? Border.all(color: color.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconName != null) ...[
                Icon(
                  _parseIcon(iconName),
                  size: 14,
                  color: selected ? color : AppTheme.onSurfaceVariant,
                ),
                const SizedBox(width: Spacing.xs),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? color : AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(WidgetNode node, BuildContext ctx) {
    final label = _prop<String>(node, 'label') ?? '';
    final color = _parseColor(_prop<String>(node, 'color')) ?? AppTheme.primary;
    final variant = _prop<String>(node, 'variant') ?? 'filled';
    final iconName = _prop<String>(node, 'icon');

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconName != null) ...[
          Icon(_parseIcon(iconName), size: 16, color: Colors.white),
          const SizedBox(width: Spacing.sm),
        ],
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: node.onTap != null ? () => _handleAction(node.onTap!, ctx) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl,
          vertical: Spacing.md,
        ),
        decoration: BoxDecoration(
          color: variant == 'outlined' ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(999),
          border: variant == 'outlined'
              ? Border.all(color: color.withValues(alpha: 0.5))
              : null,
        ),
        child: child,
      ),
    );
  }

  Widget _buildListView(WidgetNode node, BuildContext ctx) {
    final spacing = _prop<double>(node, 'spacing', 0) ?? 0;
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _buildChildrenWithSpacing(node.children, ctx, spacing),
    );
  }

  Widget _buildGridView(WidgetNode node, BuildContext ctx) {
    final crossAxisCount = _prop<int>(node, 'crossAxisCount', 2) ?? 2;
    final spacing = _prop<double>(node, 'spacing', 8) ?? 8;
    final aspectRatio = _prop<double>(node, 'childAspectRatio', 1.0) ?? 1.0;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: aspectRatio,
      ),
      children: _buildChildren(node.children, ctx),
    );
  }

  Widget _buildWrap(WidgetNode node, BuildContext ctx) {
    final spacing = _prop<double>(node, 'spacing', 8) ?? 8;
    final runSpacing = _prop<double>(node, 'runSpacing', 8) ?? 8;
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: _buildChildren(node.children, ctx),
    );
  }

  Widget _buildBottomSheet(WidgetNode node, BuildContext ctx) {
    final title = _prop<String>(node, 'title') ?? '';
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: _buildChildren(node.children, ctx),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: ctx,
        backgroundColor: AppTheme.surfaceLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(Spacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),
              if (title.isNotEmpty) ...[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
              ],
              content,
            ],
          ),
        ),
      );
    });

    return const SizedBox.shrink();
  }

  Widget _buildDialog(WidgetNode node, BuildContext ctx) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surfaceLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: _prop<String>(node, 'title') != null
              ? Text(
                  _prop<String>(node, 'title')!,
                  style: const TextStyle(color: AppTheme.onSurface),
                )
              : null,
          content: _prop<String>(node, 'content') != null
              ? Text(
                  _prop<String>(node, 'content')!,
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                )
              : null,
          actions: [
            if (_prop<String>(node, 'cancelLabel') != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  _prop<String>(node, 'cancelLabel')!,
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ),
            if (_prop<String>(node, 'confirmLabel') != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (node.onAction != null) {
                    _handleAction(node.onAction!, ctx);
                  }
                },
                child: Text(
                  _prop<String>(node, 'confirmLabel')!,
                  style: const TextStyle(color: AppTheme.primary),
                ),
              ),
          ],
        ),
      );
    });

    return const SizedBox.shrink();
  }

  Widget _buildCard(WidgetNode node, BuildContext ctx) {
    return Container(
      padding: node.props['padding'] != null
          ? _parseEdgeInsets(node.props['padding'] as Map<String, dynamic>)
          : Spacing.cardPadding,
      decoration: BoxDecoration(
        color:
            _parseColor(_prop<String>(node, 'color')) ??
            AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(
          _prop<double>(node, 'borderRadius', 16) ?? 16,
        ),
      ),
      child: _renderFirstChild(node, ctx),
    );
  }

  // ── Helpers ──

  Widget? _renderFirstChild(WidgetNode node, BuildContext ctx) {
    if (node.children.isEmpty) return null;
    return buildSingle(node.children.first, ctx);
  }

  List<Widget> _buildChildren(List<WidgetNode> children, BuildContext ctx) {
    return children.map((c) => buildSingle(c, ctx)).toList();
  }

  List<Widget> _buildChildrenWithSpacing(
    List<WidgetNode> children,
    BuildContext ctx,
    double spacing,
  ) {
    final list = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) list.add(SizedBox(height: spacing));
      list.add(buildSingle(children[i], ctx));
    }
    return list;
  }

  Widget buildSingle(WidgetNode node, BuildContext ctx) {
    final entry = get(node.widget);
    if (entry == null) {
      return _buildFallbackText('Unknown widget: ${node.widget}');
    }
    return entry.builder(node, ctx);
  }

  Widget _buildFallbackText(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Text(
        message,
        style: const TextStyle(
          color: AppTheme.warning,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  void _handleAction(WidgetAction action, BuildContext ctx) {
    debugPrint('[GenUI] Action triggered: ${action.action} ${action.params}');
    GenUiActionBus.instance.emit(action);
  }

  // ── Property Parsers ──

  T? _prop<T>(WidgetNode node, String key, [T? defaultValue]) {
    final val = node.props[key];
    if (val == null) return defaultValue;
    if (val is T) return val;
    // Handle numeric coercion
    if (T == double && val is int) return (val as num).toDouble() as T;
    if (T == int && val is double) return (val as num).toInt() as T;
    return defaultValue;
  }

  EdgeInsets _parseEdgeInsets(Map<String, dynamic>? props) {
    if (props == null) return EdgeInsets.zero;
    return EdgeInsets.only(
      left: (props['left'] as num?)?.toDouble() ?? 0,
      right: (props['right'] as num?)?.toDouble() ?? 0,
      top: (props['top'] as num?)?.toDouble() ?? 0,
      bottom: (props['bottom'] as num?)?.toDouble() ?? 0,
    );
  }

  CrossAxisAlignment _parseCrossAxisAlignment(String? value) {
    switch (value) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'center':
        return CrossAxisAlignment.center;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.start;
    }
  }

  MainAxisAlignment _parseMainAxisAlignment(String? value) {
    switch (value) {
      case 'start':
        return MainAxisAlignment.start;
      case 'end':
        return MainAxisAlignment.end;
      case 'center':
        return MainAxisAlignment.center;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  TextAlign _parseAlign(String? value) {
    switch (value) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
        return TextAlign.center;
      default:
        return TextAlign.start;
    }
  }

  Color? _parseColor(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'primary':
        return AppTheme.primary;
      case 'primaryDim':
        return AppTheme.primaryDim;
      case 'tertiary':
        return AppTheme.tertiary;
      case 'success':
        return AppTheme.success;
      case 'warning':
        return AppTheme.warning;
      case 'error':
        return AppTheme.error;
      case 'surface':
        return AppTheme.surfaceContainer;
      case 'surfaceHigh':
        return AppTheme.surfaceHigh;
      case 'onSurface':
        return AppTheme.onSurface;
      case 'onSurfaceVariant':
        return AppTheme.onSurfaceVariant;
      default:
        try {
          return Color(int.parse(value.replaceFirst('#', '0xFF')));
        } catch (_) {
          return null;
        }
    }
  }

  IconData _parseIcon(String? name) {
    if (name == null) return LucideIcons.helpCircle;
    switch (name) {
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'brain':
        return LucideIcons.brain;
      case 'checkSquare':
        return LucideIcons.checkSquare;
      case 'activity':
        return LucideIcons.activity;
      case 'timer':
        return LucideIcons.timer;
      case 'flame':
        return LucideIcons.flame;
      case 'target':
        return LucideIcons.target;
      case 'messageSquare':
        return LucideIcons.messageSquare;
      case 'coffee':
        return LucideIcons.coffee;
      case 'batteryCharging':
        return LucideIcons.batteryCharging;
      case 'rotateCcw':
        return LucideIcons.rotateCcw;
      case 'skipForward':
        return LucideIcons.skipForward;
      case 'play':
        return LucideIcons.play;
      case 'pause':
        return LucideIcons.pause;
      case 'send':
        return LucideIcons.send;
      case 'plus':
        return LucideIcons.plus;
      case 'trash2':
        return LucideIcons.trash2;
      case 'arrowLeft':
        return LucideIcons.arrowLeft;
      case 'chevronRight':
        return LucideIcons.chevronRight;
      case 'downloadCloud':
        return LucideIcons.downloadCloud;
      case 'settings':
        return LucideIcons.settings;
      case 'barChart2':
        return LucideIcons.barChart2;
      case 'shield':
        return LucideIcons.shield;
      case 'info':
        return LucideIcons.info;
      case 'crown':
        return LucideIcons.crown;
      case 'lock':
        return LucideIcons.lock;
      case 'user':
        return LucideIcons.user;
      case 'userPlus':
        return LucideIcons.userPlus;
      case 'star':
        return LucideIcons.star;
      case 'heart':
        return LucideIcons.heart;
      case 'zap':
        return LucideIcons.zap;
      case 'globe':
        return LucideIcons.globe;
      case 'sun':
        return LucideIcons.sun;
      case 'moon':
        return LucideIcons.moon;
      case 'cloudOff':
        return LucideIcons.cloudOff;
      case 'loader2':
        return LucideIcons.loader2;
      default:
        return LucideIcons.helpCircle;
    }
  }
}
