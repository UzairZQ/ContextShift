import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_theme.dart';

class ProductivityTip extends StatelessWidget {
  const ProductivityTip({super.key});

  static const _morningTip =
      'Early sessions have 20% higher completion rates. Your flow is strongest now.';
  static const _afternoonTip =
      'The afternoon slump is real. Consider a 5-minute movement break between sessions.';
  static const _eveningTip =
      'Deep work before bed can affect sleep. Aim for one final "Review" session.';

  String get _tip {
    final hour = DateTime.now().hour;
    if (hour < 11) return _morningTip;
    if (hour < 17) return _afternoonTip;
    return _eveningTip;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.lightbulb, color: AppTheme.intelligence, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _tip,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
