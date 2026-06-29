import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_theme.dart';
import '../../../shared/context_shift_primitives.dart';

class DashHeader extends StatelessWidget {
  const DashHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceHigh,
              ),
              child: const Icon(
                LucideIcons.arrowLeft,
                size: 18,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ContextShift',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'A read on your local patterns',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Transform.scale(
            scale: 0.86,
            alignment: Alignment.centerRight,
            child: const ContextSignalBadge(
              label: 'Private',
              icon: LucideIcons.lock,
            ),
          ),
        ],
      ),
    );
  }
}
