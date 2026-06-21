import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';
import '../../../widgets/motion/wonderous_motion.dart';

class FloatingNavBar extends StatelessWidget {
  static const List<_NavItem> _items = [
    _NavItem(LucideIcons.layoutDashboard, 'Home'),
    _NavItem(LucideIcons.checkSquare, 'Tasks'),
    _NavItem(LucideIcons.activity, 'Habits'),
    _NavItem(LucideIcons.timer, 'Focus'),
    _NavItem(LucideIcons.bookOpen, 'Journal'),
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
            return Expanded(
              child: Semantics(
                label: item.label,
                child: PressableScale(
                  onTap: () => onTap(i),
                  pressedScale: 0.88,
                  child: AnimatedContainer(
                    duration: Motion.normal,
                    curve: Curves.easeOutBack,
                    padding: EdgeInsets.symmetric(
                      horizontal: Spacing.xs,
                      vertical: Spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary.withValues(alpha: 0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.28),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: isActive ? 1.16 : 1,
                          duration: Motion.normal,
                          curve: Curves.easeOutBack,
                          child: isActive
                              ? CinematicPulse(
                                  minScale: 0.98,
                                  maxScale: 1.08,
                                  child: Icon(
                                    item.icon,
                                    size: 24,
                                    color: AppTheme.primary,
                                  ),
                                )
                              : Icon(
                                  item.icon,
                                  size: 24,
                                  color: AppTheme.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                        ),
                        SizedBox(height: Spacing.xs),
                        AnimatedDefaultTextStyle(
                          duration: Motion.fast,
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            fontSize: isActive ? 11 : 10,
                            fontWeight: isActive
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isActive
                                ? AppTheme.primary
                                : AppTheme.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
