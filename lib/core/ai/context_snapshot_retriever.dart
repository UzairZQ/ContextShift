import 'dart:convert';
import 'dart:math' as math;

/// Ranks the already bounded local snapshot for one prompt.
///
/// This is lightweight lexical retrieval, not an embedding model. It helps
/// JARVIS find a habit, note, or task by its actual content even when the user
/// does not use a predefined command phrase.
class ContextSnapshotRetriever {
  ContextSnapshotRetriever._();

  static const Set<String> _stopwords = {
    'a',
    'about',
    'an',
    'and',
    'are',
    'as',
    'at',
    'be',
    'can',
    'could',
    'do',
    'for',
    'from',
    'get',
    'has',
    'have',
    'how',
    'i',
    'in',
    'is',
    'it',
    'jarvis',
    'just',
    'me',
    'my',
    'of',
    'on',
    'or',
    'please',
    'should',
    'that',
    'the',
    'this',
    'to',
    'was',
    'what',
    'when',
    'with',
    'would',
    'you',
    'your',
    'aber',
    'als',
    'auf',
    'aus',
    'bei',
    'bin',
    'das',
    'der',
    'die',
    'ein',
    'eine',
    'für',
    'habe',
    'ich',
    'im',
    'ist',
    'kann',
    'mein',
    'meine',
    'mit',
    'oder',
    'und',
    'von',
    'wie',
    'zu',
  };

  static const Set<String> _overviewTerms = {
    'all',
    'day',
    'dashboard',
    'everything',
    'heute',
    'morgen',
    'overview',
    'plan',
    'report',
    'schedule',
    'stats',
    'summary',
    'today',
    'tomorrow',
    'week',
    'woche',
    'überblick',
  };
  static const Set<String> _taskTerms = {
    'aufgabe',
    'aufgaben',
    'deadline',
    'due',
    'mission',
    'missions',
    'priority',
    'project',
    'task',
    'tasks',
    'todo',
  };
  static const Set<String> _habitTerms = {
    'daily',
    'habit',
    'habits',
    'routine',
    'streak',
    'gewohnheit',
    'gewohnheiten',
  };
  static const Set<String> _noteTerms = {
    'feel',
    'feeling',
    'gedanke',
    'journal',
    'mood',
    'note',
    'notes',
    'reflect',
    'stimmung',
    'thought',
    'wrote',
  };
  static const Set<String> _focusTerms = {
    'deep',
    'focus',
    'fokus',
    'lernen',
    'pomodoro',
    'session',
    'study',
    'training',
    'workout',
  };

  static List<String> tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9äöüßà-öø-ÿ]+'))
        .where((term) => term.length >= 2 && !_stopwords.contains(term))
        .toList(growable: false);
  }

  static Map<String, Object?> select({
    required Map<String, Object?> snapshot,
    required String query,
    String topic = '',
    required String mode,
  }) {
    final terms = tokenize('$query $topic').toSet();
    final includeEverything =
        query.trim().isEmpty ||
        (mode == 'generate' && _intersects(terms, _overviewTerms)) ||
        _intersects(terms, {'overview', 'everything', 'überblick'});
    final selected = <String, Object?>{'profile': snapshot['profile']};

    final tasks = _asMap(snapshot['tasks']);
    final taskItems = _uniqueMaps([
      ..._asMapList(tasks['high_priority_open']),
      ..._asMapList(tasks['recent_open']),
    ]);
    final rankedTasks = _rank(taskItems, terms, limit: 6);
    if (includeEverything ||
        _intersects(terms, _taskTerms) ||
        rankedTasks.hasLexicalMatch) {
      selected['tasks'] = <String, Object?>{
        'open_count': tasks['open_count'],
        'completed_count': tasks['completed_count'],
        'relevant_open': rankedTasks.items,
      };
    }

    final habits = _asMap(snapshot['habits']);
    final rankedHabits = _rank(_asMapList(habits['items']), terms, limit: 6);
    if (includeEverything ||
        _intersects(terms, _habitTerms) ||
        rankedHabits.hasLexicalMatch) {
      selected['habits'] = <String, Object?>{
        'total': habits['total'],
        'open_today': habits['open_today'],
        'relevant': rankedHabits.items,
      };
    }

    final rankedNotes = _rank(
      _asMapList(snapshot['recent_notes']),
      terms,
      limit: 4,
    );
    final wantsNotes =
        includeEverything ||
        _intersects(terms, _noteTerms) ||
        rankedNotes.hasLexicalMatch;
    if (wantsNotes) {
      selected['recent_notes'] = rankedNotes.items;
      selected['recent_note'] = snapshot['recent_note'];
      selected['today_mood'] = snapshot['today_mood'];
    }

    if (includeEverything || _intersects(terms, _focusTerms)) {
      selected['focus_minutes_today'] = snapshot['focus_minutes_today'];
    }
    if (includeEverything) {
      selected['recent_commands'] = snapshot['recent_commands'];
      selected['recent_events'] = snapshot['recent_events'];
    }
    return selected;
  }

  static _RankedMaps _rank(
    List<Map<String, Object?>> items,
    Set<String> queryTerms, {
    required int limit,
  }) {
    if (items.isEmpty) return const _RankedMaps([], false);
    final scored = <_ScoredMap>[];
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final itemTerms = tokenize(jsonEncode(item));
      final lexicalScore = _lexicalScore(queryTerms, itemTerms);
      final recencyBias = (items.length - index) / items.length * 0.1;
      scored.add(
        _ScoredMap(item, lexicalScore + recencyBias, lexicalScore > 0),
      );
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    final matches = scored.where((item) => item.lexicalMatch).toList();
    final ordered = matches.isEmpty
        ? scored
        : [...matches, ...scored.where((item) => !item.lexicalMatch)];
    return _RankedMaps(
      ordered.take(limit).map((item) => item.value).toList(growable: false),
      matches.isNotEmpty,
    );
  }

  static double _lexicalScore(
    Set<String> queryTerms,
    List<String> documentTerms,
  ) {
    if (queryTerms.isEmpty || documentTerms.isEmpty) return 0;
    var hits = 0.0;
    for (final documentTerm in documentTerms.toSet()) {
      for (final queryTerm in queryTerms) {
        if (documentTerm == queryTerm) {
          hits += 1;
          break;
        }
        if (documentTerm.length >= 4 &&
            queryTerm.length >= 4 &&
            (documentTerm.startsWith(queryTerm) ||
                queryTerm.startsWith(documentTerm))) {
          hits += 0.65;
          break;
        }
      }
    }
    return hits / math.sqrt(documentTerms.length);
  }

  static bool _intersects(Set<String> terms, Set<String> candidates) {
    return terms.any(candidates.contains);
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is! Map) return const <String, Object?>{};
    return value.map<String, Object?>(
      (key, mapValue) => MapEntry(key.toString(), mapValue),
    );
  }

  static List<Map<String, Object?>> _asMapList(Object? value) {
    if (value is! Iterable) return const <Map<String, Object?>>[];
    return value
        .whereType<Map>()
        .map(
          (item) => item.map<String, Object?>(
            (key, mapValue) => MapEntry(key.toString(), mapValue),
          ),
        )
        .toList(growable: false);
  }

  static List<Map<String, Object?>> _uniqueMaps(
    List<Map<String, Object?>> values,
  ) {
    final seen = <String>{};
    return values
        .where((value) => seen.add(jsonEncode(value)))
        .toList(growable: false);
  }
}

class _RankedMaps {
  const _RankedMaps(this.items, this.hasLexicalMatch);

  final List<Map<String, Object?>> items;
  final bool hasLexicalMatch;
}

class _ScoredMap {
  const _ScoredMap(this.value, this.score, this.lexicalMatch);

  final Map<String, Object?> value;
  final double score;
  final bool lexicalMatch;
}
