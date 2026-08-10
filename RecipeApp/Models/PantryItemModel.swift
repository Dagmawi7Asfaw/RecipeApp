import Foundation
import SwiftData

@Model
class PantryItemModel {
    var id: UUID = UUID()
    var name: String
    var category: String
    var inStock: Bool = true
    var dateUpdated: Date = Date()
    
    init(name: String, category: String = "Pantry", inStock: Bool = true) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.inStock = inStock
        self.dateUpdated = Date()
    }
}

extension PantryItemModel {
    static let defaultStaples: [(name: String, category: String)] = [
        ("Olive Oil", "Oils & Vinegars"),
        ("Vegetable Oil", "Oils & Vinegars"),
        ("Butter", "Dairy & Refrigerated"),
        ("Eggs", "Dairy & Refrigerated"),
        ("Milk", "Dairy & Refrigerated"),
        ("Garlic", "Fresh Produce"),
        ("Yellow Onions", "Fresh Produce"),
        ("Red Onions", "Fresh Produce"),
        ("Lemons", "Fresh Produce"),
        ("Salt", "Spices & Seasonings"),
        ("Black Pepper", "Spices & Seasonings"),
        ("Berbere Spice", "Spices & Seasonings"),
        ("Cumin", "Spices & Seasonings"),
        ("All-Purpose Flour", "Baking & Grains"),
        ("White Sugar", "Baking & Grains"),
        ("Rice", "Baking & Grains"),
        ("Spaghetti Pasta", "Baking & Grains"),
        ("Chicken Broth", "Canned & Pantry"),
        ("Canned Crushed Tomatoes", "Canned & Pantry"),
        ("Chickpeas", "Canned & Pantry"),
        ("Niter Kibbeh (Spiced Butter)", "Specialty")
    ]
}
