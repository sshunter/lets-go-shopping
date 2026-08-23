import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_core/shared_core.dart';

/// Platform-neutral app shell that owns a [ShoppingListBloc] lifecycle.
///
/// Both the Android and iOS frontends embed this widget inside their own
/// platform-specific root ([MaterialApp]/[CupertinoApp]). The scope creates a
/// [ShoppingListBloc], dispatches the initial list load, provides the bloc to
/// [child] via [BlocProvider], reloads the list when the application resumes,
/// and closes the bloc when disposed. It does not impose any presentation on
/// its child.
class ShoppingListScope extends StatefulWidget {
  final ShoppingItemRepository repository;
  final SharedStorageSink? storageSink;
  final Widget child;

  const ShoppingListScope({
    super.key,
    required this.repository,
    this.storageSink,
    required this.child,
  });

  @override
  State<ShoppingListScope> createState() => _ShoppingListScopeState();
}

class _ShoppingListScopeState extends State<ShoppingListScope>
    with WidgetsBindingObserver {
  late final ShoppingListBloc _bloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bloc = ShoppingListBloc(
      repository: widget.repository,
      storageSink: widget.storageSink,
    )..add(LoadShoppingList());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _bloc.add(LoadShoppingList());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: widget.child,
    );
  }
}