import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';

class ThinkingCard extends StatelessWidget {
  const ThinkingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'JARVIS is processing your request',
      child: Container(
        margin: EdgeInsets.only(bottom: Spacing.lg),
        padding: EdgeInsets.all(Spacing.xl),
        decoration: AppTheme.glassmorphism(
          tint: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: 20,
        ),
        child: Row(
          children: [
            const ThinkingPulse(),
            SizedBox(width: Spacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JARVIS is working on it...',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Building a generative command module based on your prompt.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThinkingPulse extends StatefulWidget {
  const ThinkingPulse({super.key});

  @override
  State<ThinkingPulse> createState() => _ThinkingPulseState();
}

class _ThinkingPulseState extends State<ThinkingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Motion.pulse)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary.withValues(alpha: 0.1),
            border: Border.all(
              color: AppTheme.primary.withValues(
                alpha: 0.2 + (0.3 * _controller.value),
              ),
              width: 1,
            ),
          ),
          child: Icon(
            LucideIcons.sparkles,
            size: 16 + (4 * _controller.value),
            color: AppTheme.primary.withValues(
              alpha: 0.6 + (0.4 * _controller.value),
            ),
          ),
        );
      },
    );
  }
}
