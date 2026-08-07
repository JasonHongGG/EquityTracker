import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum UpdaterPermissionType {
  installPackages,
  storage,
}

class UpdaterPermissionResult {
  final bool granted;
  final UpdaterPermissionType? permissionType;
  final String? message;

  const UpdaterPermissionResult({
    required this.granted,
    this.permissionType,
    this.message,
  });
}

class UpdaterPermissionService {
  Future<UpdaterPermissionResult> checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      final installStatus = await Permission.requestInstallPackages.status;

      if (!installStatus.isGranted) {
        return const UpdaterPermissionResult(
          granted: false,
          permissionType: UpdaterPermissionType.installPackages,
          message: '需要「安裝未知應用程式」權限才能安裝更新',
        );
      }

      // Note: In a production app, you might check Android SDK version accurately.
      // We assume SDK 29+ doesn't need external storage permission for app specific cache,
      // but for generic approach, we ensure minimal disruption.
    }
    return const UpdaterPermissionResult(granted: true);
  }

  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}

final updaterPermissionServiceProvider = Provider<UpdaterPermissionService>((ref) {
  return UpdaterPermissionService();
});
