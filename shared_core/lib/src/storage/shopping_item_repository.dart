import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/shopping_item.dart';

abstract class ShoppingItemRepository {
  Future<List<ShoppingItem>> getAll();
  Future<void> insert(ShoppingItem item);
  Future<void> update(ShoppingItem item);
  Future<void> delete(String id);
}

class SQLiteShoppingItemRepository implements ShoppingItemRepository {
  static const String tableName = 'shopping_items';
  final Database database;

  SQLiteShoppingItemRepository(this.database);

  static Future<SQLiteShoppingItemRepository> init(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
    return SQLiteShoppingItemRepository(database);
  }

  @override
  Future<List<ShoppingItem>> getAll() async {
    final maps = await database.query(tableName, orderBy: 'createdAt DESC');
    return maps
        .map(
          (map) => ShoppingItem.fromJson({
            ...map,
            'isCompleted': map['isCompleted'] == 1,
          }),
        )
        .toList();
  }

  @override
  Future<void> insert(ShoppingItem item) async {
    await database.insert(tableName, {
      ...item.toJson(),
      'isCompleted': item.isCompleted ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> update(ShoppingItem item) async {
    await database.update(
      tableName,
      {...item.toJson(), 'isCompleted': item.isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await database.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
