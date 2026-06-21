import 'package:context_shift/core/genui/action_bus.dart';
import 'package:context_shift/core/genui/widget_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GenUI actions are emitted to the application action loop', () async {
    final nextAction = GenUiActionBus.instance.actions.first;
    GenUiActionBus.instance.emit(
      WidgetAction(
        action: 'create_task',
        params: const {'title': 'Plan tomorrow'},
      ),
    );

    final action = await nextAction;
    expect(action.action, 'create_task');
    expect(action.params['title'], 'Plan tomorrow');
  });
}
