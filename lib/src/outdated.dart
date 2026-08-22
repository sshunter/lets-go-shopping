/// Parsing of `pub outdated --json` output.
///
/// `pub outdated` reports every package that has a newer version reachable
/// somewhere (upgradable within constraints, resolvable after relaxing
/// constraints, or the absolute latest on pub.dev). We keep the four version
/// buckets plus the safety flags so the report can surface advisories and
/// retractions alongside the version table.
library;

import 'dart:convert';

/// One row of `pub outdated` output.
class OutdatedPackage {
  final String name;

  /// `direct` (declared in this package's pubspec, main or dev) or `transitive`.
  final String kind;

  /// Currently resolved version, or null if not yet resolved.
  final String? current;

  /// Latest version reachable without changing pubspec constraints.
  final String? upgradable;

  /// Latest version reachable by relaxing constraints (but keeping the same
  /// major line where possible) - what `--major-versions` would land on.
  final String? resolvable;

  /// Absolute latest version on pub.dev.
  final String? latest;

  final bool isDiscontinued;
  final bool isCurrentRetracted;
  final bool isCurrentAffectedByAdvisory;

  OutdatedPackage({
    required this.name,
    required this.kind,
    required this.current,
    required this.upgradable,
    required this.resolvable,
    required this.latest,
    required this.isDiscontinued,
    required this.isCurrentRetracted,
    required this.isCurrentAffectedByAdvisory,
  });

  /// True for directly-declared dependencies: both main (`direct`) and
  /// `dev` dependencies, as opposed to `transitive`.
  bool get isDirect => kind == 'direct' || kind == 'dev';

  @override
  String toString() =>
      'OutdatedPackage($name, $kind, current=$current, upgradable=$upgradable, '
      'resolvable=$resolvable, latest=$latest)';
}

/// Parse the JSON document printed by `<dart|flutter> pub outdated --json`.
///
/// Tolerates a leading non-JSON banner line (pub sometimes prints resolving
/// notices before the JSON blob) by scanning for the first `{`.
List<OutdatedPackage> parseOutdatedJson(String output) {
  final blob = _extractJsonObject(output);
  if (blob.isEmpty) return const [];
  final dynamic decoded = jsonDecode(blob);
  if (decoded is! Map<String, dynamic>) return const [];
  final packages = decoded['packages'];
  if (packages is! List) return const [];
  final result = <OutdatedPackage>[];
  for (final entry in packages) {
    if (entry is! Map<String, dynamic>) continue;
    result.add(
      OutdatedPackage(
        name: entry['package'] as String,
        kind: entry['kind'] as String? ?? 'transitive',
        current: _versionOf(entry['current']),
        upgradable: _versionOf(entry['upgradable']),
        resolvable: _versionOf(entry['resolvable']),
        latest: _versionOf(entry['latest']),
        isDiscontinued: (entry['isDiscontinued'] as bool?) ?? false,
        isCurrentRetracted: (entry['isCurrentRetracted'] as bool?) ?? false,
        isCurrentAffectedByAdvisory:
            (entry['isCurrentAffectedByAdvisory'] as bool?) ?? false,
      ),
    );
  }
  return result;
}

String? _versionOf(dynamic bucket) {
  if (bucket is Map<String, dynamic>) {
    final v = bucket['version'];
    return v is String ? v : null;
  }
  return null;
}

/// Return the substring starting at the first top-level `{`, or '' if none.
String _extractJsonObject(String output) {
  final start = output.indexOf('{');
  if (start < 0) return '';
  return output.substring(start);
}