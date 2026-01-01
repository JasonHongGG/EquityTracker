import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/import_service.dart';
import '../services/database_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            trailing: themeModeAsync.when(
              data: (mode) => Switch(
                value: mode == ThemeMode.dark,
                onChanged: (val) {
                  ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, s) => const Icon(Icons.error),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Currency Symbol'),
            subtitle: Text('\$ (Default)'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Import Transactions'),
            subtitle: const Text('Import from JSON file'),
            onTap: _isLoading ? null : _importTransactions,
            trailing: _lastImportedIds.isNotEmpty
                ? TextButton.icon(
                    onPressed: _undoImport,
                    icon: const Icon(Icons.undo, color: Colors.red),
                    label: const Text(
                      'Undo',
                      style: TextStyle(color: Colors.red),
                    ),
                  )
                : null,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Clear All Data',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Permanently delete all transactions'),
            onTap: _showClearDataConfirmation,
          ),
        ],
      ),
    );
  }

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
