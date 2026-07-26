import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';

class FloatingNavBar extends StatelessWidget {
  static const List<_NavItem> _items = [
    _NavItem(LucideIcons.house, 'Home'),
    _NavItem(LucideIcons.squareCheckBig, 'Tasks'),
    _NavItem(LucideIcons.activity, 'Habits'),
    _NavItem(LucideIcons.timer, 'Focus'),
    _NavItem(LucideIcons.notebookPen, 'Journal'),
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
        margin: EdgeInsets.only(left: Spacing.xl, right: Spacing.xl, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: AppTheme.contextPanel(
          color: AppTheme.surfaceHighest.withValues(alpha: 0.94),
          accent: AppTheme.intelligence,
          borderRadius: 999,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isActive = currentIndex == i;
            return Expanded(
              child: Semantics(
                label: item.label,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: Motion.fast,
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: Spacing.xs,
                        vertical: Spacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.intelligence.withValues(alpha: 0.14)
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
                                ? AppTheme.intelligence
                                : AppTheme.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                          SizedBox(height: Spacing.xs),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isActive ? 11 : 10,
                              fontWeight: isActive
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isActive
                                  ? AppTheme.intelligence
                                  : AppTheme.onSurfaceVariant.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                          ),
                        ],
                      ),
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
