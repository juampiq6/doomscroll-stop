import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';
import 'package:flutter/services.dart';

class MethodChannelService implements MethodChannelServiceInterface {
  static const platform = MethodChannel(
    'com.example.doomscroll_stop/doomscroll',
  );
  MethodChannelService();

  @override
  Future<void> startDetectionService({
    required Map<String, int> appTimeLimits,
  }) async {
    return await platform.invokeMethod<void>('startService', {
      'appTimeLimits': appTimeLimits,
    });
  }

  @override
  Future<void> stopDetectionService() async {
    await platform.invokeMethod<void>('stopService');
  }

  @override
  Future<bool> isServiceRunning() async {
    return await platform.invokeMethod<bool>('isServiceRunning') ?? false;
  }

  @override
  Future<List<Map<String, dynamic>>> getInstalledApps({
    bool includeSystemApps = false,
  }) async {
    final result = await platform.invokeListMethod<Map<dynamic, dynamic>>(
      'getInstalledApps',
      {'includeSystemApps': includeSystemApps},
    );
    if (result == null) return [];

    return result.map((app) => app.cast<String, dynamic>()).toList();
  }

  @override
  Future<Map<String, Map<String, dynamic>>> getAppUsageStats({
    required int beginTime,
    required int endTime,
    Set<String>? filteredAppPackages,
  }) async {
    final result = await platform
        .invokeMethod<Map<dynamic, dynamic>>('getAppUsageStats', {
          'beginTime': beginTime,
          'endTime': endTime,
          'filteredAppPackages': ?filteredAppPackages?.toList(),
        });

    if (result == null) return {};

    return result.map<String, Map<String, dynamic>>(
      (key, value) => MapEntry(
        key as String,
        (value as Map<dynamic, dynamic>).cast<String, dynamic>(),
      ),
    );
  }

  @override
  Future<void> testNotification() async {
    await platform.invokeMethod<void>('testNotification');
  }

  @override
  Future<bool> hasUsagePermission() async {
    return await platform.invokeMethod<bool>('hasUsagePermission') ?? false;
  }

  @override
  Future<void> openUsageSettings() async {
    await platform.invokeMethod<void>('openUsageSettings');
  }
}
