import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/responsive.dart';

class AddHabitSheet extends StatefulWidget {
  final TextEditingController nameController;

  const AddHabitSheet({super.key, required this.nameController});

  static const List<String> icons = [
    '🧘',
    '💪',
    '📚',
    '💧',
    '🏃',
    '🌙',
    '✍️',
    '🥗',
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
  final _cueController = TextEditingController();
  final _tinyStepController = TextEditingController();
  final _rewardController = TextEditingController();
  final _frictionController = TextEditingController();
  String _selectedIcon = AddHabitSheet.icons.first;
  String _selectedKind = 'build';

  @override
  void dispose() {
    _cueController.dispose();
    _tinyStepController.dispose();
    _rewardController.dispose();
    _frictionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = widget.nameController.text.trim();
    if (name.isEmpty) return;
    widget.nameController.clear();
    await DatabaseService.instance.addHabitWithKind(
      name: name,
      icon: _selectedIcon,
      kind: _selectedKind,
      cue: _cueController.text,
      tinyStep: _tinyStepController.text,
      reward: _rewardController.text,
      friction: _frictionController.text,
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
                'Track a behavior',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                _selectedKind == 'build'
                    ? 'For things you want to do more often.'
                    : 'For things you want to avoid or reduce.',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.72),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              _KindSelector(
                selectedKind: _selectedKind,
                onChanged: (kind) => setState(() {
                  _selectedKind = kind;
                  if (kind == 'reduce' &&
                      _selectedIcon == AddHabitSheet.icons.first) {
                    _selectedIcon = '🛡️';
                  }
                }),
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
              _StrategyField(
                controller: _cueController,
                icon: LucideIcons.bell,
                label: _selectedKind == 'build' ? 'Cue' : 'Trigger to watch',
                hint: _selectedKind == 'build'
                    ? 'After coffee, after brushing teeth...'
                    : 'Stress, boredom, after meals...',
              ),
              const SizedBox(height: 10),
              _StrategyField(
                controller: _tinyStepController,
                icon: _selectedKind == 'build'
                    ? LucideIcons.footprints
                    : LucideIcons.repeat2,
                label: _selectedKind == 'build'
                    ? 'Tiny version'
                    : 'Replacement move',
                hint: _selectedKind == 'build'
                    ? '2 minutes, 1 page, 5 pushups...'
                    : 'Water, walk, gum, breathing...',
              ),
              const SizedBox(height: 10),
              _StrategyField(
                controller: _selectedKind == 'build'
                    ? _rewardController
                    : _frictionController,
                icon: _selectedKind == 'build'
                    ? LucideIcons.sparkles
                    : LucideIcons.lock,
                label: _selectedKind == 'build'
                    ? 'Immediate reward'
                    : 'Make it harder',
                hint: _selectedKind == 'build'
                    ? 'Check it off, music, small treat...'
                    : 'Move it away, delay 10 minutes...',
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
                  child: Text(
                    _selectedKind == 'build'
                        ? 'Add Build Habit'
                        : 'Add Reduce Habit',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrategyField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hint;

  const _StrategyField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppTheme.onSurface, fontSize: 13),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 17, color: AppTheme.primary),
        labelText: label,
        labelStyle: TextStyle(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.72),
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: AppTheme.onSurfaceVariant.withValues(alpha: 0.38),
          fontSize: 12,
        ),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _KindSelector extends StatelessWidget {
  final String selectedKind;
  final ValueChanged<String> onChanged;

  const _KindSelector({required this.selectedKind, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _KindButton(
            selected: selectedKind == 'build',
            icon: LucideIcons.plus,
            label: 'Build',
            onTap: () => onChanged('build'),
          ),
          _KindButton(
            selected: selectedKind == 'reduce',
            icon: LucideIcons.shieldCheck,
            label: 'Reduce',
            onTap: () => onChanged('reduce'),
          ),
        ],
      ),
    );
  }
}

class _KindButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _KindButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: selected
                ? Border.all(color: AppTheme.primary.withValues(alpha: 0.28))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppTheme.primary : AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppTheme.onSurface
                      : AppTheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
