import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';

class OnboardingPageData {
  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  const OnboardingPageData({
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
  });
}

class OnboardingPageView extends StatelessWidget {
  final OnboardingPageData page;

  const OnboardingPageView({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
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
                  page.accent.withValues(alpha: 0.18),
                  page.accent.withValues(alpha: 0.35),
                ],
              ),
              border: Border.all(
                color: page.accent.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: page.accent.withValues(alpha: 0.18),
                  blurRadius: 32,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontSize: 38, height: 1.02),
          ),
          const SizedBox(height: 18),
          Text(
            page.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.onSurface.withValues(alpha: 0.72),
                  height: 1.55,
                ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
