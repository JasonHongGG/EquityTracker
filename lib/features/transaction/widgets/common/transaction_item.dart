import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:equity_tracker/core/enums/transaction_type.dart';

import 'package:equity_tracker/features/category/providers/category_notifier.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/features/settings/providers/settings_notifier.dart';
import 'package:equity_tracker/core/utils/currency_formatter.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/core/enums/sync_status.dart';

import 'package:equity_tracker/core/widgets/scale_button.dart';
import 'package:equity_tracker/features/transaction/data/transaction_model.dart';
import 'package:equity_tracker/features/category/data/category_model.dart';

class TransactionItem extends ConsumerWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final bool showDate;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final currencySymbol = settingsAsync.value?.currencySymbol ?? '\$';
    final notionState = ref.watch(notionConfigControllerProvider);
    final syncEnabled = notionState.isEnabled && notionState.connectionSuccess;

    final category = categoriesAsync.asData?.value.firstWhere(
      (c) => c.id == transaction.categoryId,
      orElse: () => CategoryModel(
        id: 'unknown',
        name: 'Unknown',
        iconCodePoint: FontAwesomeIcons.question.codePoint,
        colorValue: Colors.grey.toARGB32(),
        type: transaction.type,
        isSystem: false,
        isEnabled: true,
      ),
    );

    final color = transaction.type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;

    return ScaleButton(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.transparent),
        child: Row(
          children: [
            // Icon Bubble
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: category?.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(category?.iconData, color: category?.color, size: 18),
            ),
            const SizedBox(width: 16),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title?.isNotEmpty == true
                        ? transaction.title!
                        : (category?.name ?? 'Unknown'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (showDate || transaction.title?.isNotEmpty == true)
                    Text(
                      showDate
                          ? DateFormat('MM/dd').format(transaction.date)
                          : (category?.name ?? ''),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 12, // Ensure readable size
                      ),
                    ),
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        transaction.note!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Amount & Sync Status
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (syncEnabled) ...[
                  _buildSyncIcon(transaction.syncStatus),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${transaction.type == TransactionType.income ? '+' : '-'}${CurrencyFormatter.format(transaction.amount, currencySymbol)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Outfit',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncIcon(SyncStatus status) {
    IconData icon;
    Color color;
    switch (status) {
      case SyncStatus.synced:
        icon = Icons.cloud_done_outlined;
        color = Colors.green.withValues(alpha: 0.4);
        break;
      case SyncStatus.pendingCreate:
      case SyncStatus.pendingUpdate:
      case SyncStatus.pendingDelete:
        icon = Icons.cloud_upload_outlined;
        color = Colors.orange.withValues(alpha: 0.6);
        break;
    }
    return Tooltip(
      message: status == SyncStatus.synced ? 'Synced to Notion' : 'Sync pending...',
      child: Icon(icon, size: 14, color: color),
    );
  }
}
