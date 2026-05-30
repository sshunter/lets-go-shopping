import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), items: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), items: loadItems())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date(), items: loadItems())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func loadItems() -> [ShoppingItem] {
        let userDefaults = UserDefaults(suiteName: "group.com.bluecollarcode.shopping.list")
        guard let jsonString = userDefaults?.string(forKey: "shopping_items_json"),
              let data = jsonString.data(using: .utf8) else {
            return []
        }
        do {
            return try JSONDecoder().decode([ShoppingItem].self, from: data)
        } catch {
            return []
        }
    }
}

struct ShoppingItem: Codable, Identifiable {
    let id: String
    let name: String
    let isCompleted: Bool
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let items: [ShoppingItem]
}

struct ShoppingWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Shopping List")
                .font(.headline)
            if entry.items.isEmpty {
                Text("Your shopping list is empty!")
                    .font(.caption)
            } else {
                ForEach(entry.items.prefix(3)) { item in
                    Button(intent: ToggleItemIntent(id: item.id)) {
                        HStack {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            Text(item.name)
                                .strikethrough(item.isCompleted)
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                }
            }
        }
    }
}

struct ShoppingWidget: Widget {
    let kind: String = "ShoppingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ShoppingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Shopping List")
        .description("View and check off your shopping items.")
        .supportedFamilies([.accessoryRectangular, .systemSmall])
    }
}
