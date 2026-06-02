import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/firebase_service.dart';
import '../../../../core/responsive.dart';

class AddHabitSheet extends StatefulWidget {
  final TextEditingController nameController;

  const AddHabitSheet({super.key, required this.nameController});

  static const List<String> icons = [
    '🧘', '💪', '📚', '💧', '🏃', '🌙', '✍️', '🥗',
  ];

  static void show(
    BuildContext context, {
    required TextEditingController nameController,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddHabitSheet(nameController: nameController),
    );
  }

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  String _selectedIcon = AddHabitSheet.icons.first;

  Future<void> _submit() async {
    final name = widget.nameController.text.trim();
    if (name.isEmpty) return;
    widget.nameController.clear();
    await FirebaseService.instance.addHabit(
      name: name,
      icon: _selectedIcon,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: ResponsiveWrapper(
          maxWidth: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Habit',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AddHabitSheet.icons
                    .map(
                      (icon) => GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedIcon == icon
                                ? AppTheme.primary.withValues(alpha: 0.2)
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedIcon == icon
                                  ? AppTheme.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            icon,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: widget.nameController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Habit name (e.g. Morning Run)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add Habit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
