import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:http/http.dart' as http;
import 'package:equity_tracker/features/app_update/domain/update_info.dart';

class UpdateRepository {
  final Dio _dio = Dio();
  
  static const String currentAppVersion = 'v0.0.1';
  static const String githubOwner = 'JasonHongGG';
  static const String githubRepo = 'EquityTracker';

  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final url = 'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        String? apkUrl;
        final assets = json['assets'] as List<dynamic>?;
        if (assets != null) {
          for (final asset in assets) {
            final name = asset['name'] as String?;
            if (name != null && name.toLowerCase().endsWith('.apk')) {
              apkUrl = asset['browser_download_url'] as String?;
              break;
            }
          }
        }

        final releaseInfo = ReleaseInfo(
          version: json['tag_name'] as String? ?? 'unknown',
          downloadUrl: apkUrl,
          releaseNotes: json['body'] as String?,
          publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'] as String) : null,
        );

        final hasUpdate = _isNewerVersion(releaseInfo.version, currentAppVersion);

        return UpdateCheckResult(
          hasUpdate: hasUpdate,
          releaseInfo: releaseInfo,
        );
      } else if (response.statusCode == 404) {
        return UpdateCheckResult(hasUpdate: false, error: '找不到任何發布版本');
      } else {
        return UpdateCheckResult(
          hasUpdate: false,
          error: '無法檢查更新 (錯誤碼: ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Update check error: $e');
      return UpdateCheckResult(hasUpdate: false, error: '無法連線到網路，請檢查網路連線');
    }
  }

  bool _isNewerVersion(String latestVersion, String currentVersion) {
    try {
      final latest = latestVersion.replaceFirst(RegExp(r'^v'), '');
      final current = currentVersion.replaceFirst(RegExp(r'^v'), '');

      final latestParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      while (latestParts.length < 3) {
        latestParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }

      for (var i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      debugPrint('Version comparison error: $e');
      return false;
    }
  }

  Future<PermissionCheckResult> checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      final installStatus = await permission_handler.Permission.requestInstallPackages.status;

      if (!installStatus.isGranted) {
        return PermissionCheckResult(
          granted: false,
          permissionType: PermissionType.installPackages,
          message: '需要「安裝未知應用程式」權限才能安裝更新',
        );
      }

      final sdkInt = 30; // Mocked for simplicity
      if (sdkInt < 29) {
        final storageStatus = await permission_handler.Permission.storage.status;
        if (!storageStatus.isGranted) {
          return PermissionCheckResult(
            granted: false,
            permissionType: PermissionType.storage,
            message: '需要儲存空間權限才能下載更新檔案',
          );
        }
      }
    }
    return PermissionCheckResult(granted: true);
  }

  Future<DownloadResult> downloadUpdate(String downloadUrl, {void Function(double)? onProgress}) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        return DownloadResult(success: false, error: '無法取得下載目錄');
      }

      final filePath = '${directory.path}/EquityTracker_update.apk';

      final oldFile = File(filePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      return DownloadResult(success: true, filePath: filePath);
    } catch (e) {
      debugPrint('Download error: $e');
      return DownloadResult(success: false, error: '下載失敗: ${e.toString()}');
    }
  }

  Future<bool> installUpdate(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Install error: $e');
      return false;
    }
  }

  Future<bool> openAppSettings() async {
    return await permission_handler.openAppSettings();
  }
}
