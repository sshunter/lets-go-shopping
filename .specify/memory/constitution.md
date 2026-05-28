<!--
SYNC IMPACT REPORT
Version change: 2.0.0 -> 2.1.0
List of modified principles:
- None
Added sections:
- VI. Test-Driven Development (TDD) Discipline
Removed sections:
- None
Templates requiring updates:
- .specify/templates/plan-template.md: ✅ updated (added TDD Check gate)
- .specify/templates/tasks-template.md: ✅ updated (already aligned)
Follow-up TODOs:
- None
-->

# Let's Go Shopping Constitution

## Core Principles

### I. Decoupled Monorepo Architecture
The project is structured as a monorepo with strict physical decoupling: `/shared_core` (pure Dart, zero Flutter UI dependency), `/android_app` (Material 3 UX target), and `/ios_app` (Cupertino UX target). Keeping `/shared_core` decoupled is non-negotiable to ensure business logic remains platform-independent and 100% unit-testable without UI overhead.

### II. BLoC Pattern for Logic Separation
All business logic must be isolated in BLoC (Business Logic Component) or Cubit components within `shared_core` utilizing the pure Dart `bloc` package (strictly avoiding `flutter_bloc` in `shared_core`). Presentational code must be purely stateless, reacting to emitted states and dispatching events, ensuring a strict "Events In -> States Out" contract.

### III. Headless Linux-First Logic Validation
To support high-velocity, terminal-centric development on a Linux-only host, logic verification must run headlessly. Business logic and state transitions must be verified using pure Dart Stream-based assertions in `shared_core` unit tests, which can be executed instantly via the Linux CLI (`dart test`) without requiring mobile SDK emulators or IDE overhead.

### IV. CI-Based iOS Compilation Validation
To ensure long-term viability for the iOS platform without requiring active local macOS hardware or physical device testing, we validate the iOS target strictly via automated CI compilation. The iOS app is built headlessly (`flutter build ios --no-codesign`) on every push to verify that all dependencies added to `/shared_core` are fully compatible and compile successfully for iOS, guaranteeing the project remains structurally ready for iOS deployment in the future.

### V. Type-Safe Platform Interoperability
All platform channels and native boundaries (Android Kotlin / iOS Swift) must be defined using Pigeon for type-safe code generation, eliminating the overhead and fragility of manual key-value channel bindings. Hybrid Composition++ (HCPP) must be used as the Vulkan-based compositing pipeline for native views.

### VI. Test-Driven Development (TDD) Discipline
All business logic, state machines (BLoCs/Cubits), and data transformations within `/shared_core` must follow a strict Test-Driven Development workflow. Developers must write failing unit tests before writing the corresponding implementation code. Each development iteration must follow the Red-Green-Refactor lifecycle, ensuring high unit coverage and robust API boundary definitions before any UI layers are introduced.

## Platform UX Targets

To ensure the app does not feel cross-platform or non-native, distinct presentation styles must be strictly adhered to:
- **Android App (`/android_app`)**: Mandates Material 3 design and local Linux acceleration to track native Android behaviors like predictive back and dynamic system coloring.
- **iOS App (`/ios_app`)**: Mandates pure Cupertino styling using the decoupled Cupertino package (introduced in Flutter 3.44), allowing iOS UI refinements to be updated independently of global framework upgrades. Note: Active feature and presentation parity on iOS is deferred; compiler compatibility is the primary gate at this stage.

## CI/CD & Headless Quality Gates

To guard against compiler drift or CocoaPods dependency desynchronization without local macOS access:
- **Headless iOS Verification**: Every push to the main branch must trigger a headless compilation check (`flutter build ios --no-codesign`) on the CI runner to verify structural integrity.
- **Test Coverage**: Pure-Dart BLoC unit tests in `shared_core` must maintain 100% coverage and run on every commit.
- **Secrets Management**: Codemagic and Apple provisioning keys must be securely stored in CI for automated build signoff.

## Governance

- **Alignment Verification**: All Pull Requests and architectural reviews must verify strict alignment with this Constitution.
- **Architectural Simplicity**: Any deviation or added complexity (e.g., additional platform packages, structural layers) must be explicitly justified and approved through a formal update to this Constitution.
- **Runtime Guidance**: Use `/home/shunter/work/lets-go-shopping/docs/transitioning-to-flutter.md` as the primary reference for platform transitions and architectural logs.

**Version**: 2.1.0 | **Ratified**: 2026-05-28 | **Last Amended**: 2026-05-28
