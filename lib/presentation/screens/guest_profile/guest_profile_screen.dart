import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../../core/firebase_service.dart';
import '../../../core/responsive.dart';
import 'widgets/profile_form_panel.dart';

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
      if (mounted) setState(() => _isLoading = false);
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
                    ProfileFormPanel(
                      nameController: _nameController,
                      focusAreaController: _focusAreaController,
                      supportNeedController: _supportNeedController,
                      isLoading: _isLoading,
                      error: _error,
                      onSubmit: _continueAsGuest,
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
}
