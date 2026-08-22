/// Native-blocker classification for gate failures.
///
/// When a zone gate fails, `apply` prints the gate error verbatim. If the error
/// matches a recognised native-toolchain pattern it also points at the
/// relevant subsection of the native-bump runbook (`docs/dependency-management.md`);
/// otherwise it prints a generic "see the native-bump runbook" pointer. The
/// tool never edits native files - it only routes the human to the runbook.
///
/// Patterns are intentionally broad (substring/regex) and ordered: the first
/// matching [NativeBlocker] wins. Unrecognised errors map to
/// [NativeBlocker.unrecognized].
library;

/// A native-bump runbook subsection, or the catch-all for unknown errors.
enum NativeBlocker {
  /// Flutter SDK bump (`flutter upgrade` drives compileSdk/minSdk/targetSdk +
  /// iOS SPM auto-resolution).
  flutterSdk('native-bump-1-flutter-sdk'),

  /// Android native pins: Kotlin/AGP in settings.gradle.kts, Gradle wrapper,
  /// androidx.glance/Compose pins.
  androidNative('native-bump-2-android-native'),

  /// iOS deployment target via Xcode Minimum Deployments +
  /// `flutter build ios --config-only` (SPM, no CocoaPods).
  iosDeployment('native-bump-3-ios-deployment'),

  /// Built-in Kotlin migration (flag flip, AGP 9+ / Flutter 3.47+
  /// preconditions, verify with `flutter build apk --debug`).
  builtInKotlin('native-bump-4-built-in-kotlin'),

  /// No recognised pattern - generic runbook pointer.
  unrecognized(null);

  /// The anchor id in `docs/dependency-management.md`, or null for
  /// [unrecognized].
  final String? anchor;
  const NativeBlocker(this.anchor);
}

/// Ordered matchers. First hit wins. Kept as (regex, blocker) pairs so the
/// rule table is easy to read and easy to unit-test.
final _matchers = <(RegExp, NativeBlocker)>[
  (RegExp(r'built[\W_]?in[\W_]?kotlin', caseSensitive: false), NativeBlocker.builtInKotlin),
  (
    RegExp(
      r'IPHONEOS_DEPLOYMENT_TARGET|MinimumOSVersion|deployment[\W_]?target|Xcode.*version|CocoaPods|Swift package manager|SPM',
      caseSensitive: false,
    ),
    NativeBlocker.iosDeployment,
  ),
  (
    RegExp(
      r'compileSdk|minSdk|targetSdk|AGP|gradle[\W_]?version|kotlin[\W_]?version|androidx|Glance|Compose',
      caseSensitive: false,
    ),
    NativeBlocker.androidNative,
  ),
  (
    RegExp(
      r'requires[\W_]?Flutter|Flutter\s+SDK|flutter\s+version|outdated\s+by\s+the\s+SDK|the\s+current\s+Flutter\s+SDK',
      caseSensitive: false,
    ),
    NativeBlocker.flutterSdk,
  ),
];

/// Classify a gate-failure output block.
///
/// [output] is the combined stdout+stderr of the failing gate command. The
/// function scans the whole block (some errors bury the actionable line deep
/// in a Gradle/Xcode transcript).
NativeBlocker classifyGateError(String output) {
  for (final (pattern, blocker) in _matchers) {
    if (pattern.hasMatch(output)) return blocker;
  }
  return NativeBlocker.unrecognized;
}

/// Human-readable pointer line printed after the gate error on a native block.
///
/// References `docs/dependency-management.md`. For [NativeBlocker.unrecognized]
/// the pointer is generic; otherwise it names the matching subsection anchor.
String runbookPointer(NativeBlocker blocker) {
  if (blocker == NativeBlocker.unrecognized) {
    return 'See the native-bump runbook: docs/dependency-management.md#native-bump';
  }
  return 'See the native-bump runbook: docs/dependency-management.md#${blocker.anchor}';
}