/// Zone model for the three-package monorepo.
///
/// A [Zone] is one pub package that owns its own `pubspec.yaml` / `pubspec.lock`
/// and its own verification gate. The dependency-maintenance tool walks the
/// zones in [applyOrder] so that `shared_core` is upgraded before the two apps
/// that consume it via `path:`.
library;

import 'dart:io';

/// The three maintainable packages, in the order `apply` must walk them.
enum Zone {
  sharedCore,
  androidApp,
  iosApp;

  /// Dependency order: shared_core first, then the apps that resolve against it.
  static List<Zone> get applyOrder => const [
    Zone.sharedCore,
    Zone.androidApp,
    Zone.iosApp,
  ];
}

/// Per-zone configuration: where it lives, whether it is a Flutter package, and
/// which commands make up its verification gate.
class ZoneConfig {
  final Zone zone;
  final String dir;
  final bool isFlutter;

  /// Commands run in order as the zone's gate. All must exit 0 for the gate to
  /// pass. `ios_app` omits a build because iOS builds are unavailable on Linux.
  final List<List<String>> gate;

  const ZoneConfig(this.zone, this.dir, this.isFlutter, this.gate);

  static const Map<Zone, ZoneConfig> all = {
    Zone.sharedCore: ZoneConfig(
      Zone.sharedCore,
      'shared_core',
      false,
      [
        ['dart', 'test'],
      ],
    ),
    Zone.androidApp: ZoneConfig(
      Zone.androidApp,
      'android_app',
      true,
      [
        ['flutter', 'test'],
        ['flutter', 'build', 'apk', '--debug'],
      ],
    ),
    Zone.iosApp: ZoneConfig(
      Zone.iosApp,
      'ios_app',
      true,
      [
        ['flutter', 'test'],
      ],
    ),
  };

  /// Absolute directory for this zone under [repoRoot].
  Directory directory(String repoRoot) => Directory('$repoRoot/$dir');

  /// Path to the zone's pubspec.yaml under [repoRoot].
  String pubspecPath(String repoRoot) => '$repoRoot/$dir/pubspec.yaml';

  /// Path to the zone's pubspec.lock under [repoRoot].
  String lockPath(String repoRoot) => '$repoRoot/$dir/pubspec.lock';

  /// Path to the zone's resolved package_config.json under [repoRoot].
  String packageConfigPath(String repoRoot) =>
      '$repoRoot/$dir/.dart_tool/package_config.json';

  /// `dart pub upgrade` (shared_core) vs `flutter pub upgrade` (apps). Never
  /// passes `--major-versions`: `apply` only performs within-constraint bumps.
  List<String> upgradeCommand() =>
      isFlutter ? ['flutter', 'pub', 'upgrade'] : ['dart', 'pub', 'upgrade'];

  /// `dart pub outdated --json` vs `flutter pub outdated --json`.
  List<String> outdatedCommand() => isFlutter
      ? ['flutter', 'pub', 'outdated', '--json']
      : ['dart', 'pub', 'outdated', '--json'];

  /// `dart pub get` vs `flutter pub get` - used to re-resolve after a rollback.
  List<String> getCommand() =>
      isFlutter ? ['flutter', 'pub', 'get'] : ['dart', 'pub', 'get'];

  /// Human-readable label used in report tables and apply logs.
  String get label => switch (zone) {
    Zone.sharedCore => 'shared_core',
    Zone.androidApp => 'android_app',
    Zone.iosApp => 'ios_app',
  };
}