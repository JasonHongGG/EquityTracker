import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A provider that holds the PackageInfo.
/// This must be initialized before runApp by overriding it in ProviderScope.
final packageInfoProvider = Provider<PackageInfo>((ref) {
  throw UnimplementedError('packageInfoProvider must be overridden in ProviderScope during initialization');
});
