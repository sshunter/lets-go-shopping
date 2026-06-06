import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:shared_core/shared_core.dart';

class HomeWidgetStorageSink implements SharedStorageSink {
  static const String _groupId = 'group.com.bluecollarcode.shopping';
  static const String _dataKey = 'shopping_list';
  static const String _widgetName = 'ShoppingListWidgetReceiver';

  HomeWidgetStorageSink() {
    HomeWidget.setAppGroupId(_groupId);
  }

  @override
  Future<void> syncItems(List<ShoppingItem> items) async {
    final jsonItems = items
        .map((item) => {
              'id': item.id,
              'name': item.name,
              'isCompleted': item.isCompleted,
            })
        .toList();

    await HomeWidget.saveWidgetData(_dataKey, jsonEncode(jsonItems));
    await HomeWidget.updateWidget(name: _widgetName);
  }
}
