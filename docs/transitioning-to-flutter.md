# Architectural Decision Log: Transitioning to Flutter

**Date:** May 2026

---

## 1. Strategic Context and Operational Constraints

For a solo developer operating a Linux-first stack, architectural selection is a cold calculation of ergonomic efficiency and AI-compatibility. In this environment, velocity is the only metric that matters. To maintain high-output engineering without the overhead of the Apple ecosystem's hardware requirements, the framework must prioritize a terminal-centric workflow and provide a high-fidelity interface for AI code agents.

The following parameters define our operational boundaries:

### Toolchain Parameters

- **Workstation:** Linux (Fedora/Ubuntu-based)
- **Editor:** Neovim (via flutter-tools.nvim and the Dart Language Server)
- **CLI Infrastructure:** Heavy reliance on the flutter toolchain, libimobiledevice, and ios-deploy for Linux-to-iOS bridging
- **Agentic Prerequisites:** Integration with the official Dart & Flutter Model Context Protocol (MCP) server for Pi/Claude autonomy

### Hardware Reality

The absence of local macOS hardware introduces a significant risk of "OS-level micro-interaction drift"—subtle UI behaviors or haptic failures that cloud CI cannot catch. To mitigate this, a physical iPhone 13 is strategically required for on-device validation via wireless debugging. While local Android validation is handled via accelerated KVM-native emulators, the iPhone acts as the final guardrail for iOS-specific visual and tactile integrity.

---

## 2. Comparative Analysis: Why Flutter Eclipsed KMP for this Workflow

The strategic objective is "Headless Ergonomics"—the ability to build, test, and iterate without dependency on a heavy IDE. While Kotlin Multiplatform (KMP) offers native UIs, its reliance on the Gradle toolchain and fragmented LSP support creates unacceptable friction for a Neovim-centric solo developer.

### Toolchain Friction: Flutter vs. KMP for Linux/Neovim Devs

| Vector | Flutter (v3.44) | KMP (Kotlin Multiplatform) |
|--------|-----------------|---------------------------|
| Build System | pubspec.yaml; 30% reduction in crashes per "Project Quartz" findings | Gradle; verbose, slow, and complex manual config |
| LSP Reliability | Dart LSP: supports cross-package jump-to-definition and robust refactoring | Kotlin LSP: frequently breaks across Android/iOS source sets in headless modes |
| Feedback Loop | Native Headless Hot-Reload; 43.5% reduction in open issues for Linux/Android devs | Requires full recompilation or IDE-dependent previews |
| Knowledge Equity | High: Single runtime/language for logic and UI | Low: Fragmented between Kotlin, Swift, and Gradle |

### The AI Agent Factor and the Context Window Tax

In May 2026, the primary cost of development is the "Context Window Tax." KMP requires an AI agent to maintain context for two distinct UI paradigms (Jetpack Compose and SwiftUI). This duplication consumes limited tokens and increases the probability of logic drift.

Flutter 3.44's "Single UI Tree" approach allows an agent to reason about a single declarative structure. With the official Dart & Flutter MCP server, agents can now inspect application state and trigger Agentic Hot Reload autonomously via the CLI. This shifts the agent from a code generator to a real-time iteration partner, protecting the developer's flow state through a "Convergent Mindset."

### Verdict

Flutter is the objectively superior logistical choice. It consolidates developer effort into a single runtime, maximizing knowledge equity while aligning perfectly with a Linux-native toolchain.

---

## 3. The "Strictly Decoupled Monorepo" Architecture

To prevent the "Uncanny Valley" effect—where cross-platform apps feel non-native on both platforms—we implement a monorepo that enforces strict physical boundaries between presentation layers.

### Monorepo Directory Structure

```
/project_root
├── /shared_core       # Pure Dart logic (No Flutter UI dependencies)
├── /android_app       # Material 3 / Android UX target
└── /ios_app           # Cupertino / iOS UX target
```

### The Three-Zone Logic

- **shared_core:** Restricted to pure Dart. This package must depend on the bloc package (pure Dart) and not flutter_bloc. By excluding Flutter UI packages, we enable 100% unit test coverage via the Linux CLI without requiring emulators or UI overhead.
- **android_app:** Mandated Material 3 UX. It leverages local Linux acceleration to track native Android 17 behaviors (predictive back, dynamic color) with zero latency.
- **ios_app:** Mandated pure Cupertino styling. We utilize the decoupled Cupertino package (introduced in 3.44), allowing the iOS UI to be updated via pubspec.yaml independently of framework-level upgrades. This ensures we can patch iOS design tweaks within weeks of an Apple update.

---

## 4. State Management and Logic Separation via BLoC

The Business Logic Component (BLoC) pattern serves as our architectural anchor, divorcing the "brain" of the app from the pixel-rendering engine.

### Core Components

1. **Events:** Immutable inputs representing user intent (e.g., FetchData)
2. **States:** Snapshots of data emitted to the UI
3. **The BLoC:** The async engine mapping Events to States. For simple transitions, Cubit is utilized to reduce boilerplate
4. **The UI:** Stateless widgets that dispatch events and consume states

### Logic Validation and Agentic Autonomy

The "Events In -> States Out" contract is the only reliable way to achieve 100% logic validation for an iOS target on a Linux machine. AI agents utilize Stream-based logic checks; an agent can pipe a sequence of Events and assert the resulting States in a standard Dart test script. This allows for rigorous verification of the iOS app's business logic without ever needing to boot a Mac.

---

## 5. Mitigating Ecosystem Risks: Native Integration & Hardware Gaps

The risk of being "locked out" of native SDKs is mitigated through type-safe interop and cloud-based validation.

### The Native Bridge: HCPP and Pigeon

Flutter 3.44 utilizes Hybrid Composition++ (HCPP), a Vulkan-based native compositing pipeline that embeds native views (Android/iOS) into the widget tree without performance degradation. We use Pigeon to generate type-safe platform channel boilerplate. AI agents ingest native SDK documentation and generate the Kotlin/Swift glue code, eliminating the "Wrapper Code Tax."

### The Blind iOS Sanity Check

To catch "Podfile/CocoaPods" synchronization issues or compiler drift, we implement a headless CI/CD pipeline (GitHub Actions or Codemagic):

```
$ flutter build ios --no-codesign
```

This catches missing dependencies or broken iOS configurations immediately after a push, ensuring the project remains structurally sound for macOS compilation even when developed on Linux.

### Widgets and Notifications

Home screen extensions (Android App Widgets/iOS WidgetKit) and Live Activities require native code.

- **Android:** Jetpack Glance (Kotlin)
- **iOS:** WidgetKit (Swift/SwiftUI)
- **Integration:** Data is passed from the Dart shared_core to these native layers via the home_widget package, which bridges Dart background logic to Jetpack Glance and WidgetKit through shared storage pools (UserDefaults/SharedPreferences)

---

## 6. Final Decision Summary and Immediate Action Plan

By adopting this architecture, we transform a solo developer's constraints into a high-velocity, terminal-centric engine. This strategy protects the "Convergent Mindset"—minimizing context switching by keeping 95% of development in a single language (Dart) while maintaining the platform fidelity required for a professional-grade product.

### Immediate Action Plan

- [ ] Initialize Monorepo: Separate shared_core, android_app, and ios_app using the flutter CLI
- [ ] Dependency Hardening: Ensure shared_core is restricted to the pure-Dart bloc library
- [ ] CI/CD Pipeline: Configure GitHub Actions for headless iOS builds (--no-codesign) and store Apple ID/Codemagic secret keys for future provisioning
- [ ] Agent Configuration: Establish BLoC patterns and provide the Dart MCP server path to the AI agent for immediate context-setting
- [ ] Provision iPhone 13: Setup libimobiledevice for wireless debugging and sanity checks

This architecture specifically protects solo developer velocity by ensuring knowledge equity is consolidated, not fragmented.
