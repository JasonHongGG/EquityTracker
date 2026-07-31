import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/settings/domain/update_entities.dart';
import 'package:equity_tracker/features/settings/domain/repositories/i_update_repository.dart';
import 'package:equity_tracker/features/settings/data/repositories/update_repository_impl.dart';
import 'package:equity_tracker/features/settings/domain/usecases/update_usecases.dart';
import 'package:equity_tracker/features/settings/presentation/states/update_state.dart';

// --- Repo Provider ---
final updateRepositoryProvider = Provider<IUpdateRepository>((ref) {
  return UpdateRepositoryImpl();
});

// --- UseCase Providers ---
final checkUpdateUseCaseProvider = Provider<CheckUpdateUseCase>((ref) {
  return CheckUpdateUseCase(ref.read(updateRepositoryProvider));
});

final checkPermissionsUseCaseProvider = Provider<CheckPermissionsUseCase>((ref) {
  return CheckPermissionsUseCase(ref.read(updateRepositoryProvider));
});

final downloadUpdateUseCaseProvider = Provider<DownloadUpdateUseCase>((ref) {
  return DownloadUpdateUseCase(ref.read(updateRepositoryProvider));
});

final installUpdateUseCaseProvider = Provider<InstallUpdateUseCase>((ref) {
  return InstallUpdateUseCase(ref.read(updateRepositoryProvider));
});

// --- Notifier ---
class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() {
    return const UpdateState();
  }

  Future<void> checkForUpdate() async {
    state = state.copyWith(isChecking: true, error: null);

    final result = await ref.read(checkUpdateUseCaseProvider).execute();

    state = state.copyWith(
      isChecking: false,
      hasUpdate: result.hasUpdate,
      releaseInfo: result.releaseInfo,
      error: result.error,
    );
  }

  Future<PermissionCheckResult> checkPermissions() async {
    return await ref.read(checkPermissionsUseCaseProvider).execute();
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

    final result = await ref.read(downloadUpdateUseCaseProvider).execute(
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

    return await ref.read(installUpdateUseCaseProvider).execute(filePath);
  }

  void reset() {
    state = const UpdateState();
  }

  void skipUpdate() {
    state = state.copyWith(hasUpdate: false);
  }
}

final updateNotifierProvider = NotifierProvider<UpdateNotifier, UpdateState>(
  UpdateNotifier.new,
);
