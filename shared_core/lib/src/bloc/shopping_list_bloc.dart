import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_item.dart';
import '../storage/shopping_item_repository.dart';
import '../storage/shared_storage_sink.dart';
import 'shopping_list_event.dart';
import 'shopping_list_state.dart';

class ShoppingListBloc extends Bloc<ShoppingListEvent, ShoppingListState> {
  final ShoppingItemRepository repository;
  final SharedStorageSink? storageSink;
  final _uuid = const Uuid();

  ShoppingListBloc({required this.repository, this.storageSink})
    : super(ShoppingListLoading()) {
    on<LoadShoppingList>(_onLoadShoppingList);
    on<AddShoppingItem>(_onAddShoppingItem);
    on<DeleteShoppingItem>(_onDeleteShoppingItem);
    on<ToggleItemCompletion>(_onToggleItemCompletion);
  }

  Future<void> _onLoadShoppingList(
    LoadShoppingList event,
    Emitter<ShoppingListState> emit,
  ) async {
    emit(ShoppingListLoading());
    await _refreshList(emit);
  }

  Future<void> _onAddShoppingItem(
    AddShoppingItem event,
    Emitter<ShoppingListState> emit,
  ) async {
    final newItem = ShoppingItem(
      id: _uuid.v4(),
      name: event.name,
      createdAt: DateTime.now(),
    );
    try {
      await repository.insert(newItem);
      await _refreshList(emit);
    } catch (e) {
      emit(ShoppingListFailure(e.toString()));
    }
  }

  Future<void> _onDeleteShoppingItem(
    DeleteShoppingItem event,
    Emitter<ShoppingListState> emit,
  ) async {
    try {
      await repository.delete(event.id);
      await _refreshList(emit);
    } catch (e) {
      emit(ShoppingListFailure(e.toString()));
    }
  }

  Future<void> _onToggleItemCompletion(
    ToggleItemCompletion event,
    Emitter<ShoppingListState> emit,
  ) async {
    if (state is ShoppingListLoaded) {
      final items = (state as ShoppingListLoaded).items;
      try {
        final itemIndex = items.indexWhere((item) => item.id == event.id);
        if (itemIndex != -1) {
          final item = items[itemIndex];
          final updatedItem = item.copyWith(isCompleted: !item.isCompleted);
          await repository.update(updatedItem);
          await _refreshList(emit);
        }
      } catch (e) {
        emit(ShoppingListFailure(e.toString()));
      }
    }
  }

  Future<void> _refreshList(Emitter<ShoppingListState> emit) async {
    try {
      final items = await repository.getAll();
      emit(ShoppingListLoaded(items));
      await storageSink?.syncItems(items);
    } catch (e) {
      emit(ShoppingListFailure(e.toString()));
    }
  }
}
