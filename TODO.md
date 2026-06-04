# ContextShift TODO

## On-Device LLM Integration (Future Architecture)

### Goal
Replace the FastAPI Python backend with an on-device LLM so the app works fully offline, has no server costs, and is production-ready without rented infrastructure.

---

## Three Viable Architectures Considered

### Option A: Direct Gemini from app
- Use `google_generative_ai` Flutter package. App calls Gemini directly.
- **Pro:** No server at all, 30 min to implement
- **Con:** API key is in the APK — anyone can extract it and bill your account. **Hard fail for production.**

### Option B: On-device LLM (fully offline, fully private) — CHOSEN
- Bundle a small model (Gemma 2B / Phi-3 / Llama 3.2 1B) via Google AI Edge (MediaPipe LLM Inference).
- **Pro:** No server, no API costs, works offline, max privacy
- **Con:** Adds ~500MB–1.5GB to APK, slow on low-end phones, weaker than Gemini, drains battery

### Option C: Serverless proxy (Firebase Cloud Functions)
- Use Firebase Cloud Functions as a thin proxy. App → Function → Gemini.
- **Pro:** API key lives in Google Cloud, never in the app. Auto-scales to zero when idle. Pay-per-call. Uses existing Firebase Auth.
- **Con:** Needs internet for AI features (local fallback still works offline)

### Hybrid (best of all worlds)
Keep current local parser (Tier 0) + on-device LLM (Tier 1) + optional Cloud Function proxy for richer responses (Tier 2, future).

---

## Recommended Tiered Architecture

```
User input
  ↓
[Tier 0] Local regex/keyword parser  ← instant, offline (already built)
  ↓ (no match, or needs reasoning)
[Tier 1] Gemma 3 1B (on-device)      ← <500ms, offline
  ↓ (out of scope or low confidence)
[Tier 2] Cloud Function proxy        ← future, if richer AI is needed
```

---

## On-Device LLM Options for Flutter (2026)

### Option 1: Google AI Edge (MediaPipe LLM Inference) — RECOMMENDED
- **Package:** `google_mlkit_ai_edge` (or `mediapipe` via FFI)
- **Models:** Gemma 3 1B/4B, Phi-3.5-mini, Llama 3.2
- **Pro:** Official Google, GPU/NPU accelerated, mature, great docs
- **Con:** Slightly larger APK footprint
- **Best for:** Production apps, official support

### Option 2: llama.cpp via Flutter bindings
- **Package:** `flutter_llama` or build your own FFI bindings
- **Models:** Any GGUF format (Llama, Mistral, Qwen, DeepSeek, Gemma)
- **Pro:** Massive model variety, very flexible, community-driven
- **Con:** Plugin maintenance can be spotty, you manage bindings
- **Best for:** Maximum flexibility, custom model swaps

### Option 3: MLC LLM
- **Models:** Most popular open models with mobile-optimized builds
- **Pro:** WebGPU support, very fast on modern hardware
- **Con:** More complex setup, less Flutter-native

---

## Recommended Model Tiers

| Tier | Model | Size | Min phone | Use case |
|------|-------|------|-----------|----------|
| Lite | Gemma 3 1B (Q4) | ~700MB | 4GB RAM | All devices, fast |
| Standard | Gemma 3 4B (Q4) | ~2.5GB | 6GB RAM, 2022+ | Default for most users |
| Pro | Phi-3.5-mini 3.8B | ~2.2GB | 8GB RAM, 2023+ | Best quality/size |
| Reasoning | DeepSeek-R1-Distill-Qwen-1.5B | ~1.1GB | 6GB RAM | "Think then answer" tasks |

---

## Chosen Stack

**Google AI Edge + Gemma 3 1B (default) + Gemma 3 4B (downloadable upgrade).**

Why:
- 1B runs on basically any modern Android, 700MB download
- 4B fits the app's existing personality (commands, summaries, insights)
- Download on first launch (don't bundle — keeps APK small)
- Pair with existing local pattern-matcher as Tier 0 (instant for simple commands)

---

## Implementation Plan (When Ready)

### Files to create (~6 files)
- Model loader service
- Inference service
- Model download manager
- Integration into `AiService`
- Model selection UI in settings
- Progress indicator for first-time download

### Steps
1. Add `google_mlkit_ai_edge` to `pubspec.yaml`
2. Create `lib/core/local_llm/` directory
3. Build `ModelDownloader` — downloads Gemma 3 1B on first launch, stores in app docs dir
4. Build `LocalLlmService` — loads model, exposes `generate(prompt, systemPrompt)` API
5. Refactor `AiService.processCommand` to add Tier 1: try local parser first, then on-device LLM, then (optional) cloud
6. Add settings UI to let user pick model tier (Lite / Standard / Pro) and trigger download
7. Add disk space check + battery level check before running inference
8. Add telemetry: log inference latency, model size, success rate
9. Test on low-end (4GB RAM) and high-end (12GB RAM) devices
10. Add "Premium" flag for the Pro tier as potential monetization

### Open questions to resolve later
- Bundle model vs download on first launch? (Download = smaller APK, but first-run friction)
- iOS support priority? (Google AI Edge supports both, but model binaries differ)
- Use case for "Reasoning" tier (DeepSeek-R1)? (Adds latency, useful for complex planning)
- Monetization: free with 1B only, paid 4B/Pro?
- Privacy/legal: any data leaving device? (Should be zero with pure on-device)

---

## Related Items (from this session)

### Build environment fixes (committed)
- `android/settings.gradle.kts`: AGP `8.11.1` → `8.7.3` (PostProcessingBlock circular eval bug)
- `android/gradle/wrapper/gradle-wrapper.properties`: Gradle `8.14` → `8.10.2`
- `android/gradle.properties`: added `org.gradle.java.home` pointing to Java 17 (Homebrew openjdk@17)
- `android/build.gradle.kts`: fixed build directory path `../../build` → `../build` (was resolving outside project)
- Installed: `brew install openjdk@17`

### Launcher icon config (pubspec.yaml)
- `flutter_launcher_icons: ^0.14.4` in `dev_dependencies`
- All hexcodes set to `#FF8C96` (matches `AppTheme.primary`)
- Icon path: `assets/screenshots/icon.png` (currently the default Flutter logo — needs replacement)
- Run: `dart run flutter_launcher_icons` (after replacing icon)

### Home screen bug fixed
- `HomeHeader` widget existed but was never wired into `HomeTab`
- Added it to top of scroll column in `home_tab.dart`
- Added `_handleLogout` method to `HomeScreen` (signs out + navigates to `LoginScreen`)
- `HomeHeader` hides logout button for guest users

### Backend currently running
- PID: 1790
- URL: `http://localhost:8000` (Mac) / `http://10.100.19.67:8000` (phone on same WiFi)
- Run with: `flutter run --dart-define=AI_BACKEND_URL=http://10.100.19.67:8000`
- Logs: `tail -f /tmp/contextshift_server.log`
- Stop: `kill 1790`
- **To be replaced by on-device LLM per the plan above**
