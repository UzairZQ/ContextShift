import 'package:context_shift/presentation/widgets/tasks/widgets/task_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders every task inside the parent scroll view', (
    tester,
  ) async {
    final tasks = List.generate(
      21,
      (index) => <String, dynamic>{
        'id': '$index',
        'title': 'Mission $index',
        'done': false,
        'priority': 'normal',
        'due': 'Today',
        'subtasks': const <dynamic>[],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TaskList(stream: Stream.value(tasks)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Mission 0'), findsOneWidget);
    expect(find.text('Mission 20'), findsOneWidget);
    expect(find.byType(Dismissible), findsNWidgets(21));
    await tester.scrollUntilVisible(
      find.text('Mission 20'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(tester.getTopLeft(find.text('Mission 20')).dy, greaterThan(0));
  });
}
