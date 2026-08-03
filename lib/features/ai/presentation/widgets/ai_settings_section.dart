import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_section.dart';
import 'package:equity_tracker/features/settings/widgets/common/settings_tile.dart';

class AiSettingsSection extends ConsumerWidget {
  const AiSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(aiConfigControllerProvider);
    final theme = Theme.of(context);

    return SettingsSection(
      title: 'AI 智慧記帳',
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
                      apiKey: config.apiKey,
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
                  apiKey: config.apiKey,
                  modelName: newVal,
                  googleMapApiKey: config.googleMapApiKey,
                ),
          ),
        ),
        ListTile(
          title: const Text('API Key'),
          subtitle: Text(
            config.apiKey.isEmpty
                ? '尚未設定'
                : '••••••••\${config.apiKey.length > 4 ? config.apiKey.substring(config.apiKey.length - 4) : ''}',
            style: TextStyle(
              color: config.apiKey.isEmpty ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: const Icon(Icons.edit, size: 20),
          onTap: () => _editConfig(
            context,
            ref,
            'API Key',
            config.apiKey,
            (newVal) => ref.read(aiConfigControllerProvider.notifier).saveConfig(
                  providerType: config.providerType,
                  apiKey: newVal,
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
                  apiKey: config.apiKey,
                  modelName: config.modelName,
                  googleMapApiKey: newVal,
                ),
          ),
        ),
      ],
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
