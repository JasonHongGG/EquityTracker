import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/updater/updater_notifier.dart';

class UpdaterStatusDialog extends StatelessWidget {
  final String message;
  final bool isError;

  const UpdaterStatusDialog({super.key, required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isError ? '錯誤' : '檢查中'),
      content: Row(
        children: [
          if (!isError) const CircularProgressIndicator(),
          if (!isError) const SizedBox(width: 16),
          Expanded(child: Text(message)),
        ],
      ),
      actions: [
        if (isError)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
      ],
    );
  }
}

class UpdaterAlreadyLatestDialog extends StatelessWidget {
  final String currentVersion;

  const UpdaterAlreadyLatestDialog({super.key, required this.currentVersion});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('已是最新版本'),
      content: Text('您目前使用的版本 ($currentVersion) 已經是最新的了！'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('確定'),
        ),
      ],
    );
  }
}

class UpdaterPermissionDialog extends StatelessWidget {
  final String message;
  final VoidCallback onOpenSettings;
  final VoidCallback onCancel;

  const UpdaterPermissionDialog({
    super.key,
    required this.message,
    required this.onOpenSettings,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('需要權限'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: onOpenSettings,
          child: const Text('前往設定'),
        ),
      ],
    );
  }
}

class UpdaterPromptDialog extends ConsumerWidget {
  const UpdaterPromptDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(githubUpdaterNotifierProvider);
    final notifier = ref.read(githubUpdaterNotifierProvider.notifier);

    if (state.isDownloading) {
      return AlertDialog(
        title: const Text('下載更新中...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: state.downloadProgress),
            const SizedBox(height: 16),
            Text('${(state.downloadProgress * 100).toStringAsFixed(1)}%'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return AlertDialog(
        title: const Text('更新失敗'),
        content: Text(state.error!),
        actions: [
          TextButton(
            onPressed: () {
              notifier.reset();
              Navigator.pop(context);
            },
            child: const Text('關閉'),
          ),
        ],
      );
    }

    final releaseInfo = state.releaseInfo;
    if (releaseInfo == null) return const SizedBox();

    return AlertDialog(
      title: const Text('發現新版本！'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('最新版本: ${releaseInfo.version}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('更新內容:'),
            const SizedBox(height: 4),
            Text(releaseInfo.releaseNotes ?? '無詳細說明'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            notifier.skipUpdate();
            Navigator.pop(context);
          },
          child: const Text('稍後再說'),
        ),
        ElevatedButton(
          onPressed: () async {
            final permResult = await notifier.checkPermissions();
            if (!permResult.granted) {
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (ctx) => UpdaterPermissionDialog(
                    message: permResult.message ?? '權限不足',
                    onOpenSettings: () {
                      notifier.openSettings();
                      Navigator.pop(ctx);
                    },
                    onCancel: () => Navigator.pop(ctx),
                  ),
                );
              }
              return;
            }

            await notifier.downloadUpdate();
            
            if (ref.read(githubUpdaterNotifierProvider).downloadedFilePath != null) {
              final success = await notifier.installUpdate();
              if (success && context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: const Text('立即更新'),
        ),
      ],
    );
  }
}

Future<void> showGithubUpdaterPrompt(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const UpdaterPromptDialog(),
  );
}
