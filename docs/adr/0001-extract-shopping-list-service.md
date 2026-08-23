# ADR-0001: Extract ShoppingListService

**Date:** 2025-06-05
**Status:** Rejected

## Outcome

This proposal was rejected before implementation. No `ShoppingListService` exists in tracked source history. The application retained `ShoppingListBloc` as the owner of the in-app mutation path, while the Android home widget callback keeps its isolate-local mutation and synchronization path.

The current architecture is documented as it exists rather than introducing a service solely to make this stale decision record accurate. Related follow-up issues proceed independently of this rejected extraction.

## Problem

The home widget interactivity callback (`homeWidgetInteractivityCallback`) duplicated the toggle + sync logic that already existed in `ShoppingListBloc`. The callback created its own database connection, found the item, flipped it, saved it, and synced to the home widget -- all code the BLoC also owned. Any new mutation logic (side effects, validation, logging) had to be added in two places.

Root cause: the callback is a `@pragma('vm:entry-point')` top-level function running outside the widget tree. It could not `context.read<ShoppingListBloc>()` or access any BLoC instance, so it was forced to duplicate the logic.

## Proposed decision

The proposal was to extract a plain-Dart `ShoppingListService` in `shared_core` that owned the full mutation path (load, add, toggle, delete, sync to external sinks). Both the BLoC and the widget callback would have used this service. The BLoC would have become a UI-state adapter that delegated to the service and emitted `Loading`/`Loaded`/`Failure` states.

### Proposed design choices

- **ShoppingListService** is a plain Dart class in `shared_core`. No Flutter dependency.
- Injects `ShoppingItemRepository` (required) and `SharedStorageSink` (optional, nullable).
- Methods: `loadAll()`, `addItem(String name)`, `toggleItem(String id)`, `deleteItem(String id)`. Every mutation returns `Future<List<ShoppingItem>>` with the fresh item list.
- `addItem` owns UUID generation and timestamp creation (previously in BLoC).
- Mutations throw exceptions on failure (idiomatic Dart). No result types. Callers catch at their boundary.
- **ShoppingListBloc** injects `ShoppingListService` instead of `ShoppingItemRepository + SharedStorageSink`.
- **homeWidgetInteractivityCallback** creates its own `ShoppingListService` instance (different isolate, can't share) with a `HomeWidgetStorageSink`.
- The `SharedStorageSink` abstract class was kept (not collapsed to a function type).

### Related follow-up issues

These candidates came from the same architecture review but proceed independently of the rejected service extraction:

- **Widget lifecycle consolidation** -> Issue #11 (extract shared app shell)
- **Validation in BLoC** -> Issue #12 (centralize validation in the existing BLoC mutation path)
- **SharedStorageSink collapse** -> Issue #13 (revisit abstraction)
- **Dead file removal** -> Issue #14 (remove `shared_core_base.dart`)
