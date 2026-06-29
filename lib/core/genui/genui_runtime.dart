import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';

import '../ai/context_provider.dart';
import '../local_llm/gemma_service.dart';
import 'jarvis_design_catalog.dart';

class GenUiGeneration {
  final String text;
  final String rawA2ui;
  final List<String> surfaceIds;
  final GenUiGenerationSource source;
  final String? fallbackReason;
  final Duration elapsed;

  const GenUiGeneration({
    required this.text,
    required this.rawA2ui,
    required this.surfaceIds,
    required this.source,
    required this.elapsed,
    this.fallbackReason,
  });

  Map<String, dynamic> toPersistenceJson() => {
    'format': 'a2ui-v0.9',
    'raw': rawA2ui,
    'source': source.name,
    'fallbackReason': fallbackReason,
    'elapsedMs': elapsed.inMilliseconds,
  };
}

enum GenUiGenerationSource { gemma, fallback }

enum _FallbackDomain {
  workout('Workout'),
  schedule('Schedule'),
  dashboard('Dashboard'),
  comparison('Comparison'),
  tracker('Tracker'),
  form('Form'),
  checklist('Checklist'),
  plan('Plan');

  final String label;
  const _FallbackDomain(this.label);
}

/// Connects the official GenUI A2UI runtime to the on-device Gemma model.
class JarvisGenUiRuntime {
  JarvisGenUiRuntime() {
    catalog = JarvisDesignCatalog.extend(
      BasicCatalogItems.asNoAssetCatalog(
        systemPromptFragments: const [
          'Use compact, mobile-first layouts that fit ContextShift.',
          'Use the basic Flutter-style GenUI catalog as a creative construction '
              'kit: Column, Row, Card, Text, Button, CheckBox, ChoicePicker, '
              'DateTimeInput, Divider, Icon, List, Modal, Slider, Tabs, and '
              'TextField. Combine them into the UI the user actually needs.',
          'Do not default to the same generic card. First infer the domain and '
              'the job-to-be-done, then choose the smallest useful interface: '
              'for workout requests, include concrete exercise blocks, sets or '
              'time ranges, rest guidance, and progression cues; for schedules, '
              'include time blocks; for choices, include pickers or checkboxes.',
          'For clear plan, routine, workout, schedule, checklist, or dashboard '
              'requests, generate a useful first version instead of asking many '
              'questions. If details are missing, choose sensible safe defaults '
              'and make the assumptions visible in the surface.',
          'Prefer one clear hierarchy and one primary action, but use multiple '
              'sections, tabs, checkboxes, sliders, or inputs when the request '
              'benefits from them.',
          'Use event names create_task, create_habit, create_note, start_focus, '
              'or continue_conversation when an interaction should affect the app.',
        ],
      ),
    );
    controller = SurfaceController(catalogs: [catalog]);
    transport = A2uiTransportAdapter(onSend: _sendToModel);
    conversation = Conversation(controller: controller, transport: transport);
    _eventsSubscription = conversation.events.listen(_handleEvent);
  }

  late final Catalog catalog;
  late final SurfaceController controller;
  late final A2uiTransportAdapter transport;
  late final Conversation conversation;

  final StringBuffer _rawResponse = StringBuffer();
  String _latestText = '';
  int? _conversationId;
  StreamSubscription<ConversationEvent>? _eventsSubscription;

  Future<GenUiGeneration> generate({
    required String userMessage,
    int? conversationId,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final plannedMessage = _withPlanningInstruction(userMessage);
      final first = await _generateOnce(
        userMessage: plannedMessage,
        conversationId: conversationId,
        timeout: timeout,
      );
      if (first.surfaceIds.isNotEmpty && first.rawA2ui.trim().isNotEmpty) {
        stopwatch.stop();
        return GenUiGeneration(
          text: first.text,
          rawA2ui: first.rawA2ui,
          surfaceIds: first.surfaceIds,
          source: GenUiGenerationSource.gemma,
          elapsed: stopwatch.elapsed,
        );
      }

      stopwatch.stop();
      return _fallbackGeneration(
        userMessage,
        reason: 'no-visible-surface',
        elapsed: stopwatch.elapsed,
      );
    } on TimeoutException catch (error) {
      stopwatch.stop();
      debugPrint(
        '[GenUI] Generation timed out, using fallback surface: $error',
      );
      return _fallbackGeneration(
        userMessage,
        reason: 'timeout',
        elapsed: stopwatch.elapsed,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();
      debugPrint('[GenUI] Generation failed, using fallback surface: $error');
      debugPrintStack(stackTrace: stackTrace);
      return _fallbackGeneration(
        userMessage,
        reason: 'runtime-error',
        elapsed: stopwatch.elapsed,
      );
    }
  }

  Future<GenUiGeneration> _generateOnce({
    required String userMessage,
    int? conversationId,
    required Duration timeout,
  }) async {
    _rawResponse.clear();
    _latestText = '';
    _conversationId = conversationId;

    await conversation
        .sendRequest(ChatMessage.user(userMessage))
        .timeout(timeout);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    return GenUiGeneration(
      text: _latestText.trim(),
      rawA2ui: _rawResponse.toString(),
      surfaceIds: controller.activeSurfaceIds.toList(growable: false),
      source: GenUiGenerationSource.gemma,
      elapsed: Duration.zero,
    );
  }

  Future<void> _sendToModel(ChatMessage message) async {
    if (!GemmaService.instance.isModelLoaded) {
      throw const GemmaException(
        code: GemmaErrorCode.modelNotLoaded,
        message: 'The on-device model is not ready.',
      );
    }

    final localContext = await ContextProvider.instance.buildGenUiContext(
      conversationId: _conversationId,
    );
    final prompt = StringBuffer()
      ..writeln(
        PromptBuilder.chat(
          catalog: catalog,
          systemPromptFragments: [
            PromptFragments.acknowledgeUser(),
            PromptFragments.currentDate(),
            'You are JARVIS, a warm, concise, action-oriented private guide.',
            'Respond with short useful text and create a surface only when '
                'interactive or structured UI is genuinely useful.',
            'Before creating UI, silently infer the user intent, the needed '
                'data, and the most helpful component structure. Ask a brief '
                'clarifying question only when a useful UI cannot be made.',
            'When this runtime is called, the app has already decided GenUI is '
                'appropriate. Do not keep interviewing the user. Generate the '
                'card/surface now unless the request is truly unsafe or '
                'impossible without one missing fact.',
            'When creating a surface, avoid pre-made templates. Build a fresh '
                'composition from the available catalog components that fits '
                'the user prompt and any local ContextShift data.',
            'Use jarvisMemory, recentConversation, tasks, habits, notes, mood, '
                'and focus data when relevant. Prefer specific user context '
                'over generic advice.',
            'If the user asks for a plan, routine, workout, dashboard, card, '
                'screen, checklist, program, or visual structure, create an '
                'A2UI surface unless a plain chat answer is clearly better.',
            'For workout plans, use practical defaults when unspecified: '
                'beginner-to-intermediate level, full-body balance, safe warmup, '
                '3 to 5 movements, rest guidance, and one progression cue.',
          ],
          clientDataModel: localContext,
        ).systemPromptJoined(),
      )
      ..writeln('Conversation input:')
      ..writeln(jsonEncode(message.toJson()));

    await for (final token
        in GemmaService.instance
            .generateStream(prompt.toString(), maxTokens: 900, temperature: 0.2)
            .timeout(
              const Duration(seconds: 20),
              onTimeout: (sink) {
                sink.addError(
                  TimeoutException(
                    'JARVIS stream produced no output for 20 seconds.',
                  ),
                );
                sink.close();
              },
            )) {
      _rawResponse.write(token);
      transport.addChunk(token);
    }
    transport.addChunk('\n');
  }

  void _handleEvent(ConversationEvent event) {
    switch (event) {
      case ConversationContentReceived(:final text):
        _latestText = text;
      case ConversationError(:final error, :final stackTrace):
        debugPrint('[GenUI] Conversation failed: $error');
        if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
      default:
        break;
    }
  }

  void dispose() {
    _eventsSubscription?.cancel();
    conversation.dispose();
    transport.dispose();
    controller.dispose();
  }

  String _withPlanningInstruction(String userMessage) {
    return '''
Think silently before answering.
1. Identify the user's real request.
2. Decide whether an interactive/structured surface is useful.
3. Choose only the catalog widgets/components needed.
4. Build a fresh composition grounded in the provided ContextShift data.
5. If the request is a workout, plan, routine, schedule, checklist, dashboard,
   or card, create the surface now. Do not ask follow-up questions unless the
   surface would be unsafe or impossible. Use visible assumptions for missing
   details.

User request: $userMessage
''';
  }

  GenUiGeneration _fallbackGeneration(
    String userMessage, {
    required String reason,
    required Duration elapsed,
  }) {
    final lower = userMessage.toLowerCase();
    final domain = _fallbackDomain(lower);
    final title = _fallbackTitle(userMessage, domain);
    final components = <Map<String, Object?>>[
      {
        'id': 'root',
        'component': 'Column',
        'children': _fallbackChildren(domain),
      },
      {
        'id': 'hero',
        'component': 'HeroPanel',
        'eyebrow': domain.label,
        'title': title,
        'subtitle':
            'A usable first version created locally because the live generated UI hit a $reason fallback.',
        'tone': 'primary',
      },
      {
        'id': 'assumptions',
        'component': 'InsightCallout',
        'title': 'Starter assumptions',
        'body':
            'JARVIS used safe defaults from your request. Add details and ask to refine this card.',
        'tone': 'accent',
        'icon': 'info',
      },
      ..._fallbackBodyComponents(domain),
      {
        'id': 'actions',
        'component': 'ActionDock',
        'tone': 'primary',
        'actions': [
          {'label': 'Save as task', 'event': 'create_task', 'title': title},
          {
            'label': 'Refine',
            'event': 'continue_conversation',
            'message':
                'Refine this generated ${domain.label.toLowerCase()} with more specifics: $userMessage',
          },
        ],
      },
    ];

    return GenUiGeneration(
      text:
          'I made a starter ${domain.label.toLowerCase()} card while JARVIS finished thinking.',
      rawA2ui: _encodeA2ui([
        {
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'jarvis_fallback',
            'catalogId':
                'https://a2ui.org/specification/v0_9/basic_catalog.json',
            'sendDataModel': true,
          },
        },
        {
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': 'jarvis_fallback',
            'components': components,
          },
        },
      ]),
      surfaceIds: const ['jarvis_fallback'],
      source: GenUiGenerationSource.fallback,
      fallbackReason: reason,
      elapsed: elapsed,
    );
  }

  _FallbackDomain _fallbackDomain(String lower) {
    if (RegExp(
      r'\b(workout|work out|exercise|training|full body|strength|gym|cardio)\b',
    ).hasMatch(lower)) {
      return _FallbackDomain.workout;
    }
    if (RegExp(
      r'\b(schedule|calendar|timeline|itinerary|tomorrow|today|week|day plan|time block)\b',
    ).hasMatch(lower)) {
      return _FallbackDomain.schedule;
    }
    if (RegExp(
      r'\b(dashboard|stats|metrics|overview|report|analysis|progress)\b',
    ).hasMatch(lower)) {
      return _FallbackDomain.dashboard;
    }
    if (RegExp(
      r'\b(compare|comparison|versus|vs|pros|cons|choose)\b',
    ).hasMatch(lower)) {
      return _FallbackDomain.comparison;
    }
    if (RegExp(
      r'\b(tracker|track|habit|streak|log|monitor)\b',
    ).hasMatch(lower)) {
      return _FallbackDomain.tracker;
    }
    if (RegExp(
      r'\b(form|input|survey|questionnaire|collect)\b',
    ).hasMatch(lower)) {
      return _FallbackDomain.form;
    }
    if (RegExp(r'\b(checklist|steps|todo|to-do|tasks)\b').hasMatch(lower)) {
      return _FallbackDomain.checklist;
    }
    return _FallbackDomain.plan;
  }

  String _fallbackTitle(String userMessage, _FallbackDomain domain) {
    final cleaned = userMessage
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[?.!]+$'), '')
        .trim();
    if (cleaned.isEmpty) return 'Generated ${domain.label}';
    final max = cleaned.length > 34
        ? '${cleaned.substring(0, 34)}...'
        : cleaned;
    return max[0].toUpperCase() + max.substring(1);
  }

  List<String> _fallbackChildren(_FallbackDomain domain) {
    return switch (domain) {
      _FallbackDomain.workout => [
        'hero',
        'assumptions',
        'workout',
        'support',
        'actions',
      ],
      _FallbackDomain.schedule => [
        'hero',
        'assumptions',
        'timeline',
        'support',
        'actions',
      ],
      _FallbackDomain.dashboard => [
        'hero',
        'assumptions',
        'metric1',
        'metric2',
        'metric3',
        'support',
        'actions',
      ],
      _FallbackDomain.comparison => [
        'hero',
        'assumptions',
        'comparison',
        'support',
        'actions',
      ],
      _FallbackDomain.tracker => [
        'hero',
        'assumptions',
        'progress',
        'support',
        'actions',
      ],
      _FallbackDomain.form => [
        'hero',
        'assumptions',
        'field1',
        'field2',
        'support',
        'actions',
      ],
      _FallbackDomain.checklist || _FallbackDomain.plan => [
        'hero',
        'assumptions',
        'steps',
        'support',
        'actions',
      ],
    };
  }

  List<Map<String, Object?>> _fallbackBodyComponents(_FallbackDomain domain) {
    return switch (domain) {
      _FallbackDomain.workout => [
        {
          'id': 'workout',
          'component': 'WorkoutBlock',
          'title': 'Main Block',
          'focus': 'Safe starter structure',
          'tone': 'primary',
          'exercises': [
            {
              'name': 'Primary movement',
              'sets': '3 sets',
              'reps': '8-12 reps',
              'rest': '60-90 sec',
              'cue': 'Keep form clean and stop before failure.',
            },
            {
              'name': 'Secondary movement',
              'sets': '3 sets',
              'reps': '10 reps',
              'rest': '60 sec',
              'cue': 'Use a controlled tempo.',
            },
          ],
        },
        _supportChecklist([
          'Warm up for 5 minutes',
          'Keep intensity moderate',
          'Progress by one rep or a small weight jump next time',
        ]),
      ],
      _FallbackDomain.schedule => [
        {
          'id': 'timeline',
          'component': 'Timeline',
          'title': 'Draft Timeline',
          'tone': 'primary',
          'items': [
            {
              'time': 'Start',
              'title': 'Set the outcome',
              'body': 'Decide what finished looks like.',
            },
            {
              'time': 'Middle',
              'title': 'Do the core work',
              'body': 'Protect the main block from distractions.',
            },
            {
              'time': 'End',
              'title': 'Review and save',
              'body': 'Capture the next action before closing.',
            },
          ],
        },
        _supportChecklist(['Add exact times', 'Remove one low-value block']),
      ],
      _FallbackDomain.dashboard => [
        _metric('metric1', 'Focus', '0m', 'Update with real progress'),
        _metric('metric2', 'Tasks', '0', 'Open items to review'),
        _metric('metric3', 'Mood', '--', 'Log context when ready'),
        _supportChecklist(['Pick the key metric', 'Review the trend weekly']),
      ],
      _FallbackDomain.comparison => [
        {
          'id': 'comparison',
          'component': 'ComparisonTable',
          'title': 'Decision Draft',
          'tone': 'primary',
          'columns': ['Option', 'Upside', 'Tradeoff'],
          'rows': [
            ['Option A', 'Fastest to try', 'May need refinement'],
            ['Option B', 'More complete', 'Takes more setup'],
          ],
        },
        _supportChecklist(['Add real options', 'Choose based on current goal']),
      ],
      _FallbackDomain.tracker => [
        {
          'id': 'progress',
          'component': 'ProgressMeter',
          'label': 'Starter progress',
          'value': 0.25,
          'caption': 'First version ready to refine',
          'tone': 'primary',
        },
        _supportChecklist(['Define the target', 'Log one update today']),
      ],
      _FallbackDomain.form => [
        {
          'id': 'field1',
          'component': 'TextField',
          'label': 'Main input',
          'placeholder': 'Add the key detail',
        },
        {
          'id': 'field2',
          'component': 'TextField',
          'label': 'Notes',
          'placeholder': 'Add constraints or preferences',
        },
        _supportChecklist(['Collect only what matters', 'Keep it short']),
      ],
      _FallbackDomain.checklist || _FallbackDomain.plan => [
        {
          'id': 'steps',
          'component': 'Checklist',
          'title': 'Starter Steps',
          'tone': 'primary',
          'items': [
            {'title': 'Clarify the outcome'},
            {'title': 'Pick the smallest useful first action'},
            {'title': 'Review and refine with JARVIS'},
          ],
        },
        _supportChecklist(['Use this as a first draft', 'Ask for specifics']),
      ],
    };
  }

  Map<String, Object?> _supportChecklist(List<String> items) {
    return {
      'id': 'support',
      'component': 'Checklist',
      'title': 'Refine next',
      'tone': 'accent',
      'items': items.map((title) => {'title': title}).toList(),
    };
  }

  Map<String, Object?> _metric(
    String id,
    String label,
    String value,
    String caption,
  ) {
    return {
      'id': id,
      'component': 'MetricTile',
      'label': label,
      'value': value,
      'caption': caption,
      'tone': 'primary',
      'icon': 'activity',
    };
  }

  String _encodeA2ui(List<Map<String, Object?>> messages) {
    const encoder = JsonEncoder.withIndent('  ');
    return '```json\n${encoder.convert(messages)}\n```';
  }
}
