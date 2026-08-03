import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/core/widgets/toast_notification.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/core/widgets/app_switch.dart';

class NotionConfigDialog extends ConsumerStatefulWidget {
  const NotionConfigDialog({super.key});

  @override
  ConsumerState<NotionConfigDialog> createState() => _NotionConfigDialogState();
}

class _NotionConfigDialogState extends ConsumerState<NotionConfigDialog> {
  late TextEditingController _tokenController;
  late TextEditingController _dbIdController;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
    _dbIdController = TextEditingController();
    
    // We can't immediately read state and set text if we wait for future, 
    // but the state is sync initialized empty then loaded. We will just listen to state changes.
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _dbIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notionConfigControllerProvider);
    final controller = ref.read(notionConfigControllerProvider.notifier);

    // Sync text controllers with state initially if they are empty
    if (_tokenController.text.isEmpty && state.token.isNotEmpty) {
      _tokenController.text = state.token;
    }
    if (_dbIdController.text.isEmpty && state.dbId.isNotEmpty) {
      _dbIdController.text = state.dbId;
    }

    // Listen for messages to show toasts
    ref.listen<NotionConfigState>(notionConfigControllerProvider, (previous, next) {
      if (next.message != null && (previous?.message != next.message)) {
        if (next.isError) {
          ToastService.showError(context, next.message!);
        } else {
          ToastService.showSuccess(context, next.message!);
        }
        
        if (next.connectionSuccess) {
          Navigator.pop(context);
        }
        
        Future.microtask(() => controller.clearMessage());
      }
    });

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
                    child: AppSwitch(
                      value: state.isEnabled,
                      activeColor: Colors.green,
                      onChanged: controller.toggleEnabled,
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
                enabled: state.isEnabled,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: state.isEnabled
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
                enabled: state.isEnabled,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: state.isEnabled
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
              
              if (state.isEnabled) ...[
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
                        onPressed: state.isLoading ? null : () {
                          controller.updateToken(_tokenController.text);
                          controller.updateDbId(_dbIdController.text);
                          controller.syncFromNotion();
                        },
                        icon: state.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download_rounded, size: 18),
                        label: Text(state.isLoading ? "Syncing..." : "Sync Now"),
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
                            onPressed: state.isLoading ? null : controller.undoNotionSync,
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
                      onPressed: state.isVerifying
                          ? null
                          : () {
                              controller.saveAndVerify(_tokenController.text, _dbIdController.text);
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
                      child: state.isVerifying
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
