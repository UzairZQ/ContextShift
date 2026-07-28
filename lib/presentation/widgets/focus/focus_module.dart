import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../../core/services/focus_timer_controller.dart';
import '../../../core/responsive.dart';
import '../motion/wonderous_motion.dart';
import '../shared/module_cards.dart';
import 'widgets/control_button.dart';
import 'widgets/productivity_tip.dart';
import 'widgets/session_chip.dart';
import 'widgets/timer_ring.dart';

class FocusTimerModule extends StatefulWidget {
  const FocusTimerModule({super.key});

  @override
  State<FocusTimerModule> createState() => _FocusTimerModuleState();
}

class _FocusTimerModuleState extends State<FocusTimerModule>
    with SingleTickerProviderStateMixin {
  final _focusTimer = FocusTimerController.instance;
  FocusTimerState _timerState = FocusTimerController.instance.state.value;
  StreamSubscription<void>? _completionSub;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _timerState = _focusTimer.state.value;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    DatabaseService.instance.logEvent(
      eventType: 'screen_open',
      module: 'focus',
    );
    _focusTimer.state.addListener(_syncTimerState);
    _completionSub = _focusTimer.completed.listen((_) {
      if (mounted) _showCompletionSnackBar();
    });
    _syncPulse();
  }

  @override
  void dispose() {
    _focusTimer.state.removeListener(_syncTimerState);
    _completionSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _syncTimerState() {
    if (!mounted) return;
    setState(() => _timerState = _focusTimer.state.value);
    _syncPulse();
  }

  void _syncPulse() {
    if (_timerState.isRunning) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  void _updateSession(String type, int minutes) {
    _focusTimer.updateSession(type, minutes);
  }

  Future<void> _startTimer() async {
    try {
      await _focusTimer.start();
    } catch (error, stackTrace) {
      debugPrint('[FocusTimerModule] Start failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start focus. Try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _pauseTimer() {
    _focusTimer.pause();
  }

  void _resetTimer() {
    _focusTimer.reset();
  }

  Future<void> _completeSession() async {
    await _focusTimer.complete();
  }

  void _showCompletionSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              LucideIcons.timerReset,
              color: AppTheme.primary,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Focus session complete. Great work.',
                style: Theme.of(context).snackBarTheme.contentTextStyle,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceHigh.withValues(alpha: 0.96),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 112),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.28)),
        ),
      ),
    );
  }

  String get _timeDisplay {
    final m = (_timerState.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_timerState.remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    final total = _timerState.selectedMinutes * 60;
    if (total == 0) return 0;
    return 1.0 - (_timerState.remainingSeconds / total);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          WonderousReveal(
            child: const ModuleHeaderCard(
              title: 'Focus Timer',
              subtitle: 'One session, one clear next step.',
              icon: LucideIcons.timer,
              accent: AppTheme.tertiary,
            ),
          ),
          const SizedBox(height: 16),

          ResponsiveWrapper(
            maxWidth: 600,
            child: ModuleCard(
              accent: AppTheme.tertiary,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                children: [
                  WonderousReveal(
                    child: _SessionTypeSelector(
                      selectedType: _timerState.sessionType,
                      onSelect: _updateSession,
                    ),
                  ),
                  const SizedBox(height: 48),
                  WonderousReveal(
                    delay: const Duration(milliseconds: 80),
                    child: TimerRing(
                      progress: _progress,
                      timeDisplay: _timeDisplay,
                      sessionLabel: _timerState.isRunning
                          ? _timerState.sessionType
                          : 'Ready',
                      pulseAnimation: _timerState.isRunning
                          ? _pulseAnim
                          : const AlwaysStoppedAnimation(1.0),
                    ),
                  ),
                  const SizedBox(height: 48),
                  WonderousReveal(
                    delay: const Duration(milliseconds: 140),
                    child: _TimerControls(
                      isRunning: _timerState.isRunning,
                      onReset: _resetTimer,
                      onToggle: () =>
                          _timerState.isRunning ? _pauseTimer() : _startTimer(),
                      onComplete: _completeSession,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const WonderousReveal(
                    delay: Duration(milliseconds: 200),
                    child: ProductivityTip(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _SessionTypeSelector extends StatelessWidget {
  final String selectedType;
  final void Function(String type, int minutes) onSelect;

  const _SessionTypeSelector({
    required this.selectedType,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: moduleCardDecoration(
        accent: AppTheme.tertiary,
        borderRadius: 24,
        fill: AppTheme.surfaceHigh,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SessionChip(
            label: 'Focus',
            minutes: 25,
            icon: LucideIcons.brain,
            isSelected: selectedType == 'Focus',
            onTap: () => onSelect('Focus', 25),
          ),
          SessionChip(
            label: 'Short Break',
            minutes: 5,
            icon: LucideIcons.coffee,
            isSelected: selectedType == 'Short Break',
            onTap: () => onSelect('Short Break', 5),
          ),
          SessionChip(
            label: 'Long Break',
            minutes: 15,
            icon: LucideIcons.batteryCharging,
            isSelected: selectedType == 'Long Break',
            onTap: () => onSelect('Long Break', 15),
          ),
        ],
      ),
    );
  }
}

class _TimerControls extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onReset;
  final VoidCallback onToggle;
  final VoidCallback onComplete;

  const _TimerControls({
    required this.isRunning,
    required this.onReset,
    required this.onToggle,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ControlButton(
          icon: LucideIcons.rotateCcw,
          label: 'Reset',
          onTap: onReset,
          color: Colors.white24,
        ),
        const SizedBox(width: 20),
        _PlayPauseButton(isRunning: isRunning, onTap: onToggle),
        const SizedBox(width: 20),
        ControlButton(
          icon: LucideIcons.skipForward,
          label: 'Done',
          onTap: onComplete,
          color: Colors.white24,
        ),
      ],
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onTap;

  const _PlayPauseButton({required this.isRunning, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: isRunning ? 'Pause timer' : 'Start timer',
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            isRunning ? LucideIcons.pause : LucideIcons.play,
            color: AppTheme.onSurface,
            size: 28,
          ),
        ),
      ),
    );
  }
}
