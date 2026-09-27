import Foundation

/// Muscle polygons ported from react-body-highlighter (MIT license, © 2020 GV79 — credited in
/// Settings › Acknowledgements), normalized to a 0–1 box matching its 1000×2000 SVG viewBox.
enum BodyMapData {
    struct Region: Decodable {
        let muscle: String
        /// Each polygon is a list of [x, y] points, 0–1 normalized; most muscles are two polygons (left/right).
        let polygons: [[[Double]]]
    }

    struct Dataset: Decodable {
        let anterior: [Region]
        let posterior: [Region]
    }

    static let shared: Dataset = {
        guard let url = Bundle.main.url(forResource: "body_map", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dataset = try? JSONDecoder().decode(Dataset.self, from: data)
        else { fatalError("body_map.json is missing or malformed") }
        return dataset
    }()

    /// Maps a dataset region to the `MuscleGroup`(s) it fills. Empty means it's drawn as a neutral
    /// outline (head, knees) — LLR doesn't track those as trainable muscles.
    static func muscleGroups(for region: String) -> [MuscleGroup] {
        switch region {
        case "CHEST": [.chest]
        case "ABS", "OBLIQUES": [.abdominals]
        case "FRONT_DELTOIDS", "BACK_DELTOIDS": [.shoulders]
        case "TRAPEZIUS": [.traps]
        // One drawn region covers two muscles LLR tracks separately; the caller picks how to blend them.
        case "UPPER_BACK": [.upperBack, .lats]
        case "LOWER_BACK": [.lowerBack]
        case "GLUTEAL": [.glutes]
        case "HAMSTRING": [.hamstrings]
        case "QUADRICEPS": [.quadriceps]
        case "CALVES", "LEFT_SOLEUS", "RIGHT_SOLEUS": [.calves]
        case "ADDUCTOR": [.adductors]
        case "ABDUCTORS": [.abductors]
        case "BICEPS": [.biceps]
        case "TRICEPS": [.triceps]
        case "FOREARM": [.forearms]
        case "NECK": [.neck]
        default: []
        }
    }
}
