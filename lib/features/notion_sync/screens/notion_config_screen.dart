import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/core/widgets/app_switch.dart';
import 'package:equity_tracker/core/widgets/premium_config_card.dart';
import 'package:equity_tracker/core/widgets/premium_config_header.dart';
import 'package:equity_tracker/core/widgets/immersive_scaffold.dart';
import 'package:equity_tracker/core/providers/notification_provider.dart';

class NotionConfigScreen extends ConsumerStatefulWidget {
  const NotionConfigScreen({super.key});

  @override
  ConsumerState<NotionConfigScreen> createState() => _NotionConfigScreenState();
}

class _NotionConfigScreenState extends ConsumerState<NotionConfigScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _tokenController;
  late TextEditingController _dbIdController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
    _dbIdController = TextEditingController();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _dbIdController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notionConfigControllerProvider);
    final controller = ref.read(notionConfigControllerProvider.notifier);

    if (_tokenController.text.isEmpty && state.token.isNotEmpty) {
      _tokenController.text = state.token;
    }
    if (_dbIdController.text.isEmpty && state.dbId.isNotEmpty) {
      _dbIdController.text = state.dbId;
    }

    ref.listen<NotionConfigState>(notionConfigControllerProvider, (previous, next) {
      if (next.message != null && (previous?.message != next.message)) {
        if (next.isError) {
          ref.read(notificationControllerProvider.notifier).showError(next.message!);
        } else {
          ref.read(notificationControllerProvider.notifier).showSuccess(next.message!);
        }
        
        Future.microtask(() => controller.clearMessage());
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ImmersiveScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumConfigHeader(
              title: 'Notion\nIntegration',
              subtitle: 'AI Cross-Referencing Engine'.toUpperCase(),
              trailing: AppSwitch(
                value: state.isEnabled,
                onChanged: (val) {
                  ref.read(notionConfigControllerProvider.notifier).toggleEnabled(val);
                  HapticFeedback.lightImpact();
                },
                activeColor: theme.primaryColor,
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  if (state.isEnabled) ...[
                    PremiumConfigCard(
                      child: Column(
                        children: [
                          _buildGlassTextField(
                            controller: _tokenController,
                            hint: 'Integration Token',
                            icon: Icons.key_rounded,
                            isDark: isDark,
                            obscureText: true,
                          ),
                          Divider(height: 1, thickness: 1, color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), indent: 56),
                          _buildGlassTextField(
                            controller: _dbIdController,
                            hint: 'Database ID',
                            icon: Icons.table_chart_rounded,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                          const SizedBox(width: 6),
                          Text(
                            'Required Columns: "名稱", "金額", "類別", "時間"',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Save & Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton(
                          onPressed: state.isVerifying || state.isLoading
                              ? null
                              : () {
                                  controller.saveAndVerify(_tokenController.text, _dbIdController.text);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.connectionSuccess 
                                ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
                                : (isDark ? Colors.white : Colors.black),
                            foregroundColor: state.connectionSuccess
                                ? (isDark ? Colors.white54 : Colors.black54)
                                : (isDark ? Colors.black : Colors.white),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: state.isVerifying
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isDark ? Colors.black : Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (state.connectionSuccess) ...[
                                      const Icon(Icons.check_circle_outline_rounded, size: 20),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      state.connectionSuccess ? 'Verified & Linked' : 'Verify & Save',
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(
        fontFamily: 'Outfit',
        color: isDark ? Colors.white : Colors.black,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : Colors.black38,
          fontFamily: 'Outfit',
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(icon, color: isDark ? Colors.white54 : Colors.black54, size: 22),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 50),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        filled: true,
        fillColor: Colors.transparent,
      ),
    );
  }
}
