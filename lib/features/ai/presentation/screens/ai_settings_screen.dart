import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/models/ai_provider_config.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  late TextEditingController _modelNameController;
  late TextEditingController _baseUrlController;
  late TextEditingController _projectIdController;
  late TextEditingController _regionController;
  late TextEditingController _accessTokenController;
  late TextEditingController _googleMapApiController;
  
  AIProviderType? _lastProviderType;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _modelNameController = TextEditingController();
    _baseUrlController = TextEditingController();
    _projectIdController = TextEditingController();
    _regionController = TextEditingController();
    _accessTokenController = TextEditingController();
    _googleMapApiController = TextEditingController();
  }

  @override
  void dispose() {
    _modelNameController.dispose();
    _baseUrlController.dispose();
    _projectIdController.dispose();
    _regionController.dispose();
    _accessTokenController.dispose();
    _googleMapApiController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _syncControllers(AIConfigState state) {
    if (_lastProviderType == state.providerType) return;
    _lastProviderType = state.providerType;
    
    final config = state.activeConfig;
    
    if (_modelNameController.text != config.modelName) {
      _modelNameController.text = config.modelName;
    }
    
    if (_googleMapApiController.text != state.googleMapApiKey) {
      _googleMapApiController.text = state.googleMapApiKey;
    }

    if (config is GeminiFlowConfig) {
      if (_baseUrlController.text != config.baseUrl) _baseUrlController.text = config.baseUrl;
    } else if (config is OllamaConfig) {
      if (_baseUrlController.text != config.baseUrl) _baseUrlController.text = config.baseUrl;
    } else if (config is VertexAIConfig) {
      if (_projectIdController.text != config.projectId) _projectIdController.text = config.projectId;
      if (_regionController.text != config.region) _regionController.text = config.region;
      if (_accessTokenController.text != config.accessToken) _accessTokenController.text = config.accessToken;
    }
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final state = ref.read(aiConfigControllerProvider);
      final config = state.activeConfig;
      
      ProviderConfig newConfig = config;
      if (config is GeminiFlowConfig) {
        newConfig = config.copyWith(
          modelName: _modelNameController.text,
          baseUrl: _baseUrlController.text,
        );
      } else if (config is OllamaConfig) {
        newConfig = config.copyWith(
          modelName: _modelNameController.text,
          baseUrl: _baseUrlController.text,
        );
      } else if (config is VertexAIConfig) {
        newConfig = config.copyWith(
          modelName: _modelNameController.text,
          projectId: _projectIdController.text,
          region: _regionController.text,
          accessToken: _accessTokenController.text,
        );
      }

      ref.read(aiConfigControllerProvider.notifier).saveConfig(
        activeProviderConfig: newConfig,
        googleMapApiKey: _googleMapApiController.text,
      );
    });
  }

  IconData _getProviderIcon(AIProviderType type) {
    if (type == AIProviderType.geminiflow) return Icons.auto_awesome;
    if (type == AIProviderType.ollama) return Icons.memory_rounded;
    return Icons.cloud_done_rounded;
  }

  void _showProviderSelectorBottomSheet(AIConfigState state, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'AI Engine',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ...AIProviderType.values.map((type) {
                final isSelected = state.providerType == type;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  tileColor: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
                  leading: Icon(
                    _getProviderIcon(type),
                    color: isSelected ? Theme.of(context).primaryColor : (isDark ? Colors.white54 : Colors.black54),
                  ),
                  title: Text(
                    type.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Theme.of(context).primaryColor : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  trailing: isSelected 
                    ? Icon(Icons.check_circle_rounded, color: Theme.of(context).primaryColor)
                    : null,
                  onTap: () {
                    _lastProviderType = null;
                    ref.read(aiConfigControllerProvider.notifier).saveConfig(providerType: type);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSmartSelector(AIConfigState state, bool isDark) {
    final type = state.providerType;
    return GestureDetector(
      onTap: () => _showProviderSelectorBottomSheet(state, isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _getProviderIcon(type),
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                type.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalField(String hint, IconData icon, TextEditingController controller, bool isDark, {bool obscureText = false}) {
    return TextFormField(
      controller: controller,
      onChanged: (_) => _onFieldChanged(),
      obscureText: obscureText,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Outfit',
          color: isDark ? Colors.white30 : Colors.black38,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(
            icon,
            color: isDark ? Colors.white54 : Colors.black45,
            size: 20,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        filled: true,
        fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedForm(AIConfigState state, bool isDark) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: Column(
        key: ValueKey(state.providerType),
        children: [
          _buildMinimalField('Model Name', Icons.smart_toy_rounded, _modelNameController, isDark),
          const SizedBox(height: 16),
          if (state.activeConfig is VertexAIConfig) ...[
            _buildMinimalField('Project ID', Icons.business_rounded, _projectIdController, isDark),
            const SizedBox(height: 16),
            _buildMinimalField('Region', Icons.public_rounded, _regionController, isDark),
            const SizedBox(height: 16),
            _buildMinimalField('Access Token', Icons.key_rounded, _accessTokenController, isDark, obscureText: true),
          ] else ...[
            _buildMinimalField('Base URL', Icons.dns_rounded, _baseUrlController, isDark),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiConfigControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _syncControllers(state);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'AI Configuration',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          children: [
            _buildSmartSelector(state, isDark),
            const SizedBox(height: 32),
            _buildAnimatedForm(state, isDark),
            const SizedBox(height: 32),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 32),
            _buildMinimalField('Google Map API Key (Optional)', Icons.map_rounded, _googleMapApiController, isDark, obscureText: true),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
