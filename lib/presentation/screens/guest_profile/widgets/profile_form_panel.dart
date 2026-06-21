import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_theme.dart';

class ProfileFormPanel extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController focusAreaController;
  final TextEditingController supportNeedController;
  final bool isLoading;
  final String? error;
  final VoidCallback onSubmit;

  const ProfileFormPanel({
    super.key,
    required this.nameController,
    required this.focusAreaController,
    required this.supportNeedController,
    required this.isLoading,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassmorphism(
        tint: AppTheme.surfaceHighest,
        opacity: 0.84,
        borderRadius: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null) ...[
            _ErrorBanner(message: error!),
            const SizedBox(height: 18),
          ],
          const _Label(text: 'Full Name'),
          const SizedBox(height: 8),
          _FormInput(
            controller: nameController,
            hint: 'How should the app address you?',
            icon: LucideIcons.user,
          ),
          const SizedBox(height: 18),
          const _Label(text: 'Current Focus'),
          const SizedBox(height: 8),
          _FormInput(
            controller: focusAreaController,
            hint: 'Work, studies, health, startup, routines...',
            icon: LucideIcons.target,
          ),
          const SizedBox(height: 18),
          const _Label(text: 'Where should JARVIS help most?'),
          const SizedBox(height: 8),
          _FormInput(
            controller: supportNeedController,
            hint: 'Overwhelm, planning, remembering, consistency...',
            icon: LucideIcons.sparkles,
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isLoading
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
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}

class _FormInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _FormInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
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

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.24)),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.error)),
    );
  }
}
