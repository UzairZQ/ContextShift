import 'package:context_shift/core/genui/widget_node.dart';
import 'package:context_shift/presentation/widgets/genui/a2ui_surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('restores an official A2UI surface and dispatches its action', (
    tester,
  ) async {
    WidgetAction? receivedAction;
    const rawA2ui = '''
```json
[
  {"version":"v0.9","createSurface":{"surfaceId":"test","catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json","sendDataModel":true}},
  {"version":"v0.9","updateComponents":{"surfaceId":"test","components":[{"id":"root","component":"Button","child":"label","action":{"event":{"name":"create_task","context":{"title":"Ship ContextShift"}}}},{"id":"label","component":"Text","text":"Create task"}]}}
]
```
''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: A2uiSurfaceCard(
            rawA2ui: rawA2ui,
            onAction: (action) => receivedAction = action,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create task'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(receivedAction?.action, 'create_task');
    expect(receivedAction?.params['title'], 'Ship ContextShift');
  });

  testWidgets('can hide selected ActionDock actions while preserving others', (
    tester,
  ) async {
    WidgetAction? receivedAction;
    const rawA2ui = '''
```json
[
  {"version":"v0.9","createSurface":{"surfaceId":"home","catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json","sendDataModel":true}},
  {"version":"v0.9","updateComponents":{"surfaceId":"home","components":[
    {"id":"root","component":"Column","children":["actions"]},
    {"id":"actions","component":"ActionDock","tone":"primary","actions":[
      {"label":"Save card","event":"save_card","title":"Schedule"},
      {"label":"Add tasks","event":"add_schedule_to_tasks","title":"Schedule"},
      {"label":"Refine","event":"continue_conversation","message":"Refine this"}
    ]}
  ]}}
]
```
''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: A2uiSurfaceCard(
            rawA2ui: rawA2ui,
            hiddenActionNames: const {'save_card', 'continue_conversation'},
            onAction: (action) => receivedAction = action,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Save card'), findsNothing);
    expect(find.text('Refine'), findsNothing);
    expect(find.text('Add tasks'), findsOneWidget);

    await tester.tap(find.text('Add tasks'));
    await tester.pump();

    expect(receivedAction?.action, 'add_schedule_to_tasks');
    expect(receivedAction?.params['rawA2ui'], rawA2ui);
  });

  testWidgets('rebuilds the surface when an edited card changes its payload', (
    tester,
  ) async {
    const first = '''
```json
[
  {"version":"v0.9","createSurface":{"surfaceId":"edit","catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json","sendDataModel":true}},
  {"version":"v0.9","updateComponents":{"surfaceId":"edit","components":[{"id":"root","component":"Text","text":"9:00 AM"}]}}
]
```
''';
    const second = '''
```json
[
  {"version":"v0.9","createSurface":{"surfaceId":"edit","catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json","sendDataModel":true}},
  {"version":"v0.9","updateComponents":{"surfaceId":"edit","components":[{"id":"root","component":"Text","text":"10:30 AM"}]}}
]
```
''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: A2uiSurfaceCard(rawA2ui: first, onAction: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('9:00 AM'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: A2uiSurfaceCard(rawA2ui: second, onAction: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('9:00 AM'), findsNothing);
    expect(find.text('10:30 AM'), findsOneWidget);
  });
}
