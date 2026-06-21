import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local_llm/model_downloader.dart';
import '../local_llm/model_tier.dart';

enum Feature {
  e4bInference,
  unlimitedChatHistory,
  customPersonality,
  weeklyReview,
  advancedInsights,
}

class FeatureManager {
  FeatureManager._();
  static final FeatureManager instance = FeatureManager._();

  static const _e4bPurchasedKey = 'has_purchased_e4b';

  bool _hasPurchasedE4b = false;
  bool _e4bDownloaded = false;
  bool _e2bDownloaded = false;
  bool _initialized = false;

  bool get hasPurchasedE4b => _hasPurchasedE4b;
  bool get isE4bDownloaded => _e4bDownloaded;
  bool get isE2bDownloaded => _e2bDownloaded;
  bool get isInitialized => _initialized;

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
      _initialized = true;

      debugPrint(
        '[FeatureManager] Restored state: '
        'e2b=$_e2bDownloaded, e4b=$_e4bDownloaded, '
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
  }

  void setE2bDownloaded(bool downloaded) {
    debugPrint('[FeatureManager] E2B downloaded set to: $downloaded');
    _e2bDownloaded = downloaded;
  }

  bool hasFeature(Feature feature) {
    return switch (feature) {
      Feature.e4bInference => isE4bAvailable,
      Feature.unlimitedChatHistory => isE4bAvailable,
      Feature.customPersonality => isE4bAvailable,
      Feature.weeklyReview => isE4bAvailable,
      Feature.advancedInsights => isE4bAvailable,
    };
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

  void reset() {
    _hasPurchasedE4b = false;
    _e4bDownloaded = false;
    _e2bDownloaded = false;
    _initialized = false;
    debugPrint('[FeatureManager] Reset');
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
}
