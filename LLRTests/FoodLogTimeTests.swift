import SwiftData
import XCTest
@testable import LLR

@MainActor
final class FoodLogTimeTests: XCTestCase {
    private var cal: Calendar!

    override func setUp() {
        cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 3, day: day, hour: hour, minute: minute))!
    }

    func testTodayLogsNowAndAPastDayLogsMidday() {
        let now = date(10, 18, 30)
        XCTAssertEqual(FoodLogTime.defaultTime(for: date(10, 0), now: now, calendar: cal), now)
        XCTAssertEqual(FoodLogTime.defaultTime(for: date(3, 0), now: now, calendar: cal), date(3, 12))
    }

    func testDayBoundsHalfOpenAroundMidnight() {
        let bounds = FoodLogTime.dayBounds(date(5, 13), calendar: cal)
        XCTAssertEqual(bounds.start, date(5, 0))
        XCTAssertEqual(bounds.end, date(6, 0))
    }

    func testFutureTimesAreClampedToNow() {
        let now = date(10, 9)
        XCTAssertEqual(FoodLogTime.clamped(date(12, 9), now: now), now)
        XCTAssertEqual(FoodLogTime.clamped(date(8, 9), now: now), date(8, 9))
    }

    func testEditingLoggedAtMovesAnEntryBetweenDays() throws {
        let container = try ModelContainer(for: FoodEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let entry = FoodEntry(name: "Oats", meal: .breakfast, kcal: 300, proteinG: 10, carbsG: 50, fatG: 6, loggedAt: date(9, 8))
        context.insert(entry)

        func count(on day: Date) throws -> Int {
            let (start, end) = FoodLogTime.dayBounds(day, calendar: cal)
            let descriptor = FetchDescriptor<FoodEntry>(predicate: #Predicate { $0.loggedAt >= start && $0.loggedAt < end })
            return try context.fetch(descriptor).count
        }

        XCTAssertEqual(try count(on: date(9, 0)), 1)
        entry.loggedAt = date(7, 12)
        XCTAssertEqual(try count(on: date(9, 0)), 0, "gone from the day it was moved away from")
        XCTAssertEqual(try count(on: date(7, 0)), 1, "present on the day it was moved to")
    }

    func testAnEntryAtMidnightBelongsToTheNewDayOnly() throws {
        let container = try ModelContainer(for: FoodEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        context.insert(FoodEntry(name: "Late snack", meal: .snack, kcal: 100, proteinG: 1, carbsG: 20, fatG: 1, loggedAt: date(6, 0)))
        let (start, end) = FoodLogTime.dayBounds(date(5, 0), calendar: cal)
        let onFifth = try context.fetch(FetchDescriptor<FoodEntry>(predicate: #Predicate { $0.loggedAt >= start && $0.loggedAt < end }))
        XCTAssertTrue(onFifth.isEmpty)
    }
}
