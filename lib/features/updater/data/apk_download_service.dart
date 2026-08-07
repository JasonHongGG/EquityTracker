import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/updater/data/github_updater_config.dart';

class ApkDownloadService {
  final Dio _dio;
  final GithubUpdaterConfig config;

  ApkDownloadService({
    required this.config,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// Downloads the APK to external storage.
  /// Returns a tuple of (success, filePath, errorMessage).
  Future<(bool, String?, String?)> downloadUpdate(
    String downloadUrl, {
    void Function(double)? onProgress,
  }) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        return (false, null, '無法取得下載目錄');
      }

      final filePath = '${directory.path}/${config.downloadFileName}';

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

      return (true, filePath, null);
    } catch (e) {
      debugPrint('Download error: $e');
      return (false, null, '下載失敗: ${e.toString()}');
    }
  }
}

final apkDownloadServiceProvider = Provider<ApkDownloadService>((ref) {
  return ApkDownloadService(
    config: ref.watch(githubUpdaterConfigProvider),
  );
});
