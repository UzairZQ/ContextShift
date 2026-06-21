import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../widgets/motion/wonderous_motion.dart';
import 'widgets/glow_orb.dart';

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const ProfileSetupScreen({super.key, required this.onComplete});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _focusRoleController = TextEditingController();

  static const List<String> _interestOptions = [
    'Productivity',
    'Wellness',
    'Learning',
    'Creativity',
    'Career',
    'Finance',
    'Relationships',
    'Mindfulness',
  ];

  final Set<String> _selectedInterests = {};
  TimeOfDay? _windDownTime;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _focusRoleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _windDownTime ?? const TimeOfDay(hour: 21, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.surfaceHigh,
            onSurface: AppTheme.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _windDownTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick at least one area where you want a hand'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final firstName = _firstNameController.text.trim();
    await DatabaseService.instance.saveUserProfile(
      firstName: firstName,
      lastName: _lastNameController.text.trim().isEmpty
          ? null
          : _lastNameController.text.trim(),
      name: '$firstName ${_lastNameController.text.trim()}'.trim(),
      focusRole: _focusRoleController.text.trim().isEmpty
          ? null
          : _focusRoleController.text.trim(),
      interests: _selectedInterests.toList(),
      windDownTime: _windDownTime?.format(context),
    );

    widget.onComplete();
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.background,
              AppTheme.surfaceLow,
              Color(0x1AFF8C96),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -92,
                right: -56,
                child: GlowOrb(
                  color: AppTheme.primary.withValues(alpha: 0.82),
                  size: 240,
                ),
              ),
              Positioned(
                bottom: 140,
                left: -86,
                child: GlowOrb(
                  color: AppTheme.tertiary.withValues(alpha: 0.58),
                  size: 210,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        WonderousReveal(
                          begin: const Offset(-0.04, 0),
                          child: IconButton(
                            icon: const Icon(
                              LucideIcons.arrowLeft,
                              color: AppTheme.onSurface,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        WonderousReveal(
                          delay: const Duration(milliseconds: 60),
                          child: Text(
                            'Make JARVIS useful\nto you',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.onSurface,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        WonderousReveal(
                          delay: const Duration(milliseconds: 120),
                          child: Text(
                            'A little context now means fewer generic suggestions later.',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        WonderousReveal(
                          delay: const Duration(milliseconds: 180),
                          begin: const Offset(0, 0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('What should we call you?'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _firstNameController,
                                style: const TextStyle(
                                  color: AppTheme.onSurface,
                                ),
                                cursorColor: AppTheme.primary,
                                textCapitalization: TextCapitalization.words,
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(
                                    RegExp(r'\d'),
                                  ),
                                ],
                                decoration: _inputDecoration('First name'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        WonderousReveal(
                          delay: const Duration(milliseconds: 240),
                          begin: const Offset(0, 0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('Last name, if you want'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _lastNameController,
                                style: const TextStyle(
                                  color: AppTheme.onSurface,
                                ),
                                cursorColor: AppTheme.primary,
                                textCapitalization: TextCapitalization.words,
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(
                                    RegExp(r'\d'),
                                  ),
                                ],
                                decoration: _inputDecoration('Last name'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        WonderousReveal(
                          delay: const Duration(milliseconds: 300),
                          begin: const Offset(0, 0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('What fills most of your days?'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _focusRoleController,
                                style: const TextStyle(
                                  color: AppTheme.onSurface,
                                ),
                                cursorColor: AppTheme.primary,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: _inputDecoration(
                                  'Student, designer, founder...',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        WonderousReveal(
                          delay: const Duration(milliseconds: 360),
                          begin: const Offset(0, 0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('Where could you use a hand?'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _interestOptions.map((interest) {
                                  final selected = _selectedInterests.contains(
                                    interest,
                                  );
                                  return _InterestChip(
                                    label: interest,
                                    selected: selected,
                                    onTap: () => _toggleInterest(interest),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        WonderousReveal(
                          delay: const Duration(milliseconds: 420),
                          begin: const Offset(0, 0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('When do you want to switch off?'),
                              const SizedBox(height: 8),
                              PressableScale(
                                onTap: _pickTime,
                                pressedScale: 0.98,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 260),
                                  curve: Curves.easeOutCubic,
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceHigh,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _windDownTime != null
                                          ? AppTheme.primary.withValues(
                                              alpha: 0.24,
                                            )
                                          : Colors.white.withValues(
                                              alpha: 0.04,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.moon,
                                        size: 20,
                                        color: _windDownTime != null
                                            ? AppTheme.primary
                                            : AppTheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _windDownTime != null
                                            ? _windDownTime!.format(context)
                                            : 'Choose a wind-down time',
                                        style: TextStyle(
                                          color: _windDownTime != null
                                              ? AppTheme.onSurface
                                              : AppTheme.onSurfaceVariant
                                                    .withValues(alpha: 0.5),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        WonderousReveal(
                          delay: const Duration(milliseconds: 480),
                          begin: const Offset(0, 0.05),
                          child: PressableScale(
                            onTap: _submit,
                            pressedScale: 0.965,
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.24,
                                    ),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Make it mine',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
      filled: true,
      fillColor: AppTheme.surfaceHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedScale(
        scale: selected ? 1.03 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.18)
                : AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppTheme.primary.withValues(alpha: 0.36)
                  : Colors.white.withValues(alpha: 0.04),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: selected ? 8 : 0,
                height: 8,
                margin: EdgeInsets.only(right: selected ? 8 : 0),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppTheme.primary
                      : AppTheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
