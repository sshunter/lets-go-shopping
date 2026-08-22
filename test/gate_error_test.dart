import 'package:test/test.dart';
import 'package:lgs_tooling/lgs_tooling.dart';

void main() {
  group('classifyGateError', () {
    test('routes built-in Kotlin messages to the built-in Kotlin section', () {
      final blocker = classifyGateError(
        'FAILURE: Build failed. The built-in Kotlin version is outdated.',
      );
      expect(blocker, NativeBlocker.builtInKotlin);
    });

    test('routes compileSdk / AGP / Kotlin version errors to android native', () {
      expect(
        classifyGateError(
          "e: ... requires compileSdk 35 but the current is 33. "
          "Please update android.compileSdk.",
        ),
        NativeBlocker.androidNative,
      );
      expect(
        classifyGateError('The Android Gradle plugin (AGP) version 8.1.0 is too old.'),
        NativeBlocker.androidNative,
      );
      expect(
        classifyGateError("Kotlin version 1.9.0 is incompatible with androidx.compose"),
        NativeBlocker.androidNative,
      );
      expect(
        classifyGateError('Glance dependency requires a higher minSdk.'),
        NativeBlocker.androidNative,
      );
    });

    test('routes iOS deployment target messages to ios deployment', () {
      expect(
        classifyGateError('IPHONEOS_DEPLOYMENT_TARGET is set to 11.0 but Xcode requires 12.0.'),
        NativeBlocker.iosDeployment,
      );
      expect(
        classifyGateError('the MinimumOSVersion in your Podfile must be at least 13.0'),
        NativeBlocker.iosDeployment,
      );
    });

    test('routes Flutter SDK version mismatches to flutterSdk', () {
      expect(
        classifyGateError(
          'This package requires Flutter SDK version >=3.32.0 but the current Flutter '
          'SDK is 3.27.0.',
        ),
        NativeBlocker.flutterSdk,
      );
      expect(
        classifyGateError('the current Flutter SDK is out of date'),
        NativeBlocker.flutterSdk,
      );
    });

    test('falls back to unrecognized for generic failures', () {
      expect(
        classifyGateError('Error: test failed: expected X got Y.'),
        NativeBlocker.unrecognized,
      );
      expect(
        classifyGateError('Compilation failed: undefined name \'foo\'.'),
        NativeBlocker.unrecognized,
      );
    });

    test('first matcher wins (built-in Kotlin checked before android native)', () {
      // A message mentioning both builtInKotlin and AGP routes to builtInKotlin.
      final blocker = classifyGateError(
        'builtInKotlin flag conflicts with AGP version',
      );
      expect(blocker, NativeBlocker.builtInKotlin);
    });
  });

  group('runbookPointer', () {
    test('named subsections reference their anchor', () {
      expect(
        runbookPointer(NativeBlocker.androidNative),
        contains('#native-bump-2-android-native'),
      );
      expect(
        runbookPointer(NativeBlocker.iosDeployment),
        contains('#native-bump-3-ios-deployment'),
      );
      expect(
        runbookPointer(NativeBlocker.builtInKotlin),
        contains('#native-bump-4-built-in-kotlin'),
      );
      expect(
        runbookPointer(NativeBlocker.flutterSdk),
        contains('#native-bump-1-flutter-sdk'),
      );
    });

    test('unrecognized gives the generic runbook pointer', () {
      final pointer = runbookPointer(NativeBlocker.unrecognized);
      expect(pointer, contains('docs/dependency-management.md#native-bump'));
      expect(pointer, isNot(contains('#native-bump-')));
    });
  });
}