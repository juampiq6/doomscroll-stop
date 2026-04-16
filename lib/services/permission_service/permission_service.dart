import 'package:permission_handler/permission_handler.dart';
import 'package:doomscroll_stop/services/permission_service/permission_service_interface.dart';

class PermissionService implements PermissionServiceInterface {
  final AppUsagePermissionHandlerInterface _appUsagePermissionInterface;

  PermissionService(this._appUsagePermissionInterface);

  @override
  Future<NotificationPermissionStatus> notificationPermissionStatus() async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return NotificationPermissionStatus.granted;
    } else if (status.isDenied) {
      return NotificationPermissionStatus.denied;
    } else if (status.isPermanentlyDenied) {
      return NotificationPermissionStatus.permanentlyDenied;
    } else {
      return NotificationPermissionStatus.denied;
    }
  }

  @override
  Future<void> openAppNotificationSettings() async {
    await openAppSettings();
  }

  @override
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      throw PermissionPermanentlyDeniedException(
        'Notification permission permanently denied. Please enable it in the app settings.',
      );
    }

    if (status.isRestricted) {
      throw PermissionRestrictedException(
        'Notification permission is restricted.',
      );
    }

    // This handles status.isDenied or other statuses
    return false;
  }

  @override
  Future<bool> hasUsagePermission() async {
    try {
      return await _appUsagePermissionInterface.hasUsagePermission();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openUsageSettings() async {
    try {
      await _appUsagePermissionInterface.openUsageSettings();
    } catch (_) {
      // Handle error if needed
    }
  }
}
