import 'package:flutter_test/flutter_test.dart';

import 'package:context_shift/presentation/screens/chat/dictation_text.dart';

void main() {
  test('appends a new dictated segment to existing composer text', () {
    expect(
      mergeDictationText('Plan my week', 'and include German practice'),
      'Plan my week and include German practice',
    );
  });

  test('does not duplicate overlapping recognition results', () {
    expect(
      mergeDictationText('I want to learn', 'to learn German tomorrow'),
      'I want to learn German tomorrow',
    );
  });

  test('keeps the existing text when the latest result is empty', () {
    expect(mergeDictationText('Keep this context', ''), 'Keep this context');
  });

  test('keeps committed words when recognition starts a new session', () {
    final transcript = DictationTranscript('Plan my week');

    transcript.update('with German practice', isFinal: false);
    transcript.commitSession();
    transcript.update('and data mining', isFinal: false);

    expect(
      transcript.text,
      'Plan my week with German practice and data mining',
    );
  });

  test('an empty partial result never clears a long prompt', () {
    final transcript = DictationTranscript('Keep every detail in this prompt');

    transcript.update('including my project work', isFinal: true);
    transcript.update('', isFinal: false);

    expect(
      transcript.text,
      'Keep every detail in this prompt including my project work',
    );
  });

  test('final results are not duplicated when sessions overlap', () {
    final transcript = DictationTranscript('I want to learn');

    transcript.update('to learn German tomorrow', isFinal: true);
    transcript.update('German tomorrow and review vocabulary', isFinal: true);

    expect(
      transcript.text,
      'I want to learn German tomorrow and review vocabulary',
    );
  });
}
