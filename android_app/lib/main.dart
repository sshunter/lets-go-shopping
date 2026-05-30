import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart';
import 'package:shared_core/shared_core.dart';
import 'package:sqflite/sqflite.dart';
import 'src/screens/shopping_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: BlocProvider.value(
        value: _bloc,
        child: const ShoppingListScreen(),
      ),
    );
  }
}
