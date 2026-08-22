import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:lgs_tooling/lgs_tooling.dart';

void main() {
  late Directory sandbox;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('lgs_plugin_detect_');
  });
  tearDown(() {
    if (sandbox.existsSync()) sandbox.deleteSync(recursive: true);
  });

  group('pluginPlatformsFromPubspec', () {
    test('returns platform keys for a Flutter plugin', () {
      final platforms = pluginPlatformsFromPubspec({
        'flutter': {
          'plugin': {
            'platforms': {
              'android': {'pluginClass': 'Foo'},
              'ios': {'pluginClass': 'Foo'},
            },
          },
        },
      });
      expect(platforms, containsAll(['android', 'ios']));
      expect(platforms, hasLength(2));
    });

    test('returns empty for a pure-Dart package (no flutter section)', () {
      expect(pluginPlatformsFromPubspec({'name': 'path'}), isEmpty);
    });

    test('returns empty when platforms map is empty', () {
      expect(
        pluginPlatformsFromPubspec({'flutter': {'plugin': {'platforms': {}}}}),
        isEmpty,
      );
    });

    test('returns empty when plugin section is missing', () {
      expect(pluginPlatformsFromPubspec({'flutter': {}}), isEmpty);
    });

    test('returns empty for non-map input', () {
      expect(pluginPlatformsFromPubspec({'flutter': 'nope'}), isEmpty);
      expect(pluginPlatformsFromPubspec({}), isEmpty);
    });
  });

  group('detectNativeCouplingRisk', () {
    test('flags a direct dep whose pubspec declares plugin platforms', () {
      final pkgDir = Directory('${sandbox.path}/home_widget-0.9.2')
        ..createSync(recursive: true);
      File('${pkgDir.path}/pubspec.yaml').writeAsStringSync('''
name: home_widget
flutter:
  plugin:
    platforms:
      android:
        package: es.antonborri.home_widget
        pluginClass: HomeWidgetPlugin
      ios:
        pluginClass: HomeWidgetPlugin
''');
      final configPath = _writePackageConfig(sandbox, {
        'home_widget': pkgDir.uri.toString(),
      });

      final risk = detectNativeCouplingRisk(configPath, 'home_widget');
      expect(risk, isNotNull);
      expect(risk!.nativeCouplingRisk, isTrue);
      expect(risk.platforms, containsAll(['android', 'ios']));
    });

    test('does not flag a pure-Dart direct dep', () {
      final pkgDir = Directory('${sandbox.path}/path-1.9.1')
        ..createSync(recursive: true);
      File('${pkgDir.path}/pubspec.yaml').writeAsStringSync('''
name: path
description: A pure-Dart string path library.
''');
      final configPath = _writePackageConfig(sandbox, {
        'path': pkgDir.uri.toString(),
      });

      final risk = detectNativeCouplingRisk(configPath, 'path');
      expect(risk, isNotNull);
      expect(risk!.nativeCouplingRisk, isFalse);
      expect(risk.platforms, isEmpty);
    });

    test('returns null when the package is not in package_config.json', () {
      final configPath = _writePackageConfig(sandbox, {});
      expect(detectNativeCouplingRisk(configPath, 'missing'), isNull);
    });

    test('returns null when the pubspec file is absent', () {
      final pkgDir = Directory('${sandbox.path}/empty-1.0.0')
        ..createSync(recursive: true);
      final configPath = _writePackageConfig(sandbox, {
        'empty': pkgDir.uri.toString(),
      });
      expect(detectNativeCouplingRisk(configPath, 'empty'), isNull);
    });

    test('resolves file:// rootUris to a filesystem path', () {
      final pkgDir = Directory('${sandbox.path}/sqflite-2.4.3')
        ..createSync(recursive: true);
      File('${pkgDir.path}/pubspec.yaml').writeAsStringSync('''
name: sqflite
flutter:
  plugin:
    platforms:
      android:
        default_package: sqflite_android
      ios:
        default_package: sqflite_darwin
''');
      final configPath = _writePackageConfig(sandbox, {
        'sqflite': 'file://${pkgDir.path}',
      });

      final risk = detectNativeCouplingRisk(configPath, 'sqflite');
      expect(risk, isNotNull);
      expect(risk!.nativeCouplingRisk, isTrue);
      expect(risk.platforms, containsAll(['android', 'ios']));
    });
  });
}

String _writePackageConfig(Directory sandbox, Map<String, String> roots) {
  final packages = [
    for (final entry in roots.entries)
      {'name': entry.key, 'rootUri': entry.value},
  ];
  final file = File('${sandbox.path}/.dart_tool/package_config.json')
    ..createSync(recursive: true);
  file.writeAsStringSync(jsonEncode({'configVersion': 2, 'packages': packages}));
  return file.path;
}
