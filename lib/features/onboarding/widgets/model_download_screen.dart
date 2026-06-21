import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/app_theme.dart';
import '../../../core/local_llm/model_downloader.dart';
import '../../../core/local_llm/gemma_service.dart';
import '../../../core/local_llm/model_tier.dart';
import '../../../core/services/feature_manager.dart';

class ModelDownloadScreen extends StatefulWidget {
  final ModelDefinition model;
  final bool isOnboarding;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const ModelDownloadScreen({
    super.key,
    required this.model,
    this.isOnboarding = true,
    this.onComplete,
    this.onSkip,
  });

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  final ModelDownloader _downloader = ModelDownloader.instance;
  StreamSubscription<DownloadProgressInfo>? _subscription;

  DownloadProgressInfo _progress = const DownloadProgressInfo();
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyDownloaded();
  }

  Future<void> _checkIfAlreadyDownloaded() async {
    try {
      final downloaded = await _downloader.isModelDownloaded(widget.model);
      debugPrint(
        '[ModelDownloadScreen] Model "${widget.model.modelId}" already downloaded: $downloaded',
      );
      if (downloaded && mounted) {
        setState(() {
          _progress = const DownloadProgressInfo(
            state: DownloadState.completed,
            progress: 1.0,
          );
          _hasStarted = true;
        });
      }
    } catch (e, stack) {
      debugPrint('[ModelDownloadScreen] Error checking download status: $e');
      debugPrint('[ModelDownloadScreen]   Stack: $stack');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startDownload() {
    debugPrint('[ModelDownloadScreen] Start download pressed');
    setState(() {
      _hasStarted = true;
      _progress = const DownloadProgressInfo(
        state: DownloadState.checkingStorage,
      );
    });

    _subscription?.cancel();
    _subscription = _downloader
        .download(widget.model)
        .listen(
          _onProgress,
          onError: (error) {
            debugPrint('[ModelDownloadScreen] Stream error: $error');
          },
          onDone: () {
            debugPrint(
              '[ModelDownloadScreen] Stream done, state=${_progress.state}',
            );
          },
        );
  }

  Future<void> _onProgress(DownloadProgressInfo info) async {
    if (!mounted) return;
    debugPrint(
      '[ModelDownloadScreen] Progress: ${info.progressPercent} '
      'state=${info.state} '
      '${info.downloadedFormatted}/${info.totalFormatted}',
    );
    setState(() {
      _progress = info;
    });
    if (info.state == DownloadState.completed) {
      if (widget.model.tier == ModelTier.e2b) {
        FeatureManager.instance.setE2bDownloaded(true);
      } else {
        FeatureManager.instance.setE4bDownloaded(true);
      }
      try {
        await GemmaService.instance.loadModel(widget.model);
      } catch (error, stackTrace) {
        debugPrint('[ModelDownloadScreen] Model activation failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (!mounted) return;
        setState(() {
          _progress = DownloadProgressInfo(
            state: DownloadState.failed,
            errorMessage: 'Downloaded, but JARVIS could not start.',
            errorDetail: error.toString(),
            errorCode: 'model_activation_failed',
          );
        });
      }
    }
  }

  void _pauseDownload() {
    debugPrint('[ModelDownloadScreen] Pause requested');
    _downloader.pause();
    setState(() {});
  }

  void _resumeDownload() {
    debugPrint('[ModelDownloadScreen] Resume requested');
    setState(() {
      _progress = const DownloadProgressInfo(
        state: DownloadState.checkingStorage,
      );
    });
    _subscription?.cancel();
    _subscription = _downloader
        .resume(widget.model)
        .listen(
          _onProgress,
          onError: (error) {
            debugPrint('[ModelDownloadScreen] Resume stream error: $error');
          },
        );
  }

  void _cancelDownload() {
    debugPrint('[ModelDownloadScreen] Cancel requested');
    _subscription?.cancel();
    _downloader.cancel();
    setState(() {
      _hasStarted = false;
      _progress = const DownloadProgressInfo();
    });
  }

  void _retryDownload() {
    debugPrint('[ModelDownloadScreen] Retry requested');
    _startDownload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      color: AppTheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildIcon(),
                    const SizedBox(height: 32),
                    _buildTitle(),
                    const SizedBox(height: 12),
                    _buildSubtitle(),
                    const SizedBox(height: 40),
                    _buildProgressArea(),
                    const Spacer(flex: 2),
                    _buildBottomButtons(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (_progress.state) {
      case DownloadState.completed:
        icon = LucideIcons.checkCircle2;
        color = AppTheme.success;
      case DownloadState.failed:
        icon = LucideIcons.alertCircle;
        color = AppTheme.error;
      case DownloadState.paused:
        icon = LucideIcons.pauseCircle;
        color = AppTheme.warning;
      case DownloadState.downloading:
        icon = LucideIcons.downloadCloud;
        color = AppTheme.primary;
      case DownloadState.checkingStorage:
        icon = LucideIcons.hardDrive;
        color = AppTheme.primary;
      case DownloadState.idle:
        icon = LucideIcons.cloud;
        color = AppTheme.onSurfaceVariant;
    }

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, size: 48, color: color),
    );
  }

  Widget _buildTitle() {
    String title;
    switch (_progress.state) {
      case DownloadState.idle:
        title = 'Bring JARVIS offline';
      case DownloadState.checkingStorage:
        title = 'Making room';
      case DownloadState.downloading:
        title = 'Bringing JARVIS home';
      case DownloadState.paused:
        title = 'Download paused';
      case DownloadState.completed:
        title = 'JARVIS is ready';
      case DownloadState.failed:
        title = 'That didn\'t land';
    }
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    String subtitle;
    switch (_progress.state) {
      case DownloadState.idle:
        subtitle =
            'Download ${widget.model.displayName} once (${widget.model.downloadSizeFormatted}) '
            'and JARVIS can help without sending your thoughts to a server.';
      case DownloadState.checkingStorage:
        subtitle = 'Checking that your phone has enough space for JARVIS.';
      case DownloadState.downloading:
        subtitle =
            '${_progress.progressPercent} complete. You only need to do this once.';
      case DownloadState.paused:
        subtitle =
            '${_progress.downloadedFormatted} of ${_progress.totalFormatted} downloaded. Resume when you\'re ready.';
      case DownloadState.completed:
        subtitle =
            'Your private, on-device assistant is ready whenever you are.';
      case DownloadState.failed:
        subtitle =
            _progress.errorMessage ??
            'The download hit a snag. Let\'s try that again.';
    }
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 15,
        color: _progress.state == DownloadState.failed
            ? AppTheme.error
            : AppTheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildProgressArea() {
    if (!_hasStarted) return const SizedBox.shrink();

    return Column(
      children: [
        if (_progress.state == DownloadState.downloading ||
            _progress.state == DownloadState.paused) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress.progress,
              minHeight: 12,
              backgroundColor: AppTheme.surfaceHigh,
              valueColor: AlwaysStoppedAnimation<Color>(
                _progress.state == DownloadState.paused
                    ? AppTheme.warning
                    : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_progress.downloadedFormatted} / ${_progress.totalFormatted}',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          if (_progress.etaFormatted.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'ETA: ${_progress.etaFormatted}',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
        if (_progress.state == DownloadState.failed &&
            _progress.errorDetail != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _progress.errorDetail!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.error,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomButtons() {
    switch (_progress.state) {
      case DownloadState.idle:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _startDownload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Download JARVIS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (widget.isOnboarding) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onSkip,
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ],
        );

      case DownloadState.checkingStorage:
        return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        );

      case DownloadState.downloading:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _pauseDownload,
            icon: const Icon(LucideIcons.pause),
            label: const Text('Pause'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning.withValues(alpha: 0.2),
              foregroundColor: AppTheme.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );

      case DownloadState.paused:
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _cancelDownload,
                  icon: const Icon(LucideIcons.xCircle, size: 20),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error.withValues(alpha: 0.2),
                    foregroundColor: AppTheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _resumeDownload,
                  icon: const Icon(LucideIcons.play, size: 20),
                  label: const Text('Resume'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

      case DownloadState.completed:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: widget.onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Meet JARVIS',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        );

      case DownloadState.failed:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _retryDownload,
                icon: const Icon(LucideIcons.refreshCw, size: 20),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (widget.isOnboarding) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onSkip,
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }
}
