import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local_llm/model_downloader.dart';
import '../local_llm/model_tier.dart';

class FeatureManager {
  FeatureManager._();
  static final FeatureManager instance = FeatureManager._();

  static const _e4bPurchasedKey = 'has_purchased_e4b';
  static const _e2bVerifiedKey = 'e2b_model_health_verified';
  static const _e4bVerifiedKey = 'e4b_model_health_verified';

  bool _hasPurchasedE4b = false;
  bool _e4bDownloaded = false;
  bool _e2bDownloaded = false;
  bool _e2bVerified = false;
  bool _e4bVerified = false;
  bool _initialized = false;

  bool get hasPurchasedE4b => _hasPurchasedE4b;
  bool get isE4bDownloaded => _e4bDownloaded;
  bool get isE2bDownloaded => _e2bDownloaded;
  bool get isE4bVerified => _e4bVerified;
  bool get isE2bVerified => _e2bVerified;
  bool get isE4bAvailable => _hasPurchasedE4b && _e4bDownloaded;
  bool get isE2bAvailable => _e2bDownloaded;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final installed = await Future.wait([
        ModelDownloader.instance.isModelDownloaded(ModelDefinition.e2b),
        ModelDownloader.instance.isModelDownloaded(ModelDefinition.e4b),
      ]);

      _hasPurchasedE4b = prefs.getBool(_e4bPurchasedKey) ?? false;
      _e2bDownloaded = installed[0];
      _e4bDownloaded = installed[1];
      _e2bVerified =
          _e2bDownloaded && (prefs.getBool(_e2bVerifiedKey) ?? false);
      _e4bVerified =
          _e4bDownloaded && (prefs.getBool(_e4bVerifiedKey) ?? false);
      _initialized = true;

      debugPrint(
        '[FeatureManager] Restored state: '
        'e2b=$_e2bDownloaded, e4b=$_e4bDownloaded, '
        'e2bVerified=$_e2bVerified, e4bVerified=$_e4bVerified, '
        'e4bPurchased=$_hasPurchasedE4b',
      );
    } catch (error, stackTrace) {
      debugPrint('[FeatureManager] Initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  void setE4bPurchased(bool purchased) {
    debugPrint('[FeatureManager] E4B purchased set to: $purchased');
    _hasPurchasedE4b = purchased;
    unawaited(_persistE4bPurchase(purchased));
  }

  void setE4bDownloaded(bool downloaded) {
    debugPrint('[FeatureManager] E4B downloaded set to: $downloaded');
    _e4bDownloaded = downloaded;
    if (!downloaded) setModelVerified(ModelTier.e4b, false);
  }

  void setE2bDownloaded(bool downloaded) {
    debugPrint('[FeatureManager] E2B downloaded set to: $downloaded');
    _e2bDownloaded = downloaded;
    if (!downloaded) setModelVerified(ModelTier.e2b, false);
  }

  void setModelVerified(ModelTier tier, bool verified) {
    debugPrint('[FeatureManager] ${tier.name} verified set to: $verified');
    switch (tier) {
      case ModelTier.e2b:
        _e2bVerified = verified;
        unawaited(_persistModelVerification(_e2bVerifiedKey, verified));
      case ModelTier.e4b:
        _e4bVerified = verified;
        unawaited(_persistModelVerification(_e4bVerifiedKey, verified));
    }
  }

  bool isModelVerified(ModelTier tier) {
    return switch (tier) {
      ModelTier.e2b => _e2bVerified,
      ModelTier.e4b => _e4bVerified,
    };
  }

  bool get hasVerifiedModel {
    final tier = resolveBestModel();
    return tier != null && isModelVerified(tier);
  }

  ModelTier? resolveBestModel() {
    if (isE4bAvailable) return ModelTier.e4b;
    if (isE2bAvailable) return ModelTier.e2b;
    return null;
  }

  ModelDefinition? resolveBestModelDef() {
    final tier = resolveBestModel();
    if (tier == null) return null;
    return ModelDefinition.fromTier(tier);
  }

  Future<void> _persistE4bPurchase(bool purchased) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_e4bPurchasedKey, purchased);
    } catch (error, stackTrace) {
      debugPrint('[FeatureManager] Failed to persist purchase state: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _persistModelVerification(String key, bool verified) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, verified);
    } catch (error, stackTrace) {
      debugPrint(
        '[FeatureManager] Failed to persist model verification state: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
