import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/app_theme.dart';
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
      title: 'Your AI lives on\nyour phone',
      body:
          'JARVIS runs on-device, not in the cloud. No servers, no subscriptions, no one listening in. Your AI, your rules — private by design.',
      icon: LucideIcons.sparkles,
      accent: AppTheme.primary,
    ),
    OnboardingPageData(
      title: 'No internet?\nNo problem.',
      body:
          'Planes, tunnels, the middle of nowhere — JARVIS doesn\'t care. Every task, note, and insight lives on your device without needing a signal.',
      icon: LucideIcons.wifiOff,
      accent: AppTheme.warning,
    ),
    OnboardingPageData(
      title: 'Your data stays\nyours',
      body:
          'No cloud upload, no account trap, no data mining. Everything stays in your pocket and nowhere else. The product should earn your trust, not demand it.',
      icon: LucideIcons.shield,
      accent: AppTheme.success,
    ),
    OnboardingPageData(
      title: 'Your space,\nyour rules',
      body:
          'A workspace that bends around your energy and priorities instead of trapping you in a static dashboard. Capture the chaos, build momentum, and let JARVIS help you move.',
      icon: LucideIcons.layoutDashboard,
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
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.background,
              AppTheme.surfaceLow,
              page.accent.withValues(alpha: 0.16),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -40,
                child: GlowOrb(color: page.accent, size: 220),
              ),
              Positioned(
                bottom: 80,
                left: -20,
                child: GlowOrb(
                  color: AppTheme.tertiary.withValues(alpha: 0.7),
                  size: 180,
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(
                      children: [
                        Text(
                          'ContextShift',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: widget.onComplete,
                          child: const Text('Skip'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) =>
                          OnboardingPageView(page: _pages[index]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      children: [
                        PageIndicator(
                          count: _pages.length,
                          currentIndex: _currentPage,
                          activeColor: page.accent,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _next,
                            style: FilledButton.styleFrom(
                              backgroundColor: page.accent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              _currentPage == _pages.length - 1
                                  ? 'Let\'s go'
                                  : 'Next',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
