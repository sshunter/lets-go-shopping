import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_core/shared_core.dart';
import 'package:test/test.dart';

class MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

class MockSharedStorageSink extends Mock implements SharedStorageSink {}

void main() {
  late ShoppingItemRepository repository;
  late SharedStorageSink storageSink;
  late ShoppingListBloc bloc;

  setUp(() {
    repository = MockShoppingItemRepository();
    storageSink = MockSharedStorageSink();
    bloc = ShoppingListBloc(repository: repository, storageSink: storageSink);

    registerFallbackValue(const <ShoppingItem>[]);
    registerFallbackValue(
      ShoppingItem(id: '0', name: 'placeholder', createdAt: DateTime.now()),
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('ShoppingListBloc', () {
    test('initial state is ShoppingListLoading', () {
      expect(bloc.state, isA<ShoppingListLoading>());
    });

    blocTest<ShoppingListBloc, ShoppingListState>(
      'emits [ShoppingListLoading, ShoppingListLoaded([])] when LoadShoppingList is added',
      build: () {
        when(() => repository.getAll()).thenAnswer((_) async => []);
        when(() => storageSink.syncItems(any())).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(LoadShoppingList()),
      expect: () => [isA<ShoppingListLoading>(), ShoppingListLoaded([])],
      verify: (_) {
        verify(() => repository.getAll()).called(1);
        verify(() => storageSink.syncItems([])).called(1);
      },
    );

    blocTest<ShoppingListBloc, ShoppingListState>(
      'emits [ShoppingListLoaded] with new item when AddShoppingItem is added',
      build: () {
        when(() => repository.insert(any())).thenAnswer((_) async {});
        when(() => repository.getAll()).thenAnswer(
          (_) async => [
            ShoppingItem(id: '1', name: 'Apples', createdAt: DateTime.now()),
          ],
        );
        when(() => storageSink.syncItems(any())).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(AddShoppingItem('Apples')),
      expect: () => [
        isA<ShoppingListLoaded>().having(
          (s) => s.items,
          'items',
          contains(isA<ShoppingItem>().having((i) => i.name, 'name', 'Apples')),
        ),
      ],
      verify: (_) {
        verify(
          () => repository.insert(
            any(
              that: isA<ShoppingItem>().having((i) => i.name, 'name', 'Apples'),
            ),
          ),
        ).called(1);
        verify(() => storageSink.syncItems(any())).called(1);
      },
    );

    blocTest<ShoppingListBloc, ShoppingListState>(
      'emits [ShoppingListLoaded] with empty list when DeleteShoppingItem is added',
      build: () {
        when(() => repository.delete(any())).thenAnswer((_) async {});
        when(() => repository.getAll()).thenAnswer((_) async => []);
        when(() => storageSink.syncItems(any())).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(DeleteShoppingItem('1')),
      expect: () => [ShoppingListLoaded([])],
      verify: (_) {
        verify(() => repository.delete('1')).called(1);
        verify(() => storageSink.syncItems([])).called(1);
      },
    );
    blocTest<ShoppingListBloc, ShoppingListState>(
      'emits [ShoppingListLoaded] with two items when AddShoppingItem is added twice',
      build: () {
        final items = [];
        when(() => repository.insert(any())).thenAnswer((invocation) async {
          items.add(invocation.positionalArguments[0] as ShoppingItem);
        });
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => List<ShoppingItem>.from(items));
        when(() => storageSink.syncItems(any())).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc
        ..add(AddShoppingItem('Apples'))
        ..add(AddShoppingItem('Apples')),
      expect: () => [
        isA<ShoppingListLoaded>().having((s) => s.items, 'items', hasLength(1)),
        isA<ShoppingListLoaded>().having((s) => s.items, 'items', hasLength(2)),
      ],
      verify: (_) {
        final captured = verify(() => repository.insert(captureAny())).captured;
        expect(captured, hasLength(2));
        expect(
          (captured[0] as ShoppingItem).id,
          isNot((captured[1] as ShoppingItem).id),
        );
      },
    );
    blocTest<ShoppingListBloc, ShoppingListState>(
      'emits [ShoppingListLoaded] with toggled item when ToggleItemCompletion is added',
      build: () {
        final item = ShoppingItem(
          id: '1',
          name: 'Apples',
          isCompleted: false,
          createdAt: DateTime.now(),
        );
        when(() => repository.update(any())).thenAnswer((_) async {});
        when(
          () => repository.getAll(),
        ).thenAnswer((_) async => [item.copyWith(isCompleted: true)]);
        when(() => storageSink.syncItems(any())).thenAnswer((_) async {});
        return bloc;
      },
      seed: () => ShoppingListLoaded([
        ShoppingItem(
          id: '1',
          name: 'Apples',
          isCompleted: false,
          createdAt: DateTime.now(),
        ),
      ]),
      act: (bloc) => bloc.add(ToggleItemCompletion('1')),
      expect: () => [
        isA<ShoppingListLoaded>().having(
          (s) => s.items,
          'items',
          contains(
            isA<ShoppingItem>().having(
              (i) => i.isCompleted,
              'isCompleted',
              true,
            ),
          ),
        ),
      ],
      verify: (_) {
        verify(
          () => repository.update(
            any(
              that: isA<ShoppingItem>().having(
                (i) => i.isCompleted,
                'isCompleted',
                true,
              ),
            ),
          ),
        ).called(1);
      },
    );
  });
}
