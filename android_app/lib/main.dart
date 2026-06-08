import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path/path.dart';
import 'package:shared_core/shared_core.dart';
import 'package:sqflite/sqflite.dart';
import 'src/screens/shopping_list_screen.dart';
import 'src/theme/app_theme.dart';
import 'src/widgets/home_widget_storage_sink.dart';

@pragma('vm:entry-point')
Future<void> homeWidgetInteractivityCallback(Uri? uri) async {
  if (uri?.host == 'toggle') {
    final itemId = uri?.queryParameters['id'];
    if (itemId != null) {
      final database = await openDatabase(
        join(await getDatabasesPath(), 'shopping_list.db'),
      );
      final repository = await SQLiteShoppingItemRepository.init(database);
      final items = await repository.getAll();
      final itemIndex = items.indexWhere((item) => item.id == itemId);

      if (itemIndex != -1) {
        final item = items[itemIndex];
        final updatedItem = item.copyWith(isCompleted: !item.isCompleted);
        await repository.update(updatedItem);

        // Sync back to home widget
        final updatedItems = await repository.getAll();
        final jsonItems = updatedItems
            .map((item) => {
                  'id': item.id,
                  'name': item.name,
                  'isCompleted': item.isCompleted,
                })
            .toList();

        await HomeWidget.saveWidgetData('shopping_list', jsonEncode(jsonItems));
        await HomeWidget.updateWidget(name: 'ShoppingListWidgetReceiver');
      }
      // Do NOT close the database. sqflite uses a process-level singleton for
      // database connections, shared across all Flutter engines in the same
      // process. Closing here would close the main app's connection too.
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HomeWidget.registerInteractivityCallback(homeWidgetInteractivityCallback);

  final database = await openDatabase(
    join(await getDatabasesPath(), 'shopping_list.db'),
  );
  print('App Database path: ${database.path}');

  final repository = await SQLiteShoppingItemRepository.init(database);

  runApp(MyApp(repository: repository));
}

class MyApp extends StatefulWidget {
  final ShoppingItemRepository repository;

  const MyApp({super.key, required this.repository});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late ShoppingListBloc _bloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bloc = ShoppingListBloc(
      repository: widget.repository,
      storageSink: HomeWidgetStorageSink(),
    )..add(LoadShoppingList());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _bloc.add(LoadShoppingList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping List',
      theme: AppTheme.light,
      home: BlocProvider.value(
        value: _bloc,
        child: const ShoppingListScreen(),
      ),
    );
  }
}
