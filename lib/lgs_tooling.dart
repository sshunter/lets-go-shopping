/// Public API for the lets-go-shopping dev tooling package.
///
/// The CLI entrypoint is `tool/deps.dart`; it imports this barrel. Library
/// consumers (tests) import the specific `lib/src/` files they need.
library;

export 'src/apply.dart';
export 'src/gate_error.dart';
export 'src/outdated.dart';
export 'src/plugin_detect.dart';
export 'src/process_runner.dart';
export 'src/report.dart';
export 'src/rollback.dart';
export 'src/zone.dart';