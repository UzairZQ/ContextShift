# Graph Report - /Users/uzair99/Development/context_shift/.graphify_scope  (2026-05-10)

## Corpus Check
- Corpus is ~16,644 words - fits in a single context window. You may not need a graph.

## Summary
- 315 nodes · 362 edges · 16 communities
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 4 edges (avg confidence: 0.9)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Home AI Dashboard|Home AI Dashboard]]
- [[_COMMUNITY_Firebase App Bootstrap|Firebase App Bootstrap]]
- [[_COMMUNITY_Onboarding Generative UI|Onboarding Generative UI]]
- [[_COMMUNITY_Profile Form Screens|Profile Form Screens]]
- [[_COMMUNITY_Habit Tracking Module|Habit Tracking Module]]
- [[_COMMUNITY_Shared UI Theme|Shared UI Theme]]
- [[_COMMUNITY_AI Analytics Dashboard|AI Analytics Dashboard]]
- [[_COMMUNITY_Focus Session Module|Focus Session Module]]
- [[_COMMUNITY_AI Service Layer|AI Service Layer]]
- [[_COMMUNITY_Authentication Screens|Authentication Screens]]
- [[_COMMUNITY_Task Management Module|Task Management Module]]
- [[_COMMUNITY_AI Notes Module|AI Notes Module]]
- [[_COMMUNITY_Firebase Auth Service|Firebase Auth Service]]
- [[_COMMUNITY_FastAPI AI Endpoints|FastAPI AI Endpoints]]
- [[_COMMUNITY_Python Backend Dependencies|Python Backend Dependencies]]
- [[_COMMUNITY_Node Socket Server|Node Socket Server]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 16 edges
2. `../../core/app_theme.dart` - 13 edges
3. `package:lucide_icons/lucide_icons.dart` - 12 edges
4. `../../core/firebase_service.dart` - 10 edges
5. `backend_fastapi requirements manifest` - 7 edges
6. `../../core/responsive.dart` - 6 edges
7. `dart:async` - 5 edges
8. `package:flutter/foundation.dart` - 4 edges
9. `package:firebase_core/firebase_core.dart` - 3 edges
10. `../../core/ai_service.dart` - 3 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Hyperedges (group relationships)
- **Google Backend Service Stack** — requirements_firebase_admin, requirements_google_cloud_firestore, requirements_google_cloud_storage [INFERRED 0.85]

## Communities (16 total, 0 thin omitted)

### Community 0 - "Home AI Dashboard"
Cohesion: 0.04
Nodes (54): _AIPulsar, _AIPulsarState, AnimatedBuilder, AnimatedSwitcher, build, _buildAICommandBar, _buildAIInsightCard, _buildAIResponseCard (+46 more)

### Community 1 - "Firebase App Bootstrap"
Cohesion: 0.07
Nodes (26): core/firebase_runtime_options.dart, firebase_options.dart, package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, package:flutter/services.dart, package:shared_preferences/shared_preferences.dart, presentation/screens/home_screen.dart, presentation/screens/login_screen.dart (+18 more)

### Community 2 - "Onboarding Generative UI"
Cohesion: 0.08
Nodes (25): ../../core/app_theme.dart, dart:ui, package:lucide_icons/lucide_icons.dart, ./task_module.dart, build, dispose, _GlowOrb, IgnorePointer (+17 more)

### Community 3 - "Profile Form Screens"
Cohesion: 0.08
Nodes (23): ../../core/firebase_service.dart, ../../core/responsive.dart, build, _buildInput, _buildLabel, _buildPanel, Container, dispose (+15 more)

### Community 4 - "Habit Tracking Module"
Cohesion: 0.1
Nodes (20): build, _buildHabitContent, _buildMiniHeatmap, Center, Column, Container, dispose, GestureDetector (+12 more)

### Community 5 - "Shared UI Theme"
Cohesion: 0.1
Nodes (18): package:flutter/material.dart, package:google_fonts/google_fonts.dart, AppTheme, BoxDecoration, cardDecoration, glassmorphism, ThemeData, Align (+10 more)

### Community 6 - "AI Analytics Dashboard"
Cohesion: 0.1
Nodes (19): AiDashboardScreen, _AiDashboardScreenState, build, _buildActivityHeatmap, _buildCommandHistory, _buildHeader, _buildInsightCard, _buildMoodTrend (+11 more)

### Community 7 - "Focus Session Module"
Cohesion: 0.11
Nodes (17): build, _buildProductivityTip, _buildSessionChip, Center, Container, _ControlButton, dispose, FocusTimerModule (+9 more)

### Community 8 - "AI Service Layer"
Cohesion: 0.12
Nodes (15): dart:async, dart:convert, firebase_service.dart, package:http/http.dart, AiAction, AiCommandResult, AiService, _detectPriority (+7 more)

### Community 9 - "Authentication Screens"
Cohesion: 0.12
Nodes (15): guest_profile_screen.dart, register_screen.dart, build, _buildGoogleButton, _buildGuestButton, _buildPrimaryButton, _buildTextField, Container (+7 more)

### Community 10 - "Task Management Module"
Cohesion: 0.12
Nodes (15): build, _buildTaskList, _buildTaskStats, Center, Column, Container, GestureDetector, Icon (+7 more)

### Community 11 - "AI Notes Module"
Cohesion: 0.14
Nodes (13): ../../core/ai_service.dart, build, _buildEmptyState, _buildNoteCard, _buildNoteInput, Center, Column, Container (+5 more)

### Community 12 - "Firebase Auth Service"
Cohesion: 0.18
Nodes (10): package:cloud_firestore/cloud_firestore.dart, package:firebase_auth/firebase_auth.dart, package:google_sign_in/google_sign_in.dart, computeStreak, FirebaseService, _handleAuthError, logEvent, saveUserProfile (+2 more)

### Community 13 - "FastAPI AI Endpoints"
Cohesion: 0.27
Nodes (6): CommandRequest, InsightRequest, process_ai_command_alias(), process_command(), SummarizeRequest, BaseModel

### Community 14 - "Python Backend Dependencies"
Cohesion: 0.39
Nodes (8): FastAPI, Firebase Admin SDK, Google Cloud Firestore, Google Cloud Storage, Google Gen AI SDK, LangChain Google GenAI, backend_fastapi requirements manifest, Uvicorn

### Community 15 - "Node Socket Server"
Cohesion: 0.29
Nodes (6): app, cors, express, http, io, { Server }

## Knowledge Gaps
- **267 isolated node(s):** `DefaultFirebaseOptions`, `UnsupportedError`, `ContextShiftApp`, `_LaunchGate`, `_LaunchGateState` (+262 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Shared UI Theme` to `Home AI Dashboard`, `Firebase App Bootstrap`, `Onboarding Generative UI`, `Profile Form Screens`, `Habit Tracking Module`, `AI Analytics Dashboard`, `Focus Session Module`, `Authentication Screens`, `Task Management Module`, `AI Notes Module`?**
  _High betweenness centrality (0.264) - this node is a cross-community bridge._
- **Why does `../../core/app_theme.dart` connect `Onboarding Generative UI` to `Home AI Dashboard`, `Firebase App Bootstrap`, `Profile Form Screens`, `Habit Tracking Module`, `AI Analytics Dashboard`, `Focus Session Module`, `Authentication Screens`, `Task Management Module`, `AI Notes Module`?**
  _High betweenness centrality (0.152) - this node is a cross-community bridge._
- **Why does `dart:async` connect `AI Service Layer` to `Home AI Dashboard`, `Task Management Module`, `Habit Tracking Module`, `Focus Session Module`?**
  _High betweenness centrality (0.144) - this node is a cross-community bridge._
- **What connects `DefaultFirebaseOptions`, `UnsupportedError`, `ContextShiftApp` to the rest of the system?**
  _267 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Home AI Dashboard` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Firebase App Bootstrap` be split into smaller, more focused modules?**
  _Cohesion score 0.07 - nodes in this community are weakly interconnected._
- **Should `Onboarding Generative UI` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._