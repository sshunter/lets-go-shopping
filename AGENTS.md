# lets-go-shopping

Shared-core shopping list app with Flutter Android (Material) and iOS (Cupertino) frontends.

## Development Standards

### Verification & Validation Gates

Run and pass these before any task touching a zone is considered done:

#### android_app/

- `flutter test` (Unit and Widget tests)
- `flutter build apk --debug` (Mandatory to verify Kotlin/Gradle/Glance dependency integrity)

#### ios_app/

- `flutter test` (iOS build unavailable on the Linux dev machine.)

#### shared_core/

- `dart test` (Pure Dart logic/Stream tests)

## Agent skills

This repo follows the `repo-agent-conventions` skill (GitHub Issues, triage labels, domain docs) - see `docs/agents/` for detail.
