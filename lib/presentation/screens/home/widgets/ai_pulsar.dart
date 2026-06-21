import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';

class AiPulsar extends StatefulWidget {
  final bool isAnalyzing;
  final bool isOnline;

  const AiPulsar({super.key, this.isAnalyzing = false, this.isOnline = false});

  @override
  State<AiPulsar> createState() => _AiPulsarState();
}

class _AiPulsarState extends State<AiPulsar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.isAnalyzing),
    )..repeat();
  }

  @override
  void didUpdateWidget(AiPulsar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnalyzing != oldWidget.isAnalyzing ||
        widget.isOnline != oldWidget.isOnline) {
      _controller.duration = _durationFor(widget.isAnalyzing);
      _controller.repeat();
    }
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
        final color = _statusColor;
        final wave = Curves.easeOutCubic.transform(_controller.value);
        final glowStrength = widget.isOnline ? 0.85 : 0.58;
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 12 + (18 * wave),
                height: 12 + (18 * wave),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: glowStrength * (1 - wave)),
                ),
              ),
              _CoreDot(color: color, isOnline: widget.isOnline),
            ],
          ),
        );
      },
    );
  }

  Color get _statusColor =>
      widget.isOnline ? AppTheme.success : AppTheme.warning;

  Duration _durationFor(bool isAnalyzing) {
    return isAnalyzing
        ? const Duration(milliseconds: 520)
        : const Duration(milliseconds: 2200);
  }
}

class _CoreDot extends StatelessWidget {
  final Color color;
  final bool isOnline;

  const _CoreDot({required this.color, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: isOnline ? 12 : 8,
            spreadRadius: isOnline ? 3 : 2,
          ),
        ],
      ),
    );
  }
}
