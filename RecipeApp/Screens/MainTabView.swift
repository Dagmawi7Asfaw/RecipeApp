import SwiftData
import SwiftUI

struct MainTabView: View {
    @Query private var allGroceryItems: [GroceryItemModel]
    @State private var selectedTab: Int = 0

    var uncheckedGroceryCount: Int {
        allGroceryItems.filter { !$0.isChecked }.count
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Recipes", systemImage: selectedTab == 0 ? "fork.knife.circle.fill" : "fork.knife.circle")
                }
                .tag(0)

            WorldMapExplorerView()
                .tabItem {
                    Label("World Atlas", systemImage: selectedTab == 1 ? "globe.americas.fill" : "globe.americas")
                }
                .tag(1)

            GroceryListView()
                .tabItem {
                    Label("Groceries", systemImage: selectedTab == 2 ? "cart.fill" : "cart")
                }
                .badge(uncheckedGroceryCount > 0 ? uncheckedGroceryCount : 0)
                .tag(2)

            MealPlannerView()
                .tabItem {
                    Label("Planner", systemImage: selectedTab == 3 ? "calendar.badge.clock" : "calendar")
                }
                .tag(3)

            PantryView()
                .tabItem {
                    Label("Pantry", systemImage: selectedTab == 4 ? "refrigerator.fill" : "refrigerator")
                }
                .tag(4)
        }
        .tint(.accentColor)
    }
}

#Preview {
    MainTabView()
        .modelContainer(RecipeModel.preview)
}
