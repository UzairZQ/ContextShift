import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_runtime.dart';
import 'core/app_spacing.dart';
import 'core/app_theme.dart';
import 'core/database/database_service.dart';
import 'core/local_llm/gemma_service.dart';
import 'core/services/feature_manager.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/onboarding/profile_setup_screen.dart';
import 'presentation/widgets/jarvis_hero.dart';

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

enum _SetupStep { loading, onboarding, profile, home }

class _LaunchGateState extends State<_LaunchGate> {
  static const _onboardingKey = 'has_seen_onboarding';
  static const _forceOnboardingForTesting = true;
  static const _minimumSplash = Duration(milliseconds: 950);
  _SetupStep _step = _SetupStep.loading;

  @override
  void initState() {
    super.initState();
    _determineStep();
  }

  Future<void> _determineStep() async {
    final startedAt = DateTime.now();
    try {
      final hasSeenOnboarding = _forceOnboardingForTesting
          ? false
          : (await SharedPreferences.getInstance()).getBool(_onboardingKey) ??
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
    setState(() {
      final needsProfile = !DatabaseService.instance.hasProfileData;
      _step = needsProfile ? _SetupStep.profile : _SetupStep.home;
    });
  }

  void _completeProfile() {
    setState(() => _step = _SetupStep.home);
  }

  @override
  Widget build(BuildContext context) {
    final child = switch (_step) {
      _SetupStep.loading => const _BootSplash(),
      _SetupStep.onboarding => OnboardingScreen(
        onComplete: _completeOnboarding,
      ),
      _SetupStep.profile => ProfileSetupScreen(onComplete: _completeProfile),
      _SetupStep.home => const HomeScreen(),
    };

    return AnimatedSwitcher(
      duration: Motion.smoothScreen,
      reverseDuration: Motion.smoothScreenReverse,
      switchInCurve: Motion.smoothEnter,
      switchOutCurve: Motion.smoothExit,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Motion.smoothEnter,
          reverseCurve: Motion.smoothExit,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.10, 0),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(_step), child: child),
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
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.94, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: JarvisHero.tag,
                    createRectTween: JarvisHero.createRectTween,
                    flightShuttleBuilder: JarvisHero.flightShuttleBuilder,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.xl,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceHighest.withValues(
                            alpha: 0.90,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.18),
                              blurRadius: 38,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.radio,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: Spacing.md),
                            Text(
                              'JARVIS',
                              style: TextStyle(
                                color: AppTheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Preparing your private context',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
