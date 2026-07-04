import 'dart:async';
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
  static const _minimumSplash = Duration(milliseconds: 320);
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
          const _LaunchMark(),
          const SizedBox(height: 18),
          const ContextShiftWordmark(textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'Private AI workspace',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.78),
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 20),
          _LaunchProgress(value: progress.clamp(0, 1).toDouble()),
        ],
      ),
    );
  }
}

class _LaunchMark extends StatelessWidget {
  const _LaunchMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceHighest, AppTheme.surfaceContainer],
        ),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppTheme.primary.withValues(alpha: 0.94),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.onSurface.withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            top: 13,
            right: 13,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaunchProgress extends StatelessWidget {
  final double value;

  const _LaunchProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Colors.white.withValues(alpha: 0.08)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
