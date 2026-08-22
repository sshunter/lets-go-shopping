# Dependency Management

How to keep the pub dependencies of the `lets-go-shopping` monorepo up to date
without relying on LLM judgement for routine work. The repo ships a CLI,
`dart run tool/deps.dart`, that automates the read-only report and the
within-constraint upgrade + verification loop. Native toolchain changes stay
manual and are covered by the [native-bump runbook](#native-bump-runbook)
below; the tool never edits native files.

The monorepo has three pub packages, each with its own `pubspec.yaml` and
verification gate:

| Zone          | Path           | Type     | Gate                                            |
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

1. **Report** (read-only). From the repo root:

   ```
   dart run tool/deps.dart report
   ```

   Prints one table per zone: every outdated package with its version buckets
   and a `native-coupling-risk` flag, plus a one-line summary. It writes
   nothing (no `pub get`, no upgrades).

2. **Review** the tables. Note any `Risk = yes` row: those deps ship native
   platform code and can force a native-toolchain change on upgrade. If a
   native-coupling-risk dep has a new `Upgradable` version, expect the apply
   gate to possibly fail and route you to the [native-bump runbook](#native-bump-runbook).

3. **Apply** (within-constraint upgrades + per-zone gates). From the repo root:

   ```
   dart run tool/deps.dart apply
   ```

   Walks the zones in dependency order (`shared_core` -> `android_app` ->
   `ios_app`). For each zone it runs `<dart|flutter> pub upgrade` (never
   `--major-versions`), then the zone's gate. On a gate failure it rolls back
   per the [rollback rule](#rollback-behavior), prints the failing zone and
   the gate error verbatim, and points at the relevant native-bump subsection
   (or a generic pointer for unrecognized errors). On full success it stages
   the `pubspec`/`lock` diffs and prints a per-package change summary.

4. **Verify**. The gates already ran inside `apply`; review the staged diff:

   ```
   git diff --cached
   ```

5. **Commit** when satisfied. `apply` does not commit, open a PR, or add CI;
   that is the maintainer's call.

---

## Reading `pub outdated`

Each row has four version buckets (see
<https://dart.dev/tools/pub/cmd/pub-outdated>):

| Column      | Meaning                                                                     |
| ----------- | -------------------------------------------------------------------------- |
| `Current`   | The version resolved in the current `pubspec.lock`.                         |
| `Upgradable`| The newest version reachable **without changing pubspec constraints**. This is what `apply` lands on. |
| `Resolvable`| The newest version reachable by relaxing constraints (what `--major-versions` would do). Out of scope for `apply`. |
| `Latest`    | The absolute newest version published to pub.dev.                          |

Safety flags from `pub outdated` (discontinued, retracted, advisory) are
parsed but only surfaced if present; treat any such row as a manual review
item rather than an auto-apply candidate.

### native-coupling-risk

The `Risk` column is `yes` when the package's resolved pubspec declares a
non-empty `flutter.plugin.platforms` map, i.e. it is a Flutter plugin that
drops native Android/iOS/etc. code into the build. Detection reads each direct
dependency's resolved pubspec from the pub cache (located via the zone's
`.dart_tool/package_config.json`); it never consults git state. Transitive
dependencies are listed for visibility but not assessed (`Risk = -`).

A `yes` does not block `apply`; it warns you that an upgrade of that dep may
trip a native-toolchain change and fail the gate.

---

## Rollback behavior

`apply` snapshots each zone's `pubspec.yaml` and `pubspec.lock` to a temp dir
before touching anything. On a gate failure it restores snapshots:

- **`shared_core` was modified this run** -> all-or-nothing. Restore
  `shared_core` plus every already-applied zone plus the failing zone. Apps
  resolve `shared_core` via `path:`, so leaving `shared_core` bumped while an
  app fails would leave the apps broken against a version they were never
  verified against.
- **`shared_core` was unmodified** -> failing zone only. The other zones are
  independent and stay applied.

After restoring, each restored zone is re-resolved with `pub get` so
`.dart_tool/package_config.json` matches the restored lock. The working tree
ends in a self-consistent dependency state. Build artifacts under `build/`
and `.dart_tool/` are gitignored and are not part of the rollback scope.

---

## apply output

On success, `apply`:

- leaves the working tree modified with **staged** `pubspec.yaml`/`pubspec.lock`
  diffs (`git add` was run for you; tracked locks only - `shared_core`'s lock is
  gitignored by the library-package convention and is not staged);
- prints a per-package change summary, e.g. `sqflite: 2.4.3 -> 2.4.4`;
- does not commit.

On failure, `apply` exits non-zero with the failing zone, the failing command,
and the full gate output, followed by a native-bump runbook pointer.

---

<a id="native-bump"></a>

## native-bump runbook

When a `pub upgrade` forces a native toolchain change (typically a plugin
pulling a newer Kotlin/AGP/compileSdk or an iOS deployment target bump), the
zone gate build fails. `apply` rolls back per the rule above and prints the
gate error verbatim plus a pointer to one of the subsections below (or a
generic `#native-bump` pointer for unrecognized errors). The tool never edits
native files; you resolve these manually, then re-run `apply`.

<a id="native-bump-1-flutter-sdk"></a>

### native-bump-1: Flutter SDK bump

`flutter upgrade` updates the Flutter SDK, which in turn drives the Android
`compileSdk`/`minSdk`/`targetSdk` defaults and the iOS Swift Package Manager
auto-resolution. Do this first when a gate fails with a "requires Flutter SDK
version" / "the current Flutter SDK is out of date" message.

Authoritative doc: <https://docs.flutter.dev/release/upgrade>.

Steps:

1. `flutter upgrade` (updates Flutter + Dart SDK).
2. Re-run `dart run tool/deps.dart apply`.
3. If the Android gate still fails, continue to
   [native-bump-2](#native-bump-2-android-native-pins-legacy-path).
4. If the iOS gate fails (on a Mac), continue to
   [native-bump-3](#native-bump-3-ios-deployment-target).

<a id="native-bump-2-android-native"></a>

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
5. Re-run `dart run tool/deps.dart apply`.

When AGP reaches 9 and Flutter reaches 3.47+, prefer
[native-bump-4](#native-bump-4-built-in-kotlin-migration) over hand-managing
Kotlin versions.

<a id="native-bump-3-ios-deployment"></a>

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
3. Verify on device/simulator, then re-run `dart run tool/deps.dart apply`
   (the `ios_app` gate is `flutter test` only on Linux).

<a id="native-bump-4-built-in-kotlin"></a>

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
4. Re-run `dart run tool/deps.dart apply`.

---

## Out of scope / future

- `--major-versions` apply (constraint-editing upgrades). Postpone until a
  later iteration.
- Native dependency automation. Only the manual runbook above touches native
  files; the tool never does.
- CI-driven or scheduled maintenance; adding an Android CI workflow.
- The built-in Kotlin migration itself - documented as a future step only.
- `--json` report output - postpone until a CI consumer exists.
- Changing `sdk: ^3.12.0` or any existing version pin.