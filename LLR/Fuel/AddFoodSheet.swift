import PhotosUI
import SwiftUI

struct AddFoodSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(StorageKey.fuelModel) private var model = OpenRouterClient.defaultModel
    let day: Date

    @State private var photo: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var note = ""
    @State private var analyzing = false
    @State private var errorMessage: String?
    @State private var review: FoodAnalysis.Result?
    @State private var identified: IdentifiedMeal?
    @State private var reviewPhoto: Data?
    @State private var manual = false
    @FocusState private var noteFocused: Bool

    private var hasKey: Bool { !(KeychainStore.get(StorageKey.openRouterKey) ?? "").isEmpty }
    private var canAnalyze: Bool { hasKey && !analyzing && (photo != nil || !note.trimmingCharacters(in: .whitespaces).isEmpty) }

    /// A past day gets midday rather than "now", so it lands on that day with a sensible meal default.
    private var loggedAt: Date {
        Calendar.current.isDateInToday(day) ? .now
            : Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    photoArea
                    TextField(photo == nil ? "Describe it: 200 g chicken, 150 g rice…" : "Add a note (optional): portion, sauce…",
                              text: $note, axis: .vertical)
                        .lineLimit(2...5)
                        .focused($noteFocused)
                        .padding(14)
                        .background(Theme.field, in: RoundedRectangle(cornerRadius: 14))
                    if !hasKey {
                        Label("Add your OpenRouter key in Fuel settings to use AI estimates.", systemImage: "key")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote).foregroundStyle(Theme.over)
                    }
                    Button(action: analyze) {
                        if analyzing {
                            HStack(spacing: 10) { ProgressView().tint(.white); Text("Analyzing…") }
                        } else {
                            Label("Estimate macros", systemImage: "sparkles")
                        }
                    }
                    .buttonStyle(SheetButtonStyle())
                    .disabled(!canAnalyze)
                    Button("Enter manually instead") { manual = true }
                        .font(.subheadline.weight(.medium))
                }
                .padding()
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Cancel") { dismiss() } }
            .navigationDestination(item: $review) { result in
                FoodReviewView(result: result, photoData: reviewPhoto, loggedAt: loggedAt) { dismiss() }
            }
            .navigationDestination(item: $identified) { meal in
                IngredientCorrectionView(meal: meal, loggedAt: loggedAt) { dismiss() }
            }
            .sheet(isPresented: $manual) { FoodEditView(newAt: loggedAt) { dismiss() } }
            .fullScreenCover(isPresented: $showingCamera) { CameraPicker(image: $photo).ignoresSafeArea() }
            .onChange(of: pickerItem) { _, item in
                Task.detached(priority: .userInitiated) {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run { photo = image }
                    }
                }
            }
        }
    }

    private var photoArea: some View {
        Group {
            if let photo {
                Image(uiImage: photo)
                    .resizable().scaledToFill()
                    .frame(height: 240).frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(alignment: .topTrailing) {
                        Button { self.photo = nil; pickerItem = nil } label: {
                            Image(systemName: "xmark.circle.fill").font(.title2).symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.5))
                        }
                        .padding(10)
                    }
            } else {
                HStack(spacing: 12) {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        sourceTile("Camera", "camera.fill") { showingCamera = true }
                    }
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        tileLabel("Library", "photo.on.rectangle")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sourceTile(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { tileLabel(title, icon) }.buttonStyle(.plain)
    }

    private func tileLabel(_ title: String, _ icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 30))
            Text(title).font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(Theme.accent)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Theme.accent.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [6])))
    }

    private func analyze() {
        noteFocused = false
        errorMessage = nil
        analyzing = true
        // 1024 px is plenty to recognise food and keeps the upload small on mobile data.
        let jpeg = photo.flatMap { ImageDownscale.jpeg($0, maxDimension: 1024, quality: 0.8) }
        let key = KeychainStore.get(StorageKey.openRouterKey) ?? ""
        Task {
            defer { analyzing = false }
            do {
                let thumbnail = photo.flatMap { ImageDownscale.jpeg($0, maxDimension: 512, quality: 0.7) }
                if let jpeg {
                    // Photos get a correction step first: portion guesses are the biggest error source.
                    let list = try await OpenRouterClient.identify(jpeg: jpeg, note: note, key: key, model: model)
                    identified = IdentifiedMeal(ingredients: list, photoData: thumbnail)
                } else {
                    review = try await OpenRouterClient.analyze(.text(note), key: key, model: model)
                    reviewPhoto = nil
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

extension FoodAnalysis.Result: Hashable, Identifiable {
    var id: [UUID] { items.map(\.id) }
    static func == (a: Self, b: Self) -> Bool { a.id == b.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
