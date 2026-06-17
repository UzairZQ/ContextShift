# ContextShift TODO

## Core Architecture you 

### Goal
Replace the FastAPI Python backend with on-device Gemma 4 via `flutter_gemma`. Build a chat UI with **Jarvis** (AI friend) using **GenUI** for dynamic, prompt-driven UI. Feed local user data from **Drift (SQLite)** (recent chats, preferences, app state) as context to make Jarvis personalized. Fully offline — no Firebase, no server, no GDPR issues. Monetize via $14.99 one-time purchase gating the E4B model + premium features.

---

## ✅ Selected Stack

| Component | Choice | Why |
|-----------|--------|-----|
| On-device LLM | `flutter_gemma: ^0.16.5` + Gemma 4 | Wraps LiteRT-LM natively. Cross-platform, GPU/NPU, function calling, thinking mode, embeddings, RAG. Zero server costs |
| Free tier | Gemma 4 E2B (~2.4GB) | Runs on 4GB RAM, multimodal (text+image+audio), native function calling |
| Paid ($5/mo) | Gemma 4 E4B (~4.3GB) | Smarter reasoning + all premium features |
| Dynamic UI | `genui: ^0.9.2` | Official Flutter GenUI SDK (A2UI protocol). AI generates live Flutter widgets from a Catalog. Powers Jarvis chat + dynamic cards |
| Local database | **Drift (SQLite)** | Stores chat history, mood entries, user preferences, app state. Fully offline — no server, no GDPR risk |
| OTA prompts | Bundled in assets or single JSON URL fetch | Remote Config alternative without Firebase — ship Jarvis prompts in app, optional CDN fetch for updates |
| Purchases | RevenueCat (or similar) | Manages $14.99 one-time purchase, gates E4B model download + premium features |

`flutter_gemma` bundles LiteRT-LM (powers Gemini Nano in Chrome/Pixel Watch). `genui` is the official Flutter GenUI SDK (BSD-3-Clause, experimental alpha).

---

## Tiered Architecture

```
User input
  ↓
[Tier 0] Local regex/keyword parser  ← instant, offline (already built)
  ↓ (no match, or needs reasoning)
[Tier 1] Gemma 4 via flutter_gemma   ← on-device, offline, zero server cost
  ↓
[Tier 2] GenUI layer                 ← Jarvis renders dynamic widgets from catalog
         ↓
[Context] Drift DB (SQLite)          ← recent chats, user prefs, app state fed as prompt
```

---

## GenUI — Full Flutter Freedom for Jarvis

GenUI (`genui` v0.9.2) lets the AI generate live Flutter widgets from a **Catalog**. Jarvis has complete freedom to compose any UI by using a generic Flutter widget catalog with recursive children.

### Principle

Instead of pre-defining "a card" or "a chart" as a single catalog item, we give Jarvis **Flutter's building blocks** — layout + display + interactive primitives — with recursive children. Jarvis composes them arbitrarily to fit the user's request.

### Generic Widget Catalog (~20 items, all the AI needs)

**Layout widgets** (supports `child: Widget` or `children: [Widget]` for infinite nesting):

| Catalog item | Maps to | Purpose |
|-------------|---------|---------|
| `Container` | `Container` | Box with padding, margin, decoration, color, border radius |
| `Row` | `Row` | Horizontal layout (children) |
| `Column` | `Column` | Vertical layout (children) |
| `Stack` | `Stack` | Overlapping children (positioned) |
| `Padding` | `Padding` | Adds padding around a child |
| `Center` | `Center` | Centers a child |
| `SizedBox` | `SizedBox` | Fixed width/height box |
| `Expanded` | `Expanded` | Takes remaining space in Row/Column |
| `Card` | `Material Card` | Elevated card with shadow |
| `List` | `ListView` | Scrollable list of items |

**Display widgets** (leaf nodes):

| Catalog item | Maps to | Purpose |
|-------------|---------|---------|
| `Text` | `Text` | Styled text (headline, body, caption, etc.) |
| `Image` | `Image.network` | Remote image |
| `Icon` | `Icon` | Material icon by name |
| `Divider` | `Divider` | Horizontal separator |
| `Spacer` | `Spacer` | Flexible space in Row/Column |

**Interactive widgets** (user input → DataModel binding → loop back to AI):

| Catalog item | Maps to | Behavior |
|-------------|---------|----------|
| `Button` | `ElevatedButton` / `OutlinedButton` | Emits event to AI on tap |
| `TextField` | `TextField` | Binds to DataModel path |
| `Slider` | `Slider` | Binds to DataModel path |
| `Switch` | `Switch` | Binds to DataModel path |
| `Dropdown` | `DropdownButton` | Binds to DataModel path |
| `DatePicker` | `showDatePicker` | Returns date to DataModel |

### How Recursive Composition Works

Jarvis generates A2UI JSON that nests widgets arbitrarily. Example — user says *"show me a summary of my week with a mood graph and let me toggle between weeks"*:

```json
{
  "Card": {
    "elevation": 2,
    "child": {
      "Column": {
        "children": [
          {"Text": {"text": "Your Week", "style": "headline"}},
          {"Divider": {}},
          {"Container": {
            "height": 200,
            "decoration": {"borderRadius": 8},
            "child": {"Image": {"url": "https://...mood_chart.png", "fit": "contain"}}
          }},
          {"Row": {
            "children": [
              {"Text": {"text": "Filter:"}},
              {"Dropdown": {"options": ["Week 1", "Week 2", "Week 3"], "path": "/filter/week"}},
              {"Button": {"label": "Apply", "event": "filter_chart"}}
            ]
          }}
        ]
      }
    }
  }
}
```

Jarvis built a card with a chart, a filter dropdown, and a button — all from generic primitives. No custom "ChartCard" catalog item needed.

### DataModel Binding

Interactive widgets bind to paths in the `DataModel` (`/filter/week`). When the user changes the dropdown, the DataModel updates. On button press, the updated DataModel state is sent back to Jarvis as context for the next turn — creating a high-bandwidth loop.

### Why This Approach Wins

- **No UI limits** — Jarvis can render any layout Flutter supports
- **No catalog bloat** — 20 generic items cover 99% of use cases
- **Future-proof** — new user requests don't require code changes
- **Full Flutter power** — animations, gestures, material theming all work naturally since the output is real Flutter widgets

### Two Use Cases

### 1. Dynamic Cards
User says anything like *"show a card comparing my mood vs sleep this month"* — Jarvis composes Container + Row + Image + Text + Button on the fly.

### 2. Jarvis Chat Screen
Dedicated chat where Jarvis responds with any combination of text + interactive widgets — forms, sliders, pickers, lists, buttons — all generated dynamically based on conversation context.

---

## Context Layer — How Jarvis Knows the User (Fully Local)

### Architecture

```
User sends message to Jarvis
        ↓
[ContextProvider] assembles prompt in 3 parts:
  1. System instruction template (bundled asset or CDN JSON) — Jarvis's base personality + behavior
  2. Dynamic context (Drift DB) — real user data queried locally at runtime
  3. User's current message
        ↓
[Gemma 4] receives: system prompt + context + user message
        ↓
[GenUI] renders response with interactive widgets
        ↓
Response saved to Drift (chat history) for next interaction
```

### Data model (Drift schema)

```
UserPreferences (single row)
  └─ responseStyle (funny/serious/balanced), premiumPurchased (bool), onboardingDone (bool)

Conversations
  ├─ id (int, auto), title (text), createdAt (datetime), updatedAt (datetime)
  └─ Messages
       └─ id (int, auto), conversationId (FK), role (text: user/jarvis),
          content (text), widgetJson (text? optional), createdAt (datetime)

MoodEntries
  └─ id (int, auto), date (datetime, unique per day), score (int 1-10),
     note (text?), tags (text — JSON array), createdAt (datetime)
```

### What goes in the context

| Source | Where stored | What's included |
|--------|-------------|-----------------|
| Base system prompt | **Bundled asset** (`assets/prompts/jarvis_base.txt`) | Jarvis's personality, rules, tone. Can also fetch from CDN URL for OTA updates |
| Recent chats | **Drift — Messages table** | Last 10 messages — gives Jarvis memory of the conversation |
| User preferences | **Drift — UserPreferences** | Topics they like, response style (funny vs serious), favorite activities |
| App state | **Drift — computed from MoodEntries** | Today's entries, current streak, recent mood trend — queried at runtime |
| On-demand data | **Drift — MoodEntries query** | Gemma 4 function calling lets Jarvis request specific data (e.g. "show me last week's mood chart") via a Dart callback that queries Drift |

### Why fully offline is better

- **No GDPR issues** — all data stays on the device. No consent banners, no DPA, no deletion API
- **No server costs** — no Firebase bills. Drift is free, Gemma is free, the app runs fully offline
- **Faster** — SQLite queries are local, no network latency for context assembly
- **Works offline** — literally everything works on a plane. Jarvis has full context without internet
- **Token efficient** — curated context, not a dump. Jarvis uses function calling to request more on demand
- **OTA prompt updates** — ship prompt asset in updates, or optionally fetch a single URL on app launch

### Model Delivery — Play Feature Delivery (E2B) + Custom Download (E4B)
- E2B and E4B are **not bundled** in the APK — delivered as on-demand asset packs
- **E2B**: Uses **Play Feature Delivery** (on-demand asset pack) — Google Play manages the download with native progress UI, pause/resume, defer-to-WiFi. No custom downloader needed. The asset pack ships as part of the app listing on Play Store but is installed on demand.
- **Flow**: Install from Play Store → App opens → Google Play installs E2B asset pack (managed download dialog) → Model ready → Initialize app
- **E4B**: Custom download via `FlutterGemma.installModel()` after RevenueCat purchase confirmation. Cannot use Play Feature Delivery since it's gated behind payment.
- E2B download is free and required before using the app (gated behind first-launch onboarding)
- E4B download only triggers after RevenueCat confirms purchase — no purchase, no download
- Benefits: small APK size, no Play Store 150MB APK limit, native Google Play download UX with zero custom code for E2B

### Files
- `lib/core/database/database.dart` — Drift database definition (tables, DAOs, migrations)
- `lib/core/database/schema.dart` — all table definitions (UserPreferences, Conversations, Messages, MoodEntries)
- `lib/core/genui/context_provider.dart` — orchestrates: load system prompt → query Drift → assemble context → pass to Gemma
- `lib/core/genui/prompt_builder.dart` — builds the final prompt string from template + user context

---

## Revenue & Pricing Analysis

### Current App Positioning
ContextShift is a **context-recovery OS** — not a to-do list. Tasks, habits, focus, notes, mood, and JARVIS integrated around "get me back on track." The differentiation is real vs. single-purpose apps.

### Comparable Pricing

| App | Price | What you get |
|-----|-------|-------------|
| Day One | $35/yr | Journal with sync |
| Todoist | $48/yr | Task manager with AI |
| Notion AI | $120/yr | Docs + AI |
| Mood trackers | $5-10 one-time | Basic check-ins |
| **ContextShift** | **$14.99 one-time** | **AI that knows your context + builds UI on demand + fully offline** |

### Recommendation
- **Launch at $14.99** — low barrier, converts well
- **Long-term two-tier**:
  - Free: E2B, basic chat, limited history
  - Premium **$29.99 one-time** or **$3.99/mo**: E4B, unlimited history, custom Jarvis personality, advanced insights, weekly AI review, priority support
- **Why premium can be higher**: Your cost per user = $0 (on-device). Users who value deep, private AI assistance will pay more. Don't compete with $3 mood trackers — compete with $120/yr Notion AI.

### Rough Revenue
- 10,000 free users → ~3-5% convert → 300-500 premium sales
- At $14.99 = $4,500-$7,500
- At $29.99 = $9,000-$15,000

---

## Monetization — $14.99 One-Time Purchase

| Tier | Model | Perks | Price |
|------|-------|-------|-------|
| Free | Gemma 4 E2B | Basic AI, offline chat, standard cards, limited history | $0 |
| Premium | Gemma 4 E4B | Smarter reasoning, unlimited history, custom Jarvis personality, weekly AI review, advanced insights | $14.99 |

Why one-time: Gemma 4 runs entirely on-device — zero server costs per user. A subscription feels unjustified when the user carries the cost (download + storage + compute). $14.99 one-time converts better and matches the app's personal nature.

### Future tier option
If cloud sync is added later, introduce **$3.99/mo** on top (one-time buyers keep their perks + discounted sync). Launch with one-time only.

---

## Gemma 4's Full Power — What Makes This Brilliant in 2026

### Core Philosophy: JARVIS Is Not a Chatbot — It's the App
The command bar is the home screen. Tasks, habits, notes, focus timer — they're not separate modules. They're things JARVIS creates and manages through GenUI. The user talks to JARVIS, and everything else follows.

### 1. Multimodal Input (Gemma 4's Superpower)
Gemma 4 E2B/E4B supports text + image + audio natively:

| Input | What JARVIS can do |
|-------|--------------------|
| Screenshot of busy screen | "14 tabs open, 2 Slack notifications, calendar in 10 min — here's what to focus on" |
| Voice memo | "I recorded my thoughts — summarize and save as a note" |
| Photo of whiteboard | "Extract these ideas into tasks and habits" |
| Mood selfie | "You look tired — your sleep has been 5h avg. Want a wind-down reminder?" |

No other productivity app does this. Instant differentiator.

### 2. Thinking Mode + Function Calling = True Autonomy
Gemma 4 reasons step-by-step then acts:

```
User: "I'm overwhelmed, help me reset"
JARVIS thinks:
  1. Check recent tasks: 4 overdue
  2. Check mood: 😰 for 3 days
  3. Check focus sessions: 0 today
JARVIS calls: createTask("Pick 3 priorities"), createFocusSession(25)
GenUI renders: Reset card with reprioritized tasks + Start Focus button
```

All on-device, zero latency, zero cost.

### 3. Proactive Awareness via On-Device RAG
Gemma 4 supports embeddings + semantic search over Drift data:

```
User: "What was I struggling with last Tuesday?"
JARVIS queries Drift:
  → Mood: 😢 "stuck on project planning"
  → Notes: "Frustrated with unclear requirements"  
  → Tasks: "Define MVP scope" (still undone)
Renders: "You were stuck on project scope. It's still open. Break into 3 smaller tasks?"
```

### 4. Weekly JARVIS Review (The Premium Hook)
Fully on-device, personalized weekly report:
- Mood trends + correlations ("You're happiest on days you exercise")
- Task completion patterns
- Focus session effectiveness
- Conversational review — talk to JARVIS about your week
- **This alone justifies premium pricing**

### 5. Dynamic Daily Briefing
Every app open, JARVIS generates a unique brief via GenUI:
- Top 3 tasks for today (learned from behavior)
- Mood check-in prompt
- One insight from last week
- Habit streak or warning
- Different layout every time — never static

### 6. Customizable Personality
System prompt in assets means:
- "Make JARVIS more direct / casual / humorous"
- "Speak like a stoic philosopher"
- Different personas for work vs personal time
- Future premium feature: personality packs

### One-Sentence Pitch
**"ContextShift is an AI that rebuilds your productivity dashboard in real time based on how you're feeling and what you need — entirely on your phone, entirely private, entirely yours."**

---

## Design Consistency — MUST FOLLOW

All new screens and widgets must be **visually indistinguishable** from the existing app. Do not change:

- **Theme** — colors (`AppTheme.primary` = `#FF8C96`, existing surface/background/text colors)
- **Typography** — font families, sizes, weights, line heights used throughout the app
- **Spacing** — existing padding, margin, gap patterns
- **Component styles** — button shapes, input fields, cards, dividers, all match current codebase
- **Animations** — duration, curves, transitions consistent with existing patterns
- **Dark mode** — any new screens must support the existing dark theme

Check existing screens (`lib/features/`) and theme config (`lib/core/theme/`) before building anything new. When adding GenUI catalog items, make sure all generated widgets use `Theme.of(context)` so they inherit the app's design system automatically.

## Implementation Plan

### Files to create (~10 files)

**LLM Layer:**
- `lib/core/local_llm/gemma_service.dart` — wraps `FlutterGemma` API
- `lib/core/local_llm/model_downloader.dart` — download/install/delete models
- `lib/core/local_llm/model_tier.dart` — E2B vs E4B definitions

**Database Layer:**
- `lib/core/database/database.dart` — Drift database class + DAOs
- `lib/core/database/schema.dart` — table definitions (UserPreferences, Conversations, Messages, MoodEntries)

**GenUI Layer:**
- `lib/core/genui/catalog.dart` — generic Flutter widget catalog (~20 items: Container, Row, Column, Text, Button, Slider, etc.)
- `lib/core/genui/context_provider.dart` — orchestrates: load system prompt → query Drift → assemble context → pass to Gemma
- `lib/core/genui/prompt_builder.dart` — builds final prompt string from template + Drift context
- `lib/features/chat/screens/chat_screen.dart` — Jarvis chat screen with GenUI Conversation + Surface rendering

**Monetization:**
- `lib/core/services/purchase_manager.dart` — RevenueCat IAP, checks entitlement
- `lib/core/services/feature_manager.dart` — gates E4B + premium features

**UI:**
- `lib/features/settings/widgets/premium_tile.dart` — show plan, trigger purchase
- `lib/features/onboarding/widgets/model_download_screen.dart` — first-launch download

### Steps
1. `flutter pub add flutter_gemma genui drift` 
2. Set up Drift — define schema tables (Conversations, Messages, MoodEntries, UserPreferences), generate DAOs
3. Set up platform configs (iOS 16.0, Android OpenCL, macOS Podfile)
4. Create `GemmaService` — `init`, `generate`, `dispose`
5. Create `ModelDownloader` — wrapped `FlutterGemma.installModel()` with progress
6. Create GenUI generic catalog — ~20 layout/display/interactive items with recursive children so Jarvis composes any UI
7. Build Jarvis chat screen — `Conversation` + `Surface` rendering with DataModel binding for interactive widgets
8. Build `ContextProvider` + `PromptBuilder` — load prompt asset → query Drift → assemble → pass to Gemma
9. Wire into `AiService.processCommand()` — local parser → Gemma → GenUI
10. Integrate RevenueCat — gate E4B download + premium features behind $14.99 purchase
11. Build premium purchase UI in settings
12. Add telemetry: inference time, model, feature usage
13. Test fully offline (no internet, no Firebase) on 4GB (E2B) and 8GB+ (E4B) devices

### Open questions / research needed
- Launch at $14.99 or $29.99?
- ~~Bundle E2B in APK vs download on first launch?~~ ✅ **Decided: download on first launch**
- `genui` is experimental alpha — monitor API stability
- iOS target: start Android-only or both at once?
- Which purchase SDK? RevenueCat vs in-app purchases directly?
- OTA prompt updates: bundle in assets only, or add optional CDN JSON fetch?
- Drift migrations: plan for future schema changes

---

## Backlog / Tasks

### Phase 0 — Migration & Foundation (DO FIRST)
- [ ] **Data migration plan** — design how existing Firestore data (tasks, habits, notes, focus sessions, mood entries, profiles) maps to Drift tables. Write a `MigrationGuide.md`.
- [ ] **Firebase removal strategy** — decide: keep Firebase for auth+CRUD with Drift only for LLM context, or fully rip out Firebase. If keeping, define the boundary.
- [ ] **Drift schema expansion** — decide whether to migrate all current Firestore collections (tasks, habits, notes, focus_sessions) to Drift, or keep them hybrid. If migrating, add those tables to `schema.dart`.
- [ ] **Backup/restore** — design SQLite backup to iCloud/Google Drive or local file export. Add to backlog if not MVP.
- [ ] **Device compatibility matrix** — test LiteRT-LM on target devices. Document minimum RAM (4GB for E2B, 8GB for E4B), Android version, iOS version.

### Phase 1 — Model & LLM Layer
- [ ] **Model download UX design** — wireframe the full flow: storage check → download screen with progress/percentage → pause/resume → error/retry → success → model loaded confirmation. Handle edge cases (low storage, interrupt, slow network).
- [ ] **Model downloader edge cases** — implement network loss recovery, partial download resume, storage insufficient handling, model file integrity check.
- [ ] **GemmaService error handling** — define fallback behavior for model init failure, inference timeout (target: <2s per generation), OOM crashes.
- [ ] **Model tier gating** — wire `FeatureManager` to check purchase entitlement before allowing E4B download. Free users get E2B only.
- [ ] **Performance benchmarking** — establish targets: inference latency, peak memory, token/s throughput. Document results for E2B vs E4B on reference devices.

### Phase 2 — GenUI Layer
- [ ] **Catalog safety constraints** — define security boundaries: disallow `WebView`, `PlatformView`, file I/O, network calls from generated A2UI JSON. Sandbox the rendering.
- [ ] **Catalog item gaps** — review if `Chip`, `Wrap`, `GridView`, `BottomSheet`, `Dialog`, `CircularProgressIndicator` are needed for Jarvis's use cases. Add if required.
- [ ] **GenUI rendering fallback** — if A2UI JSON parsing fails, render a graceful text-only response instead of crashing or showing an error widget.
- [ ] **DataModel schema** — define all paths that interactive widgets can bind to (`/filter/*`, `/form/*`, `/settings/*`). Document the contract between AI-generated UI and app state.

### Phase 3 — Context & Prompt Layer
- [ ] **System prompt design** — craft the base Jarvis prompt with: personality definition, capability description, output format instructions, safety constraints. Version it.
- [ ] **Context assembly tokens budget** — define max tokens for context window (input limit of Gemma 4). Implement truncation strategy: recent messages first, drop oldest.
- [ ] **Function calling contract** — define the list of Dart callbacks Gemma 4 can invoke (query Drift, create task, etc.). Document each function's signature, parameters, and return schema.
- [ ] **Prompt versioning** — include a version field in the bundled prompt asset so future OTA updates can detect stale prompts and prompt re-download.

### Phase 4 — Purchases & Monetization
- [ ] **RevenueCat integration** — set up RevenueCat project, configure one-time $14.99 product for E4B unlock. Handle receipt validation for offline use.
- [ ] **Purchase restore** — implement "Restore Purchases" button. Test on fresh install.
- [ ] **Premium feature flag surface** — audit all premium-gated features (E4B, unlimited history, custom personality, weekly review). Ensure consistent gating via `FeatureManager`.
- [ ] **Trial or money-back consideration** — decide if a 24h free trial of E4B helps conversion. If yes, implement.
- [ ] **Intro offer without store dependency** — consider a local grace period (first 10 E4B queries free) so users experience premium before buying, without needing App Store intro offers.

### Phase 5 — UI & Integration
- [ ] **Tab navigation update** — integrate Jarvis chat screen as a primary tab (replacing or alongside existing modules). Redesign bottom nav if needed.
- [ ] **Onboarding flow v2** — design the first-launch experience: model download screen → choose free/premium → optional guest mode → Jarvis greeting. Replace current Firebase-heavy onboarding.
- [ ] **Jarvis chat screen states** — handle: loading (model loading), empty state (first message prompt), streaming response, error (model unavailable), premium gate prompt.
- [ ] **Dynamic card integration** — wire GenUI-rendered cards into the home screen dashboard alongside existing modules. Cards should be indistinguishable from native widgets.
- [ ] **Existing module coexistence** — if keeping existing modules (tasks, habits, etc.), ensure they still work offline. If migrating to Drift, update all CRUD operations.

### Phase 6 — Testing & QA
- [ ] **Unit tests** — Drift DAOs, PromptBuilder, FeatureManager, PurchaseManager, model_tier logic.
- [ ] **Widget tests** — catalog rendering (each of ~20 items renders correctly), ChatScreen states, ModelDownloadScreen, PremiumTile.
- [ ] **Integration tests** — full flow: user input → Tier 0 parser → Gemma service → GenUI render. Mock `FlutterGemma` for CI.
- [ ] **Device farm testing** — test on low-end (4GB) and mid-range (8GB) Android devices, iPhone SE, latest iPhone Pro.
- [ ] **Offline-only test pass** — airplane mode, no Firebase initialized: the entire app must work (except Firebase-dependent features if keeping auth).
- [ ] **Model download stress test** — test on slow network, interrupted download, low storage (within 500MB of model size), concurrent app use during download.

### Phase 7 — Polish & Launch
- [ ] **App store compliance** — verify Apple/Google policies on bundled ML models, on-device AI, one-time purchases. No server = no "account required" issues.
- [ ] **Privacy policy update** — update to reflect: all data stays on-device, no data collection, no server. Include in app and App Store listing.
- [ ] **Marketing positioning** — craft messaging around "fully private AI assistant that lives on your phone." Differentiate from cloud AI apps.
- [ ] **Crash reporting** — add opt-in crash reporting (Sentinel or similar) that respects offline-only privacy. Do not send any user data.
- [ ] **Usage analytics (privacy-first)** — count model loads, inference runs, feature usage — all stored locally in Drift, never sent anywhere. Optionally export in a future sync feature.

### Investigate & Decide
- [ ] **Sync strategy** — is local-only acceptable for MVP? If sync is needed later, research: Drift sync via custom server, or hybrid approach (Firestore for sync + Drift for LLM context).
- [x] **E2B bundling** — decided: download on first launch. Not bundled in APK. E2B downloads free after install; E4B downloads only after purchase check. Cached locally, re-download only on corruption.
- [ ] **Android vs iOS first** — decide launch platform. Android has better LiteRT-LM support. iOS may need higher deployment target (16.0+). Consider Android-only launch, then iOS.
- [ ] **Purchase SDK** — RevenueCat vs vanilla BillingClient/StoreKit2. RevenueCat saves time but adds dependency. Decide based on complexity tolerance.
- [ ] **OTA prompt delivery** — bundle only (simple, always works) vs CDN fetch with bundle fallback (flexible, needs network at least once).


