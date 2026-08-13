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
    @State private var headerOpacity: Double = 0

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
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image Header
                heroImageHeader

                // Content card that slides over the image
                VStack(spacing: 0) {
                    // Handle indicator
                    Capsule()
                        .fill(Color.secondary.opacity(0.25))
                        .frame(width: 36, height: 4)
                        .padding(.top, 10)
                        .padding(.bottom, 6)

                    // Title & meta row
                    titleMetaSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)

                    Divider().padding(.horizontal, 20)

                    // Star Rating & Serving Scaler
                    ratingAndServingSection
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)

                    // Action Buttons
                    actionButtonsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    Divider().padding(.horizontal, 20)

                    // Nutrition
                    nutritionSection
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)

                    // Tags
                    if !recipe.tags.isEmpty {
                        Divider().padding(.horizontal, 20)
                        tagsSection
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                    }

                    // Map
                    if recipe.coordinate != nil {
                        Divider().padding(.horizontal, 20)
                        mapSection
                    }

                    Divider().padding(.horizontal, 20)

                    // Ingredients
                    ingredientsSection
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)

                    Divider().padding(.horizontal, 20)

                    // Steps
                    stepsSection
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)

                    Divider().padding(.horizontal, 20)

                    // Notes
                    if !recipe.userNotes.isEmpty {
                        notesSection
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        Divider().padding(.horizontal, 20)
                    }

                    // PDF Export
                    pdfExportSection
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .offset(y: -28)
            }
        }
        .ignoresSafeArea(edges: .top)
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    recipe.isFavorite.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(recipe.isFavorite ? .pink : .primary)
                }

                ShareLink(item: shareableText) {
                    Image(systemName: "square.and.arrow.up")
                }

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
                HStack(spacing: 8) {
                    Image(systemName: "cart.fill.badge.plus")
                        .foregroundColor(.green)
                    Text("Added \(recipe.ingredients.count) ingredients to Grocery List")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.88))
                .clipShape(Capsule())
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
            }
        }
    }

    // MARK: - Hero Image

    private var heroImageHeader: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let image = recipe.viewImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image("RecipeApp")
                        .resizable()
                        .scaledToFill()
                        .overlay(Color.black.opacity(0.35))
                }
            }
            .frame(height: 300)
            .clipped()

            // Gradient scrim
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 300)
        }
        .frame(height: 300)
    }

    // MARK: - Title & Meta

    private var titleMetaSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recipe.name)
                .font(.title2.weight(.bold))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                metaPill(icon: "clock", value: "\(recipe.totalTimeMinutes) min", color: .orange)
                metaPill(icon: "person.2", value: "\(recipe.servingSize) servings", color: .blue)
                if !recipe.viewCategory.isEmpty {
                    metaPill(icon: "fork.knife", value: recipe.viewCategory, color: .purple)
                }
                Spacer(minLength: 0)
            }

            if let loc = recipe.locationName, !loc.isEmpty {
                Label(loc, systemImage: "mappin.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
    }

    private func metaPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold)).foregroundColor(color)
            Text(value).font(.caption.weight(.medium)).foregroundColor(.primary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Rating & Serving

    private var ratingAndServingSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Rating").font(.caption).foregroundColor(.secondary)
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= recipe.rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.title3)
                            .onTapGesture {
                                recipe.rating = star
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Serving Size").font(.caption).foregroundColor(.secondary)
                HStack(spacing: 12) {
                    Button {
                        if servingSize > 1 { servingSize -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(servingSize > 1 ? .accentColor : .secondary.opacity(0.4))
                    }
                    .disabled(servingSize <= 1)

                    Text("\(servingSize)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .frame(minWidth: 24)

                    Button {
                        if servingSize < 50 { servingSize += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .disabled(servingSize >= 50)
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            Button {
                showCookingMode = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                    Text("Cook Now")
                        .font(.subheadline.weight(.bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [.accentColor, Color(hue: 0.62, saturation: 0.7, brightness: 0.9)], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.accentColor.opacity(0.35), radius: 8, y: 4)
            }

            Button {
                addIngredientsToGroceryList()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cart.badge.plus")
                    Text("Groceries")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Nutrition

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Nutrition per Serving", systemImage: "chart.bar.fill")
                .font(.subheadline.weight(.bold))

            HStack(spacing: 10) {
                macroBox(title: "Calories", value: "\(recipe.calories > 0 ? recipe.calories : 380)", unit: "kcal", color: .orange)
                macroBox(title: "Protein", value: "\(recipe.proteinGrams > 0 ? recipe.proteinGrams : 28)", unit: "g", color: .red)
                macroBox(title: "Carbs", value: "\(recipe.carbsGrams > 0 ? recipe.carbsGrams : 34)", unit: "g", color: .blue)
                macroBox(title: "Fat", value: "\(recipe.fatGrams > 0 ? recipe.fatGrams : 14)", unit: "g", color: .green)
            }

            if !recipe.dietaryPreferences.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(recipe.dietaryPreferences, id: \.self) { pref in
                            Label(pref, systemImage: dietaryIcon(for: pref))
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(dietaryColor(for: pref).opacity(0.15))
                                .foregroundColor(dietaryColor(for: pref))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private func macroBox(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 3) {
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
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Tags

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Tags & Dietary", systemImage: "tag.fill")
                .font(.subheadline.weight(.bold))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(recipe.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.12))
                            .foregroundColor(.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Map

    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Origin Location", systemImage: "map.fill")
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 20)
                .padding(.top, 14)
            RecipeMapView(recipe: recipe)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
        }
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Ingredients", systemImage: "list.bullet.clipboard.fill")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("\(recipe.ingredients.count) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
                NavigationLink("Edit") { IngredientDetailView(recipe: recipe, editMode: true) }
                    .font(.caption.weight(.semibold))
            }

            if servingSize != recipe.servingSize {
                Label("Scaled to \(servingSize) servings (original: \(recipe.servingSize))", systemImage: "arrow.up.arrow.down.circle")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.08))
                    .clipShape(Capsule())
            }

            VStack(spacing: 8) {
                ForEach(recipe.viewSortedIngredients) { ingredient in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(ingredient.scaledIngredient(baseServing: recipe.servingSize, targetServing: servingSize))
                            .font(.body)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Instructions", systemImage: "checklist")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("\(recipe.steps.count) steps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                NavigationLink("Edit") { StepDetailView(recipe: recipe, editMode: true) }
                    .font(.caption.weight(.semibold))
            }

            VStack(spacing: 14) {
                ForEach(recipe.viewSortedSteps) { step in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 28, height: 28)
                            Text("\(step.stepNumber)")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.accentColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.instruction)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            if step.timerDurationMinutes > 0 {
                                Label("\(step.timerDurationMinutes) min timer", systemImage: "timer")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Chef's Notes", systemImage: "pencil.and.outline")
                .font(.subheadline.weight(.bold))
            Text(recipe.userNotes)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .background(Color.yellow.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    // MARK: - PDF Export

    private var pdfExportSection: some View {
        Button {
            generatePDF()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "printer.fill")
                Text("Export Printable Recipe Card (PDF)")
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.primary.opacity(0.05))
            .foregroundColor(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: - Private Helpers

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
        withAnimation { showGroceryAddedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showGroceryAddedToast = false }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func generatePDF() {
        pdfData = RecipePDFRenderer.shared.generatePDF(for: recipe, servingSize: servingSize)
        showPDFShare = true
    }

    private func dietaryIcon(for pref: String) -> String {
        let p = pref.lowercased()
        if p.contains("vegan") { return "leaf.fill" }
        if p.contains("vegetarian") { return "leaf" }
        if p.contains("gluten") { return "exclamationmark.triangle" }
        if p.contains("keto") { return "bolt.fill" }
        if p.contains("halal") { return "checkmark.seal.fill" }
        if p.contains("protein") { return "flame.fill" }
        if p.contains("dairy") { return "drop.fill" }
        return "heart.fill"
    }

    private func dietaryColor(for pref: String) -> Color {
        let p = pref.lowercased()
        if p.contains("vegan") || p.contains("vegetarian") { return .green }
        if p.contains("gluten") { return .orange }
        if p.contains("keto") { return .purple }
        if p.contains("halal") { return .teal }
        if p.contains("protein") { return .red }
        return .blue
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
    .modelContainer(container)
}
