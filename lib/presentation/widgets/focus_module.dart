import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/app_theme.dart';
import '../../core/firebase_service.dart';
import '../../core/responsive.dart';

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
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
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

  void _updateSession(String type, int minutes) {
    if (_isRunning) return;
    setState(() {
      _sessionType = type;
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
    });
  }

  Future<void> _startTimer() async {
    _sessionId = await FirebaseService.instance.startFocusSession(
      durationMinutes: _selectedMinutes,
    );
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
    if (mounted) setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isRunning = false;
        _remainingSeconds = _selectedMinutes * 60;
      });
    }
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    if (_sessionId != null) {
      await FirebaseService.instance.completeFocusSession(_sessionId!);
    }
    if (mounted) {
      setState(() {
        _isRunning = false;
        _remainingSeconds = _selectedMinutes * 60;
      });
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Focus Timer', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 32),
    
          ResponsiveWrapper(
            maxWidth: 600,
            child: Column(
              children: [
                // Session Type Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceHigh,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSessionChip('Focus', 25, LucideIcons.brain),
                      _buildSessionChip('Short Break', 5, LucideIcons.coffee),
                      _buildSessionChip('Long Break', 15, LucideIcons.batteryCharging),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
    
                // Timer ring
                LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.maxWidth * 0.7;
                    final cappedSize = size.clamp(200.0, 320.0);
                    
                    return Center(
                      child: ScaleTransition(
                        scale: _isRunning ? _pulseAnim : const AlwaysStoppedAnimation(1.0),
                        child: SizedBox(
                          width: cappedSize,
                          height: cappedSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: _progress,
                                  strokeWidth: Responsive.isMobile(context) ? 8 : 12,
                                  backgroundColor: AppTheme.surfaceHigh,
                                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _timeDisplay,
                                    style: TextStyle(
                                      fontSize: cappedSize * 0.25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  Text(
                                    _isRunning ? _sessionType : 'Ready',
                                    style: TextStyle(color: Colors.white38, fontSize: cappedSize * 0.06),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                _buildProductivityTip(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityTip() {
    final hour = DateTime.now().hour;
    String tip;
    if (hour < 11) {
      tip = 'Early sessions have 20% higher completion rates. Your flow is strongest now.';
    } else if (hour < 17) {
      tip = 'The afternoon slump is real. Consider a 5-minute movement break between sessions.';
    } else {
      tip = 'Deep work before bed can affect sleep. Aim for one final "Review" session.';
    }

    return Container(
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
              tip,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionChip(String type, int minutes, IconData icon) {
    final isSelected = _sessionType == type;
    return GestureDetector(
      onTap: () => _updateSession(type, minutes),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white38),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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
