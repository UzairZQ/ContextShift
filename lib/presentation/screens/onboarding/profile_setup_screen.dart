import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      color: AppTheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Make JARVIS useful\nto you',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A little context now means fewer generic suggestions later.',
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _Label('What should we call you?'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _firstNameController,
                    style: const TextStyle(color: AppTheme.onSurface),
                    cursorColor: AppTheme.primary,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\d')),
                    ],
                    decoration: _inputDecoration('First name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  _Label('Last name, if you want'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _lastNameController,
                    style: const TextStyle(color: AppTheme.onSurface),
                    cursorColor: AppTheme.primary,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\d')),
                    ],
                    decoration: _inputDecoration('Last name'),
                  ),
                  const SizedBox(height: 20),
                  _Label('What fills most of your days?'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _focusRoleController,
                    style: const TextStyle(color: AppTheme.onSurface),
                    cursorColor: AppTheme.primary,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration(
                      'Student, designer, founder...',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  _Label('Where could you use a hand?'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _interestOptions.map((interest) {
                      final selected = _selectedInterests.contains(interest);
                      return FilterChip(
                        label: Text(
                          interest,
                          style: TextStyle(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.onSurfaceVariant,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedInterests.add(interest);
                            } else {
                              _selectedInterests.remove(interest);
                            }
                          });
                        },
                        selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppTheme.primary,
                        backgroundColor: AppTheme.surfaceHigh,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _Label('When do you want to switch off?'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.moon,
                            size: 20,
                            color: AppTheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _windDownTime != null
                                ? _windDownTime!.format(context)
                                : 'Choose a wind-down time',
                            style: TextStyle(
                              color: _windDownTime != null
                                  ? AppTheme.onSurface
                                  : AppTheme.onSurfaceVariant.withValues(
                                      alpha: 0.5,
                                    ),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Make it mine',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
