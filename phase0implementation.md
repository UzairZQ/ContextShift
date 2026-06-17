# Phase 0 — Migration & Foundation

## Goal
Remove Firebase (except Crashlytics), set up Drift with all tables, create a `DatabaseService` that mirrors the existing `FirebaseService` API exactly, and swap all UI screens to use it.

---

## Step 1 — Remove Firebase Dependencies

### Remove from pubspec.yaml
```yaml
# REMOVE these lines:
cloud_firestore: ^5.6.1
firebase_auth: ^5.4.4
google_sign_in: ^6.2.2

# KEEP these:
firebase_core: ^3.15.2
firebase_crashlytics: ^4.3.10
```

### Add Drift + UUID
```yaml
drift: ^2.26.0
sqlite3_flutter_libs: ^0.5.0
path_provider: ^2.1.0
uuid: ^4.5.1
```

Also add `drift_dev` to dev_dependencies:
```yaml
dev_dependencies:
  drift_dev: ^2.26.0
  build_runner: ^2.4.0
```

Run: `flutter pub get`

---

## Step 2 — Create Drift Schema

File: `lib/core/database/schema.dart`

### All tables (11 total):

**Existing entities (8):**

| Table | PK | Key Fields |
|-------|-----|-----------|
| `Profile` | int id | `userId` (text, unique), `name`, `focusArea`?, `supportNeed`?, `isGuest`, `modelTier`?, `updatedAt` |
| `Task` | int id | `userId`, `title`, `done`, `priority`, `due`, `subtasks` (JSON text), `createdAt`, `updatedAt`? |
| `Habit` | int id | `userId`, `name`, `icon`, `completedDates` (JSON text), `createdAt` |
| `FocusSession` | int id | `userId`, `durationMinutes`, `startedAt`, `completedAt`?, `completed` |
| `Note` | int id | `userId`, `content`, `tags` (JSON text), `summary`?, `createdAt`, `updatedAt` |
| `MoodEntry` | int id | `userId`, `mood`? (emoji), `score`? (int 1-10), `date` (text YYYY-MM-DD), `note`? (text), `tags`? (JSON text), `timestamp` |
| `AiCommand` | int id | `userId`, `command`, `response`, `actions` (JSON text), `timestamp` |
| `BehaviorEvent` | int id | `userId`, `eventType`, `module`, `metadata` (JSON text), `timestamp` |

**New entities (3):**

| Table | PK | Key Fields |
|-------|-----|-----------|
| `UserPreferences` | int id | `deviceId` (text, unique), `responseStyle`, `premiumPurchased`, `onboardingDone`, `modelTier` |
| `Conversation` | int id | `userId`, `title`, `modelTier`?, `createdAt`, `updatedAt` |
| `Message` | int id | `conversationId` (FK), `role`, `content`, `widgetJson`?, `createdAt` |

### Important schema notes:
- **MoodEntry** keeps both `mood` (emoji string, nullable) for existing UI and `score` (int 1-10, nullable) for new features. The existing mood check-in writes `mood`; the new Jarvis system writes `score`. They coexist until integration.
- **Subtask, completedDates, tags, actions, metadata** — stored as JSON text strings, decoded by DAO methods. Use `dart:convert` jsonDecode/jsonEncode.
- All tables use `int` auto-increment primary keys. DAO methods return `Map<String, dynamic>` with `id` as string (`.toString()`) to match existing UI code.

---

## Step 3 — Create DatabaseService

File: `lib/core/database/database_service.dart`

A singleton that wraps Drift DAOs and exposes **exactly the same API** as `FirebaseService`:

```dart
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  late final AppDatabase _db;
  String _deviceId = '';  // generated on first launch

  Future<void> init() async { ... }
  String get currentUserId => _deviceId;
}
```

### Methods to implement (mirroring FirebaseService exactly):

| Category | FirebaseService method | DatabaseService equivalent |
|----------|----------------------|--------------------------|
| Auth | `currentUser`, `authStateChanges` | **Removed** — no auth, always a single user/device |
| Auth | `currentUserId` | Returns device UUID |
| Auth | `currentUserName`, `firstName` | Read from Profile table, fallback to "Traveler" |
| Auth | `signUp`, `signIn`, `signInWithGoogle`, `signInAsGuest`, `signOut` | **Removed** — replaced by onboarding profile setup |
| Auth | `saveUserProfile`, `_trySaveUserProfile` | Same, writes to Profile table |
| Events | `logEvent`, `getRecentEvents` | Same, writes to BehaviorEvent table |
| Context | `buildContextSnapshot`, `buildInsightStats` | Same queries against Drift tables |
| Tasks | `watchTasks()`, `addTask`, `updateTask`, `toggleTask`, `deleteTask` | Same, uses Drift DAO with streams |
| Habits | `watchHabits()`, `addHabit`, `toggleHabitToday` | Same |
| Focus | `startFocusSession`, `completeFocusSession`, `getTodayFocusMinutes` | Same |
| Notes | `watchNotes()`, `addNote`, `deleteNote`, `updateNote` | Same |
| Mood | `saveMood`, `getTodayMood`, `watchMoods()` | Same |
| AI | `saveAiCommand`, `watchAiCommands()` | Same |
| Streak | `computeStreak` | Same logic |

### Stream migration:
- Firebase: `.snapshots()` → Drift: `.watch()` (native stream support in drift)
- The DAO maps each row to `{'id': id.toString(), ...dataAsMap}` for UI compatibility
- For queries like `getTodayFocusMinutes()`, use `SELECT * WHERE completed = true` then filter in Dart (or use SQL date functions)

### Device ID:
- On first app launch, generate a UUID v4 and store in SharedPreferences
- Use this as `userId` for all tables
- In `init()`, create default `UserPreferences` row if none exists

---

## Step 4 — Update main.dart

Remove the Firebase auth gate. The new launch flow:

```
App starts
  → Initialize Firebase Crashlytics only
  → Initialize DatabaseService (creates device UUID on first run)
  → Check: has user completed onboarding?
    → No: OnboardingScreen (profile setup + model download decision)
    → Yes: HomeScreen
```

No more `StreamBuilder` waiting for auth state. Just a simple `SharedPreferences` check for onboarding status.

---

## Step 5 — Remove Auth Screens (or convert)

Files to **remove or gut**:
- `lib/presentation/screens/login/login_screen.dart` — remove
- `lib/presentation/screens/register/register_screen.dart` — remove
- `lib/presentation/screens/guest_profile/guest_profile_screen.dart` — **keep but convert**: this becomes the profile setup screen in onboarding, no longer tied to Firebase guest auth
- `lib/presentation/screens/onboarding/onboarding_screen.dart` — **keep and update**: remove Firebase auth calls, add device UUID creation and model download decision

Existing auth widgets to remove:
- `lib/presentation/shared/auth_text_field.dart` — remove (was for login form)
- `lib/presentation/shared/google_sign_in_button.dart` — remove
- `lib/presentation/shared/guest_button.dart` — remove

---

## Step 6 — Update ai_service.dart

Replace `FirebaseService.instance.buildContextSnapshot()` with `DatabaseService.instance.buildContextSnapshot()`.

The `AiService` itself stays — it's the local fallback parser. Eventually it'll be replaced by Gemma 4, but for now it keeps working exactly as before.

---

## Step 7 — Module-by-Module Screen Swap

For each existing UI screen, replace `FirebaseService.instance` with `DatabaseService.instance`. The stream API is identical, so it's a find-and-replace:

| File | Replace |
|------|---------|
| Any screen importing `firebase_service.dart` | Import `database_service.dart` instead |
| `FirebaseService.instance.watchTasks()` | `DatabaseService.instance.watchTasks()` |
| `FirebaseService.instance.watchHabits()` | `DatabaseService.instance.watchHabits()` |
| etc. | etc. |

---

## Execution Order (recommended)

1. Update pubspec.yaml, run `flutter pub get`
2. Write `schema.dart` (Drift tables)
3. Run `dart run build_runner build` to generate DAOs
4. Write `database_service.dart`
5. Update `main.dart`
6. Remove auth screens (or convert guest profile → onboarding profile)
7. Swap imports module-by-module: tasks, habits, notes, focus, mood, AI command bar, dashboard
8. Remove `firebase_service.dart` entirely (logic is fully migrated)
9. Run `flutter analyze` and fix any issues
10. Run on device to verify everything works offline

---

## Files to Create

| File | Purpose |
|------|---------|
| `lib/core/database/schema.dart` | All 11 Drift table definitions |
| `lib/core/database/database_service.dart` | Singleton service wrapping Drift DAOs |
| `lib/core/database/converters.dart` | JSON converters for subtasks, tags, etc. |

## Files to Modify

| File | Change |
|------|--------|
| `pubspec.yaml` | Swap Firebase → Drift + UUID |
| `lib/main.dart` | Remove auth gate, init DatabaseService |
| `lib/core/ai_service.dart` | Swap FirebaseService → DatabaseService |
| All screens in `lib/presentation/` | Swap FirebaseService → DatabaseService imports |

## Files to Remove

| File | Reason |
|------|--------|
| `lib/core/firebase_service.dart` | Migrated to DatabaseService |
| `lib/core/firebase_runtime_options.dart` | Firebase config helper, no longer needed |
| `lib/firebase_options.dart` | Generated Firebase config, no longer needed (Firestore removed) |
| `lib/presentation/screens/login/` | No auth |
| `lib/presentation/screens/register/` | No auth |
| `lib/presentation/shared/auth_text_field.dart` | Login form widget |
| `lib/presentation/shared/google_sign_in_button.dart` | Google sign-in |
| `lib/presentation/shared/guest_button.dart` | Guest mode button |
