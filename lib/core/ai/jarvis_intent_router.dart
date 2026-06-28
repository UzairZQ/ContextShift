import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../local_llm/gemma_service.dart';
import 'context_provider.dart';

enum JarvisIntent { chat, action, genui }

class JarvisIntentDecision {
  final JarvisIntent intent;
  final String reason;
  final bool fromModel;

  const JarvisIntentDecision({
    required this.intent,
    required this.reason,
    this.fromModel = false,
  });
}

class JarvisIntentRouter {
  JarvisIntentRouter._();
  static final JarvisIntentRouter instance = JarvisIntentRouter._();

  Future<JarvisIntentDecision> classify({
    required String message,
    int? conversationId,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return const JarvisIntentDecision(
        intent: JarvisIntent.chat,
        reason: 'empty-message',
      );
    }

    final directAction = _directActionIntent(trimmed);
    if (directAction != null) return directAction;

    final directSurface = _directGeneratedSurfaceIntent(trimmed);
    if (directSurface != null) return directSurface;

    Map<String, Object?>? context;
    if (conversationId != null) {
      context = await ContextProvider.instance.buildGenUiContext(
        conversationId: conversationId,
      );
      final contextualSurface = _contextualGeneratedSurfaceIntent(
        message: trimmed,
        context: context,
      );
      if (contextualSurface != null) return contextualSurface;
    }

    if (GemmaService.instance.isModelLoaded) {
      context ??= await ContextProvider.instance.buildGenUiContext(
        conversationId: conversationId,
      );
      final modelDecision = await _classifyWithModel(
        message: trimmed,
        context: context,
      );
      if (modelDecision != null) return modelDecision;
    }

    return _fallbackClassify(trimmed);
  }

  JarvisIntentDecision? _directActionIntent(String message) {
    final lower = message.toLowerCase();
    final startsWithAction = RegExp(
      r'^(add task|todo|remind me|create task|start focus|focus \d+|add habit|new habit|track|note|remember|write down|jot down)\b',
    ).hasMatch(lower);
    if (!startsWithAction) return null;
    return const JarvisIntentDecision(
      intent: JarvisIntent.action,
      reason: 'explicit-app-action',
    );
  }

  JarvisIntentDecision? _directGeneratedSurfaceIntent(String message) {
    final lower = message.toLowerCase();
    if (!_looksLikeGeneratedSurfaceRequest(lower)) return null;
    return const JarvisIntentDecision(
      intent: JarvisIntent.genui,
      reason: 'explicit-generated-surface-request',
    );
  }

  JarvisIntentDecision? _contextualGeneratedSurfaceIntent({
    required String message,
    required Map<String, Object?> context,
  }) {
    final lower = message.toLowerCase();
    if (!_recentConversationAskedForSurface(context)) return null;
    if (!_looksLikeClarificationAnswer(lower)) return null;
    return const JarvisIntentDecision(
      intent: JarvisIntent.genui,
      reason: 'answered-generated-surface-clarification',
    );
  }

  Future<JarvisIntentDecision?> _classifyWithModel({
    required String message,
    required Map<String, Object?> context,
  }) async {
    try {
      final prompt =
          '''
You are routing a ContextShift JARVIS request.
Return exactly one compact JSON object:
{"intent":"chat|action|genui","reason":"short reason"}

Routing rules:
- action: concrete app mutation or navigation, such as creating a task, habit, note, or starting focus.
- genui: the user wants a structured, interactive, visual, reusable, or composed surface such as a plan, card, dashboard, checklist, routine, workout, schedule, form, comparison, tracker, or generated view.
- chat: natural conversation, explanation, questions, coaching, or anything that is better answered as text.

Use the full user message, recent conversation, local snapshot, and memory. Do not route from keywords alone.
If the user is answering clarifying questions for a recent plan, workout, routine, schedule, dashboard, checklist, card, tracker, or generated view request, choose genui so the surface can be created.

Context:
${jsonEncode(context)}

User message:
$message
''';
      final response = await GemmaService.instance.generate(
        prompt,
        maxTokens: 96,
        temperature: 0,
        timeout: const Duration(seconds: 8),
      );
      final start = response.indexOf('{');
      final end = response.lastIndexOf('}');
      if (start == -1 || end <= start) return null;

      final decoded =
          jsonDecode(response.substring(start, end + 1))
              as Map<String, dynamic>;
      final intent = switch (decoded['intent']?.toString().toLowerCase()) {
        'action' => JarvisIntent.action,
        'genui' => JarvisIntent.genui,
        'chat' => JarvisIntent.chat,
        _ => null,
      };
      if (intent == null) return null;
      return JarvisIntentDecision(
        intent: intent,
        reason: decoded['reason']?.toString() ?? 'model-classified',
        fromModel: true,
      );
    } catch (error, stackTrace) {
      debugPrint('[JarvisIntentRouter] Model classification failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  JarvisIntentDecision _fallbackClassify(String message) {
    final lower = message.toLowerCase();
    if (_looksLikeGeneratedSurfaceRequest(lower)) {
      return const JarvisIntentDecision(
        intent: JarvisIntent.genui,
        reason: 'offline-generated-surface-fallback',
      );
    }
    if (_looksLikeConversation(lower)) {
      return const JarvisIntentDecision(
        intent: JarvisIntent.chat,
        reason: 'offline-conversation-fallback',
      );
    }
    return const JarvisIntentDecision(
      intent: JarvisIntent.chat,
      reason: 'offline-default-chat',
    );
  }

  bool _looksLikeGeneratedSurfaceRequest(String lower) {
    final wantsOutput = RegExp(
      r'\b(build|make|generate|design|draft|craft|create|give me|show me|put together|prepare)\b',
    ).hasMatch(lower);
    final structuredThing = RegExp(
      r'\b(plan|planner|routine|workout|work out|exercise|training|schedule|itinerary|dashboard|card|view|screen|widget|form|layout|checklist|program|tracker|comparison)\b',
    ).hasMatch(lower);
    return wantsOutput && structuredThing;
  }

  bool _recentConversationAskedForSurface(Map<String, Object?> context) {
    final recent = context['recentConversation'];
    if (recent is! List) return false;
    final joined = recent
        .whereType<Map>()
        .map((message) => message['content']?.toString().toLowerCase() ?? '')
        .where((content) => content.trim().isNotEmpty)
        .join('\n');
    if (joined.isEmpty) return false;

    final surfaceDomain = RegExp(
      r'\b(plan|planner|routine|workout|work out|exercise|training|schedule|dashboard|card|checklist|program|tracker)\b',
    ).hasMatch(joined);
    final generationLanguage = RegExp(
      r'\b(build|make|generate|create|give me|show me|put together|prepare)\b',
    ).hasMatch(joined);
    final assistantClarified = RegExp(
      r'\b(what kind|how many|which days|equipment|goal|level|preference|clarify|tell me)\b',
    ).hasMatch(joined);

    return surfaceDomain && (generationLanguage || assistantClarified);
  }

  bool _looksLikeClarificationAnswer(String lower) {
    if (lower.length > 220) return false;
    if (RegExp(
      r'\b(yes|yeah|yep|ok|okay|sure|do it|make it|generate it|create it|that works)\b',
    ).hasMatch(lower)) {
      return true;
    }
    return RegExp(
      r'\b(tomorrow|today|morning|evening|night|home|gym|bodyweight|dumbbell|barbell|machine|full body|upper|lower|push|pull|legs|strength|muscle|hypertrophy|fat loss|cardio|beginner|intermediate|advanced|minutes?|hours?|days?|sets?|reps?)\b|\b\d+\b',
    ).hasMatch(lower);
  }

  bool _looksLikeConversation(String lower) {
    if (RegExp(
      r"^(hi|hello|hey|yo|salam|assalam|how are you|what'?s up|thanks|thank you)\b",
    ).hasMatch(lower)) {
      return true;
    }
    if (lower.endsWith('?')) return true;
    return RegExp(
      r'\b(who|what|why|how|when|where|explain|tell me|advice|think|feel|should i)\b',
    ).hasMatch(lower);
  }
}
