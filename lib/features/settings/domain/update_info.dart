enum PermissionType { storage, installPackages }

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
}

class UpdateCheckResult {
  final bool hasUpdate;
  final ReleaseInfo? releaseInfo;
  final String? error;

  UpdateCheckResult({required this.hasUpdate, this.releaseInfo, this.error});
}

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

class DownloadResult {
  final bool success;
  final String? filePath;
  final String? error;

  DownloadResult({required this.success, this.filePath, this.error});
}
