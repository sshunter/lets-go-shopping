# Dev Environment Setup Checklist

**Machine:** WSL Ubuntu 24.04.4
**Goal:** Monorepo with shared_core, android_app, ios_app -- full terminal-centric workflow per docs/transitioning-to-flutter.md

---

## 1. Dart SDK

- [x] Install Dart SDK (standalone, not bundled with Flutter -- needed for shared_core pure-Dart builds)
- [x] Verify: `dart --version`

## 2. Flutter SDK

- [x] Install Flutter SDK (stable channel)
- [x] Add flutter/bin to PATH
- [x] Verify: `flutter doctor`

## 3. Android Toolchain

- [x] Install Android Studio (or just the CLI tools + SDK)
- [x] Install Android SDK platform-tools, build-tools, platform (latest stable)
- [x] Set ANDROID_HOME, ANDROID_SDK_ROOT environment variables
- [x] Accept Android SDK licenses: `flutter doctor --android-licenses`
- [x] Install KVM / configure hardware acceleration for Android emulators
- [x] Create an Android emulator (AVD) for local testing
- [x] Verify: emulator boots, `flutter devices` lists it

## 4. iOS Build Tools (Linux Bridge)

- [x] Install libimobiledevice (for wireless iOS debugging)
- [x] Install ios-deploy (if available on Linux) - NOT AVAILABLE
- [x] Verify: `flutter doctor` iOS section shows partial-but-functional status LINUX SHOWS NO IOS
- [ ] (Future) Provision physical iPhone 13 for on-device validation - Needs $99 dev sub

## 5. Neovim + Dart/Flutter LSP

- [x] Install flutter-tools.nvim plugin
- [x] Install Dart Language Server (bundled with Dart SDK -- just verify nvim-cmp/lspconfig integration)
- [x] Configure keybindings for hot-reload, hot-restart, flutter run

## 6. Dart & Flutter MCP Server (AI Agent Integration)

- [x] Clone/install the official Dart & Flutter MCP server PART OF DART INSTALL
- [x] Configure Pi/Claude to use it
- [x] Verify: agent can inspect app state and trigger hot reload

## 7. Monorepo Initialization

- [x] Create monorepo root directory
- [x] `dart create --template=package shared_core` (pure Dart -- no Flutter UI deps)
- [x] `flutter create android_app` (Material 3 target)
- [x] `flutter create ios_app` (Cupertino target)
- [x] Wire pubspec dependencies: android_app and ios_app depend on shared_core
- [x] Verify: all three projects build

## 8. Dependency Hardening

- [x] shared_core: add `bloc` (pure Dart) as dependency -- NOT flutter_bloc
- [x] shared_core: add stream-based test infrastructure for Event/State validation
- [x] Verify: `dart test` runs shared_core tests without needing Flutter SDK or emulators

## 9. CI/CD (Future)

- [ ] Set up GitHub Actions workflow for headless iOS builds (`flutter build ios --no-codesign`)
- [ ] Store Codemagic / Apple ID secrets for future provisioning
- [ ] Add Android build + test step

## 10. BLoC Pattern Bootstrap

- [ ] Define initial Event/State/BLoC structure in shared_core
- [ ] Wire a minimal example (e.g., Counter) end-to-end through android_app and ios_app
- [ ] Verify hot-reload works for both targets
