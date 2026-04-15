enum PermissionType { notification, usage }

class PermissionState {
  // 0 = granted, 1 = denied, 2 = permanently denied
  final int status;
  final String? error;

  PermissionState({required this.status, this.error});

  bool get isGranted => status == 0;
  bool get isPermanentlyDenied => status == 2;
}
