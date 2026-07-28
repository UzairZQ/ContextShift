import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../database/database_service.dart';
import '../database/schema.dart';

class JarvisMemoryService {
  JarvisMemoryService._();
  static final JarvisMemoryService instance = JarvisMemoryService._();

  static const int _maxSummaryLength = 1800;
  static const String _statePrefix = '[[jarvis_state]]';
  static const String _summaryPrefix = '[[conversation_summary]]';

  Future<void> recordTurn({
    required int conversationId,
    required String userMessage,
    required String assistantResponse,
    String mode = 'chat',
    String? generatedCardType,
  }) async {
    try {
      await Future.wait([
        _updateConversationSummary(
          conversationId: conversationId,
          userMessage: userMessage,
          assistantResponse: assistantResponse,
          mode: mode,
          generatedCardType: generatedCardType,
        ),
        _learnExplicitUserFacts(userMessage),
      ]);
    } catch (error, stackTrace) {
      // Memory is enrichment, not a prerequisite for delivering a reply.
      // A failed memory write must not turn a successful user message into an
      // error state after the assistant response was already persisted.
      debugPrint('[JarvisMemory] Failed to record turn: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<Map<String, Object?>> buildMemoryContext({int? conversationId}) async {
    var memories = const <JarvisMemoryTableData>[];
    try {
      memories = await DatabaseService.instance.getJarvisMemories();
    } catch (error, stackTrace) {
      debugPrint('[JarvisMemory] Could not load learned memory: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    ConversationMemoryTableData? conversationMemory;
    if (conversationId != null) {
      try {
        conversationMemory = await DatabaseService.instance
            .getConversationMemory(conversationId);
      } catch (error, stackTrace) {
        debugPrint('[JarvisMemory] Could not load conversation memory: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    final parsed = _parseConversationMemory(conversationMemory?.summary ?? '');

    return <String, Object?>{
      'conversationSummary': parsed.summary,
      'conversationState': parsed.state.toJson(),
      'openQuestions': _decodeOpenQuestions(conversationMemory),
      'learnedUserMemory': memories.map(_memoryToJson).toList(),
    };
  }

  Future<void> _updateConversationSummary({
    required int conversationId,
    required String userMessage,
    required String assistantResponse,
    required String mode,
    String? generatedCardType,
  }) async {
    final existing = await DatabaseService.instance.getConversationMemory(
      conversationId,
    );
    final parsed = _parseConversationMemory(existing?.summary ?? '');
    final current = parsed.summary.trim();
    final turn = _compactTurn(userMessage, assistantResponse);
    final merged = current.isEmpty ? turn : '$current\n$turn';
    final state = _updateRuntimeState(
      parsed.state,
      userMessage: userMessage,
      assistantResponse: assistantResponse,
      mode: mode,
      generatedCardType: generatedCardType,
    );
    await DatabaseService.instance.upsertConversationMemory(
      conversationId: conversationId,
      summary: _encodeConversationMemory(
        state: state,
        summary: _trimFromStart(merged, _maxSummaryLength),
      ),
      openQuestions: _extractOpenQuestions(userMessage, assistantResponse),
    );
  }

  Future<void> _learnExplicitUserFacts(String userMessage) async {
    final text = userMessage.trim();
    if (text.length < 4) return;

    final rules = <_MemoryRule>[
      _MemoryRule(
        kind: 'identity',
        key: 'preferred_name',
        pattern: RegExp(
          r"\b(?:call me|my name is)\s+([a-z][a-z\s]{1,40})",
          caseSensitive: false,
        ),
        confidence: 0.82,
      ),
      _MemoryRule(
        kind: 'preference',
        key: 'likes',
        pattern: RegExp(
          r'\b(?:i like|i love|i enjoy|i prefer)\s+(.{3,90})',
          caseSensitive: false,
        ),
        confidence: 0.72,
      ),
      _MemoryRule(
        kind: 'preference',
        key: 'dislikes',
        pattern: RegExp(
          r"\b(?:i dislike|i hate|i do not like|i don't like)\s+(.{3,90})",
          caseSensitive: false,
        ),
        confidence: 0.72,
      ),
      _MemoryRule(
        kind: 'goal',
        key: 'current_goal',
        pattern: RegExp(
          r"\b(?:my goal is|i want to|i need to|i am trying to|i'm trying to)\s+(.{4,120})",
          caseSensitive: false,
        ),
        confidence: 0.7,
      ),
      _MemoryRule(
        kind: 'routine',
        key: 'routine',
        pattern: RegExp(
          r'\b(?:every day i|i usually|i normally|my routine is)\s+(.{4,120})',
          caseSensitive: false,
        ),
        confidence: 0.68,
      ),
      _MemoryRule(
        kind: 'constraint',
        key: 'constraint',
        pattern: RegExp(
          r"\b(?:i cannot|i can't|i struggle with|i have trouble with)\s+(.{4,120})",
          caseSensitive: false,
        ),
        confidence: 0.68,
      ),
    ];

    for (final rule in rules) {
      final match = rule.pattern.firstMatch(text);
      if (match == null) continue;
      final value = _cleanFact(match.group(1) ?? '');
      if (value.length < 3) continue;
      await DatabaseService.instance.upsertJarvisMemory(
        kind: rule.kind,
        key: rule.key,
        value: value,
        confidence: rule.confidence,
        source: 'chat',
      );
    }
  }

  String _compactTurn(String userMessage, String assistantResponse) {
    final user = _singleLine(userMessage);
    final assistant = _singleLine(assistantResponse);
    return 'User: ${_clip(user, 220)}\nJARVIS: ${_clip(assistant, 220)}';
  }

  List<String> _extractOpenQuestions(
    String userMessage,
    String assistantResponse,
  ) {
    final questions = <String>[];
    for (final line in assistantResponse.split(RegExp(r'[\n\r]+'))) {
      final cleaned = _singleLine(line);
      if (cleaned.endsWith('?')) questions.add(_clip(cleaned, 140));
    }
    return questions.take(3).toList(growable: false);
  }

  _ConversationRuntimeState _updateRuntimeState(
    _ConversationRuntimeState previous, {
    required String userMessage,
    required String assistantResponse,
    required String mode,
    String? generatedCardType,
  }) {
    final pending = _extractOpenQuestions(
      userMessage,
      assistantResponse,
    ).firstOrNull;
    final topic = _detectTopic(userMessage) ?? previous.currentTopic;
    final goal = _detectGoal(userMessage) ?? previous.currentGoal;
    return previous.copyWith(
      alreadyGreeted: previous.alreadyGreeted || assistantResponse.isNotEmpty,
      currentTopic: topic,
      currentGoal: goal,
      pendingQuestion: pending ?? previous.pendingQuestion,
      lastMode: mode,
      lastGeneratedCardType:
          generatedCardType ?? previous.lastGeneratedCardType,
    );
  }

  String? _detectTopic(String message) {
    final lower = message.toLowerCase();
    if (RegExp(
      r'\b(workout|exercise|training|gym|full body)\b',
    ).hasMatch(lower)) {
      return 'fitness';
    }
    if (RegExp(
      r'\b(task|todo|priority|deadline|work plan)\b',
    ).hasMatch(lower)) {
      return 'tasks';
    }
    if (RegExp(r'\b(habit|streak|routine)\b').hasMatch(lower)) {
      return 'habits';
    }
    if (RegExp(r'\b(focus|pomodoro|deep work|session)\b').hasMatch(lower)) {
      return 'focus';
    }
    if (RegExp(r'\b(note|journal|mood|feeling|reflect)\b').hasMatch(lower)) {
      return 'journal';
    }
    if (RegExp(r'\b(study|learn|exam|course)\b').hasMatch(lower)) {
      return 'study';
    }
    return null;
  }

  String? _detectGoal(String message) {
    final cleaned = _singleLine(message);
    if (cleaned.length < 8) return null;
    if (!RegExp(
      r'\b(build|make|generate|create|plan|help|want|need|trying|goal)\b',
      caseSensitive: false,
    ).hasMatch(cleaned)) {
      return null;
    }
    return _clip(cleaned, 160);
  }

  _ParsedConversationMemory _parseConversationMemory(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || !trimmed.startsWith(_statePrefix)) {
      return _ParsedConversationMemory(
        state: const _ConversationRuntimeState(),
        summary: trimmed,
      );
    }

    final summaryIndex = trimmed.indexOf(_summaryPrefix);
    if (summaryIndex == -1) {
      return _ParsedConversationMemory(
        state: const _ConversationRuntimeState(),
        summary: trimmed,
      );
    }

    final stateRaw = trimmed
        .substring(_statePrefix.length, summaryIndex)
        .trim();
    final summary = trimmed
        .substring(summaryIndex + _summaryPrefix.length)
        .trim();
    try {
      return _ParsedConversationMemory(
        state: _ConversationRuntimeState.fromJson(
          jsonDecode(stateRaw) as Map<String, dynamic>,
        ),
        summary: summary,
      );
    } catch (_) {
      return _ParsedConversationMemory(
        state: const _ConversationRuntimeState(),
        summary: summary,
      );
    }
  }

  String _encodeConversationMemory({
    required _ConversationRuntimeState state,
    required String summary,
  }) {
    return '$_statePrefix\n${jsonEncode(state.toJson())}\n$_summaryPrefix\n$summary';
  }

  Map<String, Object?> _memoryToJson(JarvisMemoryTableData memory) {
    return {
      'kind': memory.kind,
      'key': memory.key,
      'value': memory.value,
      'confidence': memory.confidence,
      'updatedAt': memory.updatedAt.toIso8601String(),
    };
  }

  List<String> _decodeOpenQuestions(ConversationMemoryTableData? memory) {
    if (memory == null || memory.openQuestions.trim().isEmpty) return [];
    try {
      return (jsonDecode(memory.openQuestions) as List<dynamic>)
          .whereType<String>()
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return [];
    }
  }

  String _trimFromStart(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return value.substring(value.length - maxLength).trimLeft();
  }

  String _cleanFact(String value) {
    return _singleLine(value)
        .replaceFirst(RegExp(r'[.!?]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _singleLine(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _clip(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, max(0, maxLength - 3)).trim()}...';
  }
}

class _ParsedConversationMemory {
  final _ConversationRuntimeState state;
  final String summary;

  const _ParsedConversationMemory({required this.state, required this.summary});
}

class _ConversationRuntimeState {
  final bool alreadyGreeted;
  final String? currentTopic;
  final String? currentGoal;
  final String? pendingQuestion;
  final String? lastMode;
  final String? lastGeneratedCardType;

  const _ConversationRuntimeState({
    this.alreadyGreeted = false,
    this.currentTopic,
    this.currentGoal,
    this.pendingQuestion,
    this.lastMode,
    this.lastGeneratedCardType,
  });

  factory _ConversationRuntimeState.fromJson(Map<String, dynamic> json) {
    return _ConversationRuntimeState(
      alreadyGreeted: json['alreadyGreeted'] == true,
      currentTopic: json['currentTopic']?.toString(),
      currentGoal: json['currentGoal']?.toString(),
      pendingQuestion: json['pendingQuestion']?.toString(),
      lastMode: json['lastMode']?.toString(),
      lastGeneratedCardType: json['lastGeneratedCardType']?.toString(),
    );
  }

  _ConversationRuntimeState copyWith({
    bool? alreadyGreeted,
    String? currentTopic,
    String? currentGoal,
    String? pendingQuestion,
    String? lastMode,
    String? lastGeneratedCardType,
  }) {
    return _ConversationRuntimeState(
      alreadyGreeted: alreadyGreeted ?? this.alreadyGreeted,
      currentTopic: currentTopic ?? this.currentTopic,
      currentGoal: currentGoal ?? this.currentGoal,
      pendingQuestion: pendingQuestion ?? this.pendingQuestion,
      lastMode: lastMode ?? this.lastMode,
      lastGeneratedCardType:
          lastGeneratedCardType ?? this.lastGeneratedCardType,
    );
  }

  Map<String, Object?> toJson() => {
    'alreadyGreeted': alreadyGreeted,
    'currentTopic': currentTopic,
    'currentGoal': currentGoal,
    'pendingQuestion': pendingQuestion,
    'lastMode': lastMode,
    'lastGeneratedCardType': lastGeneratedCardType,
  };
}

class _MemoryRule {
  final String kind;
  final String key;
  final RegExp pattern;
  final double confidence;

  const _MemoryRule({
    required this.kind,
    required this.key,
    required this.pattern,
    required this.confidence,
  });
}
