import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

final doomscrollBackgroundServiceProvider =
    AsyncNotifierProvider<DoomscrollBackgroundServiceNotifier, bool>(
      DoomscrollBackgroundServiceNotifier.new,
    );

class DoomscrollBackgroundServiceNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return await _checkStatus();
  }

  Future<bool> _checkStatus() async {
    final service = GetIt.instance<MethodChannelServiceInterface>();
    return await service.isServiceRunning();
  }

  Future<void> start(
    Map<String, int> appTimeLimits,
    int appJumpThresholdMs,
  ) async {
    state = const AsyncValue.loading();
    final service = GetIt.instance<MethodChannelServiceInterface>();
    state = await AsyncValue.guard(() async {
      await service.startDetectionService(
        appTimeLimits: appTimeLimits,
        appJumpThresholdMs: appJumpThresholdMs,
      );
      return true;
    });
  }

  Future<void> stop() async {
    state = const AsyncValue.loading();
    final service = GetIt.instance<MethodChannelServiceInterface>();
    state = await AsyncValue.guard(() async {
      await service.stopDetectionService();
      return false;
    });
  }
}
