import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:equity_tracker/core/services/native_backup_service.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/settings/providers/settings_notifier.dart';
import 'package:equity_tracker/core/providers/notification_provider.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_tile.dart';
import 'package:go_router/go_router.dart';

class DataManagementSection extends ConsumerStatefulWidget {
  const DataManagementSection({super.key});

  @override
  ConsumerState<DataManagementSection> createState() => _DataManagementSectionState();
}

class _DataManagementSectionState extends ConsumerState<DataManagementSection> {
  bool _isLoading = false;
  bool _hasSnapshot = false;
  late NativeBackupService _backupService;

  @override
  void initState() {
    super.initState();
    _backupService = NativeBackupService(
      ref.read(categoryRepositoryProvider), 
      ref.read(transactionRepositoryProvider)
    );
    _checkSnapshot();
  }

  Future<void> _checkSnapshot() async {
    final hasSnap = await _backupService.hasSnapshot();
    if (mounted) {
      setState(() {
        _hasSnapshot = hasSnap;
      });
    }
  }

  Future<void> _exportBackup() async {
    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) return;

      setState(() => _isLoading = true);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      final jsonContent = await _backupService.createBackupJson();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'equity_tracker_backup_$timestamp.json';
      final path = '$selectedDirectory/$filename';

      final file = File(path);
      await file.writeAsString(jsonContent);

      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _isLoading = false);
      }
      ref.read(notificationControllerProvider.notifier).showSuccess('Backup saved to: $filename');
    } catch (e) {
      if (mounted) {
        if (_isLoading) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
        }
      }
      ref.read(notificationControllerProvider.notifier).showError('Export failed: $e');
    }
  }

  Future<void> _importBackup() async {
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
        final file = File(path);
        final content = await file.readAsString();

        // 1. Create a snapshot for undo
        await _backupService.createSnapshot();
        
        // 2. Replace database
        final report = await _backupService.replaceDatabaseFromContent(content);

        // ignore: unused_result
        ref.refresh(transactionNotifierProvider);
        // ignore: unused_result
        ref.refresh(settingsNotifierProvider);

        if (mounted) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
          _checkSnapshot();
        }
        ref.read(notificationControllerProvider.notifier).showSuccess(
          'Restored: ${report.categoriesImported} Categories, ${report.transactionsImported} Transactions, ${report.recurringTransactionsImported} Recurring',
        );
      }
    } catch (e) {
      if (mounted) {
        if (_isLoading) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
        }
      }
      ref.read(notificationControllerProvider.notifier).showError('Restore failed: $e');
    }
  }

  Future<void> _undoRestore() async {
    try {
      setState(() => _isLoading = true);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      await _backupService.restoreFromSnapshot();
      
      // ignore: unused_result
      ref.refresh(transactionNotifierProvider);
      // ignore: unused_result
      ref.refresh(settingsNotifierProvider);

      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _isLoading = false);
        _checkSnapshot();
      }
      ref.read(notificationControllerProvider.notifier).showSuccess('Restore reverted successfully.');
    } catch (e) {
      if (mounted) {
        if (_isLoading) {
          Navigator.of(context).pop();
          setState(() => _isLoading = false);
        }
      }
      ref.read(notificationControllerProvider.notifier).showError('Undo failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'DATA MANAGEMENT',
      children: [
        SettingsTile(
          icon: Icons.category_rounded,
          iconColor: Colors.deepPurple,
          title: 'Manage Categories',
          subtitle: 'Add, Edit, or Remove',
          onTap: () => context.push('/manage-categories'),
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
          subtitle: 'Replace current data with backup',
          onTap: _isLoading ? null : _importBackup,
        ),
        if (_hasSnapshot)
          SettingsTile(
            icon: Icons.undo_rounded,
            iconColor: Colors.orange,
            title: 'Undo Last Restore',
            subtitle: 'Revert to previous state',
            onTap: _isLoading ? null : _undoRestore,
          ),
      ],
    );
  }
}
