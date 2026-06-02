import 'package:flutter/material.dart';

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

  const DynamicModules({
    super.key,
    required this.moduleOrder,
    required this.layoutRefresher,
    required this.generativeCardPayload,
    required this.onGenerativeCardAction,
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
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildModule(name),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildModule(String name) {
    switch (name) {
      case 'GenerativeCardModule':
        if (generativeCardPayload != null) {
          return GenerativeCardModule(
            cardData: generativeCardPayload!,
            onAction: onGenerativeCardAction,
          );
        }
        return const SizedBox.shrink();
      case 'FocusTimerModule':
        return const FocusTimerModule();
      case 'TasksModule':
        return const TasksModule();
      case 'HabitModule':
        return const HabitModule();
      case 'NotesModule':
        return const NotesModule();
      default:
        return const SizedBox.shrink();
    }
  }
}
