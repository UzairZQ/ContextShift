import 'package:flutter/material.dart';

/// 8dp grid spacing system per Material Design 3 guidelines.
/// All spacing values are multiples of 4 (4dp base unit).
class Spacing {
  Spacing._();

  /// 4dp — minimum gap between related elements
  static const double xs = 4;

  /// 8dp — default gap for tightly related items
  static const double sm = 8;

  /// 12dp — gap between grouped items
  static const double md = 12;

  /// 16dp — standard section padding
  static const double lg = 16;

  /// 20dp — between sections
  static const double xl = 20;

  /// 24dp — screen edge padding
  static const double xxl = 24;

  /// 32dp — large section separators
  static const double section = 32;

  /// 48dp — very large spacing
  static const double sectionLg = 48;

  /// 64dp — max spacing before it feels disconnected
  static const double sectionXl = 64;

  // Helpers
  static const EdgeInsets horizontalScreen = EdgeInsets.symmetric(
    horizontal: xxl,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(xxl);
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );
}

/// Motion duration tokens per M3 guidance.
class Motion {
  Motion._();

  /// 100ms — micro-interactions (ink ripple, press)
  static const Duration micro = Duration(milliseconds: 100);

  /// 200ms — small UI changes (toggle, fade)
  static const Duration fast = Duration(milliseconds: 200);

  /// 300ms — standard transitions
  static const Duration normal = Duration(milliseconds: 300);

  /// 350ms — moderate transitions
  static const Duration moderate = Duration(milliseconds: 350);

  /// 400ms — complex transitions
  static const Duration complex = Duration(milliseconds: 400);

  /// 600ms — expressive transitions (hero, cards)
  static const Duration expressive = Duration(milliseconds: 600);

  /// 1000ms — loading pulses
  static const Duration pulse = Duration(milliseconds: 1000);

  // Curves
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve emphasize = Curves.easeInOutCubicEmphasized;
  static const Curve decelerate = Curves.easeOutCubic;
}

/// Touch target minimum sizes per M3 (48dp) and HIG (44dp).
class HitTarget {
  HitTarget._();

  /// Minimum touch target for mobile (M3: 48dp)
  static const double min = 48;

  /// Minimum for icon-only buttons (M3: 48dp, HIG: 44dp)
  static const double icon = 48;

  /// Minimum width for bottom nav items
  static const double navItem = 64;
}
