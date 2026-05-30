import '../models/shopping_item.dart';

abstract class SharedStorageSink {
  Future<void> syncItems(List<ShoppingItem> items);
}
