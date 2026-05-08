# ContextShift

ContextShift is a cross-platform Flutter productivity app built around a simple idea: your workspace should adapt to your current mental context instead of forcing you into a static dashboard.

The product combines task management, habits, focus sessions, notes, mood check-ins, and an AI layer called JARVIS. JARVIS can interpret commands, generate adaptive cards, and personalize responses using the user’s recent activity and profile context.

## Product Goal

Most productivity apps are good at storing information, but weak at helping people restart, refocus, and decide what matters next.

ContextShift is designed to become a:

- Re-entry workspace for people coming back after distraction or overload
- Context-aware daily operating system for tasks, habits, notes, and focus
- Lightweight AI copilot that can reshape the interface around the user’s current intent

The current version is intentionally moving away from account friction and generic dashboards toward a more helpful experience:

- First-run onboarding introduces the product before login
- Users can continue as guests without creating an account
- JARVIS stays usable even when the AI backend is offline by falling back to local command parsing

## What We Have Built So Far

### Core app experience

- Responsive Flutter app with a modular home dashboard
- Bottom navigation for Home, Tasks, Habits, Focus, and Notes
- Animated tab switching and animated module reordering
- Premium dark visual system using glassmorphism, gradients, and editorial typography

### Onboarding and access flow

- Multi-screen animated onboarding for first launch
- Email/password registration and sign-in
- Google sign-in
- Guest mode using Firebase anonymous authentication
- Guest profile capture for name, focus area, and support needs

### Productivity modules

- Tasks with priority and subtasks
- Habit tracking with emoji-based habit icons and daily completion state
- Focus sessions with saved duration data
- Notes module for quick capture
- Mood check-in using emoji states

### AI layer

- JARVIS command bar on the home screen
- Backend-powered command parsing through FastAPI
- Local fallback parser when backend is offline
- Adaptive card generation for planning, advice, and routines
- AI insight generation for dashboard summaries

### Personalization and behavior context

- Firebase-backed storage scoped by `userId`
- Behavior event logging for key interactions
- Context snapshot assembly before AI requests
- User profile context, mood, top tasks, missing habits, recent notes, recent commands, and recent events attached to JARVIS requests

## Architecture

The project is split into three main layers.

### 1. Flutter app

The Flutter application is the primary client and contains:

- App bootstrap and launch gating in [lib/main.dart](/Users/uzair99/Development/context_shift/lib/main.dart)
- Screens for onboarding, login, register, guest profile, and home
- Modular UI widgets for tasks, habits, notes, focus, AI dashboard, and generative cards
- Service classes for Firebase and AI communication

The home screen is built as a modular workspace rather than one large monolithic page. The app can reorder modules and change responses based on AI output.

### 2. Firebase layer

Firebase is used as the user data and authentication backbone.

Current Firebase responsibilities:

- Authentication
  - Email/password auth
  - Google sign-in
  - Anonymous guest auth
- Firestore storage
  - `tasks`
  - `habits`
  - `focus_sessions`
  - `notes`
  - `mood_entries`
  - `ai_commands`
  - `behavior_events`
  - `profiles`

The main data access layer lives in [lib/core/firebase_service.dart](/Users/uzair99/Development/context_shift/lib/core/firebase_service.dart).

### 3. AI backend

The AI backend lives in [backend_fastapi/main.py](/Users/uzair99/Development/context_shift/backend_fastapi/main.py).

It provides:

- `GET /health`
- `POST /command`
- `POST /ai-command`
- `POST /ai-insight`
- `POST /summarize`

Responsibilities of the backend:

- Accept command and insight requests from Flutter
- Forward prompts to Gemini through LangChain
- Return structured JSON for UI actions and adaptive cards
- Use user context passed from the app to personalize responses

There is also a small Node server in [backend_node/index.js](/Users/uzair99/Development/context_shift/backend_node/index.js) intended as a real-time relay layer for layout broadcasting, although the main product flow currently depends on the Flutter app plus the FastAPI backend.

## Technical Stack

### Frontend

- Flutter
- Dart
- Material 3
- `google_fonts`
- `lucide_icons`

### Backend

- Python
- FastAPI
- Uvicorn
- LangChain
- Google Gemini via `langchain-google-genai`
- `python-dotenv`

### Data and auth

- Firebase Core
- Firebase Auth
- Cloud Firestore
- Google Sign-In

### Utilities

- `http`
- `shared_preferences`

## Important Files

- [lib/main.dart](/Users/uzair99/Development/context_shift/lib/main.dart)
  - App bootstrap, Firebase initialization, onboarding gate
- [lib/core/firebase_service.dart](/Users/uzair99/Development/context_shift/lib/core/firebase_service.dart)
  - Auth, Firestore operations, user context assembly
- [lib/core/ai_service.dart](/Users/uzair99/Development/context_shift/lib/core/ai_service.dart)
  - Backend communication, health checks, local fallback logic
- [lib/presentation/screens/home_screen.dart](/Users/uzair99/Development/context_shift/lib/presentation/screens/home_screen.dart)
  - Main workspace, bottom navigation, AI bar, insight card
- [lib/presentation/screens/onboarding_screen.dart](/Users/uzair99/Development/context_shift/lib/presentation/screens/onboarding_screen.dart)
  - First-run onboarding flow
- [lib/presentation/screens/guest_profile_screen.dart](/Users/uzair99/Development/context_shift/lib/presentation/screens/guest_profile_screen.dart)
  - Guest-mode profile capture
- [backend_fastapi/main.py](/Users/uzair99/Development/context_shift/backend_fastapi/main.py)
  - JARVIS backend
- [firestore.rules](/Users/uzair99/Development/context_shift/firestore.rules)
  - Firestore security rules

## How JARVIS Works

### Online mode

When the backend is running:

1. Flutter builds a context snapshot from Firestore and the current user profile
2. The app sends the user command plus context to FastAPI
3. FastAPI sends the prompt to Gemini
4. Gemini returns structured JSON actions
5. Flutter applies those actions to the UI and Firestore

### Offline mode

When the backend is unavailable:

1. The health check fails
2. The command bar remains available
3. `AiService` falls back to a local intent parser
4. The app still supports common commands like adding tasks, habits, notes, or starting focus

This makes the product more resilient and prevents the AI layer from blocking the entire app.

## Current JARVIS Setup

The Flutter app expects the AI backend at:

- `http://localhost:8000` on macOS, iOS simulator, Windows, and Linux
- `http://10.0.2.2:8000` on Android emulator

The backend reads its API key from:

- `backend_fastapi/.env`

Expected variable:

```env
GOOGLE_API_KEY=your_key_here
```

## Running the Project

### Flutter app

```bash
flutter pub get
flutter run
```

### FastAPI JARVIS backend

From the project root:

```bash
cd backend_fastapi
venv/bin/python -m uvicorn main:app --host 127.0.0.1 --port 8000
```

Health check:

```bash
curl http://127.0.0.1:8000/health
```

Expected result:

```json
{"status":"ok","service":"ContextShift AI Engine"}
```

### VS Code Python setup

This project already includes VS Code Python settings in [.vscode/settings.json](/Users/uzair99/Development/context_shift/.vscode/settings.json) that point to:

- interpreter: `${workspaceFolder}/backend_fastapi/venv/bin/python`
- env file: `${workspaceFolder}/backend_fastapi/.env`

If JARVIS appears offline in development, make sure you are actually running the backend with that interpreter and not with a different global Python environment such as Conda.

## Firebase Notes

For the full auth and guest flow to work correctly, Firebase must be configured with:

- Email/Password auth enabled
- Google sign-in enabled if used
- Anonymous auth enabled for guest mode
- Firestore rules deployed from [firestore.rules](/Users/uzair99/Development/context_shift/firestore.rules)

The new `profiles` collection is part of the current product architecture and must be allowed by Firestore rules.

## Known State

What is working now:

- Onboarding flow
- Guest mode UI
- Dynamic sanctuary naming
- Animated bottom navigation transitions
- JARVIS local fallback mode
- Context-enriched AI requests
- Safer task and habit bottom sheets
- AI dashboard overflow fixes

What still depends on environment/setup:

- JARVIS online mode requires the FastAPI server to be running
- Gemini-backed generation requires a valid API key with available quota
- Firebase guest mode requires anonymous auth to be enabled
- Profile persistence requires deployed Firestore rules

## Troubleshooting JARVIS

If JARVIS looks offline or inconsistent, check these in order:

1. Is the FastAPI backend running on `127.0.0.1:8000`?
2. Does `curl http://127.0.0.1:8000/health` return `200 OK`?
3. Are you using the backend virtualenv at `backend_fastapi/venv/bin/python`?
4. Does `backend_fastapi/.env` contain a valid `GOOGLE_API_KEY`?
5. Does your Gemini project actually have quota available?

Important distinction:

- If `/health` fails, JARVIS is offline at the backend level
- If `/health` works but model calls fail with `429 RESOURCE_EXHAUSTED`, the backend is online but the Gemini quota is exhausted

## Product Direction

ContextShift is strongest when it is not just another AI productivity app.

The most promising direction is to make it a context recovery and decision-support tool:

- help users restart after distraction
- compress overwhelm into the next clear move
- adapt plans based on mood and energy
- make the interface feel more like a responsive operating system than a note-taking container

That product direction already matches the current architecture well:

- modular UI
- behavioral logging
- mood input
- AI-driven layout changes
- user-context-aware prompting

## Status Summary

ContextShift today is a functional adaptive productivity app with:

- a polished onboarding flow
- guest and account-based entry
- Firebase-backed personalization
- a live AI backend plus offline fallback
- modular adaptive UI foundations

The next big step is not adding random features. It is sharpening the product around one real user pain point and making JARVIS feel consistently helpful in that situation.
