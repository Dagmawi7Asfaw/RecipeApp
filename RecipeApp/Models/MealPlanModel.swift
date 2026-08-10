import Foundation
import SwiftData

@Model
class MealPlanModel {
    var id: UUID = UUID()
    var date: Date
    var mealType: String // "Breakfast", "Lunch", "Dinner", "Snack"
    var recipe: RecipeModel?
    var customNotes: String?
    
    init(date: Date = Date(),
         mealType: String = "Dinner",
         recipe: RecipeModel? = nil,
         customNotes: String? = nil) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.mealType = mealType
        self.recipe = recipe
        self.customNotes = customNotes
    }
}

extension MealPlanModel {
    static let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    var title: String {
        recipe?.name ?? customNotes ?? "Planned Meal"
    }
}
