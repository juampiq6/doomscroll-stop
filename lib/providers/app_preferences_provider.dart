import 'package:doomscroll_stop/services/db_service/local_storage_service_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';
import 'package:get_it/get_it.dart';

class AppPreferencesState {
  final Map<String, int> appLimits; // packageName -> seconds

  AppPreferencesState({this.appLimits = const {}});

  AppPreferencesState copyWith({Map<String, int>? appLimits}) {
    return AppPreferencesState(appLimits: appLimits ?? this.appLimits);
  }
}

class AppPreferencesNotifier extends AsyncNotifier<AppPreferencesState> {
  @override
  Future<AppPreferencesState> build() async {
    final userPrefs = await GetIt.I
        .get<LocalStorageInterface>()
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

    final methodChannelService =
        GetIt.instance<MethodChannelServiceInterface>();
    methodChannelService.stopDetectionService();

    if (currentValue.isNotEmpty) {
      // TODO: Create a better service provider so that we can also update the service status in the UI
      await methodChannelService.startDetectionService(
        appTimeLimits: currentValue,
      );
    }
  }
}

final appPreferencesProvider =
    AsyncNotifierProvider<AppPreferencesNotifier, AppPreferencesState>(
      AppPreferencesNotifier.new,
    );
