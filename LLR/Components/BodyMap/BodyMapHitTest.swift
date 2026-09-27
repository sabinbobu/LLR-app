import SwiftUI

enum BodyMapSide {
    case anterior, posterior

    var regions: [BodyMapData.Region] {
        self == .anterior ? BodyMapData.shared.anterior : BodyMapData.shared.posterior
    }
}

enum BodyMapHitTest {
    /// The dataset region under a point in the 0–1 normalized box, or nil for empty space.
    static func region(at point: CGPoint, in regions: [BodyMapData.Region]) -> String? {
        for region in regions {
            for polygon in region.polygons where path(polygon).contains(point) {
                return region.muscle
            }
        }
        return nil
    }

    /// Which tape site a tap on the silhouette means. Left/right is the *figure's* side: facing the
    /// viewer (anterior) its right arm is on screen-left; seen from behind it's the other way round.
    static func measurement(at point: CGPoint, side: BodyMapSide) -> MeasurementKind? {
        guard let region = region(at: point, in: side.regions) else { return nil }
        let figureRight = side == .anterior ? point.x < 0.5 : point.x >= 0.5
        switch region {
        case "NECK": return .neck
        case "FRONT_DELTOIDS", "BACK_DELTOIDS", "TRAPEZIUS": return .shoulders
        case "CHEST", "UPPER_BACK": return .chest
        case "ABS", "OBLIQUES", "LOWER_BACK": return .waist
        case "GLUTEAL", "ABDUCTORS", "ADDUCTOR": return .hips
        case "BICEPS", "TRICEPS": return figureRight ? .rightBicep : .leftBicep
        case "FOREARM": return figureRight ? .rightForearm : .leftForearm
        case "QUADRICEPS", "HAMSTRING": return figureRight ? .rightThigh : .leftThigh
        case "CALVES", "LEFT_SOLEUS", "RIGHT_SOLEUS": return figureRight ? .rightCalf : .leftCalf
        default: return nil
        }
    }

    static func path(_ polygon: [[Double]], size: CGSize = CGSize(width: 1, height: 1)) -> Path {
        var path = Path()
        for (index, point) in polygon.enumerated() {
            let p = CGPoint(x: point[0] * size.width, y: point[1] * size.height)
            if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}
