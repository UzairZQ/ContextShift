import 'package:drift/drift.dart';

part 'schema.g.dart';

// ── User Profile ───────────────────────────────────────────────

class ProfileTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().unique()();
  TextColumn get name => text()();
  TextColumn? get focusArea => text().nullable()();
  TextColumn? get supportNeed => text().nullable()();
  BoolColumn get isGuest => boolean().withDefault(const Constant(false))();
  TextColumn? get modelTier => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
}

// ── User Preferences (single row) ──────────────────────────────

class UserPreferencesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().unique()();
  TextColumn get responseStyle =>
      text().withDefault(const Constant('balanced'))();
  BoolColumn get premiumPurchased =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get onboardingDone =>
      boolean().withDefault(const Constant(false))();
  TextColumn get modelTier => text().withDefault(const Constant('e2b'))();
}

// ── Tasks ──────────────────────────────────────────────────────

class TaskTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  TextColumn get priority =>
      text().withDefault(const Constant('normal'))();
  TextColumn get due => text().withDefault(const Constant('Today'))();
  TextColumn get subtasks => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn? get updatedAt => dateTime().nullable()();
}

// ── Habits ─────────────────────────────────────────────────────

class HabitTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get completedDates =>
      text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
}

// ── Focus Sessions ─────────────────────────────────────────────

class FocusSessionTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  IntColumn get durationMinutes => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn? get completedAt => dateTime().nullable()();
  BoolColumn get completed =>
      boolean().withDefault(const Constant(false))();
}

// ── Notes ──────────────────────────────────────────────────────

class NoteTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get content => text()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  TextColumn? get summary => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// ── Mood Entries ───────────────────────────────────────────────

class MoodEntryTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn? get mood => text().nullable()();
  IntColumn? get score => integer().nullable()();
  TextColumn get date => text()();
  TextColumn? get note => text().nullable()();
  TextColumn? get tags => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();
}

// ── AI Command History (legacy) ────────────────────────────────

class AiCommandTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get command => text()();
  TextColumn get response => text()();
  TextColumn get actions => text().withDefault(const Constant('[]'))();
  DateTimeColumn get timestamp => dateTime()();
}

// ── Behavior Events (analytics) ────────────────────────────────

class BehaviorEventTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get eventType => text()();
  TextColumn get module => text()();
  TextColumn get metadata => text().withDefault(const Constant('{}'))();
  DateTimeColumn get timestamp => dateTime()();
}

// ── Conversations (Jarvis chat) ────────────────────────────────

class ConversationTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn? get modelTier => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// ── Messages (Jarvis chat messages) ────────────────────────────

class MessageTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  TextColumn? get widgetJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

// ── Database ───────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    ProfileTable,
    UserPreferencesTable,
    TaskTable,
    HabitTable,
    FocusSessionTable,
    NoteTable,
    MoodEntryTable,
    AiCommandTable,
    BehaviorEventTable,
    ConversationTable,
    MessageTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
