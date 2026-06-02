import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/responsive.dart';

class TimerRing extends StatelessWidget {
  final double progress;
  final String timeDisplay;
  final String sessionLabel;
  final Animation<double> pulseAnimation;

  const TimerRing({
    super.key,
    required this.progress,
    required this.timeDisplay,
    required this.sessionLabel,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.7;
        final cappedSize = size.clamp(200.0, 320.0);

        return Center(
          child: ScaleTransition(
            scale: pulseAnimation,
            child: SizedBox(
              width: cappedSize,
              height: cappedSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: Responsive.isMobile(context) ? 8 : 12,
                      backgroundColor: AppTheme.surfaceHigh,
                      valueColor: const AlwaysStoppedAnimation(
                        AppTheme.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timeDisplay,
                        style: TextStyle(
                          fontSize: cappedSize * 0.25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        sessionLabel,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: cappedSize * 0.06,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
