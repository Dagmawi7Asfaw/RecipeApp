import EventKit
import SwiftData
import SwiftUI

struct GroceryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GroceryItemModel.dateAdded, order: .reverse) private var allItems: [GroceryItemModel]

    @State private var newItemName: String = ""
    @State private var newItemQuantity: String = ""
    @State private var selectedAisle: String = "Produce"
    @State private var showExportAlert: Bool = false
    @State private var exportMessage: String = ""
    @State private var isAddBarExpanded: Bool = false

    // MARK: - Computed

    var uncheckedCount: Int { allItems.filter { !$0.isChecked }.count }
    var checkedCount: Int { allItems.filter { $0.isChecked }.count }
    var completionRatio: Double {
        guard !allItems.isEmpty else { return 0 }
        return Double(checkedCount) / Double(allItems.count)
    }

    var groupedByAisle: [String: [GroceryItemModel]] {
        Dictionary(grouping: allItems) { $0.category }
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

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Header
                if !allItems.isEmpty {
                    progressHeader
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                }

                // Quick Add Bar
                quickAddBar
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)

                Divider().opacity(0.4)

                // Content
                if allItems.isEmpty {
                    emptyState
                } else {
                    groceryList
                }
            }
            .navigationTitle("Shopping List")
            .toolbar { toolbarItems }
            .alert("Export Status", isPresented: $showExportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(exportMessage)
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(checkedCount) of \(allItems.count) items")
                        .font(.subheadline.weight(.bold))
                    Text(progressLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 5)
                        .frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0, to: completionRatio)
                        .stroke(
                            LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 44, height: 44)
                        .animation(.spring(response: 0.5), value: completionRatio)
                    Text("\(Int(completionRatio * 100))%")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 6)
                    Capsule()
                        .fill(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, geo.size.width * completionRatio), height: 6)
                        .animation(.spring(response: 0.5), value: completionRatio)
                }
            }
            .frame(height: 6)
        }
    }

    private var progressLabel: String {
        if completionRatio == 0 { return "Let's get shopping!" }
        if completionRatio < 0.5 { return "Keep going!" }
        if completionRatio < 1.0 { return "Almost done!" }
        return "All done! 🎉"
    }

    // MARK: - Quick Add Bar

    private var quickAddBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.accentColor)

                TextField("Add grocery item…", text: $newItemName)
                    .onTapGesture { withAnimation(.spring(response: 0.3)) { isAddBarExpanded = true } }

                if !newItemName.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button("Add") { addItem() }
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if isAddBarExpanded {
                HStack(spacing: 8) {
                    TextField("Qty (e.g. 2 lbs)", text: $newItemQuantity)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .frame(maxWidth: 130)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(GroceryItemModel.aisles, id: \.self) { aisle in
                                Button {
                                    selectedAisle = aisle
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: iconForAisle(aisle))
                                            .font(.system(size: 9, weight: .semibold))
                                        Text(aisle)
                                            .font(.caption.weight(selectedAisle == aisle ? .bold : .regular))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(selectedAisle == aisle ? Color.accentColor : Color.secondary.opacity(0.12))
                                    .foregroundColor(selectedAisle == aisle ? .white : .primary)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - Grocery List

    private var groceryList: some View {
        List {
            ForEach(GroceryItemModel.aisles, id: \.self) { aisle in
                if let items = groupedByAisle[aisle], !items.isEmpty {
                    Section {
                        ForEach(items) { item in
                            groceryRow(item)
                                .listRowBackground(
                                    item.isChecked
                                    ? Color.green.opacity(0.04)
                                    : Color(.secondarySystemGroupedBackground)
                                )
                        }
                        .onDelete { idx in deleteItems(items: items, at: idx) }
                    } header: {
                        aisleHeader(aisle, items: items)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "Your List is Empty",
            systemImage: "cart",
            description: Text("Add items above, or tap 'Add to Groceries' inside any recipe.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Aisle Header

    private func aisleHeader(_ title: String, items: [GroceryItemModel]) -> some View {
        let done = items.filter(\.isChecked).count
        return HStack(spacing: 8) {
            Image(systemName: iconForAisle(title))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(aisleColor(title))
                .frame(width: 22, height: 22)
                .background(aisleColor(title).opacity(0.12))
                .clipShape(Circle())

            Text(title)
                .font(.subheadline.weight(.bold))

            Spacer()

            Text("\(done)/\(items.count)")
                .font(.caption)
                .foregroundColor(done == items.count ? .green : .secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(done == items.count ? Color.green.opacity(0.12) : Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    // MARK: - Grocery Row

    private func groceryRow(_ item: GroceryItemModel) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    item.isChecked.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(item.isChecked ? Color.green : Color.secondary.opacity(0.4), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if item.isChecked {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .strikethrough(item.isChecked, color: .secondary)
                    .foregroundColor(item.isChecked ? .secondary : .primary)
                    .animation(.easeInOut(duration: 0.2), value: item.isChecked)

                if let recipeName = item.recipeName {
                    Label("For \(recipeName)", systemImage: "fork.knife")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
            }

            Spacer(minLength: 0)

            if !item.quantity.isEmpty {
                Text(item.quantity)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .swipeActions(edge: .leading) {
            Button {
                item.isChecked.toggle()
            } label: {
                Label(item.isChecked ? "Uncheck" : "Done", systemImage: item.isChecked ? "xmark.circle" : "checkmark.circle")
            }
            .tint(item.isChecked ? .orange : .green)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if !allItems.isEmpty {
                ShareLink(item: shareableListText) {
                    Image(systemName: "square.and.arrow.up")
                }

                Menu {
                    if checkedCount > 0 {
                        Button {
                            withAnimation { clearChecked() }
                        } label: {
                            Label("Clear Completed (\(checkedCount))", systemImage: "checklist.checked")
                        }
                    }
                    Button(role: .destructive) {
                        withAnimation { clearAll() }
                    } label: {
                        Label("Clear All Items", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    // MARK: - Helpers

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

    private func aisleColor(_ aisle: String) -> Color {
        switch aisle {
        case "Produce": return .green
        case "Dairy & Eggs": return .yellow
        case "Meat & Seafood": return .red
        case "Bakery": return .orange
        case "Pantry": return .brown
        case "Spices & Seasonings": return .pink
        case "Frozen": return .cyan
        default: return .accentColor
        }
    }

    private func addItem() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let item = GroceryItemModel(
            name: name,
            quantity: newItemQuantity.trimmingCharacters(in: .whitespaces),
            category: selectedAisle
        )
        modelContext.insert(item)
        newItemName = ""
        newItemQuantity = ""
        withAnimation(.spring(response: 0.3)) { isAddBarExpanded = false }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func deleteItems(items: [GroceryItemModel], at offsets: IndexSet) {
        for index in offsets { modelContext.delete(items[index]) }
    }

    private func clearChecked() {
        allItems.filter(\.isChecked).forEach { modelContext.delete($0) }
    }

    private func clearAll() {
        allItems.forEach { modelContext.delete($0) }
    }
}
