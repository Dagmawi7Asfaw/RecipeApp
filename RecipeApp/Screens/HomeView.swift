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
    @State private var showSurpriseMeSheet: Bool = false
    
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
                            showSurpriseMeSheet = true
                        } label: {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(
                                    LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
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
            .sheet(isPresented: $showSurpriseMeSheet) {
                SurpriseMeView(allRecipes: allRecipes)
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

// MARK: - "What Should I Cook?" Decision Assistant

struct SurpriseMeView: View {
    let allRecipes: [RecipeModel]
    @Environment(\.dismiss) private var dismiss
    
    // Filter state
    @State private var selectedTimeRange: TimeRange = .any
    @State private var selectedCuisine: String = "Any"
    @State private var selectedDietary: String = "Any"
    @State private var favoritesOnly: Bool = false
    
    // Result state
    @State private var revealedRecipe: RecipeModel?
    @State private var isRevealing: Bool = false
    @State private var cardOffset: CGFloat = 600
    @State private var cardRotation: Double = 12
    @State private var cardOpacity: Double = 0
    @State private var showConfetti: Bool = false
    @State private var navigateToRecipe: Bool = false
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case any = "Any Time"
        case quick = "Under 30 min"
        case medium = "30–60 min"
        case long = "Over 1 hour"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .any: return "infinity"
            case .quick: return "bolt.fill"
            case .medium: return "timer"
            case .long: return "clock.fill"
            }
        }
    }
    
    var availableCuisines: [String] {
        let cats = Set(allRecipes.compactMap { $0.category?.name })
        return ["Any"] + cats.sorted()
    }
    
    var availableDietary: [String] {
        let prefs = Set(allRecipes.flatMap { $0.dietaryPreferences })
        return ["Any"] + prefs.sorted()
    }
    
    var candidateRecipes: [RecipeModel] {
        allRecipes.filter { recipe in
            // Time filter
            let totalTime = recipe.totalTimeMinutes
            switch selectedTimeRange {
            case .any: break
            case .quick: if totalTime > 30 { return false }
            case .medium: if totalTime < 30 || totalTime > 60 { return false }
            case .long: if totalTime < 60 { return false }
            }
            // Cuisine filter
            if selectedCuisine != "Any" {
                if recipe.category?.name != selectedCuisine { return false }
            }
            // Dietary filter
            if selectedDietary != "Any" {
                if !recipe.dietaryPreferences.contains(selectedDietary) { return false }
            }
            // Favorites filter
            if favoritesOnly && !recipe.isFavorite { return false }
            return true
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color.purple.opacity(0.08), Color.pink.opacity(0.06), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 6) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .padding(.bottom, 4)
                            
                            Text("What Should I Cook?")
                                .font(.title.weight(.bold))
                            
                            Text("Tell us your mood and we'll pick the perfect recipe.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)
                        
                        // Time Picker
                        VStack(alignment: .leading, spacing: 10) {
                            Label("How much time do you have?", systemImage: "clock")
                                .font(.subheadline.weight(.semibold))
                            
                            HStack(spacing: 8) {
                                ForEach(TimeRange.allCases) { range in
                                    Button {
                                        withAnimation(.spring(response: 0.35)) {
                                            selectedTimeRange = range
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: range.icon)
                                                .font(.body)
                                            Text(range.rawValue)
                                                .font(.caption2.weight(.medium))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            selectedTimeRange == range
                                            ? AnyShapeStyle(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            : AnyShapeStyle(Color.primary.opacity(0.06))
                                        )
                                        .foregroundColor(selectedTimeRange == range ? .white : .primary)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        
                        // Cuisine & Dietary row
                        HStack(spacing: 12) {
                            // Cuisine picker
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Cuisine", systemImage: "globe")
                                    .font(.subheadline.weight(.semibold))
                                
                                Menu {
                                    ForEach(availableCuisines, id: \.self) { cuisine in
                                        Button {
                                            selectedCuisine = cuisine
                                        } label: {
                                            HStack {
                                                Text(cuisine)
                                                if selectedCuisine == cuisine {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedCuisine)
                                            .font(.subheadline)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                    }
                                    .padding(10)
                                    .background(Color.primary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            
                            // Dietary picker
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Dietary", systemImage: "leaf")
                                    .font(.subheadline.weight(.semibold))
                                
                                Menu {
                                    ForEach(availableDietary, id: \.self) { pref in
                                        Button {
                                            selectedDietary = pref
                                        } label: {
                                            HStack {
                                                Text(pref)
                                                if selectedDietary == pref {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedDietary)
                                            .font(.subheadline)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                    }
                                    .padding(10)
                                    .background(Color.primary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        
                        // Favorites toggle
                        Toggle(isOn: $favoritesOnly) {
                            Label("Only from my favorites", systemImage: "heart.fill")
                                .font(.subheadline.weight(.medium))
                        }
                        .tint(.pink)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        
                        // Match count
                        Text("\(candidateRecipes.count) recipe\(candidateRecipes.count == 1 ? "" : "s") match your preferences")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Surprise Me Button
                        Button {
                            triggerReveal()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "wand.and.stars")
                                    .font(.title3)
                                Text("Surprise Me!")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                candidateRecipes.isEmpty
                                ? AnyShapeStyle(Color.gray.opacity(0.3))
                                : AnyShapeStyle(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                            )
                            .foregroundColor(candidateRecipes.isEmpty ? .secondary : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: candidateRecipes.isEmpty ? .clear : .purple.opacity(0.35), radius: 12, y: 6)
                        }
                        .disabled(candidateRecipes.isEmpty)
                        
                        // Revealed recipe card
                        if let recipe = revealedRecipe {
                            revealedCard(recipe)
                                .offset(y: cardOffset)
                                .rotationEffect(.degrees(cardRotation))
                                .opacity(cardOpacity)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Decide for Me")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        resetFilters()
                    } label: {
                        Text("Reset")
                            .font(.subheadline)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToRecipe) {
                if let recipe = revealedRecipe {
                    RecipeDetailView(recipe: recipe)
                }
            }
        }
    }
    
    // MARK: - Revealed Recipe Card
    
    private func revealedCard(_ recipe: RecipeModel) -> some View {
        Button {
            navigateToRecipe = true
        } label: {
            VStack(spacing: 0) {
                // Image
                ZStack(alignment: .bottomLeading) {
                    Image(uiImage: recipe.viewImageWithDefault)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                    
                    // Gradient overlay
                    LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 80)
                    
                    // Category badge
                    if let catName = recipe.category?.name {
                        Text(catName)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(12)
                    }
                }
                
                // Info section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(recipe.name)
                            .font(.title3.weight(.bold))
                            .foregroundColor(.primary)
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(0..<recipe.rating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Label("\(recipe.totalTimeMinutes) min", systemImage: "clock")
                        Label("\(recipe.servingSize) servings", systemImage: "person.2")
                        Label("\(recipe.calories) cal", systemImage: "flame")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    if let location = recipe.locationName, !location.isEmpty {
                        Label(location, systemImage: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                    }
                    
                    if !recipe.dietaryPreferences.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(recipe.dietaryPreferences, id: \.self) { pref in
                                Text(pref)
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.green.opacity(0.12))
                                    .foregroundColor(.green)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    // CTA
                    HStack {
                        Text("Tap to view full recipe")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .font(.title2)
                    }
                }
                .padding(16)
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .purple.opacity(0.2), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    
    private func triggerReveal() {
        guard let recipe = candidateRecipes.randomElement() else { return }
        
        // Reset animation state
        cardOffset = 600
        cardRotation = 12
        cardOpacity = 0
        revealedRecipe = recipe
        isRevealing = true
        
        // Animate card entrance
        withAnimation(.spring(response: 0.7, dampingFraction: 0.72, blendDuration: 0)) {
            cardOffset = 0
            cardRotation = 0
            cardOpacity = 1
        }
        
        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let success = UINotificationFeedbackGenerator()
            success.notificationOccurred(.success)
        }
    }
    
    private func resetFilters() {
        withAnimation {
            selectedTimeRange = .any
            selectedCuisine = "Any"
            selectedDietary = "Any"
            favoritesOnly = false
            revealedRecipe = nil
            cardOffset = 600
            cardRotation = 12
            cardOpacity = 0
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(RecipeModel.preview)
}
