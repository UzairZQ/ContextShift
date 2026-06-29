import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_runtime.dart';
import 'core/app_spacing.dart';
import 'core/app_theme.dart';
import 'core/database/database_service.dart';
import 'core/local_llm/gemma_service.dart';
import 'core/responsive.dart';
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
  static const _minimumSplash = Duration(milliseconds: 950);
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
      if (!needsProfile) unawaited(_warmJarvisDuringSplash());
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

  Future<void> _warmJarvisDuringSplash() async {
    if (GemmaService.instance.isModelLoaded) return;
    if (!FeatureManager.instance.hasVerifiedModel) return;
    try {
      await GemmaService.instance.loadBestAvailableModel().timeout(
        const Duration(seconds: 45),
      );
    } catch (error, stackTrace) {
      debugPrint('[_LaunchGate] Splash JARVIS warmup skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
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
  static const _homeSettleDelay = Duration(milliseconds: 1200);
  static const _revealDuration = Duration(milliseconds: 1250);

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
    final media = MediaQuery.of(context);
    final size = media.size;
    final targetLeft = Responsive.horizontalPadding(context);
    final targetTop = media.padding.top + Spacing.xxl;
    final startLeft = (size.width - 260) / 2;
    final startTop = (size.height - 42) / 2;

    return Stack(
      children: [
        RepaintBoundary(
          child: AbsorbPointer(
            absorbing: !_finished,
            child: HomeScreen(hideWordmark: !_finished),
          ),
        ),
        if (!_finished)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final movement = Curves.easeInOutCubic.transform(
                  Interval(0.12, 0.92).transform(_controller.value),
                );
                final reveal = Curves.easeOutCubic.transform(
                  Interval(0.34, 0.96).transform(_controller.value),
                );
                final subtitle =
                    1 -
                    Curves.easeInCubic.transform(
                      Interval(0.12, 0.50).transform(_controller.value),
                    );

                return Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.2, -0.15),
                            radius: 0.9,
                            colors: [
                              AppTheme.primary.withValues(
                                alpha: 0.20 * (1 - reveal),
                              ),
                              AppTheme.surfaceLow.withValues(
                                alpha: 0.72 * (1 - reveal),
                              ),
                              AppTheme.background.withValues(alpha: 1 - reveal),
                            ],
                            stops: const [0, 0.42, 1],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: lerpDouble(startLeft, targetLeft, movement)!,
                      top: lerpDouble(startTop, targetTop, movement)!,
                      width: lerpDouble(260, 240, movement)!,
                      child: ContextShiftWordmark(
                        textAlign: movement < 0.58
                            ? TextAlign.center
                            : TextAlign.start,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: startTop + 58,
                      child: Opacity(
                        opacity: subtitle,
                        child: Text(
                          'Preparing your private context',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.2, -0.15),
            radius: 0.9,
            colors: [
              AppTheme.primary.withValues(alpha: 0.20),
              AppTheme.surfaceLow.withValues(alpha: 0.72),
              AppTheme.background,
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ContextShiftWordmark(textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    'Preparing your private context',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
