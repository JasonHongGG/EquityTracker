import 'package:flutter/material.dart';
import 'package:equity_tracker/features/settings/domain/update_entities.dart';
import 'package:equity_tracker/features/settings/presentation/constants/update_ui_constants.dart';

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
    final primaryColor = theme.colorScheme.primary;

    final (icon, title, steps) = _getPermissionDetails();

    return Dialog(
      shape: UpdateDialogStyle.shape,
      backgroundColor: theme.canvasColor,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(maxWidth: UpdateDialogStyle.maxWidth),
        padding: UpdateDialogStyle.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusIcon(
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
                      backgroundColor: primaryColor,
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
