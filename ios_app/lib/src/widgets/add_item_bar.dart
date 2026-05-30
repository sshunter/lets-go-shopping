import 'package:flutter/cupertino.dart';

class AddItemBar extends StatefulWidget {
  final Function(String) onAdd;

  const AddItemBar({super.key, required this.onAdd});

  @override
  State<AddItemBar> createState() => _AddItemBarState();
}

class _AddItemBarState extends State<AddItemBar> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && text.length <= 100) {
      widget.onAdd(text);
      _controller.clear();
    } else if (text.isEmpty) {
      // In a real app, maybe show a toast or change border color
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _controller,
              placeholder: 'Add an item...',
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _submit,
            child: const Icon(CupertinoIcons.add_circled_solid),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
