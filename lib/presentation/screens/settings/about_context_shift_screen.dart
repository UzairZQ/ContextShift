import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_spacing.dart';
import '../../../core/app_theme.dart';
import '../../../core/responsive.dart';
import '../../shared/context_shift_primitives.dart';
import '../../widgets/motion/wonderous_motion.dart';

class AboutContextShiftScreen extends StatelessWidget {
  const AboutContextShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsInfoScaffold(
      title: 'ContextShift',
      subtitle: 'A private productivity workspace that adapts to your day.',
      icon: LucideIcons.sparkles,
      children: const [
        InfoHero(
          title: 'Your day, rebuilt around context.',
          body:
              'ContextShift brings tasks, habits, focus, notes, mood, and JARVIS into one local workspace. Instead of forcing you into a static dashboard, it helps you restart, plan, and choose the next useful move.',
        ),
        InfoCard(
          icon: LucideIcons.messageSquare,
          title: 'Ask JARVIS',
          body:
              'Use the Home JARVIS bar for quick plans, checklists, schedules, and cards. Use Chat when you want a longer conversation or a generated view you can refine.',
        ),
        InfoCard(
          icon: LucideIcons.panelTop,
          title: 'Generate useful cards',
          body:
              'Build workout plans, study schedules, decision cards, trackers, and checklists. Save one active card to Home, edit schedule timings locally, or refine the prompt before asking Gemma again.',
        ),
        InfoCard(
          icon: LucideIcons.checkCircle2,
          title: 'Keep the basics moving',
          body:
              'Capture tasks, shape habits, run focus sessions, write quick notes, log your mood, and review the AI analysis summary when you want a read on your patterns.',
        ),
        InfoCard(
          icon: LucideIcons.repeat2,
          title: 'Build or break habits',
          body:
              'Habits can be positive routines you want to build or negative loops you want to reduce. Add cues, tiny steps, rewards, and friction so the habit has a real behavior design behind it.',
        ),
        InfoCard(
          icon: LucideIcons.cpu,
          title: 'On-device intelligence',
          body:
              'When the local Gemma model is downloaded, JARVIS can generate responses and structured cards on your phone. Simple actions still work instantly through local parsing.',
        ),
      ],
    );
  }
}

class SettingsInfoScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const SettingsInfoScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, AppTheme.surfaceLow],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
            ),
            child: ResponsiveWrapper(
              maxWidth: 560,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: Spacing.sm,
                        bottom: Spacing.lg,
                      ),
                      child: _InfoHeader(
                        title: title,
                        subtitle: subtitle,
                        icon: icon,
                      ),
                    ),
                  ),
                  SliverList.separated(
                    itemCount: children.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Spacing.md),
                    itemBuilder: (context, index) => WonderousReveal(
                      delay: Duration(milliseconds: 60 + (index * 35)),
                      child: children[index],
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: Spacing.section),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InfoHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return WonderousReveal(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            color: AppTheme.onSurface,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: AppTheme.intelligence),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InfoHero extends StatelessWidget {
  final String title;
  final String body;

  const InfoHero({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return ContextPanel(
      padding: const EdgeInsets.all(20),
      color: AppTheme.surfaceContainer,
      accent: AppTheme.intelligence,
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.contextPanel(
        color: AppTheme.surfaceHigh.withValues(alpha: 0.72),
        accent: AppTheme.intelligence,
        accentOpacity: 0.08,
        borderRadius: 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.intelligence.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.intelligence, size: 18),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
