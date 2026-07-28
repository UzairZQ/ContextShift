import 'package:context_shift/core/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local task commands request duplicate protection', () async {
    final result = await AiService.instance.processCommand(
      command: 'add task review the release checklist',
      userName: 'Alex',
    );

    expect(result.actions, hasLength(1));
    expect(result.actions.single.type, 'add_task');
    expect(result.actions.single.params['dedupe_existing'], isTrue);
  });

  test('AI insight refreshes when user statistics change', () async {
    final overloaded = await AiService.instance.fetchInsight(
      userName: 'Alex',
      stats: const {
        'open_tasks': 5,
        'completed_tasks': 0,
        'total_habits': 0,
        'completed_habits_today': 0,
        'focus_minutes_today': 0,
      },
    );
    final focused = await AiService.instance.fetchInsight(
      userName: 'Alex',
      stats: const {
        'open_tasks': 0,
        'completed_tasks': 5,
        'total_habits': 0,
        'completed_habits_today': 0,
        'focus_minutes_today': 75,
      },
    );

    expect(overloaded, contains('5 open tasks'));
    expect(focused, contains('75 focused minutes'));
    expect(focused, isNot(overloaded));
  });
}
