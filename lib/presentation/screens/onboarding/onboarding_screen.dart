import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../widgets/motion/wonderous_motion.dart';
import 'widgets/glow_orb.dart';
import 'widgets/onboarding_page_view.dart';
import 'widgets/page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingPageData> _pages = [
    OnboardingPageData(
      eyebrow: 'Capture the chaos',
      title: 'Too much in your head?\nDrop it here.',
      body:
          'Write the messy version. JARVIS helps turn scattered thoughts, overdue tasks, and half-made plans into one clear next move.',
      icon: LucideIcons.sparkles,
      accent: AppTheme.primary,
    ),
    OnboardingPageData(
      eyebrow: 'One place to restart',
      title: 'Find the next move.\nNot another list.',
      body:
          'Tasks, habits, notes, focus, and mood finally work together. Open the app and see what matters now, without rebuilding your day.',
      icon: LucideIcons.compass,
      accent: AppTheme.warning,
    ),
    OnboardingPageData(
      eyebrow: 'Private by default',
      title: 'Built to work\noffline.',
      body:
          'On a train, in a tunnel, or hiding from bad Wi-Fi, your workspace still works. JARVIS runs on your phone, so a weak signal never breaks your flow.',
      icon: LucideIcons.wifiOff,
      accent: AppTheme.success,
    ),
    OnboardingPageData(
      eyebrow: 'Yours means yours',
      title: 'Your life isn\'t\ntraining data.',
      body:
          'Your plans, moods, notes, and conversations stay on your device. No cloud history to sell. No audience. Just a private space that helps.',
      icon: LucideIcons.shield,
      accent: AppTheme.tertiary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage == _pages.length - 1) {
      widget.onComplete();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.background,
                AppTheme.surfaceLow,
                page.accent.withValues(alpha: 0.06),
                page.accent.withValues(alpha: 0.16),
              ],
              stops: const [0, 0.48, 0.74, 1],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -110,
                right: -42,
                child: _BreathingOrb(
                  color: page.accent,
                  size: 260,
                  travel: const Offset(-18, 22),
                ),
              ),
              Positioned(
                bottom: 80,
                left: -20,
                child: _BreathingOrb(
                  color: AppTheme.tertiary.withValues(alpha: 0.7),
                  size: 180,
                  travel: const Offset(16, -18),
                  delay: const Duration(milliseconds: 360),
                ),
              ),
              Positioned(
                top: 120,
                left: -84,
                child: _BreathingOrb(
                  color: page.accent.withValues(alpha: 0.65),
                  size: 130,
                  travel: const Offset(26, 10),
                  delay: const Duration(milliseconds: 720),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    WonderousReveal(
                      begin: const Offset(0, -0.05),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: Row(
                          children: [
                            Text(
                              'ContextShift',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const Spacer(),
                            PressableScale(
                              onTap: widget.onComplete,
                              pressedScale: 0.94,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: const Text('Skip'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemBuilder: (context, index) => OnboardingPageView(
                          page: _pages[index],
                          controller: _pageController,
                          index: index,
                        ),
                      ),
                    ),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 180),
                      begin: const Offset(0, 0.04),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Column(
                          children: [
                            PageIndicator(
                              count: _pages.length,
                              currentIndex: _currentPage,
                              activeColor: page.accent,
                            ),
                            const SizedBox(height: 18),
                            PressableScale(
                              onTap: _next,
                              pressedScale: 0.965,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 340),
                                curve: Curves.easeOutCubic,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: page.accent,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: page.accent.withValues(
                                        alpha: 0.26,
                                      ),
                                      blurRadius: 28,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _currentPage == _pages.length - 1
                                      ? 'Build my space'
                                      : 'Next',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathingOrb extends StatefulWidget {
  final Color color;
  final double size;
  final Offset travel;
  final Duration delay;

  const _BreathingOrb({
    required this.color,
    required this.size,
    required this.travel,
    this.delay = Duration.zero,
  });

  @override
  State<_BreathingOrb> createState() => _BreathingOrbState();
}

class _BreathingOrbState extends State<_BreathingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine);

    Future<void>.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return GlowOrb(color: widget.color, size: widget.size);
    }

    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final value = _curve.value;
        return Transform.translate(
          offset: Offset(widget.travel.dx * value, widget.travel.dy * value),
          child: Transform.scale(
            scale: 0.94 + (value * 0.1),
            child: GlowOrb(color: widget.color, size: widget.size),
          ),
        );
      },
    );
  }
}
