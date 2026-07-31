import 'package:equity_tracker/features/settings/domain/update_entities.dart';

abstract class IUpdateRepository {
  Future<UpdateCheckResult> checkForUpdate();
  Future<PermissionCheckResult> checkAndRequestPermissions();
  Future<DownloadResult> downloadUpdate(String downloadUrl, {void Function(double)? onProgress});
  Future<bool> installUpdate(String filePath);
  Future<bool> openAppSettings();
}
