import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/update_provider.dart';
import '../services/update_service.dart';

/// --------------------------------------------------------------------------
/// Shared Styles & Components
/// --------------------------------------------------------------------------

class _DialogStyle {
  static ShapeBorder get shape =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(24));

  static EdgeInsets get padding => const EdgeInsets.all(28);
  static double get maxWidth => 360;
}

class _StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _StatusIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, size: 36, color: color),
    );
  }
}

/// --------------------------------------------------------------------------
/// 1. Checking / Status Dialog
/// --------------------------------------------------------------------------

class UpdateStatusDialog extends StatelessWidget {
  final String message;
  final bool isError;

  const UpdateStatusDialog({
    super.key,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: _DialogStyle.shape,
      backgroundColor: theme.canvasColor,
      surfaceTintColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: _DialogStyle.maxWidth),
        padding: _DialogStyle.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isError)
              _StatusIcon(
                icon: Icons.error_rounded,
                color: Colors.redAccent,
                backgroundColor: Colors.redAccent.withOpacity(0.1),
              )
            else
              Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C3E)
                      : const Color(0xFFF0F2F5),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(strokeWidth: 3),
              ),
            const SizedBox(height: 24),
            Text(
              isError ? '檢查失敗' : '檢查中',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontFamily: 'Outfit',
                height: 1.5,
              ),
            ),
            if (isError) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '關閉',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// --------------------------------------------------------------------------
/// 2. Update Available / Downloading Dialog
/// --------------------------------------------------------------------------

class UpdateDialog extends ConsumerStatefulWidget {
  const UpdateDialog({super.key});

  @override
  ConsumerState<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<UpdateDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateProvider);
    final releaseInfo = updateState.releaseInfo;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final highlightColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade100;

    return Dialog(
      shape: _DialogStyle.shape,
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(maxWidth: _DialogStyle.maxWidth),
        padding: _DialogStyle.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            _StatusIcon(
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
                      currentAppVersion,
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
                const SizedBox(height: 0), // Spacing handled above
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isProcessing
                          ? null
                          : () {
                              ref.read(updateProvider.notifier).skipUpdate();
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
                    flex: 2, // Highlight update button
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

    final notifier = ref.read(updateProvider.notifier);

    // 1. Check permissions (UI ONLY, actual check logic is inside service but we trigger UI from here)
    final permissionResult = await notifier.checkPermissions();

    if (!permissionResult.granted) {
      if (!mounted) return;

      // Show custom permission dialog
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (context) => PermissionRequestDialog(
          permissionType: permissionResult.permissionType!,
          message: permissionResult.message!,
        ),
      );

      if (shouldOpenSettings == true) {
        // Use permission_handler's openAppSettings directly
        await openAppSettings();
      }

      setState(() => _isProcessing = false);
      return;
    }

    // 2. Start download
    await notifier.downloadUpdate();

    final updateState = ref.read(updateProvider);

    if (updateState.downloadedFilePath != null) {
      // 3. Install
      await notifier.installUpdate();
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}

/// --------------------------------------------------------------------------
/// 3. Permission Request Dialog
/// --------------------------------------------------------------------------

class PermissionRequestDialog extends StatelessWidget {
  final PermissionType permissionType;
  final String message;

  const PermissionRequestDialog({
    super.key,
    required this.permissionType,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Align color with UpdateDialog (Primary instead of Tertiary)
    final primaryColor = theme.colorScheme.primary;

    final (icon, title, steps) = _getPermissionDetails();

    return Dialog(
      shape: _DialogStyle.shape,
      backgroundColor: theme.canvasColor,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(maxWidth: _DialogStyle.maxWidth),
        padding: _DialogStyle.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon matching UpdateDialog style
            _StatusIcon(
              icon: icon,
              color: primaryColor,
              backgroundColor: primaryColor.withOpacity(0.1),
            ),
            const SizedBox(height: 24),

            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontFamily: 'Outfit',
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Steps - Clean layout without boxy borders
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '如何開啟權限：',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),

            ...steps.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final step = entry.value;
              final isLast = index == steps.length;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$index',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.dividerColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 16),
                        child: Text(
                          step,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15,
                            height: 1.3,
                            color: theme.textTheme.bodyLarge?.color
                                ?.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      foregroundColor: theme.textTheme.bodyMedium?.color
                          ?.withOpacity(0.6),
                    ),
                    child: const Text(
                      '取消',
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
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor, // Use primary color
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: primaryColor.withOpacity(0.3),
                    ),
                    child: const Text(
                      '前往設定',
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
        ),
      ),
    );
  }

  (IconData, String, List<String>) _getPermissionDetails() {
    switch (permissionType) {
      case PermissionType.installPackages:
        return (
          Icons.admin_panel_settings_rounded,
          '需要安裝權限',
          ['點擊「前往設定」', '找到「Equity Tracker」', '開啟「允許來自此來源」', '返回 App 繼續更新'],
        );
      case PermissionType.storage:
        return (
          Icons.folder_special_rounded,
          '需要儲存空間權限',
          ['點擊「前往設定」', '進入「權限」', '選擇「儲存空間」或「檔案」', '選擇「允許管理所有檔案」'],
        );
    }
  }
}

/// Helper function to show update dialog
Future<void> showUpdateDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const UpdateDialog(),
  );
}

/// Helper to show status/checking dialog
Future<void> showUpdateCheckingDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const UpdateStatusDialog(
      message: '正在連接 GitHub 伺服器...',
    ), // Initial message
  );
}
