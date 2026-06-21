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
  _SetupStep _step = _SetupStep.loading;

  @override
  void initState() {
    super.initState();
    _determineStep();
  }

  Future<void> _determineStep() async {
    try {
      final hasSeenOnboarding = _forceOnboardingForTesting
          ? false
          : (await SharedPreferences.getInstance()).getBool(_onboardingKey) ??
                false;

      if (!hasSeenOnboarding) {
        if (!mounted) return;
        setState(() => _step = _SetupStep.onboarding);
        return;
      }

      final needsProfile = !DatabaseService.instance.hasProfileData;
      if (!mounted) return;
      setState(
        () => _step = needsProfile ? _SetupStep.profile : _SetupStep.home,
      );
    } on PlatformException catch (error, stackTrace) {
      debugPrint('[_LaunchGate] SharedPreferences read failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _step = _SetupStep.onboarding);
    } catch (error, stackTrace) {
      debugPrint('[_LaunchGate] Startup routing failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _step = _SetupStep.onboarding);
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
    switch (_step) {
      case _SetupStep.loading:
        return const _BootSplash();
      case _SetupStep.onboarding:
        return OnboardingScreen(onComplete: _completeOnboarding);
      case _SetupStep.profile:
        return ProfileSetupScreen(onComplete: _completeProfile);
      case _SetupStep.home:
        return const HomeScreen();
    }
  }
}

class _BootSplash extends StatelessWidget {
  const _BootSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
    );
  }
}
