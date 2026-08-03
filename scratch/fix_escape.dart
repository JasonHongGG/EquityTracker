import 'dart:io';

void main() {
  final dir = Directory('lib/features/ai');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    var content = file.readAsStringSync();
    if (content.contains(r'\$')) {
      content = content.replaceAll(r'\$', r'$');
      file.writeAsStringSync(content);
      print('Fixed \$ file: \${file.path}');
    }
  }
}
