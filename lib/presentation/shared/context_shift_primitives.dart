import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_spacing.dart';
import '../../core/app_theme.dart';

class ContextPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? accent;
  final double radius;

  const ContextPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.margin,
    this.color,
    this.accent,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: AppTheme.contextPanel(
        color: color,
        accent: accent,
        borderRadius: radius,
      ),
      child: child,
    );
  }
}

class ContextSectionLabel extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;

  const ContextSectionLabel({
    super.key,
    required this.text,
    this.icon,
    this.color = AppTheme.intelligence,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: Spacing.xs),
        ],
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class ContextSignalBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const ContextSignalBadge({
    super.key,
    required this.label,
    this.icon = LucideIcons.audioLines,
    this.color = AppTheme.intelligence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class ContextFieldPainter extends CustomPainter {
  final Color color;
  final double opacity;

  const ContextFieldPainter({
    this.color = AppTheme.intelligence,
    this.opacity = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Intentionally blank: older ContextShift panels used quiet surfaces
    // without decorative signal lines.
  }

  @override
  bool shouldRepaint(covariant ContextFieldPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}
