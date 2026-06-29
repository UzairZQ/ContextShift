import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/responsive.dart';

class ContextShiftWordmark extends StatelessWidget {
  final bool compact;
  final TextAlign textAlign;

  const ContextShiftWordmark({
    super.key,
    this.compact = false,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = compact
        ? 24.0
        : Responsive.isMobile(context)
        ? 28.0
        : 36.0;

    return Material(
      color: Colors.transparent,
      child: Text(
        'ContextShift',
        textAlign: textAlign,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          letterSpacing: 0,
          color: AppTheme.onSurface,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
