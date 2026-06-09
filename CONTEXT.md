# lets-go-shopping

A shared-core shopping list application with Android (Flutter/Material) and iOS (Flutter/Cupertino) frontends.

## Language

**ShoppingItem**:
An individual line on the shopping list. Has an id, name, completion status, and creation timestamp.
_Avoid_: Task, todo

**ShoppingItemRepository**:
An abstract interface for persisting ShoppingItems. SQLiteShoppingItemRepository is the one adapter.
_Avoid_: DAO, data source

**SharedStorageSink**:
An abstract interface for synchronising the shopping list to external surfaces (home widget, etc.). Has one adapter (HomeWidgetStorageSink); kept as an interface against future iOS widget needs.
_Avoid_: Callback, listener

**ShoppingListService**:
A plain-Dart module in shared_core that owns all mutations (load, add, toggle, delete) and synchronises changes to external storage sinks. Both the in-app BLoC and the home widget callback use this service. Mutations throw exceptions on failure (idiomatic Dart).
_Avoid_: BLoC (for business logic - BLoC is a UI-state adapter only)

**ShoppingListBloc**:
A BLoC that maps UI events to ShoppingListService calls and emits UI-oriented states (Loading, Loaded, Failure). Owns no business logic - only UI-state transitions and event dispatch.
_Avoid_: None
