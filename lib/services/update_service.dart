import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Current app version - Update this for each release
const String currentAppVersion = 'v0.0.1';

/// GitHub repository information
const String githubOwner = 'JasonHongGG';
const String githubRepo = 'EquityTracker';

/// Model class for GitHub release information
class ReleaseInfo {
  final String version;
  final String? downloadUrl;
  final String? releaseNotes;
  final DateTime? publishedAt;

  ReleaseInfo({
    required this.version,
    this.downloadUrl,
    this.releaseNotes,
    this.publishedAt,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    // Find APK asset in release assets
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

    return ReleaseInfo(
      version: json['tag_name'] as String? ?? 'unknown',
      downloadUrl: apkUrl,
      releaseNotes: json['body'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
    );
  }
}

/// Result class for update check
class UpdateCheckResult {
  final bool hasUpdate;
  final ReleaseInfo? releaseInfo;
  final String? error;

  UpdateCheckResult({required this.hasUpdate, this.releaseInfo, this.error});
}

/// Service for handling GitHub-based app updates
class UpdateService {
  final Dio _dio = Dio();

  /// Check for updates from GitHub releases
  Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final url =
          'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final releaseInfo = ReleaseInfo.fromJson(json);

        final hasUpdate = _isNewerVersion(
          releaseInfo.version,
          currentAppVersion,
        );

        return UpdateCheckResult(
          hasUpdate: hasUpdate,
          releaseInfo: releaseInfo,
        );
      } else if (response.statusCode == 404) {
        // No releases found
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

  /// Compare version strings (v1.2.3 format)
  bool _isNewerVersion(String latestVersion, String currentVersion) {
    try {
      // Remove 'v' prefix if present
      final latest = latestVersion.replaceFirst(RegExp(r'^v'), '');
      final current = currentVersion.replaceFirst(RegExp(r'^v'), '');

      final latestParts = latest
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final currentParts = current
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      // Pad with zeros to ensure same length
      while (latestParts.length < 3) latestParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      for (var i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false; // Same version
    } catch (e) {
      debugPrint('Version comparison error: $e');
      return false;
    }
  }

  /// Check required permissions (does NOT auto-request, just checks status)
  Future<PermissionCheckResult> checkAndRequestPermissions() async {
    // For Android 8.0+, we need install packages permission
    if (Platform.isAndroid) {
      // Check install unknown apps permission - only check status, don't request
      final installStatus = await Permission.requestInstallPackages.status;

      if (!installStatus.isGranted) {
        // Return immediately with permission info - let UI show dialog first
        return PermissionCheckResult(
          granted: false,
          permissionType: PermissionType.installPackages,
          message: '需要「安裝未知應用程式」權限才能安裝更新',
        );
      }

      // For older Android versions, check storage permission
      final sdkInt = await _getAndroidSdkVersion();
      if (sdkInt < 29) {
        final storageStatus = await Permission.storage.status;
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

  /// Get Android SDK version
  Future<int> _getAndroidSdkVersion() async {
    try {
      // Default to a high version for newer Android
      return 30;
    } catch (e) {
      return 30;
    }
  }

  /// Download APK file with progress callback
  Future<DownloadResult> downloadUpdate(
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Get download directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        return DownloadResult(success: false, error: '無法取得下載目錄');
      }

      final filePath = '${directory.path}/EquityTracker_update.apk';

      // Delete old APK if exists
      final oldFile = File(filePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      // Download with progress
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

  /// Install the downloaded APK
  Future<bool> installUpdate(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Install error: $e');
      return false;
    }
  }

  /// Open app settings for permission configuration
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}

/// Result class for permission check
class PermissionCheckResult {
  final bool granted;
  final PermissionType? permissionType;
  final String? message;

  PermissionCheckResult({
    required this.granted,
    this.permissionType,
    this.message,
  });
}

/// Types of permissions that may be needed
enum PermissionType { storage, installPackages }

/// Result class for download operation
class DownloadResult {
  final bool success;
  final String? filePath;
  final String? error;

  DownloadResult({required this.success, this.filePath, this.error});
}
