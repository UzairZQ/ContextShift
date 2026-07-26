import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'schema.dart';

/// Singleton service backed by a local Drift (SQLite) database.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  late final AppDatabase _db;
  String _deviceId = '';
  bool _initialized = false;

  static String dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String todayKey() => dateKey(DateTime.now());

  // ── Init ─────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('_device_id') ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = const Uuid().v4();
      await prefs.setString('_device_id', _deviceId);
    }

    _db = AppDatabase(_openConnection());

    // Ensure a UserPreferences row exists
    final existing = await (_db.select(
      _db.userPreferencesTable,
    )..where((t) => t.deviceId.equals(_deviceId))).getSingleOrNull();
    if (existing == null) {
      await _db
          .into(_db.userPreferencesTable)
          .insert(UserPreferencesTableCompanion.insert(deviceId: _deviceId));
    }

    // Cache profile
    _cachedProfile = await (_db.select(
      _db.profileTable,
    )..where((t) => t.userId.equals(_deviceId))).getSingleOrNull();

    _initialized = true;
    debugPrint('DatabaseService: initialized with deviceId=$_deviceId');
  }

  LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbDir = await getApplicationDocumentsDirectory();
      await dbDir.create(recursive: true);
      final dbPath = p.join(dbDir.path, 'context_shift.db');
      return NativeDatabase(File(dbPath));
    });
  }

  // ── Device / User ────────────────────────────────────────────

  String get currentUserId => _deviceId;

  bool get isGuest => _cachedProfile?.isGuest ?? false;

  String get currentUserName {
    final name = _cachedProfile?.name;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    return 'Traveler';
  }

  String get firstName {
    final name = currentUserName.trim();
    if (name.isEmpty) return 'Traveler';
    return name.split(' ').first;
  }

  String? get lastName => _cachedProfile?.lastName;

  String? get focusRole => _cachedProfile?.focusRole;

  String? get windDownTime => _cachedProfile?.windDownTime;

  ProfileTableData? _cachedProfile;

  Future<void> saveUserProfile({
    String? name,
    String? firstName,
    String? lastName,
    String? focusRole,
    List<String>? interests,
    String? windDownTime,
    String? focusArea,
    String? supportNeed,
    bool? isGuest,
  }) async {
    final uid = _deviceId;
    final finalName = (name ?? _cachedProfile?.name ?? 'Traveler').trim();

    await _db
        .into(_db.profileTable)
        .insert(
          ProfileTableCompanion.insert(
            userId: uid,
            name: finalName,
            firstName:
                firstName ??
                _cachedProfile?.firstName ??
                finalName.split(' ').first,
            lastName: Value(lastName?.trim()),
            focusRole: Value(focusRole?.trim()),
            interests: Value(interests != null ? jsonEncode(interests) : null),
            windDownTime: Value(windDownTime?.trim()),
            focusArea: Value(focusArea?.trim()),
            supportNeed: Value(supportNeed?.trim()),
            isGuest: Value(isGuest ?? _cachedProfile?.isGuest ?? false),
            updatedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrReplace,
        );

    _cachedProfile = await (_db.select(
      _db.profileTable,
    )..where((t) => t.userId.equals(uid))).getSingleOrNull();

    debugPrint('DatabaseService: saved profile for $uid');
  }

  List<String> get profileInterests {
    final raw = _cachedProfile?.interests;
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  bool get hasProfileData {
    final p = _cachedProfile;
    if (p == null) return false;
    return p.firstName.isNotEmpty &&
        (p.focusRole?.isNotEmpty ?? false) &&
        (p.interests?.isNotEmpty ?? false);
  }

  // ── Behavior Events ──────────────────────────────────────────

  Future<void> logEvent({
    required String eventType,
    required String module,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _db
          .into(_db.behaviorEventTable)
          .insert(
            BehaviorEventTableCompanion.insert(
              userId: _deviceId,
              eventType: eventType,
              module: module,
              metadata: Value(jsonEncode(metadata ?? {})),
              timestamp: DateTime.now(),
            ),
          );
    } catch (e) {
      debugPrint('DatabaseService.logEvent error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentEvents({int limit = 50}) async {
    try {
      final rows =
          await (_db.select(_db.behaviorEventTable)
                ..where((t) => t.userId.equals(_deviceId))
                ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
                ..limit(limit))
              .get();

      return rows.map(_eventToMap).toList();
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> _eventToMap(BehaviorEventTableData event) {
    return {
      'id': event.id.toString(),
      'userId': event.userId,
      'eventType': event.eventType,
      'module': event.module,
      'metadata': jsonDecode(event.metadata) as Map<String, dynamic>? ?? {},
      'timestamp': event.timestamp,
    };
  }

  // ── Context Snapshot (for AI) ────────────────────────────────

  Future<Map<String, dynamic>> buildContextSnapshot() async {
    try {
      final todayStr = todayKey();

      final profile = await (_db.select(
        _db.profileTable,
      )..where((t) => t.userId.equals(_deviceId))).getSingleOrNull();

      final tasks =
          await (_db.select(_db.taskTable)
                ..where((t) => t.userId.equals(_deviceId))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
                ..limit(120))
              .get();
      final openTasks = tasks.where((task) => !task.done).toList();

      final allHabits = await (_db.select(
        _db.habitTable,
      )..where((t) => t.userId.equals(_deviceId))).get();

      final openBehaviorSignals = <String>[];
      for (final h in allHabits) {
        final dates = jsonDecode(h.completedDates) as List<dynamic>? ?? [];
        if (!dates.contains(todayStr)) {
          openBehaviorSignals.add(h.name);
        }
      }

      final sortedNotes =
          await (_db.select(_db.noteTable)
                ..where((t) => t.userId.equals(_deviceId))
                ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
                ..limit(12))
              .get();
      final recentNote = sortedNotes.isNotEmpty
          ? sortedNotes.first.content
          : null;

      final sortedCommands =
          await (_db.select(_db.aiCommandTable)
                ..where((t) => t.userId.equals(_deviceId))
                ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
                ..limit(5))
              .get();

      final sortedEvents =
          await (_db.select(_db.behaviorEventTable)
                ..where((t) => t.userId.equals(_deviceId))
                ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
                ..limit(10))
              .get();

      final todayMood = await _getTodayMoodRaw();
      final focusMinutes = await getTodayFocusMinutes();

      return {
        'profile': {
          'name': profile?.name ?? currentUserName,
          'first_name': profile?.firstName ?? firstName,
          'last_name': profile?.lastName,
          'focus_role': profile?.focusRole,
          'interests': profile?.interests != null
              ? jsonDecode(profile!.interests!) as List<dynamic>? ?? []
              : [],
          'wind_down_time': profile?.windDownTime,
          'focus_area': profile?.focusArea,
          'support_need': profile?.supportNeed,
          'is_guest': profile?.isGuest ?? false,
          'model_tier': profile?.modelTier,
        },
        'tasks': {
          'open_count': openTasks.length,
          'completed_count': tasks.where((task) => task.done).length,
          'high_priority_open': openTasks
              .where((task) => task.priority == 'high')
              .map(_taskToMap)
              .take(5)
              .toList(),
          'recent_open': openTasks.map(_taskToMap).take(10).toList(),
        },
        'habits': {
          'total': allHabits.length,
          'open_today': openBehaviorSignals.take(10).toList(),
          'items': allHabits.map(_habitToMap).take(10).toList(),
        },
        'recent_note': recentNote,
        'recent_notes': sortedNotes.map(_noteToMap).take(5).toList(),
        'today_mood': todayMood,
        'focus_minutes_today': focusMinutes,
        'recent_commands': sortedCommands
            .take(3)
            .map((c) => {'command': c.command, 'response': c.response})
            .toList(),
        'recent_events': sortedEvents
            .take(5)
            .map((e) => {'event_type': e.eventType, 'module': e.module})
            .toList(),
      };
    } catch (e) {
      debugPrint('DatabaseService.buildContextSnapshot error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> buildInsightStats() async {
    try {
      final tasks = await (_db.select(
        _db.taskTable,
      )..where((t) => t.userId.equals(_deviceId))).get();
      final habits = await (_db.select(
        _db.habitTable,
      )..where((t) => t.userId.equals(_deviceId))).get();
      final focusMinutes = await getTodayFocusMinutes();
      final todayMood = await _getTodayMoodRaw();
      final todayStr = _todayString();

      final openTasks = tasks.where((t) => !t.done).length;
      final completedTasks = tasks.where((t) => t.done).length;
      final completedHabits = habits.where((h) {
        final dates = jsonDecode(h.completedDates) as List<dynamic>? ?? [];
        return dates.contains(todayStr);
      }).length;

      return {
        'open_tasks': openTasks,
        'completed_tasks': completedTasks,
        'total_habits': habits.length,
        'completed_habits_today': completedHabits,
        'focus_minutes_today': focusMinutes,
        'current_streak': computeStreak(habits.map(_habitToMap).toList()),
        'today_mood': todayMood,
      };
    } catch (e) {
      debugPrint('DatabaseService.buildInsightStats error: $e');
      return {};
    }
  }

  // ── Tasks ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRecentTasks({int limit = 120}) async {
    final rows =
        await (_db.select(_db.taskTable)
              ..where((t) => t.userId.equals(_deviceId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(limit))
            .get();
    return rows.map(_taskToMap).toList();
  }

  Stream<List<Map<String, dynamic>>> watchTasks() {
    return (_db.select(_db.taskTable)
          ..where((t) => t.userId.equals(_deviceId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_taskToMap).toList());
  }

  Future<void> addTask({
    required String title,
    String priority = 'normal',
    String due = 'Today',
    List<Map<String, dynamic>> subtasks = const [],
  }) async {
    await _db
        .into(_db.taskTable)
        .insert(
          TaskTableCompanion.insert(
            userId: _deviceId,
            title: title,
            priority: Value(priority),
            due: Value(due),
            subtasks: Value(jsonEncode(subtasks)),
            createdAt: DateTime.now(),
          ),
        );
    await logEvent(eventType: 'task_created', module: 'tasks');
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    final id = int.parse(taskId);

    // Build companion from the updates map
    final companionBuilder = TaskTableCompanion(
      updatedAt: Value(DateTime.now()),
    );
    final updated = companionBuilder.copyWith(
      title: updates.containsKey('title')
          ? Value(updates['title'] as String)
          : const Value.absent(),
      done: updates.containsKey('done')
          ? Value(updates['done'] as bool)
          : const Value.absent(),
      priority: updates.containsKey('priority')
          ? Value(updates['priority'] as String)
          : const Value.absent(),
      due: updates.containsKey('due')
          ? Value(updates['due'] as String)
          : const Value.absent(),
      subtasks: updates.containsKey('subtasks')
          ? Value(jsonEncode(updates['subtasks']))
          : const Value.absent(),
    );

    await (_db.update(
      _db.taskTable,
    )..where((t) => t.id.equals(id))).write(updated);
  }

  Future<void> toggleTask(String taskId, bool isDone) async {
    final id = int.parse(taskId);
    await (_db.update(_db.taskTable)..where((t) => t.id.equals(id))).write(
      TaskTableCompanion(done: Value(isDone), updatedAt: Value(DateTime.now())),
    );
    await logEvent(
      eventType: isDone ? 'task_completed' : 'task_uncompleted',
      module: 'tasks',
    );
  }

  Future<void> deleteTask(String taskId) async {
    final id = int.parse(taskId);
    await (_db.delete(_db.taskTable)..where((t) => t.id.equals(id))).go();
    await logEvent(eventType: 'task_deleted', module: 'tasks');
  }

  Map<String, dynamic> _taskToMap(TaskTableData t) {
    return {
      'id': t.id.toString(),
      'userId': t.userId,
      'title': t.title,
      'done': t.done,
      'priority': t.priority,
      'due': t.due,
      'subtasks': jsonDecode(t.subtasks) as List<dynamic>? ?? [],
      'createdAt': t.createdAt,
    };
  }

  // ── Habits ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getHabitsList() async {
    final rows = await (_db.select(
      _db.habitTable,
    )..where((t) => t.userId.equals(_deviceId))).get();
    return rows.map(_habitToMap).toList();
  }

  Stream<List<Map<String, dynamic>>> watchHabits() {
    return (_db.select(_db.habitTable)
          ..where((t) => t.userId.equals(_deviceId)))
        .watch()
        .map((rows) => rows.map(_habitToMap).toList());
  }

  Future<void> addHabit({required String name, required String icon}) async {
    final kind = _inferHabitKind(name);
    await addHabitWithKind(name: name, icon: icon, kind: kind);
  }

  Future<void> addHabitWithKind({
    required String name,
    required String icon,
    required String kind,
    String? cue,
    String? tinyStep,
    String? reward,
    String? friction,
  }) async {
    final normalizedKind = kind == 'reduce' ? 'reduce' : 'build';
    final defaults = _defaultHabitStrategy(name, normalizedKind);
    await _db
        .into(_db.habitTable)
        .insert(
          HabitTableCompanion.insert(
            userId: _deviceId,
            name: name,
            icon: icon,
            kind: Value(normalizedKind),
            cue: Value(_cleanNullable(cue) ?? defaults.cue),
            tinyStep: Value(_cleanNullable(tinyStep) ?? defaults.tinyStep),
            reward: Value(_cleanNullable(reward) ?? defaults.reward),
            friction: Value(_cleanNullable(friction) ?? defaults.friction),
            createdAt: DateTime.now(),
          ),
        );
    await logEvent(
      eventType: 'habit_created',
      module: 'habits',
      metadata: {'kind': normalizedKind},
    );
  }

  Future<void> toggleHabitToday(String habitId, bool isDone) async {
    final id = int.parse(habitId);
    final today = _todayString();
    final habit = await (_db.select(
      _db.habitTable,
    )..where((t) => t.id.equals(id))).getSingle();

    final dates = jsonDecode(habit.completedDates) as List<dynamic>? ?? [];
    if (isDone) {
      if (!dates.contains(today)) dates.add(today);
    } else {
      dates.remove(today);
    }

    await (_db.update(_db.habitTable)..where((t) => t.id.equals(id))).write(
      HabitTableCompanion(completedDates: Value(jsonEncode(dates))),
    );
    await logEvent(
      eventType: isDone ? 'habit_completed' : 'habit_uncompleted',
      module: 'habits',
      metadata: {'habitId': habitId, 'date': today},
    );
  }

  Map<String, dynamic> _habitToMap(HabitTableData h) {
    return {
      'id': h.id.toString(),
      'userId': h.userId,
      'name': h.name,
      'icon': h.icon,
      'kind': h.kind,
      'cue': h.cue,
      'tinyStep': h.tinyStep,
      'reward': h.reward,
      'friction': h.friction,
      'completedDates': jsonDecode(h.completedDates) as List<dynamic>? ?? [],
      'createdAt': h.createdAt,
    };
  }

  ({String cue, String tinyStep, String reward, String friction})
  _defaultHabitStrategy(String name, String kind) {
    if (kind == 'reduce') {
      return (
        cue: 'When the urge shows up',
        tinyStep: 'Do a 2-minute replacement first',
        reward: 'Mark the day protected',
        friction: 'Put one extra step between you and $name',
      );
    }
    return (
      cue: 'After an existing routine',
      tinyStep: 'Do the smallest 2-minute version',
      reward: 'Mark the win immediately',
      friction: 'Keep the first step visible and ready',
    );
  }

  String? _cleanNullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  String _inferHabitKind(String name) {
    final lower = name.toLowerCase();
    if (RegExp(
      r'\b(nicotine|smok(e|ing)?|vape|alcohol|drink less|junk food|doomscroll|scroll less|avoid|stop|quit|reduce|less)\b',
    ).hasMatch(lower)) {
      return 'reduce';
    }
    return 'build';
  }

  // ── Focus Sessions ───────────────────────────────────────────

  Future<String> startFocusSession({int durationMinutes = 25}) async {
    final id = await _db
        .into(_db.focusSessionTable)
        .insert(
          FocusSessionTableCompanion.insert(
            userId: _deviceId,
            durationMinutes: durationMinutes,
            startedAt: DateTime.now(),
          ),
        );
    await logEvent(
      eventType: 'focus_started',
      module: 'focus',
      metadata: {'duration': durationMinutes},
    );
    return id.toString();
  }

  Future<void> completeFocusSession(String sessionId) async {
    final id = int.parse(sessionId);
    await (_db.update(
      _db.focusSessionTable,
    )..where((t) => t.id.equals(id))).write(
      FocusSessionTableCompanion(
        completedAt: Value(DateTime.now()),
        completed: const Value(true),
      ),
    );
    await logEvent(eventType: 'focus_completed', module: 'focus');
  }

  Future<int> getTodayFocusMinutes() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final sessions =
          await (_db.select(_db.focusSessionTable)..where(
                (t) =>
                    t.userId.equals(_deviceId) &
                    t.completed.equals(true) &
                    t.completedAt.isBiggerOrEqualValue(startOfDay),
              ))
              .get();

      int total = 0;
      for (final s in sessions) {
        final d = s.completedAt;
        if (d != null) {
          total += _actualFocusMinutes(s.startedAt, d, s.durationMinutes);
        }
      }
      return total;
    } catch (e) {
      debugPrint('DatabaseService.getTodayFocusMinutes error: $e');
      return 0;
    }
  }

  int _actualFocusMinutes(
    DateTime startedAt,
    DateTime completedAt,
    int plannedMinutes,
  ) {
    final elapsedSeconds = completedAt.difference(startedAt).inSeconds;
    if (elapsedSeconds <= 0) return 0;
    final actualMinutes = (elapsedSeconds / 60).round();
    return actualMinutes.clamp(0, plannedMinutes);
  }

  // ── Notes ────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRecentNotes({int limit = 40}) async {
    final rows =
        await (_db.select(_db.noteTable)
              ..where((t) => t.userId.equals(_deviceId))
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
              ..limit(limit))
            .get();
    return rows.map(_noteToMap).toList();
  }

  Stream<List<Map<String, dynamic>>> watchNotes() {
    return (_db.select(_db.noteTable)
          ..where((t) => t.userId.equals(_deviceId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .map((rows) => rows.map(_noteToMap).toList());
  }

  Future<void> addNote({required String content, List<String>? tags}) async {
    final now = DateTime.now();
    await _db
        .into(_db.noteTable)
        .insert(
          NoteTableCompanion.insert(
            userId: _deviceId,
            content: content,
            tags: Value(jsonEncode(tags ?? [])),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await logEvent(eventType: 'note_created', module: 'notes');
  }

  Future<void> deleteNote(String noteId) async {
    final id = int.parse(noteId);
    await (_db.delete(_db.noteTable)..where((t) => t.id.equals(id))).go();
    await logEvent(eventType: 'note_deleted', module: 'notes');
  }

  Future<void> updateNote(
    String noteId,
    String content, {
    List<String>? tags,
    String? summary,
  }) async {
    final id = int.parse(noteId);

    final companion = NoteTableCompanion(
      content: Value(content),
      updatedAt: Value(DateTime.now()),
      tags: tags != null ? Value(jsonEncode(tags)) : const Value.absent(),
      summary: summary != null ? Value(summary) : const Value.absent(),
    );

    await (_db.update(
      _db.noteTable,
    )..where((t) => t.id.equals(id))).write(companion);
    await logEvent(eventType: 'note_updated', module: 'notes');
  }

  Map<String, dynamic> _noteToMap(NoteTableData n) {
    return {
      'id': n.id.toString(),
      'userId': n.userId,
      'content': n.content,
      'tags': jsonDecode(n.tags) as List<dynamic>? ?? [],
      'summary': n.summary,
      'updatedAt': n.updatedAt,
      'createdAt': n.createdAt,
    };
  }

  // ── Mood Tracking ────────────────────────────────────────────

  Future<void> saveMood(String mood) async {
    await _db
        .into(_db.moodEntryTable)
        .insert(
          MoodEntryTableCompanion.insert(
            userId: _deviceId,
            mood: Value(mood),
            date: _todayString(),
            timestamp: DateTime.now(),
          ),
        );
    await logEvent(
      eventType: 'mood_logged',
      module: 'mood',
      metadata: {'mood': mood},
    );
  }

  Future<String?> _getTodayMoodRaw() async {
    try {
      final todayStr = _todayString();
      final row =
          await (_db.select(_db.moodEntryTable)
                ..where(
                  (t) => t.userId.equals(_deviceId) & t.date.equals(todayStr),
                )
                ..limit(1))
              .getSingleOrNull();
      return row?.mood;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getTodayMood() => _getTodayMoodRaw();

  Stream<List<Map<String, dynamic>>> watchMoods({int days = 14}) {
    return (_db.select(_db.moodEntryTable)
          ..where((t) => t.userId.equals(_deviceId))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(days))
        .watch()
        .map((rows) => rows.map(_moodToMap).toList());
  }

  Map<String, dynamic> _moodToMap(MoodEntryTableData m) {
    return {
      'id': m.id.toString(),
      'userId': m.userId,
      'mood': m.mood,
      'score': m.score,
      'date': m.date,
      'note': m.note,
      'tags': m.tags != null ? jsonDecode(m.tags!) as List<dynamic>? ?? [] : [],
      'timestamp': m.timestamp,
    };
  }

  // ── AI Command History ───────────────────────────────────────

  Future<void> saveAiCommand({
    required String command,
    required String response,
    List<Map<String, dynamic>>? actions,
  }) async {
    await _db
        .into(_db.aiCommandTable)
        .insert(
          AiCommandTableCompanion.insert(
            userId: _deviceId,
            command: command,
            response: response,
            actions: Value(jsonEncode(actions ?? [])),
            timestamp: DateTime.now(),
          ),
        );
  }

  Stream<List<Map<String, dynamic>>> watchAiCommands({int limit = 20}) {
    return (_db.select(_db.aiCommandTable)
          ..where((t) => t.userId.equals(_deviceId))
          ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
          ..limit(limit))
        .watch()
        .map((rows) => rows.map(_aiCommandToMap).toList());
  }

  Map<String, dynamic> _aiCommandToMap(AiCommandTableData cmd) {
    return {
      'id': cmd.id.toString(),
      'userId': cmd.userId,
      'command': cmd.command,
      'response': cmd.response,
      'actions': jsonDecode(cmd.actions) as List<dynamic>? ?? [],
      'timestamp': cmd.timestamp,
    };
  }

  // ── Saved Generated Cards ───────────────────────────────────

  Future<SavedGeneratedCardTableData> saveGeneratedCard({
    required String title,
    required String domain,
    required String rawA2ui,
    String? source,
    String? fallbackReason,
    int? elapsedMs,
    String? originalPrompt,
  }) async {
    final now = DateTime.now();
    await (_db.delete(
      _db.savedGeneratedCardTable,
    )..where((t) => t.userId.equals(_deviceId))).go();
    final id = await _db
        .into(_db.savedGeneratedCardTable)
        .insert(
          SavedGeneratedCardTableCompanion.insert(
            userId: _deviceId,
            title: _clipText(title.trim().isEmpty ? 'Generated card' : title),
            domain: Value(_clipText(domain.trim().isEmpty ? 'card' : domain)),
            rawA2ui: rawA2ui,
            source: Value(_clipNullable(source)),
            fallbackReason: Value(_clipNullable(fallbackReason)),
            elapsedMs: Value(elapsedMs),
            originalPrompt: Value(_clipNullable(originalPrompt, max: 1000)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await logEvent(
      eventType: 'generated_card_saved',
      module: 'jarvis',
      metadata: {'domain': domain, 'source': source},
    );
    return (_db.select(
      _db.savedGeneratedCardTable,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Stream<List<SavedGeneratedCardTableData>> watchSavedGeneratedCards({
    int limit = 1,
  }) {
    return (_db.select(_db.savedGeneratedCardTable)
          ..where((t) => t.userId.equals(_deviceId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  Future<void> deleteSavedGeneratedCard(int id) async {
    await (_db.delete(
      _db.savedGeneratedCardTable,
    )..where((t) => t.id.equals(id) & t.userId.equals(_deviceId))).go();
    await logEvent(
      eventType: 'generated_card_deleted',
      module: 'jarvis',
      metadata: {'cardId': id},
    );
  }

  String _clipText(String value, {int max = 240}) {
    final text = value.trim();
    if (text.length <= max) return text;
    return text.substring(0, max);
  }

  String? _clipNullable(String? value, {int max = 240}) {
    if (value == null) return null;
    final text = value.trim();
    if (text.isEmpty) return null;
    return _clipText(text, max: max);
  }

  // ── Conversations (Jarvis chat) ─────────────────────────────

  Future<List<ConversationTableData>> getAllConversations() async {
    return (_db.select(_db.conversationTable)
          ..where((t) => t.userId.equals(_deviceId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<ConversationTableData> createConversation({
    required String title,
    String? modelTier,
  }) async {
    final now = DateTime.now();
    final id = await _db
        .into(_db.conversationTable)
        .insert(
          ConversationTableCompanion.insert(
            userId: _deviceId,
            title: title,
            modelTier: Value(modelTier),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final conv = await (_db.select(
      _db.conversationTable,
    )..where((t) => t.id.equals(id))).getSingle();
    return conv;
  }

  Future<void> renameConversation(int id, String title) async {
    await (_db.update(
      _db.conversationTable,
    )..where((t) => t.id.equals(id))).write(
      ConversationTableCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteConversation(int id) async {
    await (_db.delete(
      _db.messageTable,
    )..where((t) => t.conversationId.equals(id))).go();
    await (_db.delete(
      _db.conversationMemoryTable,
    )..where((t) => t.conversationId.equals(id))).go();
    await (_db.delete(
      _db.conversationTable,
    )..where((t) => t.id.equals(id))).go();
  }

  Stream<List<MessageTableData>> watchMessages(int conversationId) {
    return (_db.select(_db.messageTable)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<List<MessageTableData>> getMessages(int conversationId) async {
    return (_db.select(_db.messageTable)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<MessageTableData> addMessage({
    required int conversationId,
    required String role,
    required String content,
    String? widgetJson,
  }) async {
    final id = await _db
        .into(_db.messageTable)
        .insert(
          MessageTableCompanion.insert(
            conversationId: conversationId,
            role: role,
            content: content,
            widgetJson: Value(widgetJson),
            createdAt: DateTime.now(),
          ),
        );
    // Touch conversation updatedAt
    await (_db.update(_db.conversationTable)
          ..where((t) => t.id.equals(conversationId)))
        .write(ConversationTableCompanion(updatedAt: Value(DateTime.now())));
    final msg = await (_db.select(
      _db.messageTable,
    )..where((t) => t.id.equals(id))).getSingle();
    return msg;
  }

  // ── Jarvis Memory ────────────────────────────────────────────

  Future<ConversationMemoryTableData?> getConversationMemory(
    int conversationId,
  ) {
    return (_db.select(
      _db.conversationMemoryTable,
    )..where((t) => t.conversationId.equals(conversationId))).getSingleOrNull();
  }

  Future<void> upsertConversationMemory({
    required int conversationId,
    required String summary,
    List<String> openQuestions = const [],
  }) async {
    final existing = await getConversationMemory(conversationId);
    final now = DateTime.now();
    if (existing == null) {
      await _db
          .into(_db.conversationMemoryTable)
          .insert(
            ConversationMemoryTableCompanion.insert(
              conversationId: conversationId,
              summary: Value(summary),
              openQuestions: Value(jsonEncode(openQuestions)),
              updatedAt: now,
            ),
          );
      return;
    }
    await (_db.update(
      _db.conversationMemoryTable,
    )..where((t) => t.conversationId.equals(conversationId))).write(
      ConversationMemoryTableCompanion(
        summary: Value(summary),
        openQuestions: Value(jsonEncode(openQuestions)),
        updatedAt: Value(now),
      ),
    );
  }

  Future<List<JarvisMemoryTableData>> getJarvisMemories({
    int limit = 30,
  }) async {
    return (_db.select(_db.jarvisMemoryTable)
          ..where((t) => t.userId.equals(_deviceId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.confidence),
            (t) => OrderingTerm.desc(t.updatedAt),
          ])
          ..limit(limit))
        .get();
  }

  Future<void> upsertJarvisMemory({
    required String kind,
    required String key,
    required String value,
    double confidence = 0.65,
    String? source,
  }) async {
    final now = DateTime.now();
    final normalizedKey = key.trim().toLowerCase();
    final existing =
        await (_db.select(_db.jarvisMemoryTable)..where(
              (t) =>
                  t.userId.equals(_deviceId) &
                  t.kind.equals(kind) &
                  t.key.equals(normalizedKey),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await _db
          .into(_db.jarvisMemoryTable)
          .insert(
            JarvisMemoryTableCompanion.insert(
              userId: _deviceId,
              kind: kind,
              key: normalizedKey,
              value: value.trim(),
              confidence: Value(confidence.clamp(0.0, 1.0)),
              source: Value(source),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return;
    }

    await (_db.update(
      _db.jarvisMemoryTable,
    )..where((t) => t.id.equals(existing.id))).write(
      JarvisMemoryTableCompanion(
        value: Value(value.trim()),
        confidence: Value(
          confidence > existing.confidence
              ? confidence.clamp(0.0, 1.0)
              : existing.confidence,
        ),
        source: Value(source ?? existing.source),
        updatedAt: Value(now),
      ),
    );
  }

  // ── Streak Calculation ───────────────────────────────────────

  int computeStreak(List<Map<String, dynamic>> habits) {
    if (habits.isEmpty) return 0;

    final Set<String> allDates = {};
    for (final h in habits) {
      final dates = (h['completedDates'] as List<dynamic>?) ?? [];
      for (final d in dates) {
        if (d is String) allDates.add(d);
      }
    }

    int streak = 0;
    DateTime day = DateTime.now();
    while (true) {
      final dayStr = dateKey(day);
      if (allDates.contains(dayStr)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Helpers ──────────────────────────────────────────────────

  String _todayString() {
    return todayKey();
  }
}
