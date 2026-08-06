import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncProgressState {
  final bool isSyncing;
  final String statusText;
  final double progress; // 0.0 to 1.0

  SyncProgressState({
    this.isSyncing = false,
    this.statusText = '',
    this.progress = 0.0,
  });

  SyncProgressState copyWith({
    bool? isSyncing,
    String? statusText,
    double? progress,
  }) {
    return SyncProgressState(
      isSyncing: isSyncing ?? this.isSyncing,
      statusText: statusText ?? this.statusText,
      progress: progress ?? this.progress,
    );
  }
}

class SyncProgressController extends Notifier<SyncProgressState> {
  @override
  SyncProgressState build() {
    return SyncProgressState();
  }

  void startSync(String status) {
    state = state.copyWith(isSyncing: true, statusText: status, progress: 0.0);
  }

  void updateProgress(String status, double progress) {
    state = state.copyWith(statusText: status, progress: progress);
  }

  void stopSync({String? finalStatus}) {
    state = state.copyWith(
      isSyncing: false,
      statusText: finalStatus ?? '',
      progress: 1.0,
    );
  }
}

final syncProgressProvider = NotifierProvider<SyncProgressController, SyncProgressState>(() {
  return SyncProgressController();
});
