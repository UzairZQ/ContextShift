import 'package:context_shift/core/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('explicit task command parses without the model', () async {
    final result = await AiService.instance.processCommand(
      command: 'add task buy milk asap',
      userName: 'Alex',
    );
    expect(result.actions, hasLength(1));
    expect(result.actions.first.type, 'add_task');
    expect(result.actions.first.params['title'], 'buy milk asap');
    expect(result.actions.first.params['priority'], 'high');
  });

  test('remind me phrasing becomes a task', () async {
    final result = await AiService.instance.processCommand(
      command: 'Remind me to call the dentist',
      userName: 'Alex',
    );
    expect(result.actions.first.type, 'add_task');
    expect(result.actions.first.params['title'], 'call the dentist');
  });

  test('focus command with duration starts a session', () async {
    final result = await AiService.instance.processCommand(
      command: 'focus 45 min',
      userName: 'Alex',
    );
    expect(result.actions.first.type, 'start_focus');
    expect(result.actions.first.params['duration_minutes'], 45);
  });

  test('note command saves content', () async {
    final result = await AiService.instance.processCommand(
      command: 'jot down ship the beta on Friday',
      userName: 'Alex',
    );
    expect(result.actions.first.type, 'add_note');
    expect(result.actions.first.params['content'], 'ship the beta on Friday');
  });
}
