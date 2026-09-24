import XCTest
@testable import LLR

final class CSVTests: XCTestCase {
    func testQuotedDelimiterStaysInOneField() {
        let rows = CSV.parse("a,b\n\"28 Mar 2025, 17:29\",x\n")
        XCTAssertEqual(rows, [["a", "b"], ["28 Mar 2025, 17:29", "x"]])
    }

    func testDoubledQuotesAndEmbeddedNewline() {
        let rows = CSV.parse("\"he said \"\"go\"\"\",\"line1\nline2\"\n")
        XCTAssertEqual(rows, [["he said \"go\"", "line1\nline2"]])
    }

    func testCRLFBOMBlankLinesAndEmptyFields() {
        let rows = CSV.parse("\u{FEFF}a,b,c\r\n\r\n1,,3\r\n")
        XCTAssertEqual(rows, [["a", "b", "c"], ["1", "", "3"]])
    }

    func testDelimiterDetectedFromHeader() {
        XCTAssertEqual(CSV.delimiter(of: "Date;Workout Name;Weight\n2020;\"a,b\";1,5"), ";")
        XCTAssertEqual(CSV.delimiter(of: "Date,Workout Name,Weight\n"), ",")
    }

    func testLineEscapesOnlyWhatNeedsIt() {
        XCTAssertEqual(CSV.line(["plain", "a,b", "say \"hi\""]), "plain,\"a,b\",\"say \"\"hi\"\"\"")
        XCTAssertEqual(CSV.parse(CSV.line(["plain", "a,b", "say \"hi\""])), [["plain", "a,b", "say \"hi\""]])
    }
}
