import 'dart:async';

import 'package:flutter/foundation.dart';

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

  final state = ValueNotifier<FocusTimerState>(FocusTimerState.initial());
  final _completedController = StreamController<void>.broadcast();
  Timer? _ticker;
  DateTime? _endsAt;
  bool _isCompleting = false;

  Stream<void> get completed => _completedController.stream;

  void updateSession(String type, int minutes) {
    final current = state.value;
    if (current.isRunning || current.hasActiveSession) return;
    state.value = current.copyWith(
      sessionType: type,
      selectedMinutes: minutes,
      remainingSeconds: minutes * 60,
    );
  }

  Future<void> start() async {
    final current = state.value;
    if (current.isRunning) return;
    final sessionId =
        current.sessionId ??
        await DatabaseService.instance.startFocusSession(
          durationMinutes: current.selectedMinutes,
        );
    _endsAt = DateTime.now().add(Duration(seconds: current.remainingSeconds));
    state.value = current.copyWith(isRunning: true, sessionId: sessionId);
    _ensureTicker();
    _tick();
  }

  void pause() {
    if (!state.value.isRunning) return;
    _tick(updateOnly: true);
    _ticker?.cancel();
    _ticker = null;
    state.value = state.value.copyWith(isRunning: false);
  }

  void reset() {
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
  }

  Future<void> complete() async {
    if (_isCompleting) return;
    _isCompleting = true;
    _ticker?.cancel();
    _ticker = null;
    _endsAt = null;

    final current = state.value;
    final sessionId = current.sessionId;
    if (sessionId != null) {
      await DatabaseService.instance.completeFocusSession(sessionId);
    }

    state.value = FocusTimerState(
      sessionType: current.sessionType,
      selectedMinutes: current.selectedMinutes,
      remainingSeconds: current.selectedMinutes * 60,
      isRunning: false,
    );
    _completedController.add(null);
    _isCompleting = false;
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
}

const _unchanged = Object();
