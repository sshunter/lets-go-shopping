import 'package:shared_core/shared_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

void main() {
  late Database database;
  late SQLiteShoppingItemRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    repository = await SQLiteShoppingItemRepository.init(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('getAll returns an empty list initially', () async {
    final items = await repository.getAll();
    expect(items, isEmpty);
  });

  test('insert then getAll returns the item', () async {
    final item = ShoppingItem(
      id: '1',
      name: 'Apples',
      createdAt: DateTime.now(),
    );
    await repository.insert(item);
    final items = await repository.getAll();
    expect(items, hasLength(1));
    expect(items.first.name, 'Apples');
  });

  test('delete then getAll returns empty', () async {
    final item = ShoppingItem(
      id: '1',
      name: 'Apples',
      createdAt: DateTime.now(),
    );
    await repository.insert(item);
    await repository.delete('1');
    final items = await repository.getAll();
    expect(items, isEmpty);
  });
  test('update flips isCompleted', () async {
    final item = ShoppingItem(
      id: '1',
      name: 'Apples',
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    await repository.insert(item);
    await repository.update(item.copyWith(isCompleted: true));
    final items = await repository.getAll();
    expect(items.first.isCompleted, isTrue);
  });
}
