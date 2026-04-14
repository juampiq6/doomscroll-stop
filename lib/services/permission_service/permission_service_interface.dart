abstract interface class PermissionServiceInterface {
  Future<NotificationPermissionStatus> notificationPermissionStatus();
  Future<void> openAppNotificationSettings();

  /// Requests the notification permission.
  ///
  /// Throws [PermissionPermanentlyDeniedException] if the user has permanently denied the permission.
  /// Throws [PermissionRestrictedException] if the permission is restricted by the OS.
  /// Returns true if granted or limited, false if denied.
  Future<bool> requestNotificationPermission();

  Future<bool> isUsagePermissionGranted();

  Future<void> openUsageSettings();
}

enum NotificationPermissionStatus { granted, denied, permanentlyDenied }

class PermissionPermanentlyDeniedException implements Exception {
  final String message;
  PermissionPermanentlyDeniedException([
    this.message = 'Permission permanently denied by the user.',
  ]);

  @override
  String toString() => message;
}

class PermissionRestrictedException implements Exception {
  final String message;
  PermissionRestrictedException([
    this.message = 'Permission is restricted by the OS.',
  ]);

  @override
  String toString() => message;
}
