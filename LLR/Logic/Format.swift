import Foundation

enum Format {
    static func duration(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval)) / 60
        return minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
    }

    static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let (h, m, s) = (total / 3600, (total % 3600) / 60, total % 60)
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }
}
