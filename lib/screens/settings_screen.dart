import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/import_service.dart';
import '../services/native_backup_service.dart'; // Add this
import '../services/database_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';

import '../widgets/settings_widgets.dart';

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
        padding: const EdgeInsets.only(bottom: 40),
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

            // Section 3: Danger Zone
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
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                  fontFamily: 'Outfit',
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved to: $filename'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (_isLoading) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Restored: ${report.categoriesImported} Categories, ${report.transactionsImported} Transactions',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (_isLoading) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(
                seconds: 8,
              ), // Longer duration to read error
            ),
          );

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Import reverted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Undo failed: $e')));
      }
    }
  }

  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Clear All Data?'),
        content: const Text(
          'This action cannot be undone. All transactions will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await _clearAllData();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      final db = DatabaseService();
      await db.clearAllTransactions();

      // Clear preferences related to import
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_import_ids');
      setState(() {
        _lastImportedIds = [];
      });

      // Refresh list
      // ignore: unused_result
      ref.refresh(transactionListProvider);
      // ignore: unused_result
      ref.refresh(recentTitlesProvider); // Ensure suggestions are cleared too

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to clear data: $e')));
      }
    }
  }
}
