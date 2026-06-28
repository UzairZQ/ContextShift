import 'dart:convert';
import 'dart:math';

import '../database/database_service.dart';
import '../database/schema.dart';

class JarvisMemoryService {
  JarvisMemoryService._();
  static final JarvisMemoryService instance = JarvisMemoryService._();

  static const int _maxSummaryLength = 1800;

  Future<void> recordTurn({
    required int conversationId,
    required String userMessage,
    required String assistantResponse,
  }) async {
    await Future.wait([
      _updateConversationSummary(
        conversationId: conversationId,
        userMessage: userMessage,
        assistantResponse: assistantResponse,
      ),
      _learnExplicitUserFacts(userMessage),
    ]);
  }

  Future<Map<String, Object?>> buildMemoryContext({int? conversationId}) async {
    final memories = await DatabaseService.instance.getJarvisMemories();
    final conversationMemory = conversationId == null
        ? null
        : await DatabaseService.instance.getConversationMemory(conversationId);

    return <String, Object?>{
      'conversationSummary': conversationMemory?.summary,
      'openQuestions': _decodeOpenQuestions(conversationMemory),
      'learnedUserMemory': memories.map(_memoryToJson).toList(),
    };
  }

  Future<void> _updateConversationSummary({
    required int conversationId,
    required String userMessage,
    required String assistantResponse,
  }) async {
    final existing = await DatabaseService.instance.getConversationMemory(
      conversationId,
    );
    final current = existing?.summary.trim() ?? '';
    final turn = _compactTurn(userMessage, assistantResponse);
    final merged = current.isEmpty ? turn : '$current\n$turn';
    await DatabaseService.instance.upsertConversationMemory(
      conversationId: conversationId,
      summary: _trimFromStart(merged, _maxSummaryLength),
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
          r"\b(?:call me|my name is|i am|i'm)\s+([a-z][a-z\s]{1,40})",
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
