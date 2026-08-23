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

**ShoppingListBloc**:
The in-app coordinator for shopping-list mutations and UI-oriented loading, loaded, and failure states. The Android home widget callback uses a separate mutation path because it runs outside the widget tree.
_Avoid_: ShoppingListService
