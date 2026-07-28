import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local_llm/model_downloader.dart';
import '../local_llm/model_tier.dart';

class FeatureManager {
  FeatureManager._();
  static final FeatureManager instance = FeatureManager._();

  static const _e2bVerifiedKey = 'e2b_model_health_verified';

  bool _e2bDownloaded = false;
  bool _e2bVerified = false;
  bool _initialized = false;
  bool _initializationFailed = false;
  Future<void>? _initializeFuture;
  final ValueNotifier<int> statusRevision = ValueNotifier<int>(0);

  bool get isE2bDownloaded => _e2bDownloaded;
  bool get isE2bVerified => _e2bVerified;
  bool get isE2bAvailable => _e2bDownloaded;
  bool get hasVerifiedModel => _e2bDownloaded && _e2bVerified;
  bool get hasInitializationResult => _initialized || _initializationFailed;

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initializeFuture ??= _initialize().whenComplete(() {
      _initializeFuture = null;
    });
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _e2bDownloaded = await ModelDownloader.instance.isModelDownloaded(
        ModelDefinition.e2b,
      );
      _e2bVerified =
          _e2bDownloaded && (prefs.getBool(_e2bVerifiedKey) ?? false);
      _initialized = true;
      _initializationFailed = false;

      debugPrint(
        '[FeatureManager] Restored state: '
        'e2b=$_e2bDownloaded, e2bVerified=$_e2bVerified',
      );
      _notifyStatusChanged();
    } catch (error, stackTrace) {
      _initializationFailed = true;
      _notifyStatusChanged();
      debugPrint('[FeatureManager] Initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  void setE2bDownloaded(bool downloaded) {
    debugPrint('[FeatureManager] E2B downloaded set to: $downloaded');
    _e2bDownloaded = downloaded;
    if (!downloaded) setModelVerified(ModelTier.e2b, false);
    _notifyStatusChanged();
  }

  void setModelVerified(ModelTier tier, bool verified) {
    if (tier != ModelTier.e2b) return;
    debugPrint('[FeatureManager] ${tier.name} verified set to: $verified');
    _e2bVerified = verified;
    _notifyStatusChanged();
    unawaited(_persistModelVerification(verified));
  }

  void _notifyStatusChanged() {
    statusRevision.value += 1;
  }

  bool isModelVerified(ModelTier tier) {
    return tier == ModelTier.e2b && _e2bVerified;
  }

  ModelDefinition? resolveBestModelDef() {
    return isE2bAvailable ? ModelDefinition.e2b : null;
  }

  Future<void> _persistModelVerification(bool verified) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_e2bVerifiedKey, verified);
    } catch (error, stackTrace) {
      debugPrint(
        '[FeatureManager] Failed to persist model verification state: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
