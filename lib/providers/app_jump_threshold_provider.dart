import 'package:doomscroll_stop/providers/app_preferences_provider.dart';
import 'package:doomscroll_stop/providers/doomscroll_background_service_provider.dart';
import 'package:doomscroll_stop/services/db_service/local_storage_service_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

final appJumpThresholdProvider =
    AsyncNotifierProvider<AppJumpThresholdNotifier, int>(
      AppJumpThresholdNotifier.new,
    );

class AppJumpThresholdNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    return GetIt.I.get<LocalStorageInterface>().getJumpThresholdMs();
  }

  Future<void> setThreshold(int ms) async {
    await GetIt.I.get<LocalStorageInterface>().saveJumpThresholdMs(ms);
    state = AsyncValue.data(ms);

    final prefs = ref.read(appPreferencesProvider).value;
    if (prefs != null && prefs.isNotEmpty) {
      final service = ref.read(doomscrollBackgroundServiceProvider.notifier);
      await service.stop();
      await service.start(prefs, ms);
    }
  }
}
