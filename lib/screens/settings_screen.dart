import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/import_service.dart';
import '../services/notion_service.dart';
import '../models/transaction_model.dart';
import '../services/native_backup_service.dart'; // Add this
import '../services/database_service.dart';
import '../services/update_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/update_provider.dart';
import '../widgets/update_dialog.dart';
import 'category_management_screen.dart';
import 'dart:io';
import '../widgets/custom_toast.dart';

import '../widgets/settings_widgets.dart';

import '../widgets/scale_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<int> _lastImportedIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLastImport();
  }

  Future<void> _loadLastImport() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList('last_import_ids');
    if (stored != null && mounted) {
      setState(() {
        _lastImportedIds = stored.map((e) => int.parse(e)).toList();
      });
    }
  }

  Future<void> _checkForUpdate() async {
    // Show checking dialog
    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const UpdateStatusDialog(message: '正在檢查 GitHub 版本...'),
    );

    // Check for updates
    await ref.read(updateProvider.notifier).checkForUpdate();

    if (!mounted) return;

    // Close loading dialog
    Navigator.of(context).pop();

    final updateState = ref.read(updateProvider);

    if (updateState.hasUpdate && updateState.releaseInfo?.downloadUrl != null) {
      // Show update dialog (built-in helper from update_dialog.dart)
      await showUpdateDialog(context);
    } else if (updateState.error != null) {
      // Show error dialog
      await showDialog(
        context: context,
        builder: (ctx) =>
            UpdateStatusDialog(message: updateState.error!, isError: true),
      );
    } else {
      // Already up to date - Show a nice success dialog briefly or a simple status dialog
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '已是最新版本',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '目前使用版本 $currentAppVersion',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('太棒了'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeModeAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F111A)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            // Section 1: Preferences
            SettingsSection(
              title: 'PREFERENCES',
              children: [
                SettingsTile(
                  icon: Icons.dark_mode_rounded,
                  iconColor: Colors.purpleAccent,
                  title: 'Dark Mode',
                  trailing: themeModeAsync.when(
                    data: (settings) => Switch(
                      value: settings.themeMode == ThemeMode.dark,
                      onChanged: (val) {
                        ref
                            .read(settingsProvider.notifier)
                            .setThemeMode(
                              val ? ThemeMode.dark : ThemeMode.light,
                            );
                      },
                    ),
                    loading: () => const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (e, s) => const Icon(Icons.error, size: 20),
                  ),
                ),
                SettingsTile(
                  icon: Icons.security_rounded,
                  iconColor: const Color(0xFF34C759), // iOS Green
                  title: 'Privacy Mode',
                  subtitle: 'Hide balance on dashboard',
                  trailing: themeModeAsync.when(
                    data: (settings) => Switch(
                      value: settings.isPrivacyModeEnabled,
                      onChanged: (val) {
                        ref.read(settingsProvider.notifier).setPrivacyMode(val);
                      },
                    ),
                    loading: () => const SizedBox(height: 0),
                    error: (e, s) => const SizedBox(height: 0),
                  ),
                ),
                SettingsTile(
                  icon: Icons.currency_exchange,
                  iconColor: Colors.amber,
                  title: 'Currency Symbol',
                  subtitle: '\$ (USD)',
                ),
              ],
            ),

            // Section 2: Data Management
            SettingsSection(
              title: 'DATA MANAGEMENT',
              children: [
                SettingsTile(
                  icon: Icons.category_rounded,
                  iconColor: Colors.deepPurple,
                  title: 'Manage Categories',
                  subtitle: 'Add, Edit, or Remove',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryManagementScreen(),
                    ),
                  ),
                ),
                SettingsTile(
                  icon: Icons.file_download_rounded,
                  iconColor: Colors.teal,
                  title: 'Export Backup',
                  subtitle: 'Save to JSON',
                  onTap: _isLoading ? null : _exportBackup,
                ),
                SettingsTile(
                  icon: Icons.restore_page_rounded,
                  iconColor: Colors.indigoAccent,
                  title: 'Restore Backup',
                  subtitle: 'Merge from backup file',
                  onTap: _isLoading ? null : _importBackup,
                ),
              ],
            ),

            // Section 3: Integrations (Experimental)
            SettingsSection(
              title: 'EXPERIMENTAL',
              children: [
                SettingsTile(
                  icon: Icons.sync_rounded,
                  iconColor: Colors.black87,
                  title: 'Notion Integration',
                  subtitle: 'Sync new transactions to Notion',
                  onTap: _showNotionConfig,
                ),
                SettingsTile(
                  icon: Icons.file_upload_rounded,
                  iconColor: Colors.blueAccent,
                  title: 'Import Transactions',
                  subtitle: 'From JSON backup',
                  onTap: _isLoading ? null : _importTransactions,
                ),
                if (_lastImportedIds.isNotEmpty)
                  SettingsTile(
                    icon: Icons.undo_rounded,
                    iconColor: Colors.orange,
                    title: 'Undo Last Import',
                    onTap: _undoImport,
                  ),
              ],
            ),
            // Section 4: Danger Zone
            SettingsSection(
              title: 'DANGER ZONE',
              children: [
                SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: Colors.red,
                  title: 'Clear All Data',
                  subtitle: 'Permanently delete all records',
                  isDestructive: true,
                  onTap: _showClearDataConfirmation,
                ),
              ],
            ),

            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _checkForUpdate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Version $currentAppVersion',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Native Backup Methods ---

  Future<void> _exportBackup() async {
    try {
      // 1. Pick Directory
      final String? selectedDirectory = await FilePicker.platform
          .getDirectoryPath();

      if (selectedDirectory == null) {
        // User canceled
        return;
      }

      setState(() => _isLoading = true);

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      // 2. Generate JSON
      final backupService = NativeBackupService();
      final jsonContent = await backupService.createBackupJson();

      // 3. Write File
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'equity_tracker_backup_$timestamp.json';
      final path = '$selectedDirectory/$filename';

      final file = File(path); // Requires 'dart:io'
      await file.writeAsString(jsonContent);

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        setState(() => _isLoading = false);

        ToastService.showSuccess(context, 'Backup saved to: $filename');
      }
    } catch (e) {
      if (mounted) {
        if (_isLoading) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
        }
        ToastService.showError(context, 'Export failed: $e');
      }
    }
  }

  Future<void> _importBackup() async {
    try {
      // 1. Pick File
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        }

        final path = result.files.single.path!;
        final file = File(path);
        final content = await file.readAsString();

        // 2. Restore
        final backupService = NativeBackupService();
        final report = await backupService.restoreFromBackupContent(content);

        // 3. Refresh UI
        // ignore: unused_result
        ref.refresh(transactionListProvider);
        // ignore: unused_result
        ref.refresh(
          settingsProvider,
        ); // If we synced settings later, but now just in case

        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading
          setState(() => _isLoading = false);

          ToastService.showSuccess(
            context,
            'Restored: ${report.categoriesImported} Categories, ${report.transactionsImported} Transactions',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (_isLoading) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
        }
        ToastService.showError(context, 'Restore failed: $e');
      }
    }
  }

  // --- End Native Backup Methods ---

  Future<void> _importTransactions() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);

        // Show loading dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        }

        final path = result.files.single.path!;
        final importService = ImportService();
        final importResult = await importService.importFromJsonFile(path);
        final insertedIds = importResult.insertedIds;

        // Save to Prefs
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'last_import_ids',
          insertedIds.map((e) => e.toString()).toList(),
        );

        if (mounted) {
          Navigator.of(context).pop(); // Dismiss loading
          setState(() {
            _isLoading = false;
            _lastImportedIds = insertedIds;
          });

          String message = 'Imported ${insertedIds.length} transactions.';
          if (importResult.failureCount > 0) {
            message += ' Failed: ${importResult.failureCount}.';
            if (importResult.lastError != null) {
              message += ' Last Error: ${importResult.lastError}';
            }
          }

          ToastService.showInfo(context, message);

          // Refresh the transaction list to show new data
          // ignore: unused_result
          ref.refresh(transactionListProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        if (_isLoading) {
          Navigator.of(context).pop(); // Dismiss loading if active
          setState(() => _isLoading = false);
        }
        ToastService.showError(context, 'Import failed: $e');
      }
    }
  }

  Future<void> _undoImport() async {
    try {
      final importService = ImportService();
      await importService.revertImport(_lastImportedIds);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_import_ids');

      if (mounted) {
        setState(() {
          _lastImportedIds = [];
        });

        // Refresh the transaction list to remove deleted data
        // ignore: unused_result
        ref.refresh(transactionListProvider);

        ToastService.showSuccess(context, 'Import reverted.');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Undo failed: $e');
      }
    }
  }

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Danger Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.redAccent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Clear All Data?',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Content
              const Text(
                'This action cannot be undone. All transactions will be permanently deleted.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ScaleButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ScaleButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _clearAllData();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Delete All',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      final db = DatabaseService();
      await db.clearAllTransactions();

      // Clear preferences related to import & Notion sync
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_import_ids');
      await prefs.remove('notion_last_sync_time');
      await prefs.remove('notion_last_pull_ids');
      await prefs.remove('notion_prev_sync_time');
      setState(() {
        _lastImportedIds = [];
      });

      // Refresh list
      // ignore: unused_result
      ref.refresh(transactionListProvider);
      // ignore: unused_result
      ref.refresh(recentTitlesProvider); // Ensure suggestions are cleared too

      if (mounted) {
        ToastService.showSuccess(context, 'All data cleared.');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Failed to clear data: $e');
      }
    }
  }

  Future<void> _showNotionConfig() async {
    final notionService = NotionService();
    final token = await notionService.token ?? '';
    final dbId = await notionService.databaseId ?? '';
    bool isEnabled = await notionService.isEnabled;

    final tokenController = TextEditingController(text: token);
    final dbIdController = TextEditingController(text: dbId);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) {
        bool isVerifying = false;
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final backgroundColor = isDark
                ? const Color(0xFF1E1E2C)
                : Colors.white;
            final inputFillColor = isDark
                ? Colors.black12
                : Colors.grey.shade50;

            return Dialog(
              backgroundColor: backgroundColor,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.science_rounded,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Notion \nIntegration',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                          ),
                          // Toggle Switch
                          Transform.scale(
                            scale: 0.9,
                            child: Switch(
                              value: isEnabled,
                              activeColor: Colors.white,
                              activeTrackColor: Colors.green,
                              onChanged: (val) =>
                                  setState(() => isEnabled = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black45,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Database Requirements",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Columns: "名稱", "金額", "類別", "時間"',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Inputs
                      Text(
                        "CREDENTIALS",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Token Field
                      TextField(
                        controller: tokenController,
                        enabled: isEnabled,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isEnabled
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? Colors.white24 : Colors.black26),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Integration Token',
                          labelStyle: const TextStyle(fontFamily: 'Outfit'),
                          filled: true,
                          fillColor: inputFillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          prefixIcon: const Icon(Icons.key_rounded, size: 20),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),

                      // DB ID Field
                      TextField(
                        controller: dbIdController,
                        enabled: isEnabled,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isEnabled
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? Colors.white24 : Colors.black26),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Database ID',
                          labelStyle: const TextStyle(fontFamily: 'Outfit'),
                          filled: true,
                          fillColor: inputFillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.dataset_rounded,
                            size: 20,
                          ),
                        ),
                      ),
                      // Sync Functionality (Experimental)
                      if (isEnabled) ...[
                        const Divider(height: 48, color: Colors.white10),
                        Text(
                          "DATA SYNC",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sync Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : () => _syncFromNotion(setState, context),
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.download_rounded,
                                        size: 18,
                                      ),
                                label: Text(
                                  _isLoading ? "Syncing..." : "Sync Now",
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                                  ),
                                  foregroundColor: isDark
                                      ? Colors.white
                                      : Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Undo Button (Only if available)
                        FutureBuilder(
                          future: SharedPreferences.getInstance().then(
                            (p) => p.getStringList('notion_last_pull_ids'),
                          ),
                          builder: (ctx, snap) {
                            if (!snap.hasData ||
                                snap.data == null ||
                                snap.data!.isEmpty)
                              return const SizedBox.shrink();
                            return Column(
                              children: [
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _undoNotionSync(setState),
                                    icon: const Icon(
                                      Icons.undo_rounded,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    label: const Text(
                                      "Undo Last Sync",
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      backgroundColor: Colors.orange
                                          .withOpacity(0.1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),
                      ],

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white60 : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isVerifying
                                  ? null
                                  : () async {
                                      // 1. Set Loading
                                      setState(() => isVerifying = true);

                                      // 2. Save Credentials
                                      await notionService.setCredentials(
                                        tokenController.text.trim(),
                                        dbIdController.text.trim(),
                                        isEnabled,
                                      );

                                      // 3. Verification Logic
                                      if (isEnabled) {
                                        final success = await notionService
                                            .testConnection();

                                        if (success) {
                                          if (ctx.mounted) {
                                            Navigator.pop(ctx); // Close Dialog
                                            if (mounted) {
                                              ToastService.showSuccess(
                                                context,
                                                'Connected Successfully! ✅',
                                              );
                                            }
                                          }
                                        } else {
                                          // Failure: Keep Dialog Open, Show Error
                                          if (ctx.mounted) {
                                            setState(() => isVerifying = false);
                                            if (mounted) {
                                              ToastService.showError(
                                                context,
                                                'Connection Failed ❌\nCheck Token/ID',
                                              );
                                            }
                                          }
                                        }
                                      } else {
                                        // Disabled: Just Close
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          if (mounted) {
                                            ToastService.showInfo(
                                              context,
                                              'Notion Sync Disabled',
                                            );
                                          }
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isVerifying
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Save",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Notion Sync Logic ---

  Future<void> _syncFromNotion(
    StateSetter setDialogState,
    BuildContext dialogContext,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Save current inputs first? Ideally user hit Save.
    // We assume user has saved credentials if this button is enabled.

    setDialogState(() => _isLoading = true); // Local loading in dialog?
    // Actually setDialogState updates the StatefulBuilder.
    // But _isLoading is in the main class.
    // Let's use a local loading indicator or reusing _isLoading is fine if we check mounted.

    // Show Loading SnackBar
    if (mounted) {
      ToastService.showInfo(context, 'Syncing from Notion... ⏳');
    }

    try {
      final notionService = NotionService();

      // 1. Get Last Sync Time
      final lastSyncStr = prefs.getString('notion_last_sync_time');
      final DateTime? lastSync = lastSyncStr != null
          ? DateTime.parse(lastSyncStr)
          : null;

      // 2. Fetch
      final transactions = await notionService.fetchTransactions(
        since: lastSync,
      );

      if (transactions.isEmpty) {
        if (mounted) {
          ToastService.showInfo(context, 'No new transactions found.');
        }
        setDialogState(() => _isLoading = false);
        return;
      }

      // 3. Deduplicate
      // Get current transactions from provider
      final currentTx = ref.read(transactionListProvider).value ?? [];
      final List<TransactionModel> toInsert = [];

      for (final tx in transactions) {
        // Check if exists: Same Date, Amount, Title
        // (Not perfect but good for experimental)
        final exists = currentTx.any(
          (existing) =>
              existing.amount == tx.amount &&
              existing.title == tx.title &&
              DateUtils.isSameDay(existing.date, tx.date) &&
              existing.type == tx.type,
        );

        if (!exists) {
          toInsert.add(tx);
        }
      }

      if (toInsert.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All items were duplicates. Skipped.'),
            ),
          );
        }
        setDialogState(() => _isLoading = false);
        return;
      }

      // 4. Insert
      final List<int> insertedIds = [];
      for (final tx in toInsert) {
        // We need to add one by one to get IDs (or batch insert if supported)
        // Provider addTransaction is void, but we can query latest?
        // Or modify provider to return ID.
        // As a workaround for "experimental":
        // We will read DatabaseService direct insert which returns ID.
        final id = await DatabaseService().insertTransaction(tx);
        insertedIds.add(id);
      }

      // 5. Update State (Provider)
      // ignore: unused_result
      ref.refresh(transactionListProvider);

      // 6. Save Sync State for Undo
      await prefs.setStringList(
        'notion_last_pull_ids',
        insertedIds.map((e) => e.toString()).toList(),
      );
      if (lastSyncStr != null) {
        await prefs.setString('notion_prev_sync_time', lastSyncStr);
      } else {
        await prefs.remove('notion_prev_sync_time');
      }

      // Update Last Sync Time to NOW
      await prefs.setString(
        'notion_last_sync_time',
        DateTime.now().toIso8601String(),
      );

      if (mounted) {
        ToastService.showSuccess(
          context,
          'Synced ${insertedIds.length} items from Notion! 🎉',
        );
        // Close Dialog? Or stay to let user undo?
        // Let's Refresh the Dialog to show Undo button
        setDialogState(() {});
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Sync Error: $e');
      }
    } finally {
      setDialogState(() => _isLoading = false);
    }
  }

  Future<void> _undoNotionSync(StateSetter setDialogState) async {
    final prefs = await SharedPreferences.getInstance();
    final idsStr = prefs.getStringList('notion_last_pull_ids');
    if (idsStr == null || idsStr.isEmpty) return;

    try {
      final ids = idsStr.map((e) => int.parse(e)).toList();

      // 1. Delete
      for (final id in ids) {
        await DatabaseService().deleteTransaction(id);
      }

      // 2. Revert Time
      final prevTime = prefs.getString('notion_prev_sync_time');
      if (prevTime != null) {
        await prefs.setString('notion_last_sync_time', prevTime);
      } else {
        await prefs.remove('notion_last_sync_time');
      }

      // 3. Clear Undo History
      await prefs.remove('notion_last_pull_ids');
      await prefs.remove('notion_prev_sync_time');

      // 4. Refresh Provider
      // ignore: unused_result
      ref.refresh(transactionListProvider);

      if (mounted) {
        ToastService.showSuccess(context, 'Last Notion Sync Reverted ↩️');
        setDialogState(() {});
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Undo Failed: $e');
      }
    }
  }
}
