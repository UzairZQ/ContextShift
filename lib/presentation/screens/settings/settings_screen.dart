import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/app_spacing.dart';
import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../../core/local_llm/gemma_service.dart';
import '../../../core/local_llm/model_tier.dart';
import '../../../core/responsive.dart';
import '../../../core/services/feature_manager.dart';
import '../../../features/onboarding/widgets/model_download_screen.dart';

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
    if (FeatureManager.instance.isE4bAvailable) {
      return 'E4B downloaded, activation pending';
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
                    Row(
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
                    const SizedBox(height: Spacing.xxl),
                    _sectionHeader('Profile'),
                    const SizedBox(height: Spacing.lg),
                    _GlassTextField(
                      controller: _nameController,
                      label: 'First name',
                      icon: LucideIcons.user,
                      error: _nameError,
                    ),
                    const SizedBox(height: Spacing.md),
                    _GlassTextField(
                      controller: _lastNameController,
                      label: 'Last name (optional)',
                      icon: LucideIcons.userPlus,
                    ),
                    const SizedBox(height: Spacing.md),
                    _GlassTextField(
                      controller: _focusRoleController,
                      label: 'Focus role',
                      icon: LucideIcons.target,
                      error: _focusRoleError,
                    ),
                    const SizedBox(height: Spacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: _GlassButton(label: 'Save', onTap: _saveProfile),
                    ),
                    const SizedBox(height: Spacing.section),
                    _sectionHeader('Model & AI'),
                    const SizedBox(height: Spacing.lg),
                    _SettingsTile(
                      icon: LucideIcons.downloadCloud,
                      title: 'Manage AI model',
                      subtitle: _modelStatusSubtitle(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ModelDownloadScreen(
                              model: ModelDefinition.e2b,
                              isOnboarding: false,
                              onComplete: () => Navigator.pop(context),
                            ),
                          ),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: FeatureManager.instance.isE4bAvailable
                          ? LucideIcons.crown
                          : LucideIcons.lock,
                      title: FeatureManager.instance.isE4bAvailable
                          ? 'E4B Premium'
                          : 'Unlock E4B Premium',
                      subtitle: FeatureManager.instance.isE4bAvailable
                          ? 'Full model access active'
                          : 'Faster, smarter AI model',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Coming soon'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: Spacing.section),
                    _sectionHeader('About'),
                    const SizedBox(height: Spacing.lg),
                    _SettingsTile(
                      icon: LucideIcons.info,
                      title: 'ContextShift',
                      subtitle: 'v1.0.0 — Fully offline AI',
                      onTap: null,
                    ),
                    _SettingsTile(
                      icon: LucideIcons.shield,
                      title: 'Privacy',
                      subtitle: 'All data stays on your device',
                      onTap: null,
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
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? error;

  const _GlassTextField({
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
          decoration: AppTheme.glassmorphism(
            tint: error != null
                ? AppTheme.error.withValues(alpha: 0.08)
                : AppTheme.surfaceHighest,
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
                    : AppTheme.onSurfaceVariant,
              ),
              hintText: label,
              hintStyle: TextStyle(
                color: error != null
                    ? AppTheme.error.withValues(alpha: 0.5)
                    : AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
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
                  color: AppTheme.surfaceBright,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: AppTheme.primary),
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

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GlassButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        decoration: AppTheme.glassmorphism(
          tint: AppTheme.primary,
          opacity: 0.2,
          borderRadius: 14,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
