import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct DataTransferView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(StorageKey.weightUnit) private var unit: WeightUnit = .kg
    // Gym only: a Strong-format row can't carry pain, and reimporting it would turn a rehab
    // session into gym history. Kineto gets its own export (see the Kineto log CSV).
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil && $0.sectionRaw == "gym" }) private var finished: [Workout]
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil && $0.sectionRaw == "kineto" }) private var kinetoFinished: [Workout]
    @State private var strongUnit: WeightUnit?
    @State private var choosingFile = false
    @State private var outcome: Outcome?

    private enum Outcome {
        case imported(WorkoutCSV.Source, ImportSummary)
        case failed(String)
    }

    private var exportFile: CSVFile {
        let day = WorkoutCSV.strongDate.string(from: .now).prefix(10)
        return CSVFile(name: "LLR-workouts-\(day).csv", text: WorkoutExport.strongCSV(finished, unit: unit))
    }

    private var kinetoExportFile: CSVFile {
        let day = WorkoutCSV.strongDate.string(from: .now).prefix(10)
        return CSVFile(name: "LLR-kineto-\(day).csv", text: WorkoutExport.kinetoCSV(kinetoFinished))
    }

    var body: some View {
        Form {
            Section {
                Button("Choose Hevy or Strong CSV", systemImage: "square.and.arrow.down") { choosingFile = true }
                Picker("Strong file unit", selection: Binding(get: { strongUnit ?? unit }, set: { strongUnit = $0 })) {
                    ForEach(WeightUnit.allCases) { Text($0.rawValue).tag($0) }
                }
            } header: {
                Text("Import")
            } footer: {
                Text("Hevy: Settings › Export & Import Data › Export Workouts. Strong: Settings › Export Data. Strong files don't record their unit, so pick the one you logged in. Importing a file twice skips workouts already here.")
            }

            if let outcome {
                Section("Last import") { outcomeRows(outcome) }
            }

            Section {
                ShareLink(item: exportFile, preview: SharePreview("LLR workouts")) {
                    Label("Export workouts", systemImage: "square.and.arrow.up")
                }
                .disabled(finished.isEmpty)
            } header: {
                Text("Export")
            } footer: {
                Text("A Strong-format CSV in \(unit.rawValue): Hevy's Strong import reads it, and so does LLR. LLR doesn't sync, so this is how your history leaves the phone.")
            }

            Section {
                ShareLink(item: kinetoExportFile, preview: SharePreview("LLR Kineto log")) {
                    Label("Export Kineto log", systemImage: "square.and.arrow.up")
                }
                .disabled(kinetoFinished.isEmpty)
            } header: {
                Text("Kineto")
            } footer: {
                Text("A separate CSV with sets as reps × seconds and your back/leg pain before and after each session. Not part of the Strong-format export above.")
            }
        }
        .navigationTitle("Import & Export")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $choosingFile, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            outcome = importFile(result)
        }
    }

    @ViewBuilder
    private func outcomeRows(_ outcome: Outcome) -> some View {
        switch outcome {
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle").foregroundStyle(.red)
        case .imported(let source, let summary):
            LabeledContent("Source", value: source.rawValue)
            LabeledContent("Workouts added", value: "\(summary.workouts)")
            LabeledContent("Sets added", value: "\(summary.sets)")
            if summary.duplicates > 0 {
                LabeledContent("Already here, skipped", value: "\(summary.duplicates)")
            }
            if summary.skippedTimedSets > 0 {
                LabeledContent("Timed or cardio sets skipped", value: "\(summary.skippedTimedSets)")
            }
            if !summary.newExercises.isEmpty {
                LabeledContent("New custom exercises", value: summary.newExercises.joined(separator: ", "))
            }
        }
    }

    private func importFile(_ result: Result<URL, Error>) -> Outcome {
        do {
            let url = try result.get()
            // Files picked outside the app's container are only readable inside this access window.
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let text = try String(contentsOf: url, encoding: .utf8)
            let parsed = try WorkoutCSV.parse(text, strongUnit: strongUnit ?? unit)
            let summary = WorkoutImporter.apply(parsed, into: context)
            // Imported sessions can extend the streak; refresh the widget like Finish does.
            if summary.workouts > 0 { TrainingSnapshotSync.sync(context: context) }
            return .imported(parsed.source, summary)
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
