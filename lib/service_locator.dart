import 'package:doomscroll_stop/services/db_service/local_storage_service.dart';
import 'package:doomscroll_stop/services/db_service/local_storage_service_interface.dart';
import 'package:doomscroll_stop/services/method_channel_service/method_channel_service.dart';
import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';
import 'package:doomscroll_stop/services/permission_service/permission_service.dart';
import 'package:doomscroll_stop/services/permission_service/permission_service_interface.dart';
import 'package:doomscroll_stop/repositories/preferences_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _getIt = GetIt.I;

void configureDependencies() {
  _getIt.registerLazySingleton<MethodChannelServiceInterface>(
    MethodChannelService.new,
  );
  _getIt.registerLazySingleton<PermissionServiceInterface>(
    () => PermissionService(_getIt.get<MethodChannelServiceInterface>()),
  );
  _getIt.registerSingletonAsync<LocalStorageInterface>(
    () async => LocalStorageService(await SharedPreferences.getInstance()),
  );
  _getIt.registerLazySingletonAsync<PreferencesRepository>(
    () async =>
        PreferencesRepository(await _getIt.getAsync<LocalStorageInterface>()),
  );
}
