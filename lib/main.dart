import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_runtime.dart';
import 'core/app_theme.dart';
import 'core/database/database_service.dart';
import 'core/local_llm/gemma_service.dart';
import 'core/services/feature_manager.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/onboarding/profile_setup_screen.dart';
import 'presentation/widgets/context_shift_wordmark.dart';

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('[Runtime] ContextShift build=$appRuntimeBuild');

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('[FlutterError] ${details.exceptionAsString()}');
        debugPrintStack(stackTrace: details.stack);
      };
      ErrorWidget.builder = (details) {
        debugPrint('[ErrorWidget] ${details.exceptionAsString()}');
        debugPrintStack(stackTrace: details.stack);
        return Material(
          color: AppTheme.background,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'ContextShift UI error:\n${details.exceptionAsString()}',
                style: const TextStyle(color: AppTheme.error, fontSize: 13),
              ),
            ),
          ),
        );
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('[UncaughtError] $error');
        debugPrintStack(stackTrace: stack);
        return true;
      };

      // Initialize local database
      await DatabaseService.instance.init();

      // Initialize FlutterGemma (don't fail if not supported on this platform)
      try {
        await GemmaService.instance.init();
        debugPrint('[main] GemmaService initialized');
      } catch (e, stack) {
        debugPrint('[main] GemmaService init skipped (non-fatal): $e');
        debugPrintStack(stackTrace: stack);
      }

      try {
        await FeatureManager.instance.initialize();
      } catch (e, stack) {
        debugPrint('[main] Feature state restore failed (non-fatal): $e');
        debugPrintStack(stackTrace: stack);
      }

      runApp(const ContextShiftApp());
    },
    (error, stack) {
      debugPrint('[ZoneError] $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

class ContextShiftApp extends StatelessWidget {
  const ContextShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ContextShift',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _LaunchGate(),
    );
  }
}

class _LaunchGate extends StatefulWidget {
  const _LaunchGate();

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

enum _SetupStep { loading, onboarding, profile, homeReveal, home }

class _LaunchGateState extends State<_LaunchGate> {
  static const _onboardingKey = 'has_seen_onboarding';
  static const _minimumSplash = Duration(milliseconds: 850);
  _SetupStep _step = _SetupStep.loading;
  bool _navigatedHome = false;

  @override
  void initState() {
    super.initState();
    _determineStep();
  }

  Future<void> _determineStep() async {
    final startedAt = DateTime.now();
    try {
      final hasSeenOnboarding =
          (await SharedPreferences.getInstance()).getBool(_onboardingKey) ??
          false;

      if (!hasSeenOnboarding) {
        await _holdSplash(startedAt);
        if (!mounted) return;
        setState(() => _step = _SetupStep.onboarding);
        return;
      }

      final needsProfile = !DatabaseService.instance.hasProfileData;
      await _holdSplash(startedAt);
      if (!mounted) return;
      if (!needsProfile) {
        _openHomeFromSplash();
        return;
      }
      setState(
        () => _step = needsProfile ? _SetupStep.profile : _SetupStep.home,
      );
    } on PlatformException catch (error, stackTrace) {
      debugPrint('[_LaunchGate] SharedPreferences read failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _holdSplash(startedAt);
      if (!mounted) return;
      setState(() => _step = _SetupStep.onboarding);
    } catch (error, stackTrace) {
      debugPrint('[_LaunchGate] Startup routing failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _holdSplash(startedAt);
      if (!mounted) return;
      setState(() => _step = _SetupStep.onboarding);
    }
  }

  Future<void> _holdSplash(DateTime startedAt) async {
    final elapsed = DateTime.now().difference(startedAt);
    final remaining = _minimumSplash - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } on PlatformException catch (error, stackTrace) {
      debugPrint('[_LaunchGate] SharedPreferences save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } catch (error, stackTrace) {
      debugPrint('[_LaunchGate] Onboarding completion failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!mounted) return;
    final needsProfile = !DatabaseService.instance.hasProfileData;
    if (needsProfile) {
      setState(() => _step = _SetupStep.profile);
    } else {
      _openHomeFromSplash();
    }
  }

  void _completeProfile() {
    _openHomeFromSplash();
  }

  void _openHomeFromSplash() {
    if (_navigatedHome || !mounted) return;
    _navigatedHome = true;
    setState(() => _step = _SetupStep.homeReveal);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_step) {
      _SetupStep.loading => const _BootSplash(),
      _SetupStep.onboarding => OnboardingScreen(
        onComplete: _completeOnboarding,
      ),
      _SetupStep.profile => ProfileSetupScreen(onComplete: _completeProfile),
      _SetupStep.homeReveal => const _HomeLaunchReveal(),
      _SetupStep.home => const HomeScreen(),
    };
  }
}

class _HomeLaunchReveal extends StatefulWidget {
  const _HomeLaunchReveal();

  @override
  State<_HomeLaunchReveal> createState() => _HomeLaunchRevealState();
}

class _HomeLaunchRevealState extends State<_HomeLaunchReveal>
    with SingleTickerProviderStateMixin {
  static const _homeSettleDelay = Duration(milliseconds: 40);
  static const _revealDuration = Duration(milliseconds: 520);

  late final AnimationController _controller;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _revealDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _finished = true);
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(_homeSettleDelay);
      if (!mounted) return;
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) return const HomeScreen();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Stack(
      children: [
        RepaintBoundary(
          child: AbsorbPointer(
            absorbing: !_finished,
            child: const HomeScreen(),
          ),
        ),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final fade = reduceMotion
                  ? 0.0
                  : 1 - Curves.easeOutCubic.transform(_controller.value);
              final lift = reduceMotion
                  ? 0.0
                  : Curves.easeOutCubic.transform(_controller.value);
              return Opacity(
                opacity: fade,
                child: DecoratedBox(
                  decoration: _launchBackdrop(alpha: fade),
                  child: Center(
                    child: Transform.translate(
                      offset: Offset(0, -10 * lift),
                      child: Transform.scale(
                        scale: 1 - (0.018 * lift),
                        child: _LaunchIdentity(progress: 1 - fade),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BootSplash extends StatefulWidget {
  const _BootSplash();

  @override
  State<_BootSplash> createState() => _BootSplashState();
}

class _BootSplashState extends State<_BootSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = reduceMotion
              ? 1.0
              : Curves.easeOutCubic.transform(_controller.value);
          return DecoratedBox(
            decoration: _launchBackdrop(),
            child: SafeArea(
              child: Center(
                child: Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - value)),
                    child: Transform.scale(
                      scale: 0.96 + (0.04 * value),
                      child: _LaunchIdentity(progress: value),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

BoxDecoration _launchBackdrop({double alpha = 1}) {
  return BoxDecoration(
    color: AppTheme.background,
    gradient: RadialGradient(
      center: const Alignment(0.1, -0.28),
      radius: 0.92,
      colors: [
        AppTheme.primary.withValues(alpha: 0.18 * alpha),
        AppTheme.surfaceLow.withValues(alpha: 0.88 * alpha),
        AppTheme.background,
      ],
      stops: const [0, 0.44, 1],
    ),
  );
}

class _LaunchIdentity extends StatelessWidget {
  final double progress;

  const _LaunchIdentity({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ContextShift is starting',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ReactorMark(size: 96),
          const SizedBox(height: 22),
          const ContextShiftWordmark(textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'YOUR PRIVATE AI WORKSPACE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.primary.withValues(alpha: 0.75),
              fontWeight: FontWeight.w800,
              letterSpacing: 3.2,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 26),
          const _LaunchShimmer(),
        ],
      ),
    );
  }
}

/// Animated arc-reactor style launch mark: rotating cyan arcs around a
/// breathing core, drawn with a single repaint-bounded CustomPaint.
class _ReactorMark extends StatefulWidget {
  final double size;

  const _ReactorMark({required this.size});

  @override
  State<_ReactorMark> createState() => _ReactorMarkState();
}

class _ReactorMarkState extends State<_ReactorMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduceMotion) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ReactorPainter(t: _controller.value),
            );
          },
        ),
      ),
    );
  }
}

class _ReactorPainter extends CustomPainter {
  final double t;

  const _ReactorPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final angle = t * 2 * math.pi;

    // Ambient glow
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.22),
            AppTheme.primary.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Tick ring
    final tickPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.16)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const tickCount = 48;
    for (var i = 0; i < tickCount; i++) {
      final a = (i / tickCount) * 2 * math.pi;
      final outer = center + Offset(math.cos(a), math.sin(a)) * (radius - 2);
      final inner = center + Offset(math.cos(a), math.sin(a)) * (radius - 6);
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Outer rotating arc
    final arcRect = Rect.fromCircle(center: center, radius: radius - 11);
    canvas.drawArc(
      arcRect,
      angle,
      math.pi * 0.62,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: angle,
          endAngle: angle + math.pi * 0.62,
          colors: [
            AppTheme.primary.withValues(alpha: 0.0),
            AppTheme.primary,
          ],
          transform: GradientRotation(angle),
        ).createShader(arcRect),
    );

    // Inner counter-rotating arc
    final innerRect = Rect.fromCircle(center: center, radius: radius - 20);
    final innerAngle = -angle * 1.4 + math.pi;
    canvas.drawArc(
      innerRect,
      innerAngle,
      math.pi * 0.4,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = AppTheme.tertiary.withValues(alpha: 0.55),
    );

    // Breathing core
    final breath = 0.5 + 0.5 * math.sin(angle * 2);
    final coreRadius = (radius * 0.24) + (radius * 0.03 * breath);
    canvas.drawCircle(
      center,
      coreRadius + 6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.5 + 0.2 * breath),
            AppTheme.primary.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: coreRadius + 6),
        ),
    );
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFEAFBFF), AppTheme.primary],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );
  }

  @override
  bool shouldRepaint(covariant _ReactorPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// Indeterminate shimmer line under the wordmark.
class _LaunchShimmer extends StatefulWidget {
  const _LaunchShimmer();

  @override
  State<_LaunchShimmer> createState() => _LaunchShimmerState();
}

class _LaunchShimmerState extends State<_LaunchShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduceMotion) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final x = (_controller.value * 2.4) - 1.2;
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.white.withValues(alpha: 0.08)),
                FractionallySizedBox(
                  alignment: Alignment(x.clamp(-1.0, 1.0), 0),
                  widthFactor: 0.42,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
