import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/app_theme.dart';
import 'core/firebase_runtime_options.dart';
import 'core/firebase_service.dart';
import 'firebase_options.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Try Dart-define environment variables first (CI / production builds).
  // 2. Fall back to the generated DefaultFirebaseOptions (local dev).
  final firebaseOptions =
      FirebaseRuntimeOptions.currentPlatform ??
      DefaultFirebaseOptions.currentPlatform;

  await Firebase.initializeApp(options: firebaseOptions);
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
  static const _forceOnboarding = true; // Temporary screenshot mode
  bool? _hasSeenOnboarding;
  bool _prefsUnavailable = false;

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
        _hasSeenOnboarding = _forceOnboarding
            ? false
            : prefs.getBool(_onboardingKey) ?? false;
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

  @override
  Widget build(BuildContext context) {
    if (_hasSeenOnboarding == null) {
      return const _BootSplash();
    }

    return StreamBuilder(
      stream: FirebaseService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _BootSplash();
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        if (_hasSeenOnboarding == false) {
          return OnboardingScreen(onComplete: _completeOnboarding);
        }
        return const LoginScreen();
      },
    );
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
