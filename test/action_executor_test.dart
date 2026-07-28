import 'package:flutter_test/flutter_test.dart';
import 'package:context_shift/core/ai/action_executor.dart';
import 'package:context_shift/core/ai_service.dart';

void main() {
  test(
    'reports malformed and unsupported actions instead of claiming success',
    () async {
      final result = await ActionExecutor.instance.executeAll([
        AiAction(type: 'add_task', params: const {}),
        AiAction(type: 'not_a_real_action', params: const {}),
      ]);

      expect(result.executedCount, 0);
      expect(result.failedCount, 2);
      expect(result.allSucceeded, isFalse);
    },
  );

  test('reports an empty action batch as successful', () async {
    final result = await ActionExecutor.instance.executeAll(const []);

    expect(result.executedCount, 0);
    expect(result.failedCount, 0);
    expect(result.allSucceeded, isTrue);
  });
}
