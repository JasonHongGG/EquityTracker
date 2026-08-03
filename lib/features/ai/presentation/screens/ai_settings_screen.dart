import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_section.dart';

class AiSettingsScreen extends ConsumerWidget {
  const AiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(aiConfigControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 智慧記帳設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SettingsSection(
            title: '提供者與模型',
            children: [
              ListTile(
                title: const Text('AI Provider'),
                subtitle: Text(config.providerType.name.toUpperCase()),
                trailing: DropdownButton<AIProviderType>(
                  value: config.providerType,
                  underline: const SizedBox(),
                  items: AIProviderType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(aiConfigControllerProvider.notifier).saveConfig(
                            providerType: value,
                            baseUrl: config.baseUrl,
                            modelName: config.modelName,
                            googleMapApiKey: config.googleMapApiKey,
                          );
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Model Name'),
                subtitle: Text(config.modelName),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () => _editConfig(
                  context,
                  ref,
                  'Model Name',
                  config.modelName,
                  (newVal) => ref.read(aiConfigControllerProvider.notifier).saveConfig(
                        providerType: config.providerType,
                        baseUrl: config.baseUrl,
                        modelName: newVal,
                        googleMapApiKey: config.googleMapApiKey,
                      ),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: '伺服器設定',
            children: [
              ListTile(
                title: const Text('Base URL (API Server)'),
                subtitle: Text(
                  config.baseUrl.isEmpty ? 'http://127.0.0.1:8000' : config.baseUrl,
                  style: TextStyle(
                    color: config.baseUrl.isEmpty ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () => _editConfig(
                  context,
                  ref,
                  'Base URL',
                  config.baseUrl,
                  (newVal) => ref.read(aiConfigControllerProvider.notifier).saveConfig(
                        providerType: config.providerType,
                        baseUrl: newVal,
                        modelName: config.modelName,
                        googleMapApiKey: config.googleMapApiKey,
                      ),
                ),
              ),
              ListTile(
                title: const Text('Google Map API Key'),
                subtitle: Text(
                  config.googleMapApiKey.isEmpty
                      ? '尚未設定 (無地圖搜尋功能)'
                      : '••••••••\${config.googleMapApiKey.length > 4 ? config.googleMapApiKey.substring(config.googleMapApiKey.length - 4) : ''}',
                  style: TextStyle(
                    color: config.googleMapApiKey.isEmpty ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () => _editConfig(
                  context,
                  ref,
                  'Google Map API Key',
                  config.googleMapApiKey,
                  (newVal) => ref.read(aiConfigControllerProvider.notifier).saveConfig(
                        providerType: config.providerType,
                        baseUrl: config.baseUrl,
                        modelName: config.modelName,
                        googleMapApiKey: newVal,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editConfig(BuildContext context, WidgetRef ref, String title, String currentValue, Function(String) onSave) {
    String tempValue = currentValue;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit \$title'),
        content: TextFormField(
          initialValue: currentValue,
          onChanged: (val) => tempValue = val,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Enter \$title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              onSave(tempValue);
              Navigator.pop(context);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }
}
