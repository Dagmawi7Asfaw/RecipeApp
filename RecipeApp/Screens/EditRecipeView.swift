import PhotosUI
import SwiftData
import SwiftUI

struct DraftIngredient: Identifiable {
    let id = UUID()
    var existingModel: IngredientModel? = nil
    var name: String
    var quantity: String
}

struct DraftStep: Identifiable {
    let id = UUID()
    var existingModel: StepModel? = nil
    var stepNumber: Int
    var instruction: String
    var timerMins: Int
}

struct EditRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let recipe: RecipeModel
    @Query private var categories: [CategoryModel]
    
    // Draft State Variables (Unsaved edits remain local until Save & Done is clicked)
    @State private var draftName: String = ""
    @State private var draftCategory: CategoryModel?
    @State private var draftPrepTime: Int = 0
    @State private var draftCookTime: Int = 0
    @State private var draftServingSize: Int = 1
    @State private var draftIsFavorite: Bool = false
    @State private var draftImageData: Data?
    @State private var draftLocationName: String = ""
    @State private var draftLatitude: Double? = nil
    @State private var draftLongitude: Double? = nil
    @State private var draftTags: [String] = []
    @State private var draftIngredients: [DraftIngredient] = []
    @State private var draftSteps: [DraftStep] = []
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showLocationPicker: Bool = false
    @State private var tagInput: String = ""
    @State private var customCategoryName: String = ""
    
    // New ingredient & step draft inputs
    @State private var newIngName: String = ""
    @State private var newIngQty: String = ""
    
    @State private var newStepInstruction: String = ""
    @State private var newStepTimer: Int = 0
    
    var body: some View {
        Form {
            // 1. Basic Details
            Section("Basic Information") {
                TextField("Recipe Name", text: $draftName)
                
                Picker("Category", selection: $draftCategory) {
                    Text("Uncategorized").tag(CategoryModel?.none)
                    ForEach(categories) { category in
                        Text(category.name).tag(CategoryModel?.some(category))
                    }
                }
                
                if draftCategory == nil {
                    HStack {
                        TextField("New category name...", text: $customCategoryName)
                        Button("Set") {
                            let trimmed = customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                let newCat = CategoryModel(name: trimmed)
                                modelContext.insert(newCat)
                                draftCategory = newCat
                                customCategoryName = ""
                            }
                        }
                        .disabled(customCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                Stepper("Prep Time: \(draftPrepTime) mins", value: $draftPrepTime, in: 0...300, step: 5)
                Stepper("Cook Time: \(draftCookTime) mins", value: $draftCookTime, in: 0...300, step: 5)
                Stepper("Serving Size: \(draftServingSize)", value: $draftServingSize, in: 1...50)
                
                Toggle("Favorite Recipe", isOn: $draftIsFavorite)
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            // 2. Cover Photo
            Section("Cover Photo") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        // Thumbnail Preview
                        ZStack(alignment: .bottomTrailing) {
                            if let data = draftImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 84, height: 84)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                            } else {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.secondary.opacity(0.12))
                                    .frame(width: 84, height: 84)
                                    .overlay {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 28))
                                            .foregroundColor(.secondary)
                                    }
                            }
                        }
                        .contextMenu {
                            if UIPasteboard.general.hasImages {
                                Button {
                                    pasteImageFromClipboard()
                                } label: {
                                    Label("Paste Image from Clipboard", systemImage: "doc.on.clipboard")
                                }
                            }
                            if let data = draftImageData, let uiImage = UIImage(data: data) {
                                Button {
                                    UIPasteboard.general.image = uiImage
                                } label: {
                                    Label("Copy Image", systemImage: "doc.on.doc")
                                }
                            }
                            if draftImageData != nil {
                                Button(role: .destructive) {
                                    draftImageData = nil
                                    selectedPhoto = nil
                                } label: {
                                    Label("Remove Photo", systemImage: "trash")
                                }
                            }
                        }
                        
                        // Professional Action Buttons Grid
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                                    Label(draftImageData == nil ? "Choose Photo" : "Change", systemImage: "photo.on.rectangle.angled")
                                        .font(.subheadline.weight(.medium))
                                }
                                .buttonStyle(.bordered)
                                .tint(.accentColor)
                                
                                Button {
                                    pasteImageFromClipboard()
                                } label: {
                                    Label("Paste", systemImage: "doc.on.clipboard")
                                        .font(.subheadline.weight(.medium))
                                }
                                .buttonStyle(.bordered)
                                .tint(UIPasteboard.general.hasImages ? .blue : .gray)
                                .disabled(!UIPasteboard.general.hasImages)
                            }
                            
                            if draftImageData != nil {
                                Button(role: .destructive) {
                                    draftImageData = nil
                                    selectedPhoto = nil
                                } label: {
                                    Label("Remove Photo", systemImage: "trash")
                                        .font(.caption.weight(.medium))
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.red)
                            } else {
                                Text(UIPasteboard.general.hasImages ? "Tip: Image in clipboard ready to paste!" : "Choose from library or copy an image to paste")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            // 3. Origin Location & Map
            Section("Origin / Market Location (Map)") {
                TextField("Location Name (e.g. Paris, France)", text: $draftLocationName)
                
                if let lat = draftLatitude, let lon = draftLongitude {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.red)
                        Text(String(format: "Lat: %.4f, Lon: %.4f", lat, lon))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                
                HStack {
                    Button {
                        showLocationPicker = true
                    } label: {
                        Label(draftLatitude == nil ? "Pick Location on Map" : "Change Map Pin", systemImage: "map")
                    }
                    
                    if draftLatitude != nil {
                        Spacer()
                        Button("Clear Location", role: .destructive) {
                            draftLatitude = nil
                            draftLongitude = nil
                            draftLocationName = ""
                        }
                        .font(.caption)
                    }
                }
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            // 4. Ingredients Inline Editor
            Section("Ingredients") {
                // Add new ingredient
                HStack {
                    TextField("Qty (e.g., 2 cups)", text: $newIngQty)
                        .frame(width: 110)
                    TextField("Ingredient name", text: $newIngName)
                    Button("Add") {
                        let trimmedName = newIngName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedName.isEmpty {
                            let newDraftIng = DraftIngredient(name: trimmedName, quantity: newIngQty.trimmingCharacters(in: .whitespacesAndNewlines))
                            draftIngredients.append(newDraftIng)
                            newIngName = ""
                            newIngQty = ""
                        }
                    }
                    .disabled(newIngName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                // Existing ingredients list with direct text editing
                ForEach($draftIngredients) { $ingredient in
                    HStack(spacing: 8) {
                        TextField("Qty", text: $ingredient.quantity)
                            .frame(width: 100)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Ingredient", text: $ingredient.name)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            draftIngredients.removeAll { $0.id == ingredient.id }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete { indexSet in
                    draftIngredients.remove(atOffsets: indexSet)
                }
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            // 5. Cooking Steps Inline Editor
            Section("Cooking Steps") {
                // Add new step
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Add new step instruction...", text: $newStepInstruction, axis: .vertical)
                        .lineLimit(3)
                    
                    HStack {
                        Stepper("Timer: \(newStepTimer) mins", value: $newStepTimer, in: 0...180, step: 1)
                        Spacer()
                        Button("Add Step") {
                            let trimmedInst = newStepInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedInst.isEmpty {
                                let nextNum = draftSteps.count + 1
                                let newDraftStep = DraftStep(stepNumber: nextNum, instruction: trimmedInst, timerMins: newStepTimer)
                                draftSteps.append(newDraftStep)
                                newStepInstruction = ""
                                newStepTimer = 0
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newStepInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                // Existing steps with direct editing
                ForEach(Array($draftSteps.enumerated()), id: \.element.id) { index, $step in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Step \(index + 1)")
                                .font(.headline)
                            Spacer()
                            Button {
                                draftSteps.removeAll { $0.id == step.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        TextField("Instruction", text: $step.instruction, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(4)
                        
                        Stepper("Step Timer: \(step.timerMins) mins", value: $step.timerMins, in: 0...180, step: 1)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { indexSet in
                    draftSteps.remove(atOffsets: indexSet)
                }
            }
            .listRowBackground(Color.primary.opacity(0.05))
            
            // 6. Tags
            Section("Tags") {
                HStack {
                    TextField("Add tag (e.g. Italian, Spicy)", text: $tagInput)
                    Button("Add") {
                        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty && !draftTags.contains(trimmed) {
                            draftTags.append(trimmed)
                            tagInput = ""
                        }
                    }
                    .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                if !draftTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(draftTags, id: \.self) { tag in
                                HStack {
                                    Text("#\(tag)")
                                    Button {
                                        draftTags.removeAll { $0 == tag }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.accentColor.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.primary.opacity(0.05))
        }
        .scrollContentBackground(.hidden)
        .background(.regularMaterial)
        .background {
            if let data = draftImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .ignoresSafeArea()
                    .opacity(0.5)
            } else {
                Image("RecipeApp")
                    .opacity(0.5)
            }
        }
        .navigationTitle("Edit Recipe")
        .headerProminence(.increased)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save & Done") {
                    saveChanges()
                }
                .bold()
                .disabled(draftName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(latitude: $draftLatitude, longitude: $draftLongitude, locationName: $draftLocationName)
        }
        .task(id: selectedPhoto) {
            if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                draftImageData = data
            }
        }
        .onAppear {
            loadRecipeIntoDraft()
        }
    }
    
    private func pasteImageFromClipboard() {
        if let pasteboardImage = UIPasteboard.general.image,
           let data = pasteboardImage.pngData() ?? pasteboardImage.jpegData(compressionQuality: 0.9) {
            draftImageData = data
        } else if let pngData = UIPasteboard.general.data(forPasteboardType: "public.png") {
            draftImageData = pngData
        } else if let jpegData = UIPasteboard.general.data(forPasteboardType: "public.jpeg") {
            draftImageData = jpegData
        }
    }
    
    private func loadRecipeIntoDraft() {
        draftName = recipe.name
        draftCategory = recipe.category
        draftPrepTime = recipe.prepTimeMinutes
        draftCookTime = recipe.minutesToCook
        draftServingSize = recipe.servingSize
        draftIsFavorite = recipe.isFavorite
        draftImageData = recipe.image
        draftLocationName = recipe.locationName ?? ""
        draftLatitude = recipe.latitude
        draftLongitude = recipe.longitude
        draftTags = recipe.tags
        
        draftIngredients = recipe.viewSortedIngredients.map {
            DraftIngredient(existingModel: $0, name: $0.name, quantity: $0.quantity)
        }
        
        draftSteps = recipe.viewSortedSteps.map {
            DraftStep(existingModel: $0, stepNumber: $0.stepNumber, instruction: $0.instruction, timerMins: $0.timerDurationMinutes)
        }
    }
    
    private func saveChanges() {
        recipe.name = draftName
        recipe.category = draftCategory
        recipe.prepTimeMinutes = draftPrepTime
        recipe.minutesToCook = draftCookTime
        recipe.servingSize = draftServingSize
        recipe.isFavorite = draftIsFavorite
        recipe.image = draftImageData
        recipe.locationName = draftLocationName.isEmpty ? nil : draftLocationName
        recipe.latitude = draftLatitude
        recipe.longitude = draftLongitude
        recipe.tags = draftTags
        
        // Sync Ingredients
        let keptIngModels = Set(draftIngredients.compactMap { $0.existingModel })
        for existing in recipe.ingredients {
            if !keptIngModels.contains(existing) {
                modelContext.delete(existing)
            }
        }
        
        var newIngredientsList: [IngredientModel] = []
        for draft in draftIngredients {
            if let existing = draft.existingModel {
                existing.name = draft.name
                existing.quantity = draft.quantity
                newIngredientsList.append(existing)
            } else {
                let newIng = IngredientModel(name: draft.name, quantity: draft.quantity)
                modelContext.insert(newIng)
                newIngredientsList.append(newIng)
            }
        }
        recipe.ingredients = newIngredientsList
        
        // Sync Steps
        let keptStepModels = Set(draftSteps.compactMap { $0.existingModel })
        for existing in recipe.steps {
            if !keptStepModels.contains(existing) {
                modelContext.delete(existing)
            }
        }
        
        var newStepsList: [StepModel] = []
        for (index, draft) in draftSteps.enumerated() {
            if let existing = draft.existingModel {
                existing.stepNumber = index + 1
                existing.instruction = draft.instruction
                existing.timerDurationMinutes = draft.timerMins
                newStepsList.append(existing)
            } else {
                let newStep = StepModel(stepNumber: index + 1, instruction: draft.instruction, timerDurationMinutes: draft.timerMins)
                modelContext.insert(newStep)
                newStepsList.append(newStep)
            }
        }
        recipe.steps = newStepsList
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let container = RecipeModel.preview
    let recipes = try! container.mainContext.fetch(FetchDescriptor<RecipeModel>())
    
    return NavigationStack {
        EditRecipeView(recipe: recipes[0])
    }
}
