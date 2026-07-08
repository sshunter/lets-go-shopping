---
name: flutter-tdd
description: Implement a Flutter feature from a PRD, spec, or resolved conversation using test-driven development. Orchestrates the global `tdd` and `code-review` skills' red-green-refactor discipline with Flutter's unit/widget/integration tiers and the project's MVVM + Repository architecture. Use when building a Flutter feature test-first, implementing a PRD or lighter spec in Flutter via TDD, or doing red-green-refactor in a Flutter app.
---

# Flutter TDD Orchestrator

A thin orchestrator that composes the global `tdd` and `code-review` skills (discipline + close-out review) with the project's flutter skills (architecture + test mechanics) to implement a Flutter feature test-first from a PRD, a lighter spec, or just a resolved conversation.

This skill restates the BINDING rules an agent must follow. The referenced skills are the source of truth for rationale and mechanics.

## Load these skills

Load and follow these before writing code:

- `tdd` (global) - the red-green-refactor discipline, behavior-over-implementation philosophy, vertical-slice and anti-horizontal rules, mocking principles. Source of truth for the rationale behind the rules below. NOTE: `tdd` now delegates interface-design and deep-modules vocabulary to `codebase-design` (its Planning and Refactor steps say to run `/codebase-design`) - load it too.
- `codebase-design` (global) - the deep-module vocabulary (Module, Interface, Depth, Seam, Adapter) and testability checks. Source of truth for the interface-design and seam-placement language used below (Repository interface = port/seam, "deepen modules" in refactor).
- `flutter-apply-architecture-best-practices` (project) - the MVVM + Repository layering this project uses (View -> ViewModel (ChangeNotifier) -> Repository -> Service). This is the default architecture.
- `flutter-add-widget-test` (project) - widget-test mechanics (`testWidgets`, `pumpWidget`, `WidgetTester`, `Finder`, `Matcher`, `pump` / `pumpAndSettle`). NOTE: that skill teaches test-after by default; under TDD, override its framing with the red-first sequencing in this skill.
- `flutter-add-integration-test` (project) - integration-test mechanics (`IntegrationTestWidgetsFlutterBinding`, `enableFlutterDriverExtension`, `ValueKey` targeting, `flutter drive`). Same note: use its mechanics, not its test-after framing, under TDD.

If a referenced skill is absent from the project, fall back to your Flutter training for the mechanics; the discipline and boundary rules below still apply unchanged.

## Planning gate (before any code)

Accept whatever input you have: a formal PRD, a grill-me / idea-refine / handoff artifact, a few bullets, or just the resolved conversation. Do NOT require a formal PRD.

1. Extract the BEHAVIORS to test (what the system does), not implementation steps. Pull from PRD acceptance criteria, session decisions, or the conversation.
2. Prioritize: critical paths and complex logic first. You cannot test everything; confirm with the user which behaviors matter most.
3. Identify deep-module opportunities at the Repository / UseCase seams (small interface hiding complex implementation) using the `codebase-design` vocabulary. This shapes which behaviors are worth testing through the interface.
4. Propose the vertical-slice ordering: tracer bullet, then per-behavior logic-tier-first red-green, then integration verification (see Tier strategy).
5. Present the behavior list + ordering to the user and get confirmation. This is the ONE approval gate.
6. After confirmation, run the red-green-refactor loops autonomously, one behavior at a time. Do not re-ask per slice.

This is the `tdd` skill's Planning step, adapted for an agent and for thin specs.

## Tier strategy (hybrid - mirrors `tdd`'s tracer-bullet-then-incremental workflow)

Per feature:

1. **Tracer bullet.** Write ONE thin end-to-end slice proving the feature path - usually a widget test of the feature's entry widget with minimal stubs, NOT a full `integration_test` (those need the whole app bootstrapped and are painful red-first at the start). RED (the widget / behavior does not exist: compile or assertion fail) -> minimal plumbing to get it running -> GREEN. This proves the architecture path before you build layers.

2. **Incremental red-green, logic-tier-first, per behavior.** For each behavior:
   - Logic tier: write a failing unit test for the ViewModel / Repository / UseCase method, implement minimal code to pass, refactor.
   - Widget tier: write a failing widget test for the UI of that behavior, implement the widget to pass.
   Logic first because that is where the interface-design and deep-modules emphasis lives cleanest (vocabulary now in `codebase-design`, which `tdd` references), and the widget consumes the interface you just designed.

3. **Integration verification last.** At feature completion, write a full `integration_test` covering the end-to-end user flow from the PRD / spec. This proves the layers compose; it is not the primary red-first loop.

Red-first applies at all three tiers. The FORM of RED differs:

- Logic tier: assertion fail.
- Widget tier: compile fail (widget / behavior does not exist yet), then assertion fail.
- Integration tier: flow fail (the flow is not wired end-to-end yet).

## Discipline (strict - faithful to `tdd`)

- One behavior -> one test -> run RED -> minimal code to pass -> run GREEN -> refactor -> run -> next behavior.
- Anti-horizontal, restated for Flutter: do NOT write all the ViewModel's unit tests then implement the whole ViewModel; do NOT write all widget tests then build all widgets. One behavior at a time.
- RED / GREEN detection: run the specific file, `flutter test test/<file>_test.dart` (or `integration_test/<file>_test.dart`). Exit code 0 = GREEN; non-zero = RED. Compile errors count as RED (that is the widget tier's first RED). Read the failure output to know what to implement.
- Suite check: run the full `flutter test` after each GREEN (or at minimum at feature completion) to catch regressions from refactor / assembly.
- Never refactor while RED. Get to GREEN first.
- No batching for speed. Batching tests then implementing is the horizontal-slicing anti-pattern `tdd` calls out as producing crap tests.

## Mocking boundary map (reconciled with `tdd`'s principle)

`tdd` says mock only at system boundaries, never internal collaborators. In Flutter's MVVM + Repository layering, apply it like this:

- **Service (external API / DB / platform channel) = true system boundary.** Mock or fake it when testing the Repository. Prefer fakes over mocks (the `tdd` "prefer test DB over mock DB" spirit).
- **Repository interface = declared boundary (port) when injected via constructor.** Mock it when testing the ViewModel / Use Case. The Repository IMPLEMENTATION gets its own tests against fake Services. This is the seam `flutter-apply-architecture-best-practices` already implies ("inject Repositories into ViewModels via the constructor"). Mocking a stable injected interface tests the contract, not the implementation - consistent with `tdd`'s principle, even though its literal "don't mock your own classes" assumes no injected interface.
- **ViewModel = internal collaborator. NEVER mock it when testing a View.** Test the View with a real ViewModel (which itself runs against a mocked Repository). This preserves `tdd`'s "don't mock internal collaborators" where it matters most.
- **Never mock the unit under test. Never assert on internal call counts / order** (`tdd`'s explicit red flags).

## Architecture

Adopt the project's actual structure. Default in this project: `flutter-apply-architecture-best-practices` MVVM + Repository - `lib/ui/features/<feature>/{views,view_models}`, `lib/data/{services,repositories,models}`, optional `lib/domain/use_cases`. If the project uses a different structure, detect and follow it; the tier strategy and boundary map still apply (map "logic tier" to the project's logic unit, "Repository interface" to its data seam).

## Close-out (the `implement` step's tail)

After integration verification and the full `flutter test` suite are GREEN, this skill has completed the `implement` step of the lifecycle (`Grill -> Spec -> Tickets -> Implement -> Code Review`). Finish the implement step:

1. **Hand off to `/code-review`** against the feature's starting point (the branch base / first commit of the feature). `code-review` runs the two-axis review (Standards + Spec, with the Fowler smell baseline) on the diff since that point. Treat its findings as the refactor pass — fix real smells before committing.
2. **Commit** your work to the current branch once review is clean. Do not commit before `/code-review` returns.

Refactoring during red-green (after each GREEN) is still in-scope here; `/code-review` is the final, diff-level smell pass that closes the feature out.

## Reference

See [worked-example.md](references/worked-example.md) for a concrete end-to-end run of the loop on a small feature (tracer bullet -> per-behavior logic + widget red-green -> integration), including the mocking boundary map shown in Dart.
