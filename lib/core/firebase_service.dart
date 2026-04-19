import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Singleton service for all Firestore interactions.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Auth ─────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String? get currentUserId => _auth.currentUser?.uid;
  String get currentUserName => _auth.currentUser?.displayName ?? "Traveler";
  String get firstName => currentUserName.split(' ').first;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      debugPrint('Firebase: Attempting sign up for $email...');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        debugPrint('Firebase: User created. Updating display name to $name...');
        await credential.user!.updateDisplayName(name);
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error Code: ${e.code}');
      throw _handleAuthError(e);
    } catch (e, stack) {
      debugPrint('Unexpected Error during SignUp: $e');
      debugPrint('Stacktrace: $stack');
      throw 'An unexpected error occurred. Please check your console.';
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      default:
        return e.message ?? 'An internal error occurred.';
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Collections ─────────────────────────────────────────────
  CollectionReference get _tasksCol => _db.collection('tasks');
  CollectionReference get _habitsCol => _db.collection('habits');
  CollectionReference get _eventsCol => _db.collection('behavior_events');
  CollectionReference get _focusCol => _db.collection('focus_sessions');
  CollectionReference get _notesCol => _db.collection('notes');
  CollectionReference get _moodCol => _db.collection('mood_entries');
  CollectionReference get _aiCommandsCol => _db.collection('ai_commands');

  // ─────────────────────────────────────────────────────────────
  // BEHAVIOR EVENT LOGGING
  // ─────────────────────────────────────────────────────────────

  Future<void> logEvent({
    required String eventType,
    required String module,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _eventsCol.add({
        'userId': uid,
        'eventType': eventType,
        'module': module,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail — never block the UI for logging
      debugPrint('FirebaseService.logEvent error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentEvents({int limit = 50}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    try {
      final snap = await _eventsCol
          .where('userId', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TARGETED GENUI CONTEXT SNAPSHOT
  // ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> buildContextSnapshot() async {
    final uid = currentUserId;
    if (uid == null) return {};
    try {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 1. Get 3 Pending Tasks
      final tSnap = await _tasksCol
          .where('userId', isEqualTo: uid)
          .where('done', isEqualTo: false)
          .limit(3)
          .get();
      final topTasks = tSnap.docs.map((d) => (d.data() as Map<String, dynamic>)['title']).toList();

      // 2. Get Missing Habits Today
      final hSnap = await _habitsCol.where('userId', isEqualTo: uid).get();
      final missingHabits = <String>[];
      for (var d in hSnap.docs) {
        final data = d.data() as Map<String, dynamic>;
        final completed = (data['completedDates'] as List<dynamic>?) ?? [];
        if (!completed.contains(todayStr)) {
          missingHabits.add(data['name'] as String);
        }
      }

      // 3. Get 1 Recent Note
      final nSnap = await _notesCol
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      final recentNote = nSnap.docs.isNotEmpty
          ? (nSnap.docs.first.data() as Map<String, dynamic>)['content']
          : null;

      return {
        'top_tasks': topTasks,
        'missing_habits': missingHabits.take(3).toList(),
        'recent_note': recentNote,
      };
    } catch (e) {
      debugPrint('Error building context snapshot: $e');
      return {};
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TASKS
  // ─────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchTasks() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _tasksCol.where('userId', isEqualTo: uid).snapshots().map((snap) {
      final docs = snap.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();

      docs.sort((a, b) {
        final ta = a['createdAt'] as Timestamp?;
        final tb = b['createdAt'] as Timestamp?;
        if (ta == null) return -1;
        if (tb == null) return 1;
        return tb.compareTo(ta);
      });
      return docs;
    });
  }

  Future<void> addTask({
    required String title,
    String priority = 'normal',
    String due = 'Today',
    List<Map<String, dynamic>> subtasks = const [],
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _tasksCol.add({
      'userId': uid,
      'title': title,
      'done': false,
      'priority': priority,
      'due': due,
      'subtasks': subtasks,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await logEvent(eventType: 'task_created', module: 'tasks');
  }

  Future<void> updateTask(
    String taskId,
    Map<String, dynamic> updates,
  ) async {
    await _tasksCol.doc(taskId).update(updates);
  }

  Future<void> toggleTask(String taskId, bool isDone) async {
    await _tasksCol.doc(taskId).update({'done': isDone});
    await logEvent(
      eventType: isDone ? 'task_completed' : 'task_uncompleted',
      module: 'tasks',
    );
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksCol.doc(taskId).delete();
    await logEvent(eventType: 'task_deleted', module: 'tasks');
  }

  // ─────────────────────────────────────────────────────────────
  // HABITS
  // ─────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchHabits() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _habitsCol.where('userId', isEqualTo: uid).snapshots().map(
          (snap) => snap.docs
              .map(
                  (d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
              .toList(),
        );
  }

  Future<void> addHabit({required String name, required String icon}) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _habitsCol.add({
      'userId': uid,
      'name': name,
      'icon': icon,
      'completedDates': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await logEvent(eventType: 'habit_created', module: 'habits');
  }

  Future<void> toggleHabitToday(String habitId, bool isDone) async {
    final today = _todayString();
    if (isDone) {
      await _habitsCol.doc(habitId).update({
        'completedDates': FieldValue.arrayUnion([today]),
      });
    } else {
      await _habitsCol.doc(habitId).update({
        'completedDates': FieldValue.arrayRemove([today]),
      });
    }
    await logEvent(
      eventType: isDone ? 'habit_completed' : 'habit_uncompleted',
      module: 'habits',
      metadata: {'habitId': habitId, 'date': today},
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FOCUS SESSIONS
  // ─────────────────────────────────────────────────────────────

  Future<String> startFocusSession({int durationMinutes = 25}) async {
    final uid = currentUserId;
    if (uid == null) throw 'User not authenticated';

    final doc = await _focusCol.add({
      'userId': uid,
      'durationMinutes': durationMinutes,
      'startedAt': FieldValue.serverTimestamp(),
      'completedAt': null,
      'completed': false,
    });
    await logEvent(
      eventType: 'focus_started',
      module: 'focus',
      metadata: {'duration': durationMinutes},
    );
    return doc.id;
  }

  Future<void> completeFocusSession(String sessionId) async {
    await _focusCol.doc(sessionId).update({
      'completedAt': FieldValue.serverTimestamp(),
      'completed': true,
    });
    await logEvent(eventType: 'focus_completed', module: 'focus');
  }

  /// Get total focus minutes completed today
  Future<int> getTodayFocusMinutes() async {
    final uid = currentUserId;
    if (uid == null) return 0;

    try {
      final snap = await _focusCol
          .where('userId', isEqualTo: uid)
          .where('completed', isEqualTo: true)
          .get();

      final today = _todayString();
      int total = 0;
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final completedAt = data['completedAt'] as Timestamp?;
        if (completedAt != null) {
          final d = completedAt.toDate();
          final dateStr =
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          if (dateStr == today) {
            total += (data['durationMinutes'] as int?) ?? 0;
          }
        }
      }
      return total;
    } catch (e) {
      debugPrint('getTodayFocusMinutes error: $e');
      return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // QUICK NOTES
  // ─────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchNotes() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _notesCol.where('userId', isEqualTo: uid).snapshots().map((snap) {
      final docs = snap.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();
      docs.sort((a, b) {
        final ta = a['updatedAt'] as Timestamp?;
        final tb = b['updatedAt'] as Timestamp?;
        if (ta == null) return -1;
        if (tb == null) return 1;
        return tb.compareTo(ta);
      });
      return docs;
    });
  }

  Future<void> addNote({required String content, List<String>? tags}) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _notesCol.add({
      'userId': uid,
      'content': content,
      'tags': tags ?? [],
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await logEvent(eventType: 'note_created', module: 'notes');
  }

  Future<void> deleteNote(String noteId) async {
    await _notesCol.doc(noteId).delete();
    await logEvent(eventType: 'note_deleted', module: 'notes');
  }

  Future<void> updateNote(
    String noteId,
    String content, {
    List<String>? tags,
    String? summary,
  }) async {
    await _notesCol.doc(noteId).update({
      'content': content,
      if (tags != null) 'tags': tags,
      if (summary != null) 'summary': summary,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await logEvent(eventType: 'note_updated', module: 'notes');
  }

  // ─────────────────────────────────────────────────────────────
  // MOOD TRACKING
  // ─────────────────────────────────────────────────────────────

  Future<void> saveMood(String mood) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _moodCol.add({
      'userId': uid,
      'mood': mood,
      'date': _todayString(),
      'timestamp': FieldValue.serverTimestamp(),
    });
    await logEvent(
      eventType: 'mood_logged',
      module: 'mood',
      metadata: {'mood': mood},
    );
  }

  Future<String?> getTodayMood() async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final today = _todayString();
      final snap = await _moodCol
          .where('userId', isEqualTo: uid)
          .where('date', isEqualTo: today)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        return (snap.docs.first.data() as Map<String, dynamic>)['mood']
            as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> watchMoods({int days = 14}) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _moodCol
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(days)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
            .toList());
  }

  // ─────────────────────────────────────────────────────────────
  // AI COMMAND HISTORY
  // ─────────────────────────────────────────────────────────────

  Future<void> saveAiCommand({
    required String command,
    required String response,
    List<Map<String, dynamic>>? actions,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _aiCommandsCol.add({
      'userId': uid,
      'command': command,
      'response': response,
      'actions': actions ?? [],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchAiCommands({int limit = 20}) {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _aiCommandsCol
        .where('userId', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
            .toList());
  }

  // ─────────────────────────────────────────────────────────────
  // STREAK CALCULATION
  // ─────────────────────────────────────────────────────────────

  /// Compute the current streak (consecutive days with at least 1 habit done)
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
      final dayStr =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      if (allDates.contains(dayStr)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Helpers ───────────────────────────────────────────────

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
