import Foundation
import SwiftData

@Model
class GroceryItemModel {
    var id: UUID = UUID()
    var name: String
    var quantity: String
    var category: String // Aisle: "Produce", "Dairy & Eggs", "Meat & Seafood", "Bakery", "Pantry", "Spices & Seasonings", "Frozen", "Other"
    var isChecked: Bool = false
    var dateAdded: Date = Date()
    var recipeName: String?
    
    init(name: String,
         quantity: String = "",
         category: String = "Other",
         isChecked: Bool = false,
         dateAdded: Date = Date(),
         recipeName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.category = category
        self.isChecked = isChecked
        self.dateAdded = dateAdded
        self.recipeName = recipeName
    }
}

extension GroceryItemModel {
    static let aisles = [
        "Produce",
        "Dairy & Eggs",
        "Meat & Seafood",
        "Bakery",
        "Pantry",
        "Spices & Seasonings",
        "Frozen",
        "Other"
    ]
    
    static func autoCategorize(ingredientName: String) -> String {
        let lower = ingredientName.lowercased()
        
        if lower.contains("onion") || lower.contains("garlic") || lower.contains("tomato") ||
           lower.contains("lemon") || lower.contains("herb") || lower.contains("spinach") ||
           lower.contains("potato") || lower.contains("carrot") || lower.contains("apple") ||
           lower.contains("strawberry") || lower.contains("pepper") || lower.contains("basil") ||
           lower.contains("rosemary") || lower.contains("ginger") || lower.contains("mushroom") {
            return "Produce"
        }
        
        if lower.contains("milk") || lower.contains("butter") || lower.contains("cheese") ||
           lower.contains("egg") || lower.contains("cream") || lower.contains("yogurt") ||
           lower.contains("ayib") || lower.contains("parmesan") || lower.contains("mozzarella") {
            return "Dairy & Eggs"
        }
        
        if lower.contains("chicken") || lower.contains("beef") || lower.contains("salmon") ||
           lower.contains("lobster") || lower.contains("meat") || lower.contains("pork") ||
           lower.contains("steak") || lower.contains("lamb") || lower.contains("fish") {
            return "Meat & Seafood"
        }
        
        if lower.contains("bread") || lower.contains("bun") || lower.contains("crust") ||
           lower.contains("tortilla") || lower.contains("injera") || lower.contains("croissant") {
            return "Bakery"
        }
        
        if lower.contains("berbere") || lower.contains("salt") || lower.contains("pepper") ||
           lower.contains("cumin") || lower.contains("cinnamon") || lower.contains("turmeric") ||
           lower.contains("paprika") || lower.contains("oregano") || lower.contains("spice") ||
           lower.contains("cardamom") || lower.contains("nutmeg") {
            return "Spices & Seasonings"
        }
        
        if lower.contains("flour") || lower.contains("sugar") || lower.contains("oil") ||
           lower.contains("rice") || lower.contains("pasta") || lower.contains("sauce") ||
           lower.contains("broth") || lower.contains("stock") || lower.contains("bean") ||
           lower.contains("chickpea") || lower.contains("shiro") || lower.contains("niter kibbeh") ||
           lower.contains("vinegar") || lower.contains("honey") || lower.contains("spaghetti") {
            return "Pantry"
        }
        
        return "Other"
    }
}
