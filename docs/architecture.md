# ContextShift Architecture

ContextShift is an offline-first Flutter productivity system. The app combines
classic productivity modules with an on-device JARVIS layer that can chat,
execute app actions, build local context, and generate adaptive GenUI surfaces.

## System Architecture

```mermaid
flowchart TB
  User["User"] --> Input["Touch, typing, dictation"]

  subgraph App["Flutter App"]
    Main["main.dart\nbootstrap, database init, model init, launch gating"]
    Shell["HomeScreen\nbottom navigation, splash reveal, shared app shell"]

    subgraph Screens["Presentation Layer"]
      Onboarding["Onboarding\nprofile setup, model download"]
      Home["Home\ncommand bar, mood, insight, generated card"]
      Tasks["Tasks"]
      Habits["Habits"]
      Focus["Focus timer"]
      Journal["Journal / notes"]
      Chat["JARVIS Chat\nchat mode, generate mode, history drawer, dictation"]
      Dashboard["AI Summary"]
      Settings["Settings"]
    end

    subgraph Motion["UI System"]
      Theme["AppTheme\ncolors, typography, snackbars"]
      Primitives["ContextShift primitives"]
      Reveal["WonderousReveal\nstaggered screen motion"]
      Wordmark["ContextShiftWordmark\nsplash-to-home identity"]
    end

    subgraph Core["Core Services"]
      DBService["DatabaseService\nCRUD, streams, context snapshots"]
      AiService["AiService\nfast command parsing, action JSON fallback"]
      ContextProvider["ContextProvider\nprompt context selection and gating"]
      Memory["JarvisMemoryService\nconversation state, summaries, learned facts"]
      Actions["ActionExecutor\ncreate task, habit, note, focus"]
      FeatureManager["FeatureManager\nmodel-tier feature gates"]
      Storage["DeviceStorageService\nnative storage channel"]
    end

    subgraph GenUI["GenUI Layer"]
      Runtime["JarvisGenUiRuntime\nGemma prompt, A2UI stream, timeout fallback"]
      Catalog["JarvisDesignCatalog + BasicCatalogItems\nsafe Flutter-style components"]
      Renderer["A2uiSurfaceCard + SafeRenderer\nrenders generated surfaces"]
      ActionBus["GenUiActionBus\nsurface button events"]
    end

    subgraph LLM["On-device AI"]
      Gemma["GemmaService\nFlutterGemma init, load, generate, stream"]
      Downloader["ModelDownloader\nHuggingFace download, resume, install"]
      Tiers["ModelTier\nE2B / E4B"]
    end

    subgraph Data["Local Data Layer"]
      Drift["Drift / SQLite\nschema.dart + schema.g.dart"]
      Tables["Profile, Preferences, Tasks, Habits,\nFocus, Notes, Mood, Commands,\nEvents, Conversations, Messages,\nConversationMemory, JarvisMemory"]
      Prefs["SharedPreferences\ndevice-local preferences"]
    end
  end

  Input --> Screens
  Main --> Shell
  Shell --> Screens
  Screens --> Theme
  Screens --> Primitives
  Screens --> Reveal
  Main --> Wordmark

  Screens --> DBService
  DBService --> Drift
  Drift --> Tables
  DBService --> Prefs

  Home --> AiService
  Chat --> AiService
  Chat --> Runtime
  Home --> Runtime

  AiService --> ContextProvider
  Runtime --> ContextProvider
  ContextProvider --> DBService
  ContextProvider --> Memory
  Memory --> DBService
  AiService --> Actions
  Actions --> DBService

  Runtime --> Gemma
  Runtime --> Catalog
  Catalog --> Renderer
  Renderer --> ActionBus
  ActionBus --> Actions

  Gemma --> Tiers
  Downloader --> Gemma
  Downloader --> Storage
  FeatureManager --> Tiers
  Onboarding --> Downloader
  Onboarding --> FeatureManager
```

## JARVIS And GenUI Flow

```mermaid
sequenceDiagram
  actor U as User
  participant Chat as Chat / Home UI
  participant DB as DatabaseService
  participant Ctx as ContextProvider
  participant Mem as JarvisMemoryService
  participant AI as AiService
  participant Gen as JarvisGenUiRuntime
  participant Gem as GemmaService
  participant A2UI as GenUI Runtime
  participant Act as ActionExecutor

  U->>Chat: Type, send, or dictate a message
  Chat->>DB: Save user message / command

  alt Chat mode
    Chat->>Ctx: buildChat(userMessage, conversationId)
    Ctx->>DB: Read profile, tasks, habits, notes, mood, focus, recent messages
    Ctx->>Mem: Read conversation state and learned local memory
    Mem->>DB: Load conversation memory and JarvisMemory rows
    Ctx-->>Chat: Compact prompt with gated context
    Chat->>Gem: Generate plain JARVIS reply
    Gem-->>Chat: Local text response
    Chat->>DB: Save assistant message
    Chat->>Mem: Record turn and update summary/state
  else Action command
    Chat->>AI: Process command
    AI->>AI: Try keyword parser first
    AI->>Ctx: Build action prompt if parser misses
    AI->>Gem: Ask for structured JSON action
    Gem-->>AI: response + actions
    AI->>Act: Execute supported actions
    Act->>DB: Create task, habit, note, or focus session
    AI-->>Chat: Human response + action result
  else Generate mode / Home generation
    Chat->>Gen: generate(userMessage, conversationId)
    Gen->>Ctx: buildGenUiContext
    Ctx->>DB: Read local snapshot and recent conversation
    Ctx->>Mem: Read memory and runtime state
    Gen->>Gem: Stream catalog-aware A2UI prompt
    Gem-->>Gen: Text + A2UI chunks
    Gen->>A2UI: Feed chunks into safe runtime
    A2UI-->>Chat: Render surface IDs
    alt Gemma surface succeeds
      Chat->>DB: Save assistant message with widgetJson source=gemma
    else Timeout / no visible surface / runtime error
      Gen-->>Chat: Local fallback surface with reason
      Chat->>DB: Save widgetJson source=fallback
    end
    Chat->>Mem: Record generated turn and card type
  end

  A2UI->>Chat: User taps generated button or checklist
  Chat->>Act: Route emitted WidgetAction
  Act->>DB: Persist app-side result when needed
```

## Local Data Model

```mermaid
erDiagram
  PROFILE_TABLE {
    int id PK
    string userId UK
    string name
    string firstName
    string focusRole
    string focusArea
    string supportNeed
    string modelTier
    datetime updatedAt
  }

  USER_PREFERENCES_TABLE {
    int id PK
    string deviceId UK
    string responseStyle
    boolean premiumPurchased
    boolean onboardingDone
    string modelTier
  }

  TASK_TABLE {
    int id PK
    string userId
    string title
    boolean done
    string priority
    string due
    string subtasks
    datetime createdAt
  }

  HABIT_TABLE {
    int id PK
    string userId
    string name
    string icon
    string completedDates
    datetime createdAt
  }

  FOCUS_SESSION_TABLE {
    int id PK
    string userId
    int durationMinutes
    datetime startedAt
    datetime completedAt
    boolean completed
  }

  NOTE_TABLE {
    int id PK
    string userId
    string content
    string tags
    string summary
    datetime createdAt
    datetime updatedAt
  }

  MOOD_ENTRY_TABLE {
    int id PK
    string userId
    string mood
    int score
    string date
    string note
    datetime timestamp
  }

  AI_COMMAND_TABLE {
    int id PK
    string userId
    string command
    string response
    string actions
    datetime timestamp
  }

  BEHAVIOR_EVENT_TABLE {
    int id PK
    string userId
    string eventType
    string module
    string metadata
    datetime timestamp
  }

  CONVERSATION_TABLE {
    int id PK
    string userId
    string title
    string modelTier
    datetime createdAt
    datetime updatedAt
  }

  MESSAGE_TABLE {
    int id PK
    int conversationId
    string role
    string content
    string widgetJson
    datetime createdAt
  }

  CONVERSATION_MEMORY_TABLE {
    int id PK
    int conversationId UK
    string summary
    string openQuestions
    datetime updatedAt
  }

  JARVIS_MEMORY_TABLE {
    int id PK
    string userId
    string kind
    string key
    string value
    float confidence
    string source
    datetime createdAt
    datetime updatedAt
  }

  PROFILE_TABLE ||--o{ TASK_TABLE : owns
  PROFILE_TABLE ||--o{ HABIT_TABLE : owns
  PROFILE_TABLE ||--o{ FOCUS_SESSION_TABLE : owns
  PROFILE_TABLE ||--o{ NOTE_TABLE : owns
  PROFILE_TABLE ||--o{ MOOD_ENTRY_TABLE : owns
  PROFILE_TABLE ||--o{ AI_COMMAND_TABLE : owns
  PROFILE_TABLE ||--o{ BEHAVIOR_EVENT_TABLE : owns
  PROFILE_TABLE ||--o{ CONVERSATION_TABLE : owns
  PROFILE_TABLE ||--o{ JARVIS_MEMORY_TABLE : learns
  CONVERSATION_TABLE ||--o{ MESSAGE_TABLE : contains
  CONVERSATION_TABLE ||--|| CONVERSATION_MEMORY_TABLE : summarizes
```

## Layer Responsibilities

| Layer | Responsibility | Key files |
| --- | --- | --- |
| App bootstrap | Initialize database, Gemma, launch routing, splash/home reveal | `lib/main.dart` |
| Presentation | Screens, modules, chat, generated-card rendering, motion | `lib/presentation/**` |
| Local data | Drift schema, CRUD, streams, context snapshots | `lib/core/database/schema.dart`, `lib/core/database/database_service.dart` |
| JARVIS context | Select relevant local context, recent messages, memory, runtime state | `lib/core/ai/context_provider.dart`, `lib/core/ai/jarvis_memory_service.dart` |
| Command actions | Parse commands and execute safe app mutations | `lib/core/ai_service.dart`, `lib/core/ai/action_executor.dart` |
| GenUI | Ask Gemma for A2UI, constrain to catalog, render safely, fall back locally | `lib/core/genui/**`, `lib/presentation/widgets/genui/a2ui_surface_card.dart` |
| Local model | Initialize, load, download, and run Gemma locally | `lib/core/local_llm/**` |
| Native support | Storage checks for large local model downloads | `lib/core/services/device_storage_service.dart` |

## Runtime Principles

- Local-first by default: user data, conversations, memories, and generated UI
  metadata are stored on device.
- Model-aware: the app can run without Gemma loaded, then unlock richer chat and
  GenUI once the model is available.
- Catalog-constrained GenUI: JARVIS can compose dynamic surfaces from safe,
  known widgets instead of executing arbitrary Flutter code at runtime.
- Context-gated prompting: JARVIS receives the smallest useful slice of local
  profile, productivity, memory, and conversation state for each mode.
- Recoverable generation: if Gemma times out or does not produce a visible
  surface, the runtime returns a labeled local fallback rather than crashing.
