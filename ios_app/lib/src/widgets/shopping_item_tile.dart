import 'package:flutter/cupertino.dart';
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
    return CupertinoListTile(
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onToggle,
        child: Icon(
          item.isCompleted
              ? CupertinoIcons.check_mark_circled_solid
              : CupertinoIcons.circle,
        ),
      ),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
          color: item.isCompleted
              ? CupertinoColors.secondaryLabel
              : CupertinoColors.label,
        ),
      ),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onDelete,
        child: const Icon(
          CupertinoIcons.delete,
          color: CupertinoColors.destructiveRed,
        ),
      ),
    );
  }
}
