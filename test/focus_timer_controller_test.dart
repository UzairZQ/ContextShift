import 'package:flutter_test/flutter_test.dart';
import 'package:context_shift/core/services/focus_timer_controller.dart';

void main() {
  test('counts active time from remaining time, not planned duration', () {
    final state = FocusTimerState.initial().copyWith(remainingSeconds: 21 * 60);

    expect(FocusTimerController.activeElapsedMinutes(state), 4);
  });

  test('clamps invalid remaining time and never exceeds the plan', () {
    final initial = FocusTimerState.initial();

    expect(
      FocusTimerController.activeElapsedMinutes(
        initial.copyWith(remainingSeconds: -30),
      ),
      25,
    );
    expect(
      FocusTimerController.activeElapsedMinutes(
        initial.copyWith(remainingSeconds: 26 * 60),
      ),
      0,
    );
  });
}
