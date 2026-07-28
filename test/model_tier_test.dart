import 'package:context_shift/core/local_llm/model_tier.dart';
import 'package:context_shift/core/local_llm/model_downloader.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('E2B uses the official LiteRT-LM model format', () {
    final model = ModelDefinition.e2b;

    expect(model.downloadUrl, contains('litert-community'));
    expect(model.downloadUrl, endsWith('gemma-4-E2B-it.litertlm'));
    expect(model.modelId, 'gemma-4-E2B-it.litertlm');
    expect(model.fileType, ModelFileType.litertlm);
    expect(model.requiresPurchase, isFalse);
    expect(model.contextTokens, 4096);
  });

  test('download speed uses elapsed bytes instead of a placeholder zero', () {
    expect(
      estimateDownloadSpeed(
        downloadedBytes: 4 * 1024 * 1024,
        elapsed: const Duration(seconds: 2),
      ),
      2 * 1024 * 1024,
    );
    expect(
      estimateDownloadSpeed(
        downloadedBytes: 0,
        elapsed: const Duration(seconds: 2),
      ),
      0,
    );
  });
}
