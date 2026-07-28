import 'package:context_shift/presentation/screens/home/jarvis_home_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not show download state before availability is checked', () {
    expect(
      resolveJarvisHomeStatus(
        hasCheckedAvailability: false,
        isDownloaded: false,
        isLoading: false,
        isLoaded: false,
      ),
      JarvisHomeStatus.checking,
    );
  });

  test('shows standby for an installed model that is not in memory', () {
    expect(
      resolveJarvisHomeStatus(
        hasCheckedAvailability: true,
        isDownloaded: true,
        isLoading: false,
        isLoaded: false,
      ),
      JarvisHomeStatus.standby,
    );
  });

  test('loaded state wins after model warm-up completes', () {
    expect(
      resolveJarvisHomeStatus(
        hasCheckedAvailability: true,
        isDownloaded: true,
        isLoading: true,
        isLoaded: true,
      ),
      JarvisHomeStatus.ready,
    );
  });
}
