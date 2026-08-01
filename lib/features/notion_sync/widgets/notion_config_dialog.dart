import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/core/providers/repository_providers.dart';


import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/transaction/providers/transaction_notifier.dart';
import 'package:equity_tracker/core/widgets/toast_notification.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

class NotionConfigDialog extends ConsumerStatefulWidget {
  const NotionConfigDialog({super.key});

  @override
  ConsumerState<NotionConfigDialog> createState() => _NotionConfigDialogState();
}

class _NotionConfigDialogState extends ConsumerState<NotionConfigDialog> {
  late TextEditingController _tokenController;
  late TextEditingController _dbIdController;
  bool _isEnabled = false;
  bool _isVerifying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
    _dbIdController = TextEditingController();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('notion_token') ?? '';
    final dbId = prefs.getString('notion_database_id') ?? '';
    final isEnabled = prefs.getBool('notion_enabled') ?? false;
    if (mounted) {
      setState(() {
        _tokenController.text = token;
        _dbIdController.text = dbId;
        _isEnabled = isEnabled;
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _dbIdController.dispose();
    super.dispose();
  }

  Future<void> _syncFromNotion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isLoading = true);

    if (mounted) {
      ToastService.showInfo(context, 'Syncing from Notion... ⏳');
    }

    try {
      final lastSyncStr = prefs.getString('notion_last_sync_time');
      final DateTime? lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

      final categories = List<CategoryModel>.from(await ref.read(categoryRepositoryProvider).getCategories());
      final transactions = await ref.read(notionApiClientProvider).fetchTransactions(
        _tokenController.text.trim(),
        _dbIdController.text.trim(),
        categories,
        since: lastSync,
      );

      if (transactions.isEmpty) {
        if (mounted) {
          ToastService.showInfo(context, 'No new transactions found.');
        }
        setState(() => _isLoading = false);
        return;
      }

      final currentTx = ref.read(transactionNotifierProvider).value ?? [];
      final List<TransactionModel> toInsert = [];

      for (final tx in transactions) {
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
            const SnackBar(content: Text('All items were duplicates. Skipped.')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final List<int> insertedIds = [];
      for (final tx in toInsert) {
        final id = await ref.read(transactionRepositoryProvider).insertTransaction(tx);
        insertedIds.add(id);
      }

      // ignore: unused_result
      ref.refresh(transactionNotifierProvider);

      await prefs.setStringList(
        'notion_last_pull_ids',
        insertedIds.map((e) => e.toString()).toList(),
      );
      if (lastSyncStr != null) {
        await prefs.setString('notion_prev_sync_time', lastSyncStr);
      } else {
        await prefs.remove('notion_prev_sync_time');
      }

      await prefs.setString(
        'notion_last_sync_time',
        DateTime.now().toIso8601String(),
      );

      if (mounted) {
        ToastService.showSuccess(
          context,
          'Synced ${insertedIds.length} items from Notion! 🎉',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Sync Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _undoNotionSync() async {
    final prefs = await SharedPreferences.getInstance();
    final idsStr = prefs.getStringList('notion_last_pull_ids');
    if (idsStr == null || idsStr.isEmpty) return;

    try {
      final ids = idsStr.map((e) => int.parse(e)).toList();

      for (final id in ids) {
        await ref.read(transactionRepositoryProvider).deleteTransaction(id);
      }

      final prevTime = prefs.getString('notion_prev_sync_time');
      if (prevTime != null) {
        await prefs.setString('notion_last_sync_time', prevTime);
      } else {
        await prefs.remove('notion_last_sync_time');
      }

      await prefs.remove('notion_last_pull_ids');
      await prefs.remove('notion_prev_sync_time');

      // ignore: unused_result
      ref.refresh(transactionNotifierProvider);

      if (mounted) {
        ToastService.showSuccess(context, 'Last Notion Sync Reverted ↩️');
        setState(() {}); // refresh UI
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Undo Failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E2C) : Colors.white;
    final inputFillColor = isDark ? Colors.black12 : Colors.grey.shade50;

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
                      color: Colors.greenAccent.withValues(alpha: 0.1),
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
                  Transform.scale(
                    scale: 0.9,
                    child: Switch(
                      value: _isEnabled,
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.green,
                      onChanged: (val) => setState(() => _isEnabled = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
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
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Database Requirements",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
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

              TextField(
                controller: _tokenController,
                enabled: _isEnabled,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: _isEnabled
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  prefixIcon: const Icon(Icons.key_rounded, size: 20),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _dbIdController,
                enabled: _isEnabled,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: _isEnabled
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  prefixIcon: const Icon(Icons.dataset_rounded, size: 20),
                ),
              ),
              
              if (_isEnabled) ...[
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

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _syncFromNotion,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download_rounded, size: 18),
                        label: Text(_isLoading ? "Syncing..." : "Sync Now"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                FutureBuilder(
                  future: SharedPreferences.getInstance().then(
                    (p) => p.getStringList('notion_last_pull_ids'),
                  ),
                  builder: (ctx, snap) {
                    if (!snap.hasData || snap.data == null || snap.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: _isLoading ? null : _undoNotionSync,
                            icon: const Icon(Icons.undo_rounded, size: 18, color: Colors.orange),
                            label: const Text("Undo Last Sync", style: TextStyle(color: Colors.orange)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: Colors.orange.withValues(alpha: 0.1),
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
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                      onPressed: _isVerifying
                          ? null
                          : () async {
                              setState(() => _isVerifying = true);
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('notion_token', _tokenController.text.trim());
                              await prefs.setString('notion_database_id', _dbIdController.text.trim());
                              await prefs.setBool('notion_enabled', _isEnabled);

                              if (_isEnabled) {
                                final success = await ref.read(notionApiClientProvider).testConnection(_tokenController.text.trim(), _dbIdController.text.trim());
                                if (success) {
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ToastService.showSuccess(context, 'Connected Successfully! ✅');
                                  }
                                } else {
                                  if (mounted) {
                                    setState(() => _isVerifying = false);
                                    ToastService.showError(context, 'Connection Failed ❌\nCheck Token/ID');
                                  }
                                }
                              } else {
                                if (mounted) {
                                  Navigator.pop(context);
                                  ToastService.showInfo(context, 'Notion Sync Disabled');
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isVerifying
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
  }
}
