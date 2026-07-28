import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_spacing.dart';
import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../widgets/motion/wonderous_motion.dart';
import '../../widgets/notes/notes_module.dart';
import '../../widgets/shared/module_cards.dart';
import '../home/widgets/mood_checkin.dart';

class JournalScreen extends StatelessWidget {
  final String? todayMood;
  final ValueChanged<String> onSelectMood;

  const JournalScreen({
    super.key,
    required this.todayMood,
    required this.onSelectMood,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          WonderousReveal(child: _JournalHeader(todayMood: todayMood)),
          const SizedBox(height: 16),
          WonderousReveal(
            delay: const Duration(milliseconds: 80),
            child: MoodCheckIn(selectedMood: todayMood, onSelect: onSelectMood),
          ),
          const SizedBox(height: 16),
          WonderousReveal(
            delay: const Duration(milliseconds: 140),
            child: const _RecentMoodStrip(),
          ),
          const SizedBox(height: 16),
          WonderousReveal(
            delay: const Duration(milliseconds: 180),
            child: _GuidedReflectionCard(todayMood: todayMood),
          ),
          const SizedBox(height: 8),
          WonderousReveal(
            delay: const Duration(milliseconds: 220),
            child: const NotesModule(),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 92),
        ],
      ),
    );
  }
}

class _JournalHeader extends StatelessWidget {
  final String? todayMood;

  const _JournalHeader({required this.todayMood});

  @override
  Widget build(BuildContext context) {
    return ModuleHeaderCard(
      title: 'Journal',
      subtitle: todayMood == null
          ? 'Log the day, save the useful pieces.'
          : 'Mood logged. Keep the thread of today.',
      icon: LucideIcons.bookOpen,
      accent: AppTheme.warning,
    );
  }
}

class _GuidedReflectionCard extends StatefulWidget {
  final String? todayMood;

  const _GuidedReflectionCard({required this.todayMood});

  @override
  State<_GuidedReflectionCard> createState() => _GuidedReflectionCardState();
}

class _GuidedReflectionCardState extends State<_GuidedReflectionCard> {
  final _whatController = TextEditingController();
  final _meaningController = TextEditingController();
  final _nextController = TextEditingController();
  String _lens = 'steady';
  bool _isSaving = false;

  @override
  void dispose() {
    _whatController.dispose();
    _meaningController.dispose();
    _nextController.dispose();
    super.dispose();
  }

  Future<void> _saveReflection() async {
    final what = _whatController.text.trim();
    final meaning = _meaningController.text.trim();
    final next = _nextController.text.trim();
    if (what.isEmpty && meaning.isEmpty && next.isEmpty) return;

    setState(() => _isSaving = true);
    final mood = widget.todayMood;
    final content = [
      if (mood != null) 'Mood: $mood',
      'Lens: $_lens',
      if (what.isNotEmpty) 'What happened: $what',
      if (meaning.isNotEmpty) 'What it means: $meaning',
      if (next.isNotEmpty) 'Next kind action: $next',
    ].join('\n');

    try {
      await DatabaseService.instance.addNote(
        content: content,
        tags: ['reflection', _lens, if (mood != null) 'mood'],
      );
      if (!mounted) return;
      _whatController.clear();
      _meaningController.clear();
      _nextController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reflection saved to Journal'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[JournalScreen] Reflection save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save reflection. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.lg),
      decoration: moduleCardDecoration(
        accent: AppTheme.warning,
        borderRadius: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.warning.withValues(alpha: 0.13),
                  border: Border.all(
                    color: AppTheme.warning.withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  LucideIcons.messageCircleQuestion,
                  color: AppTheme.warning,
                  size: 18,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guided reflection',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Turn the day into context JARVIS can remember locally.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Wrap(
            spacing: Spacing.sm,
            runSpacing: Spacing.sm,
            children: [
              _LensButton(
                label: 'Steady',
                value: 'steady',
                selected: _lens == 'steady',
                onTap: () => setState(() => _lens = 'steady'),
              ),
              _LensButton(
                label: 'Grateful',
                value: 'grateful',
                selected: _lens == 'grateful',
                onTap: () => setState(() => _lens = 'grateful'),
              ),
              _LensButton(
                label: 'Untangle',
                value: 'untangle',
                selected: _lens == 'untangle',
                onTap: () => setState(() => _lens = 'untangle'),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          _ReflectionField(
            controller: _whatController,
            label: 'What actually happened?',
            hint: _hintForLens(_lens, 0),
          ),
          const SizedBox(height: Spacing.sm),
          _ReflectionField(
            controller: _meaningController,
            label: 'What is the signal?',
            hint: _hintForLens(_lens, 1),
          ),
          const SizedBox(height: Spacing.sm),
          _ReflectionField(
            controller: _nextController,
            label: 'What is one kind next action?',
            hint: _hintForLens(_lens, 2),
          ),
          const SizedBox(height: Spacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveReflection,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.save, size: 16),
              label: Text(_isSaving ? 'Saving' : 'Save reflection'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.warning,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _hintForLens(String lens, int index) {
    final prompts = switch (lens) {
      'grateful' => const [
        'Name one moment worth keeping.',
        'Why did that matter to you?',
        'How can you make space for more of it?',
      ],
      'untangle' => const [
        'Write the situation without judging it.',
        'What feeling, need, or pattern is underneath?',
        'What would make the next hour lighter?',
      ],
      _ => const [
        'Capture the plain facts of the day.',
        'What should future-you understand about this?',
        'What is the smallest useful move now?',
      ],
    };
    return prompts[index];
  }
}

class _LensButton extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _LensButton({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label reflection lens',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.warning.withValues(alpha: 0.18)
                : AppTheme.surfaceContainer.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppTheme.warning.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? AppTheme.warning : AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReflectionField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _ReflectionField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 3,
        style: const TextStyle(color: AppTheme.onSurface, fontSize: 13.5),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppTheme.warning.withValues(alpha: 0.86),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppTheme.onSurfaceVariant.withValues(alpha: 0.42),
            fontSize: 12.5,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _RecentMoodStrip extends StatelessWidget {
  const _RecentMoodStrip();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService.instance.watchMoods(days: 7),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        final moods = snapshot.data ?? const <Map<String, dynamic>>[];
        if (moods.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Text(
                'Last check-ins',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              ...moods
                  .take(5)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        entry['mood'] as String? ?? '•',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
