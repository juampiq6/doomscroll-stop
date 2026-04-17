import 'package:doomscroll_stop/repositories/preferences_repository.dart';
import 'package:doomscroll_stop/services/db_service/local_storage_service_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doomscroll_stop/providers/doomscroll_background_service_provider.dart';
import 'package:get_it/get_it.dart';

const maxMinutes = 300;
const defaultAppJumpThresholdMs = 30000;

class AppPreferencesNotifier extends AsyncNotifier<Map<String, int>> {
  @override
  Future<Map<String, int>> build() async {
    final userPrefs = await (await GetIt.I.getAsync<PreferencesRepository>())
        .getPreferences();
    return userPrefs;
  }

  void updateLimit(String packageName, int seconds) {
    final newLimits = Map<String, int>.from(state.value!);
    newLimits[packageName] = seconds;
    state = AsyncValue.data(newLimits);
  }

  void removeApp(String packageName) {
    final newLimits = Map<String, int>.from(state.value!);
    newLimits.remove(packageName);
    state = AsyncValue.data(newLimits);
  }

  Future<void> saveAndApply() async {
    final currentValue = state.value!;

    await GetIt.I.get<LocalStorageInterface>().savePreferences(currentValue);

    final serviceNotifier = ref.read(
      doomscrollBackgroundServiceProvider.notifier,
    );
    // Stop if running, then start if not empty
    await serviceNotifier.stop();

    if (currentValue.isNotEmpty) {
      await serviceNotifier.start(currentValue, defaultAppJumpThresholdMs);
    }
  }
}

final appPreferencesProvider =
    AsyncNotifierProvider<AppPreferencesNotifier, Map<String, int>>(
      AppPreferencesNotifier.new,
    );
