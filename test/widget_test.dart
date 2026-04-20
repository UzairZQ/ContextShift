import 'package:context_shift/core/app_theme.dart';
import 'package:context_shift/presentation/widgets/generative_card_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Generative card renders AI content', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: GenerativeCardModule(
            cardData: {
              'title': 'Adaptive Plan',
              'type': 'planner',
              'description': 'A short plan generated from your Jarvis prompt.',
              'list_items': [
                {
                  'text': 'Pick the most important outcome',
                  'task_payload': {
                    'title': 'Define the main outcome for today',
                    'priority': 'high',
                  },
                },
                {
                  'text': 'Run one 25 minute sprint',
                  'task_payload': {
                    'title': 'Do one 25 minute sprint',
                    'priority': 'normal',
                  },
                },
              ],
              'action_label': 'Start Focus',
              'action_module': 'FocusTimerModule',
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Adaptive Plan'), findsOneWidget);
    expect(find.text('A short plan generated from your Jarvis prompt.'), findsOneWidget);
    expect(find.text('Pick the most important outcome'), findsOneWidget);
    expect(find.text('START FOCUS'), findsOneWidget);
  });
}
