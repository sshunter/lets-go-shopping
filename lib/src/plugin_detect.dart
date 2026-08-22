/// Native-coupling-risk detection.
///
/// A direct dependency "ships platform code" when its resolved pubspec
/// declares a non-empty `flutter.plugin.platforms` map - i.e. it is a Flutter
/// plugin that drops native Android/iOS/etc. code into the build. Such deps
/// are the ones that can force a native-toolchain change on `pub upgrade` and
/// block the gate build, so the report flags them and `apply`'s native-blocker
/// handling points back to the runbook when they are involved.
///
/// The resolved pubspec is located via the zone's `.dart_tool/package_config.json`
/// (each package's `rootUri` points at its checkout in the pub cache or a
/// `path:` source). The tool never consults git state for this.
library;

import 'dart:convert';
import 'dart:io';
import 'package:yaml/yaml.dart';

/// Result of probing one direct dependency for native coupling.
class PluginRisk {
  final String package;

  /// True when `flutter.plugin.platforms` is present and non-empty.
  final bool nativeCouplingRisk;

  /// The platform keys found (android, ios, ...), for display.
  final List<String> platforms;

  PluginRisk({
    required this.package,
    required this.nativeCouplingRisk,
    required this.platforms,
  });
}

/// Read `flutter.plugin.platforms` from a parsed pubspec map.
///
/// Returns the platform keys (e.g. `['android', 'ios']`) or an empty list when
/// the pubspec has no plugin section or an empty platforms map. Pure function
/// over a parsed pubspec so it is trivially unit-testable.
List<String> pluginPlatformsFromPubspec(Map<dynamic, dynamic> pubspec) {
  final flutter = pubspec['flutter'];
  if (flutter is! Map) return const [];
  final plugin = flutter['plugin'];
  if (plugin is! Map) return const [];
  final platforms = plugin['platforms'];
  if (platforms is! Map) return const [];
  return platforms.keys.cast<String>().toList()..sort();
}

/// Parse a pubspec.yaml document into a plain map.
Map<dynamic, dynamic> parsePubspec(String yaml) {
  final doc = loadYaml(yaml);
  if (doc is Map) return Map<dynamic, dynamic>.from(doc);
  return {};
}

/// Load the zone's resolved package_config.json and return a map of package
/// name to its resolved root directory URI (as a string).
Map<String, String> loadPackageRoots(String packageConfigPath) {
  final file = File(packageConfigPath);
  if (!file.existsSync()) return const {};
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) return const {};
  final configPackages = decoded['packages'];
  if (configPackages is! List) return const {};
  final result = <String, String>{};
  for (final entry in configPackages) {
    if (entry is! Map<String, dynamic>) continue;
    final name = entry['name'];
    final root = entry['rootUri'];
    if (name is String && root is String) {
      result[name] = root;
    }
  }
  return result;
}

/// Detect the native-coupling-risk flag for [packageName] by reading its
/// resolved pubspec from the pub cache (located via [packageConfigPath]).
///
/// Returns null when the package cannot be located or its pubspec is absent,
/// which the caller renders as an unknown/`?` row.
PluginRisk? detectNativeCouplingRisk(String packageConfigPath, String packageName) {
  final roots = loadPackageRoots(packageConfigPath);
  final rootUri = roots[packageName];
  if (rootUri == null) return null;
  final dir = _uriToPath(rootUri);
  final pubspecFile = File('$dir/pubspec.yaml');
  if (!pubspecFile.existsSync()) return null;
  final platforms = pluginPlatformsFromPubspec(parsePubspec(
    pubspecFile.readAsStringSync(),
  ));
  return PluginRisk(
    package: packageName,
    nativeCouplingRisk: platforms.isNotEmpty,
    platforms: platforms,
  );
}

/// Resolve a `package_config.json` rootUri (a `file://` URI or a bare path) to
/// a filesystem path.
String _uriToPath(String rootUri) {
  if (rootUri.startsWith('file://')) {
    return Uri.parse(rootUri).toFilePath();
  }
  return rootUri;
}