import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [CategoryModel]
    @Query private var allRecipes: [RecipeModel]
    
    @State private var searchText: String = ""
    @State private var showFavoritesOnly: Bool = false
    @State private var selectedCategoryFilter: String? = nil
    @State private var showAddRecipeSheet: Bool = false
    @State private var showImporterSheet: Bool = false
    @State private var showCategorySheet: Bool = false
    @State private var randomRecipe: RecipeModel?
    
    var filteredCategories: [(categoryName: String, recipes: [RecipeModel])] {
        var result: [(categoryName: String, recipes: [RecipeModel])] = []
        
        for category in categories {
            if let selectedCategoryFilter, category.name != selectedCategoryFilter {
                continue
            }
            
            let matchingRecipes = category.recipes.filter { recipe in
                if showFavoritesOnly && !recipe.isFavorite {
                    return false
                }
                
                if searchText.isEmpty {
                    return true
                }
                
                let query = searchText.localizedLowercase
                let matchesName = recipe.name.localizedLowercase.contains(query)
                let matchesTag = recipe.tags.contains { $0.localizedLowercase.contains(query) }
                let matchesLocation = recipe.locationName?.localizedLowercase.contains(query) ?? false
                let matchesIngredient = recipe.ingredients.contains { $0.name.localizedLowercase.contains(query) }
                
                return matchesName || matchesTag || matchesLocation || matchesIngredient
            }
            
            if !matchingRecipes.isEmpty {
                result.append((categoryName: category.name, recipes: matchingRecipes))
            }
        }
        
        // Uncategorized recipes
        if selectedCategoryFilter == nil || selectedCategoryFilter == "Uncategorized" {
            let uncategorized = allRecipes.filter { $0.category == nil }.filter { recipe in
                if showFavoritesOnly && !recipe.isFavorite {
                    return false
                }
                
                if searchText.isEmpty {
                    return true
                }
                
                let query = searchText.localizedLowercase
                let matchesName = recipe.name.localizedLowercase.contains(query)
                let matchesTag = recipe.tags.contains { $0.localizedLowercase.contains(query) }
                let matchesLocation = recipe.locationName?.localizedLowercase.contains(query) ?? false
                let matchesIngredient = recipe.ingredients.contains { $0.name.localizedLowercase.contains(query) }
                
                return matchesName || matchesTag || matchesLocation || matchesIngredient
            }
            
            if !uncategorized.isEmpty {
                result.append((categoryName: "Uncategorized", recipes: uncategorized))
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedCategoryFilter == nil) {
                            selectedCategoryFilter = nil
                        }
                        
                        ForEach(categories) { category in
                            FilterChip(title: category.name, isSelected: selectedCategoryFilter == category.name) {
                                if selectedCategoryFilter == category.name {
                                    selectedCategoryFilter = nil
                                } else {
                                    selectedCategoryFilter = category.name
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                List {
                    if filteredCategories.isEmpty {
                        ContentUnavailableView(
                            "No Recipes Found",
                            systemImage: "fork.knife.circle",
                            description: Text(searchText.isEmpty ? "Try adding a new recipe or adjusting your filters." : "No recipes match '\(searchText)'.")
                        )
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(filteredCategories, id: \.categoryName) { section in
                            Section(section.categoryName) {
                                ForEach(section.recipes) { recipe in
                                    NavigationLink {
                                        RecipeDetailView(recipe: recipe)
                                    } label: {
                                        HStack(spacing: 12) {
                                            Image(uiImage: recipe.viewImageWithDefault)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(recipe.name)
                                                    .font(.title3.weight(.bold))
                                                
                                                HStack(spacing: 8) {
                                                    Label("\(recipe.totalTimeMinutes)m", systemImage: "clock")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    
                                                    Label("\(recipe.servingSize)", systemImage: "person.2")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    
                                                    if let locationName = recipe.locationName, !locationName.isEmpty {
                                                        Label(locationName, systemImage: "mappin.circle.fill")
                                                            .font(.caption)
                                                            .foregroundColor(.red)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                
                                                if !recipe.tags.isEmpty {
                                                    HStack(spacing: 4) {
                                                        ForEach(recipe.tags.prefix(3), id: \.self) { tag in
                                                            Text("#\(tag)")
                                                                .font(.caption2)
                                                                .padding(.horizontal, 6)
                                                                .padding(.vertical, 2)
                                                                .background(Color.accentColor.opacity(0.12))
                                                                .clipShape(Capsule())
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            // Favorite Toggle Button
                                            Button {
                                                recipe.isFavorite.toggle()
                                            } label: {
                                                Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                                                    .foregroundColor(recipe.isFavorite ? .red : .gray.opacity(0.5))
                                                    .font(.title3)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        modelContext.delete(section.recipes[index])
                                    }
                                }
                            }
                        }
                    }
                }
                .listRowBackground(Color.primary.opacity(0.05))
            }
            .navigationTitle("Recipes")
            .headerProminence(.increased)
            .searchable(text: $searchText, prompt: "Search recipes, ingredients, tags, or locations...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showCategorySheet = true
                    } label: {
                        Image(systemName: "folder.badge.gearshape")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            if let random = allRecipes.randomElement() {
                                randomRecipe = random
                            }
                        } label: {
                            Image(systemName: "dice.fill")
                                .foregroundColor(.purple)
                        }
                        
                        Button {
                            showImporterSheet = true
                        } label: {
                            Image(systemName: "globe.badge.chevron.backward")
                        }
                        
                        Button {
                            showFavoritesOnly.toggle()
                        } label: {
                            Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                                .foregroundColor(showFavoritesOnly ? .red : .primary)
                        }
                        
                        Button {
                            showAddRecipeSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddRecipeSheet) {
                AddRecipeView()
            }
            .sheet(isPresented: $showImporterSheet) {
                RecipeImporterView()
            }
            .sheet(isPresented: $showCategorySheet) {
                CategoryManagementView()
            }
            .sheet(item: $randomRecipe) { recipe in
                NavigationStack {
                    RecipeDetailView(recipe: recipe)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Close") {
                                    randomRecipe = nil
                                }
                            }
                        }
                }
            }
            .scrollContentBackground(.hidden)
            .background(.regularMaterial)
            .background {
                Image("RecipeApp")
                    .opacity(0.5)
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .bold : .medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accentColor : Color.primary.opacity(0.08))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(RecipeModel.preview)
}
