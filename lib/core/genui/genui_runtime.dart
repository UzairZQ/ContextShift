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

  const GenUiGeneration({
    required this.text,
    required this.rawA2ui,
    required this.surfaceIds,
  });

  Map<String, dynamic> toPersistenceJson() => {
    'format': 'a2ui-v0.9',
    'raw': rawA2ui,
  };
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
            'When creating a surface, avoid pre-made templates. Build a fresh '
                'composition from the available catalog components that fits '
                'the user prompt and any local ContextShift data.',
            'If the user asks for a plan, routine, workout, dashboard, card, '
                'screen, checklist, program, or visual structure, create an '
                'A2UI surface unless a plain chat answer is clearly better.',
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
              const Duration(seconds: 30),
              onTimeout: (sink) {
                sink.addError(
                  TimeoutException(
                    'JARVIS stream produced no output for 30 seconds.',
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
}
