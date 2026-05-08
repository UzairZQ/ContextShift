import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      title: 'Your space should\nwake up with you',
      body:
          'ContextShift reshapes your workspace around your energy, priorities, and mental state instead of trapping you in a static dashboard.',
      icon: LucideIcons.sparkles,
      accent: AppTheme.primary,
    ),
    _OnboardingPageData(
      title: 'JARVIS turns chaos\ninto the next move',
      body:
          'Capture a messy thought, a vague plan, or a moment of overwhelm and let the app convert it into tasks, habits, notes, and focus prompts.',
      icon: LucideIcons.bot,
      accent: AppTheme.warning,
    ),
    _OnboardingPageData(
      title: 'Start lightweight,\nkeep the door open',
      body:
          'Sign in for sync, or continue as a guest and build your flow first. The product should earn the account step, not demand it.',
      icon: LucideIcons.rocket,
      accent: AppTheme.success,
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
                child: _GlowOrb(color: page.accent, size: 220),
              ),
              Positioned(
                bottom: 80,
                left: -20,
                child: _GlowOrb(
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
                      itemBuilder: (context, index) {
                        final item = _pages[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Spacer(),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: LinearGradient(
                                    colors: [
                                      item.accent.withValues(alpha: 0.18),
                                      item.accent.withValues(alpha: 0.35),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: item.accent.withValues(alpha: 0.35),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: item.accent.withValues(
                                        alpha: 0.18,
                                      ),
                                      blurRadius: 32,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(fontSize: 38, height: 1.02),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                item.body,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppTheme.onSurface.withValues(
                                        alpha: 0.72,
                                      ),
                                      height: 1.55,
                                    ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(
                            _pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.only(right: 8),
                              width: index == _currentPage ? 28 : 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: index == _currentPage
                                    ? page.accent
                                    : Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
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
                                  ? 'Continue'
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

class _OnboardingPageData {
  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  const _OnboardingPageData({
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
