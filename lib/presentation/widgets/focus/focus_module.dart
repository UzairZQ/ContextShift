import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../../core/responsive.dart';
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
  String _sessionType = 'Focus';
  int _selectedMinutes = 25;
  late int _remainingSeconds;
  bool _isRunning = false;
  Timer? _timer;
  String? _sessionId;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _selectedMinutes * 60;
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateSession(String type, int minutes) {
    if (_isRunning) return;
    setState(() {
      _sessionType = type;
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
    });
  }

  Future<void> _startTimer() async {
    _sessionId = await DatabaseService.instance.startFocusSession(
      durationMinutes: _selectedMinutes,
    );
    _pulseController.repeat(reverse: true);
    if (mounted) setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _completeSession();
      } else {
        if (mounted) setState(() => _remainingSeconds--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.value = 0;
    if (mounted) setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.value = 0;
    if (mounted) {
      setState(() {
        _isRunning = false;
        _remainingSeconds = _selectedMinutes * 60;
      });
    }
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.value = 0;
    if (_sessionId != null) {
      await DatabaseService.instance.completeFocusSession(_sessionId!);
    }
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '🎉 Focus session complete! Great work!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String get _timeDisplay {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    final total = _selectedMinutes * 60;
    return 1.0 - (_remainingSeconds / total);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Focus Timer',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 32),

          ResponsiveWrapper(
            maxWidth: 600,
            child: Column(
              children: [
                _SessionTypeSelector(
                  selectedType: _sessionType,
                  onSelect: _updateSession,
                ),
                const SizedBox(height: 48),
                TimerRing(
                  progress: _progress,
                  timeDisplay: _timeDisplay,
                  sessionLabel: _isRunning ? _sessionType : 'Ready',
                  pulseAnimation: _isRunning
                      ? _pulseAnim
                      : const AlwaysStoppedAnimation(1.0),
                ),
                const SizedBox(height: 48),
                _TimerControls(
                  isRunning: _isRunning,
                  onReset: _resetTimer,
                  onToggle: () => _isRunning ? _pauseTimer() : _startTimer(),
                  onComplete: _completeSession,
                ),
                const SizedBox(height: 40),
                const ProductivityTip(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
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
      decoration: BoxDecoration(
        color: AppTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(24),
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
