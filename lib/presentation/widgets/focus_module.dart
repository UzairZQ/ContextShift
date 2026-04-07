import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../core/firebase_service.dart';

class FocusTimerModule extends StatefulWidget {
  const FocusTimerModule({super.key});

  @override
  State<FocusTimerModule> createState() => _FocusTimerModuleState();
}

class _FocusTimerModuleState extends State<FocusTimerModule>
    with SingleTickerProviderStateMixin {
  static const _presets = [15, 25, 45, 60];
  int _selectedMinutes = 25;
  late int _remainingSeconds;
  bool _isRunning = false;
  Timer? _timer;
  String? _sessionId;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _selectedMinutes * 60;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    FirebaseService.instance.logEvent(eventType: 'screen_open', module: 'focus');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _selectPreset(int minutes) {
    if (_isRunning) return;
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
    });
  }

  Future<void> _startTimer() async {
    _sessionId = await FirebaseService.instance.startFocusSession(
      durationMinutes: _selectedMinutes,
    );
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _completeSession();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    if (_sessionId != null) {
      await FirebaseService.instance.completeFocusSession(_sessionId!);
    }
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🎉 Focus session complete! Great work!'),
          backgroundColor: AppTheme.surfaceHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('Focus Timer', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 32),

        // Preset selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _presets.map((min) {
            final isSelected = min == _selectedMinutes;
            return GestureDetector(
              onTap: () => _selectPreset(min),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${min}m',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 48),

        // Timer ring
        Center(
          child: ScaleTransition(
            scale: _isRunning ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 8,
                      backgroundColor: AppTheme.surfaceHigh,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _timeDisplay,
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        _isRunning ? 'Focus mode' : 'Ready',
                        style: const TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 48),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlButton(
              icon: LucideIcons.rotateCcw,
              label: 'Reset',
              onTap: _resetTimer,
              color: Colors.white24,
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: _isRunning ? _pauseTimer : _startTimer,
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
                  _isRunning ? LucideIcons.pause : LucideIcons.play,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 20),
            _ControlButton(
              icon: LucideIcons.skipForward,
              label: 'Done',
              onTap: _completeSession,
              color: Colors.white24,
            ),
          ],
        ),
        const SizedBox(height: 40),

        // Tip
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppTheme.primary, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your AI noticed you focus best at 9AM. Sessions logged here will improve your daily layout suggestions.',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceHigh,
              border: Border.all(color: color),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
