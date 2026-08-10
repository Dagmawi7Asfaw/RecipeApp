import SwiftData
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Recipes", systemImage: "fork.knife.circle.fill")
                }
                .tag(0)
            
            WorldMapExplorerView()
                .tabItem {
                    Label("World Atlas", systemImage: "globe.americas.fill")
                }
                .tag(1)
            
            GroceryListView()
                .tabItem {
                    Label("Groceries", systemImage: "cart.fill")
                }
                .tag(2)
            
            MealPlannerView()
                .tabItem {
                    Label("Planner", systemImage: "calendar.badge.clock")
                }
                .tag(3)
            
            PantryView()
                .tabItem {
                    Label("Pantry", systemImage: "refrigerator.fill")
                }
                .tag(4)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(RecipeModel.preview)
}
