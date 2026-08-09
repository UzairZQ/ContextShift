import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_service.dart';

class FocusTimerState {
  final String sessionType;
  final int selectedMinutes;
  final int remainingSeconds;
  final bool isRunning;
  final String? sessionId;

  const FocusTimerState({
    required this.sessionType,
    required this.selectedMinutes,
    required this.remainingSeconds,
    required this.isRunning,
    this.sessionId,
  });

  factory FocusTimerState.initial() {
    return const FocusTimerState(
      sessionType: 'Focus',
      selectedMinutes: 25,
      remainingSeconds: 25 * 60,
      isRunning: false,
    );
  }

  bool get hasActiveSession => sessionId != null;

  FocusTimerState copyWith({
    String? sessionType,
    int? selectedMinutes,
    int? remainingSeconds,
    bool? isRunning,
    Object? sessionId = _unchanged,
  }) {
    return FocusTimerState(
      sessionType: sessionType ?? this.sessionType,
      selectedMinutes: selectedMinutes ?? this.selectedMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      sessionId: sessionId == _unchanged
          ? this.sessionId
          : sessionId as String?,
    );
  }
}

class FocusTimerController {
  FocusTimerController._();

  static final instance = FocusTimerController._();
  static const _persistedStateKey = 'focus_timer_state';

  final state = ValueNotifier<FocusTimerState>(FocusTimerState.initial());
  final _completedController = StreamController<void>.broadcast();
  Timer? _ticker;
  DateTime? _endsAt;
  bool _isCompleting = false;
  Future<void>? _restoreFuture;
  Future<void>? _startFuture;

  Stream<void> get completed => _completedController.stream;

  Future<void> restore() {
    return _restoreFuture ??= _restoreInternal().whenComplete(() {
      _restoreFuture = null;
    });
  }

  Future<void> _restoreInternal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_persistedStateKey);
      if (encoded == null || encoded.trim().isEmpty) return;

      final raw = jsonDecode(encoded);
      if (raw is! Map) {
        await prefs.remove(_persistedStateKey);
        return;
      }

      final selectedMinutes = _clampMinutes(raw['selectedMinutes']);
      final remainingSeconds = _clampSeconds(
        raw['remainingSeconds'],
        selectedMinutes,
      );
      final sessionId = raw['sessionId']?.toString();
      final isRunning = raw['isRunning'] == true && sessionId != null;
      final endsAtMillis = raw['endsAtMillis'];

      state.value = FocusTimerState(
        sessionType: raw['sessionType']?.toString() ?? 'Focus',
        selectedMinutes: selectedMinutes,
        remainingSeconds: remainingSeconds,
        isRunning: isRunning,
        sessionId: sessionId,
      );

      if (!isRunning) return;

      final parsedEndsAt = endsAtMillis is int
          ? DateTime.fromMillisecondsSinceEpoch(endsAtMillis)
          : null;
      if (parsedEndsAt == null) {
        state.value = state.value.copyWith(isRunning: false);
        await _persistState();
        return;
      }

      _endsAt = parsedEndsAt;
      _ensureTicker();
      _tick();
    } catch (error, stackTrace) {
      debugPrint('[FocusTimer] Failed to restore timer state: $error');
      debugPrintStack(stackTrace: stackTrace);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_persistedStateKey);
    }
  }

  static int activeElapsedSeconds(FocusTimerState current) {
    return (current.selectedMinutes * 60 - current.remainingSeconds).clamp(
      0,
      current.selectedMinutes * 60,
    );
  }

  static int activeElapsedMinutes(FocusTimerState current) =>
      activeElapsedSeconds(current) ~/ 60;

  void updateSession(String type, int minutes) {
    final current = state.value;
    if (current.isRunning || current.hasActiveSession) return;
    state.value = current.copyWith(
      sessionType: type,
      selectedMinutes: minutes,
      remainingSeconds: minutes * 60,
    );
  }

  Future<void> start() {
    final pending = _startFuture;
    if (pending != null) return pending;
    final future = _startInternal();
    _startFuture = future.whenComplete(() => _startFuture = null);
    return _startFuture!;
  }

  Future<void> _startInternal() async {
    final current = state.value;
    if (current.isRunning) return;
    final sessionId =
        current.sessionId ??
        await DatabaseService.instance.startFocusSession(
          durationMinutes: current.selectedMinutes,
          sessionType: current.sessionType,
        );
    _endsAt = DateTime.now().add(Duration(seconds: current.remainingSeconds));
    state.value = current.copyWith(isRunning: true, sessionId: sessionId);
    await _persistState();
    _ensureTicker();
    _tick();
  }

  void pause() {
    if (!state.value.isRunning) return;
    _tick(updateOnly: true);
    _ticker?.cancel();
    _ticker = null;
    state.value = state.value.copyWith(isRunning: false);
    unawaited(_persistState());
  }

  void reset() {
    final sessionId = state.value.sessionId;
    _ticker?.cancel();
    _ticker = null;
    _endsAt = null;
    final current = state.value;
    state.value = FocusTimerState(
      sessionType: current.sessionType,
      selectedMinutes: current.selectedMinutes,
      remainingSeconds: current.selectedMinutes * 60,
      isRunning: false,
    );
    if (sessionId != null) {
      unawaited(_cancelSession(sessionId));
    }
    unawaited(_clearPersistedState());
  }

  Future<void> _cancelSession(String sessionId) async {
    try {
      await DatabaseService.instance.cancelFocusSession(sessionId);
    } catch (error, stackTrace) {
      debugPrint('[FocusTimer] Failed to cancel reset session: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> complete() async {
    if (_isCompleting) return;
    _isCompleting = true;

    if (state.value.isRunning) {
      _tick(updateOnly: true);
    }
    _ticker?.cancel();
    _ticker = null;
    _endsAt = null;

    final current = state.value;
    final sessionId = current.sessionId;
    final actualSeconds = activeElapsedSeconds(current);
    try {
      if (sessionId != null) {
        await DatabaseService.instance.completeFocusSession(
          sessionId,
          actualSeconds: actualSeconds,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[FocusTimer] Failed to persist completed session: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      state.value = FocusTimerState(
        sessionType: current.sessionType,
        selectedMinutes: current.selectedMinutes,
        remainingSeconds: current.selectedMinutes * 60,
        isRunning: false,
      );
      await _clearPersistedState();
      _completedController.add(null);
      _isCompleting = false;
    }
  }

  void _ensureTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick({bool updateOnly = false}) {
    final endsAt = _endsAt;
    if (endsAt == null) return;
    final remaining = endsAt
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, state.value.selectedMinutes * 60);
    state.value = state.value.copyWith(remainingSeconds: remaining);
    if (remaining <= 0 && !updateOnly) {
      unawaited(complete());
    }
  }

  Future<void> _persistState() async {
    final current = state.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _persistedStateKey,
      jsonEncode({
        'sessionType': current.sessionType,
        'selectedMinutes': current.selectedMinutes,
        'remainingSeconds': current.remainingSeconds,
        'isRunning': current.isRunning,
        'sessionId': current.sessionId,
        'endsAtMillis': _endsAt?.millisecondsSinceEpoch,
      }),
    );
  }

  Future<void> _clearPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_persistedStateKey);
  }

  int _clampMinutes(Object? value) {
    final minutes = value is num ? value.round() : 25;
    return minutes.clamp(1, 24 * 60);
  }

  int _clampSeconds(Object? value, int minutes) {
    final seconds = value is num ? value.round() : minutes * 60;
    return seconds.clamp(0, minutes * 60);
  }
}

const _unchanged = Object();
