import 'dart:convert';
import 'dart:io';

void main() {
  final configFile = File('.dart_tool/package_config.json').absolute;
  final config = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
  final configUri = configFile.uri;
  final lines = <String>[];

  for (final package in (config['packages'] as List)) {
    final item = package as Map<String, dynamic>;
    final rootText = item['rootUri'] as String;
    Uri rootUri = Uri.parse(rootText);
    if (!rootUri.isAbsolute) {
      rootUri = configUri.resolve(rootText);
    }
    rootUri = Uri.parse(rootUri.toString().endsWith('/') ? rootUri.toString() : '${rootUri.toString()}/');
    final packageUri = rootUri.resolve(item['packageUri'] as String);
    lines.add('${item['name']}=${packageUri.toString()}');
  }

  File('.packages').writeAsStringSync('${lines.join('\n')}\n');
}
