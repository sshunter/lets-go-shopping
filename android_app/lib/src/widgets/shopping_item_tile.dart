import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(value: item.isCompleted, onChanged: (_) => onToggle()),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
    );
  }
}
