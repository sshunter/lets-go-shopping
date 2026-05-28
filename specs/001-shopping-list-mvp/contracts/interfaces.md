# Interface and Integration Contracts: Shopping List MVP

This document outlines the contracts for both programmatic Dart interfaces and cross-process data sharing for the Shopping List application.

## 1. BLoC (Business Logic Component) Contract

The `shared_core` package exposes the `ShoppingListBloc` which manages the list state.

### Events (`ShoppingListEvent`)

- `LoadShoppingList`: Triggered on app startup or widget refresh to load all items from database.
- `AddShoppingItem(String name)`: Triggered when user submits a new item.
- `ToggleItemCompletion(String id)`: Triggered when user checks or unchecks an item.
- `DeleteShoppingItem(String id)`: Triggered when user deletes an item.

### States (`ShoppingListState`)

- `ShoppingListLoading`: Initial state when database is being read.
- `ShoppingListLoaded`: Main operational state.
  - Fields: `List<ShoppingItem> items` (sorted by `createdAt` ascending).
- `ShoppingListFailure`: Emitted on database error.
  - Fields: `String errorMessage`.

---

## 2. Shared Storage Bridge Contract (`home_widget`)

To enable interactive lockscreen updates without biometric unlocks, the main app and widget extensions communicate via a shared key-value and file pool.

### Shared Storage Schema (Platform-Specific)

- **App Group Identifier (iOS)**: `group.com.bluecollarcode.shopping.list`
- **Shared Storage Filename**: `shopping_list_shared`
- **Keys**:
  - `shopping_items_json`: String. Contains the full serialized list of items.

    ```json
    [
      {
        "id": "uuid-1",
        "name": "Apples",
        "isCompleted": false,
        "createdAt": 1780000
      }
    ]
    ```

### Interactive Actions Protocol

When an item is checked/unchecked from the Lockscreen Widget:

1. **Event Trigger**: The native widget fires a platform action (Android: `AppWidgetProvider` pending intent; iOS: `AppIntent` in WidgetKit).
2. **Background Channel Call**: The native hook calls the `home_widget` background receiver.
3. **Database Write**: The background handler updates `isCompleted` inside the shared SQLite database file.
4. **Broadcast**: A broadcast event triggers both the widget display update and forces the main app widget-tree to reload state if the app is active in the foreground.
