import 'dart:convert';

import 'package:doomscroll_stop/services/db_service/local_storage_service_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService implements LocalStorageInterface {
  final SharedPreferences _sharedPreferences;
  LocalStorageService(this._sharedPreferences);

  @override
  Future<void> savePreferences(Map<String, int> appLimits) async {
    await _sharedPreferences.setString('appLimits', jsonEncode(appLimits));
  }

  @override
  Future<Map<String, int>> getPreferences() async {
    final r = _sharedPreferences.getString('appLimits');
    if (r == null) return {};
    return (jsonDecode(r) as Map<String, dynamic>).cast<String, int>();
  }
}
