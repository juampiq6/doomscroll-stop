abstract interface class MethodChannelServiceInterface {
  Future<void> startDetectionService({
    required Map<String, int> appTimeLimits,
    required int appJumpThresholdMs,
  });

  Future<void> stopDetectionService();

  Future<List<Map<String, dynamic>>> getInstalledApps({
    bool includeSystemApps = false,
  });

  Future<bool> isServiceRunning();

  // Filters query by packages names. Times should be in milli since epoch
  Future<Map<String, Map<String, dynamic>>> getAppUsageStats({
    required int beginTime,
    required int endTime,
    Set<String>? filteredAppPackages,
  });

  Future<void> testNotification();

  Future<bool> hasUsagePermission();

  Future<void> openUsageSettings();
}
