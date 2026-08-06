/// Represents information about a GitHub release.
class ReleaseInfo {
  final String version;
  final String? downloadUrl;
  final String? releaseNotes;
  final DateTime? publishedAt;

  const ReleaseInfo({
    required this.version,
    this.downloadUrl,
    this.releaseNotes,
    this.publishedAt,
  });
}
