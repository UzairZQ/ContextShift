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
      duration: const Duration(seconds: 2),
    );
    if (widget.isAnalyzing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AiPulsar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnalyzing != oldWidget.isAnalyzing) {
      _controller.duration = widget.isAnalyzing
          ? const Duration(milliseconds: 500)
          : const Duration(seconds: 2);
      if (widget.isAnalyzing) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAnalyzing) {
      return Center(child: _CoreDot(isOnline: widget.isOnline));
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 12 + (16 * _controller.value),
                height: 12 + (16 * _controller.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (widget.isOnline ? AppTheme.success : AppTheme.primary)
                      .withValues(alpha: 0.7 * (1 - _controller.value)),
                ),
              ),
              _CoreDot(isOnline: widget.isOnline),
            ],
          ),
        );
      },
    );
  }
}

class _CoreDot extends StatelessWidget {
  final bool isOnline;

  const _CoreDot({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppTheme.success : AppTheme.primary;
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 8, spreadRadius: 2)],
      ),
    );
  }
}
