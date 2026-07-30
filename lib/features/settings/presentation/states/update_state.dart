import 'package:equity_tracker/core/services/update_service.dart';

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
