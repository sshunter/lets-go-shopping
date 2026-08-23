# Dependency Management

How to keep the pub dependencies of the `lets-go-shopping` monorepo up to date
without relying on LLM judgement for routine work. This is a runbook of shell
commands for the routine report -> upgrade -> verify loop. Native toolchain
changes stay manual and are covered by the [native-bump runbook](#native-bump-runbook)
below.

The monorepo has three pub packages, each with its own `pubspec.yaml` and
verification gate:

| Package       | Path           | Type     | Gate                                            |
| ------------- | -------------- | -------- | ----------------------------------------------- |
| `shared_core` | `shared_core/` | Pure Dart| `dart test`                                     |
| `android_app` | `android_app/` | Flutter  | `flutter test` then `flutter build apk --debug` |
| `ios_app`     | `ios_app/`     | Flutter  | `flutter test`                                  |

`shared_core` is a `path:` dependency of both apps, so it must be upgraded
first. `ios_app` has no build gate on the Linux dev machine: iOS builds are
unavailable here, so **never run `flutter build ios` from this machine**. iOS
build validation happens on a Mac.

See also: [Dev Environment Setup Checklist](setup-todo.md).

---

## Workflow: report -> review -> apply -> verify

### 1. Report (read-only)

See what's outdated in each package:

```
(cd shared_core && dart pub outdated)
(cd android_app && flutter pub outdated)
(cd ios_app && flutter pub outdated)
```

Each prints every outdated package with its version buckets (see
[Reading `pub outdated`](#reading-pub-outdated)). This writes nothing.

### 2. Review

Scan the lists. The deps that can force a native-toolchain change on upgrade
are the **Flutter plugins** - in this repo, `home_widget` and `sqflite`
(ship native Android/iOS code). Pure-Dart deps (`bloc`, `uuid`, `path`,
`test`, `mocktail`, etc.) will not. If a plugin has a new `Upgradable` version,
expect the gate to possibly fail and route you to the
[native-bump runbook](#native-bump-runbook).

<a id="apply"></a>

### 3. Apply (within-constraint upgrades + each package's gate)

Run these in order. `pub upgrade` (no flags) stays within the constraints in
each `pubspec.yaml` - it never crosses a major version. If any gate fails,
**stop** and see [Rollback](#rollback) before continuing.

```
# shared_core first - it's a path: dep of both apps
cd shared_core && dart pub upgrade && dart test

# android_app - includes the native-integrity build (Kotlin/Gradle/Glance)
cd android_app && flutter pub upgrade && flutter test && flutter build apk --debug

# ios_app - no build gate on Linux
cd ios_app && flutter pub upgrade && flutter test
```

### 4. Verify

The gates already ran above. Review the resulting diff:

```
git diff
```

### 5. Commit when satisfied.

---

## Reading `pub outdated`

Each row has four version buckets (see
<https://dart.dev/tools/pub/cmd/pub-outdated>):

| Column       | Meaning                                                                        |
| ------------ | ------------------------------------------------------------------------------ |
| `Current`    | The version resolved in the current `pubspec.lock`.                            |
| `Upgradable` | The newest version reachable **without changing pubspec constraints**. This is what step 3 lands on. |
| `Resolvable` | The newest version reachable by relaxing constraints (what `--major-versions` would do). Out of scope here. |
| `Latest`     | The absolute newest version published to pub.dev.                             |

If a row is marked discontinued, retracted, or has a security advisory, treat
it as a manual review item - do not auto-apply it; resolve the advisory or
find a replacement first.

---

## Rollback

`pub upgrade` rewrites `pubspec.lock` (and can shift transitive resolutions
across all three packages, because `shared_core` is a `path:` dep of both
apps). If any gate fails, restore all three packages to their pre-upgrade
state and re-resolve, then investigate the failing gate:

```
git checkout -- shared_core android_app ios_app
(cd shared_core && dart pub get)
(cd android_app && flutter pub get)
(cd ios_app && flutter pub get)
```

This is deliberately all-or-nothing: because the apps resolve `shared_core`
via `path:`, leaving `shared_core` bumped while an app's gate fails would
leave the apps broken against a version they were never verified against.
Rolling back all three and re-running the apply steps is cheaper than
reasoning about partial rollbacks. If you want to keep a passing package's
upgrade and only investigate the failing one, do it manually: `git checkout`
only the failing package, re-resolve it, and re-run its gate - but only when
you are sure the failure is independent of `shared_core`.

Build artifacts under `build/` and `.dart_tool/` are gitignored and are not
affected by `git checkout`.

---


## native-bump runbook

When a `pub upgrade` forces a native toolchain change (typically a plugin
pulling a newer Kotlin/AGP/compileSdk or an iOS deployment target bump), the
package's gate fails. Roll back per [Rollback](#rollback), read the gate
error, and follow the matching subsection below. These are manual - you edit
native files, then re-run the apply steps from the workflow above.


### native-bump-1: Flutter SDK bump

`flutter upgrade` updates the Flutter SDK, which in turn drives the Android
`compileSdk`/`minSdk`/`targetSdk` defaults and the iOS Swift Package Manager
auto-resolution. Do this first when a gate fails with a "requires Flutter SDK
version" / "the current Flutter SDK is out of date" message.

Authoritative doc: <https://docs.flutter.dev/install/upgrade>.

Steps:

1. `flutter upgrade` (updates Flutter + Dart SDK).
2. Re-run the [apply steps](#apply).
3. If the Android gate still fails, continue to
   [native-bump-2](#native-bump-2-android-native-pins-legacy-path).
4. If the iOS gate fails (on a Mac), continue to
   [native-bump-3](#native-bump-3-ios-deployment-target).


### native-bump-2: Android native pins (legacy path)

Manual pinning of Kotlin, the Android Gradle Plugin (AGP), the Gradle wrapper,
and androidx/Compose versions. This repo already carries a manual
`androidx.glance` pin scar from a past native-version conflict, so this class
of problem is known to bite.

Authoritative docs:

- Flutter Android build/deployment: <https://docs.flutter.dev/deployment/android>.
- Migrate to built-in Kotlin (AGP 9): <https://developer.android.com/build/migrate-to-built-in-kotlin>.
- Kotlin/Gradle version compatibility: <https://kotlinlang.org/docs/gradle.html>.

Steps (edit under `android_app/android/`):

1. **Kotlin / AGP** - set in `android/settings.gradle.kts` (or
   `build.gradle.kts` on the legacy Gradle layout). Keep Kotlin and AGP on a
   compatible pair per the Kotlin/Gradle matrix linked above.
2. **Gradle wrapper** - `android/gradle/wrapper/gradle-wrapper.properties`
   (`distributionUrl`). Bump only when AGP requires a newer Gradle.
3. **androidx / Compose / glance pins** - in the app `build.gradle.kts` or a
   version catalog. Re-resolve the conflict that forced the pin.
4. Verify: `cd android_app && flutter build apk --debug`.
5. Re-run the [apply steps](#apply).

When AGP reaches 9 and Flutter reaches 3.47+, prefer
[native-bump-4](#native-bump-4-built-in-kotlin-migration) over hand-managing
Kotlin versions.


### native-bump-3: iOS deployment target

Bump the iOS minimum deployment target when a plugin requires a newer
MinimumOSVersion, then let SPM re-resolve. This subsection is acted on from
**macOS**; on the Linux dev machine `ios_app` has no build gate and you cannot
run `flutter build ios` here.

Authoritative docs:

- Flutter iOS deployment: <https://docs.flutter.dev/deployment/ios>.
- Swift Package Manager for app developers: <https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers>.

Steps (on a Mac):

1. Set the minimum in Xcode: project -> *Signing & Capabilities* -> *Minimum
   Deployments* (or `IPHONEOS_DEPLOYMENT_TARGET` in `ios/Runner.xcodeproj`).
2. Re-resolve SPM without CocoaPods:

   ```
   flutter pub get
   flutter build ios --config-only
   ```

   This repo uses SPM (no CocoaPods). If a plugin lacks a `Package.swift`, it
   is not SPM-compatible; track that as a plugin issue, not a config fix.
3. Verify on device/simulator, then re-run the
   [apply steps](#apply)
   (the `ios_app` gate is `flutter test` only on Linux).


### native-bump-4: built-in Kotlin migration

AGP 9 ships Kotlin built in. Once you are on AGP 9+ and Flutter 3.47+, flip
the built-in Kotlin flag and stop hand-managing the Kotlin Gradle plugin
version. This is a future step documented here so it can be acted on later
via fact-finding, not re-triaged.

Authoritative doc:
<https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers>.

Preconditions: AGP 9+ and Flutter 3.47+.

Steps:

1. In `android_app/android/settings.gradle.kts` (or the app
   `build.gradle.kts`), flip `android.builtInKotlin` from `false` to `true`
   (and remove the explicit Kotlin Gradle plugin version).
2. Verify: `cd android_app && flutter build apk --debug`.
3. Fallback: if the build fails, set `android.builtInKotlin = false` again,
   confirm the build is green, and leave migration for a later session - do
   not leave the tree in a half-migrated state.
4. Re-run the [apply steps](#apply).

---

## Out of scope / future

- `--major-versions` upgrades (constraint-editing). Postpone until you have a
  reason to cross a major version.
- Native dependency automation. Only the manual runbook above touches native
  files.
- CI-driven or scheduled maintenance; adding an Android CI workflow.
- The built-in Kotlin migration itself - documented as a future step only.
- A wrapper script for the routine loop. Try the manual commands first; once
  the consequences of each step are clear, a small script can capture the
  workflow without becoming a program to maintain.
- Changing `sdk: ^3.12.0` or any existing version pin.