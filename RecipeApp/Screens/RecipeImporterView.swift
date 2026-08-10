import SwiftData
import SwiftUI

struct RecipeImporterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [CategoryModel]
    
    @State private var urlString: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var parsedRecipe: ParsedWebRecipe? = nil
    @State private var downloadedImageData: Data? = nil
    @State private var selectedCategory: CategoryModel? = nil
    
    // Quick Demo Preset URLs
    let sampleURLs = [
        ("NYT Pasta Carbonara", "https://cooking.nytimes.com/recipes/12965-spaghetti-carbonara"),
        ("BBC Good Food Roast", "https://www.bbcgoodfood.com/recipes/classic-roast-chicken-stuffing"),
        ("AllRecipes Guacamole", "https://www.allrecipes.com/recipe/14231/guacamole/")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: URL Input
                Section(header: Text("Web URL"), footer: Text("Paste any recipe URL from your browser or food blog.")) {
                    HStack {
                        TextField("https://...", text: $urlString)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        if let clipboard = UIPasteboard.general.string, clipboard.hasPrefix("http") {
                            Button("Paste") {
                                urlString = clipboard
                            }
                            .buttonStyle(.bordered)
                            .font(.caption)
                        }
                    }
                    
                    Button {
                        startImport()
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .padding(.trailing, 4)
                                Text("Analyzing Recipe...")
                            } else {
                                Label("Import Recipe", systemImage: "arrow.down.doc.fill")
                            }
                            Spacer()
                        }
                        .font(.headline)
                    }
                    .disabled(urlString.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
                
                // Section 2: Sample Presets
                if parsedRecipe == nil && !isLoading {
                    Section("Quick Test Presets") {
                        ForEach(sampleURLs, id: \.0) { sample in
                            Button {
                                urlString = sample.1
                                startImport()
                            } label: {
                                HStack {
                                    Text(sample.0)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.right.circle")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                // Error message
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
                
                // Section 3: Parsed Recipe Preview
                if let recipe = parsedRecipe {
                    Section("Imported Preview") {
                        if let data = downloadedImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .listRowBackground(Color.clear)
                        }
                        
                        Text(recipe.title)
                            .font(.title3.weight(.bold))
                        
                        if !recipe.description.isEmpty {
                            Text(recipe.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Label("\(recipe.prepTimeMinutes)m prep", systemImage: "clock")
                            Spacer()
                            Label("\(recipe.cookTimeMinutes)m cook", systemImage: "flame")
                            Spacer()
                            Label("\(recipe.servings) servings", systemImage: "person.2")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Section("Category") {
                        Picker("Select Category", selection: $selectedCategory) {
                            Text("Uncategorized").tag(CategoryModel?.none)
                            ForEach(categories) { cat in
                                Text(cat.name).tag(CategoryModel?.some(cat))
                            }
                        }
                    }
                    
                    Section("Ingredients (\(recipe.ingredients.count))") {
                        ForEach(recipe.ingredients, id: \.self) { ing in
                            Text("• \(ing)")
                                .font(.subheadline)
                        }
                    }
                    
                    Section("Instructions (\(recipe.instructions.count))") {
                        ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Step \(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.accentColor)
                                Text(step)
                                    .font(.subheadline)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    
                    Section {
                        Button {
                            saveImportedRecipe()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Save to My Recipes", systemImage: "checkmark.circle.fill")
                                    .font(.headline)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("Import from Web")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func startImport() {
        let cleanUrl = urlString.trimmingCharacters(in: .whitespaces)
        guard !cleanUrl.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        parsedRecipe = nil
        downloadedImageData = nil
        
        Task {
            do {
                let parsed = try await WebRecipeParser.shared.parseRecipe(from: cleanUrl)
                await MainActor.run {
                    self.parsedRecipe = parsed
                    self.isLoading = false
                    
                    // Match category if exists
                    if let existing = categories.first(where: { $0.name.localizedCaseInsensitiveContains(parsed.category) }) {
                        self.selectedCategory = existing
                    }
                }
                
                // Download Image if available
                if let imgUrlStr = parsed.imageUrl, let imgUrl = URL(string: imgUrlStr) {
                    if let (data, _) = try? await URLSession.shared.data(from: imgUrl) {
                        await MainActor.run {
                            self.downloadedImageData = data
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Could not extract recipe: \(error.localizedDescription). Please verify URL."
                }
            }
        }
    }
    
    private func saveImportedRecipe() {
        guard let parsed = parsedRecipe else { return }
        
        let newRecipe = RecipeModel(
            name: parsed.title,
            image: downloadedImageData,
            category: selectedCategory,
            minutesToCook: parsed.cookTimeMinutes,
            prepTimeMinutes: parsed.prepTimeMinutes,
            servingSize: parsed.servings,
            isFavorite: false,
            tags: ["Web Import", parsed.category]
        )
        
        // Add Ingredients
        for rawIng in parsed.ingredients {
            let ing = IngredientModel(name: rawIng, quantity: "1 serving")
            newRecipe.ingredients.append(ing)
        }
        
        // Add Steps
        for (idx, stepText) in parsed.instructions.enumerated() {
            let step = StepModel(stepNumber: idx + 1, instruction: stepText)
            newRecipe.steps.append(step)
        }
        
        modelContext.insert(newRecipe)
        try? modelContext.save()
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
