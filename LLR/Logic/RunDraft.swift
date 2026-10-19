import Foundation

/// What the Add Run sheet has typed so far, kept as text so a half-typed number never fights the field.
struct RunDraft: Equatable {
    var kmText = ""
    var hoursText = ""
    var minutesText = ""
    var secondsText = ""

    /// Accepts "10.5" and "10,5".
    var distanceKm: Double? {
        let trimmed = kmText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        return Double(trimmed)
    }

    /// Empty time fields count as zero; a non-number in any of them makes the time invalid (nil).
    /// Summed as Doubles: a long run of digits in the hours field would overflow Int and crash.
    var seconds: Double? {
        guard let h = part(hoursText), let m = part(minutesText), let s = part(secondsText) else { return nil }
        return Double(h) * 3600 + Double(m) * 60 + Double(s)
    }

    private func part(_ text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return 0 }
        guard let value = Int(trimmed), value >= 0 else { return nil }
        return value
    }

    var isValid: Bool {
        guard let km = distanceKm, let seconds else { return false }
        return RunLoad.isPlausible(km: km, seconds: seconds)
    }

    /// Only speaks up once both numbers exist and the pair cannot be a real run.
    var problem: String? {
        guard let km = distanceKm, let seconds, km > 0, seconds > 0 else { return nil }
        return RunLoad.isPlausible(km: km, seconds: seconds) ? nil : "That pace looks off. Check the distance and the time."
    }
}
