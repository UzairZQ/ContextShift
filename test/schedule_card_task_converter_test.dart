import 'package:context_shift/core/ai/schedule_card_task_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts schedule timeline rows into task actions', () {
    const rawA2ui = '''
```json
[
  {"version":"v0.9","createSurface":{"surfaceId":"schedule","catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json","sendDataModel":true}},
  {"version":"v0.9","updateComponents":{"surfaceId":"schedule","components":[
    {"id":"root","component":"Column","children":["timeline"]},
    {"id":"timeline","component":"Timeline","title":"Day plan","items":[
      {"time":"09:00","title":"Learn German","detail":"Review A2 vocabulary"},
      {"time":"Next","title":"Data mining","body":"Read clustering notes"}
    ]}
  ]}}
]
```
''';

    final actions = ScheduleCardTaskConverter.actionsFromA2ui(rawA2ui);

    expect(actions, hasLength(2));
    expect(actions.first.type, 'add_task');
    expect(actions.first.params['title'], 'Learn German');
    expect(actions.first.params['dedupe_existing'], isTrue);
    expect(actions.first.params['due'], '09:00');
    expect(actions.first.params['subtasks'], [
      {'title': 'Review A2 vocabulary', 'completed': false},
    ]);
    expect(actions.last.params['title'], 'Data mining');
    expect(actions.last.params.containsKey('due'), isFalse);
    expect(actions.last.params['subtasks'], [
      {'title': 'Read clustering notes', 'completed': false},
    ]);
  });

  test('returns no actions for malformed A2UI', () {
    final actions = ScheduleCardTaskConverter.actionsFromA2ui('not json');

    expect(actions, isEmpty);
  });
}
