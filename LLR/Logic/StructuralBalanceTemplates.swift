import Foundation

/// The published tables, numbers transcribed from the articles named in each `citation`.
/// Rows whose exercise the library doesn't have are left out and named in `note`.
extension StructuralBalance {
    static let templates = [thibaudeau, poliquin]

    private static let bench = ["Bench Press (Barbell)"]
    private static let squat = ["Squat (Barbell)"]
    private static let deadlift = ["Deadlift (Barbell)"]
    private static let closeGrip = ["Bench Press - Close Grip (Barbell)"]
    private static let incline = ["Incline Bench Press (Barbell)"]
    private static let militaryPress = ["Standing Military Press (Barbell)", "Overhead Press (Barbell)"]
    private static let chinUp = ["Chin Up", "Chin Up (Weighted)", "Chin Up (Assisted)"]
    private static let dip = [
        "Chest Dip", "Chest Dip (Weighted)", "Chest Dip (Assisted)",
        "Triceps Dip", "Triceps Dip (Weighted)", "Triceps Dip (Assisted)",
    ]

    static let thibaudeau = Template(
        id: "thibaudeau",
        title: "Thibaudeau",
        citation: "Christian Thibaudeau, “Know Your Ratios, Destroy Weaknesses”, Thibarmy / T Nation.",
        url: URL(string: "https://thibarmy.com/know-your-ratios-destroy-weaknesses/"),
        note: "The article tests a 3- or 5-rep max; here each lift is your best estimated one-rep max. "
            + "Its clean and snatch deadlifts and Olympic-lift ratios are left out.",
        groups: [
            Group(
                id: "upper", title: "Upper Body",
                reference: Lift(id: "bench", name: "Bench Press", exercises: bench, targetPct: 100),
                lifts: [
                    Lift(id: "closeGrip", name: "Close-Grip Bench Press", exercises: closeGrip, targetPct: 90),
                    Lift(id: "pushPress", name: "Push Press", exercises: ["Push Press"], targetPct: 85),
                    Lift(id: "incline", name: "Incline Bench Press", exercises: incline, targetPct: 80),
                    Lift(id: "military", name: "Military Press", exercises: militaryPress, targetPct: 60),
                    Lift(id: "dip", name: "Weighted Dip", exercises: dip, targetPct: 105, includesBodyweight: true),
                    Lift(id: "chin", name: "Supinated Chin-Up", exercises: chinUp, targetPct: 90, includesBodyweight: true),
                    Lift(id: "row", name: "Chest-Supported Row", exercises: ["Seal Row (Barbell)"], targetPct: 70),
                    Lift(id: "preacher", name: "Preacher Curl", exercises: ["Preacher Curl (Barbell)"], targetPct: 40),
                    Lift(id: "reverseCurl", name: "Standing Reverse Curl", exercises: ["Reverse Curl (Barbell)"], targetPct: 35),
                ]
            ),
            Group(
                id: "lower", title: "Lower Body",
                reference: Lift(id: "squat", name: "Back Squat", exercises: squat, targetPct: 100),
                lifts: [
                    Lift(id: "frontSquat", name: "Front Squat", exercises: ["Front Squat"], targetPct: 85),
                    Lift(id: "deadlift", name: "Deadlift", exercises: deadlift, targetPct: 120),
                ]
            ),
            Group(
                id: "whole", title: "Whole Body",
                reference: Lift(id: "squat", name: "Back Squat", exercises: squat, targetPct: 100),
                lifts: [
                    Lift(id: "bench", name: "Bench Press", exercises: bench, targetPct: 75),
                    Lift(id: "deadlift", name: "Deadlift", exercises: deadlift, targetPct: 120),
                    Lift(id: "military", name: "Military Press", exercises: militaryPress, targetPct: 45),
                ]
            ),
        ]
    )

    static let poliquin = Template(
        id: "poliquin",
        title: "Poliquin",
        citation: "Charles Poliquin, “Achieving Structural Balance”, T Nation (table dated 1997).",
        url: URL(string: "https://archive.t-nation.com/training/achieving-structural-balance/"),
        note: "Measured on elite male athletes in upper-body sports. Its behind-the-neck press (64%) "
            + "and 8-rep external rotation (9%) are left out: the library has no matching exercise.",
        groups: [
            Group(
                id: "upper", title: "Upper Body",
                reference: Lift(id: "closeGrip", name: "Close-Grip Bench Press", exercises: closeGrip, targetPct: 100),
                lifts: [
                    Lift(id: "incline", name: "Incline Barbell Press", exercises: incline, targetPct: 83),
                    Lift(id: "chin", name: "Supinated Chin-Up", exercises: chinUp, targetPct: 81, includesBodyweight: true),
                    Lift(id: "scott", name: "Scott Barbell Curl", exercises: ["Preacher Curl (Barbell)"], targetPct: 46),
                    Lift(id: "reverseCurl", name: "Standing Reverse Curl", exercises: ["Reverse Curl (Barbell)"], targetPct: 30),
                ]
            ),
        ]
    )
}
