import 'package:flutter_gemma/flutter_gemma.dart';

enum ModelTier { e2b }

class ModelDefinition {
  final ModelTier tier;
  final String displayName;
  final String modelId;
  final String downloadUrl;
  final int downloadSizeMb;
  final int minRamMb;
  final bool requiresPurchase;
  final ModelType modelType;
  final ModelFileType fileType;
  final int maxTokens;

  const ModelDefinition({
    required this.tier,
    required this.displayName,
    required this.modelId,
    required this.downloadUrl,
    required this.downloadSizeMb,
    required this.minRamMb,
    required this.requiresPurchase,
    required this.modelType,
    required this.fileType,
    this.maxTokens = 2048,
  });

  String get downloadSizeFormatted {
    if (downloadSizeMb >= 1000) {
      return '${(downloadSizeMb / 1000).toStringAsFixed(1)}GB';
    }
    return '${downloadSizeMb}MB';
  }

  String get minRamFormatted {
    if (minRamMb >= 1000) {
      return '${(minRamMb / 1000).toStringAsFixed(0)}GB';
    }
    return '${minRamMb}MB';
  }

  static ModelDefinition get e2b => _e2b;

  static const ModelDefinition _e2b = ModelDefinition(
    tier: ModelTier.e2b,
    displayName: 'E2B',
    modelId: 'gemma-4-E2B-it.litertlm',
    downloadUrl:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    downloadSizeMb: 2590,
    minRamMb: 4096,
    requiresPurchase: false,
    modelType: ModelType.gemma4,
    fileType: ModelFileType.litertlm,
    maxTokens: 2048,
  );
}

enum DownloadState {
  idle,
  checkingStorage,
  downloading,
  paused,
  completed,
  failed,
}

class DownloadProgressInfo {
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final double speedBytesPerSec;
  final DownloadState state;
  final String? errorMessage;
  final String? errorDetail;
  final String? errorCode;

  const DownloadProgressInfo({
    this.progress = 0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0,
    this.state = DownloadState.idle,
    this.errorMessage,
    this.errorDetail,
    this.errorCode,
  });

  String get progressPercent => '${(progress * 100).toStringAsFixed(1)}%';

  String get speedFormatted {
    if (speedBytesPerSec < 1024) {
      return '${speedBytesPerSec.toStringAsFixed(0)} B/s';
    }
    if (speedBytesPerSec < 1024 * 1024) {
      return '${(speedBytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String get downloadedFormatted {
    if (downloadedBytes < 1024 * 1024) {
      return '${(downloadedBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(downloadedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get totalFormatted {
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get etaFormatted {
    if (speedBytesPerSec <= 0 || progress >= 1) return '';
    final remaining = (totalBytes - downloadedBytes) / speedBytesPerSec;
    if (remaining < 60) return '${remaining.toStringAsFixed(0)}s';
    if (remaining < 3600) {
      return '${(remaining / 60).toStringAsFixed(0)}m ${(remaining % 60).toStringAsFixed(0)}s';
    }
    return '${(remaining / 3600).toStringAsFixed(1)}h';
  }

  DownloadProgressInfo copyWith({
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    double? speedBytesPerSec,
    DownloadState? state,
    String? errorMessage,
    String? errorDetail,
    String? errorCode,
  }) {
    return DownloadProgressInfo(
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      errorDetail: errorDetail ?? this.errorDetail,
      errorCode: errorCode ?? this.errorCode,
    );
  }
}
