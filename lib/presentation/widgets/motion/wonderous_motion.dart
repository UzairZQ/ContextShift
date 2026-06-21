import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_spacing.dart';

class WonderousReveal extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Offset begin;
  final double scaleBegin;
  final double rotationBegin;

  const WonderousReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.begin = const Offset(0, 0.12),
    this.scaleBegin = 0.98,
    this.rotationBegin = 0,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.moderate + delay,
      curve: Interval(
        delay.inMilliseconds /
            math.max(1, (Motion.moderate + delay).inMilliseconds),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, value, child) {
        final clampedOpacity = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: clampedOpacity,
          child: Transform.translate(
            offset: Offset(begin.dx * 56, begin.dy * 56) * (1 - value),
            child: Transform.rotate(
              angle: rotationBegin * (1 - value),
              child: Transform.scale(
                scale: scaleBegin + ((1 - scaleBegin) * value),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class CinematicFloat extends StatefulWidget {
  final Widget child;
  final Offset travel;
  final double scaleDelta;
  final Duration duration;
  final Duration delay;
  final bool enabled;

  const CinematicFloat({
    super.key,
    required this.child,
    this.travel = const Offset(0, -5),
    this.scaleDelta = 0.012,
    this.duration = const Duration(milliseconds: 3600),
    this.delay = Duration.zero,
    this.enabled = false,
  });

  @override
  State<CinematicFloat> createState() => _CinematicFloatState();
}

class _CinematicFloatState extends State<CinematicFloat>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    final controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller = controller;
    _animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutSine,
    );
    Future<void>.delayed(widget.delay, () {
      if (mounted) controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animation = _animation;
    if (reduceMotion || !widget.enabled || animation == null) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: animation,
      child: widget.child,
      builder: (context, child) {
        final value = animation.value;
        return Transform.translate(
          offset: Offset(widget.travel.dx * value, widget.travel.dy * value),
          child: Transform.scale(
            scale: 1 + (widget.scaleDelta * value),
            child: child,
          ),
        );
      },
    );
  }
}

class CinematicPulse extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;
  final bool enabled;

  const CinematicPulse({
    super.key,
    required this.child,
    this.minScale = 0.96,
    this.maxScale = 1.08,
    this.duration = const Duration(milliseconds: 2200),
    this.enabled = false,
  });

  @override
  State<CinematicPulse> createState() => _CinematicPulseState();
}

class _CinematicPulseState extends State<CinematicPulse>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) return;
    final controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    _controller = controller;
    _animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animation = _animation;
    if (reduceMotion || !widget.enabled || animation == null) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: animation,
      child: widget.child,
      builder: (context, child) {
        return Transform.scale(
          scale:
              widget.minScale +
              ((widget.maxScale - widget.minScale) * animation.value),
          child: child,
        );
      },
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
    if (widget.onTap == null) {
      return widget.child;
    }

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

class PointerTilt extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final bool enabled;

  const PointerTilt({
    super.key,
    required this.child,
    this.maxTilt = 0.025,
    this.enabled = false,
  });

  @override
  State<PointerTilt> createState() => _PointerTiltState();
}

class _PointerTiltState extends State<PointerTilt> {
  Offset _position = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion || !widget.enabled) return widget.child;
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
