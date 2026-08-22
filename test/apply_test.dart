import 'dart:io';

import 'package:test/test.dart';
import 'package:lgs_tooling/lgs_tooling.dart';

void main() {
  late Directory sandbox;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('lgs_apply_');
  });
  tearDown(() {
    if (sandbox.existsSync()) sandbox.deleteSync(recursive: true);
  });

  group('diffLocks', () {
    test('reports version bumps', () {
      final changes = diffLocks(
        {'packages': {'bloc': {'version': '9.2.1'}, 'uuid': {'version': '4.5.1'}}},
        {'packages': {'bloc': {'version': '9.2.2'}, 'uuid': {'version': '4.5.1'}}},
      );
      final bump = changes.singleWhere((c) => c.name == 'bloc');
      expect(bump.isBump, isTrue);
      expect(bump.oldVersion, '9.2.1');
      expect(bump.newVersion, '9.2.2');
      final unchanged = changes.singleWhere((c) => c.name == 'uuid');
      expect(unchanged.isBump, isFalse);
    });

    test('reports added packages', () {
      final changes = diffLocks(
        {'packages': {'bloc': {'version': '9.2.1'}}},
        {'packages': {'bloc': {'version': '9.2.1'}, 'uuid': {'version': '4.5.1'}}},
      );
      final added = changes.singleWhere((c) => c.name == 'uuid');
      expect(added.added, isTrue);
      expect(added.newVersion, '4.5.1');
    });

    test('reports removed packages', () {
      final changes = diffLocks(
        {'packages': {'bloc': {'version': '9.2.1'}, 'uuid': {'version': '4.5.1'}}},
        {'packages': {'bloc': {'version': '9.2.1'}}},
      );
      final removed = changes.singleWhere((c) => c.name == 'uuid');
      expect(removed.removed, isTrue);
      expect(removed.oldVersion, '4.5.1');
    });

    test('handles missing packages map', () {
      expect(diffLocks({}, {}), isEmpty);
      expect(diffLocks({'packages': {}}, {}), isEmpty);
    });

    test('preserves package metadata versions as strings', () {
      final changes = diffLocks(
        {'packages': {'x': {'version': 1}}},
        {'packages': {'x': {'version': 2}}},
      );
      final x = changes.singleWhere((c) => c.name == 'x');
      expect(x.oldVersion, '1');
      expect(x.newVersion, '2');
    });
  });

  group('snapshotZone / restoreZone round-trip', () {
    final config = ZoneConfig.all[Zone.sharedCore]!;

    test('snapshots then restores pubspec.yaml and pubspec.lock', () async {
      final repo = Directory('${sandbox.path}/repo/shared_core')
        ..createSync(recursive: true);
      File('${repo.path}/pubspec.yaml').writeAsStringSync('name: shared_core\n');
      File('${repo.path}/pubspec.lock').writeAsStringSync('packages:\n  bloc:\n    version: 9.2.1\n');

      final snap = snapshotZone(config, '${sandbox.path}/repo', sandbox);
      expect(File(snap.pubspecYamlPath).existsSync(), isTrue);
      expect(File(snap.lockPath).existsSync(), isTrue);

      // Simulate an upgrade modifying the lock.
      File('${repo.path}/pubspec.lock').writeAsStringSync('packages:\n  bloc:\n    version: 9.2.2\n');

      // Restore via a fake runner that records the `pub get` call.
      final calls = <List<String>>[];
      await restoreZone(
        config,
        '${sandbox.path}/repo',
        snap,
        (command, dir) async {
          calls.add(command);
          return CommandResult(0, '', '');
        },
      );

      expect(File('${repo.path}/pubspec.lock').readAsStringSync(),
          contains('9.2.1'));
      expect(calls, hasLength(1));
      expect(calls.first, config.getCommand());
    });

    test('restore deletes the live lock when the snapshot had none', () async {
      final repo = Directory('${sandbox.path}/repo/shared_core')
        ..createSync(recursive: true);
      File('${repo.path}/pubspec.yaml').writeAsStringSync('name: shared_core\n');
      // No pubspec.lock in the snapshot, but a live one exists after "upgrade".
      File('${repo.path}/pubspec.lock').writeAsStringSync('packages:\n');

      final snap = snapshotZone(config, '${sandbox.path}/repo', sandbox);
      // Force the snapshot to have no lock copy by deleting it.
      File(snap.lockPath).deleteSync();
      final emptySnap = ZoneSnapshot(config, snap.pubspecYamlPath, '', sandbox);

      await restoreZone(
        config,
        '${sandbox.path}/repo',
        emptySnap,
        (_, _) async => CommandResult(0, '', ''),
      );

      expect(File('${repo.path}/pubspec.lock').existsSync(), isFalse);
    });
  });

  group('zoneModified', () {
    final config = ZoneConfig.all[Zone.sharedCore]!;

    test('false when files match the snapshot', () {
      final repo = Directory('${sandbox.path}/repo/shared_core')
        ..createSync(recursive: true);
      File('${repo.path}/pubspec.yaml').writeAsStringSync('name: shared_core\n');
      File('${repo.path}/pubspec.lock').writeAsStringSync('lock: 1\n');
      final snap = snapshotZone(config, '${sandbox.path}/repo', sandbox);
      expect(zoneModified(config, '${sandbox.path}/repo', snap), isFalse);
    });

    test('true when the lock changed', () {
      final repo = Directory('${sandbox.path}/repo/shared_core')
        ..createSync(recursive: true);
      File('${repo.path}/pubspec.yaml').writeAsStringSync('name: shared_core\n');
      File('${repo.path}/pubspec.lock').writeAsStringSync('lock: 1\n');
      final snap = snapshotZone(config, '${sandbox.path}/repo', sandbox);
      File('${repo.path}/pubspec.lock').writeAsStringSync('lock: 2\n');
      expect(zoneModified(config, '${sandbox.path}/repo', snap), isTrue);
    });
  });
}