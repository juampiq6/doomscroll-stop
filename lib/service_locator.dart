import 'package:doomscroll_stop/db_service/local_db_service.dart';
import 'package:doomscroll_stop/db_service/local_db_service_interface.dart';
import 'package:doomscroll_stop/method_channel_service/method_channel_service.dart';
import 'package:doomscroll_stop/method_channel_service/method_channel_service_interface.dart';
import 'package:doomscroll_stop/permission_service/permission_service.dart';
import 'package:doomscroll_stop/permission_service/permission_service_interface.dart';
import 'package:get_it/get_it.dart';

void configureDependencies() {
  GetIt.instance.registerLazySingleton<MethodChannelServiceInterface>(
    () => MethodChannelService(),
  );
  GetIt.instance.registerLazySingleton<LocalDbServiceInterface>(
    () => LocalDbService(),
  );
  GetIt.instance.registerLazySingleton<PermissionServiceInterface>(
    () => PermissionService(GetIt.instance<MethodChannelServiceInterface>()),
  );
}
