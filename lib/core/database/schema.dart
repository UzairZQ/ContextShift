import 'package:drift/drift.dart';

part 'schema.g.dart';

// ── User Profile ───────────────────────────────────────────────

class ProfileTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().unique()();
  TextColumn get name => text()();
  TextColumn get firstName => text()();
  TextColumn? get lastName => text().nullable()();
  TextColumn? get focusRole => text().nullable()();
  TextColumn? get interests => text().nullable()();
  TextColumn? get windDownTime => text().nullable()();
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
  TextColumn get priority => text().withDefault(const Constant('normal'))();
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
  TextColumn get completedDates => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
}

// ── Focus Sessions ─────────────────────────────────────────────

class FocusSessionTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  IntColumn get durationMinutes => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn? get completedAt => dateTime().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
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

// ── AI Command History ─────────────────────────────────────────

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

// ── Conversation Memory (Jarvis long context) ──────────────────

class ConversationMemoryTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId => integer().unique()();
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get openQuestions => text().withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt => dateTime()();
}

// ── Learned User Memory (Jarvis profile/context) ───────────────

class JarvisMemoryTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get kind => text()();
  TextColumn get key => text()();
  TextColumn get value => text()();
  RealColumn get confidence => real().withDefault(const Constant(0.65))();
  TextColumn? get source => text().nullable()();
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
    ConversationMemoryTable,
    JarvisMemoryTable,
    MessageTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from == 1) {
          await m.addColumn(profileTable, profileTable.firstName);
          await m.addColumn(profileTable, profileTable.lastName);
          await m.addColumn(profileTable, profileTable.focusRole);
          await m.addColumn(profileTable, profileTable.interests);
          await m.addColumn(profileTable, profileTable.windDownTime);

          // Migrate existing data: copy name→firstName if firstName is empty
          await customStatement(
            'UPDATE profile_table SET first_name = name WHERE first_name IS NULL OR first_name = \'\'',
          );
          await customStatement(
            'UPDATE profile_table SET focus_role = focus_area WHERE focus_role IS NULL AND focus_area IS NOT NULL',
          );
        }
        if (from < 3) {
          await m.createTable(conversationMemoryTable);
          await m.createTable(jarvisMemoryTable);
        }
      },
    );
  }
}
