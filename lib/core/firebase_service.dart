import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Singleton service for all Firestore interactions.
/// Logs user behavior events and performs CRUD on tasks/habits.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Auth ─────────────────────────────────────────────────────
  
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUp({required String email, required String password}) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signIn({required String email, required String password}) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google Sign-In error: $e');
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

  // ─────────────────────────────────────────────────────────────
  // BEHAVIOR EVENT LOGGING
  // ─────────────────────────────────────────────────────────────

  /// Logs any user interaction (tab tap, module open, etc.)
  Future<void> logEvent({
    required String eventType,
    required String module,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _eventsCol.add({
        'userId': 'uzair',
        'eventType': eventType,
        'module': module,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail — never block the UI for logging
      print('FirebaseService.logEvent error: $e');
    }
  }

  /// Fetches recent behavior events for the AI to analyze.
  Future<List<Map<String, dynamic>>> getRecentEvents({int limit = 50}) async {
    try {
      final snap = await _eventsCol
          .where('userId', isEqualTo: 'uzair')
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
  // TASKS
  // ─────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchTasks() {
    // We remove the strict orderBy here because it filters out documents with null 'createdAt' 
    // (which occurs momentarily during the optimistic local update).
    // Sorting is handled client-side for better UX.
    return _tasksCol
        .where('userId', isEqualTo: 'uzair')
        .snapshots()
        .map((snap) {
      final docs = snap.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();
      
      // Sort client-side: items without a timestamp (new ones) go to the top
      docs.sort((a, b) {
        final ta = a['createdAt'] as Timestamp?;
        final tb = b['createdAt'] as Timestamp?;
        if (ta == null) return -1;
        if (tb == null) return 1;
        return tb.compareTo(ta); // Newest first
      });
      return docs;
    });
  }

  Future<void> addTask({
    required String title,
    String priority = 'normal',
    String due = 'Today',
  }) async {
    await _tasksCol.add({
      'userId': 'uzair',
      'title': title,
      'done': false,
      'priority': priority,
      'due': due,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await logEvent(eventType: 'task_created', module: 'tasks');
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
    return _habitsCol
        .where('userId', isEqualTo: 'uzair')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
            .toList());
  }

  Future<void> addHabit({required String name, required String icon}) async {
    await _habitsCol.add({
      'userId': 'uzair',
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
    final doc = await _focusCol.add({
      'userId': 'uzair',
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

  // ─────────────────────────────────────────────────────────────
  // QUICK NOTES
  // ─────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchNotes() {
    return _notesCol
        .where('userId', isEqualTo: 'uzair')
        .snapshots()
        .map((snap) {
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
    await _notesCol.add({
      'userId': 'uzair',
      'content': content,
      'tags': tags ?? [],
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await logEvent(eventType: 'note_created', module: 'notes');
  }

  Future<void> updateNote(String noteId, String content, {List<String>? tags}) async {
    await _notesCol.doc(noteId).update({
      'content': content,
      if (tags != null) 'tags': tags,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await logEvent(eventType: 'note_updated', module: 'notes');
  }

  Future<void> deleteNote(String noteId) async {
    await _notesCol.doc(noteId).delete();
    await logEvent(eventType: 'note_deleted', module: 'notes');
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
