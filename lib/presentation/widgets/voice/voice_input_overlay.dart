import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/app_spacing.dart';
import '../../../core/app_theme.dart';
import '../../screens/chat/dictation_text.dart';

class VoiceInputOverlay {
  VoiceInputOverlay._();

  static Future<String?> show(BuildContext context, {String initialText = ''}) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Voice input',
      barrierColor: AppTheme.background,
      transitionDuration: reduceMotion ? Duration.zero : Motion.fast,
      pageBuilder: (_, _, _) => _VoiceInputView(initialText: initialText),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }
}

enum _VoicePhase { starting, listening, paused, unavailable }

class _VoiceInputView extends StatefulWidget {
  const _VoiceInputView({required this.initialText});

  final String initialText;

  @override
  State<_VoiceInputView> createState() => _VoiceInputViewState();
}

class _VoiceInputViewState extends State<_VoiceInputView> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ValueNotifier<double> _level = ValueNotifier<double>(0);
  late final DictationTranscript _transcript;

  _VoicePhase _phase = _VoicePhase.starting;
  bool _speechReady = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _transcript = DictationTranscript(widget.initialText);
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _level.dispose();
    unawaited(_speech.stop());
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _speechReady = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
        options: [
          stt.SpeechToText.androidNoBluetooth,
          stt.SpeechToText.iosNoBluetooth,
        ],
      );
      if (!mounted) return;
      if (!_speechReady) {
        setState(() => _phase = _VoicePhase.unavailable);
        return;
      }
      await _listen();
    } catch (error, stackTrace) {
      debugPrint('[VoiceInput] Initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _phase = _VoicePhase.unavailable);
    }
  }

  Future<void> _listen() async {
    if (!_speechReady || _closing) return;
    if (mounted) setState(() => _phase = _VoicePhase.starting);
    try {
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
      if (mounted && !_closing) {
        setState(() => _phase = _VoicePhase.listening);
      }
    } catch (error, stackTrace) {
      debugPrint('[VoiceInput] Listening failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _phase = _VoicePhase.paused);
    }
  }

  void _handleResult(SpeechRecognitionResult result) {
    if (!mounted || _closing) return;
    _transcript.update(result.recognizedWords, isFinal: result.finalResult);
    setState(() {});
  }

  void _handleSoundLevel(double level) {
    if (_closing) return;
    final normalized = level < 0 ? (level + 50) / 60 : level / 10;
    _level.value = normalized.clamp(0.0, 1.0);
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint('[VoiceInput] Recognition error: $error');
    if (!mounted || _closing) return;
    _transcript.commitSession();
    setState(() {
      _phase = error.permanent || error.errorMsg == 'error_permission'
          ? _VoicePhase.unavailable
          : _VoicePhase.paused;
    });
  }

  void _handleStatus(String status) {
    if (!mounted || _closing) return;
    final ended =
        status == stt.SpeechToText.notListeningStatus ||
        status == stt.SpeechToText.doneStatus;
    if (ended && _phase == _VoicePhase.listening) {
      _transcript.commitSession();
      _level.value = 0;
      setState(() => _phase = _VoicePhase.paused);
    }
  }

  Future<void> _pause() async {
    _transcript.commitSession();
    await _speech.stop();
    _level.value = 0;
    if (mounted && !_closing) setState(() => _phase = _VoicePhase.paused);
  }

  Future<void> _finish() async {
    if (_closing || _transcript.isEmpty) return;
    _closing = true;
    _transcript.commitSession();
    await _speech.stop();
    if (!mounted) return;
    Navigator.of(context).pop(_transcript.text);
  }

  Future<void> _cancel() async {
    if (_closing) return;
    _closing = true;
    await _speech.stop();
    if (mounted) Navigator.of(context).pop();
  }

  String get _statusLabel => switch (_phase) {
    _VoicePhase.starting => 'Starting microphone',
    _VoicePhase.listening => 'Listening',
    _VoicePhase.paused => 'Paused',
    _VoicePhase.unavailable => 'Voice input unavailable',
  };

  @override
  Widget build(BuildContext context) {
    final transcript = _transcript.text;
    final hasTranscript = transcript.isNotEmpty;
    final listening = _phase == _VoicePhase.listening;

    return Material(
      color: AppTheme.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.xxl,
            Spacing.sm,
            Spacing.xxl,
            Spacing.xxl,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.audioLines,
                    size: 19,
                    color: AppTheme.intelligence,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    'Talk to JARVIS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _cancel,
                    tooltip: 'Cancel',
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: Spacing.xxl),
                    child: Text(
                      hasTranscript ? transcript : 'Say anything...',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: hasTranscript
                                ? AppTheme.onSurface
                                : AppTheme.onSurfaceVariant.withValues(
                                    alpha: 0.45,
                                  ),
                            fontSize: _transcriptSize(transcript.length),
                            height: 1.32,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _level,
                builder: (_, level, _) =>
                    _VoiceBars(level: listening ? level : 0, active: listening),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                _statusLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _phase == _VoicePhase.unavailable
                      ? AppTheme.warning
                      : AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: _phase == _VoicePhase.unavailable
                        ? null
                        : listening
                        ? _pause
                        : _listen,
                    tooltip: listening ? 'Pause dictation' : 'Resume dictation',
                    icon: Icon(listening ? LucideIcons.pause : LucideIcons.mic),
                  ),
                  const SizedBox(width: Spacing.md),
                  FilledButton.icon(
                    onPressed: hasTranscript ? _finish : null,
                    icon: const Icon(LucideIcons.arrowUp, size: 18),
                    label: const Text('Use in chat'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _transcriptSize(int length) {
    if (length <= 90) return 26;
    if (length <= 220) return 22;
    if (length <= 420) return 19;
    return 17;
  }
}

class _VoiceBars extends StatelessWidget {
  const _VoiceBars({required this.level, required this.active});

  final double level;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const weights = [0.38, 0.68, 1.0, 0.76, 0.48];
    return Semantics(
      label: active ? 'Microphone level' : 'Microphone paused',
      child: SizedBox(
        height: 54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: weights
              .map((weight) {
                final height = 8 + (38 * level * weight);
                return AnimatedContainer(
                  duration: Motion.micro,
                  curve: Curves.easeOut,
                  width: 5,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color:
                        (active
                                ? AppTheme.intelligence
                                : AppTheme.onSurfaceVariant)
                            .withValues(alpha: active ? 0.85 : 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}
