# Research and Technical Decisions: Shopping List MVP

This document outlines the architectural and technology choices for implementing the Shopping List application with a lockscreen widget using the Flutter monorepo structure.

## Decision 1: Project Architecture and Decoupling

* **Decision**: strictly follow the strictly decoupled monorepo structure with three zones:
  - `/shared_core`: Pure Dart package containing data models, database repositories, BLoC state management, and stream tests. Zero dependencies on Flutter UI.
  - `/android_app`: Flutter Material 3 application that targets native Android UI and implements Jetpack Glance widgets.
  - `/ios_app`: Flutter Cupertino application that targets native iOS UI and implements WidgetKit lockscreen extensions.
* **Rationale**: DIVORCES logic from presentational rendering. Pure Dart logic in `shared_core` can maintain 100% unit test coverage run instantly on a headless Linux CI/CD without the overhead of emulators or Xcode compile steps.
* **Alternatives considered**:
  - *Single Monolithic Flutter App*: Easier to set up but bloats the presentation tree, violates the project constitution, and makes logic testing dependent on UI or full emulator suites.

## Decision 2: State Management Pattern

* **Decision**: Business Logic Component (BLoC) pattern utilizing the pure Dart `bloc` package in `/shared_core`.
* **Rationale**: Fits the "Events In -> States Out" paradigm perfectly. An AI agent or local developer can run stream assertions directly on BLoC streams (piping a sequence of action events and asserting the exact resulting state changes) in standard unit tests.
* **Alternatives considered**:
  - *ChangeNotifier / Provider*: Too coupled with Flutter framework context, harder to run purely headlessly in non-Flutter Dart packages.

## Decision 3: Shared Storage Pool and Lockscreen Widget Synchronization

* **Decision**: Local storage utilizing a light local database (like SQLite/sembast or a custom JSON store) inside `shared_core`, bridged to the OS widget containers via the `home_widget` package.
  - **Android (Glance)**: Shares state via Android SharedPreferences using `home_widget` or directly reads from a shared database file in the app's internal storage context.
  - **iOS (WidgetKit)**: Shares state via an App Group container (`UserDefaults` or shared file storage) using `home_widget`, which is readable and writable by both the main iOS host and the WidgetKit Lockscreen extension.
* **Rationale**: The lockscreen widget operates inside a separate OS process. Passing state via `home_widget` ensures instant (under 500ms) synchronous state updates between the background OS widget and the core Dart application thread.
* **Alternatives considered**:
  - *Rest-API / Cloud Sync*: Rejected for MVP due to "offline-first" constraint and unnecessary infrastructure overhead.

## Decision 4: Testing & Verification Strategy

* **Decision**: Headless-first test suite + CI gate compiling.
  - All BLoCs and storage repositories are validated via `dart test` inside `shared_core/test/`.
  - Android application is verified via local emulator.
  - iOS compilation is validated via headless GitHub Actions build (`flutter build ios --no-codesign`) on every push to catch dependency/compiler desynchronization immediately.
* **Rationale**: Direct conformance to Principle III and IV of the project constitution.
