import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../services/device_storage_service.dart';
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
  DownloadProgressInfo _lastProgress = const DownloadProgressInfo();

  bool get isDownloading => _isDownloading;

  Stream<DownloadProgressInfo> download(ModelDefinition model) {
    if (_isDownloading) {
      throw StateError('A model download is already in progress.');
    }

    debugPrint('[ModelDownloader] Starting download: ${model.modelId}');
    debugPrint('[ModelDownloader]   URL: ${model.downloadUrl}');
    debugPrint('[ModelDownloader]   Size: ${model.downloadSizeFormatted}');
    debugPrint('[ModelDownloader]   Min RAM: ${model.minRamFormatted}');

    _cancelToken = CancelToken();
    _progressController = StreamController<DownloadProgressInfo>.broadcast();
    _isDownloading = true;
    _lastProgress = const DownloadProgressInfo();

    _runDownload(model);

    return _progressController!.stream;
  }

  Future<void> _runDownload(ModelDefinition model) async {
    try {
      _emitProgress(
        const DownloadProgressInfo(
          state: DownloadState.checkingStorage,
          progress: 0,
        ),
      );

      final hasStorage = await hasSufficientStorage(model);
      if (!hasStorage) {
        final info = await _getStorageInfo();
        throw DownloadException(
          code: DownloadErrorCode.insufficientStorage,
          message:
              'Insufficient storage. Need ${model.downloadSizeFormatted} '
              'but only ${info['available']} available.',
          detail:
              'Required: ${model.downloadSizeMb}MB, '
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
            _emitProgress(
              DownloadProgressInfo(
                state: DownloadState.downloading,
                progress: progress / 100.0,
                downloadedBytes:
                    (model.downloadSizeMb * 1024 * 1024 * progress / 100)
                        .round(),
                totalBytes: model.downloadSizeMb * 1024 * 1024,
                speedBytesPerSec: 0,
              ),
            );
          })
          .withCancelToken(_cancelToken!)
          .install();

      debugPrint('[ModelDownloader] Download completed successfully');
      _emitProgress(
        const DownloadProgressInfo(
          state: DownloadState.completed,
          progress: 1.0,
        ),
      );
    } on DownloadCancelledException catch (e, stackTrace) {
      debugPrint('[ModelDownloader] Download cancelled: $e');
      debugPrintStack(stackTrace: stackTrace);
      _emitProgress(
        _lastProgress.copyWith(
          state: DownloadState.idle,
          errorMessage: 'Download cancelled',
          errorDetail: e.message,
          errorCode: DownloadErrorCode.cancelled.name,
        ),
      );
    } on DownloadException catch (e, stackTrace) {
      debugPrint('[ModelDownloader] Download error: $e');
      debugPrintStack(stackTrace: stackTrace);
      _emitProgress(
        DownloadProgressInfo(
          state: DownloadState.failed,
          errorMessage: e.message,
          errorDetail: e.detail,
          errorCode: e.code.name,
        ),
      );
    } catch (e, stack) {
      debugPrint('[ModelDownloader] Unexpected error: $e');
      debugPrint('[ModelDownloader] Stack trace: $stack');
      _emitProgress(
        DownloadProgressInfo(
          state: DownloadState.failed,
          errorMessage: 'Unexpected download error',
          errorDetail: e.toString(),
          errorCode: DownloadErrorCode.unknown.name,
        ),
      );
    } finally {
      _isDownloading = false;
      await _progressController?.close();
      _progressController = null;
    }
  }

  Future<void> cancel() async {
    if (!_isDownloading || _cancelToken == null) return;
    debugPrint('[ModelDownloader] Cancel requested');
    _cancelToken?.cancel('User cancelled download');
  }

  Future<bool> hasSufficientStorage(ModelDefinition model) async {
    try {
      final storage = await DeviceStorageService.instance.getStorageInfo();
      final availableBytes = storage.availableBytes;
      if (availableBytes == null) {
        throw const DownloadException(
          code: DownloadErrorCode.unknown,
          message: 'Device did not report available storage.',
        );
      }

      final neededBytes = (model.downloadSizeMb + 500) * 1024 * 1024;
      final hasSpace = availableBytes > neededBytes;

      debugPrint(
        '[ModelDownloader] Storage check: '
        'available=${_formatBytes(availableBytes)}, '
        'needed=${_formatBytes(neededBytes)}, '
        'sufficient=$hasSpace',
      );

      return hasSpace;
    } catch (e, stack) {
      debugPrint(
        '[ModelDownloader] Storage check ujarvisilable; '
        'the native installer will enforce capacity: $e',
      );
      debugPrint('[ModelDownloader]   Stack: $stack');
      return true;
    }
  }

  Future<Map<String, dynamic>> _getStorageInfo() async {
    try {
      final storage = await DeviceStorageService.instance.getStorageInfo();
      final availableBytes = storage.availableBytes;
      return {
        'available': availableBytes == null
            ? 'unknown'
            : _formatBytes(availableBytes),
        'availableMb': storage.availableMb,
        'totalMb': storage.totalMb,
      };
    } catch (e, stackTrace) {
      debugPrint('[ModelDownloader] Failed to read storage details: $e');
      debugPrintStack(stackTrace: stackTrace);
      return {'available': 'unknown', 'availableMb': 0, 'totalMb': 0};
    }
  }

  Future<bool> isModelDownloaded(ModelDefinition model) async {
    try {
      final installed = await FlutterGemma.isModelInstalled(model.modelId);
      debugPrint(
        '[ModelDownloader] Model "${model.modelId}" installed: $installed',
      );
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
      rethrow;
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
    _lastProgress = info;
    final controller = _progressController;
    if (controller != null && !controller.isClosed) {
      controller.add(info);
    }
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
