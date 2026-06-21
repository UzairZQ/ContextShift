import 'package:context_shift/presentation/screens/chat/chat_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routes creative structured prompts to GenUI', () {
    expect(
      shouldRouteChatMessageToGenUi(
        'Can you build me a work plan for tomorrow for full body?',
      ),
      isTrue,
    );
    expect(
      shouldRouteChatMessageToGenUi('Generate a workout checklist for legs'),
      isTrue,
    );
    expect(
      shouldRouteChatMessageToGenUi('Design a dashboard for my habits'),
      isTrue,
    );
  });

  test('keeps concrete app commands out of GenUI', () {
    expect(shouldRouteChatMessageToGenUi('add task buy groceries'), isFalse);
    expect(shouldRouteChatMessageToGenUi('start focus 25 min'), isFalse);
    expect(shouldRouteChatMessageToGenUi('show my notes'), isFalse);
  });
}
