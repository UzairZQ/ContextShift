import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_spacing.dart';

class WonderousReveal extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Offset begin;

  const WonderousReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.begin = const Offset(0, 0.08),
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.expressive + delay,
      curve: Interval(
        delay.inMilliseconds /
            math.max(1, (Motion.expressive + delay).inMilliseconds),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(begin.dx * 80, begin.dy * 80) * (1 - value),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.975,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1,
          duration: Motion.fast,
          curve: Curves.easeOutBack,
          child: widget.child,
        ),
      ),
    );
  }
}

class PointerTilt extends StatefulWidget {
  final Widget child;
  final double maxTilt;

  const PointerTilt({super.key, required this.child, this.maxTilt = 0.025});

  @override
  State<PointerTilt> createState() => _PointerTiltState();
}

class _PointerTiltState extends State<PointerTilt> {
  Offset _position = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return widget.child;
    return MouseRegion(
      onExit: (_) => setState(() => _position = Offset.zero),
      child: GestureDetector(
        onPanUpdate: (details) {
          final size = context.size;
          if (size == null) return;
          setState(() {
            _position = Offset(
              (details.localPosition.dx / size.width - 0.5) * 2,
              (details.localPosition.dy / size.height - 0.5) * 2,
            );
          });
        },
        onPanEnd: (_) => setState(() => _position = Offset.zero),
        child: AnimatedContainer(
          duration: Motion.fast,
          transformAlignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(-_position.dy * widget.maxTilt)
            ..rotateY(_position.dx * widget.maxTilt),
          child: widget.child,
        ),
      ),
    );
  }
}
