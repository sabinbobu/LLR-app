import XCTest
import UIKit
@testable import LLR

final class ThemeContrastTests: XCTestCase {
    private let light = UITraitCollection(userInterfaceStyle: .light)
    private let dark = UITraitCollection(userInterfaceStyle: .dark)

    private func channel(_ value: CGFloat) -> CGFloat {
        value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }

    private func luminance(_ color: UIColor, _ traits: UITraitCollection) -> CGFloat {
        let resolved: UIColor = color.resolvedColor(with: traits)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        let red: CGFloat = 0.2126 * channel(r)
        let green: CGFloat = 0.7152 * channel(g)
        let blue: CGFloat = 0.0722 * channel(b)
        return red + green + blue
    }

    private func ratio(_ a: UIColor, _ b: UIColor, _ traits: UITraitCollection) -> CGFloat {
        let la: CGFloat = luminance(a, traits)
        let lb: CGFloat = luminance(b, traits)
        let hi: CGFloat = max(la, lb)
        let lo: CGFloat = min(la, lb)
        return (hi + 0.05) / (lo + 0.05)
    }

    private func assertAA(_ text: UIColor, on fill: UIColor, _ name: String,
                          file: StaticString = #filePath, line: UInt = #line) {
        let modes: [(String, UITraitCollection)] = [("light", light), ("dark", dark)]
        for (label, traits) in modes {
            let value: CGFloat = ratio(text, fill, traits)
            XCTAssertGreaterThanOrEqual(value, 4.5, "\(name) in \(label) mode is \(value):1", file: file, line: line)
        }
    }

    func testRepeatLabelOnRepeatFill() {
        assertAA(Theme.repeatActionLabelUI, on: Theme.repeatActionUI, "repeat label on fill")
    }

    func testPrimaryLabelOnPrimaryFill() {
        assertAA(Theme.onPrimaryFillUI, on: Theme.primaryFillUI, "primary label on fill")
    }

    func testDestructiveLabelOnDestructiveFill() {
        assertAA(Theme.onPrimaryFillUI, on: Theme.destructiveFillUI, "destructive label on fill")
    }

    func testLabelOnSystemBackground() {
        assertAA(UIColor.label, on: UIColor.systemBackground, "label on background")
    }

    func testAccentTextOnCard() {
        assertAA(Theme.accentUI, on: UIColor.secondarySystemBackground, "accent text on card")
    }
}
