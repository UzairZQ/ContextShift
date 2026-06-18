import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_theme.dart';
import 'core/database/database_service.dart';
import 'core/local_llm/gemma_service.dart';
import 'core/local_llm/model_tier.dart';
import 'features/onboarding/widgets/model_download_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Crashlytics only
  try {
    await Firebase.initializeApp();
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e, stack) {
    debugPrint('[main] Firebase init failed (non-fatal): $e');
    debugPrint('[main]   Stack: $stack');
  }

  // Initialize local database
  await DatabaseService.instance.init();

  // Initialize FlutterGemma (don't fail if not supported on this platform)
  try {
    await GemmaService.instance.init();
    debugPrint('[main] GemmaService initialized');
  } catch (e, stack) {
    debugPrint('[main] GemmaService init skipped (non-fatal): $e');
    debugPrint('[main]   Stack: $stack');
  }

  runApp(const ContextShiftApp());
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

class _LaunchGateState extends State<_LaunchGate> {
  static const _onboardingKey = 'has_seen_onboarding';
  static const _modelDownloadedKey = 'e2b_model_downloaded';
  bool? _hasSeenOnboarding;
  bool _prefsUnavailable = false;
  bool _modelDownloaded = false;

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;
        _modelDownloaded = prefs.getBool(_modelDownloadedKey) ?? false;
        _prefsUnavailable = false;
      });
    } on PlatformException catch (error) {
      debugPrint(
        'SharedPreferences unavailable, continuing without persistence: $error',
      );
      if (!mounted) return;
      setState(() {
        _hasSeenOnboarding = false;
        _prefsUnavailable = true;
        _modelDownloaded = false;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    if (_prefsUnavailable) {
      if (!mounted) return;
      setState(() => _hasSeenOnboarding = true);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } on PlatformException catch (error) {
      debugPrint('SharedPreferences save failed, continuing in-memory: $error');
      _prefsUnavailable = true;
    }

    if (!mounted) return;
    setState(() => _hasSeenOnboarding = true);
  }

  Future<void> _onModelDownloaded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_modelDownloadedKey, true);
    } catch (e) {
      debugPrint('[LaunchGate] Failed to save model downloaded flag: $e');
    }
    if (!mounted) return;
    setState(() => _modelDownloaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenOnboarding == null) {
      return const _BootSplash();
    }

    if (_hasSeenOnboarding == false) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    if (!_modelDownloaded && !_prefsUnavailable) {
      return ModelDownloadScreen(
        model: ModelDefinition.e2b,
        isOnboarding: true,
        onComplete: _onModelDownloaded,
        onSkip: _onModelDownloaded,
      );
    }

    return const HomeScreen();
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
