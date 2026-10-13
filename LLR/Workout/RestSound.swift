import AVFoundation
import UIKit

/// The "rest over" tick. In the background the scheduled notification plays it; iOS suppresses that
/// notification while the app is open, so the app plays it itself and the two never double up.
@MainActor
enum RestSound {
    static let resource = "rest-tick"
    static let fileExtension = "wav"
    static var fileName: String { "\(resource).\(fileExtension)" }
    private static var player: AVAudioPlayer?

    static var url: URL? { Bundle.main.url(forResource: resource, withExtension: fileExtension) }

    static func play() {
        guard UIApplication.shared.applicationState == .active, let url else { return }
        // .ambient mixes with the lifter's music and follows the silent switch.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient)
        try? session.setActive(true)
        player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        player?.play()
    }
}
