import 'package:context_shift/core/local_llm/model_tier.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('E2B uses the official LiteRT-LM model format', () {
    final model = ModelDefinition.e2b;

    expect(model.downloadUrl, contains('litert-community'));
    expect(model.downloadUrl, endsWith('model.litertlm'));
    expect(model.fileType, ModelFileType.litertlm);
    expect(model.requiresPurchase, isFalse);
  });
}
