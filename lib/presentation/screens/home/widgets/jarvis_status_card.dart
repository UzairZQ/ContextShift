import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';

/// Lifecycle of the on-device model, as the home screen presents it.
enum JarvisModelState { notDownloaded, standby, warming, ready }

/// Rich status surface shown while JARVIS is not fully ready.
///
/// Replaces the old thin warning banner: each state gets an icon, a plain
/// explanation, and a single obvious action. Renders nothing when ready.
class JarvisStatusCard extends StatefulWidget {
  final JarvisModelState state;
  final VoidCallback onDownload;
  final VoidCallback onWarmUp;

  const JarvisStatusCard({
    super.key,
    required this.state,
    required this.onDownload,
    required this.onWarmUp,
  });

  @override
  State<JarvisStatusCard> createState() => _JarvisStatusCardState();
}

class _JarvisStatusCardState extends State<JarvisStatusCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: Motion.pulse)
      ..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state == JarvisModelState.ready) {
      return const SizedBox.shrink();
    }

    final (icon, title, body, actionLabel, onAction) = switch (widget.state) {
      JarvisModelState.notDownloaded => (
        LucideIcons.hardDriveDownload,
        'JARVIS is not on this device yet',
        'Download the on-device model once (~2.6 GB). Everything runs '
            'locally — nothing ever leaves your phone.',
        'Download model',
        widget.onDownload,
      ),
      JarvisModelState.standby => (
        LucideIcons.cpu,
        'JARVIS is on standby',
        'The model is installed. Wake it now, or it wakes automatically '
            'with your first message.',
        'Wake JARVIS',
        widget.onWarmUp,
      ),
      _ => (
        LucideIcons.loaderCircle,
        'Warming up JARVIS...',
        'Loading the model into memory. This takes a few seconds on the '
            'first run.',
        null,
        null,
      ),
    };

    final isWarming = widget.state == JarvisModelState.warming;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = isWarming ? 0.16 + (0.14 * _pulse.value) : 0.12;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: isWarming ? 0.3 : 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: glow),
                blurRadius: 34,
                offset: const Offset(0, 14),
                spreadRadius: -12,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StatusIcon(icon: icon, spinning: isWarming, spin: _spin),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12.5,
                    height: 1.35,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 10),
                  _StatusAction(label: actionLabel, onTap: onAction!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final IconData icon;
  final bool spinning;
  final Animation<double> spin;

  const _StatusIcon({
    required this.icon,
    required this.spinning,
    required this.spin,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 22, color: AppTheme.primary);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primary.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.26)),
      ),
      child: spinning
          ? RotationTransition(turns: spin, child: iconWidget)
          : iconWidget,
    );
  }
}

class _StatusAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StatusAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
                spreadRadius: -6,
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.background,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}
