import SwiftData
import SwiftUI

struct PantryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PantryItemModel.name) private var pantryItems: [PantryItemModel]
    @Query private var allRecipes: [RecipeModel]
    
    @State private var selectedTab: Int = 0 // 0: Inventory, 1: Recipe Matcher
    @State private var newStapleName: String = ""
    @State private var newStapleCategory: String = "Pantry"
    @State private var filterOnlyInStock: Bool = false
    
    var inStockPantryNames: Set<String> {
        Set(pantryItems.filter { $0.inStock }.map { $0.name.lowercased() })
    }
    
    struct RecipeMatch: Identifiable {
        let id = UUID()
        let recipe: RecipeModel
        let totalCount: Int
        let matchedCount: Int
        let missingIngredients: [String]
        var percentage: Int {
            guard totalCount > 0 else { return 0 }
            return Int((Double(matchedCount) / Double(totalCount)) * 100)
        }
    }
    
    var recipeMatches: [RecipeMatch] {
        let stocked = inStockPantryNames
        var matches: [RecipeMatch] = []
        
        for recipe in allRecipes {
            let total = recipe.ingredients.count
            guard total > 0 else { continue }
            
            var matched = 0
            var missing: [String] = []
            
            for ing in recipe.ingredients {
                let ingLower = ing.name.lowercased()
                let isOwned = stocked.contains { staple in
                    ingLower.contains(staple) || staple.contains(ingLower)
                }
                
                if isOwned {
                    matched += 1
                } else {
                    missing.append(ing.name)
                }
            }
            
            matches.append(RecipeMatch(recipe: recipe, totalCount: total, matchedCount: matched, missingIngredients: missing))
        }
        
        return matches.sorted { $0.percentage > $1.percentage }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segment Control
                Picker("Pantry Mode", selection: $selectedTab) {
                    Text("Pantry Inventory").tag(0)
                    Text("What Can I Cook?").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    inventoryView
                } else {
                    recipeMatcherView
                }
            }
            .navigationTitle(selectedTab == 0 ? "My Pantry Inventory" : "Pantry Matcher")
            .onAppear {
                seedStaplesIfNeeded()
            }
        }
    }
    
    // MARK: - Inventory View
    private var inventoryView: some View {
        VStack(spacing: 0) {
            // Quick Add Staple
            HStack(spacing: 8) {
                TextField("Add ingredient (e.g. Garlic)...", text: $newStapleName)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    addCustomStaple()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(newStapleName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            List {
                ForEach(groupedPantryCategories, id: \.key) { category, items in
                    Section(header: Text(category)) {
                        ForEach(items) { item in
                            HStack {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        item.inStock.toggle()
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                } label: {
                                    Image(systemName: item.inStock ? "checkmark.square.fill" : "square")
                                        .font(.title3)
                                        .foregroundColor(item.inStock ? .green : .secondary)
                                }
                                .buttonStyle(.plain)
                                
                                Text(item.name)
                                    .font(.body)
                                    .foregroundColor(item.inStock ? .primary : .secondary)
                                
                                Spacer()
                                
                                Text(item.inStock ? "In Stock" : "Out")
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(item.inStock ? Color.green.opacity(0.15) : Color.secondary.opacity(0.12))
                                    .foregroundColor(item.inStock ? .green : .secondary)
                                    .clipShape(Capsule())
                            }
                        }
                        .onDelete { indexSet in
                            for idx in indexSet {
                                modelContext.delete(items[idx])
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
    
    // MARK: - Recipe Matcher View
    private var recipeMatcherView: some View {
        Group {
            if recipeMatches.isEmpty {
                ContentUnavailableView("No Recipes Found", systemImage: "fork.knife", description: Text("Add recipes or mark pantry items in stock to see what you can cook."))
            } else {
                List {
                    ForEach(recipeMatches) { match in
                        NavigationLink {
                            RecipeDetailView(recipe: match.recipe)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    if let image = match.recipe.viewImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(match.recipe.name)
                                            .font(.headline)
                                        
                                        Text("\(match.matchedCount) of \(match.totalCount) ingredients available")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Match Badge
                                    Text("\(match.percentage)%")
                                        .font(.subheadline.weight(.bold))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(matchColor(match.percentage).opacity(0.2))
                                        .foregroundColor(matchColor(match.percentage))
                                        .clipShape(Capsule())
                                }
                                
                                // Progress Bar
                                ProgressView(value: Double(match.matchedCount), total: Double(match.totalCount))
                                    .tint(matchColor(match.percentage))
                                
                                // Missing Ingredients preview & quick add
                                if !match.missingIngredients.isEmpty {
                                    HStack {
                                        Text("Missing: \(match.missingIngredients.prefix(3).joined(separator: ", "))\(match.missingIngredients.count > 3 ? "..." : "")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        Button {
                                            addMissingToGroceries(match.missingIngredients, recipeName: match.recipe.name)
                                        } label: {
                                            Label("Add to Groceries", systemImage: "cart.badge.plus")
                                                .font(.caption2.weight(.medium))
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
    
    private var groupedPantryCategories: [(key: String, value: [PantryItemModel])] {
        let grouped = Dictionary(grouping: pantryItems) { $0.category }
        return grouped.map { (key: $0.key, value: $0.value) }.sorted { $0.key < $1.key }
    }
    
    private func matchColor(_ percentage: Int) -> Color {
        if percentage == 100 { return .green }
        if percentage >= 70 { return .blue }
        if percentage >= 40 { return .orange }
        return .red
    }
    
    private func addCustomStaple() {
        let name = newStapleName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        let item = PantryItemModel(name: name, category: "Custom Items", inStock: true)
        modelContext.insert(item)
        newStapleName = ""
    }
    
    private func seedStaplesIfNeeded() {
        if pantryItems.isEmpty {
            for staple in PantryItemModel.defaultStaples {
                let item = PantryItemModel(name: staple.name, category: staple.category, inStock: true)
                modelContext.insert(item)
            }
        }
    }
    
    private func addMissingToGroceries(_ missing: [String], recipeName: String) {
        for name in missing {
            let item = GroceryItemModel(
                name: name,
                quantity: "1 unit",
                category: GroceryItemModel.autoCategorize(ingredientName: name),
                recipeName: recipeName
            )
            modelContext.insert(item)
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
