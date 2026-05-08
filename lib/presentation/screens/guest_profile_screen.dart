import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/app_theme.dart';
import '../../core/firebase_service.dart';
import '../../core/responsive.dart';

class GuestProfileScreen extends StatefulWidget {
  const GuestProfileScreen({super.key});

  @override
  State<GuestProfileScreen> createState() => _GuestProfileScreenState();
}

class _GuestProfileScreenState extends State<GuestProfileScreen> {
  final _nameController = TextEditingController();
  final _focusAreaController = TextEditingController();
  final _supportNeedController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _focusAreaController.dispose();
    _supportNeedController.dispose();
    super.dispose();
  }

  Future<void> _continueAsGuest() async {
    final name = _nameController.text.trim();
    final focusArea = _focusAreaController.text.trim();
    final supportNeed = _supportNeedController.text.trim();

    if (name.isEmpty || focusArea.isEmpty) {
      setState(() {
        _error = 'Please tell us your name and current focus area.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FirebaseService.instance.signInAsGuest(
        name: name,
        focusArea: focusArea,
        supportNeed: supportNeed,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Guest mode could not start right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, AppTheme.surfaceLow],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
            ),
            child: ResponsiveWrapper(
              maxWidth: 520,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        LucideIcons.arrowLeft,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Start in\nGuest Mode',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We will personalize the workspace without forcing an account first.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    _buildPanel(
                      context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_error != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.error.withValues(alpha: 0.24),
                                ),
                              ),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: AppTheme.error),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                          _buildLabel('Full Name'),
                          const SizedBox(height: 8),
                          _buildInput(
                            controller: _nameController,
                            hint: 'How should the app address you?',
                            icon: LucideIcons.user,
                          ),
                          const SizedBox(height: 18),
                          _buildLabel('Current Focus'),
                          const SizedBox(height: 8),
                          _buildInput(
                            controller: _focusAreaController,
                            hint: 'Work, studies, health, startup, routines...',
                            icon: LucideIcons.target,
                          ),
                          const SizedBox(height: 18),
                          _buildLabel('Where should JARVIS help most?'),
                          const SizedBox(height: 8),
                          _buildInput(
                            controller: _supportNeedController,
                            hint:
                                'Overwhelm, planning, remembering, consistency...',
                            icon: LucideIcons.sparkles,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _continueAsGuest,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Continue Without Account',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
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

  Widget _buildPanel(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(
        tint: AppTheme.surfaceHighest,
        opacity: 0.84,
        borderRadius: 28,
      ),
      child: child,
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.onSurface),
        decoration: InputDecoration(
          icon: Icon(icon, color: AppTheme.onSurfaceVariant, size: 18),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
