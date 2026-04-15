import 'package:doomscroll_stop/models/app_preferences_state.dart';
import 'package:doomscroll_stop/repositories/preferences_repository.dart';
import 'package:doomscroll_stop/services/db_service/local_storage_service_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doomscroll_stop/providers/doomscroll_background_service_provider.dart';
import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';
import 'package:get_it/get_it.dart';

class AppPreferencesNotifier extends AsyncNotifier<AppPreferencesState> {
  @override
  Future<AppPreferencesState> build() async {
    final userPrefs = await (await GetIt.I.getAsync<PreferencesRepository>())
        .getPreferences();
    return AppPreferencesState(appLimits: userPrefs);
  }

  void updateLimit(String packageName, int seconds) {
    final newLimits = Map<String, int>.from(state.value!.appLimits);
    newLimits[packageName] = seconds;
    state = AsyncValue.data(state.value!.copyWith(appLimits: newLimits));
  }

  void removeApp(String packageName) {
    final newLimits = Map<String, int>.from(state.value!.appLimits);
    newLimits.remove(packageName);
    state = AsyncValue.data(state.value!.copyWith(appLimits: newLimits));
  }

  Future<void> saveAndApply() async {
    final currentValue = state.value!.appLimits;

    await GetIt.I.get<LocalStorageInterface>().savePreferences(currentValue);

    final serviceNotifier = ref.read(
      doomscrollBackgroundServiceProvider.notifier,
    );
    // Stop if running, then start if not empty
    await serviceNotifier.stop();

    if (currentValue.isNotEmpty) {
      await serviceNotifier.start(currentValue);
    }
  }
}

final appPreferencesProvider =
    AsyncNotifierProvider<AppPreferencesNotifier, AppPreferencesState>(
      AppPreferencesNotifier.new,
    );
