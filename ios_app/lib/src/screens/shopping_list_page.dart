import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_core/shared_core.dart';
import '../widgets/add_item_bar.dart';
import '../widgets/shopping_item_tile.dart';

class ShoppingListPage extends StatelessWidget {
  const ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Shopping List'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocListener<ShoppingListBloc, ShoppingListState>(
                listener: (context, state) {
                  if (state is ShoppingListFailure) {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('Error'),
                        content: Text(state.message),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: BlocBuilder<ShoppingListBloc, ShoppingListState>(
                  builder: (context, state) {
                    if (state is ShoppingListLoading) {
                      return const Center(child: CupertinoActivityIndicator());
                    } else if (state is ShoppingListLoaded) {
                      if (state.items.isEmpty) {
                        return const Center(
                          child: Text('Your shopping list is empty!'),
                        );
                      }
                      return CupertinoListSection.insetGrouped(
                        children: state.items.map((item) {
                          return ShoppingItemTile(
                            item: item,
                            onDelete: () => context
                                .read<ShoppingListBloc>()
                                .add(DeleteShoppingItem(item.id)),
                            onToggle: () => context
                                .read<ShoppingListBloc>()
                                .add(ToggleItemCompletion(item.id)),
                          );
                        }).toList(),
                      );
                    } else if (state is ShoppingListFailure) {
                      return Center(child: Text('Error: ${state.message}'));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            AddItemBar(
              onAdd: (name) =>
                  context.read<ShoppingListBloc>().add(AddShoppingItem(name)),
            ),
          ],
        ),
      ),
    );
  }
}
