import SwiftData
import SwiftUI

@main
struct RecipeAppApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(
                for: RecipeModel.self,
                CategoryModel.self,
                IngredientModel.self,
                StepModel.self,
                GroceryItemModel.self,
                MealPlanModel.self,
                PantryItemModel.self
            )
            seedDataIfNeeded(context: container.mainContext)
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(container)
        }
    }
    
    @MainActor
    private func seedDataIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<RecipeModel>()
        let existingRecipes = (try? context.fetch(descriptor)) ?? []
        let hasContinents = existingRecipes.contains { $0.name.contains("Tonkotsu") || $0.name.contains("South Pole") }
        if existingRecipes.isEmpty || !hasContinents {
            // Delete old recipes to avoid duplicates and re-seed cleanly
            for recipe in existingRecipes {
                context.delete(recipe)
            }
            let catDescriptor = FetchDescriptor<CategoryModel>()
            let existingCats = (try? context.fetch(catDescriptor)) ?? []
            for cat in existingCats {
                context.delete(cat)
            }
            try? context.save()
            RecipeModel.insertSampleData(into: context)
        }
    }
}
