import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_flutter/shared_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'src/screens/shopping_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final database = await openDatabase(
    join(await getDatabasesPath(), 'shopping_list.db'),
  );
  
  final repository = await SQLiteShoppingItemRepository.init(database);

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final ShoppingItemRepository repository;

  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ShoppingListScope(
        repository: repository,
        child: const ShoppingListPage(),
      ),
    );
  }
}
