import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  bool _isInitializing = false;
  bool _isHealthChecking = false;
  bool _isDeleting = false;
  bool _healthCheckPassed = false;
  String? _statusDetail;

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
          _healthCheckPassed = GemmaService.instance.isModelLoaded;
          _statusDetail = GemmaService.instance.isModelLoaded
              ? 'JARVIS is initialized on this device.'
              : 'Downloaded. Initialize JARVIS before using chat.';
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
      setState(() {
        _healthCheckPassed = false;
        _statusDetail = 'Downloaded. Initialize JARVIS before using chat.';
      });
    }
  }

  Future<void> _initializeModel() async {
    if (_isInitializing) return;
    debugPrint('[ModelDownloadScreen] Initialize requested');
    setState(() {
      _isInitializing = true;
      _statusDetail = 'Initializing local model...';
    });
    try {
      await GemmaService.instance.loadModel(widget.model);
      if (!mounted) return;
      setState(() {
        _healthCheckPassed = false;
        _statusDetail = 'Initialized. Run health check to verify responses.';
      });
    } catch (error, stackTrace) {
      debugPrint('[ModelDownloadScreen] Model initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _statusDetail = error.toString();
      });
      _showSnack('JARVIS could not initialize.');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  Future<void> _runHealthCheck() async {
    if (_isHealthChecking) return;
    debugPrint('[ModelDownloadScreen] Health check requested');
    setState(() {
      _isHealthChecking = true;
      _statusDetail = 'Sending a tiny test prompt to JARVIS...';
    });
    try {
      final response = await GemmaService.instance.runHealthCheck(widget.model);
      if (!mounted) return;
      setState(() {
        _healthCheckPassed = true;
        _statusDetail = 'Health check passed. Response: $response';
      });
      _showSnack('JARVIS health check passed.');
    } catch (error, stackTrace) {
      debugPrint('[ModelDownloadScreen] Health check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _healthCheckPassed = false;
        _statusDetail = error.toString();
      });
      _showSnack('JARVIS health check failed.');
    } finally {
      if (mounted) setState(() => _isHealthChecking = false);
    }
  }

  Future<void> _deleteModel() async {
    if (_isDeleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceHigh,
        title: const Text('Delete JARVIS model?'),
        content: Text(
          'This removes ${widget.model.displayName} from this device. '
          'You can download it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    debugPrint('[ModelDownloadScreen] Delete requested');
    setState(() {
      _isDeleting = true;
      _statusDetail = 'Deleting local model...';
    });
    try {
      await GemmaService.instance.disposeModel();
      await _downloader.deleteModel(widget.model);
      if (widget.model.tier == ModelTier.e2b) {
        FeatureManager.instance.setE2bDownloaded(false);
      } else {
        FeatureManager.instance.setE4bDownloaded(false);
      }
      if (!mounted) return;
      setState(() {
        _progress = const DownloadProgressInfo();
        _hasStarted = false;
        _healthCheckPassed = false;
        _statusDetail = 'Model deleted from this device.';
      });
      _showSnack('JARVIS model deleted.');
    } catch (error, stackTrace) {
      debugPrint('[ModelDownloadScreen] Delete failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _statusDetail = error.toString());
      _showSnack('Could not delete model.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    _buildIcon(),
                    const SizedBox(height: 32),
                    _buildTitle(),
                    const SizedBox(height: 12),
                    _buildSubtitle(),
                    const SizedBox(height: 40),
                    _buildProgressArea(),
                    const SizedBox(height: 40),
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

    if (_isInitializing || _isHealthChecking || _isDeleting) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    switch (_progress.state) {
      case DownloadState.completed:
        icon = _healthCheckPassed ? LucideIcons.checkCircle2 : LucideIcons.cpu;
        color = _healthCheckPassed ? AppTheme.success : AppTheme.warning;
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
    if (_isInitializing) {
      title = 'Initializing JARVIS';
    } else if (_isHealthChecking) {
      title = 'Checking JARVIS';
    } else if (_isDeleting) {
      title = 'Deleting model';
    } else {
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
          title = _healthCheckPassed
              ? 'JARVIS is ready'
              : 'JARVIS is downloaded';
        case DownloadState.failed:
          title = 'That didn\'t land';
      }
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
    if (_isInitializing) {
      subtitle =
          'Activating the downloaded model and preparing the local chat session.';
    } else if (_isHealthChecking) {
      subtitle = 'Running a tiny prompt to verify the model can respond.';
    } else if (_isDeleting) {
      subtitle = 'Removing the local model and clearing active state.';
    } else {
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
          subtitle = _healthCheckPassed
              ? 'Your private, on-device assistant passed its health check.'
              : 'The file is on your phone. Initialize and health-check it before using JARVIS.';
        case DownloadState.failed:
          subtitle =
              _progress.errorMessage ??
              'The download hit a snag. Let\'s try that again.';
      }
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
    if (!_hasStarted && _statusDetail == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (_statusDetail != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_healthCheckPassed ? AppTheme.success : AppTheme.warning)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    (_healthCheckPassed ? AppTheme.success : AppTheme.warning)
                        .withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              _statusDetail!,
              style: TextStyle(
                fontSize: 12,
                color: _healthCheckPassed
                    ? AppTheme.success
                    : AppTheme.onSurfaceVariant,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
        ],
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
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isInitializing || _isHealthChecking
                    ? null
                    : _initializeModel,
                icon: const Icon(LucideIcons.power, size: 20),
                label: Text(
                  GemmaService.instance.isModelLoaded
                      ? 'Re-initialize JARVIS'
                      : 'Initialize JARVIS',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isInitializing || _isHealthChecking
                    ? null
                    : _runHealthCheck,
                icon: const Icon(LucideIcons.activity, size: 20),
                label: const Text('Run health check'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _healthCheckPassed
                      ? AppTheme.success
                      : AppTheme.warning.withValues(alpha: 0.22),
                  foregroundColor: _healthCheckPassed
                      ? Colors.black
                      : AppTheme.warning,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (widget.onComplete != null && _healthCheckPassed) ...[
              const SizedBox(height: 12),
              SizedBox(
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
              ),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _isDeleting ? null : _deleteModel,
              icon: const Icon(LucideIcons.trash2, size: 18),
              label: const Text('Delete model'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            ),
          ],
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
