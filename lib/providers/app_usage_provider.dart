import 'package:doomscroll_stop/models/app_session.dart';
import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

class AppUsageState {
  final List<AppUsage> usageList;
  final int beginTime;
  final int endTime;

  AppUsageState({
    required this.usageList,
    required this.beginTime,
    required this.endTime,
  });
}

final appUsageProvider = AsyncNotifierProvider<AppUsageNotifier, AppUsageState>(
  AppUsageNotifier.new,
);

class AppUsageNotifier extends AsyncNotifier<AppUsageState> {
  @override
  Future<AppUsageState> build() async {
    return _fetch(const Duration(days: 1));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(const Duration(days: 1)));
  }

  Future<AppUsageState> _fetch(Duration window) async {
    final service = GetIt.instance<MethodChannelServiceInterface>();
    final now = DateTime.now().millisecondsSinceEpoch;
    final beginTime = DateTime.now().subtract(window).millisecondsSinceEpoch;

    final rawStats = await service.getAppUsageStats(
      beginTime: beginTime,
      endTime: now,
    );

    // Filter out apps with zero usage time to keep the list clean
    final usageList =
        rawStats.entries
            .map((entry) => AppUsage.fromSessions(entry.key, entry.value))
            .where((usage) => usage.totalTimeMs > 0)
            .toList()
          ..sort((a, b) => b.totalTimeMs.compareTo(a.totalTimeMs));

    return AppUsageState(
      usageList: usageList,
      beginTime: beginTime,
      endTime: now,
    );
  }
}
