import 'package:doomscroll_stop/models/app_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doomscroll_stop/services/method_channel_service/method_channel_service_interface.dart';
import 'package:get_it/get_it.dart';

final installedAppsProvider =
    AsyncNotifierProvider<InstalledAppsNotifier, List<AppInfo>>(
      InstalledAppsNotifier.new,
    );

class InstalledAppsNotifier extends AsyncNotifier<List<AppInfo>> {
  @override
  Future<List<AppInfo>> build() async {
    final service = GetIt.instance<MethodChannelServiceInterface>();
    final List<Map<String, dynamic>> apps = await service.getInstalledApps(
      includeSystemApps: false,
    );
    return apps.map((e) => AppInfo.fromMap(e)).toList();
  }
}
