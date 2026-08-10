import SwiftData
import SwiftUI

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var categories: [CategoryModel]
    
    @State private var newCategoryName: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("Add Category") {
                    HStack {
                        TextField("New Category Name", text: $newCategoryName)
                        Button("Add") {
                            addCategory()
                        }
                        .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                
                Section("Existing Categories") {
                    ForEach(categories) { category in
                        HStack {
                            Text(category.name)
                                .font(.headline)
                            Spacer()
                            Text("\(category.recipes.count) recipes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete(perform: deleteCategories)
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addCategory() {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let category = CategoryModel(name: trimmed)
        modelContext.insert(category)
        newCategoryName = ""
    }
    
    private func deleteCategories(indexSet: IndexSet) {
        for index in indexSet {
            let category = categories[index]
            // Remove category association from recipes before deleting
            for recipe in category.recipes {
                recipe.category = nil
            }
            modelContext.delete(category)
        }
    }
}
