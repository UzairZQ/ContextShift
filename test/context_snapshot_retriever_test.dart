import 'package:context_shift/core/ai/context_snapshot_retriever.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final snapshot = <String, Object?>{
    'profile': {'name': 'Uzair'},
    'tasks': {
      'open_count': 2,
      'completed_count': 4,
      'high_priority_open': [
        {'title': 'Finish Career OS dashboard', 'priority': 'high'},
      ],
      'recent_open': [
        {'title': 'Review data mining lecture', 'priority': 'medium'},
        {'title': 'Finish Career OS dashboard', 'priority': 'high'},
      ],
    },
    'habits': {
      'total': 2,
      'open_today': ['Reduce nicotine', 'German vocabulary'],
      'items': [
        {'name': 'Reduce nicotine', 'kind': 'reduce'},
        {'name': 'German vocabulary', 'kind': 'build'},
      ],
    },
    'recent_note': 'Nicotine is strongest after lunch.',
    'recent_notes': [
      {'content': 'Nicotine is strongest after lunch.'},
      {'content': 'Career OS needs a cleaner navigation model.'},
    ],
    'today_mood': 'focused',
    'focus_minutes_today': 18,
    'recent_commands': const [],
    'recent_events': const [],
  };

  test('finds a habit by content without requiring a habit command phrase', () {
    final selected = ContextSnapshotRetriever.select(
      snapshot: snapshot,
      query: 'How is nicotine going?',
      mode: 'chat',
    );

    expect(selected['habits'], isNotNull);
    expect(selected['tasks'], isNull);
  });

  test('ranks the matching task ahead of other bounded task candidates', () {
    final selected = ContextSnapshotRetriever.select(
      snapshot: snapshot,
      query: 'What should I do for data mining?',
      mode: 'chat',
    );
    final tasks = selected['tasks']! as Map<String, Object?>;
    final relevant = tasks['relevant_open']! as List<Object?>;

    expect((relevant.first as Map)['title'], 'Review data mining lecture');
    expect(tasks['completed_count'], 4);
  });

  test('supports German domain and overview terms', () {
    final selected = ContextSnapshotRetriever.select(
      snapshot: snapshot,
      query: 'Gib mir einen Überblick über meine Gewohnheiten heute',
      mode: 'generate',
    );

    expect(ContextSnapshotRetriever.tokenize('Überblick Gewohnheiten'), [
      'überblick',
      'gewohnheiten',
    ]);
    expect(selected.keys, containsAll(['tasks', 'habits', 'recent_notes']));
    expect(selected['focus_minutes_today'], 18);
  });
}
