import SwiftUI

/// A per-exercise rest override: nil follows the global default, 0 turns the timer off.
struct RestTimerPicker: View {
    @Binding var selection: Int?

    var body: some View {
        Picker("Rest timer", selection: $selection) {
            Text("Default").tag(Int?.none)
            ForEach(RestDuration.choices, id: \.self) { Text(RestDuration.label($0)).tag(Int?.some($0)) }
            Text("Off").tag(Int?.some(0))
        }
    }
}
