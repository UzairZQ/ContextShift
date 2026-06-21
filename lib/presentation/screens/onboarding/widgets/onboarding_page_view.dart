import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../../widgets/motion/wonderous_motion.dart';

class OnboardingPageData {
  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  const OnboardingPageData({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });
}

class OnboardingPageView extends StatelessWidget {
  final OnboardingPageData page;
  final PageController controller;
  final int index;

  const OnboardingPageView({
    super.key,
    required this.page,
    required this.controller,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final offset = _pageOffset;
        final distance = offset.abs().clamp(0.0, 1.0);
        final opacity = 1 - (distance * 0.35);
        final scale = 1 - (distance * 0.045);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Transform.translate(
                    offset: Offset(offset * -34, 0),
                    child: WonderousReveal(
                      begin: const Offset(-0.04, 0.08),
                      child: _DepthIconCard(page: page),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Transform.translate(
                    offset: Offset(offset * -20, 0),
                    child: WonderousReveal(
                      delay: const Duration(milliseconds: 55),
                      begin: const Offset(0, 0.04),
                      child: _Eyebrow(page: page),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Transform.translate(
                    offset: Offset(offset * -14, 0),
                    child: WonderousReveal(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        page.title,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(fontSize: 38, height: 1.02),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Transform.translate(
                    offset: Offset(offset * -8, 0),
                    child: WonderousReveal(
                      delay: const Duration(milliseconds: 165),
                      child: Text(
                        page.body,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.onSurface.withValues(alpha: 0.72),
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double get _pageOffset {
    if (!controller.hasClients || !controller.position.hasContentDimensions) {
      return 0;
    }
    final pageValue = controller.page ?? controller.initialPage.toDouble();
    return pageValue - index;
  }
}

class _DepthIconCard extends StatelessWidget {
  final OnboardingPageData page;

  const _DepthIconCard({required this.page});

  @override
  Widget build(BuildContext context) {
    return CinematicFloat(
      travel: const Offset(0, -9),
      scaleDelta: 0.018,
      child: PointerTilt(
        maxTilt: 0.075,
        child: SizedBox(
          width: 126,
          height: 112,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: 2,
                top: 10,
                child: CinematicPulse(
                  minScale: 0.88,
                  maxScale: 1.12,
                  duration: const Duration(milliseconds: 2600),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: page.accent.withValues(alpha: 0.28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: page.accent.withValues(alpha: 0.14),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                bottom: 0,
                child: Container(
                  width: 72,
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: page.accent.withValues(alpha: 0.34),
                        blurRadius: 34,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutCubic,
                width: 98,
                height: 98,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(31),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      page.accent.withValues(alpha: 0.42),
                      AppTheme.surfaceHigh.withValues(alpha: 0.84),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: page.accent.withValues(alpha: 0.34),
                      blurRadius: 54,
                      offset: const Offset(0, 22),
                    ),
                  ],
                ),
                child: Icon(page.icon, size: 40, color: Colors.white),
              ),
              Positioned(
                left: 76,
                top: 74,
                child: CinematicPulse(
                  minScale: 0.82,
                  maxScale: 1.18,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: page.accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.background.withValues(alpha: 0.7),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: page.accent.withValues(alpha: 0.34),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final OnboardingPageData page;

  const _Eyebrow({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: page.accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: page.accent.withValues(alpha: 0.25)),
      ),
      child: Text(
        page.eyebrow.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: page.accent,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
