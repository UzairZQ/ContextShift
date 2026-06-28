import 'package:context_shift/core/genui/widget_node.dart';
import 'package:context_shift/presentation/widgets/genui/a2ui_surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('A2UI surface renders generated Jarvis content', (tester) async {
    WidgetAction? receivedAction;
    const rawA2ui = '''
```json
[
  {"version":"v0.9","createSurface":{"surfaceId":"home","catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json","sendDataModel":true}},
  {"version":"v0.9","updateComponents":{"surfaceId":"home","components":[
    {"id":"root","component":"Column","children":["hero","steps","actions"]},
    {"id":"hero","component":"HeroPanel","eyebrow":"Plan","title":"Adaptive Plan","subtitle":"A short plan generated from your Jarvis prompt.","tone":"primary"},
    {"id":"steps","component":"Checklist","title":"Next steps","tone":"primary","items":[
      {"title":"Pick the most important outcome"},
      {"title":"Run one 25 minute sprint"}
    ]},
    {"id":"actions","component":"ActionDock","tone":"primary","actions":[
      {"label":"Start Focus","event":"start_focus","title":"Focus sprint"}
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
            onAction: (action) => receivedAction = action,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Adaptive Plan'), findsOneWidget);
    expect(
      find.text('A short plan generated from your Jarvis prompt.'),
      findsOneWidget,
    );
    expect(find.text('Pick the most important outcome'), findsOneWidget);
    expect(find.text('Start Focus'), findsOneWidget);

    await tester.tap(find.text('Start Focus'));
    await tester.pump();

    expect(receivedAction?.action, 'start_focus');
  });
}
