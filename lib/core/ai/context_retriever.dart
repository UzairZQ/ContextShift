import 'dart:math' as math;

import '../database/database_service.dart';

/// Result of a retrieval pass: compact, ranked, prompt-ready context.
class RetrievedContext {
  final List<Map<String, Object?>> tasks;
  final List<Map<String, Object?>> habits;
  final List<Map<String, Object?>> notes;
  final List<Map<String, Object?>> memories;
  final Map<String, Object?> presence;
  final Set<String> queryTerms;

  const RetrievedContext({
    required this.tasks,
    required this.habits,
    required this.notes,
    required this.memories,
    required this.presence,
    required this.queryTerms,
  });

  /// Only non-empty sections, cheapest-to-encode form.
  Map<String, Object?> toPromptJson() {
    return <String, Object?>{
      if (tasks.isNotEmpty) 'tasks': tasks,
      if (habits.isNotEmpty) 'habits': habits,
      if (notes.isNotEmpty) 'notes': notes,
      if (memories.isNotEmpty) 'userMemory': memories,
      if (presence.isNotEmpty) 'today': presence,
    };
  }
}

/// On-device retrieval layer for JARVIS prompts.
///
/// Ranks tasks, habits, notes, and learned memories against the user's
/// message with lexical overlap (exact + prefix), recency decay, and
/// domain boosts, then returns only the top slice of each — instead of
/// dumping whole tables into the prompt.
class ContextRetriever {
  ContextRetriever._();
  static final ContextRetriever instance = ContextRetriever._();

  static const Set<String> _stopwords = {
    'a', 'an', 'and', 'are', 'as', 'at', 'be', 'but', 'by', 'can', 'do',
    'for', 'from', 'get', 'has', 'have', 'how', 'i', 'in', 'is', 'it',
    'its', 'let', 'like', 'make', 'me', 'my', 'no', 'not', 'of', 'on',
    'or', 'our', 'out', 'so', 'some', 'that', 'the', 'their', 'them',
    'then', 'there', 'they', 'this', 'to', 'up', 'us', 'was', 'we',
    'what', 'when', 'where', 'which', 'who', 'will', 'with', 'would',
    'you', 'your', 'please', 'jarvis', 'about', 'should', 'could', 'just',
  };

  static List<String> tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 2 && !_stopwords.contains(t))
        .toList(growable: false);
  }

  Future<RetrievedContext> retrieve({
    required String query,
    int maxTasks = 6,
    int maxHabits = 5,
    int maxNotes = 4,
    int maxMemories = 8,
  }) async {
    final queryTerms = tokenize(query).toSet();
    final wantsEverything = _wantsOverview(query);

    final db = DatabaseService.instance;
    final results = await Future.wait([
      db.getRecentTasks(limit: 120),
      db.getHabitsList(),
      db.getRecentNotes(limit: 40),
      db.getJarvisMemories(),
      db.getTodayFocusMinutes(),
      db.getTodayMood(),
    ]);
    final allTasks = results[0] as List<Map<String, dynamic>>;
    final allHabits = results[1] as List<Map<String, dynamic>>;
    final allNotes = results[2] as List<Map<String, dynamic>>;
    final allMemories = results[3] as List;
    final focusMinutes = results[4] as int;
    final todayMood = results[5] as String?;

    final today = DatabaseService.todayKey();
    final openTasks = allTasks.where((t) => t['done'] != true).toList();

    final tasks = _rank<Map<String, dynamic>>(
      items: openTasks,
      queryTerms: queryTerms,
      textOf: (t) => t['title'] as String? ?? '',
      timeOf: (t) => t['createdAt'] as DateTime?,
      boostOf: (t) => switch (t['priority']) {
        'high' || 'urgent' => 0.6,
        'medium' => 0.2,
        _ => 0.0,
      },
      limit: maxTasks,
      includeByDefault: wantsEverything || _mentionsTasks(query),
    ).map((t) {
      return <String, Object?>{
        'title': _clip(t['title'] as String? ?? '', 90),
        'priority': t['priority'],
        if ((t['due'] as String?)?.isNotEmpty ?? false) 'due': t['due'],
      };
    }).toList(growable: false);

    final habits = _rank<Map<String, dynamic>>(
      items: allHabits,
      queryTerms: queryTerms,
      textOf: (h) =>
          '${h['name'] ?? ''} ${h['kind'] ?? ''} ${h['cue'] ?? ''}',
      timeOf: (h) => h['createdAt'] as DateTime?,
      boostOf: (h) {
        final dates = (h['completedDates'] as List<dynamic>?) ?? const [];
        return dates.contains(today) ? 0.0 : 0.25;
      },
      limit: maxHabits,
      includeByDefault: wantsEverything || _mentionsHabits(query),
    ).map((h) {
      final dates = (h['completedDates'] as List<dynamic>?) ?? const [];
      return <String, Object?>{
        'name': _clip(h['name'] as String? ?? '', 60),
        'kind': h['kind'],
        'doneToday': dates.contains(today),
      };
    }).toList(growable: false);

    final notes = _rank<Map<String, dynamic>>(
      items: allNotes,
      queryTerms: queryTerms,
      textOf: (n) => n['content'] as String? ?? '',
      timeOf: (n) => n['updatedAt'] as DateTime?,
      boostOf: (_) => 0.0,
      limit: maxNotes,
      includeByDefault: wantsEverything || _mentionsNotes(query),
    ).map((n) {
      return <String, Object?>{
        'content': _clip(n['content'] as String? ?? '', 180),
      };
    }).toList(growable: false);

    // Learned memories: identity/goals always matter; the rest compete on
    // confidence + lexical relevance.
    final memoryMaps = allMemories.map((m) {
      final dynamic mem = m;
      return <String, Object?>{
        'kind': mem.kind as String,
        'key': mem.key as String,
        'value': mem.value as String,
        'confidence': mem.confidence as double,
        'updatedAt': mem.updatedAt as DateTime,
      };
    }).toList(growable: false);
    final rankedMemories = _rank<Map<String, Object?>>(
      items: memoryMaps,
      queryTerms: queryTerms,
      textOf: (m) => '${m['key']} ${m['value']}',
      timeOf: (m) => m['updatedAt'] as DateTime?,
      boostOf: (m) {
        final base = (m['confidence'] as double? ?? 0.5) * 0.8;
        final kind = m['kind'] as String? ?? '';
        return base + (kind == 'identity' || kind == 'goal' ? 0.5 : 0.0);
      },
      limit: maxMemories,
      includeByDefault: true,
    ).map((m) {
      return <String, Object?>{
        'kind': m['kind'],
        'key': m['key'],
        'value': _clip(m['value'] as String? ?? '', 120),
      };
    }).toList(growable: false);

    final presence = <String, Object?>{
      'openTasks': openTasks.length,
      'habitsTotal': allHabits.length,
      'focusMinutes': focusMinutes,
      'mood': ?todayMood,
    };

    return RetrievedContext(
      tasks: tasks,
      habits: habits,
      notes: notes,
      memories: rankedMemories,
      presence: presence,
      queryTerms: queryTerms,
    );
  }

  /// Score, sort, and slice one corpus.
  ///
  /// Items with lexical hits always rank first. When [includeByDefault] is
  /// false and nothing matches lexically, the section stays empty so the
  /// prompt budget goes to sections the user actually asked about.
  List<T> _rank<T>({
    required List<T> items,
    required Set<String> queryTerms,
    required String Function(T) textOf,
    required DateTime? Function(T) timeOf,
    required double Function(T) boostOf,
    required int limit,
    required bool includeByDefault,
  }) {
    if (items.isEmpty) return const [];

    final scored = <(T, double, bool)>[];
    for (final item in items) {
      final tokens = tokenize(textOf(item));
      final lexical = _lexicalScore(queryTerms, tokens);
      final score =
          (2.2 * lexical) + _recency(timeOf(item)) + boostOf(item);
      scored.add((item, score, lexical > 0));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));

    final matched = scored.where((s) => s.$3).map((s) => s.$1).toList();
    if (matched.isNotEmpty) {
      if (matched.length >= limit || !includeByDefault) {
        return matched.take(limit).toList();
      }
      final rest = scored
          .where((s) => !s.$3)
          .map((s) => s.$1)
          .take(limit - matched.length);
      return [...matched, ...rest];
    }
    if (!includeByDefault) return const [];
    return scored.map((s) => s.$1).take(limit).toList();
  }

  double _lexicalScore(Set<String> queryTerms, List<String> docTokens) {
    if (queryTerms.isEmpty || docTokens.isEmpty) return 0;
    var hits = 0.0;
    for (final token in docTokens) {
      for (final term in queryTerms) {
        if (token == term) {
          hits += 1;
          break;
        }
        if (token.length >= 4 &&
            term.length >= 4 &&
            (token.startsWith(term) || term.startsWith(token))) {
          hits += 0.7;
          break;
        }
      }
    }
    if (hits == 0) return 0;
    return hits / math.sqrt(docTokens.length.toDouble());
  }

  double _recency(DateTime? timestamp, {double halfLifeDays = 7}) {
    if (timestamp == null) return 0;
    final ageDays =
        DateTime.now().difference(timestamp).inHours / 24.0;
    if (ageDays <= 0) return 1;
    return math.pow(0.5, ageDays / halfLifeDays).toDouble();
  }

  bool _wantsOverview(String query) => RegExp(
    r'\b(dashboard|overview|summary|stats|metrics|report|everything|all|day|today|tomorrow|week|plan my)\b',
    caseSensitive: false,
  ).hasMatch(query);

  bool _mentionsTasks(String query) => RegExp(
    r'\b(task|todo|to-do|priorit|deadline|due|checklist|work on)\b',
    caseSensitive: false,
  ).hasMatch(query);

  bool _mentionsHabits(String query) => RegExp(
    r'\b(habit|routine|streak|daily|consistent)\b',
    caseSensitive: false,
  ).hasMatch(query);

  bool _mentionsNotes(String query) => RegExp(
    r'\b(note|journal|wrote|written|remember|idea|thought)\b',
    caseSensitive: false,
  ).hasMatch(query);

  String _clip(String value, int maxLength) {
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= maxLength) return cleaned;
    return '${cleaned.substring(0, maxLength - 3).trim()}...';
  }
}
