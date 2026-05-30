import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_core/shared_core.dart';
import '../widgets/add_item_bar.dart';
import '../widgets/shopping_item_tile.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocListener<ShoppingListBloc, ShoppingListState>(
              listener: (context, state) {
                if (state is ShoppingListFailure) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              child: BlocBuilder<ShoppingListBloc, ShoppingListState>(
                builder: (context, state) {
                  if (state is ShoppingListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ShoppingListLoaded) {
                    if (state.items.isEmpty) {
                      return const Center(
                        child: Text('Your shopping list is empty!'),
                      );
                    }
                    return ListView.builder(
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return ShoppingItemTile(
                          item: item,
                          onDelete: () => context.read<ShoppingListBloc>().add(
                            DeleteShoppingItem(item.id),
                          ),
                          onToggle: () => context.read<ShoppingListBloc>().add(
                            ToggleItemCompletion(item.id),
                          ),
                        );
                      },
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
    );
  }
}
