import 'package:doomscroll_stop/services/db_service/local_storage_service_interface.dart';

class PreferencesRepository {
  final LocalStorageInterface _localStorageService;

  PreferencesRepository(this._localStorageService);

  Future<void> savePreferences(Map<String, int> appLimits) async {
    await _localStorageService.savePreferences(appLimits);
  }

  Future<Map<String, int>> getPreferences() async {
    return await _localStorageService.getPreferences();
  }
}
