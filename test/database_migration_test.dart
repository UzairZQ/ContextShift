import 'package:context_shift/core/database/schema.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migrates v1 profile and habit rows without data loss', () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        database.execute('''
          CREATE TABLE profile_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            focus_area TEXT,
            support_need TEXT,
            is_guest INTEGER NOT NULL DEFAULT 0,
            model_tier TEXT,
            updated_at INTEGER NOT NULL
          )
        ''');
        database.execute('''
          CREATE TABLE user_preferences_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT NOT NULL UNIQUE,
            response_style TEXT NOT NULL DEFAULT 'balanced',
            premium_purchased INTEGER NOT NULL DEFAULT 0,
            onboarding_done INTEGER NOT NULL DEFAULT 0,
            model_tier TEXT NOT NULL DEFAULT 'e2b'
          )
        ''');
        database.execute('''
          CREATE TABLE task_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            done INTEGER NOT NULL DEFAULT 0,
            priority TEXT NOT NULL DEFAULT 'normal',
            due TEXT NOT NULL DEFAULT 'Today',
            subtasks TEXT NOT NULL DEFAULT '[]',
            created_at INTEGER NOT NULL,
            updated_at INTEGER
          )
        ''');
        database.execute('''
          CREATE TABLE habit_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            icon TEXT NOT NULL,
            completed_dates TEXT NOT NULL DEFAULT '[]',
            created_at INTEGER NOT NULL
          )
        ''');
        database.execute('''
          CREATE TABLE focus_session_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            duration_minutes INTEGER NOT NULL,
            started_at INTEGER NOT NULL,
            completed_at INTEGER,
            completed INTEGER NOT NULL DEFAULT 0
          )
        ''');
        database.execute('''
          CREATE TABLE note_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            content TEXT NOT NULL,
            tags TEXT NOT NULL DEFAULT '[]',
            summary TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        database.execute('''
          CREATE TABLE mood_entry_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            mood TEXT,
            score INTEGER,
            date TEXT NOT NULL,
            note TEXT,
            tags TEXT,
            timestamp INTEGER NOT NULL
          )
        ''');
        database.execute('''
          CREATE TABLE ai_command_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            command TEXT NOT NULL,
            response TEXT NOT NULL,
            actions TEXT NOT NULL DEFAULT '[]',
            timestamp INTEGER NOT NULL
          )
        ''');
        database.execute('''
          CREATE TABLE behavior_event_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            event_type TEXT NOT NULL,
            module TEXT NOT NULL,
            metadata TEXT NOT NULL DEFAULT '{}',
            timestamp INTEGER NOT NULL
          )
        ''');
        database.execute('''
          CREATE TABLE conversation_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            model_tier TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        database.execute('''
          CREATE TABLE message_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conversation_id INTEGER NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            widget_json TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        database.execute(
          "INSERT INTO profile_table "
          "(user_id, name, focus_area, updated_at) "
          "VALUES ('device-1', 'Ada Lovelace', 'Engineering', 0)",
        );
        database.execute(
          "INSERT INTO habit_table "
          "(user_id, name, icon, created_at) "
          "VALUES ('device-1', 'consume nicotine', 'smoking', 0)",
        );
        database.execute('PRAGMA user_version = 1');
      },
    );
    final database = AppDatabase(executor);
    addTearDown(database.close);

    final profile = await database.select(database.profileTable).getSingle();
    final habit = await database.select(database.habitTable).getSingle();

    expect(profile.firstName, 'Ada Lovelace');
    expect(profile.focusRole, 'Engineering');
    expect(habit.kind, 'reduce');
    expect(habit.tinyStep, isNull);
    expect(
      await database
          .customSelect(
            "SELECT name FROM sqlite_master "
            "WHERE type = 'table' AND name = 'saved_generated_card_table'",
          )
          .get(),
      isNotEmpty,
    );
  });
}
