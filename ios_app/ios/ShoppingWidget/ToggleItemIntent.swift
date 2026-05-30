import AppIntents
import WidgetKit

struct ToggleItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Shopping Item"
    static var description = IntentDescription("Toggles the completion status of a shopping item.")

    @Parameter(title: "Item ID")
    var id: String

    init() {}
    init(id: String) {
        self.id = id
    }

    func perform() async throws -> some IntentResult {
        let userDefaults = UserDefaults(suiteName: "group.com.bluecollarcode.shopping.list")
        if let jsonString = userDefaults?.string(forKey: "shopping_items_json"),
           let data = jsonString.data(using: .utf8) {
            do {
                var items = try JSONDecoder().decode([ShoppingItem].self, from: data)
                if let index = items.firstIndex(where: { $0.id == id }) {
                    let item = items[index]
                    items[index] = ShoppingItem(id: item.id, name: item.name, isCompleted: !item.isCompleted)
                    let updatedData = try JSONEncoder().encode(items)
                    if let updatedJson = String(data: updatedData, encoding: .utf8) {
                        userDefaults?.set(updatedJson, forKey: "shopping_items_json")
                    }
                }
            } catch {
                // Handle error
            }
        }
        
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
