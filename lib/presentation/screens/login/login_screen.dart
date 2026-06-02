import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../../core/firebase_service.dart';
import '../../../core/responsive.dart';
import '../../shared/auth_text_field.dart';
import '../../shared/google_sign_in_button.dart';
import '../../shared/guest_button.dart';
import '../../shared/primary_button.dart';
import '../guest_profile/guest_profile_screen.dart';
import '../register/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await FirebaseService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    await FirebaseService.instance.signInWithGoogle();
    if (mounted) setState(() => _isLoading = false);
  }

  void _openGuestProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GuestProfileScreen()),
    );
  }

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppTheme.background),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
            ),
            child: ResponsiveWrapper(
              maxWidth: 450,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: Responsive.isMobile(context) ? 60 : 100),
                    Text(
                      'Welcome\nBack',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sign in for sync, or keep going as a guest and personalize the workspace first.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 48),
                    if (_error != null) _ErrorBanner(message: _error!),
                    AuthTextField(
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: LucideIcons.mail,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: LucideIcons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      onTap: _login,
                      label: 'Sign In',
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 24),
                    const _OrDivider(),
                    const SizedBox(height: 24),
                    GoogleSignInButton(
                      onTap: _loginWithGoogle,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                    GuestButton(onTap: _openGuestProfile),
                    const SizedBox(height: 48),
                    _RegisterLink(onTap: _openRegister),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'OR',
        style: TextStyle(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  final VoidCallback onTap;

  const _RegisterLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            text: "Don't have an account? ",
            style: TextStyle(color: AppTheme.onSurfaceVariant),
            children: const [
              TextSpan(
                text: 'Create One',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
