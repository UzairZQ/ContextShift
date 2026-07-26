import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/app_spacing.dart';
import '../../../core/app_theme.dart';

/// Full-screen voice capture with a live, amplitude-driven waveform.
///
/// Returns the final transcript when the user confirms, or null when the
/// sheet is dismissed. The caller decides what to do with the text
/// (ContextShift hands it to the JARVIS chat screen).
class VoiceInputOverlay {
  VoiceInputOverlay._();

  static Future<String?> show(BuildContext context) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Voice input',
      barrierColor: Colors.transparent,
      transitionDuration: Motion.normal,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return const _VoiceInputSheet();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Motion.smoothEnter,
          reverseCurve: Motion.smoothExit,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _VoiceInputSheet extends StatefulWidget {
  const _VoiceInputSheet();

  @override
  State<_VoiceInputSheet> createState() => _VoiceInputSheetState();
}

enum _VoicePhase { starting, listening, paused, unavailable }

class _VoiceInputSheetState extends State<_VoiceInputSheet>
    with SingleTickerProviderStateMixin {
  static const int _barCount = 36;

  final stt.SpeechToText _speech = stt.SpeechToText();
  late final AnimationController _ticker;
  final List<double> _levels = List.filled(_barCount, 0);

  _VoicePhase _phase = _VoicePhase.starting;
  String _transcript = '';
  double _liveLevel = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addListener(_advanceWave);
    _ticker.repeat();
    unawaited(_start());
  }

  @override
  void dispose() {
    _ticker.dispose();
    unawaited(_speech.stop());
    super.dispose();
  }

  void _advanceWave() {
    // Scroll the ring buffer left and append the newest smoothed level, so
    // the waveform drifts like a live oscilloscope.
    final idle = _phase == _VoicePhase.listening ? 0.06 : 0.02;
    final jitter = math.Random().nextDouble() * 0.03;
    final next = (_liveLevel * 0.92) + idle + jitter;
    _levels
      ..removeAt(0)
      ..add(next.clamp(0.0, 1.0));
    _liveLevel *= 0.86;
    if (mounted) setState(() {});
  }

  Future<void> _start() async {
    try {
      final available = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        options: [
          stt.SpeechToText.androidNoBluetooth,
          stt.SpeechToText.iosNoBluetooth,
        ],
      );
      if (!mounted) return;
      if (!available) {
        setState(() => _phase = _VoicePhase.unavailable);
        return;
      }
      await _listen();
    } catch (error, stackTrace) {
      debugPrint('[VoiceInput] init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _phase = _VoicePhase.unavailable);
    }
  }

  Future<void> _listen() async {
    await _speech.listen(
      onResult: _handleResult,
      onSoundLevelChange: _handleSoundLevel,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        autoPunctuation: true,
        enableHapticFeedback: true,
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(minutes: 2),
        cancelOnError: true,
      ),
    );
    if (!mounted) return;
    setState(() => _phase = _VoicePhase.listening);
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() => _transcript = result.recognizedWords.trim());
  }

  void _handleSoundLevel(double level) {
    // iOS reports roughly -50..10 dB, Android 0..10. Normalize both.
    final normalized = level < 0 ? (level + 50) / 60 : level / 10;
    _liveLevel = math.max(_liveLevel, normalized.clamp(0.0, 1.0));
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint('[VoiceInput] error: $error');
    if (!mounted) return;
    if (error.permanent || error.errorMsg == 'error_permission') {
      setState(() => _phase = _VoicePhase.unavailable);
    } else {
      setState(() => _phase = _VoicePhase.paused);
    }
  }

  void _handleStatus(String status) {
    if (!mounted) return;
    if (status == stt.SpeechToText.notListeningStatus ||
        status == stt.SpeechToText.doneStatus) {
      if (_phase == _VoicePhase.listening) {
        setState(() => _phase = _VoicePhase.paused);
      }
    }
  }

  Future<void> _resume() async {
    setState(() => _phase = _VoicePhase.starting);
    await _listen();
  }

  Future<void> _finish() async {
    if (_closing) return;
    _closing = true;
    await _speech.stop();
    if (!mounted) return;
    Navigator.of(context).pop(_transcript.trim().isEmpty ? null : _transcript);
  }

  Future<void> _cancel() async {
    if (_closing) return;
    _closing = true;
    await _speech.stop();
    if (!mounted) return;
    Navigator.of(context).pop(null);
  }

  String get _statusLabel {
    return switch (_phase) {
      _VoicePhase.starting => 'Starting the mic...',
      _VoicePhase.listening => 'Listening',
      _VoicePhase.paused => 'Paused — tap the mic to continue',
      _VoicePhase.unavailable => 'Voice input is unavailable on this device',
    };
  }

  @override
  Widget build(BuildContext context) {
    final hasTranscript = _transcript.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.4),
              radius: 1.2,
              colors: [
                AppTheme.primary.withValues(alpha: 0.10),
                AppTheme.background.withValues(alpha: 0.94),
                AppTheme.background,
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xxl),
              child: Column(
                children: [
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.audioLines,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: Spacing.sm),
                      Text(
                        'Talk to JARVIS',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _cancel,
                        icon: const Icon(LucideIcons.x, size: 20),
                        color: AppTheme.onSurfaceVariant,
                        tooltip: 'Cancel',
                      ),
                    ],
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: SingleChildScrollView(
                        reverse: true,
                        child: Text(
                          hasTranscript ? _transcript : 'Say anything...',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: hasTranscript
                                    ? AppTheme.onSurface
                                    : AppTheme.onSurfaceVariant.withValues(
                                        alpha: 0.4,
                                      ),
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  SizedBox(
                    height: 84,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _WaveformPainter(
                        levels: _levels,
                        color: _phase == _VoicePhase.listening
                            ? AppTheme.primary
                            : AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    _statusLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _phase == _VoicePhase.unavailable
                          ? AppTheme.warning
                          : AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: Spacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoundAction(
                        icon: LucideIcons.x,
                        label: 'Cancel',
                        onTap: _cancel,
                      ),
                      const SizedBox(width: Spacing.xl),
                      _MicOrb(
                        isLive: _phase == _VoicePhase.listening,
                        level: _levels.last,
                        onTap: _phase == _VoicePhase.listening
                            ? _finish
                            : _resume,
                      ),
                      const SizedBox(width: Spacing.xl),
                      _RoundAction(
                        icon: LucideIcons.arrowUp,
                        label: 'To chat',
                        emphasized: hasTranscript,
                        onTap: hasTranscript ? _finish : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.section),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MicOrb extends StatelessWidget {
  final bool isLive;
  final double level;
  final VoidCallback onTap;

  const _MicOrb({required this.isLive, required this.level, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final glow = 0.22 + (level * 0.5);
    return Semantics(
      label: isLive ? 'Stop and review' : 'Resume listening',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isLive ? AppTheme.primaryGradient : null,
            color: isLive ? null : AppTheme.surfaceHighest,
            border: Border.all(
              color: isLive
                  ? Colors.white.withValues(alpha: 0.22)
                  : AppTheme.primary.withValues(alpha: 0.34),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: isLive ? glow : 0.12),
                blurRadius: 44,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            isLive ? LucideIcons.audioLines : LucideIcons.mic,
            size: 30,
            color: isLive ? AppTheme.background : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;
  final VoidCallback? onTap;

  const _RoundAction({
    required this.icon,
    required this.label,
    this.emphasized = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      label: label,
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Motion.fast,
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: emphasized
                    ? AppTheme.primary.withValues(alpha: 0.16)
                    : AppTheme.surfaceHigh.withValues(alpha: 0.8),
                border: Border.all(
                  color: emphasized
                      ? AppTheme.primary.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Icon(
                icon,
                size: 21,
                color: !enabled
                    ? AppTheme.onSurfaceVariant.withValues(alpha: 0.35)
                    : emphasized
                    ? AppTheme.primary
                    : AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.onSurfaceVariant.withValues(
                  alpha: enabled ? 0.8 : 0.4,
                ),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> levels;
  final Color color;

  const _WaveformPainter({required this.levels, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;
    final barWidth = size.width / (levels.length * 1.7);
    final gap = (size.width - (barWidth * levels.length)) / (levels.length - 1);
    final centerY = size.height / 2;

    for (var i = 0; i < levels.length; i++) {
      // Emphasize the center of the strip so it reads as a voice, not noise.
      final centerBias =
          1 - ((i - levels.length / 2).abs() / (levels.length / 2)) * 0.45;
      final magnitude = (levels[i] * centerBias).clamp(0.02, 1.0);
      final barHeight = math.max(3.0, magnitude * size.height);
      final x = i * (barWidth + gap) + barWidth / 2;
      final paint = Paint()
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.35 + magnitude * 0.65);
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}
