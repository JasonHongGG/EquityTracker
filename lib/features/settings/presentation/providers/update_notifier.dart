import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/services/update_service.dart';
import 'package:equity_tracker/features/settings/presentation/states/update_state.dart';

/// Provider for UpdateService singleton
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

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
      state = state.copyWith(error: '?曆??唬?頛??');
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
        error: result.error ?? '銝?憭望?',
      );
    }
  }

  /// Install the downloaded update
  Future<bool> installUpdate() async {
    final filePath = state.downloadedFilePath;
    if (filePath == null) {
      state = state.copyWith(error: '?曆??唬?頛?瑼?');
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
final updateNotifierProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);
