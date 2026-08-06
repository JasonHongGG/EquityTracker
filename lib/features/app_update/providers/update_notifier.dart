import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/app_update/domain/update_info.dart';
import 'package:equity_tracker/features/app_update/data/update_repository.dart';

// --- Repo Provider ---
final updateRepositoryProvider = Provider<UpdateRepository>((ref) {
  return UpdateRepository();
});

// --- Notifier ---
class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() {
    return const UpdateState();
  }

  Future<void> checkForUpdate() async {
    state = state.copyWith(isChecking: true, error: null);

    final result = await ref.read(updateRepositoryProvider).checkForUpdate();

    state = state.copyWith(
      isChecking: false,
      hasUpdate: result.hasUpdate,
      releaseInfo: result.releaseInfo,
      error: result.error,
    );
  }

  Future<PermissionCheckResult> checkPermissions() async {
    return await ref.read(updateRepositoryProvider).checkAndRequestPermissions();
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

    final result = await ref.read(updateRepositoryProvider).downloadUpdate(
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

  Future<bool> installUpdate() async {
    final filePath = state.downloadedFilePath;
    if (filePath == null) {
      state = state.copyWith(error: '找不到下載的檔案');
      return false;
    }

    return await ref.read(updateRepositoryProvider).installUpdate(filePath);
  }

  void reset() {
    state = const UpdateState();
  }

  void skipUpdate() {
    state = state.copyWith(hasUpdate: false);
  }
}

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

final updateNotifierProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);
