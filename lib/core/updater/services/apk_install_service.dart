import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApkInstallService {
  /// Attempts to install the APK at the given path.
  Future<bool> installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Install error: $e');
      return false;
    }
  }
}

final apkInstallServiceProvider = Provider<ApkInstallService>((ref) {
  return ApkInstallService();
});
