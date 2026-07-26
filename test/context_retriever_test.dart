import 'package:context_shift/core/ai/context_retriever.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tokenize drops stopwords and keeps meaningful terms', () {
    final tokens = ContextRetriever.tokenize(
      'Can you help me plan my workout for tomorrow?',
    );
    expect(tokens, containsAll(['help', 'plan', 'workout', 'tomorrow']));
    expect(tokens, isNot(contains('me')));
    expect(tokens, isNot(contains('my')));
    expect(tokens, isNot(contains('you')));
  });

  test('tokenize normalizes punctuation and case', () {
    final tokens = ContextRetriever.tokenize('Ship-It: FINISH the beta!');
    expect(tokens, containsAll(['ship', 'finish', 'beta']));
  });
}
