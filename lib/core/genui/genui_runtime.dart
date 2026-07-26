import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../ai/context_provider.dart';
import '../local_llm/gemma_service.dart';

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
  JarvisGenUiRuntime();

  Future<GenUiGeneration> generate({
    required String userMessage,
    int? conversationId,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final first = await _generateOnce(
        userMessage: userMessage,
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
    final localContext = await ContextProvider.instance.buildGenUiContext(
      conversationId: conversationId,
      userMessage: userMessage,
    );
    final prompt = _buildSurfaceSpecPrompt(
      request: userMessage,
      localContext: localContext,
    );
    debugPrint('[GenUI] E2B spec prompt length=${prompt.length}');
    final modelText = await GemmaService.instance.generate(
      prompt,
      maxTokens: _maxOutputTokensForRequest(userMessage),
      temperature: 0.2,
      timeout: timeout,
    );
    var spec = _parseSurfaceSpec(modelText);
    spec ??= await _repairSurfaceSpec(
      userMessage: userMessage,
      invalidOutput: modelText,
      timeout: timeout,
    );
    if (spec == null) {
      debugPrint('[GenUI] Gemma surface spec was not valid JSON: $modelText');
      return const GenUiGeneration(
        text: '',
        rawA2ui: '',
        surfaceIds: [],
        source: GenUiGenerationSource.gemma,
        elapsed: Duration.zero,
      );
    }

    final rawA2ui = _a2uiFromSpec(spec, userMessage);

    return GenUiGeneration(
      text: _responseTextFromSpec(spec),
      rawA2ui: rawA2ui,
      surfaceIds: const ['jarvis_generated'],
      source: GenUiGenerationSource.gemma,
      elapsed: Duration.zero,
    );
  }

  Future<Map<String, Object?>?> _repairSurfaceSpec({
    required String userMessage,
    required String invalidOutput,
    required Duration timeout,
  }) async {
    final clipped = invalidOutput.length > 900
        ? invalidOutput.substring(0, 900)
        : invalidOutput;
    final prompt =
        '''
Your previous card spec was invalid or incomplete JSON.
Return one corrected compact JSON object only. No Markdown. No comments.

Allowed shapes:
Workout: {"domain":"workout","title":"","subtitle":"","exercises":[{"name":"","sets":"","reps":"","duration":"","rest":"","cue":""}],"tips":[""],"actionTitle":""}
Schedule: {"domain":"schedule","title":"","subtitle":"","timeline":[{"time":"","title":"","detail":""}],"tips":[""],"actionTitle":""}
Other: {"domain":"plan","title":"","subtitle":"","items":[{"title":"","detail":""}],"tips":[""],"actionTitle":""}

Rules:
- Pick the best shape for the original request.
- Maximum 4 exercises, 5 timeline blocks, or 5 items.
- Short values. Finish the JSON object.

Original request: $userMessage

Invalid output:
$clipped
''';

    try {
      debugPrint('[GenUI] Repairing invalid Gemma spec');
      final repaired = await GemmaService.instance.generate(
        prompt,
        maxTokens: _maxOutputTokensForRequest(userMessage),
        temperature: 0.1,
        timeout: timeout,
      );
      return _parseSurfaceSpec(repaired);
    } catch (error, stackTrace) {
      debugPrint('[GenUI] Gemma spec repair failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  void dispose() {}

  String _buildSurfaceSpecPrompt({
    required String request,
    required Map<String, Object?> localContext,
  }) {
    final forcedRefineDomain = _refineDomainFromRequest(request);
    final isWorkout = RegExp(
      r'\b(workout|work out|exercise|training|full body|strength|gym|cardio)\b',
      caseSensitive: false,
    ).hasMatch(request);
    if (forcedRefineDomain != null &&
        forcedRefineDomain != 'workout' &&
        forcedRefineDomain != 'schedule') {
      return '''
You are JARVIS inside ContextShift. Return one compact JSON object only.
No Markdown. No comments. No keys except the schema keys.

Schema:
{"domain":"$forcedRefineDomain","title":"","subtitle":"","items":[{"title":"","detail":""}],"tips":[""],"actionTitle":""}

Rules:
- Keep domain exactly "$forcedRefineDomain".
- Use 3-5 useful items.
- No timeline, no exercises, no extra keys.
- Short values. Finish the JSON object.

Ground titles and content in the Context JSON (profile, tasks, habits, memory) when it helps.
Context JSON:
${jsonEncode(localContext)}

User request: $request
''';
    }
    if (isWorkout) {
      return '''
You are JARVIS inside ContextShift. Return one compact JSON object only.
No Markdown. No comments. No keys except the schema keys.

Schema:
{"domain":"workout","title":"","subtitle":"","exercises":[{"name":"","sets":"","reps":"","duration":"","rest":"","cue":""}],"tips":[""],"actionTitle":""}

Rules:
- Exactly 4 exercise objects.
- No timeline, no items, no extra keys.
- Short values. Finish the JSON object.
- Use safe beginner/intermediate defaults if details are missing.

Ground titles and content in the Context JSON (profile, tasks, habits, memory) when it helps.
Context JSON:
${jsonEncode(localContext)}

User request: $request
''';
    }

    final isSchedule = RegExp(
      r'\b(schedule|calendar|timeline|itinerary|tomorrow|today|week|day plan|time block|time-blocked)\b',
      caseSensitive: false,
    ).hasMatch(request);
    if (isSchedule) {
      return '''
You are JARVIS inside ContextShift. Return one compact JSON object only.
No Markdown. No comments. No keys except the schema keys.

Schema:
{"domain":"schedule","title":"","subtitle":"","timeline":[{"time":"","title":"","detail":""}],"tips":[""],"actionTitle":""}

Rules:
- Exactly 5 timeline objects.
- Include concrete times or durations in the time fields.
- Cover every named priority in the request.
- Include breaks and one low-energy fallback block.
- Short values. Finish the JSON object.

Ground titles and content in the Context JSON (profile, tasks, habits, memory) when it helps.
Context JSON:
${jsonEncode(localContext)}

User request: $request
''';
    }

    return '''
You are JARVIS inside ContextShift. Return one compact JSON object only.
No Markdown. No comments. Keep values short and useful.

Schema:
{"domain":"workout|schedule|dashboard|comparison|tracker|form|checklist|plan","title":"","subtitle":"","exercises":[{"name":"","sets":"","reps":"","duration":"","rest":"","cue":""}],"timeline":[{"time":"","title":"","detail":""}],"items":[{"title":"","detail":""}],"tips":[""],"actionTitle":""}

Rules:
- For workout requests, include 3-4 safe exercises with sets/reps/rest/cues.
- For schedule requests, include timeline items with times.
- For everything else, use items and tips.
- Use sensible defaults if details are missing.
- Maximum 4 exercises, 5 items, 3 tips.

Ground titles and content in the Context JSON (profile, tasks, habits, memory) when it helps.
Context JSON:
${jsonEncode(localContext)}

User request: $request
''';
  }

  int _maxOutputTokensForRequest(String request) {
    final forcedRefineDomain = _refineDomainFromRequest(request);
    if (forcedRefineDomain != null && forcedRefineDomain != 'schedule') {
      return 280;
    }
    if (RegExp(
      r'\b(schedule|calendar|timeline|itinerary|time block|time-blocked)\b',
      caseSensitive: false,
    ).hasMatch(request)) {
      return 360;
    }
    return 280;
  }

  String? _refineDomainFromRequest(String request) {
    final match = RegExp(
      r'refine this gemma-generated\s+([a-z]+)\s+card',
      caseSensitive: false,
    ).firstMatch(request);
    final domain = match?.group(1)?.toLowerCase();
    return switch (domain) {
      'workout' => 'workout',
      'schedule' => 'schedule',
      'dashboard' => 'dashboard',
      'comparison' => 'comparison',
      'tracker' => 'tracker',
      'form' => 'form',
      'checklist' => 'checklist',
      'plan' => 'plan',
      _ => null,
    };
  }

  Map<String, Object?>? _parseSurfaceSpec(String text) {
    final trimmed = text.trim();
    final fenced = RegExp(
      r'```(?:json)?\s*([\s\S]*?)\s*```',
    ).firstMatch(trimmed);
    final candidate = fenced?.group(1) ?? _firstJsonObject(trimmed);
    if (candidate == null) return _partialSurfaceSpec(trimmed);
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is Map) return Map<String, Object?>.from(decoded);
    } catch (_) {
      return _partialSurfaceSpec(trimmed);
    }
    return _partialSurfaceSpec(trimmed);
  }

  String? _firstJsonObject(String text) {
    final start = text.indexOf('{');
    if (start == -1) return null;

    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = start; i < text.length; i++) {
      final char = text[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;
      if (char == '{') depth++;
      if (char == '}') {
        depth--;
        if (depth == 0) return text.substring(start, i + 1);
      }
    }
    return null;
  }

  Map<String, Object?>? _partialSurfaceSpec(String text) {
    final exercises = _partialObjectsWithKey(text, 'name');
    if (exercises.isNotEmpty) {
      debugPrint(
        '[GenUI] Recovered partial Gemma workout spec with '
        '${exercises.length} exercises',
      );
      return {
        'domain': _regexValue(text, 'domain') ?? 'workout',
        'title': _regexValue(text, 'title') ?? 'Generated workout',
        'subtitle': _regexValue(text, 'subtitle') ?? 'Gemma-generated plan',
        'exercises': exercises,
        'tips': const ['Warm up first', 'Keep form clean'],
        'actionTitle': _regexValue(text, 'actionTitle') ?? 'Workout plan',
      };
    }

    final timeline = _partialObjectsWithKey(text, 'time');
    if (timeline.isNotEmpty) {
      debugPrint(
        '[GenUI] Recovered partial Gemma schedule spec with '
        '${timeline.length} blocks',
      );
      return {
        'domain': _regexValue(text, 'domain') ?? 'schedule',
        'title': _regexValue(text, 'title') ?? 'Generated schedule',
        'subtitle': _regexValue(text, 'subtitle') ?? 'Gemma-generated plan',
        'timeline': timeline,
        'tips': const ['Protect breaks', 'Keep the fallback priority visible'],
        'actionTitle': _regexValue(text, 'actionTitle') ?? 'Schedule plan',
      };
    }

    return null;
  }

  List<Map<String, Object?>> _partialObjectsWithKey(String text, String key) {
    final objects = <Map<String, Object?>>[];
    final pattern = RegExp('\\{[^{}]*"$key"[^{}]*\\}');
    for (final match in pattern.allMatches(text)) {
      try {
        final decoded = jsonDecode(match.group(0)!);
        if (decoded is Map) {
          objects.add(Map<String, Object?>.from(decoded));
        }
      } catch (_) {
        continue;
      }
    }
    return objects;
  }

  String? _regexValue(String text, String key) {
    final match = RegExp('"$key"\\s*:\\s*"([^"]*)"').firstMatch(text);
    return match?.group(1);
  }

  String _a2uiFromSpec(Map<String, Object?> spec, String userMessage) {
    final domain = _cleanText(spec['domain'], fallback: 'plan').toLowerCase();
    final title = _cleanText(
      spec['title'],
      fallback: _fallbackTitle(
        userMessage,
        _fallbackDomain(userMessage.toLowerCase()),
      ),
    );
    final subtitle = _cleanText(
      spec['subtitle'],
      fallback: 'Generated locally with Gemma.',
    );
    final exercises = _mapList(spec['exercises']).take(4).toList();
    final timeline = _mapList(spec['timeline']).take(5).toList();
    final items = _mapList(spec['items']).take(5).toList();
    final tips = _stringList(spec['tips']).take(3).toList();
    final tone = _toneForDomain(domain);
    final supportTone = tone == 'warning' ? 'primary' : 'accent';
    final children = <String>['hero'];
    final components = <Map<String, Object?>>[
      {'id': 'root', 'component': 'Column', 'children': children},
      {
        'id': 'hero',
        'component': 'HeroPanel',
        'eyebrow': _domainLabel(domain),
        'title': title,
        'subtitle': subtitle,
        'tone': tone,
      },
    ];

    if (exercises.isNotEmpty) {
      children.add('main');
      components.add({
        'id': 'main',
        'component': 'WorkoutBlock',
        'title': _domainLabel(domain) == 'Workout' ? 'Main block' : title,
        'focus': subtitle,
        'tone': tone,
        'exercises': exercises.map(_exerciseJson).toList(),
      });
    } else if (timeline.isNotEmpty) {
      children.add('timeline');
      components.add({
        'id': 'timeline',
        'component': 'Timeline',
        'title': 'Timeline',
        'tone': tone,
        'items': timeline.map(_timelineJson).toList(),
      });
    } else {
      children.add('main');
      components.add({
        'id': 'main',
        'component': 'Checklist',
        'title': _domainLabel(domain),
        'tone': tone,
        'items': (items.isEmpty ? _defaultItems(userMessage) : items)
            .map(_itemJson)
            .toList(),
      });
    }

    if (tips.isNotEmpty) {
      children.add('tips');
      components.add({
        'id': 'tips',
        'component': 'Checklist',
        'title': 'Keep in mind',
        'tone': supportTone,
        'items': tips.map((tip) => {'title': tip}).toList(),
      });
    }

    children.add('actions');
    final actions = <Map<String, Object?>>[
      {
        'label': 'Save card',
        'event': 'save_card',
        'title': title,
        'domain': domain,
      },
      if (timeline.isNotEmpty)
        {
          'label': 'Edit times',
          'event': 'edit_schedule_times',
          'title': title,
          'domain': domain,
        },
      if (timeline.isNotEmpty)
        {
          'label': 'Add tasks',
          'event': 'add_schedule_to_tasks',
          'title': title,
          'domain': domain,
        },
      {
        'label': 'Refine',
        'event': 'continue_conversation',
        'message': _refineMessageFromSpec(spec, userMessage),
      },
    ];
    components.add({
      'id': 'actions',
      'component': 'ActionDock',
      'tone': tone,
      'actions': actions,
    });

    return _encodeA2ui([
      {
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'jarvis_generated',
          'catalogId': 'https://a2ui.org/specification/v0_9/basic_catalog.json',
          'sendDataModel': true,
        },
      },
      {
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'jarvis_generated',
          'components': components,
        },
      },
    ]);
  }

  String _responseTextFromSpec(Map<String, Object?> spec) {
    final domain = _domainLabel(_cleanText(spec['domain'], fallback: 'card'));
    return 'I built a ${domain.toLowerCase()} card with Gemma.';
  }

  String _refineMessageFromSpec(Map<String, Object?> spec, String userMessage) {
    final domain = _domainLabel(
      _cleanText(spec['domain'], fallback: 'card').toLowerCase(),
    );
    final title = _cleanText(spec['title'], fallback: 'Generated card');
    final subtitle = _cleanText(spec['subtitle']);
    final exercises = _mapList(spec['exercises'])
        .take(4)
        .map((item) {
          final name = _cleanText(item['name'], fallback: 'Exercise');
          final sets = _cleanText(item['sets']);
          final reps = _cleanText(item['reps']);
          final rest = _cleanText(item['rest']);
          final cue = _cleanText(item['cue']);
          return [
            name,
            if (sets.isNotEmpty || reps.isNotEmpty) '$sets x $reps'.trim(),
            if (rest.isNotEmpty) 'rest $rest',
            if (cue.isNotEmpty) cue,
          ].join(' | ');
        })
        .join('; ');
    final items = _mapList(spec['items'])
        .take(5)
        .map((item) => _cleanText(item['title']))
        .where((item) => item.isNotEmpty)
        .join('; ');
    final timeline = _mapList(spec['timeline'])
        .take(5)
        .map((item) {
          final time = _cleanText(item['time']);
          final title = _cleanText(item['title'], fallback: 'Block');
          final detail = _cleanText(item['detail']);
          return [
            if (time.isNotEmpty) time,
            title,
            if (detail.isNotEmpty) detail,
          ].join(' | ');
        })
        .join('; ');
    final tips = _stringList(spec['tips']).take(3).join('; ');

    final currentDetails = [
      'Title: $title',
      if (subtitle.isNotEmpty) 'Subtitle: $subtitle',
      if (exercises.isNotEmpty) 'Exercises: $exercises',
      if (timeline.isNotEmpty) 'Timeline: $timeline',
      if (items.isNotEmpty) 'Items: $items',
      if (tips.isNotEmpty) 'Tips: $tips',
    ].join('\n');

    return '''
Refine this Gemma-generated $domain card into a better second version.

Original request: $userMessage

Current card:
$currentDetails

Improve it by making it more specific, useful, and personalized. Keep what works, fix weak parts, add missing details, and generate a new card instead of only explaining changes.
''';
  }

  String _domainLabel(String domain) {
    return switch (domain) {
      'workout' => 'Workout',
      'schedule' => 'Schedule',
      'dashboard' => 'Dashboard',
      'comparison' => 'Comparison',
      'tracker' => 'Tracker',
      'form' => 'Form',
      'checklist' => 'Checklist',
      _ => 'Plan',
    };
  }

  String _toneForDomain(String domain) {
    return switch (domain.toLowerCase()) {
      'workout' => 'success',
      'checklist' => 'success',
      'schedule' => 'warning',
      'dashboard' => 'accent',
      'comparison' => 'neutral',
      'tracker' => 'accent',
      'form' => 'neutral',
      _ => 'primary',
    };
  }

  List<Map<String, Object?>> _mapList(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .toList();
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => _cleanText(item))
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, Object?> _exerciseJson(Map<String, Object?> item) {
    return {
      'name': _cleanText(item['name'], fallback: 'Movement'),
      'sets': _cleanText(item['sets']),
      'reps': _cleanText(item['reps']),
      'duration': _cleanText(item['duration']),
      'rest': _cleanText(item['rest']),
      'cue': _cleanText(item['cue']),
    };
  }

  Map<String, Object?> _timelineJson(Map<String, Object?> item) {
    return {
      'time': _cleanText(item['time'], fallback: 'Next'),
      'title': _cleanText(item['title'], fallback: 'Block'),
      'detail': _cleanText(item['detail']),
    };
  }

  Map<String, Object?> _itemJson(Map<String, Object?> item) {
    return {
      'title': _cleanText(item['title'], fallback: 'Step'),
      'detail': _cleanText(item['detail']),
    };
  }

  List<Map<String, Object?>> _defaultItems(String userMessage) {
    return [
      {'title': _fallbackTitle(userMessage, _FallbackDomain.plan)},
      {'title': 'Ask JARVIS to refine with more details'},
    ];
  }

  String _cleanText(Object? value, {String fallback = ''}) {
    final text = value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    if (text.isEmpty) return fallback;
    return text.length > 180 ? '${text.substring(0, 177)}...' : text;
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
          {
            'label': 'Save card',
            'event': 'save_card',
            'title': title,
            'domain': domain.label.toLowerCase(),
          },
          if (domain == _FallbackDomain.schedule)
            {
              'label': 'Add tasks',
              'event': 'add_schedule_to_tasks',
              'title': title,
              'domain': domain.label.toLowerCase(),
            },
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
