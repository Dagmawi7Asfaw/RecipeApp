import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recipe: RecipeModel
    
    @State private var servingSize: Int
    @State private var showCookingMode: Bool = false
    @State private var showPDFShare: Bool = false
    @State private var pdfData: Data? = nil
    @State private var showGroceryAddedToast: Bool = false
    
    init(recipe: RecipeModel) {
        self.recipe = recipe
        self._servingSize = State(initialValue: recipe.servingSize)
    }
    
    var shareableText: String {
        var text = "🍳 \(recipe.name)\n"
        if let category = recipe.category?.name { text += "Category: \(category)\n" }
        text += "Prep: \(recipe.prepTimeMinutes) mins | Cook: \(recipe.minutesToCook) mins\n"
        text += "Servings: \(servingSize)\n\n"
        text += "🛒 INGREDIENTS:\n"
        for ing in recipe.viewSortedIngredients {
            text += "• \(ing.scaledIngredient(baseServing: recipe.servingSize, targetServing: servingSize))\n"
        }
        text += "\n👩‍🍳 INSTRUCTIONS:\n"
        for step in recipe.viewSortedSteps {
            text += "\(step.stepNumber). \(step.instruction)\n"
        }
        return text
    }
    
    var body: some View {
        List {
            Section {
                if let image = recipe.viewImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .listRowBackground(Color.clear)
                }
                
                // Star Rating & Category
                HStack {
                    LabeledContent("Category", value: recipe.viewCategory)
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= recipe.rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                                .onTapGesture {
                                    recipe.rating = star
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                        }
                    }
                }
                
                LabeledContent("Prep Time", value: "\(recipe.prepTimeMinutes) mins")
                LabeledContent("Cook Time", value: "\(recipe.minutesToCook) mins")
                
                // Serving Size Scaler
                Stepper(value: $servingSize, in: 1...50) {
                    HStack {
                        Text("Serving Size:")
                        Text("\(servingSize)")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        if servingSize != recipe.servingSize {
                            Text("(Original: \(recipe.servingSize))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Action Buttons: Guided Cooking & Add to Groceries
                VStack(spacing: 8) {
                    Button {
                        showCookingMode = true
                    } label: {
                        Label("Start Guided Cooking Assistant", systemImage: "play.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        addIngredientsToGroceryList()
                    } label: {
                        Label("Add to Grocery Shopping List", systemImage: "cart.badge.plus")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 2)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            // Nutrition Facts & Macro Breakdown
            Section("Nutrition (Per Serving)") {
                HStack(spacing: 12) {
                    macroBox(title: "Calories", value: "\(recipe.calories > 0 ? recipe.calories : 380)", unit: "kcal", color: .orange)
                    macroBox(title: "Protein", value: "\(recipe.proteinGrams > 0 ? recipe.proteinGrams : 28)", unit: "g", color: .red)
                    macroBox(title: "Carbs", value: "\(recipe.carbsGrams > 0 ? recipe.carbsGrams : 34)", unit: "g", color: .blue)
                    macroBox(title: "Fat", value: "\(recipe.fatGrams > 0 ? recipe.fatGrams : 14)", unit: "g", color: .green)
                }
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            // Map Location Section
            if recipe.coordinate != nil {
                Section {
                    RecipeMapView(recipe: recipe)
                }
                .listRowBackground(Color.primary.opacity(0.05))
            }
            
            // Tags Section
            if !recipe.tags.isEmpty {
                Section("Tags & Dietary") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(recipe.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.subheadline)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.accentColor.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .listRowBackground(Color.primary.opacity(0.05))
            }
            
            // Ingredients Section with Live Scaling
            Section("Ingredients (\(recipe.ingredients.count))") {
                ForEach(recipe.viewSortedIngredients) { ingredient in
                    Text("• \(ingredient.scaledIngredient(baseServing: recipe.servingSize, targetServing: servingSize))")
                }
                
                NavigationLink("Edit Ingredients") {
                    IngredientDetailView(recipe: recipe, editMode: true)
                }
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            // Instructions / Steps Section
            Section("Instructions (\(recipe.steps.count))") {
                ForEach(recipe.viewSortedSteps) { step in
                    VStack(alignment: .leading, spacing: 4) {
                        Label(step.instruction, systemImage: "\(step.stepNumber).square")
                        if step.timerDurationMinutes > 0 {
                            Label("Timer: \(step.timerDurationMinutes) mins", systemImage: "timer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                NavigationLink("Edit Steps") {
                    StepDetailView(recipe: recipe, editMode: true)
                }
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            // Printable PDF Card Export Section
            Section {
                Button {
                    generatePDF()
                } label: {
                    Label("Export Printable PDF Recipe Card", systemImage: "printer.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
            }
            .listRowBackground(Color.primary.opacity(0.05))
        }
        .scrollContentBackground(.hidden)
        .background(.regularMaterial)
        .background {
            if let image = recipe.viewImage {
                Image(uiImage: image)
                    .resizable()
                    .ignoresSafeArea()
                    .opacity(0.5)
            } else {
                Image("RecipeApp")
                    .opacity(0.5)
            }
        }
        .navigationTitle(recipe.name)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Favorite Heart Toggle Button
                Button {
                    recipe.isFavorite.toggle()
                } label: {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(recipe.isFavorite ? .red : .primary)
                }
                
                // Share Link
                ShareLink(item: shareableText) {
                    Image(systemName: "square.and.arrow.up")
                }
                
                // Edit Button
                NavigationLink {
                    EditRecipeView(recipe: recipe)
                } label: {
                    Image(systemName: "square.and.pencil.circle")
                }
            }
        }
        .fullScreenCover(isPresented: $showCookingMode) {
            CookingModeView(recipe: recipe)
        }
        .sheet(isPresented: $showPDFShare) {
            if let pdfData {
                PDFActivityView(pdfData: pdfData, title: recipe.name)
            }
        }
        .overlay(alignment: .bottom) {
            if showGroceryAddedToast {
                Text("🛒 Added \(recipe.ingredients.count) ingredients to Grocery List!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private func macroBox(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func addIngredientsToGroceryList() {
        for ing in recipe.viewSortedIngredients {
            let scaledQty = ing.scaledQuantity(baseServing: recipe.servingSize, targetServing: servingSize)
            let item = GroceryItemModel(
                name: ing.name,
                quantity: scaledQty,
                category: GroceryItemModel.autoCategorize(ingredientName: ing.name),
                recipeName: recipe.name
            )
            modelContext.insert(item)
        }
        
        withAnimation {
            showGroceryAddedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showGroceryAddedToast = false
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func generatePDF() {
        pdfData = RecipePDFRenderer.shared.generatePDF(for: recipe, servingSize: servingSize)
        showPDFShare = true
    }
}

#Preview {
    let container = RecipeModel.preview
    let recipes = try! container.mainContext.fetch(
        FetchDescriptor<RecipeModel>(predicate: #Predicate { recipe in
            recipe.name == "Lobster Bisque"
        }))
    
    return NavigationStack {
        RecipeDetailView(recipe: recipes[0])
    }
}
