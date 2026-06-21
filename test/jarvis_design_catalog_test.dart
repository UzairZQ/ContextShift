import 'package:context_shift/core/genui/jarvis_design_catalog.dart';
import 'package:context_shift/core/genui/widget_node.dart';
import 'package:context_shift/presentation/widgets/genui/a2ui_surface_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  test('extends the basic GenUI catalog with Jarvis design components', () {
    final catalog = JarvisDesignCatalog.extend(
      BasicCatalogItems.asNoAssetCatalog(),
    );
    final names = catalog.items.map((item) => item.name).toSet();

    expect(names, containsAll(['HeroPanel', 'WorkoutBlock', 'Timeline']));
    expect(names, containsAll(['Checklist', 'MetricTile', 'ActionDock']));
  });

  testWidgets('renders custom Jarvis design components from A2UI', (
    tester,
  ) async {
    WidgetAction? receivedAction;
    const rawA2ui = '''
```json
[
  {"version":"v0.9","createSurface":{"surfaceId":"jarvis","catalogId":"https://a2ui.org/specification/v0_9/basic_catalog.json","sendDataModel":true}},
  {"version":"v0.9","updateComponents":{"surfaceId":"jarvis","components":[
    {"id":"root","component":"Column","children":["hero","workout","actions"]},
    {"id":"hero","component":"HeroPanel","eyebrow":"Workout","title":"Tomorrow Full Body","subtitle":"A balanced strength plan with warmup, main lifts, and cooldown.","tone":"accent"},
    {"id":"workout","component":"WorkoutBlock","title":"Main Strength","focus":"Full body · moderate intensity","tone":"accent","exercises":[
      {"name":"Goblet squat","sets":"3 sets","reps":"10 reps","rest":"75 sec","cue":"Keep chest tall"},
      {"name":"Push-up","sets":"3 sets","reps":"8-12 reps","rest":"60 sec","cue":"Stop two reps before failure"}
    ]},
    {"id":"actions","component":"ActionDock","tone":"accent","actions":[
      {"label":"Save workout","event":"create_task","title":"Tomorrow full body workout"}
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

    expect(find.text('Tomorrow Full Body'), findsOneWidget);
    expect(find.text('Goblet squat'), findsOneWidget);
    expect(find.text('Save workout'), findsOneWidget);

    await tester.tap(find.text('Save workout'));
    await tester.pump();

    expect(receivedAction?.action, 'create_task');
    expect(receivedAction?.params['title'], 'Tomorrow full body workout');
  });
}
