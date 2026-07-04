import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_routes.dart';
import '../../../core/app_spacing.dart';
import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../../core/local_llm/gemma_service.dart';
import '../../../core/local_llm/model_tier.dart';
import '../../../core/responsive.dart';
import '../../../core/services/feature_manager.dart';
import '../../../features/onboarding/widgets/model_download_screen.dart';
import '../../shared/context_shift_primitives.dart';
import '../../widgets/motion/wonderous_motion.dart';
import 'about_context_shift_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _focusRoleController = TextEditingController();
  String? _nameError;
  String? _focusRoleError;

  @override
  void initState() {
    super.initState();
    _nameController.text = DatabaseService.instance.firstName;
    _lastNameController.text = DatabaseService.instance.lastName ?? '';
    _focusRoleController.text = DatabaseService.instance.focusRole ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _focusRoleController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'First name is required');
      return;
    }
    setState(() {
      _nameError = null;
      _focusRoleError = null;
    });

    await DatabaseService.instance.saveUserProfile(
      firstName: name,
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      focusRole: _focusRoleController.text.trim().isEmpty
          ? null
          : _focusRoleController.text.trim(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _modelStatusSubtitle() {
    if (GemmaService.instance.isModelLoaded) {
      final active = GemmaService.instance.activeModelDef?.displayName;
      return active == null ? 'JARVIS model active' : '$active model active';
    }
    if (FeatureManager.instance.isE2bAvailable) {
      return 'E2B downloaded, activation pending';
    }
    return 'No model downloaded';
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
                padding: const EdgeInsets.only(top: Spacing.sm, bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WonderousReveal(
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              LucideIcons.arrowLeft,
                              color: AppTheme.onSurface,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            'Settings',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.xxl),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 80),
                      child: _sectionHeader('Identity'),
                    ),
                    const SizedBox(height: Spacing.lg),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 120),
                      child: _ContextTextField(
                        controller: _nameController,
                        label: 'First name',
                        icon: LucideIcons.user,
                        error: _nameError,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 160),
                      child: _ContextTextField(
                        controller: _lastNameController,
                        label: 'Last name (optional)',
                        icon: LucideIcons.userPlus,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 200),
                      child: _ContextTextField(
                        controller: _focusRoleController,
                        label: 'Focus role',
                        icon: LucideIcons.target,
                        error: _focusRoleError,
                      ),
                    ),
                    const SizedBox(height: Spacing.xl),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 240),
                      child: SizedBox(
                        width: double.infinity,
                        child: _ContextButton(
                          label: 'Save identity',
                          onTap: _saveProfile,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.section),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 280),
                      child: _sectionHeader('Local intelligence'),
                    ),
                    const SizedBox(height: Spacing.lg),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 320),
                      child: _SettingsTile(
                        icon: LucideIcons.downloadCloud,
                        title: 'Manage AI model',
                        subtitle: _modelStatusSubtitle(),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            SmoothPageRoute(
                              builder: (_) => ModelDownloadScreen(
                                model: ModelDefinition.e2b,
                                isOnboarding: false,
                                onComplete: () => Navigator.pop(context),
                              ),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: Spacing.section),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 360),
                      child: _sectionHeader('About'),
                    ),
                    const SizedBox(height: Spacing.lg),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 400),
                      child: _SettingsTile(
                        icon: LucideIcons.info,
                        title: 'ContextShift',
                        subtitle: 'What this workspace can do',
                        onTap: () => Navigator.push(
                          context,
                          SmoothPageRoute(
                            builder: (_) => const AboutContextShiftScreen(),
                          ),
                        ),
                      ),
                    ),
                    WonderousReveal(
                      delay: const Duration(milliseconds: 440),
                      child: _SettingsTile(
                        icon: LucideIcons.shield,
                        title: 'Privacy',
                        subtitle: 'Local data and diagnostics',
                        onTap: () => Navigator.push(
                          context,
                          SmoothPageRoute(
                            builder: (_) => const PrivacyScreen(),
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

  Widget _sectionHeader(String title) {
    return ContextSectionLabel(text: title, icon: LucideIcons.scanLine);
  }
}

class _ContextTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? error;

  const _ContextTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: 2),
          decoration: AppTheme.contextPanel(
            color: error != null
                ? AppTheme.error.withValues(alpha: 0.08)
                : AppTheme.surfaceContainer,
            accent: error != null ? AppTheme.error : null,
            borderRadius: 14,
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: error != null ? AppTheme.error : AppTheme.onSurface,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              icon: Icon(
                icon,
                size: 18,
                color: error != null
                    ? AppTheme.error
                    : AppTheme.intelligence.withValues(alpha: 0.78),
              ),
              hintText: label,
              hintStyle: TextStyle(
                color: error != null
                    ? AppTheme.error.withValues(alpha: 0.5)
                    : AppTheme.onSurfaceVariant.withValues(alpha: 0.58),
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: Spacing.md),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: Spacing.sm, top: Spacing.xs),
            child: Text(
              error!,
              style: const TextStyle(color: AppTheme.error, fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          decoration: AppTheme.cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.intelligence.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: AppTheme.intelligence),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ContextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        decoration: AppTheme.contextPanel(
          color: AppTheme.primary.withValues(alpha: 0.13),
          accent: AppTheme.primary,
          borderRadius: 14,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
