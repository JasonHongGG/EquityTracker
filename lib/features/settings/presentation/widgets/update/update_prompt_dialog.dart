import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:equity_tracker/features/settings/presentation/providers/update_notifier.dart';
import 'package:equity_tracker/features/settings/data/update_repository_impl.dart';
import 'package:equity_tracker/features/settings/presentation/constants/update_ui_constants.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/update/permission_request_dialog.dart';

class UpdatePromptDialog extends ConsumerStatefulWidget {
  const UpdatePromptDialog({super.key});

  @override
  ConsumerState<UpdatePromptDialog> createState() => _UpdatePromptDialogState();
}

class _UpdatePromptDialogState extends ConsumerState<UpdatePromptDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateNotifierProvider);
    final releaseInfo = updateState.releaseInfo;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final highlightColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade100;

    return Dialog(
      shape: UpdateDialogStyle.shape,
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(maxWidth: UpdateDialogStyle.maxWidth),
        padding: UpdateDialogStyle.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            StatusIcon(
              icon: updateState.isDownloading
                  ? Icons.downloading_rounded
                  : Icons.rocket_launch_rounded,
              color: primaryColor,
              backgroundColor: primaryColor.withOpacity(0.1),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              updateState.isDownloading ? '下載中...' : '發現新版本',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),

            // Version Pill
            if (!updateState.isDownloading)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      UpdateRepositoryImpl.currentAppVersion,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.5,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.3,
                        ),
                      ),
                    ),
                    Text(
                      releaseInfo?.version ?? "Unknown",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Release Notes
            if (!updateState.isDownloading &&
                releaseInfo?.releaseNotes != null) ...[
              const SizedBox(height: 24),
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: highlightColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '更新內容',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.5,
                          ),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        releaseInfo!.releaseNotes!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Outfit',
                          height: 1.5,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Download Progress / Content
            if (updateState.isDownloading) ...[
              LinearProgressIndicator(
                value: updateState.downloadProgress,
                backgroundColor: highlightColor,
                borderRadius: BorderRadius.circular(8),
                minHeight: 8,
              ),
              const SizedBox(height: 12),
              Text(
                '${(updateState.downloadProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: primaryColor,
                ),
              ),
            ] else if (updateState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        updateState.error!,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            if (!updateState.isDownloading) ...[
              if (updateState.error == null)
                const SizedBox(height: 0),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isProcessing
                          ? null
                          : () {
                              ref.read(updateNotifierProvider.notifier).skipUpdate();
                              Navigator.of(context).pop();
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: theme.textTheme.bodyMedium?.color
                            ?.withOpacity(0.6),
                      ),
                      child: const Text(
                        '稍後更新',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isProcessing ? null : _handleUpdate,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: primaryColor.withOpacity(0.3),
                        elevation: 4,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              '立即更新',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    setState(() => _isProcessing = true);

    final notifier = ref.read(updateNotifierProvider.notifier);

    final permissionResult = await notifier.checkPermissions();

    if (!permissionResult.granted) {
      if (!mounted) return;

      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (context) => PermissionRequestDialog(
          permissionType: permissionResult.permissionType!,
          message: permissionResult.message!,
        ),
      );

      if (shouldOpenSettings == true) {
        await openAppSettings();
      }

      setState(() => _isProcessing = false);
      return;
    }

    await notifier.downloadUpdate();

    final updateState = ref.read(updateNotifierProvider);

    if (updateState.downloadedFilePath != null) {
      await notifier.installUpdate();
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}
