import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/core/services/import_service.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/transaction_notifier.dart';
import 'package:equity_tracker/core/widgets/toast_notification.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/common/settings_tile.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/settings_screen/notion_config_dialog.dart';

class ExperimentalSection extends ConsumerStatefulWidget {
  const ExperimentalSection({super.key});

  @override
  ConsumerState<ExperimentalSection> createState() => _ExperimentalSectionState();
}

class _ExperimentalSectionState extends ConsumerState<ExperimentalSection> {
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

  Future<void> _importTransactions() async {
    try {
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
        final importService = ImportService();
        final importResult = await importService.importFromJsonFile(path);
        final insertedIds = importResult.insertedIds;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'last_import_ids',
          insertedIds.map((e) => e.toString()).toList(),
        );

        if (mounted) {
          Navigator.of(context).pop();
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

          // ignore: unused_result
          ref.refresh(transactionNotifierProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        if (_isLoading) {
          Navigator.of(context).pop();
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

        // ignore: unused_result
        ref.refresh(transactionNotifierProvider);
        ToastService.showSuccess(context, 'Import reverted.');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Undo failed: $e');
      }
    }
  }

  void _showNotionConfig() {
    showDialog(
      context: context,
      builder: (ctx) => const NotionConfigDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
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
    );
  }
}
