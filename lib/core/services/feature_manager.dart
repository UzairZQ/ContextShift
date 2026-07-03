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

  bool get isE2bDownloaded => _e2bDownloaded;
  bool get isE2bVerified => _e2bVerified;
  bool get isE2bAvailable => _e2bDownloaded;
  bool get hasVerifiedModel => _e2bDownloaded && _e2bVerified;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _e2bDownloaded = await ModelDownloader.instance.isModelDownloaded(
        ModelDefinition.e2b,
      );
      _e2bVerified =
          _e2bDownloaded && (prefs.getBool(_e2bVerifiedKey) ?? false);
      _initialized = true;

      debugPrint(
        '[FeatureManager] Restored state: '
        'e2b=$_e2bDownloaded, e2bVerified=$_e2bVerified',
      );
    } catch (error, stackTrace) {
      debugPrint('[FeatureManager] Initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  void setE2bDownloaded(bool downloaded) {
    debugPrint('[FeatureManager] E2B downloaded set to: $downloaded');
    _e2bDownloaded = downloaded;
    if (!downloaded) setModelVerified(ModelTier.e2b, false);
  }

  void setModelVerified(ModelTier tier, bool verified) {
    debugPrint('[FeatureManager] ${tier.name} verified set to: $verified');
    _e2bVerified = verified;
    unawaited(_persistModelVerification(verified));
  }

  bool isModelVerified(ModelTier tier) => _e2bVerified;

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
