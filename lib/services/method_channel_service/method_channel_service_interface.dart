abstract interface class MethodChannelServiceInterface {
  Future<void> startDetectionService({required Map<String, int> appTimeLimits});

  Future<void> stopDetectionService();

  Future<List<Map<String, dynamic>>> getInstalledApps({bool includeSystemApps = false});

  Future<bool> isServiceRunning();

  Future<Map<String, Map<String, dynamic>>> getAppUsageStats({
    required int beginTime,
    required int endTime,
  });

  Future<void> testNotification();

  Future<bool> hasUsagePermission();

  Future<void> openUsageSettings();
}
