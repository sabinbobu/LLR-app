import Foundation
import SwiftData

enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case glutes = "Glutes"
    case core = "Core"
    case fullBody = "Full Body"

    var id: String { rawValue }
}

enum ExerciseLibrary {
    static let builtIn: [(String, MuscleGroup)] = [
        ("Bench Press (Barbell)", .chest),
        ("Incline Bench Press (Barbell)", .chest),
        ("Bench Press (Dumbbell)", .chest),
        ("Incline Press (Dumbbell)", .chest),
        ("Chest Fly (Cable)", .chest),
        ("Push Up", .chest),
        ("Dip", .chest),
        ("Deadlift (Barbell)", .back),
        ("Bent Over Row (Barbell)", .back),
        ("One Arm Row (Dumbbell)", .back),
        ("Pull Up", .back),
        ("Chin Up", .back),
        ("Lat Pulldown (Cable)", .back),
        ("Seated Row (Cable)", .back),
        ("Overhead Press (Barbell)", .shoulders),
        ("Shoulder Press (Dumbbell)", .shoulders),
        ("Lateral Raise (Dumbbell)", .shoulders),
        ("Face Pull (Cable)", .shoulders),
        ("Rear Delt Fly (Dumbbell)", .shoulders),
        ("Curl (Barbell)", .biceps),
        ("Curl (Dumbbell)", .biceps),
        ("Hammer Curl (Dumbbell)", .biceps),
        ("Curl (Cable)", .biceps),
        ("Triceps Pushdown (Cable)", .triceps),
        ("Skull Crusher (Barbell)", .triceps),
        ("Overhead Extension (Dumbbell)", .triceps),
        ("Close Grip Bench Press", .triceps),
        ("Squat (Barbell)", .legs),
        ("Front Squat (Barbell)", .legs),
        ("Leg Press (Machine)", .legs),
        ("Lunge (Dumbbell)", .legs),
        ("Bulgarian Split Squat", .legs),
        ("Leg Extension (Machine)", .legs),
        ("Leg Curl (Machine)", .legs),
        ("Calf Raise (Machine)", .legs),
        ("Romanian Deadlift (Barbell)", .glutes),
        ("Hip Thrust (Barbell)", .glutes),
        ("Plank", .core),
        ("Hanging Leg Raise", .core),
        ("Cable Crunch", .core),
        ("Kettlebell Swing", .fullBody),
        ("Clean (Barbell)", .fullBody),
    ]

    static func seedIfNeeded(_ context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        guard existing == 0 else { return }
        for (name, group) in builtIn {
            context.insert(Exercise(name: name, muscleGroup: group.rawValue))
        }
        try? context.save()
    }
}
