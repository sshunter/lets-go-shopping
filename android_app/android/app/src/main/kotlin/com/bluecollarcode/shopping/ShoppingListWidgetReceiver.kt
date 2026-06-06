package com.bluecollarcode.shopping

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class ShoppingListWidgetReceiver : HomeWidgetGlanceWidgetReceiver<ShoppingListWidget>() {
    override val glanceAppWidget: ShoppingListWidget = ShoppingListWidget()
}
