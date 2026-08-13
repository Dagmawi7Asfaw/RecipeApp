import SwiftData
import SwiftUI

struct MealPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allMealPlans: [MealPlanModel]
    @Query private var allRecipes: [RecipeModel]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showRecipePicker: Bool = false
    @State private var activeMealTypeToAssign: String = "Dinner"
    @State private var customMealNote: String = ""
    @State private var showSuccessBanner: Bool = false
    @State private var successBannerMessage: String = ""

    private let calendar = Calendar.current

    // MARK: - Computed

    var daysOfWeek: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
            .map { calendar.startOfDay(for: $0) }
    }

    var plansForSelectedDay: [MealPlanModel] {
        allMealPlans.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var weekFilledCount: Int {
        let calendar = Calendar.current
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return 0 }
        return allMealPlans.filter { $0.date >= weekInterval.start && $0.date < weekInterval.end }.count
    }

    var weekTotalSlots: Int { 7 * MealPlanModel.mealTypes.count }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week header strip
                weekHeaderStrip
                    .background(.ultraThinMaterial)

                Divider().opacity(0.4)

                // Day detail content
                dayContent
            }
            .navigationTitle("Meal Planner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showRecipePicker) { recipePickerSheet }
            .overlay(alignment: .bottom) {
                if showSuccessBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill.badge.plus")
                            .foregroundColor(.green)
                        Text(successBannerMessage)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.88))
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                }
            }
        }
    }

    // MARK: - Week Header Strip

    private var weekHeaderStrip: some View {
        VStack(spacing: 8) {
            // Week label & progress
            HStack {
                Text(weekRangeLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(weekFilledCount) of \(weekTotalSlots) slots filled")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // Day bubbles
            HStack(spacing: 8) {
                ForEach(daysOfWeek, id: \.self) { day in
                    dayBubble(day)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }

    private var weekRangeLabel: String {
        guard let first = daysOfWeek.first, let last = daysOfWeek.last else { return "This Week" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return "\(fmt.string(from: first)) – \(fmt.string(from: last))"
    }

    private func dayBubble(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day)
        let hasPlans = allMealPlans.contains { calendar.isDate($0.date, inSameDayAs: day) }

        return Button {
            withAnimation(.spring(response: 0.3)) { selectedDate = day }
        } label: {
            VStack(spacing: 4) {
                Text(fmt(day, "EEE").prefix(1))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .secondary)

                Text(fmt(day, "d"))
                    .font(.system(size: 17, weight: isSelected ? .black : .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : (isToday ? .accentColor : .primary))

                Circle()
                    .fill(hasPlans
                          ? (isSelected ? Color.white : Color.accentColor)
                          : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected
                ? AnyShapeStyle(LinearGradient(colors: [.accentColor, Color(hue: 0.62, saturation: 0.7, brightness: 0.9)], startPoint: .top, endPoint: .bottom))
                : AnyShapeStyle(isToday ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                isToday && !isSelected
                ? AnyView(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.4), lineWidth: 1.5))
                : AnyView(EmptyView())
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Day Content

    private var dayContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Day label
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fmt(selectedDate, "EEEE"))
                            .font(.title3.weight(.bold))
                        Text(fmt(selectedDate, "MMMM d, yyyy"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if plansForSelectedDay.isEmpty {
                        Text("No meals planned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    } else {
                        Text("\(plansForSelectedDay.count) meal\(plansForSelectedDay.count == 1 ? "" : "s")")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                // Meal type slots
                ForEach(MealPlanModel.mealTypes, id: \.self) { mealType in
                    let plan = plansForSelectedDay.first { $0.mealType == mealType }
                    mealSlot(mealType: mealType, plan: plan)
                        .padding(.horizontal, 16)
                }

                Spacer(minLength: 20)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Meal Slot

    private func mealSlot(mealType: String, plan: MealPlanModel?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section label
            HStack {
                Label(mealType, systemImage: mealTypeIcon(mealType))
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(mealTypeColor(mealType))
                Spacer()
                if plan == nil {
                    Button {
                        activeMealTypeToAssign = mealType
                        showRecipePicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.title3)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if let plan {
                mealSlotCard(plan: plan)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            } else {
                Button {
                    activeMealTypeToAssign = mealType
                    showRecipePicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.dashed")
                            .font(.title3)
                            .foregroundColor(.accentColor.opacity(0.6))
                        Text("Add \(mealType)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                            .foregroundColor(Color.secondary.opacity(0.2))
                    )
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Meal Slot Card

    private func mealSlotCard(plan: MealPlanModel) -> some View {
        HStack(spacing: 12) {
            if let recipe = plan.recipe {
                Image(uiImage: recipe.viewImageWithDefault)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Label("\(recipe.totalTimeMinutes)m", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if !recipe.viewCategory.isEmpty {
                            Text(recipe.viewCategory)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 1) {
                        ForEach(0..<recipe.rating, id: \.self) { _ in
                            Image(systemName: "star.fill").font(.system(size: 8)).foregroundColor(.yellow)
                        }
                    }
                }
            } else if let note = plan.customNotes {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 58, height: 58)
                    Image(systemName: "note.text")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(note)
                        .font(.subheadline)
                        .lineLimit(2)
                    Text("Custom note")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 0)

            Button(role: .destructive) {
                withAnimation { modelContext.delete(plan) }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Recipe Picker Sheet

    private var recipePickerSheet: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "pencil.line")
                            .foregroundColor(.accentColor)
                        TextField("e.g. Dining out, Leftovers…", text: $customMealNote)
                        if !customMealNote.isEmpty {
                            Button("Add Note") {
                                assignCustomNote(customMealNote)
                                customMealNote = ""
                                showRecipePicker = false
                            }
                            .font(.caption.weight(.bold))
                            .foregroundColor(.accentColor)
                        }
                    }
                } header: {
                    Label("Custom Note", systemImage: "note.text")
                }

                Section {
                    ForEach(allRecipes) { recipe in
                        Button {
                            assignRecipe(recipe)
                            showRecipePicker = false
                        } label: {
                            HStack(spacing: 12) {
                                Image(uiImage: recipe.viewImageWithDefault)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(recipe.name)
                                        .font(.body.weight(.medium))
                                        .foregroundColor(.primary)
                                    HStack(spacing: 6) {
                                        Text(recipe.viewCategory)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Label("\(recipe.totalTimeMinutes)m", systemImage: "clock")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                } header: {
                    Label("My Recipes (\(allRecipes.count))", systemImage: "book.closed")
                }
            }
            .navigationTitle("Add \(activeMealTypeToAssign)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showRecipePicker = false }
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                addWeekToGroceryList()
            } label: {
                Label("Add Week to Groceries", systemImage: "cart.badge.plus")
            }
        }
    }

    // MARK: - Private Helpers

    private func assignRecipe(_ recipe: RecipeModel) {
        if let existing = plansForSelectedDay.first(where: { $0.mealType == activeMealTypeToAssign }) {
            modelContext.delete(existing)
        }
        let plan = MealPlanModel(date: selectedDate, mealType: activeMealTypeToAssign, recipe: recipe)
        modelContext.insert(plan)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func assignCustomNote(_ note: String) {
        if let existing = plansForSelectedDay.first(where: { $0.mealType == activeMealTypeToAssign }) {
            modelContext.delete(existing)
        }
        let plan = MealPlanModel(date: selectedDate, mealType: activeMealTypeToAssign, customNotes: note)
        modelContext.insert(plan)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func addWeekToGroceryList() {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return }
        let weekPlans = allMealPlans.filter { $0.date >= weekInterval.start && $0.date < weekInterval.end }
        var addedCount = 0
        for plan in weekPlans {
            if let recipe = plan.recipe {
                for ing in recipe.ingredients {
                    let grocery = GroceryItemModel(
                        name: ing.name,
                        quantity: ing.quantity,
                        category: GroceryItemModel.autoCategorize(ingredientName: ing.name),
                        recipeName: recipe.name
                    )
                    modelContext.insert(grocery)
                    addedCount += 1
                }
            }
        }
        withAnimation {
            successBannerMessage = "Added \(addedCount) ingredients to Grocery List!"
            showSuccessBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation { showSuccessBanner = false }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func fmt(_ date: Date, _ format: String) -> String {
        let f = DateFormatter(); f.dateFormat = format; return f.string(from: date)
    }

    private func mealTypeIcon(_ type: String) -> String {
        switch type {
        case "Breakfast": return "sunrise.fill"
        case "Lunch": return "sun.max.fill"
        case "Dinner": return "moon.stars.fill"
        case "Snack": return "apple.logo"
        default: return "fork.knife"
        }
    }

    private func mealTypeColor(_ type: String) -> Color {
        switch type {
        case "Breakfast": return .orange
        case "Lunch": return .yellow
        case "Dinner": return .indigo
        case "Snack": return .green
        default: return .accentColor
        }
    }
}
