import PhotosUI
import SwiftData
import SwiftUI

/// Everything onboarding asked, editable afterwards. Writes the same keys onboarding does, so Fuel's
/// targets and the rest of the app pick changes up with no extra wiring.
struct ProfileDetailsView: View {
    @Binding var avatar: UIImage?
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<BodyMeasurement> { $0.kindRaw == "bodyWeight" }, sort: \BodyMeasurement.takenAt, order: .reverse)
    private var weights: [BodyMeasurement]
    @AppStorage(StorageKey.displayName) private var name = ""
    @AppStorage(StorageKey.gender) private var gender: Gender?
    @AppStorage(StorageKey.birthday) private var birthday: Double = 820_454_400
    @AppStorage(StorageKey.heightCm) private var heightCm = 170
    @AppStorage(StorageKey.goal) private var goal: TrainingGoal?
    @AppStorage(StorageKey.experience) private var experience: Experience?
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    @AppStorage(StorageKey.fuelActivity) private var activityRaw = ActivityLevel.moderate.rawValue
    @State private var pickerItem: PhotosPickerItem?
    @State private var heightAtOpen: Int?

    private var birthdayDate: Binding<Date> {
        Binding(get: { Date(timeIntervalSince1970: birthday) }, set: { birthday = $0.timeIntervalSince1970 })
    }

    private var calorieTarget: Double {
        NutritionTargets.auto(NutritionTargets.profile(latestWeightKg: weights.first?.value)).kcal
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        AvatarView(image: avatar, name: name, size: 104)
                            .overlay(alignment: .bottomTrailing) {
                                Image(systemName: "camera.fill").font(.footnote).foregroundStyle(.white)
                                    .padding(8).background(Theme.accent, in: Circle())
                            }
                    }
                    .accessibilityLabel("Change photo")
                    Spacer()
                }
                .listRowBackground(Color.clear)
                if avatar != nil {
                    Button("Remove photo", role: .destructive) { AvatarStore.delete(); avatar = nil }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            }
            Section("You") {
                TextField("Name", text: $name).textContentType(.name)
                Picker("Sex", selection: $gender) {
                    Text("Not set").tag(Gender?.none)
                    ForEach(Gender.allCases) { Text($0.title).tag(Gender?.some($0)) }
                }
                DatePicker("Birthday", selection: birthdayDate, in: ...Date.now, displayedComponents: .date)
                Stepper(value: $heightCm, in: 120...230) {
                    LabeledContent("Height", value: "\(unit.formatLength(cm: Double(heightCm))) \(unit.lengthSuffix)")
                }
            }
            Section {
                Picker("Goal", selection: $goal) {
                    Text("Not set").tag(TrainingGoal?.none)
                    ForEach(TrainingGoal.allCases) { Label($0.title, systemImage: $0.icon).tag(TrainingGoal?.some($0)) }
                }
                Picker("Experience", selection: $experience) {
                    Text("Not set").tag(Experience?.none)
                    ForEach(Experience.allCases) { Text("\($0.title) · \($0.detail)").tag(Experience?.some($0)) }
                }
                Picker("Activity", selection: $activityRaw) {
                    ForEach(ActivityLevel.allCases) { Text($0.title).tag($0.rawValue) }
                }
                Picker("Units", selection: $unit) {
                    ForEach(WeightUnit.allCases) { Text($0.rawValue).tag($0) }
                }
            } header: {
                Text("Training")
            } footer: {
                Text("Sex, birthday, height, weight, goal and activity set your Fuel targets: \(Int(calorieTarget)) kcal a day right now.")
                    .contentTransition(.numericText())
            }
        }
        .navigationTitle("Personal Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { heightAtOpen = heightCm }
        .onDisappear(perform: recordHeightChange)
        .onChange(of: pickerItem) { _, item in
            Task {
                guard let data = try? await item?.loadTransferable(type: Data.self) else { return }
                AvatarStore.save(data)
                avatar = AvatarStore.load()
            }
        }
    }

    /// One history row per edit session, not one per stepper tap.
    private func recordHeightChange() {
        guard let heightAtOpen, heightAtOpen != heightCm else { return }
        context.insert(BodyMeasurement(kind: .height, value: Double(heightCm)))
    }
}
