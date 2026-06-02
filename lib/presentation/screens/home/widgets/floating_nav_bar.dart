import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
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
            return GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  item.icon,
                  size: 24,
                  color: isActive
                      ? AppTheme.primary
                      : AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
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
