/// Subprocess runner abstraction.
///
/// The report and apply commands shell out to `dart` / `flutter`. Wrapping the
/// shell behind an interface lets unit tests drive the orchestration with a
/// fake runner instead of spawning real toolchains.
library;

import 'dart:io';

/// One captured subprocess result.
class CommandResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  CommandResult(this.exitCode, this.stdout, this.stderr);

  bool get success => exitCode == 0;

  /// Combined stdout + stderr, as gate-error classification expects.
  String get combinedOutput => '$stdout\n$stderr';
}

/// Runs a command list in [workingDirectory], inheriting the parent
/// environment, capturing stdout/stderr.
typedef ProcessRunner = Future<CommandResult> Function(
  List<String> command,
  String workingDirectory,
);

/// Default runner backed by [Process.run].
Future<CommandResult> systemProcessRunner(
  List<String> command,
  String workingDirectory,
) async {
  final executable = command.first;
  final args = command.skip(1).toList();
  final result = await Process.run(
    executable,
    args,
    workingDirectory: workingDirectory,
    runInShell: false,
  );
  final stdout = result.stdout is String ? result.stdout as String : '${result.stdout}';
  final stderr = result.stderr is String ? result.stderr as String : '${result.stderr}';
  return CommandResult(result.exitCode, stdout, stderr);
}