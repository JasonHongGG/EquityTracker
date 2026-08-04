import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equity_tracker/core/widgets/toast_notification.dart';
import 'package:equity_tracker/features/notion_sync/controllers/notion_config_controller.dart';
import 'package:equity_tracker/core/widgets/app_switch.dart';

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
          ToastService.showError(context, next.message!);
        } else {
          ToastService.showSuccess(context, next.message!);
        }
        
        Future.microtask(() => controller.clearMessage());
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111116) : const Color(0xFFF7F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Glow Effect
          if (state.isEnabled)
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Positioned(
                  top: -100,
                  right: -50,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: state.isVerifying || state.isLoading
                          ? Colors.orange.withValues(alpha: 0.15 + (_glowController.value * 0.1))
                          : state.connectionSuccess 
                              ? Colors.green.withValues(alpha: 0.1 + (_glowController.value * 0.1))
                              : Colors.blue.withValues(alpha: 0.1 + (_glowController.value * 0.05)),
                    ),
                  ),
                );
              },
            ),
          
          if (state.isEnabled)
            Positioned(
              top: -100,
              right: -50,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(
                  width: 300,
                  height: 300,
                  color: Colors.transparent,
                ),
              ),
            ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notion \nIntegration',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AI Cross-Referencing Engine',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              color: isDark ? Colors.white38 : Colors.black38,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      AppSwitch(
                        value: state.isEnabled,
                        activeColor: Colors.blue,
                        onChanged: controller.toggleEnabled,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Token Input
                  _buildSectionHeader('API TOKEN', isDark),
                  const SizedBox(height: 12),
                  _buildGlassTextField(
                    controller: _tokenController,
                    hint: 'secret_XXXXXXXX',
                    icon: Icons.key_rounded,
                    isDark: isDark,
                    enabled: state.isEnabled,
                    obscure: true,
                  ),
                  const SizedBox(height: 24),

                  // DB ID Input
                  _buildSectionHeader('DATABASE ID', isDark),
                  const SizedBox(height: 12),
                  _buildGlassTextField(
                    controller: _dbIdController,
                    hint: '32 character ID',
                    icon: Icons.dataset_rounded,
                    isDark: isDark,
                    enabled: state.isEnabled,
                    obscure: false,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // DB requirement tip
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: isDark ? Colors.white54 : Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Required Columns: "名稱", "金額", "類別", "時間"',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Save & Verify Button
                  if (state.isEnabled)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.isVerifying
                            ? null
                            : () {
                                controller.saveAndVerify(_tokenController.text, _dbIdController.text);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.connectionSuccess ? Colors.green : Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: state.isVerifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                state.connectionSuccess ? 'Verified & Linked' : 'Verify & Save',
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                      ),
                    ),

                  // Data Sync Actions
                  if (state.isEnabled && state.connectionSuccess) ...[
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_sync_outlined, color: Colors.green, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Automated Sync Active",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Transactions are seamlessly synced in the background.",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: isDark ? Colors.white38 : Colors.black38,
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required bool enabled,
    required bool obscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscure,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: enabled
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? Colors.white24 : Colors.black26),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark ? Colors.white24 : Colors.black26,
            fontFamily: 'Outfit',
          ),
          prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.black54, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }


}
