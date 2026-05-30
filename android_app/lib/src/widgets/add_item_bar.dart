import 'package:flutter/material.dart';

class AddItemBar extends StatefulWidget {
  final Function(String) onAdd;

  const AddItemBar({super.key, required this.onAdd});

  @override
  State<AddItemBar> createState() => _AddItemBarState();
}

class _AddItemBarState extends State<AddItemBar> {
  final _controller = TextEditingController();

  String? _errorText;

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'Name cannot be empty');
      return;
    }
    if (text.length > 100) {
      setState(() => _errorText = 'Name too long (max 100)');
      return;
    }

    setState(() => _errorText = null);
    widget.onAdd(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Add an item...',
                    border: const OutlineInputBorder(),
                    errorText: _errorText,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _submit,
                icon: const Icon(Icons.add),
              ),
            ],
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
