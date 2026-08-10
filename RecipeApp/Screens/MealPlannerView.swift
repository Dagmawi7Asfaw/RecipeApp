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
    @State private var showCustomNoteAlert: Bool = false
    @State private var showSuccessBanner: Bool = false
    @State private var successBannerMessage: String = ""
    
    var daysOfWeek: [Date] {
        let calendar = Calendar.current
        let today = selectedDate
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else { return [] }
        var days: [Date] = []
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: weekInterval.start) {
                days.append(calendar.startOfDay(for: day))
            }
        }
        return days
    }
    
    var plansForSelectedDay: [MealPlanModel] {
        allMealPlans.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Horizontal Day Strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(daysOfWeek, id: \.self) { day in
                            let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                            let isToday = Calendar.current.isDateInToday(day)
                            
                            Button {
                                selectedDate = day
                            } label: {
                                VStack(spacing: 4) {
                                    Text(dayFormatter(day, format: "EEE"))
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(isSelected ? .white : .secondary)
                                    
                                    Text(dayFormatter(day, format: "d"))
                                        .font(.headline.weight(isSelected ? .bold : .semibold))
                                        .foregroundColor(isSelected ? .white : .primary)
                                    
                                    if isToday {
                                        Circle()
                                            .fill(isSelected ? .white : Color.accentColor)
                                            .frame(width: 4, height: 4)
                                    }
                                }
                                .frame(width: 46, height: 64)
                                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(.ultraThinMaterial)
                
                // Meal Slots for the Day
                List {
                    ForEach(MealPlanModel.mealTypes, id: \.self) { mealType in
                        let plan = plansForSelectedDay.first { $0.mealType == mealType }
                        
                        Section(header: Text(mealType)) {
                            if let plan {
                                mealSlotCard(plan: plan)
                            } else {
                                Button {
                                    activeMealTypeToAssign = mealType
                                    showRecipePicker = true
                                } label: {
                                    Label("Schedule \(mealType)", systemImage: "plus.circle.dashed")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Weekly Meal Planner")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        addWeekToGroceryList()
                    } label: {
                        Label("Add Week to Groceries", systemImage: "cart.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showRecipePicker) {
                recipePickerSheet
            }
            .overlay(alignment: .bottom) {
                if showSuccessBanner {
                    Text(successBannerMessage)
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
    }
    
    private func mealSlotCard(plan: MealPlanModel) -> some View {
        HStack(spacing: 12) {
            if let recipe = plan.recipe {
                if let image = recipe.viewImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.name)
                        .font(.body.weight(.semibold))
                    
                    Text("\(recipe.totalTimeMinutes) mins • \(recipe.viewCategory)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let note = plan.customNotes {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text(note)
                    .font(.body)
            }
            
            Spacer()
            
            Button(role: .destructive) {
                modelContext.delete(plan)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
    
    private var recipePickerSheet: some View {
        NavigationStack {
            List {
                Section("Custom Meal Note") {
                    HStack {
                        TextField("e.g. Dining out, Leftovers...", text: $customMealNote)
                        Button("Add") {
                            if !customMealNote.isEmpty {
                                assignCustomNote(customMealNote)
                                customMealNote = ""
                                showRecipePicker = false
                            }
                        }
                        .disabled(customMealNote.isEmpty)
                    }
                }
                
                Section("Select from My Recipes") {
                    ForEach(allRecipes) { recipe in
                        Button {
                            assignRecipe(recipe)
                            showRecipePicker = false
                        } label: {
                            HStack(spacing: 12) {
                                if let image = recipe.viewImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(recipe.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text(recipe.viewCategory)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Assign \(activeMealTypeToAssign)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showRecipePicker = false }
                }
            }
        }
    }
    
    private func assignRecipe(_ recipe: RecipeModel) {
        // Remove existing for this slot
        if let existing = plansForSelectedDay.first(where: { $0.mealType == activeMealTypeToAssign }) {
            modelContext.delete(existing)
        }
        
        let plan = MealPlanModel(
            date: selectedDate,
            mealType: activeMealTypeToAssign,
            recipe: recipe
        )
        modelContext.insert(plan)
    }
    
    private func assignCustomNote(_ note: String) {
        if let existing = plansForSelectedDay.first(where: { $0.mealType == activeMealTypeToAssign }) {
            modelContext.delete(existing)
        }
        
        let plan = MealPlanModel(
            date: selectedDate,
            mealType: activeMealTypeToAssign,
            customNotes: note
        )
        modelContext.insert(plan)
    }
    
    private func addWeekToGroceryList() {
        let calendar = Calendar.current
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
            successBannerMessage = "Added \(addedCount) ingredients from this week's plan to your Grocery List!"
            showSuccessBanner = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                showSuccessBanner = false
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func dayFormatter(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
