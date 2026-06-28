import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../../shared/context_shift_primitives.dart';

class DashStatCard extends StatelessWidget {
  final String value;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;

  const DashStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ContextPanel(
      padding: const EdgeInsets.all(16),
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
