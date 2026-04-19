import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../core/firebase_service.dart';
import '../../core/responsive.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _focusController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  final _emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (name.isEmpty) {
      if (mounted) setState(() => _error = "Please enter your name.");
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      if (mounted) setState(() => _error = "Please enter a valid email address.");
      return;
    }
    if (password.length < 6) {
      if (mounted) setState(() => _error = "Password must be at least 6 characters.");
      return;
    }
    if (password != confirmPassword) {
      if (mounted) setState(() => _error = "Passwords do not match.");
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      await FirebaseService.instance.signUp(
        email: email,
        password: password,
        name: name,
      );
      
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
      debugPrint('Registration Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    const SizedBox(height: 20),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Join the\nSanctuary',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Build your personalized Life OS.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),
                    
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!, 
                                style: const TextStyle(color: Colors.redAccent, fontSize: 13)
                              ),
                            ),
                          ],
                        ),
                      ),

                    _buildTextField(
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: LucideIcons.user,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: LucideIcons.lock,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm Password',
                      icon: LucideIcons.shieldCheck,
                      isPassword: true,
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _focusController,
                      hint: 'Career Focus (e.g. Design)',
                      icon: LucideIcons.sparkles,
                    ),
                    
                    const SizedBox(height: 32),
                    _buildPrimaryButton(
                      onTap: _register,
                      label: 'Create Account',
                      isLoading: _isLoading,
                    ),
                    
                    const SizedBox(height: 48),
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
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
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
        obscureText: isPassword ? obscureText : false,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppTheme.onSurface),
        decoration: InputDecoration(
          icon: Icon(icon, color: AppTheme.onSurfaceVariant, size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(
                  obscureText ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: AppTheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
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
}
