# Implementation Plan: Shopping List App MVP

**Branch**: `001-shopping-list-mvp` | **Date**: 2026-05-28 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-shopping-list-mvp/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

This feature delivers a unified, offline-first Shopping List MVP. It leverages a strictly decoupled monorepo architecture where all business logic resides in a pure Dart package (`/shared_core`), divorced from platform-specific UI targets. The user interface uses Material 3 on Android (`/android_app`) and Cupertino on iOS (`/ios_app`). We implement interactive lockscreen widgets using native system tools (Jetpack Glance and WidgetKit) bridged via the `home_widget` shared storage pool to enable fast, on-the-go checking of shopping items.

## Technical Context

**Language/Version**: Dart 3.x, Flutter 3.44

**Primary Dependencies**:
- `bloc` (pure Dart package, strictly no `flutter_bloc` in `shared_core`)
- `home_widget` (platform-specific shared storage bridging)
- `uuid` (for client-side item ID generation)

**Storage**:
- Local SQLite database (internal to `shared_core` storage layer)
- Shared storage containers (UserDefaults App Group on iOS, SharedPreferences on Android) synced via `home_widget`

**Testing**:
- Pure Dart headless testing (`dart test` inside `shared_core`) utilizing Stream-based BLoC assertions
- Local Android emulator validation with local GPU acceleration
- Headless iOS compilation validation (`flutter build ios --no-codesign`) on GitHub Actions

**Target Platform**: Android (Android 10+, API level 29+) and iOS (iOS 15+, Lock Screen Widgets)

**Project Type**: mobile-app (decoupled monorepo)

**Performance Goals**:
- New items added to local database and rendered in UI in under 1 second
- Checked-state toggles on lockscreen widgets synced and rendered in under 500 milliseconds

**Constraints**:
- Offline-first local storage (no network overhead or remote authentication required)
- Lockscreen widgets restrict interactions solely to checking/unchecking items (no addition or deletion)

**Scale/Scope**: Solo developer workspace, single active shopping list checklist

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Decoupled Monorepo Check**: Does this feature follow the three-zone logic? Are pure Dart logic files located exclusively in `shared_core`?
- [x] **BLoC Separation Check**: Are all logic and states isolated from the UI using the pure-Dart BLoC/Cubit pattern?
- [x] **Headless Test Coverage**: Are there stream-based assertions for all events and states to be run headlessly via the CLI?
- [x] **iOS Compilation Check**: Is local Android emulator validation planned, and is a headless CI compilation (`flutter build ios --no-codesign`) verified for iOS dependency compatibility?
- [x] **TDD Check**: Are failing unit/behavior tests planned and written FIRST before writing any implementation code?
- [x] **Type-Safe Interop**: If native platform bridges are needed, are they defined using Pigeon?

## Project Structure

### Documentation (this feature)

```text
specs/001-shopping-list-mvp/
├── plan.md              # This file
├── research.md          # Technology decisions and rationale (Phase 0)
├── data-model.md        # Entity definition and database schemes (Phase 1)
├── quickstart.md        # Command checklists for testing & builds (Phase 1)
├── contracts/
│   └── interfaces.md    # BLoC events/states & shared storage keys (Phase 1)
└── checklists/
    └── requirements.md  # Quality validation checklist
```

### Source Code (repository root)

```text
/shared_core
├── lib/
│   ├── shared_core.dart
│   └── src/
│       ├── models/              # ShoppingItem entity definitions
│       ├── bloc/                # ShoppingListBloc, events, and states
│       └── storage/             # SQLite DB and home_widget interfaces
└── test/
    └── shared_core_test.dart    # TDD BLoC stream assertions & DB tests

/android_app
├── lib/
│   └── main.dart                # Material 3 UI presentation app entry
├── android/
│   └── app/                     # Jetpack Glance Android Widget integration

/ios_app
├── lib/
│   └── main.dart                # Cupertino UI presentation app entry
├── ios/
│   └── Runner/                  # WidgetKit iOS Lock Screen Widget extension
```

**Structure Decision**: Decoupled Monorepo with three physical zones (`shared_core`, `android_app`, `ios_app`) to maximize testability and logical decoupling.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*No violations. The proposed plan is in 100% compliance with all constitutional principles, ensuring zero UI dependencies in logic packages and automated CI gates.*
