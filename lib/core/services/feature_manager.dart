import 'package:flutter/foundation.dart';

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

  bool _hasPurchasedE4b = false;
  bool _e4bDownloaded = false;
  bool _e2bDownloaded = false;

  bool get hasPurchasedE4b => _hasPurchasedE4b;
  bool get isE4bDownloaded => _e4bDownloaded;
  bool get isE2bDownloaded => _e2bDownloaded;

  bool get isE4bAvailable => _hasPurchasedE4b && _e4bDownloaded;
  bool get isE2bAvailable => _e2bDownloaded;

  void setE4bPurchased(bool purchased) {
    debugPrint('[FeatureManager] E4B purchased set to: $purchased');
    _hasPurchasedE4b = purchased;
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
    debugPrint('[FeatureManager] Reset');
  }
}
