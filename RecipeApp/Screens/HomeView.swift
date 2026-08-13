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
    @State private var layoutIsGrid: Bool = true

    // MARK: - Computed

    var filteredCategories: [(categoryName: String, recipes: [RecipeModel])] {
        var result: [(categoryName: String, recipes: [RecipeModel])] = []

        for category in categories {
            if let selectedCategoryFilter, category.name != selectedCategoryFilter { continue }
            let matching = category.recipes.filter { matches($0) }
            if !matching.isEmpty { result.append((category.name, matching)) }
        }

        if selectedCategoryFilter == nil || selectedCategoryFilter == "Uncategorized" {
            let uncategorized = allRecipes.filter { $0.category == nil && matches($0) }
            if !uncategorized.isEmpty { result.append(("Uncategorized", uncategorized)) }
        }
        return result
    }

    private func matches(_ recipe: RecipeModel) -> Bool {
        if showFavoritesOnly && !recipe.isFavorite { return false }
        if searchText.isEmpty { return true }
        let q = searchText.localizedLowercase
        return recipe.name.localizedLowercase.contains(q)
            || recipe.tags.contains { $0.localizedLowercase.contains(q) }
            || (recipe.locationName?.localizedLowercase.contains(q) ?? false)
            || recipe.ingredients.contains { $0.name.localizedLowercase.contains(q) }
    }

    var totalRecipes: Int { allRecipes.count }
    var favoritesCount: Int { allRecipes.filter(\.isFavorite).count }
    var continentsCount: Int { Set(allRecipes.compactMap { $0.category?.name }).count }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats Banner
                statsBanner
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)

                // Category Filter Chips
                filterChipsRow
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)

                Divider().opacity(0.4)

                // Content
                Group {
                    if filteredCategories.isEmpty {
                        emptyState
                    } else if layoutIsGrid {
                        gridContent
                    } else {
                        listContent
                    }
                }
            }
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search recipes, ingredients, tags…")
            .toolbar { toolbarItems }
            .sheet(isPresented: $showAddRecipeSheet) { AddRecipeView() }
            .sheet(isPresented: $showImporterSheet) { RecipeImporterView() }
            .sheet(isPresented: $showCategorySheet) { CategoryManagementView() }
            .sheet(isPresented: $showSurpriseMeSheet) { SurpriseMeView(allRecipes: allRecipes) }
            .scrollContentBackground(.hidden)
            .background(backgroundGradient)
        }
    }

    // MARK: - Stats Banner

    private var statsBanner: some View {
        HStack(spacing: 0) {
            statCell(value: "\(totalRecipes)", label: "Recipes", icon: "book.closed.fill", color: .accentColor)
            divider
            statCell(value: "\(favoritesCount)", label: "Saved", icon: "heart.fill", color: .pink)
            divider
            statCell(value: "\(continentsCount)", label: "Cuisines", icon: "globe", color: .orange)
        }
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(width: 1, height: 36)
    }

    private func statCell(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    // MARK: - Filter Chips

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", icon: "square.grid.2x2", isSelected: selectedCategoryFilter == nil) {
                    withAnimation(.spring(response: 0.3)) { selectedCategoryFilter = nil }
                }
                ForEach(categories) { cat in
                    FilterChip(
                        title: cat.name,
                        icon: continentIcon(for: cat.name),
                        isSelected: selectedCategoryFilter == cat.name
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategoryFilter = selectedCategoryFilter == cat.name ? nil : cat.name
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Grid Content

    private var gridContent: some View {
        ScrollView {
            LazyVStack(spacing: 24, pinnedViews: .sectionHeaders) {
                ForEach(filteredCategories, id: \.categoryName) { section in
                    LazyVStack(alignment: .leading, spacing: 12) {
                        sectionHeader(section.categoryName, count: section.recipes.count)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                            ForEach(section.recipes) { recipe in
                                NavigationLink { RecipeDetailView(recipe: recipe) } label: {
                                    RecipeGridCard(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                                .contextMenu { contextMenuItems(recipe) }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - List Content

    private var listContent: some View {
        List {
            ForEach(filteredCategories, id: \.categoryName) { section in
                Section {
                    ForEach(section.recipes) { recipe in
                        NavigationLink { RecipeDetailView(recipe: recipe) } label: {
                            RecipeListRow(recipe: recipe)
                        }
                        .listRowBackground(Color.primary.opacity(0.04))
                    }
                    .onDelete { idx in
                        for i in idx { modelContext.delete(section.recipes[i]) }
                    }
                } header: {
                    sectionHeader(section.categoryName, count: section.recipes.count)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            searchText.isEmpty ? "No Recipes Yet" : "No Results",
            systemImage: searchText.isEmpty ? "fork.knife.circle" : "magnifyingglass",
            description: Text(searchText.isEmpty
                ? "Add your first recipe with the + button above."
                : "No recipes match "\(searchText)". Try a different search.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundColor(.primary)
            Text("\(count)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Color.accentColor)
                .clipShape(Capsule())
            Spacer()
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuItems(_ recipe: RecipeModel) -> some View {
        Button { recipe.isFavorite.toggle() } label: {
            Label(recipe.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                  systemImage: recipe.isFavorite ? "heart.slash" : "heart")
        }
        Button(role: .destructive) { modelContext.delete(recipe) } label: {
            Label("Delete Recipe", systemImage: "trash")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { showCategorySheet = true } label: {
                Image(systemName: "folder.badge.gearshape")
            }
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button { showSurpriseMeSheet = true } label: {
                Image(systemName: "wand.and.stars")
                    .foregroundStyle(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            Button { showImporterSheet = true } label: {
                Image(systemName: "globe.badge.chevron.backward")
            }
            Button { withAnimation { showFavoritesOnly.toggle() } } label: {
                Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                    .foregroundColor(showFavoritesOnly ? .pink : .primary)
            }
            Button { withAnimation(.spring(response: 0.3)) { layoutIsGrid.toggle() } } label: {
                Image(systemName: layoutIsGrid ? "list.bullet" : "square.grid.2x2")
            }
            Button { showAddRecipeSheet = true } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color(.systemBackground)
            Image("RecipeApp")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .opacity(0.03)
        }
        .ignoresSafeArea()
    }

    // MARK: - Helpers

    private func continentIcon(for name: String) -> String {
        let n = name.lowercased()
        if n.contains("african") || n.contains("ethiopian") || n.contains("nigerian") { return "flame" }
        if n.contains("asian") || n.contains("japanese") || n.contains("indian") { return "sparkles" }
        if n.contains("european") || n.contains("french") || n.contains("italian") { return "building.columns" }
        if n.contains("north american") || n.contains("american") { return "flag" }
        if n.contains("south american") || n.contains("latin") { return "leaf" }
        if n.contains("ocean") || n.contains("austral") { return "sun.max" }
        if n.contains("antarct") { return "snowflake" }
        if n.contains("dessert") { return "birthday.cake" }
        return "fork.knife"
    }
}

// MARK: - Recipe Grid Card

struct RecipeGridCard: View {
    @Bindable var recipe: RecipeModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                Image(uiImage: recipe.viewImageWithDefault)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 130)
                    .clipped()

                // Favorite heart
                Button { recipe.isFavorite.toggle() } label: {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(recipe.isFavorite ? .pink : .white)
                        .padding(7)
                        .background(.ultraThinMaterial, in: Circle())
                        .shadow(color: .black.opacity(0.15), radius: 3)
                }
                .buttonStyle(.plain)
                .padding(8)

                // Category badge
                if let catName = recipe.category?.name {
                    Text(catName.components(separatedBy: " ").first ?? catName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.45), in: Capsule())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(8)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 5) {
                Text(recipe.name)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(2)
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Label("\(recipe.totalTimeMinutes)m", systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    // Stars (compact)
                    HStack(spacing: 1) {
                        ForEach(0..<recipe.rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 7))
                                .foregroundColor(.yellow)
                        }
                    }
                }

                if !recipe.tags.isEmpty {
                    Text(recipe.tags.prefix(2).map { "#\($0)" }.joined(separator: " "))
                        .font(.system(size: 10))
                        .foregroundColor(.accentColor.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Recipe List Row

struct RecipeListRow: View {
    @Bindable var recipe: RecipeModel

    var body: some View {
        HStack(spacing: 14) {
            Image(uiImage: recipe.viewImageWithDefault)
                .resizable()
                .scaledToFill()
                .frame(width: 62, height: 62)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label("\(recipe.totalTimeMinutes)m", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Label("\(recipe.servingSize)", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let loc = recipe.locationName, !loc.isEmpty {
                        Label(loc.components(separatedBy: ",").first ?? loc, systemImage: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .lineLimit(1)
                    }
                }

                if !recipe.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(recipe.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundColor(.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            Button { recipe.isFavorite.toggle() } label: {
                Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(recipe.isFavorite ? .pink : .secondary.opacity(0.5))
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(title)
                    .font(.subheadline.weight(isSelected ? .bold : .medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.primary.opacity(0.07))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(isSelected ? Color.clear : Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .animation(.spring(response: 0.25), value: isSelected)
    }
}

// MARK: - Surprise Me View

struct SurpriseMeView: View {
    let allRecipes: [RecipeModel]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTimeRange: TimeRange = .any
    @State private var selectedCuisine: String = "Any"
    @State private var selectedDietary: String = "Any"
    @State private var favoritesOnly: Bool = false

    @State private var revealedRecipe: RecipeModel?
    @State private var cardOffset: CGFloat = 600
    @State private var cardRotation: Double = 12
    @State private var cardOpacity: Double = 0
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
        ["Any"] + Set(allRecipes.compactMap { $0.category?.name }).sorted()
    }

    var availableDietary: [String] {
        ["Any"] + Set(allRecipes.flatMap { $0.dietaryPreferences }).sorted()
    }

    var candidateRecipes: [RecipeModel] {
        allRecipes.filter { recipe in
            switch selectedTimeRange {
            case .any: break
            case .quick: if recipe.totalTimeMinutes > 30 { return false }
            case .medium: if recipe.totalTimeMinutes < 30 || recipe.totalTimeMinutes > 60 { return false }
            case .long: if recipe.totalTimeMinutes < 60 { return false }
            }
            if selectedCuisine != "Any", recipe.category?.name != selectedCuisine { return false }
            if selectedDietary != "Any", !recipe.dietaryPreferences.contains(selectedDietary) { return false }
            if favoritesOnly && !recipe.isFavorite { return false }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.purple.opacity(0.08), Color.pink.opacity(0.05), Color(.systemBackground)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 6) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 44))
                                .foregroundStyle(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .padding(.bottom, 2)
                            Text("What Should I Cook?")
                                .font(.title2.weight(.bold))
                            Text("Set your preferences and let us decide.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 10)

                        // Time Picker
                        filterCard {
                            Label("Time Available", systemImage: "clock")
                                .font(.subheadline.weight(.semibold))
                                .padding(.bottom, 4)
                            HStack(spacing: 8) {
                                ForEach(TimeRange.allCases) { range in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) { selectedTimeRange = range }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: range.icon).font(.body)
                                            Text(range.rawValue)
                                                .font(.caption2.weight(.medium))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.75)
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

                        // Cuisine & Dietary
                        HStack(spacing: 12) {
                            filterCard(compact: true) {
                                pickerMenu(label: "Cuisine", icon: "globe", value: $selectedCuisine, options: availableCuisines)
                            }
                            filterCard(compact: true) {
                                pickerMenu(label: "Dietary", icon: "leaf", value: $selectedDietary, options: availableDietary)
                            }
                        }

                        // Favorites toggle
                        filterCard {
                            Toggle(isOn: $favoritesOnly) {
                                Label("Favorites only", systemImage: "heart.fill")
                                    .font(.subheadline.weight(.medium))
                            }
                            .tint(.pink)
                        }

                        Text("\(candidateRecipes.count) recipe\(candidateRecipes.count == 1 ? "" : "s") match")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Surprise Button
                        Button { triggerReveal() } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "wand.and.stars").font(.title3)
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
                            .shadow(color: candidateRecipes.isEmpty ? .clear : .purple.opacity(0.3), radius: 12, y: 6)
                        }
                        .disabled(candidateRecipes.isEmpty)

                        if let recipe = revealedRecipe {
                            revealedCard(recipe)
                                .offset(y: cardOffset)
                                .rotationEffect(.degrees(cardRotation))
                                .opacity(cardOpacity)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Decide for Me")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { resetFilters() } label: { Text("Reset").font(.subheadline) }
                }
            }
            .navigationDestination(isPresented: $navigateToRecipe) {
                if let r = revealedRecipe { RecipeDetailView(recipe: r) }
            }
        }
    }

    @ViewBuilder
    private func filterCard<Content: View>(compact: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) { content() }
            .padding(compact ? 12 : 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func pickerMenu(label: String, icon: String, value: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.subheadline.weight(.semibold))
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button {
                        value.wrappedValue = opt
                    } label: {
                        HStack {
                            Text(opt)
                            if value.wrappedValue == opt { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(value.wrappedValue).font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.caption)
                }
                .padding(10)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundColor(.primary)
            }
        }
    }

    private func revealedCard(_ recipe: RecipeModel) -> some View {
        Button { navigateToRecipe = true } label: {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    Image(uiImage: recipe.viewImageWithDefault)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                    LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                    if let cat = recipe.category?.name {
                        Text(cat)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(12)
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(recipe.name).font(.title3.weight(.bold))
                        Spacer()
                        HStack(spacing: 1) {
                            ForEach(0..<recipe.rating, id: \.self) { _ in
                                Image(systemName: "star.fill").font(.caption2).foregroundColor(.yellow)
                            }
                        }
                    }
                    HStack(spacing: 14) {
                        Label("\(recipe.totalTimeMinutes) min", systemImage: "clock")
                        Label("\(recipe.servingSize) servings", systemImage: "person.2")
                        Label("\(recipe.calories) cal", systemImage: "flame")
                    }
                    .font(.caption).foregroundColor(.secondary)

                    HStack {
                        Text("Tap to view full recipe").font(.caption).foregroundColor(.secondary)
                        Spacer()
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
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

    private func triggerReveal() {
        guard let recipe = candidateRecipes.randomElement() else { return }
        cardOffset = 600; cardRotation = 12; cardOpacity = 0
        revealedRecipe = recipe
        withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
            cardOffset = 0; cardRotation = 0; cardOpacity = 1
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func resetFilters() {
        withAnimation {
            selectedTimeRange = .any; selectedCuisine = "Any"; selectedDietary = "Any"
            favoritesOnly = false; revealedRecipe = nil
            cardOffset = 600; cardRotation = 12; cardOpacity = 0
        }
    }
}

#Preview {
    HomeView().modelContainer(RecipeModel.preview)
}
