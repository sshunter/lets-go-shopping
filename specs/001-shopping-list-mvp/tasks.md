# Tasks: Shopping List App MVP

**Input**: Design documents from `/specs/001-shopping-list-mvp/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [data-model.md](./data-model.md), [contracts/interfaces.md](./contracts/interfaces.md), [research.md](./research.md)

**Tests**: TDD is required per the plan.md Constitution Check — test tasks are included and **MUST fail before implementation begins**.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **shared_core**: `shared_core/lib/src/`, tests at `shared_core/test/`
- **android_app**: `android_app/lib/`, native at `android_app/android/app/src/main/`
- **ios_app**: `ios_app/lib/`, native extension at `ios_app/ios/ShoppingWidget/`

> **Android package namespace**: `com.bluecollarcode.shopping` (used in all Kotlin paths below)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize all three monorepo zones and their dependencies before any feature work begins.

- [ ] T001 Verify `shared_core` is a valid pure Dart package — confirm `shared_core/pubspec.yaml` declares `sdk: dart` (not `sdk: flutter`) and has no Flutter UI dependencies
- [ ] T002 [P] Add `bloc`, `uuid`, and `sqflite_common_ffi` dependencies to `shared_core/pubspec.yaml` and run `dart pub get`
- [ ] T003 [P] Add `flutter_bloc` and `home_widget` dependencies to `android_app/pubspec.yaml` and run `flutter pub get`
- [ ] T004 [P] Add `flutter_bloc` and `home_widget` dependencies to `ios_app/pubspec.yaml` and run `flutter pub get`
- [ ] T005 Create the directory structure in `shared_core/lib/src/`: `models/`, `bloc/`, `storage/`
- [ ] T006 Create/update the barrel export file `shared_core/lib/shared_core.dart` to re-export public API

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data model, storage layer, BLoC skeleton, and the `SharedStorageSink` abstraction that ALL user stories depend on. No user story work can begin until this phase is complete.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

> **Architecture note (C1/C2)**: `shared_core` must remain pure Dart with zero Flutter plugin dependencies so that all tests run headlessly via `dart test`. The `home_widget` Flutter plugin is NOT imported here. Instead, `shared_core` defines a `SharedStorageSink` abstract interface. Each platform app (`android_app`, `ios_app`) provides a concrete adapter using `home_widget`. This preserves `dart test` headless testing (Constitution Principles I & III) and keeps the BLoC fully mockable.

> **Architecture note (C3/Pigeon)**: The lockscreen widget reads/writes OS-native shared storage (Android `SharedPreferences`, iOS `UserDefaults`) directly — this is a native OS API, not a custom Flutter platform channel. The widget-to-app callback uses `home_widget`'s built-in background mechanism, which already provides a typed, versioned boundary. No custom Pigeon schema is required; Constitution Principle V applies to custom `MethodChannel` bindings, which this design does not introduce.

### TDD: Write Failing Tests First

- [ ] T007 [P] Write failing stream test for `LoadShoppingList` event → `ShoppingListLoaded([])` state in `shared_core/test/shopping_list_bloc_test.dart`
- [ ] T008 [P] Write failing repository test asserting SQLite table is created and `getAll()` returns an empty list in `shared_core/test/shopping_item_repository_test.dart`
- [ ] T009 [P] Write failing test: `ShoppingListBloc` constructed with a mock `SharedStorageSink` — after emitting `ShoppingListLoaded`, `mockSink.syncItems()` is called with the correct items list in `shared_core/test/shopping_list_bloc_test.dart`

### Implementation

- [ ] T010 [P] Define `ShoppingItem` model with `id`, `name`, `isCompleted`, `createdAt` fields in `shared_core/lib/src/models/shopping_item.dart` — include `copyWith`, `==`, `hashCode`, and JSON serialization helpers
- [ ] T011 Implement `ShoppingItemRepository` with SQLite backend (create table, CRUD methods: `getAll`, `insert`, `update`, `delete`) in `shared_core/lib/src/storage/shopping_item_repository.dart`
- [ ] T012 Define `ShoppingListEvent` sealed class with `LoadShoppingList`, `AddShoppingItem`, `ToggleItemCompletion`, `DeleteShoppingItem` in `shared_core/lib/src/bloc/shopping_list_event.dart`
- [ ] T013 Define `ShoppingListState` sealed class with `ShoppingListLoading`, `ShoppingListLoaded`, `ShoppingListFailure` in `shared_core/lib/src/bloc/shopping_list_state.dart`
- [ ] T014 Define `SharedStorageSink` abstract interface in `shared_core/lib/src/storage/shared_storage_sink.dart` — single method: `Future<void> syncItems(List<ShoppingItem> items)`
- [ ] T015 Implement `ShoppingListBloc` skeleton in `shared_core/lib/src/bloc/shopping_list_bloc.dart` — constructor accepts `ShoppingItemRepository` and `SharedStorageSink?`; handles `LoadShoppingList` by emitting `ShoppingListLoading` then `ShoppingListLoaded(items)`; calls `storageSink?.syncItems(items)` after every `ShoppingListLoaded` emission
- [ ] T016 Run `dart test` in `shared_core/` — confirm T007, T008, and T009 tests now pass ✅

**Checkpoint**: Foundation ready — `ShoppingItem`, `ShoppingItemRepository`, `SharedStorageSink`, and `ShoppingListBloc` exist and load an empty list successfully. All tests run headlessly.

---

## Phase 3: User Story 1 — Manage Shopping List Items (Priority: P1) 🎯 MVP

**Goal**: Users can add new items, view all items in a single list, and permanently delete items.

**Independent Test**: A user can add "Apples", see it appear in the checklist, and tap delete next to "Apples" to remove it entirely from the list.

### TDD: Write Failing Tests First

- [ ] T017 [P] [US1] Write failing BLoC stream test for `AddShoppingItem("Apples")` → `ShoppingListLoaded([ShoppingItem(name:"Apples", isCompleted:false)])` in `shared_core/test/shopping_list_bloc_test.dart`
- [ ] T018 [P] [US1] Write failing BLoC stream test for `DeleteShoppingItem(id)` → `ShoppingListLoaded([])` (item removed) in `shared_core/test/shopping_list_bloc_test.dart`
- [ ] T019 [P] [US1] Write failing repository test: `insert()` then `getAll()` returns one item; `delete()` then `getAll()` returns empty in `shared_core/test/shopping_item_repository_test.dart`
- [ ] T020 [P] [US1] Write failing BLoC stream test: two sequential `AddShoppingItem("Apples")` events → `ShoppingListLoaded` with two items each having distinct UUIDs (edge case: duplicate names) in `shared_core/test/shopping_list_bloc_test.dart`

### Implementation: shared_core

- [ ] T021 [US1] Implement `AddShoppingItem` handler in `ShoppingListBloc` — generate UUID, set `createdAt`, persist via `ShoppingItemRepository.insert()`, emit updated `ShoppingListLoaded`, call `storageSink?.syncItems()` in `shared_core/lib/src/bloc/shopping_list_bloc.dart`
- [ ] T022 [US1] Implement `DeleteShoppingItem` handler in `ShoppingListBloc` — call `ShoppingItemRepository.delete(id)`, emit updated `ShoppingListLoaded`, call `storageSink?.syncItems()` in `shared_core/lib/src/bloc/shopping_list_bloc.dart`
- [ ] T023 [US1] Run `dart test` in `shared_core/` — confirm T017, T018, T019, T020 tests now pass ✅

### Implementation: android_app (Material 3 UI)

- [ ] T024 [P] [US1] Wire `ShoppingListBloc` into `android_app/lib/main.dart` using `BlocProvider` — pass `ShoppingItemRepository` and `null` for `SharedStorageSink` (real sink injected in Phase 5 when widget is added)
- [ ] T025 [US1] Implement `ShoppingListScreen` widget in `android_app/lib/src/screens/shopping_list_screen.dart` — uses `BlocBuilder<ShoppingListBloc, ShoppingListState>` to render `ListView` of items; shows empty-state message "Your shopping list is empty!" when `ShoppingListLoaded([])` is emitted
- [ ] T026 [US1] Implement `AddItemBar` widget in `android_app/lib/src/widgets/add_item_bar.dart` — bottom `TextField` + submit button; dispatches `AddShoppingItem(name)` on submit; validates non-empty and max 100 chars
- [ ] T027 [US1] Implement `ShoppingItemTile` widget in `android_app/lib/src/widgets/shopping_item_tile.dart` (Material 3 `ListTile`) — displays item name; includes delete icon button that dispatches `DeleteShoppingItem(id)`

### Implementation: ios_app (Cupertino UI)

- [ ] T028 [P] [US1] Wire `ShoppingListBloc` into `ios_app/lib/main.dart` using `BlocProvider` — pass `ShoppingItemRepository` and `null` for `SharedStorageSink` (real sink injected in Phase 5)
- [ ] T029 [P] [US1] Implement `ShoppingListPage` widget in `ios_app/lib/src/screens/shopping_list_page.dart` — uses `BlocBuilder` to render `CupertinoListSection` of items; shows empty-state message when `ShoppingListLoaded([])` is emitted
- [ ] T030 [P] [US1] Implement `AddItemBar` widget in `ios_app/lib/src/widgets/add_item_bar.dart` — `CupertinoTextField` + submit `CupertinoButton`; dispatches `AddShoppingItem(name)` on submit; validates non-empty and max 100 chars
- [ ] T031 [P] [US1] Implement `ShoppingItemTile` widget in `ios_app/lib/src/widgets/shopping_item_tile.dart` — Cupertino-styled tile with trailing delete button dispatching `DeleteShoppingItem(id)`

**Checkpoint**: User Story 1 fully functional. Validate with `dart test` in `shared_core/` and manual emulator run via `flutter run` in `android_app/`.

---

## Phase 4: User Story 2 — Toggle Checklist Completion (Priority: P1)

**Goal**: Users can tap on items in the checklist inside the application to mark them as completed or uncompleted.

**Independent Test**: A user can tap the checkbox next to "Milk" to mark it checked, then tap again to mark it unchecked.

### TDD: Write Failing Tests First

- [ ] T032 [P] [US2] Write failing BLoC stream test: `ToggleItemCompletion(id)` on an unchecked item → `ShoppingListLoaded([ShoppingItem(isCompleted:true)])` in `shared_core/test/shopping_list_bloc_test.dart`
- [ ] T033 [P] [US2] Write failing BLoC stream test: second `ToggleItemCompletion(id)` → `ShoppingListLoaded([ShoppingItem(isCompleted:false)])` (toggle back) in `shared_core/test/shopping_list_bloc_test.dart`
- [ ] T034 [P] [US2] Write failing repository test: `update()` flips `isCompleted` in the DB in `shared_core/test/shopping_item_repository_test.dart`

### Implementation: shared_core

- [ ] T035 [US2] Implement `ToggleItemCompletion` handler in `ShoppingListBloc` — call `ShoppingItemRepository.update(item.copyWith(isCompleted: !item.isCompleted))`, emit updated `ShoppingListLoaded`, call `storageSink?.syncItems()` in `shared_core/lib/src/bloc/shopping_list_bloc.dart`
- [ ] T036 [US2] Run `dart test` in `shared_core/` — confirm T032, T033, T034 tests now pass ✅

### Implementation: android_app

- [ ] T037 [US2] Update `ShoppingItemTile` in `android_app/lib/src/widgets/shopping_item_tile.dart` — add `Checkbox` widget bound to `item.isCompleted`; tapping dispatches `ToggleItemCompletion(item.id)`; apply strikethrough text style when completed

### Implementation: ios_app

- [ ] T038 [P] [US2] Update `ShoppingItemTile` in `ios_app/lib/src/widgets/shopping_item_tile.dart` — add `CupertinoCheckbox` (or custom tick indicator) bound to `item.isCompleted`; tapping dispatches `ToggleItemCompletion(item.id)`; apply strikethrough text style when completed

**Checkpoint**: User Stories 1 AND 2 fully functional. Run `dart test` in `shared_core/` and verify toggle behavior on emulator.

---

## Phase 5: User Story 3 — Lockscreen Widget Interactive Checklist (Priority: P2)

**Goal**: A native lockscreen widget displays all shopping list items and allows users to check/uncheck them directly from the lockscreen without opening the app.

**Independent Test**: With the widget configured on the lockscreen, the user can check off an item and verify the state updates in both the widget and the main app.

> **Sync flow (I1 clarification)**: The shared storage pool (Android `SharedPreferences`, iOS `UserDefaults`) is the source of truth for the widget. SQLite is the source of truth for the app. The two-step write path on widget interaction is: (1) native widget fires OS action → `home_widget` background callback fires → (2) Dart background handler reads the toggle event and writes the updated item to SQLite → (3) app resumes and dispatches `LoadShoppingList` to reload state from SQLite. The widget reads the shared JSON pool written by `syncItems()` — it does NOT read SQLite directly.

### TDD: Write Failing Tests First

- [ ] T039 [US3] Write failing test: `ShoppingListBloc` with a mock `SharedStorageSink` — after `AddShoppingItem`, `mockSink.syncItems()` is called with a list containing the new item serialized to the correct JSON schema (`id`, `name`, `isCompleted`, `createdAt`) in `shared_core/test/shopping_list_bloc_test.dart`
- [ ] T040 [US3] Write failing BLoC test: mock `ShoppingItemRepository` returns a new set of items when `getAll()` is called a second time; re-dispatching `LoadShoppingList` emits `ShoppingListLoaded` with the updated items (verifies state refresh on widget resume) in `shared_core/test/shopping_list_bloc_test.dart`

### Implementation: shared_core (Storage Bridge via interface)

- [ ] T041 [US3] Run `dart test` in `shared_core/` — confirm T039 and T040 tests pass with mock implementations ✅ (no `home_widget` used in shared_core)

### Implementation: platform adapters (home_widget)

- [ ] T042 [US3] Implement `HomeWidgetStorageSink` in `android_app/lib/src/storage/home_widget_storage_sink.dart` — implements `SharedStorageSink`; `syncItems()` serializes items to JSON and writes to `home_widget` shared storage under key `shopping_items_json`; calls `HomeWidget.updateWidget()` to trigger widget refresh
- [ ] T043 [P] [US3] Implement `HomeWidgetStorageSink` in `ios_app/lib/src/storage/home_widget_storage_sink.dart` — same interface and key as T042
- [ ] T044 [US3] Update `android_app/lib/main.dart` `BlocProvider` to replace `null` with `HomeWidgetStorageSink()` as the `SharedStorageSink` argument to `ShoppingListBloc`
- [ ] T045 [P] [US3] Update `ios_app/lib/main.dart` `BlocProvider` to replace `null` with `HomeWidgetStorageSink()` as the `SharedStorageSink` argument to `ShoppingListBloc`

### Implementation: android_app (Jetpack Glance Widget)

- [ ] T046 [US3] Configure `android_app/android/app/src/main/AndroidManifest.xml` — register `AppWidgetProvider` receiver and declare widget metadata; configure `home_widget`'s App Group identifier
- [ ] T047 [US3] Implement Jetpack Glance widget layout in `android_app/android/app/src/main/kotlin/com/bluecollarcode/shopping/ShoppingListWidget.kt` — reads `shopping_items_json` from `SharedPreferences`, deserializes JSON, renders a scrollable list of items with checkbox toggles; shows empty-state message "Your shopping list is empty!" when list is empty or key is absent; no add or delete controls present
- [ ] T048 [US3] Implement `AppWidgetProvider` background toggle handler in `android_app/android/app/src/main/kotlin/com/bluecollarcode/shopping/ShoppingListWidgetReceiver.kt` — on checkbox tap: (1) updates `isCompleted` in the `shopping_items_json` SharedPreferences key, (2) triggers `home_widget` background Dart callback to write the change to SQLite, (3) calls `AppWidgetManager.notifyAppWidgetViewDataChanged()` to refresh the widget display

### Implementation: ios_app (WidgetKit Lock Screen Extension)

- [ ] T049 [P] [US3] Configure iOS App Group container identifier (`group.com.bluecollarcode.shopping.list`) in `ios_app/ios/Runner.xcodeproj` — add WidgetKit extension target `ShoppingWidget`; ensure App Group entitlement is added to both the Runner and the extension
- [ ] T050 [P] [US3] Implement WidgetKit lock screen extension entry in `ios_app/ios/ShoppingWidget/ShoppingWidget.swift` — reads `shopping_items_json` from `UserDefaults(suiteName: "group.com.bluecollarcode.shopping.list")`; deserializes JSON; renders items list using SwiftUI `List`; shows empty-state text when list is empty or key absent; no add or delete controls present
- [ ] T051 [P] [US3] Implement `AppIntent` toggle action in `ios_app/ios/ShoppingWidget/ToggleItemIntent.swift` — on item tap: (1) reads and mutates `shopping_items_json` in the shared `UserDefaults` key, (2) calls `WidgetCenter.shared.reloadAllTimelines()` to refresh the widget display, (3) notifies Flutter via `home_widget` background callback to write the change to SQLite

### State Refresh on App Resume (Concurrent Modification Sync)

- [ ] T052 [US3] In `android_app/lib/main.dart`, subscribe to `HomeWidget.widgetClicked` stream — on each event, dispatch `LoadShoppingList` to `ShoppingListBloc` so the app reloads fresh state from SQLite after a widget toggle
- [ ] T053 [P] [US3] In `ios_app/lib/main.dart`, subscribe to `HomeWidget.widgetClicked` stream — on each event, dispatch `LoadShoppingList` to `ShoppingListBloc`

**Checkpoint**: All three user stories fully functional. Validate widget behavior on Android emulator and run headless iOS compilation (`flutter build ios --no-codesign` in `ios_app/`).

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Edge case validation, error state rendering, and final quality gates across all user stories.

- [ ] T054 [P] Validate empty-state message "Your shopping list is empty!" renders correctly in `android_app` `ShoppingListScreen` and `ios_app` `ShoppingListPage` when the list is empty — confirm both T025 and T029 implementations are correct on emulator
- [ ] T055 [P] Add input validation UI feedback in `android_app/lib/src/widgets/add_item_bar.dart` and `ios_app/lib/src/widgets/add_item_bar.dart` — show inline error if name is blank or exceeds 100 characters
- [ ] T056 [P] Implement `ShoppingListFailure` state rendering in `android_app` `ShoppingListScreen` (`android_app/lib/src/screens/shopping_list_screen.dart`) and `ios_app` `ShoppingListPage` (`ios_app/lib/src/screens/shopping_list_page.dart`) — show error snackbar/banner with the failure message
- [ ] T057 Run full headless test suite: `dart test` in `shared_core/` — confirm all tests pass ✅
- [ ] T058 Run headless iOS compilation gate: `flutter build ios --no-codesign` in `ios_app/` — confirm zero compile errors ✅
- [ ] T059 Run quickstart.md validation — execute all commands in `specs/001-shopping-list-mvp/quickstart.md` and confirm all steps pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) — **BLOCKS all user stories**
- **US1 (Phase 3)** and **US2 (Phase 4)**: Both depend on Foundational; can proceed sequentially or in parallel (both P1)
- **US3 (Phase 5)**: Depends on US1 + US2 being complete (widget needs full item state: add, delete, and toggle)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Can start after Phase 2 — no story dependencies
- **US2 (P1)**: Can start after Phase 2 — additive change to existing BLoC and UI
- **US3 (P2)**: Depends on US1 + US2 — widget surfaces all item operations

### Within Each User Story

1. Write failing tests FIRST — verify they FAIL before implementation
2. Implement `shared_core` logic → run `dart test` → confirm tests pass
3. Implement `android_app` UI and `ios_app` UI in parallel where marked [P]
4. Run full test suite + quickstart validation at each checkpoint

### Key `SharedStorageSink` Wiring Sequence

- T014 (Phase 2): Define interface (pure Dart, `shared_core`)
- T024/T028 (Phase 3): Wire `null` into BlocProvider (no-op during US1/US2)
- T042/T043 (Phase 5): Implement `HomeWidgetStorageSink` adapters in each platform app
- T044/T045 (Phase 5): Update BlocProvider to inject real adapters

---

## Parallel Execution Examples

### Phase 2: Foundational

```bash
# In parallel (TDD first):
# T007: BLoC load test, T008: repository test, T009: sink mock test

# Then in parallel:
# T010: models/shopping_item.dart
# T011: storage/shopping_item_repository.dart
# T012: bloc/shopping_list_event.dart
# T013: bloc/shopping_list_state.dart
# T014: storage/shared_storage_sink.dart
```

### Phase 3: User Story 1 (android_app + ios_app in parallel after shared_core)

```bash
# After T021-T023 (shared_core logic):
# android_app (T024-T027) and ios_app (T028-T031) can run in parallel
```

### Phase 5: User Story 3 (platform adapters + native widget code in parallel)

```bash
# After T041 (dart test passes):
# T042 and T043 (HomeWidgetStorageSink adapters) in parallel
# T046-T048 (Android widget) and T049-T051 (iOS widget) in parallel
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only — Core App)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1 (Add, View, Delete)
4. Complete Phase 4: User Story 2 (Toggle completion)
5. **STOP and VALIDATE**: `dart test` in `shared_core/` + Android emulator smoke test
6. Ship/demo the core app without the widget

### Incremental Delivery

1. Setup + Foundational → Core infrastructure + `SharedStorageSink` abstraction ready
2. US1 → Test independently → Core list management works
3. US2 → Test independently → Full in-app checklist experience
4. US3 → Inject real `HomeWidgetStorageSink` adapters → Lockscreen widget live
5. Polish → Production-ready

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [Story] label maps each task to its user story for traceability
- **TDD is mandatory** per the Constitution Check in plan.md — write failing tests before each implementation block
- `shared_core` must remain pure Dart — never import `home_widget` or any Flutter plugin here
- `SharedStorageSink` is the only seam between `shared_core` BLoC and platform-specific storage adapters
- The intermediate `dart test` gates (T016, T023, T036, T041, T057) are per-story checkpoints, not duplicates — T057 is the final cumulative gate
- Run `flutter build ios --no-codesign` in `ios_app/` as the CI gate for iOS compatibility
- Commit after each checkpoint
- `ShoppingItem` is the only domain entity — it serves all three user stories
