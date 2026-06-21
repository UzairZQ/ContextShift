import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/app_spacing.dart';
import '../../core/app_theme.dart';
import '../../core/genui/safe_renderer.dart';
import '../../core/genui/widget_catalog.dart';
import 'tasks/widgets/add_task_sheet.dart';

class GenerativeCardModule extends StatelessWidget {
  final Map<String, dynamic> cardData;
  final VoidCallback? onAction;

  const GenerativeCardModule({
    super.key,
    required this.cardData,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    WidgetCatalog.instance.init();
    final renderer = SafeRenderer(catalog: WidgetCatalog.instance);

    // Check if this is raw A2UI JSON (has "widget" key)
    if (cardData.containsKey('widget') || cardData.containsKey('a2ui')) {
      final jsonSource =
          cardData['a2ui'] as String? ?? _mapToJsonString(cardData);
      final result = renderer.render(jsonSource, context);
      if (result.isSuccess) {
        return result.widget!;
      }
      return SafeRenderer.buildFallbackWidget(
        result.errorMessage ?? 'Could not render this content.',
      );
    }

    // ── Legacy card format (backward compatible) ──
    return _buildLegacyCard(context);
  }

  Widget _buildLegacyCard(BuildContext context) {
    final title = cardData['title'] as String? ?? 'Intelligence';
    final type = cardData['type'] as String? ?? 'advice';
    final description = cardData['description'] as String? ?? '';
    final listItems = (cardData['list_items'] as List<dynamic>?) ?? [];
    final actionLabel = cardData['action_label'] as String?;

    IconData headerIcon = LucideIcons.sparkles;
    Color themeColor = AppTheme.primary;

    if (type == 'workout') {
      headerIcon = LucideIcons.dumbbell;
      themeColor = AppTheme.accent;
    } else if (type == 'planner') {
      headerIcon = LucideIcons.calendarClock;
      themeColor = AppTheme.tertiary;
    } else if (type == 'advice') {
      headerIcon = LucideIcons.lightbulb;
      themeColor = AppTheme.tertiary;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.moderate,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              padding: Spacing.cardPaddingLg,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Spacing.xxl),
                border: Border.all(
                  color: themeColor.withValues(alpha: 0.22),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Spacing.sm),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.14),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Icon(headerIcon, color: themeColor, size: 20),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (type == 'planner' || type == 'workout')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(Spacing.sm),
                  ),
                  child: Text(
                    'INTERACTABLE',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          if (description.isNotEmpty) ...[
            Text(
              description,
              style: const TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: Spacing.xl),
          ],
          if (listItems.isNotEmpty)
            ...listItems.map((item) {
              final String text = (item is Map)
                  ? (item['text'] ?? '')
                  : item.toString();
              final Map<String, dynamic>? taskPayload =
                  (item is Map && item['task_payload'] is Map)
                  ? Map<String, dynamic>.from(item['task_payload'] as Map)
                  : null;
              return Semantics(
                label: text,
                button: taskPayload != null,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.md),
                  child: InkWell(
                    onTap: (taskPayload != null)
                        ? () => AddTaskSheet.show(
                            context,
                            initialTitle: taskPayload['title'],
                            initialPriority: taskPayload['priority'],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(Spacing.md),
                    child: Container(
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(Spacing.md),
                        border: Border.all(
                          color: taskPayload != null
                              ? themeColor.withValues(alpha: 0.15)
                              : AppTheme.onSurfaceVariant.withValues(
                                  alpha: 0.1,
                                ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Icon(
                              taskPayload != null
                                  ? LucideIcons.plusCircle
                                  : LucideIcons.checkCircle2,
                              color: taskPayload != null
                                  ? themeColor
                                  : themeColor.withValues(alpha: 0.4),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Text(
                              text,
                              style: TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: taskPayload != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          if (listItems.isNotEmpty) const SizedBox(height: Spacing.sm),
          if (actionLabel != null && actionLabel.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor.withValues(alpha: 0.2),
                  foregroundColor: themeColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Spacing.lg),
                    side: BorderSide(
                      color: themeColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  actionLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _mapToJsonString(Map<String, dynamic> map) {
    final buf = StringBuffer();
    _writeJson(buf, map);
    return buf.toString();
  }

  void _writeJson(StringBuffer buf, dynamic value) {
    if (value == null) {
      buf.write('null');
    } else if (value is String) {
      buf.write('"');
      buf.write(value.replaceAll('"', '\\"').replaceAll('\n', '\\n'));
      buf.write('"');
    } else if (value is num || value is bool) {
      buf.write(value.toString());
    } else if (value is Map) {
      buf.write('{');
      bool first = true;
      for (final entry in value.entries) {
        if (!first) buf.write(',');
        first = false;
        _writeJson(buf, entry.key.toString());
        buf.write(':');
        _writeJson(buf, entry.value);
      }
      buf.write('}');
    } else if (value is List) {
      buf.write('[');
      for (int i = 0; i < value.length; i++) {
        if (i > 0) buf.write(',');
        _writeJson(buf, value[i]);
      }
      buf.write(']');
    }
  }
}
