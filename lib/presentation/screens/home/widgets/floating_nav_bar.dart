import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';

class FloatingNavBar extends StatelessWidget {
  static const List<_NavItem> _items = [
    _NavItem(LucideIcons.layoutDashboard, 'Home'),
    _NavItem(LucideIcons.checkSquare, 'Tasks'),
    _NavItem(LucideIcons.activity, 'Habits'),
    _NavItem(LucideIcons.timer, 'Focus'),
    _NavItem(LucideIcons.stickyNote, 'Notes'),
  ];

  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.only(
          left: Spacing.xxl,
          right: Spacing.xxl,
          bottom: Spacing.lg,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: AppTheme.glassmorphism(
          tint: AppTheme.surfaceHighest,
          opacity: 0.90,
          borderRadius: 999,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isActive = currentIndex == i;
            return Semantics(
              label: item.label,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: HitTarget.navItem,
                ),
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    padding: EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 24,
                          color: isActive
                              ? AppTheme.primary
                              : AppTheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                        ),
                        SizedBox(height: Spacing.xs),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: isActive
                                ? AppTheme.primary
                                : AppTheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}
