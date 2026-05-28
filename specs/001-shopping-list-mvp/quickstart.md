# Developer Quickstart: Shopping List MVP

This guide provides rapid setup and verification commands for the Shopping List monorepo.

## 1. Verify Business Logic (shared_core)

Since `/shared_core` is pure Dart, all tests run headlessly on your local Linux machine instantly without requiring mobile emulators.

### Run All Unit and Stream Tests:
```bash
cd shared_core
dart test
```

---

## 2. Launch Local Android Application

Android verification runs locally with hardware acceleration.

### Pre-requisites:
- Android emulator (AVD) configured and running.
- To check connected emulators:
  ```bash
  flutter devices
  ```

### Run Android App:
```bash
cd android_app
flutter run -d <emulator-id>
```

---

## 3. Run Headless iOS Compilation (CI Gate Validation)

To ensure compile-time sanity without local macOS access, verify compiling using:

```bash
cd ios_app
flutter build ios --no-codesign
```

This ensures CocoaPods integration, Pigeon platforms channels, and Cupertino widget layouts are structurally solid and fully ready for macOS provisioning when needed.
