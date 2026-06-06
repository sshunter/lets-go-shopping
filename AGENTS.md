# Development Standards

## Verification & Validation Gates

To prevent build regressions and dependency mismatches, the following commands MUST be executed and pass successfully before any task involving these zones is considered "Done":

### android_app/

- `flutter test` (Unit and Widget tests)
- `flutter build apk --debug` (Mandatory to verify Kotlin/Gradle/Glance dependency integrity)

### ios_app/

- `flutter test`
- That is all. We can't build ios_app on our linux dev machine.

### shared_core/

- `dart test` (Pure Dart logic/Stream tests)

## Agent skills

### Issue tracker

Issues are tracked as local markdown files under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles use their default names. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.
