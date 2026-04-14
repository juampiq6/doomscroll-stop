import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doomscroll_stop/permission_service/permission_service_interface.dart';
import 'package:get_it/get_it.dart';

enum PermissionType { notification, usage }

class PermissionState {
  // 0 = granted, 1 = denied, 2 = permanently denied
  final int status;
  final String? error;

  PermissionState({required this.status, this.error});

  bool get isGranted => status == 0;
  bool get isPermanentlyDenied => status == 2;
}

final permissionProvider =
    AsyncNotifierProvider.family<
      PermissionNotifier,
      PermissionState,
      PermissionType
    >(PermissionNotifier.new);

class PermissionNotifier extends AsyncNotifier<PermissionState> {
  final PermissionType _type;
  PermissionNotifier(this._type);

  @override
  Future<PermissionState> build() async {
    return await _checkPermission(_type);
  }

  Future<PermissionState> _checkPermission(PermissionType type) async {
    final service = GetIt.instance<PermissionServiceInterface>();

    if (type == PermissionType.notification) {
      final notifGranted = await service.notificationPermissionStatus();
      if (notifGranted == NotificationPermissionStatus.granted) {
        return PermissionState(status: 0);
      } else if (notifGranted ==
          NotificationPermissionStatus.permanentlyDenied) {
        return PermissionState(
          status: 2,
          error:
              "Notification permissions are permanently denied. Please enable them in System Settings.",
        );
      } else {
        return PermissionState(
          status: 1,
          error:
              "Notification permissions are required for the tracker to alert you.",
        );
      }
    } else {
      // Usage Permission
      try {
        final usageGranted = await service.isUsagePermissionGranted();
        if (usageGranted) {
          return PermissionState(status: 0);
        } else {
          return PermissionState(
            status: 1,
            error:
                "Usage Access is required to track app time. Please enable it in Settings.",
          );
        }
      } catch (e) {
        return PermissionState(
          status: 1,
          error: "An error occurred checking usage permission: $e",
        );
      }
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _checkPermission(_type));
  }

  Future<void> requestPermission() async {
    final service = GetIt.instance<PermissionServiceInterface>();

    try {
      if (_type == PermissionType.notification) {
        final currentState = state.value;
        if (currentState?.status == 2) {
          await service.openAppNotificationSettings();
        } else {
          await service.requestNotificationPermission();
        }
      } else {
        await service.openUsageSettings();
      }
    } catch (e) {
      // Ignored here because reload() will catch the latest status
    } finally {
      await reload();
    }
  }
}
