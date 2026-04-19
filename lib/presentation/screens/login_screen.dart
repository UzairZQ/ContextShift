import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../core/firebase_service.dart';
import '../../core/responsive.dart';
import 'register_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.background,
        ),
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
                      'Sign in to your private sanctuary.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 48),
                    
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      ),

                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: LucideIcons.mail,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: LucideIcons.lock,
                      isPassword: true,
                    ),
                    
                    const SizedBox(height: 32),
                    _buildPrimaryButton(
                      onTap: _login,
                      label: 'Sign In',
                      isLoading: _isLoading,
                    ),
                    
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'OR',
                        style: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildGoogleButton(),
                    
                    const SizedBox(height: 48),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        ),
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: AppTheme.onSurfaceVariant),
                            children: const [
                              TextSpan(
                                text: 'Create One',
                                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: AppTheme.onSurface),
        decoration: InputDecoration(
          icon: Icon(icon, color: AppTheme.onSurfaceVariant, size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onTap,
    required String label,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryDim, AppTheme.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _loginWithGoogle,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.chrome, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
