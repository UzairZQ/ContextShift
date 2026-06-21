import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_spacing.dart';
import '../../core/app_theme.dart';

class JarvisHero {
  JarvisHero._();

  static const tag = 'jarvis_bar';

  static RectTween createRectTween(Rect? begin, Rect? end) {
    return RectTween(begin: begin, end: end);
  }

  static Widget flightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.08, 1, curve: Motion.smoothEnter),
      reverseCurve: Motion.smoothExit,
    );
    final glow = Tween<double>(
      begin: 0.08,
      end: 0.16,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return FadeTransition(
          opacity: fade,
          child: Material(
            color: Colors.transparent,
            child: RepaintBoundary(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.xl,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHighest.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: glow.value),
                      blurRadius: 34,
                      offset: const Offset(0, 14),
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.sparkles,
                      color: AppTheme.primary,
                      size: 19,
                    ),
                    const SizedBox(width: Spacing.md),
                    SizedBox(
                      width: 128,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppTheme.onSurfaceVariant.withValues(
                            alpha: 0.18,
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    const Icon(
                      LucideIcons.send,
                      color: AppTheme.primary,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
