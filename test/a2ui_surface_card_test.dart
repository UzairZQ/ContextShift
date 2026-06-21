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
}
