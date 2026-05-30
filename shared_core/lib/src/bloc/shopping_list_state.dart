import '../models/shopping_item.dart';

sealed class ShoppingListState {}

class ShoppingListLoading extends ShoppingListState {}

class ShoppingListLoaded extends ShoppingListState {
  final List<ShoppingItem> items;
  ShoppingListLoaded(this.items);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingListLoaded &&
          runtimeType == other.runtimeType &&
          items.length == other.items.length &&
          items.every((item) => other.items.contains(item));

  @override
  int get hashCode => items.hashCode;
}

class ShoppingListFailure extends ShoppingListState {
  final String message;
  ShoppingListFailure(this.message);
}
