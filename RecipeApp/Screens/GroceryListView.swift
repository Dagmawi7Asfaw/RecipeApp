import EventKit
import SwiftData
import SwiftUI

struct GroceryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GroceryItemModel.dateAdded, order: .reverse) private var allItems: [GroceryItemModel]
    
    @State private var newItemName: String = ""
    @State private var newItemQuantity: String = ""
    @State private var selectedAisle: String = "Produce"
    @State private var filterRecipe: String? = nil
    @State private var showExportAlert: Bool = false
    @State private var exportMessage: String = ""
    
    var activeItems: [GroceryItemModel] {
        allItems.filter { item in
            if let filterRecipe, item.recipeName != filterRecipe {
                return false
            }
            return true
        }
    }
    
    var uncheckedCount: Int {
        activeItems.filter { !$0.isChecked }.count
    }
    
    var groupedByAisle: [String: [GroceryItemModel]] {
        Dictionary(grouping: activeItems) { $0.category }
    }
    
    var shareableListText: String {
        var text = "🛒 GROCERY SHOPPING LIST\n\n"
        for aisle in GroceryItemModel.aisles {
            if let items = groupedByAisle[aisle], !items.isEmpty {
                text += "📦 \(aisle.uppercased()):\n"
                for item in items {
                    let mark = item.isChecked ? "✅" : "⬜️"
                    let qty = item.quantity.isEmpty ? "" : " (\(item.quantity))"
                    text += "\(mark) \(item.name)\(qty)\n"
                }
                text += "\n"
            }
        }
        return text
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick Add Item Bar
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        TextField("Add grocery item...", text: $newItemName)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Qty (e.g. 2 lbs)", text: $newItemQuantity)
                            .frame(width: 110)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            addItem()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                        }
                        .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    
                    // Aisle Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(GroceryItemModel.aisles, id: \.self) { aisle in
                                Button {
                                    selectedAisle = aisle
                                } label: {
                                    Text(aisle)
                                        .font(.caption.weight(selectedAisle == aisle ? .bold : .regular))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(selectedAisle == aisle ? Color.accentColor : Color.secondary.opacity(0.15))
                                        .foregroundColor(selectedAisle == aisle ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                
                // List of items
                if activeItems.isEmpty {
                    ContentUnavailableView(
                        "Your Grocery List is Empty",
                        systemImage: "cart",
                        description: Text("Add items above or tap 'Add to Grocery List' inside any recipe to plan your shopping!")
                    )
                } else {
                    List {
                        ForEach(GroceryItemModel.aisles, id: \.self) { aisle in
                            if let items = groupedByAisle[aisle], !items.isEmpty {
                                Section(header: aisleHeader(aisle, count: items.count)) {
                                    ForEach(items) { item in
                                        groceryRow(item)
                                    }
                                    .onDelete { indexSet in
                                        deleteItems(items: items, at: indexSet)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Shopping List (\(uncheckedCount))")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !activeItems.isEmpty {
                        ShareLink(item: shareableListText) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        
                        Menu {
                            Button(role: .destructive) {
                                clearChecked()
                            } label: {
                                Label("Clear Completed", systemImage: "checklist.checked")
                            }
                            
                            Button(role: .destructive) {
                                clearAll()
                            } label: {
                                Label("Clear All Items", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Export Status", isPresented: $showExportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(exportMessage)
            }
        }
    }
    
    private func aisleHeader(_ title: String, count: Int) -> some View {
        HStack {
            Label(title, systemImage: iconForAisle(title))
                .font(.headline)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func iconForAisle(_ aisle: String) -> String {
        switch aisle {
        case "Produce": return "leaf"
        case "Dairy & Eggs": return "cup.and.saucer"
        case "Meat & Seafood": return "fish"
        case "Bakery": return "birthday.cake"
        case "Pantry": return "archivebox"
        case "Spices & Seasonings": return "flame"
        case "Frozen": return "snowflake"
        default: return "bag"
        }
    }
    
    private func groceryRow(_ item: GroceryItemModel) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    item.isChecked.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.isChecked ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .secondary : .primary)
                
                if let recipeName = item.recipeName {
                    Text("For \(recipeName)")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
            
            if !item.quantity.isEmpty {
                Text(item.quantity)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
    
    private func addItem() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        
        let qty = newItemQuantity.trimmingCharacters(in: .whitespaces)
        let aisle = selectedAisle
        
        let item = GroceryItemModel(
            name: name,
            quantity: qty,
            category: aisle
        )
        modelContext.insert(item)
        
        newItemName = ""
        newItemQuantity = ""
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func deleteItems(items: [GroceryItemModel], at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            modelContext.delete(item)
        }
    }
    
    private func clearChecked() {
        let checked = allItems.filter { $0.isChecked }
        for item in checked {
            modelContext.delete(item)
        }
    }
    
    private func clearAll() {
        for item in allItems {
            modelContext.delete(item)
        }
    }
}
