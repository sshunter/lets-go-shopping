sealed class ShoppingListEvent {}

class LoadShoppingList extends ShoppingListEvent {}

class AddShoppingItem extends ShoppingListEvent {
  final String name;
  AddShoppingItem(this.name);
}

class ToggleItemCompletion extends ShoppingListEvent {
  final String id;
  ToggleItemCompletion(this.id);
}

class DeleteShoppingItem extends ShoppingListEvent {
  final String id;
  DeleteShoppingItem(this.id);
}
