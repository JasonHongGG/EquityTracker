import 'package:equity_tracker/features/settings/domain/update_entities.dart';
import 'package:equity_tracker/features/settings/domain/i_update_repository.dart';

class CheckUpdateUseCase {
  final IUpdateRepository repository;
  CheckUpdateUseCase(this.repository);

  Future<UpdateCheckResult> execute() => repository.checkForUpdate();
}

class CheckPermissionsUseCase {
  final IUpdateRepository repository;
  CheckPermissionsUseCase(this.repository);

  Future<PermissionCheckResult> execute() => repository.checkAndRequestPermissions();
}

class DownloadUpdateUseCase {
  final IUpdateRepository repository;
  DownloadUpdateUseCase(this.repository);

  Future<DownloadResult> execute(String url, {void Function(double)? onProgress}) {
    return repository.downloadUpdate(url, onProgress: onProgress);
  }
}

class InstallUpdateUseCase {
  final IUpdateRepository repository;
  InstallUpdateUseCase(this.repository);

  Future<bool> execute(String filePath) => repository.installUpdate(filePath);
}
