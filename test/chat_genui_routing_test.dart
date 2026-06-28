import 'package:context_shift/core/ai/jarvis_intent_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes creative structured prompts to GenUI', () async {
    expect(
      (await JarvisIntentRouter.instance.classify(
        message: 'Can you build me a work plan for tomorrow for full body?',
      )).intent,
      JarvisIntent.genui,
    );
    expect(
      (await JarvisIntentRouter.instance.classify(
        message: 'Generate a workout checklist for legs',
      )).intent,
      JarvisIntent.genui,
    );
    expect(
      (await JarvisIntentRouter.instance.classify(
        message: 'Design a dashboard for my habits',
      )).intent,
      JarvisIntent.genui,
    );
  });

  test('keeps concrete app commands out of GenUI', () async {
    expect(
      (await JarvisIntentRouter.instance.classify(
        message: 'add task buy groceries',
      )).intent,
      JarvisIntent.action,
    );
    expect(
      (await JarvisIntentRouter.instance.classify(
        message: 'start focus 25 min',
      )).intent,
      JarvisIntent.action,
    );
    expect(
      (await JarvisIntentRouter.instance.classify(
        message: 'how should I plan my afternoon?',
      )).intent,
      JarvisIntent.chat,
    );
  });
}
