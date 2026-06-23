import 'package:flutter/services.dart';

class DeviceStorageInfo {
  final int? availableBytes;
  final int? totalBytes;

  const DeviceStorageInfo({
    required this.availableBytes,
    required this.totalBytes,
  });

  int get availableMb => ((availableBytes ?? 0) / (1024 * 1024)).round();

  int get totalMb => ((totalBytes ?? 0) / (1024 * 1024)).round();
}

class DeviceStorageService {
  DeviceStorageService._();
  static final DeviceStorageService instance = DeviceStorageService._();

  static const MethodChannel _channel = MethodChannel(
    'context_shift/device_storage',
  );

  Future<DeviceStorageInfo> getStorageInfo() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'getStorageInfo',
    );
    return DeviceStorageInfo(
      availableBytes: _asInt(result?['availableBytes']),
      totalBytes: _asInt(result?['totalBytes']),
    );
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return null;
  }
}
