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
    
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .modelContainer(container)
                    .opacity(showSplash ? 0 : 1)
                
                if showSplash {
                    SplashScreenView {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                }
            }
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
