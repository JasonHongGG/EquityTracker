import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/updater/models/release_info.dart';
import 'package:equity_tracker/core/updater/services/github_version_service.dart';
import 'package:equity_tracker/core/updater/services/updater_permission_service.dart';
import 'package:equity_tracker/core/updater/services/apk_download_service.dart';
import 'package:equity_tracker/core/updater/services/apk_install_service.dart';

class UpdaterState {
  final bool isChecking;
  final bool isDownloading;
  final bool hasUpdate;
  final double downloadProgress;
  final ReleaseInfo? releaseInfo;
  final String? error;
  final String? downloadedFilePath;

  const UpdaterState({
    this.isChecking = false,
    this.isDownloading = false,
    this.hasUpdate = false,
    this.downloadProgress = 0.0,
    this.releaseInfo,
    this.error,
    this.downloadedFilePath,
  });

  UpdaterState copyWith({
    bool? isChecking,
    bool? isDownloading,
    bool? hasUpdate,
    double? downloadProgress,
    ReleaseInfo? releaseInfo,
    String? error,
    String? downloadedFilePath,
  }) {
    return UpdaterState(
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      releaseInfo: releaseInfo ?? this.releaseInfo,
      error: error,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
    );
  }
}

class GithubUpdaterNotifier extends Notifier<UpdaterState> {
  @override
  UpdaterState build() {
    return const UpdaterState();
  }

  Future<void> checkForUpdate() async {
    state = state.copyWith(isChecking: true, error: null);

    final versionService = ref.read(githubVersionServiceProvider);
    final (hasUpdate, releaseInfo, error) = await versionService.checkForUpdate();

    state = state.copyWith(
      isChecking: false,
      hasUpdate: hasUpdate,
      releaseInfo: releaseInfo,
      error: error,
    );
  }

  Future<UpdaterPermissionResult> checkPermissions() async {
    return await ref.read(updaterPermissionServiceProvider).checkAndRequestPermissions();
  }

  Future<bool> openSettings() async {
    return await ref.read(updaterPermissionServiceProvider).openSettings();
  }

  Future<void> downloadUpdate() async {
    final downloadUrl = state.releaseInfo?.downloadUrl;
    if (downloadUrl == null) {
      state = state.copyWith(error: '找不到下載網址');
      return;
    }

    state = state.copyWith(
      isDownloading: true,
      downloadProgress: 0.0,
      error: null,
    );

    final downloadService = ref.read(apkDownloadServiceProvider);
    final (success, filePath, error) = await downloadService.downloadUpdate(
      downloadUrl,
      onProgress: (progress) {
        state = state.copyWith(downloadProgress: progress);
      },
    );

    if (success && filePath != null) {
      state = state.copyWith(
        isDownloading: false,
        downloadedFilePath: filePath,
      );
    } else {
      state = state.copyWith(
        isDownloading: false,
        error: error ?? '下載失敗',
      );
    }
  }

  Future<bool> installUpdate() async {
    final filePath = state.downloadedFilePath;
    if (filePath == null) {
      state = state.copyWith(error: '找不到下載的檔案');
      return false;
    }

    return await ref.read(apkInstallServiceProvider).installApk(filePath);
  }

  void reset() {
    state = const UpdaterState();
  }

  void skipUpdate() {
    state = state.copyWith(hasUpdate: false);
  }
}

final githubUpdaterNotifierProvider = NotifierProvider<GithubUpdaterNotifier, UpdaterState>(
  GithubUpdaterNotifier.new,
);
