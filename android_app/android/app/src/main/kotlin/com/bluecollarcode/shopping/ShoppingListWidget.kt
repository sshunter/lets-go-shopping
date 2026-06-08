package com.bluecollarcode.shopping

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionSendBroadcast
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.*
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetBackgroundReceiver
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import org.json.JSONArray

// PantryPalooza palette
private val slateBlue = Color(0xFF3D5F8F)
private val mossGreen = Color(0xFF556347)
private val nearBlack = Color(0xFF151514)
private val warmOffWhite = Color(0xFFF2F0E8)

class ShoppingListWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<HomeWidgetGlanceState>().preferences
            val shoppingListJson = prefs.getString("shopping_list", "[]")
            val items = parseItems(shoppingListJson)
            GlanceTheme {
                ShoppingListContent(context, items)
            }
        }
    }

    @Composable
    private fun ShoppingListContent(context: Context, items: List<ShoppingItem>) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(warmOffWhite)
                .padding(8.dp)
        ) {
            Text(
                text = "Shopping List",
                style = TextStyle(
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp,
                    color = ColorProvider(slateBlue)
                ),
                modifier = GlanceModifier.padding(bottom = 8.dp)
            )

            if (items.isEmpty()) {
                Box(modifier = GlanceModifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(text = "Empty list", style = TextStyle(color = ColorProvider(Color.Gray)))
                }
            } else {
                LazyColumn(modifier = GlanceModifier.fillMaxSize()) {
                    items(items) { item ->
                        ShoppingItemRow(context, item)
                    }
                }
            }
        }
    }

    @Composable
    private fun ShoppingItemRow(context: Context, item: ShoppingItem) {
        val intent = Intent(context, HomeWidgetBackgroundReceiver::class.java).apply {
            data = Uri.parse("homeWidgetExample://toggle?id=${item.id}")
            action = "es.antonborri.home_widget.action.BACKGROUND"
        }
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .padding(vertical = 4.dp)
                .clickable(
                    onClick = actionSendBroadcast(intent)
                ),
            verticalAlignment = Alignment.CenterVertically
        ) {
            val checkboxText = if (item.isCompleted) "☑" else "☐"
            val checkboxColor = if (item.isCompleted) mossGreen else slateBlue
            Text(
                text = checkboxText,
                style = TextStyle(fontSize = 20.sp, color = ColorProvider(checkboxColor)),
                modifier = GlanceModifier.padding(end = 8.dp)
            )
            Text(
                text = item.name,
                style = TextStyle(
                    fontSize = 16.sp,
                    color = ColorProvider(if (item.isCompleted) Color.Gray else nearBlack)
                )
            )
        }
    }

    private fun parseItems(json: String?): List<ShoppingItem> {
        if (json.isNullOrEmpty() || json == "null") return emptyList()
        return try {
            val list = mutableListOf<ShoppingItem>()
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                list.add(
                    ShoppingItem(
                        id = obj.getString("id"),
                        name = obj.getString("name"),
                        isCompleted = obj.getBoolean("isCompleted")
                    )
                )
            }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }

    data class ShoppingItem(val id: String, val name: String, val isCompleted: Boolean)
}

@Composable
fun GlanceTheme(content: @Composable () -> Unit) {
    // Simple theme wrapper, can be expanded
    content()
}
