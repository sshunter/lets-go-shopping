import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:lgs_tooling/lgs_tooling.dart';

void main() {
  late Directory sandbox;
  late String repoRoot;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('lgs_report_');
    repoRoot = '${sandbox.path}/repo';
  });
  tearDown(() {
    if (sandbox.existsSync()) sandbox.deleteSync(recursive: true);
  });

  group('buildReportRows', () {
    test('flags direct plugin deps, leaves transitive deps unassessed', () {
      final cache = Directory('${sandbox.path}/cache');
      _makePkg(cache, 'home_widget-0.9.2', pluginPlatforms: ['android', 'ios']);
      _makePkg(cache, 'sqflite-2.4.3', pluginPlatforms: ['android', 'ios', 'macos']);
      _makePkg(cache, 'path-1.9.1');
      _makePkg(cache, 'bloc-9.2.1');
      _makePkg(cache, 'uuid-4.5.3');
      _makePkg(cache, 'mocktail-1.0.5');
      final config = ZoneConfig.all[Zone.androidApp]!;
      _writePackageConfig(repoRoot, config.label, {
        'home_widget': 'file://${cache.path}/home_widget-0.9.2',
        'sqflite': 'file://${cache.path}/sqflite-2.4.3',
        'path': 'file://${cache.path}/path-1.9.1',
        'bloc': 'file://${cache.path}/bloc-9.2.1',
        'uuid': 'file://${cache.path}/uuid-4.5.3',
        'mocktail': 'file://${cache.path}/mocktail-1.0.5',
      });

      final outdated = [
        _pkg('home_widget', 'direct', cur: '0.9.2', up: '0.9.3'),
        _pkg('sqflite', 'direct', cur: '2.4.3', up: '2.4.4'),
        _pkg('path', 'direct', cur: '1.9.1', up: '1.9.2'),
        _pkg('bloc', 'direct', cur: '9.2.1', up: '9.2.1'),
        _pkg('uuid', 'direct', cur: '4.5.3', up: '4.6.0'),
        _pkg('mocktail', 'direct', cur: '1.0.5', up: '1.0.6'),
        _pkg('jni', 'transitive', cur: '1.0.0', up: '1.0.3'),
      ];
      final rows = buildReportRows(config, repoRoot, outdated);

      final byName = {for (final r in rows) r.name: r};
      expect(byName['home_widget']!.risk, 'yes');
      expect(byName['home_widget']!.platforms, 'android,ios');
      expect(byName['sqflite']!.risk, 'yes');
      // path is pure-Dart: not a native-coupling risk.
      expect(byName['path']!.risk, 'no');
      expect(byName['path']!.platforms, isEmpty);
      expect(byName['bloc']!.risk, 'no');
      expect(byName['uuid']!.risk, 'no');
      expect(byName['mocktail']!.risk, 'no');
      // Transitive deps are shown but not assessed.
      expect(byName['jni']!.risk, '-');
      expect(byName['jni']!.platforms, isEmpty);
    });
  });

  group('formatReportTable', () {
    test('renders a header and one row per package', () {
      final rows = [
        ReportRow(
          name: 'home_widget',
          kind: 'direct',
          current: '0.9.2',
          upgradable: '0.9.3',
          resolvable: '0.9.3',
          latest: '0.9.3',
          risk: 'yes',
          platforms: 'android,ios',
        ),
        ReportRow(
          name: 'bloc',
          kind: 'direct',
          current: '9.2.1',
          upgradable: '9.2.1',
          resolvable: '9.2.1',
          latest: '9.2.2',
          risk: 'no',
          platforms: '',
        ),
      ];
      final table = formatReportTable('android_app', rows);
      expect(table, startsWith('## android_app\n'));
      expect(table, contains('home_widget'));
      expect(table, contains('android,ios'));
      expect(table, contains('Package'));
      expect(table, contains('Risk'));
    });

    test('notes when there are no outdated dependencies', () {
      final table = formatReportTable('shared_core', const []);
      expect(table, contains('(no outdated dependencies)'));
    });
  });

  group('formatSummary', () {
    test('counts total, direct, and risk-flagged rows across zones', () {
      final summary = formatSummary({
        Zone.sharedCore: [
          ReportRow(name: 'bloc', kind: 'direct', current: '9.2.1', upgradable: '9.2.2', resolvable: '9.2.2', latest: '9.2.2', risk: 'no', platforms: ''),
          ReportRow(name: 'uuid', kind: 'direct', current: '4.5.3', upgradable: '4.6.0', resolvable: '4.6.0', latest: '4.6.0', risk: 'no', platforms: ''),
        ],
        Zone.androidApp: [
          ReportRow(name: 'home_widget', kind: 'direct', current: '0.9.2', upgradable: '0.9.3', resolvable: '0.9.3', latest: '0.9.3', risk: 'yes', platforms: 'android,ios'),
          ReportRow(name: 'jni', kind: 'transitive', current: '1.0.0', upgradable: '1.0.3', resolvable: '1.0.3', latest: '1.0.3', risk: '-', platforms: ''),
        ],
      });
      expect(summary, 'Summary: 4 outdated (3 direct), 1 native-coupling-risk.');
    });
  });
}

OutdatedPackage _pkg(
  String name,
  String kind, {
  String? cur,
  String? up,
  String? res,
  String? latest,
}) {
  return OutdatedPackage(
    name: name,
    kind: kind,
    current: cur,
    upgradable: up,
    resolvable: res,
    latest: latest,
    isDiscontinued: false,
    isCurrentRetracted: false,
    isCurrentAffectedByAdvisory: false,
  );
}

void _makePkg(Directory cache, String dirName, {List<String> pluginPlatforms = const []}) {
  final pkgDir = Directory('${cache.path}/$dirName')..createSync(recursive: true);
  final buf = StringBuffer('name: ${dirName.split('-').first}\n');
  if (pluginPlatforms.isNotEmpty) {
    buf.writeln('flutter:');
    buf.writeln('  plugin:');
    buf.writeln('    platforms:');
    for (final p in pluginPlatforms) {
      buf.writeln('      $p:');
      buf.writeln('        pluginClass: FooPlugin');
    }
  }
  File('${pkgDir.path}/pubspec.yaml').writeAsStringSync(buf.toString());
}

void _writePackageConfig(String repoRoot, String zoneLabel, Map<String, String> roots) {
  final dir = Directory('$repoRoot/$zoneLabel/.dart_tool')..createSync(recursive: true);
  final file = File('${dir.path}/package_config.json');
  file.writeAsStringSync(jsonEncode({
    'configVersion': 2,
    'packages': [
      for (final e in roots.entries) {'name': e.key, 'rootUri': e.value},
    ],
  }));
}