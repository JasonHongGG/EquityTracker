import 'dart:io';

void main() {
  final files = [
    'lib/features/ai/utils/ai_logger.dart',
    'lib/features/ai/data/providers/gemini_provider.dart',
    'lib/features/ai/domain/agents/base_agent.dart',
    'lib/features/ai/domain/agents/extraction_agent.dart',
    'lib/features/ai/domain/usecases/process_ai_transaction_usecase.dart',
    'lib/features/ai/screens/ai_input_bottom_sheet.dart',
    'lib/features/ai/domain/factory/agent_factory.dart',
    'lib/features/settings/widgets/ai_settings_section.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    
    // Replace \$ with $
    content = content.replaceAll(r'\$', r'$');
    
    // Replace \\n with \n
    content = content.replaceAll(r'\\n', r'\n');
    
    file.writeAsStringSync(content);
    print('Fixed \$path');
  }
}
