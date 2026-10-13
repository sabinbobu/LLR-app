import AVFoundation
import XCTest
@testable import LLR

@MainActor
final class RestSoundTests: XCTestCase {
    func testTheSoundIsBundledAndShortEnoughForANotification() throws {
        let url = try XCTUnwrap(RestSound.url, "rest-tick.wav must ship in the app bundle")
        let file = try AVAudioFile(forReading: url)
        let seconds = Double(file.length) / file.processingFormat.sampleRate
        XCTAssertGreaterThan(seconds, 0.2)
        XCTAssertLessThan(seconds, 30, "iOS rejects notification sounds of 30 s or more")
        XCTAssertEqual(file.fileFormat.settings[AVFormatIDKey] as? UInt32, kAudioFormatLinearPCM)
    }

    func testNotificationAndInAppPlaybackUseTheSameFile() {
        XCTAssertEqual(RestSound.fileName, "rest-tick.wav")
    }
}
