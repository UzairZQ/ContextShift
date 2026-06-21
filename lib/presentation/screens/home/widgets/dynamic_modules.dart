import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/app_spacing.dart';
import '../../../../core/app_theme.dart';
import '../../../widgets/focus/focus_module.dart';
import '../../../widgets/habits/habit_module.dart';
import '../../../widgets/notes/notes_module.dart';
import '../../../widgets/tasks/tasks_module.dart';
import '../../../widgets/generative_card_module.dart';

class DynamicModules extends StatelessWidget {
  final List<String> moduleOrder;
  final String layoutRefresher;
  final Map<String, dynamic>? generativeCardPayload;
  final VoidCallback? onGenerativeCardAction;
  final ValueChanged<String>? onSeeAll;

  const DynamicModules({
    super.key,
    required this.moduleOrder,
    required this.layoutRefresher,
    required this.generativeCardPayload,
    required this.onGenerativeCardAction,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutQuad,
      switchOutCurve: Curves.easeInQuad,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Column(
        key: ValueKey('${moduleOrder.join('-')}-$layoutRefresher'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: moduleOrder
            .map(
              (name) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildModule(name),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildModule(String name) {
    final Widget module;
    switch (name) {
      case 'GenerativeCardModule':
        if (generativeCardPayload != null) {
          module = GenerativeCardModule(
            cardData: generativeCardPayload!,
            onAction: onGenerativeCardAction,
          );
        } else {
          return const SizedBox.shrink();
        }
      case 'FocusTimerModule':
        module = const FocusTimerModule();
      case 'TasksModule':
        module = const TasksModule();
      case 'HabitModule':
        module = const HabitModule();
      case 'NotesModule':
        module = const NotesModule();
      default:
        return const SizedBox.shrink();
    }

    final seeAllCallback = onSeeAll != null ? () => onSeeAll!(name) : null;
    return _ModuleSection(module: module, onSeeAll: seeAllCallback);
  }
}

class _ModuleSection extends StatelessWidget {
  final Widget module;
  final VoidCallback? onSeeAll;

  const _ModuleSection({required this.module, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        module,
        if (onSeeAll != null)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: Spacing.xs),
              child: GestureDetector(
                onTap: onSeeAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See all',
                        style: TextStyle(
                          color: AppTheme.primary.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 12,
                        color: AppTheme.primary.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
