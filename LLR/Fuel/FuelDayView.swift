import SwiftData
import SwiftUI

/// One day's summary and meals. A separate view so its `@Query` can be rebuilt with that day's
/// bounds instead of loading every entry ever logged.
struct FuelDayView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [FoodEntry]
    let targets: Macros
    @State private var editing: FoodEntry?

    init(day: Date, targets: Macros) {
        let (start, end) = FoodLogTime.dayBounds(day)
        _entries = Query(filter: #Predicate<FoodEntry> { $0.loggedAt >= start && $0.loggedAt < end },
                         sort: \FoodEntry.loggedAt)
        self.targets = targets
    }

    private var total: Macros { DailyNutrition.total(entries) }

    var body: some View {
        VStack(spacing: 20) {
            summaryCard
            if entries.isEmpty {
                EmptyStateCard(systemImage: "fork.knife", message: "Nothing logged yet")
            } else {
                ForEach(DailyNutrition.byMeal(entries), id: \.meal) { group in
                    mealCard(group.meal, group.entries)
                }
            }
        }
        .sheet(item: $editing) { FoodEditView(entry: $0) }
    }

    private var summaryCard: some View {
        VStack(spacing: 22) {
            MacroRing(value: total.kcal, target: targets.kcal)
                .frame(width: 210, height: 210)
            VStack(spacing: 14) {
                MacroBar(title: "Protein", value: total.proteinG, target: targets.proteinG, color: Theme.protein)
                MacroBar(title: "Carbs", value: total.carbsG, target: targets.carbsG, color: Theme.carbs)
                MacroBar(title: "Fat", value: total.fatG, target: targets.fatG, color: Theme.fat)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private func mealCard(_ meal: Meal, _ items: [FoodEntry]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(meal.title, systemImage: meal.icon).font(.headline)
                Spacer()
                Text("\(Int(DailyNutrition.total(items).kcal)) kcal")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)
            ForEach(items) { entry in
                Divider()
                FoodEntryRow(entry: entry)
                    .contentShape(Rectangle())
                    .onTapGesture { editing = entry }
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            withAnimation { context.delete(entry) }
                        }
                    }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}
