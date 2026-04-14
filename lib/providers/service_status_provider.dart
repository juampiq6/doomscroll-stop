import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';
import 'package:get_it/get_it.dart';

class ServiceStatusNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return await _checkStatus();
  }

  Future<bool> _checkStatus() async {
    final service = GetIt.instance<MethodChannelServiceInterface>();
    return await service.isServiceRunning();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _checkStatus());
  }

  // Explicitly update status (e.g. after starting/stopping)
  void updateStatus(bool isRunning) {
    state = AsyncValue.data(isRunning);
  }
}

final serviceStatusProvider =
    AsyncNotifierProvider<ServiceStatusNotifier, bool>(() {
      return ServiceStatusNotifier();
    });
