import PhotosUI
import SwiftData
import SwiftUI

struct AddRecipeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var categories: [CategoryModel]
    
    @State private var name: String = ""
    @State private var minutesToCook: Int = 30
    @State private var prepTimeMinutes: Int = 15
    @State private var servingSize: Int = 4
    @State private var selectedCategory: CategoryModel?
    @State private var customCategoryName: String = ""
    
    @State private var tagInput: String = ""
    @State private var tags: [String] = []
    
    @State private var locationName: String = ""
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    @State private var showLocationPicker: Bool = false
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    
    // Ingredients & Steps draft list
    @State private var ingredientsDraft: [(name: String, quantity: String)] = []
    @State private var newIngName: String = ""
    @State private var newIngQty: String = ""
    
    @State private var stepsDraft: [(instruction: String, timerMins: Int)] = []
    @State private var newStepInstruction: String = ""
    @State private var newStepTimer: Int = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe Details") {
                    TextField("Recipe Name (e.g. Pasta Carbonara)", text: $name)
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select Category...").tag(CategoryModel?.none)
                        ForEach(categories) { category in
                            Text(category.name).tag(CategoryModel?.some(category))
                        }
                    }
                    
                    if selectedCategory == nil {
                        TextField("Or enter new category name", text: $customCategoryName)
                    }
                    
                    Stepper("Prep Time: \(prepTimeMinutes) mins", value: $prepTimeMinutes, in: 0...300, step: 5)
                    Stepper("Cook Time: \(minutesToCook) mins", value: $minutesToCook, in: 0...300, step: 5)
                    Stepper("Serving Size: \(servingSize)", value: $servingSize, in: 1...50)
                }
                
                Section("Cover Photo") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 16) {
                            // Thumbnail Preview
                            ZStack(alignment: .bottomTrailing) {
                                if let imageData, let uiImage = UIImage(data: imageData) {
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
                                if let imageData, let uiImage = UIImage(data: imageData) {
                                    Button {
                                        UIPasteboard.general.image = uiImage
                                    } label: {
                                        Label("Copy Image", systemImage: "doc.on.doc")
                                    }
                                }
                                if imageData != nil {
                                    Button(role: .destructive) {
                                        imageData = nil
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
                                        Label(imageData == nil ? "Choose Photo" : "Change", systemImage: "photo.on.rectangle.angled")
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
                                
                                if imageData != nil {
                                    Button(role: .destructive) {
                                        imageData = nil
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
                
                Section("Origin / Market Location (Map)") {
                    if let latitude, let longitude {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(locationName.isEmpty ? "Selected Location" : locationName)
                                .font(.headline)
                            Text(String(format: "Lat: %.4f, Lon: %.4f", latitude, longitude))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button {
                        showLocationPicker = true
                    } label: {
                        Label(latitude == nil ? "Set Map Location" : "Change Map Location", systemImage: "map")
                    }
                }
                
                Section("Ingredients") {
                    HStack {
                        TextField("Qty (e.g., 2 cups)", text: $newIngQty)
                            .frame(width: 120)
                        TextField("Ingredient name", text: $newIngName)
                        Button("Add") {
                            let trimmedName = newIngName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedName.isEmpty {
                                ingredientsDraft.append((name: trimmedName, quantity: newIngQty.trimmingCharacters(in: .whitespacesAndNewlines)))
                                newIngName = ""
                                newIngQty = ""
                            }
                        }
                        .disabled(newIngName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    ForEach(Array(ingredientsDraft.enumerated()), id: \.offset) { index, ing in
                        HStack {
                            Text(ing.quantity.isEmpty ? ing.name : "\(ing.quantity) \(ing.name)")
                            Spacer()
                            Button {
                                ingredientsDraft.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section("Cooking Steps") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Step Instruction", text: $newStepInstruction, axis: .vertical)
                            .lineLimit(3)
                        
                        HStack {
                            Stepper("Timer: \(newStepTimer) mins", value: $newStepTimer, in: 0...180, step: 1)
                            Spacer()
                            Button("Add Step") {
                                let trimmedInst = newStepInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !trimmedInst.isEmpty {
                                    stepsDraft.append((instruction: trimmedInst, timerMins: newStepTimer))
                                    newStepInstruction = ""
                                    newStepTimer = 0
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(newStepInstruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    
                    ForEach(Array(stepsDraft.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .bold()
                            VStack(alignment: .leading) {
                                Text(step.instruction)
                                if step.timerMins > 0 {
                                    Text("Timer: \(step.timerMins) mins")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Button {
                                stepsDraft.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                Section("Tags") {
                    HStack {
                        TextField("Add tag (e.g. Vegan, Quick)", text: $tagInput)
                        Button("Add") {
                            let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty && !tags.contains(trimmed) {
                                tags.append(trimmed)
                                tagInput = ""
                            }
                        }
                        .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    if !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags, id: \.self) { tag in
                                    HStack {
                                        Text("#\(tag)")
                                        Button {
                                            tags.removeAll { $0 == tag }
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
            }
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Save & Add Another") {
                        saveRecipe(dismissAfter: false)
                    }
                    .font(.caption)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    
                    Button("Save & Done") {
                        saveRecipe(dismissAfter: true)
                    }
                    .font(.headline)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(latitude: $latitude, longitude: $longitude, locationName: $locationName)
            }
            .task(id: selectedPhoto) {
                if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
        }
    }
    
    private func pasteImageFromClipboard() {
        if let pasteboardImage = UIPasteboard.general.image,
           let data = pasteboardImage.pngData() ?? pasteboardImage.jpegData(compressionQuality: 0.9) {
            imageData = data
        } else if let pngData = UIPasteboard.general.data(forPasteboardType: "public.png") {
            imageData = pngData
        } else if let jpegData = UIPasteboard.general.data(forPasteboardType: "public.jpeg") {
            imageData = jpegData
        }
    }
    
    private func resetForm() {
        name = ""
        minutesToCook = 30
        prepTimeMinutes = 15
        servingSize = 4
        selectedCategory = nil
        customCategoryName = ""
        tagInput = ""
        tags = []
        locationName = ""
        latitude = nil
        longitude = nil
        selectedPhoto = nil
        imageData = nil
        ingredientsDraft = []
        newIngName = ""
        newIngQty = ""
        stepsDraft = []
        newStepInstruction = ""
        newStepTimer = 0
    }
    
    private func saveRecipe(dismissAfter: Bool) {
        var targetCategory = selectedCategory
        
        if targetCategory == nil && !customCategoryName.trimmingCharacters(in: .whitespaces).isEmpty {
            let catName = customCategoryName.trimmingCharacters(in: .whitespaces)
            let newCat = CategoryModel(name: catName)
            modelContext.insert(newCat)
            targetCategory = newCat
        }
        
        let newRecipe = RecipeModel(
            name: name,
            image: imageData,
            category: targetCategory,
            minutesToCook: minutesToCook,
            prepTimeMinutes: prepTimeMinutes,
            servingSize: servingSize,
            tags: tags,
            locationName: locationName.isEmpty ? nil : locationName,
            latitude: latitude,
            longitude: longitude
        )
        
        modelContext.insert(newRecipe)
        
        for ing in ingredientsDraft {
            let ingModel = IngredientModel(name: ing.name, quantity: ing.quantity)
            modelContext.insert(ingModel)
            newRecipe.ingredients.append(ingModel)
        }
        
        for (idx, step) in stepsDraft.enumerated() {
            let stepModel = StepModel(stepNumber: idx + 1, instruction: step.instruction, timerDurationMinutes: step.timerMins)
            modelContext.insert(stepModel)
            newRecipe.steps.append(stepModel)
        }
        
        try? modelContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        if dismissAfter {
            dismiss()
        } else {
            resetForm()
        }
    }
}
