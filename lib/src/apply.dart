/// `apply` subcommand: within-constraint upgrades across the three zones, with
/// all-or-nothing rollback and a native-blocker runbook pointer.
///
/// Walks the zones in dependency order (shared_core first), runs
/// `<dart|flutter> pub upgrade` (never `--major-versions`), then the zone's
/// verification gate. On a gate failure it restores snapshots per the rollback
/// rule, prints the failing zone + gate error verbatim, and (for native
/// blocks) points at the runbook. On full success it leaves staged
/// pubspec/lock diffs and prints a per-package change summary; it never
/// commits or opens a PR.
library;

import 'dart:io';

import 'gate_error.dart';
import 'plugin_detect.dart';
import 'process_runner.dart';
import 'rollback.dart';
import 'zone.dart';

/// One package version change between the pre-upgrade and post-upgrade lock.
class LockChange {
  final String name;
  final String? oldVersion;
  final String? newVersion;

  /// true when the package is new in the upgraded lock.
  final bool added;

  /// true when the package is gone from the upgraded lock.
  final bool removed;

  LockChange({
    required this.name,
    required this.oldVersion,
    required this.newVersion,
    required this.added,
    required this.removed,
  });

  bool get isBump => !added && !removed && oldVersion != newVersion;

  @override
  String toString() {
    if (added) return '$name (added: $newVersion)';
    if (removed) return '$name (removed: was $oldVersion)';
    return '$name: $oldVersion -> $newVersion';
  }
}

/// A captured pre-upgrade snapshot of one zone's pubspec.yaml + pubspec.lock.
class ZoneSnapshot {
  final ZoneConfig zone;
  final String pubspecYamlPath;
  final String lockPath;
  final Directory snapshotDir;

  ZoneSnapshot(this.zone, this.pubspecYamlPath, this.lockPath, this.snapshotDir);
}

/// Copy a zone's pubspec.yaml and pubspec.lock into `[snapshotDir]/<zone>`.
///
/// Missing files (e.g. a zone with no lock yet) are skipped - restore then
/// deletes the live file to match. Returns the snapshot descriptor.
ZoneSnapshot snapshotZone(
  ZoneConfig zone,
  String repoRoot,
  Directory snapshotDir,
) {
  final zoneSnapDir = Directory('${snapshotDir.path}/${zone.label}');
  if (!zoneSnapDir.existsSync()) zoneSnapDir.createSync(recursive: true);
  String? pubspecSnap;
  String? lockSnap;
  final pubspec = File(zone.pubspecPath(repoRoot));
  if (pubspec.existsSync()) {
    pubspecSnap = '${zoneSnapDir.path}/pubspec.yaml';
    pubspec.copySync(pubspecSnap);
  }
  final lock = File(zone.lockPath(repoRoot));
  if (lock.existsSync()) {
    lockSnap = '${zoneSnapDir.path}/pubspec.lock';
    lock.copySync(lockSnap);
  }
  return ZoneSnapshot(zone, pubspecSnap ?? '', lockSnap ?? '', snapshotDir);
}

/// Restore a zone's pubspec.yaml and pubspec.lock from its snapshot, then
/// re-resolve with `pub get`. [runner] is used for the `pub get`.
Future<void> restoreZone(
  ZoneConfig zone,
  String repoRoot,
  ZoneSnapshot snap,
  ProcessRunner runner,
) async {
  final livePubspec = File(zone.pubspecPath(repoRoot));
  final liveLock = File(zone.lockPath(repoRoot));

  if (snap.pubspecYamlPath.isNotEmpty) {
    File(snap.pubspecYamlPath).copySync(livePubspec.path);
  } else if (livePubspec.existsSync()) {
    livePubspec.deleteSync();
  }
  if (snap.lockPath.isNotEmpty) {
    File(snap.lockPath).copySync(liveLock.path);
  } else if (liveLock.existsSync()) {
    liveLock.deleteSync();
  }
  // Re-resolve so .dart_tool/package_config.json matches the restored lock.
  await runner(zone.getCommand(), zone.directory(repoRoot).path);
}

/// True when the zone's live pubspec.yaml or pubspec.lock differs from its
/// snapshot (i.e. `pub upgrade` actually changed something this run).
bool zoneModified(ZoneConfig zone, String repoRoot, ZoneSnapshot snap) {
  if (snap.pubspecYamlPath.isNotEmpty &&
      File(snap.pubspecYamlPath).readAsStringSync() !=
          File(zone.pubspecPath(repoRoot)).readAsStringSync()) {
    return true;
  }
  if (snap.lockPath.isNotEmpty &&
      File(snap.lockPath).readAsStringSync() !=
          File(zone.lockPath(repoRoot)).readAsStringSync()) {
    return true;
  }
  // pubspec.yaml existed before but the live one is now gone, etc.
  if (snap.pubspecYamlPath.isNotEmpty &&
      !File(zone.pubspecPath(repoRoot)).existsSync()) {
    return true;
  }
  if (snap.lockPath.isNotEmpty && !File(zone.lockPath(repoRoot)).existsSync()) {
    return true;
  }
  return false;
}

/// Diff two parsed pubspec.lock documents into a sorted list of changes.
List<LockChange> diffLocks(Map<dynamic, dynamic> oldLock, Map<dynamic, dynamic> newLock) {
  final oldPkgs = _lockPackages(oldLock);
  final newPkgs = _lockPackages(newLock);
  final names = {...oldPkgs.keys, ...newPkgs.keys}..toList().sort();
  return [
    for (final name in names)
      if (oldPkgs.containsKey(name) && newPkgs.containsKey(name))
        LockChange(
          name: name,
          oldVersion: oldPkgs[name],
          newVersion: newPkgs[name],
          added: false,
          removed: false,
        )
      else if (newPkgs.containsKey(name))
        LockChange(
          name: name,
          oldVersion: null,
          newVersion: newPkgs[name],
          added: true,
          removed: false,
        )
      else
        LockChange(
          name: name,
          oldVersion: oldPkgs[name],
          newVersion: null,
          added: false,
          removed: true,
        ),
  ];
}

Map<String, String?> _lockPackages(Map<dynamic, dynamic> lock) {
  final packages = lock['packages'];
  if (packages is! Map) return const {};
  final out = <String, String?>{};
  for (final entry in packages.entries) {
    final name = entry.key.toString();
    final meta = entry.value;
    if (meta is Map) {
      out[name] = meta['version']?.toString();
    }
  }
  return out;
}

/// Outcome of one zone's apply attempt.
class ZoneResult {
  final Zone zone;
  final bool gatePassed;
  final String? failingCommand;
  final String? gateOutput;

  ZoneResult({
    required this.zone,
    required this.gatePassed,
    this.failingCommand,
    this.gateOutput,
  });
}

/// The `apply` command.
class ApplyCommand {
  final String repoRoot;
  final ProcessRunner runner;

  ApplyCommand(this.repoRoot, this.runner);

  Future<int> run() async {
    final snapshotDir = Directory.systemTemp.createTempSync('lgs_deps_apply_');
    final snapshots = <Zone, ZoneSnapshot>{};
    for (final zone in Zone.applyOrder) {
      snapshots[zone] = snapshotZone(ZoneConfig.all[zone]!, repoRoot, snapshotDir);
    }

    var sharedCoreModified = false;
    final applied = <Zone>[];

    for (final zone in Zone.applyOrder) {
      final config = ZoneConfig.all[zone]!;
      final dir = config.directory(repoRoot).path;

      stdout.writeln('=> ${config.label}: upgrading within constraints...');
      final up = await runner(config.upgradeCommand(), dir);
      if (!up.success) {
        stdout.writeln('   upgrade reported: ${up.combinedOutput.trim()}');
      }

      stdout.writeln('=> ${config.label}: running gate...');
      final gateResult = await _runGate(config, dir);
      if (!gateResult.gatePassed) {
        await _handleFailure(
          zone: zone,
          config: config,
          gateResult: gateResult,
          sharedCoreModified: sharedCoreModified,
          applied: applied,
          snapshots: snapshots,
          snapshotDir: snapshotDir,
        );
        return 1;
      }

      applied.add(zone);
      if (zone == Zone.sharedCore &&
          zoneModified(config, repoRoot, snapshots[zone]!)) {
        sharedCoreModified = true;
      }
      stdout.writeln('   ${config.label}: gate passed.');
    }

    // All zones passed: stage diffs + print change summary.
    stdout.writeln();
    stdout.writeln('All zone gates passed. Staging pubspec/lock diffs...');
    for (final zone in Zone.applyOrder) {
      final config = ZoneConfig.all[zone]!;
      await _stageZone(config);
    }
    stdout.writeln();
    stdout.writeln('Per-package change summary:');
    for (final zone in Zone.applyOrder) {
      final config = ZoneConfig.all[zone]!;
      final changes = _zoneChanges(config, repoRoot, snapshots[zone]!);
      stdout.writeln('  ${config.label}:');
      if (changes.isEmpty) {
        stdout.writeln('    (no version changes)');
      } else {
        for (final c in changes) {
          stdout.writeln('    $c');
        }
      }
    }
    stdout.writeln();
    stdout.writeln('Staged. Review with `git diff --cached`; commit when ready.');
    if (snapshotDir.existsSync()) snapshotDir.deleteSync(recursive: true);
    return 0;
  }

  Future<ZoneResult> _runGate(ZoneConfig config, String dir) async {
    for (final cmd in config.gate) {
      final result = await runner(cmd, dir);
      if (!result.success) {
        return ZoneResult(
          zone: config.zone,
          gatePassed: false,
          failingCommand: cmd.join(' '),
          gateOutput: result.combinedOutput,
        );
      }
    }
    return ZoneResult(zone: config.zone, gatePassed: true);
  }

  Future<void> _handleFailure({
    required Zone zone,
    required ZoneConfig config,
    required ZoneResult gateResult,
    required bool sharedCoreModified,
    required List<Zone> applied,
    required Map<Zone, ZoneSnapshot> snapshots,
    required Directory snapshotDir,
  }) async {
    final scope = decideRollbackScope(sharedCoreModified: sharedCoreModified);
    final toRestore = <Zone>{};
    if (scope == RollbackScope.allApplied) {
      toRestore.add(Zone.sharedCore);
      toRestore.addAll(applied);
    }
    toRestore.add(zone); // failing zone always restores

    stdout.writeln();
    stdout.writeln('GATE FAILED in zone ${config.label}:');
    stdout.writeln('  command: ${gateResult.failingCommand}');
    stdout.writeln('  --- gate output ---');
    stdout.writeln(gateResult.gateOutput?.trim() ?? '(no output)');
    stdout.writeln('  --- end gate output ---');

    stdout.writeln('Rolling back (${scope == RollbackScope.allApplied ? "all-or-nothing" : "failing zone only"}): '
        '${toRestore.map((z) => ZoneConfig.all[z]!.label).join(", ")}');
    for (final z in toRestore) {
      await restoreZone(ZoneConfig.all[z]!, repoRoot, snapshots[z]!, runner);
    }

    final blocker = classifyGateError(gateResult.gateOutput ?? '');
    stdout.writeln('Native-coupling: ${runbookPointer(blocker)}');

    if (snapshotDir.existsSync()) snapshotDir.deleteSync(recursive: true);
  }

  List<LockChange> _zoneChanges(
    ZoneConfig config,
    String repoRoot,
    ZoneSnapshot snap,
  ) {
    final oldLock = snap.lockPath.isNotEmpty
        ? parsePubspec(File(snap.lockPath).readAsStringSync())
        : <dynamic, dynamic>{};
    final liveLockFile = File(config.lockPath(repoRoot));
    final newLock = liveLockFile.existsSync()
        ? parsePubspec(liveLockFile.readAsStringSync())
        : <dynamic, dynamic>{};
    return diffLocks(oldLock, newLock).where((c) => c.isBump || c.added || c.removed).toList();
  }

  Future<void> _stageZone(ZoneConfig config) async {
    // Stage pubspec.yaml (always tracked) and pubspec.lock when not gitignored.
    await _gitAdd(repoRoot, config.pubspecPath(repoRoot));
    await _gitAdd(repoRoot, config.lockPath(repoRoot));
  }

  Future<void> _gitAdd(String repoRoot, String path) async {
    final file = File(path);
    if (!file.existsSync()) return;
    final ignored = await _isGitIgnored(repoRoot, path);
    if (ignored) return;
    final result = await Process.run(
      'git',
      ['add', path],
      workingDirectory: repoRoot,
    );
    if (result.exitCode != 0) {
      stderr.writeln('  git add failed for $path: ${result.stderr}'.trim());
    }
  }

  Future<bool> _isGitIgnored(String repoRoot, String path) async {
    final result = await Process.run(
      'git',
      ['check-ignore', path],
      workingDirectory: repoRoot,
    );
    return result.exitCode == 0;
  }
}