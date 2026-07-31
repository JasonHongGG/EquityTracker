import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:equity_tracker/core/services/native_backup_service.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';
import 'package:equity_tracker/features/transaction/presentation/providers/transaction_notifier.dart';
import 'package:equity_tracker/features/settings/presentation/providers/settings_notifier.dart';
import 'package:equity_tracker/core/widgets/toast_notification.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/presentation/widgets/common/settings_tile.dart';
import 'package:go_router/go_router.dart';

class DataManagementSection extends ConsumerStatefulWidget {
  const DataManagementSection({super.key});

  @override
  ConsumerState<DataManagementSection> createState() => _DataManagementSectionState();
}

class _DataManagementSectionState extends ConsumerState<DataManagementSection> {
  bool _isLoading = false;

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

      final backupService = NativeBackupService(
        ref.read(categoryRepositoryProvider), 
        ref.read(transactionRepositoryProvider)
      );
      final jsonContent = await backupService.createBackupJson();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'equity_tracker_backup_$timestamp.json';
      final path = '$selectedDirectory/$filename';

      final file = File(path);
      await file.writeAsString(jsonContent);

      if (mounted) {
        Navigator.of(context).pop();
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

        final backupService = NativeBackupService(
          ref.read(categoryRepositoryProvider), 
          ref.read(transactionRepositoryProvider)
        );
        final report = await backupService.restoreFromBackupContent(content);

        // ignore: unused_result
        ref.refresh(transactionNotifierProvider);
        // ignore: unused_result
        ref.refresh(settingsNotifierProvider);

        if (mounted) {
          Navigator.of(context).pop();
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
          subtitle: 'Merge from backup file',
          onTap: _isLoading ? null : _importBackup,
        ),
      ],
    );
  }
}
