import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/update_service.dart';

/// Provider for UpdateService singleton
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

/// State class for update checking process
class UpdateState {
  final bool isChecking;
  final bool isDownloading;
  final bool hasUpdate;
  final double downloadProgress;
  final ReleaseInfo? releaseInfo;
  final String? error;
  final String? downloadedFilePath;

  const UpdateState({
    this.isChecking = false,
    this.isDownloading = false,
    this.hasUpdate = false,
    this.downloadProgress = 0.0,
    this.releaseInfo,
    this.error,
    this.downloadedFilePath,
  });

  UpdateState copyWith({
    bool? isChecking,
    bool? isDownloading,
    bool? hasUpdate,
    double? downloadProgress,
    ReleaseInfo? releaseInfo,
    String? error,
    String? downloadedFilePath,
  }) {
    return UpdateState(
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

/// Notifier class for managing update state using Riverpod 3.x Notifier
class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() {
    return const UpdateState();
  }

  UpdateService get _updateService => ref.read(updateServiceProvider);

  /// Check for available updates
  Future<void> checkForUpdate() async {
    state = state.copyWith(isChecking: true, error: null);

    final result = await _updateService.checkForUpdate();

    state = state.copyWith(
      isChecking: false,
      hasUpdate: result.hasUpdate,
      releaseInfo: result.releaseInfo,
      error: result.error,
    );
  }

  /// Check and request permissions
  Future<PermissionCheckResult> checkPermissions() async {
    return await _updateService.checkAndRequestPermissions();
  }

  /// Download the update
  Future<void> downloadUpdate() async {
    final downloadUrl = state.releaseInfo?.downloadUrl;
    if (downloadUrl == null) {
      state = state.copyWith(error: '找不到下載連結');
      return;
    }

    state = state.copyWith(
      isDownloading: true,
      downloadProgress: 0.0,
      error: null,
    );

    final result = await _updateService.downloadUpdate(
      downloadUrl,
      onProgress: (progress) {
        state = state.copyWith(downloadProgress: progress);
      },
    );

    if (result.success && result.filePath != null) {
      state = state.copyWith(
        isDownloading: false,
        downloadedFilePath: result.filePath,
      );
    } else {
      state = state.copyWith(
        isDownloading: false,
        error: result.error ?? '下載失敗',
      );
    }
  }

  /// Install the downloaded update
  Future<bool> installUpdate() async {
    final filePath = state.downloadedFilePath;
    if (filePath == null) {
      state = state.copyWith(error: '找不到下載的檔案');
      return false;
    }

    return await _updateService.installUpdate(filePath);
  }

  /// Reset update state
  void reset() {
    state = const UpdateState();
  }

  /// Skip current update check (user chose "Later")
  void skipUpdate() {
    state = state.copyWith(hasUpdate: false);
  }
}

/// Provider for update state management
final updateProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);
