import SwiftData
import SwiftUI

struct FuelView: View {
    @Query(filter: #Predicate<BodyMeasurement> { $0.kindRaw == "bodyWeight" }, sort: \BodyMeasurement.takenAt, order: .reverse)
    private var weights: [BodyMeasurement]
    // Read here only so the targets recompute the moment settings change.
    @AppStorage(StorageKey.fuelActivity) private var activityRaw = ActivityLevel.moderate.rawValue
    @AppStorage(StorageKey.fuelKcalOverride) private var kcalOverride = 0.0
    @AppStorage(StorageKey.fuelProteinOverride) private var proteinOverride = 0.0
    @AppStorage(StorageKey.fuelCarbsOverride) private var carbsOverride = 0.0
    @AppStorage(StorageKey.fuelFatOverride) private var fatOverride = 0.0

    @State private var day = Calendar.current.startOfDay(for: .now)
    @State private var adding = false
    @State private var pickingDay = false
    @State private var showingSettings = false

    private var targets: Macros {
        NutritionTargets.resolved(
            auto: NutritionTargets.auto(NutritionTargets.profile(latestWeightKg: weights.first?.value)),
            overrides: Macros(kcal: kcalOverride, proteinG: proteinOverride, carbsG: carbsOverride, fatG: fatOverride)
        )
    }

    private var isToday: Bool { Calendar.current.isDateInToday(day) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    daySwitcher
                    FuelDayView(day: day, targets: targets)
                }
                .padding()
                .padding(.bottom, 80)
            }
            .background(Theme.background)
            .navigationTitle("Fuel")
            .toolbar {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            .overlay(alignment: .bottomTrailing) { addButton }
            .sheet(isPresented: $adding) { AddFoodSheet(day: day) }
            .sheet(isPresented: $showingSettings) { FuelSettingsView() }
            .sheet(isPresented: $pickingDay) { FuelDayPickerSheet(day: $day) }
        }
    }

    private var daySwitcher: some View {
        HStack {
            Button { shiftDay(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 36) }
            Spacer()
            Button { pickingDay = true } label: {
                HStack(spacing: 4) {
                    Text(isToday ? "Today" : day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                        .font(.headline)
                        .contentTransition(.numericText())
                    Image(systemName: "chevron.down").font(.caption.weight(.bold))
                }
            }
            .accessibilityHint("Pick a day")
            Spacer()
            Button { shiftDay(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 36) }
                .disabled(isToday)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.accent)
    }

    private var addButton: some View {
        Button {
            adding = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Theme.accent, in: Circle())
                .shadow(color: Theme.accent.opacity(0.4), radius: 12, y: 6)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 90)
        .sensoryFeedback(.impact(weight: .light), trigger: adding)
    }

    private func shiftDay(_ delta: Int) {
        guard let next = Calendar.current.date(byAdding: .day, value: delta, to: day) else { return }
        withAnimation(.snappy) { day = next }
    }
}
