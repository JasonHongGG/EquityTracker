import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/core/providers/package_info_provider.dart';
import 'package:equity_tracker/features/updater/presentation/providers/updater_notifier.dart';
import 'package:equity_tracker/features/updater/domain/release_info.dart';
import 'package:equity_tracker/features/updater/data/updater_permission_service.dart';

Future<void> showGithubUpdaterBottomSheet(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const GithubUpdaterBottomSheet(),
  );
}

class GithubUpdaterBottomSheet extends ConsumerStatefulWidget {
  const GithubUpdaterBottomSheet({super.key});

  @override
  ConsumerState<GithubUpdaterBottomSheet> createState() => _GithubUpdaterBottomSheetState();
}

class _GithubUpdaterBottomSheetState extends ConsumerState<GithubUpdaterBottomSheet> {
  UpdaterPermissionResult? _permissionRequired;
  bool _isProcessingAction = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentStateView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStateView() {
    final state = ref.watch(githubUpdaterNotifierProvider);

    if (_permissionRequired != null) {
      return _buildPermissionRequest();
    }
    if (state.isChecking) {
      return _buildChecking();
    }
    if (state.error != null) {
      return _buildError(state.error!);
    }
    if (state.isDownloading) {
      return _buildDownloading(state.downloadProgress);
    }
    if (state.downloadedFilePath != null || _isProcessingAction && state.hasUpdate) {
      return _buildInstalling();
    }
    if (state.hasUpdate && state.releaseInfo != null) {
      return _buildUpdateAvailable(state.releaseInfo!);
    }
    
    return _buildUpToDate();
  }

  // --- Views ---

  Widget _buildChecking() {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('checking'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(Icons.sync_rounded, theme.colorScheme.primary, isSpinning: true),
        const SizedBox(height: 24),
        Text(
          '正在檢查更新...',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '請稍候，正在與 GitHub 伺服器連線',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }

  Widget _buildUpToDate() {
    final theme = Theme.of(context);
    final packageInfo = ref.watch(packageInfoProvider);

    return Column(
      key: const ValueKey('up_to_date'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(Icons.check_circle_rounded, Colors.green),
        const SizedBox(height: 24),
        Text(
          '已是最新版本',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '目前版本：${packageInfo.version}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完成', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('error'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(Icons.error_outline_rounded, Colors.red),
        const SizedBox(height: 24),
        Text(
          '發生錯誤',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('關閉', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateAvailable(ReleaseInfo releaseInfo) {
    final theme = Theme.of(context);
    final packageInfo = ref.watch(packageInfoProvider);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      key: const ValueKey('update_available'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(Icons.rocket_launch_rounded, theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          '發現新版本',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                packageInfo.version,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded, size: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3)),
              ),
              Text(
                releaseInfo.version,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (releaseInfo.releaseNotes != null && releaseInfo.releaseNotes!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '更新內容：',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    releaseInfo.releaseNotes!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _isProcessingAction ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('稍後再說', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isProcessingAction ? null : _handleUpdate,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('立即更新', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDownloading(double progress) {
    final theme = Theme.of(context);
    final percentage = (progress * 100).toInt();

    return Column(
      key: const ValueKey('downloading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(Icons.downloading_rounded, theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          '下載中...',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$percentage%',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildInstalling() {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('installing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(Icons.system_update_rounded, theme.colorScheme.primary, isSpinning: true),
        const SizedBox(height: 24),
        Text(
          '準備安裝...',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionRequest() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    String title;
    List<String> steps;
    IconData icon;

    if (_permissionRequired!.permissionType == UpdaterPermissionType.installPackages) {
      icon = Icons.admin_panel_settings_rounded;
      title = '需要安裝權限';
      steps = ['點擊「前往設定」', '找到「Equity Tracker」', '開啟「允許來自此來源」', '返回 App 繼續更新'];
    } else {
      icon = Icons.folder_special_rounded;
      title = '需要儲存空間權限';
      steps = ['點擊「前往設定」', '進入「權限」', '選擇「儲存空間」或「檔案」', '選擇「允許管理所有檔案」'];
    }

    return Column(
      key: const ValueKey('permission'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIcon(icon, primaryColor),
        const SizedBox(height: 24),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _permissionRequired!.message ?? '請授權以繼續更新',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
                        color: primaryColor.withValues(alpha: 0.1),
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
                            color: theme.dividerColor.withValues(alpha: 0.3),
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
                        color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.9),
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
                onPressed: () {
                  setState(() => _permissionRequired = null);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('取消', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () async {
                  await ref.read(githubUpdaterNotifierProvider.notifier).openSettings();
                  if (mounted) setState(() => _permissionRequired = null);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('前往設定', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Logic Helpers ---

  Future<void> _handleUpdate() async {
    setState(() => _isProcessingAction = true);
    final notifier = ref.read(githubUpdaterNotifierProvider.notifier);

    final permissionResult = await notifier.checkPermissions();
    if (!permissionResult.granted) {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
          _permissionRequired = permissionResult;
        });
      }
      return;
    }

    await notifier.downloadUpdate();

    final stateAfter = ref.read(githubUpdaterNotifierProvider);
    if (stateAfter.downloadedFilePath != null) {
      await notifier.installUpdate();
      if (mounted) Navigator.of(context).pop();
    } else {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  // --- UI Helpers ---

  Widget _buildIcon(IconData icon, Color color, {bool isSpinning = false}) {
    Widget iconWidget = Icon(icon, size: 32, color: color);
    
    if (isSpinning) {
      iconWidget = SizedBox(
        width: 32, height: 32,
        child: CircularProgressIndicator(strokeWidth: 3, color: color),
      );
    }

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(child: iconWidget),
    );
  }
}
