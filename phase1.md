# Phase 1 — Model & LLM Layer

## Goal
Add `flutter_gemma`, download E2B/E4B models on-device (custom downloader, no Play Feature Delivery), create `GemmaService` wrapper, build download UX integrated into onboarding + settings, and wire basic inference into the app.

---

## Step 1 — Add Dependencies & Platform Configs

### pubspec.yaml
```yaml
flutter_gemma: ^0.16.5
genui: ^0.9.2
path_provider: ^2.1.0  # already added in Phase 0
```

Run: `flutter pub get`

### Platform Configs

**Android (`android/app/build.gradle`):**
```groovy
android {
    compileSdk 34  // minimum 34 for LiteRT-LM
    defaultConfig {
        minSdk 24
        ndk { abiFilters "arm64-v8a" }  // Gemma only supports arm64
    }
}
```

**iOS (`ios/Podfile`):**
```ruby
platform :ios, '16.0'  // minimum for LiteRT-LM
```

**Note:** macOS/Windows/Linux generated plugin registrants will auto-compile against the new deps but Gemma won't work on desktop — guard with platform checks at runtime.

---

## Step 2 — Model Definitions

File: `lib/core/local_llm/model_tier.dart`

```dart
enum ModelTier { e2b, e4b }

class ModelDefinition {
  final ModelTier tier;
  final String displayName;
  final String modelId;       // flutter_gemma model identifier
  final int downloadSizeMb;   // approximate
  final int minRamMb;         // minimum RAM required
  final bool requiresPurchase;

  static const e2b = ModelDefinition(
    tier: ModelTier.e2b,
    displayName: 'Gemma 4 E2B',
    modelId: 'gemma4-e2b',
    downloadSizeMb: 2400,
    minRamMb: 4096,
    requiresPurchase: false,
  );

  static const e4b = ModelDefinition(
    tier: ModelTier.e4b,
    displayName: 'Gemma 4 E4B',
    modelId: 'gemma4-e4b',
    downloadSizeMb: 4300,
    minRamMb: 8192,
    requiresPurchase: true,
  );

  const ModelDefinition({...});
}
```

---

## Step 3 — Model Downloader Service

File: `lib/core/local_llm/model_downloader.dart`

A custom download service since we're not using Play Feature Delivery.

### States
```dart
enum DownloadState { idle, checkingStorage, downloading, paused, completed, failed }

class DownloadProgress {
  final double progress;        // 0.0 – 1.0
  final int downloadedBytes;
  final int totalBytes;
  final double speedBytesPerSec;
  final DownloadState state;
  final String? errorMessage;
}
```

### Responsibilities
- **Storage check** — verify available space >= model size + 500MB buffer before starting
- **Download** — HTTP GET with range headers for resume support, write to app documents directory
- **Progress reporting** — stream `DownloadProgress` with real-time percentage + speed
- **Pause/Resume** — save partial download offset, resume with `Range` header
- **Integrity check** — SHA-256 hash verification after download (store expected hash in ModelDefinition)
- **Error handling**:
  - `InsufficientStorage` — show storage warning, suggest cleanup
  - `NetworkError` — retry with exponential backoff (3 attempts)
  - `CorruptDownload` — delete partial file, restart
  - `Interrupted` — resume from last offset on next app launch
- **Cleanup** — delete model files on uninstall or manual removal from settings

### File layout
```
{appDocDir}/models/
  e2b/
    model.bin          # downloaded model file
    model.sha256       # stored checksum for verification
    download.tmp       # partial download (while in progress)
  e4b/
    ...
```

### API
```dart
class ModelDownloader {
  Future<bool> hasSufficientStorage(ModelDefinition model);
  Stream<DownloadProgress> download(ModelDefinition model);
  Future<void> pause();
  Future<void> resume();
  Future<void> cancel();
  Future<bool> verifyIntegrity(ModelDefinition model);
  Future<void> deleteModel(ModelDefinition model);
  Future<bool> isModelDownloaded(ModelDefinition model);
}
```

---

## Step 4 — GemmaService

File: `lib/core/local_llm/gemma_service.dart`

Wraps `FlutterGemma` API with error handling and lifecycle management.

### API
```dart
class GemmaService {
  static final GemmaService instance = GemmaService._();

  bool _initialized = false;
  ModelTier? _activeModel;

  Future<void> init(ModelDefinition model);
  // Loads model file from disk, initializes FlutterGemma.
  // Throws on OOM, corrupt model, or incompatible device.

  Stream<String> generate(String prompt, {int maxTokens = 512, double temperature = 0.1});
  // Streams token-by-token response.
  // Timeout after 10s total.

  Future<String> generateSync(String prompt, {int maxTokens = 512, double temperature = 0.1});
  // Convenience wrapper that collects stream into a single string.
  // Used by AiService.processCommand() fallback.

  Future<void> dispose();
  // Unloads model from memory. Call before switching models or exiting.

  bool get isInitialized => _initialized;
  ModelTier? get activeModel => _activeModel;
}
```

### Error Handling
| Error | Cause | Handling |
|-------|-------|----------|
| `ModelLoadException` | OOM, corrupt file, incompatible device | Show error screen, suggest device check, fall back to local parser (Tier 0) |
| `InferenceTimeoutException` | Generation > 10s | Retry once with fewer tokens, then return fallback response |
| `ModelNotInitializedException` | generate() called before init() | Auto-init with E2B if available, else show download prompt |

### Initialization Flow
```
GemmaService.init(E2B)
  → check: is model file on disk?
    → No → throw (caller should trigger download first)
    → Yes → load into FlutterGemma
      → OOM → catch, log, suggest reboot or device upgrade
      → success → _initialized = true
```

---

## Step 5 — FeatureManager

File: `lib/core/services/feature_manager.dart`

Gates premium features behind purchase + model availability.

```dart
class FeatureManager {
  static final FeatureManager instance = FeatureManager._();

  bool get isE4bAvailable;         // purchased AND downloaded AND min RAM met
  bool get isE2bAvailable;         // downloaded AND min RAM met
  bool get hasPurchasedE4b;        // RevenueCat entitlement check
  
  Future<ModelTier> resolveBestModel();
  // Returns E4B if available, E2B if available, throws if none.
}
```

---

## Step 6 — Model Download UX

### 6a. Storage Check Screen (pre-download)

File: `lib/features/onboarding/widgets/storage_check_screen.dart`

- Shows model size vs available storage
- "Insufficient storage" warning with space-usage breakdown if < model size + buffer
- "Continue" button → starts download

### 6b. Download Progress Screen

File: `lib/features/onboarding/widgets/model_download_screen.dart`

States:
| State | UI |
|-------|----|
| `idle` | "Ready to download E2B (2.4GB)" with Start button |
| `checkingStorage` | Spinner + "Checking storage..." |
| `downloading` | Progress bar + percentage + speed + ETA + Pause button |
| `paused` | "Download paused" + Resume/Cancel buttons |
| `completed` | "Model ready!" → auto-advance to next screen |
| `failed` | Error message + Retry button + "Skip for now" link |

Props (configurable by parent):
- `ModelDefinition model` — determines size, name, whether purchase is required
- `bool isOnboarding` — if true, skip goes to home; if false (settings), skip returns to settings
- `VoidCallback onComplete` — called when download finishes

### 6c. Integration into Onboarding Flow

```
App first launch
  → OnboardingScreen (profile setup)
  → StorageCheckScreen
  → ModelDownloadScreen (E2B, required)
  → Purchase prompt (optional E4B upsell)
    → Yes → RevenueCat purchase → ModelDownloadScreen (E4B)
    → No → HomeScreen
  → HomeScreen
```

### 6d. Settings Integration

File: `lib/features/settings/widgets/model_management_tile.dart`

- Show current model (E2B / E4B / None)
- Model download size + storage used
- "Re-download model" button
- "Download E4B" button (if purchased but not downloaded)
- "Delete model" button (frees storage)

---

## Step 7 — Wire into Existing App

### AiService Integration

Update `lib/core/ai_service.dart`:
- After local regex parser (Tier 0) fails to match → route through `GemmaService.generateSync()` (Tier 1)
- Wrap with try/catch for fallback to existing local response

### Home Screen Awareness

- On app launch, if no model is downloaded:
  - Show a banner: "Download AI model for JARVIS features"
  - Or block into onboarding if first launch

---

## Files to Create

| File | Purpose |
|------|---------|
| `lib/core/local_llm/model_tier.dart` | E2B/E4B model definitions (size, RAM, ID) |
| `lib/core/local_llm/model_downloader.dart` | Custom download service with pause/resume/integrity |
| `lib/core/local_llm/gemma_service.dart` | FlutterGemma wrapper (init, generate, dispose) |
| `lib/core/services/feature_manager.dart` | Feature gating for models + premium |
| `lib/features/onboarding/widgets/storage_check_screen.dart` | Storage verification before download |
| `lib/features/onboarding/widgets/model_download_screen.dart` | Download progress with all states |
| `lib/features/onboarding/widgets/model_download_screen.dart` | (same file, integrated) |
| `lib/features/settings/widgets/model_management_tile.dart` | Settings UI for model management |
| `lib/features/onboarding/onboarding_flow.dart` | Orchestrates: profile → storage→ download → upsell → home |

## Files to Modify

| File | Change |
|------|--------|
| `pubspec.yaml` | Add flutter_gemma, genui |
| `android/app/build.gradle` | compileSdk 34, minSdk 24, arm64 ABI filter |
| `ios/Podfile` | platform :ios, '16.0' |
| `lib/core/ai_service.dart` | Route through GemmaService after local parser fails |
| `lib/main.dart` | Integrate onboarding flow with model download |
| `lib/presentation/screens/onboarding/onboarding_screen.dart` | Remove old logic, delegate to new onboarding flow |
| `lib/presentation/screens/home/home_screen.dart` | Add model-available check, show banner if missing |

---

## Step 8 — Test Plan

| Test | What to verify |
|------|---------------|
| Storage check | Shows correct available vs required space. Blocks on insufficient. |
| Download progress | 0→100% progress, speed/ETA display, pause/resume works mid-stream |
| Resume after kill | Kill app mid-download → reopen → resume from last offset |
| Integrity check | Corrupt file detected → auto re-download |
| E2B inference | GemmaService.generate() returns tokens, < 2s for short prompts |
| E4B purchase gate | FeatureManager.resolveBestModel() returns E2B before purchase, E4B after |
| Settings re-download | Delete model → re-download from settings works |
| Onboarding flow | Fresh install → profile → storage → download → home |
| Platform guard | macOS/Windows doesn't crash, shows "not supported" gracefully |
| Memory cleanup | dispose() → model unloaded, memory freed |
| OOM handling | Under 4GB device → E4B init fails gracefully with user-friendly message |

---

## Open Questions

- flutter_gemma model IDs: what are the exact modelId strings for E2B and E4B on 2026? Need to check once package is installed.
- Download URL: where do we host the model files for custom download? Or does flutter_gemma provide built-in download?
- RevenueCat: not set up yet. Phase 1 can gate E4B behind a simple local flag for development, wire real purchase in Phase 4.
- genui dependency: needed in Phase 1 just for the catalog definition, or can wait until Phase 2? Defer if not blocking.
