enum JarvisHomeStatus { checking, downloadRequired, standby, waking, ready }

JarvisHomeStatus resolveJarvisHomeStatus({
  required bool hasCheckedAvailability,
  required bool isDownloaded,
  required bool isLoading,
  required bool isLoaded,
}) {
  if (!hasCheckedAvailability) return JarvisHomeStatus.checking;
  if (!isDownloaded) return JarvisHomeStatus.downloadRequired;
  if (isLoaded) return JarvisHomeStatus.ready;
  if (isLoading) return JarvisHomeStatus.waking;
  return JarvisHomeStatus.standby;
}
