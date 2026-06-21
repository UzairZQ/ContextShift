import 'package:flutter/material.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';

class MoodCheckIn extends StatelessWidget {
  static const List<String> _moods = ['😴', '😐', '🙂', '😊', '🔥'];

  final String? selectedMood;
  final ValueChanged<String> onSelect;

  const MoodCheckIn({
    super.key,
    required this.selectedMood,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Spacing.cardPadding,
      decoration: AppTheme.cardDecoration(color: AppTheme.surfaceContainer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedMood != null
                ? 'Feeling $selectedMood today'
                : 'How are you feeling?',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: Spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moods
                .map(
                  (mood) => _MoodButton(
                    emoji: mood,
                    isSelected: selectedMood == mood,
                    onTap: () => onSelect(mood),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  static const Map<String, String> _semanticLabels = {
    '😴': 'Mood: very low',
    '😐': 'Mood: low',
    '🙂': 'Mood: neutral',
    '😊': 'Mood: good',
    '🔥': 'Mood: great',
  };

  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabels[emoji] ?? 'Mood option',
      button: true,
      selected: isSelected,
      child: SizedBox(
        width: HitTarget.min,
        height: HitTarget.min,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: Motion.fast,
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(fontSize: isSelected ? 28 : 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
