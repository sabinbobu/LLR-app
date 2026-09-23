import SwiftUI

struct BirthdayStep: View {
    // 1996-01-01: a neutral starting point so the wheel doesn't open on today's date.
    @AppStorage(StorageKey.birthday) private var birthday: Double = 820_454_400
    let next: () -> Void

    private var date: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: birthday) },
            set: { birthday = $0.timeIntervalSince1970 }
        )
    }

    var body: some View {
        OnboardingScaffold(title: "When is your birthday?", showsPrivacyNote: true, onContinue: next) {
            DatePicker("Birthday", selection: date, in: ...Date.now, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
