/// `report` subcommand: read-only outdated-deps view with native-coupling risk.
///
/// For each zone, run `<dart|flutter> pub outdated --json`, parse it, flag every
/// direct dependency whose resolved pubspec declares a non-empty
/// `flutter.plugin.platforms`, and print one table per zone plus a one-line
/// summary. `report` writes nothing - no `pub get`, no upgrades.
library;

import 'dart:io';

import 'outdated.dart';
import 'plugin_detect.dart';
import 'process_runner.dart';
import 'zone.dart';

/// One rendered row of a zone's report table.
class ReportRow {
  final String name;
  final String kind;
  final String current;
  final String upgradable;
  final String resolvable;
  final String latest;

  /// "yes" / "no" for direct deps; "-" for transitive (not assessed).
  final String risk;

  /// Platforms behind a "yes", e.g. "android,ios"; empty otherwise.
  final String platforms;

  ReportRow({
    required this.name,
    required this.kind,
    required this.current,
    required this.upgradable,
    required this.resolvable,
    required this.latest,
    required this.risk,
    required this.platforms,
  });
}

/// Build the report rows for [zone] from already-parsed [outdated] packages.
///
/// Reads the zone's `.dart_tool/package_config.json` and each direct dep's
/// resolved pubspec from the pub cache to set the risk flag. Transitive deps
/// are shown but not assessed (`risk = '-'`).
List<ReportRow> buildReportRows(
  ZoneConfig zone,
  String repoRoot,
  List<OutdatedPackage> outdated,
) {
  final packageConfigPath = zone.packageConfigPath(repoRoot);
  return [
    for (final p in outdated)
      _rowFor(p, () => detectNativeCouplingRisk(packageConfigPath, p.name)),
  ];
}

/// Build one row. [probe] is called at most once per row (and only for direct
/// deps) so the report reads each dep's pubspec from the cache once, not twice.
ReportRow _rowFor(OutdatedPackage p, PluginRisk? Function() probe) {
  if (!p.isDirect) {
    return ReportRow(
      name: p.name,
      kind: p.kind,
      current: p.current ?? '-',
      upgradable: p.upgradable ?? '-',
      resolvable: p.resolvable ?? '-',
      latest: p.latest ?? '-',
      risk: '-',
      platforms: '',
    );
  }
  final risk = probe();
  final flagged = risk != null && risk.nativeCouplingRisk;
  return ReportRow(
    name: p.name,
    kind: p.kind,
    current: p.current ?? '-',
    upgradable: p.upgradable ?? '-',
    resolvable: p.resolvable ?? '-',
    latest: p.latest ?? '-',
    risk: risk == null ? '?' : (flagged ? 'yes' : 'no'),
    platforms: flagged ? risk.platforms.join(',') : '',
  );
}

/// Render a zone's rows as a fixed-width text table with a header.
String formatReportTable(String zoneLabel, List<ReportRow> rows) {
  final header = [
    'Package',
    'Kind',
    'Current',
    'Upgradable',
    'Resolvable',
    'Latest',
    'Risk',
    'Platforms',
  ];

  String cell(ReportRow r, int i) => [
    r.name,
    r.kind,
    r.current,
    r.upgradable,
    r.resolvable,
    r.latest,
    r.risk,
    r.platforms,
  ][i];

  final widths = List.generate(header.length, (i) {
    var w = header[i].length;
    for (final row in rows) {
      final len = cell(row, i).length;
      if (len > w) w = len;
    }
    return w;
  });

  String pad(String s, int w) => s.padRight(w);

  String line(List<String> cells) => [
    for (var i = 0; i < cells.length; i++) pad(cells[i], widths[i]),
  ].join('  ');

  final out = StringBuffer('## $zoneLabel\n');
  out.writeln(line(header));
  out.writeln(line(['-' * widths[0], '', '', '', '', '', '', '']).trimRight());
  if (rows.isEmpty) {
    out.writeln('  (no outdated dependencies)');
  } else {
    for (final r in rows) {
      out.writeln(line([
        r.name,
        r.kind,
        r.current,
        r.upgradable,
        r.resolvable,
        r.latest,
        r.risk,
        r.platforms,
      ]));
    }
  }
  return out.toString();
}

/// One-line summary across all zones.
String formatSummary(Map<Zone, List<ReportRow>> rowsByZone) {
  var total = 0;
  var direct = 0;
  var risk = 0;
  for (final rows in rowsByZone.values) {
    for (final r in rows) {
      total++;
      if (r.kind == 'direct' || r.kind == 'dev') direct++;
      if (r.risk == 'yes') risk++;
    }
  }
  return 'Summary: $total outdated ($direct direct), $risk native-coupling-risk.';
}

/// The `report` command: read-only, prints one table per zone + a summary.
class ReportCommand {
  final String repoRoot;
  final ProcessRunner runner;

  ReportCommand(this.repoRoot, this.runner);

  Future<int> run() async {
    final rowsByZone = <Zone, List<ReportRow>>{};
    for (final zone in Zone.applyOrder) {
      final config = ZoneConfig.all[zone]!;
      final dir = config.directory(repoRoot);
      if (!dir.existsSync()) {
        stderr.writeln('Zone ${config.label}: directory not found at ${dir.path}');
        continue;
      }
      final result = await runner(config.outdatedCommand(), dir.path);
      if (!result.success) {
        stderr.writeln('Zone ${config.label}: `pub outdated` failed:');
        stderr.writeln(result.combinedOutput.trim());
        stderr.writeln('(run `${config.getCommand().join(' ')}` in ${config.label} to resolve)');
        rowsByZone[zone] = const [];
        continue;
      }
      final outdated = parseOutdatedJson(result.stdout);
      rowsByZone[zone] = buildReportRows(config, repoRoot, outdated);
    }
    final out = StringBuffer();
    for (final zone in Zone.applyOrder) {
      final config = ZoneConfig.all[zone]!;
      out.write(formatReportTable(config.label, rowsByZone[zone] ?? const []));
      out.writeln();
    }
    out.writeln(formatSummary(rowsByZone));
    stdout.write(out.toString());
    return 0;
  }
}