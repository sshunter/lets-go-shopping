// Dependency-maintenance CLI for the lets-go-shopping monorepo.
//
// Usage:
//   dart run tool/deps.dart report   # read-only outdated view + risk flags
//   dart run tool/deps.dart apply    # within-constraint upgrades + per-zone gates
//   dart run tool/deps.dart help     # usage
//
// See docs/dependency-management.md for the full runbook.
import 'dart:io';

import 'package:args/args.dart';
import 'package:lgs_tooling/lgs_tooling.dart';

const _commands = ['report', 'apply'];

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print this usage.')
    ..addCommand('report', ArgParser())
    ..addCommand('apply', ArgParser());

  if (arguments.isEmpty || arguments.first == 'help') {
    stdout.writeln(_usage(parser));
    exit(0);
  }

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } on ArgParserException catch (e) {
    stderr.writeln('deps: $e');
    stderr.writeln(_usage(parser));
    exit(64);
  }

  if (results['help'] as bool? ?? false) {
    stdout.writeln(_usage(parser));
    exit(0);
  }

  final command = results.command?.name;
  if (command == null) {
    stderr.writeln('deps: no subcommand given.');
    stderr.writeln(_usage(parser));
    exit(64);
  }
  if (!_commands.contains(command)) {
    stderr.writeln('deps: unknown subcommand "$command".');
    stderr.writeln(_usage(parser));
    exit(64);
  }

  final repoRoot = Directory.current.path;
  switch (command) {
    case 'report':
      final code = await ReportCommand(repoRoot, systemProcessRunner).run();
      exit(code);
    case 'apply':
      final code = await ApplyCommand(repoRoot, systemProcessRunner).run();
      exit(code);
  }
}

String _usage(ArgParser parser) {
  return [
    'lgs deps - dependency maintenance for lets-go-shopping.',
    '',
    'Usage: dart run tool/deps.dart <command>',
    '',
    'Commands:',
    '  report   Read-only: list outdated deps per zone with native-coupling-risk flags.',
    '  apply    Upgrade within constraints, run each zone gate, stage pubspec/lock diffs.',
    '',
    'Run "dart run tool/deps.dart help" to see this message.',
    '',
    parser.usage,
  ].join('\n');
}