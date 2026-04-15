import 'dart:typed_data';

class AppInfo {
  final String appName;
  final String packageName;
  final Uint8List? icon;

  AppInfo({required this.appName, required this.packageName, this.icon});

  factory AppInfo.fromMap(Map<String, dynamic> map) {
    return AppInfo(
      appName: map['appName'] as String,
      packageName: map['packageName'] as String,
      icon: map['icon'] as Uint8List?,
    );
  }
}
