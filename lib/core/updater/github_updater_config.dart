import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuration for the GitHub Auto Updater module.
/// By injecting this configuration, the updater becomes completely decoupled
/// from the host application.
class GithubUpdaterConfig {
  /// The GitHub username or organization name.
  final String githubOwner;
  
  /// The GitHub repository name.
  final String githubRepo;
  
  /// The local filename to save the downloaded APK as.
  final String downloadFileName;

  const GithubUpdaterConfig({
    required this.githubOwner,
    required this.githubRepo,
    this.downloadFileName = 'app_update.apk',
  });
}

/// A provider that must be overridden in the ProviderScope of the host app.
/// Throws an UnimplementedError if the host app forgets to provide the config.
final githubUpdaterConfigProvider = Provider<GithubUpdaterConfig>((ref) {
  throw UnimplementedError('githubUpdaterConfigProvider must be overridden in ProviderScope');
});
