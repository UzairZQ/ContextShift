import 'dart:async';
import 'dart:io' show Directory, FileStat;

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

import 'model_tier.dart';

enum DownloadErrorCode {
  insufficientStorage,
  networkError,
  corruptDownload,
  modelInitFailed,
  cancelled,
  unknown,
}

class DownloadException implements Exception {
  final DownloadErrorCode code;
  final String message;
  final String? detail;
  final StackTrace? stackTrace;

  const DownloadException({
    required this.code,
    required this.message,
    this.detail,
    this.stackTrace,
  });

  @override
  String toString() {
    final buf = StringBuffer('DownloadException[$code]: $message');
    if (detail != null) buf.write('\n  Detail: $detail');
    return buf.toString();
  }
}

class ModelDownloader {
  ModelDownloader._();
  static final ModelDownloader instance = ModelDownloader._();

  CancelToken? _cancelToken;
  StreamController<DownloadProgressInfo>? _progressController;
  bool _isDownloading = false;

  bool get isDownloading => _isDownloading;

  Stream<DownloadProgressInfo> download(ModelDefinition model) {
    debugPrint('[ModelDownloader] Starting download: ${model.modelId}');
    debugPrint('[ModelDownloader]   URL: ${model.downloadUrl}');
    debugPrint('[ModelDownloader]   Size: ${model.downloadSizeFormatted}');
    debugPrint('[ModelDownloader]   Min RAM: ${model.minRamFormatted}');

    _cancelToken = CancelToken();
    _progressController = StreamController<DownloadProgressInfo>.broadcast();
    _isDownloading = true;

    _runDownload(model);

    return _progressController!.stream;
  }

  Future<void> _runDownload(ModelDefinition model) async {
    try {
      _emitProgress(const DownloadProgressInfo(
        state: DownloadState.checkingStorage,
        progress: 0,
      ));

      final hasStorage = await hasSufficientStorage(model);
      if (!hasStorage) {
        final info = await _getStorageInfo();
        throw DownloadException(
          code: DownloadErrorCode.insufficientStorage,
          message: 'Insufficient storage. Need ${model.downloadSizeFormatted} '
              'but only ${info['available']} available.',
          detail: 'Required: ${model.downloadSizeMb}MB, '
              'Available: ${info['availableMb']}MB, '
              'Total: ${info['totalMb']}MB',
        );
      }

      debugPrint('[ModelDownloader] Storage OK, starting download...');

      await FlutterGemma.installModel(
        modelType: model.modelType,
        fileType: model.fileType,
      )
          .fromNetwork(
            model.downloadUrl,
            foreground: model.downloadSizeMb > 500,
          )
          .withProgress((int progress) {
            debugPrint('[ModelDownloader] Progress: $progress%');
            _emitProgress(DownloadProgressInfo(
              state: DownloadState.downloading,
              progress: progress / 100.0,
              downloadedBytes: (model.downloadSizeMb * 1024 * 1024 * progress / 100).round(),
              totalBytes: model.downloadSizeMb * 1024 * 1024,
              speedBytesPerSec: 0,
            ));
          })
          .withCancelToken(_cancelToken!)
          .install();

      if (_cancelToken?.isCancelled ?? false) {
        debugPrint('[ModelDownloader] Download was cancelled');
        _emitProgress(const DownloadProgressInfo(
          state: DownloadState.idle,
          errorMessage: 'Download cancelled',
          errorCode: 'cancelled',
        ));
        return;
      }

      debugPrint('[ModelDownloader] Download completed successfully');
      _emitProgress(const DownloadProgressInfo(
        state: DownloadState.completed,
        progress: 1.0,
      ));
    } on DownloadCancelledException catch (e) {
      debugPrint('[ModelDownloader] Download cancelled: $e');
      _emitProgress(DownloadProgressInfo(
        state: DownloadState.idle,
        errorMessage: 'Download cancelled',
        errorDetail: e.message,
        errorCode: 'cancelled',
      ));
    } on DownloadException catch (e) {
      debugPrint('[ModelDownloader] Download error: $e');
      _emitProgress(DownloadProgressInfo(
        state: DownloadState.failed,
        errorMessage: e.message,
        errorDetail: e.detail,
        errorCode: e.code.name,
      ));
    } catch (e, stack) {
      debugPrint('[ModelDownloader] Unexpected error: $e');
      debugPrint('[ModelDownloader] Stack trace: $stack');
      _emitProgress(DownloadProgressInfo(
        state: DownloadState.failed,
        errorMessage: 'Unexpected download error',
        errorDetail: e.toString(),
        errorCode: DownloadErrorCode.unknown.name,
      ));
    } finally {
      _isDownloading = false;
      await _progressController?.close();
      _progressController = null;
    }
  }

  void pause() {
    debugPrint('[ModelDownloader] Pause requested');
    _cancelToken?.cancel('User paused download');
    _emitProgress(const DownloadProgressInfo(
      state: DownloadState.paused,
    ));
  }

  Stream<DownloadProgressInfo> resume(ModelDefinition model) {
    debugPrint('[ModelDownloader] Resume requested');
    _cancelToken = CancelToken();
    _progressController = StreamController<DownloadProgressInfo>.broadcast();
    _isDownloading = true;
    _runDownload(model);
    return _progressController!.stream;
  }

  Future<void> cancel() async {
    debugPrint('[ModelDownloader] Cancel requested');
    _cancelToken?.cancel('User cancelled download');
    _isDownloading = false;
  }

  Future<bool> hasSufficientStorage(ModelDefinition model) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      // Best-effort check: stat the parent to estimate available space
      final parentDir = Directory(directory.path);
      FileStat stat;
      try {
        stat = await parentDir.stat();
      } catch (_) {
        // Fall back to root
        stat = await Directory('/').stat();
      }
      final availableBytes = stat.size;
      final neededBytes = model.downloadSizeMb * 1024 * 1024 + (500 * 1024 * 1024);
      final hasSpace = availableBytes > neededBytes;

      debugPrint('[ModelDownloader] Storage check: '
          'available=${_formatBytes(availableBytes)}, '
          'needed=${_formatBytes(neededBytes)}, '
          'sufficient=$hasSpace');

      return hasSpace;
    } catch (e, stack) {
      debugPrint('[ModelDownloader] Storage check failed, proceeding: $e');
      debugPrint('[ModelDownloader]   Stack: $stack');
      return true;
    }
  }

  Future<Map<String, dynamic>> _getStorageInfo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stat = await directory.stat();
      final availableBytes = stat.size;
      return {
        'available': _formatBytes(availableBytes),
        'availableMb': (availableBytes / (1024 * 1024)).round(),
        'totalMb': 0,
      };
    } catch (e) {
      return {'available': 'unknown', 'availableMb': 0, 'totalMb': 0};
    }
  }

  Future<bool> isModelDownloaded(ModelDefinition model) async {
    try {
      final installed = await FlutterGemma.isModelInstalled(model.modelId);
      debugPrint('[ModelDownloader] Model "${model.modelId}" installed: $installed');
      return installed;
    } catch (e, stack) {
      debugPrint('[ModelDownloader] Error checking model installed: $e');
      debugPrint('[ModelDownloader]   Stack: $stack');
      return false;
    }
  }

  Future<void> deleteModel(ModelDefinition model) async {
    debugPrint('[ModelDownloader] Deleting model: ${model.modelId}');
    try {
      await FlutterGemma.uninstallModel(model.modelId);
      debugPrint('[ModelDownloader] Model deleted successfully');
    } catch (e, stack) {
      debugPrint('[ModelDownloader] Error deleting model: $e');
      debugPrint('[ModelDownloader]   Stack: $stack');
    }
  }

  Future<List<String>> listInstalledModels() async {
    try {
      final models = await FlutterGemma.listInstalledModels();
      debugPrint('[ModelDownloader] Installed models: $models');
      return models;
    } catch (e, stack) {
      debugPrint('[ModelDownloader] Error listing models: $e');
      debugPrint('[ModelDownloader]   Stack: $stack');
      return [];
    }
  }

  void _emitProgress(DownloadProgressInfo info) {
    _progressController?.add(info);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
