//
//  PomodoroEngineTests.swift
//  QuestDoroTests
//

import XCTest
@testable import QuestDoro

final class PomodoroEngineTests: XCTestCase {

    var engine: PomodoroEngine!

    override func setUp() {
        super.setUp()
        engine = PomodoroEngine()
    }

    override func tearDown() {
        engine = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertEqual(engine.phase, .idle)
        XCTAssertEqual(engine.remaining, 25 * 60)
        XCTAssertEqual(engine.focusSeconds, 25 * 60)
        XCTAssertEqual(engine.breakSeconds, 5 * 60)
        XCTAssertEqual(engine.completedFocusSessions, 0)
        XCTAssertFalse(engine.isRunning)
    }

    // MARK: - Display String

    func testDisplayString_DefaultTime() {
        XCTAssertEqual(engine.displayString(), "25:00")
    }

    func testDisplayString_SingleDigitMinutes() {
        engine.remaining = 5 * 60 + 30
        XCTAssertEqual(engine.displayString(), "05:30")
    }

    func testDisplayString_Zero() {
        engine.remaining = 0
        XCTAssertEqual(engine.displayString(), "00:00")
    }

    // MARK: - Start/Stop

    func testStart_FromIdle() {
        engine.start()
        XCTAssertEqual(engine.phase, .focus)
        XCTAssertTrue(engine.isRunning)
        XCTAssertEqual(engine.remaining, 25 * 60)
    }

    func testStop() {
        engine.start()
        engine.stop()
        XCTAssertFalse(engine.isRunning)
        XCTAssertEqual(engine.phase, .focus) // Phase doesn't change on stop
    }

    // MARK: - Restart

    func testRestartCurrent_DuringFocus() {
        engine.start()
        engine.remaining = 10 * 60 // Simulate time passing
        engine.restartCurrent()

        XCTAssertFalse(engine.isRunning)
        XCTAssertEqual(engine.remaining, 25 * 60)
        XCTAssertEqual(engine.phase, .focus)
    }

    func testRestartCurrent_DuringBreak() {
        engine.phase = .breakTime
        engine.remaining = 2 * 60
        engine.restartCurrent()

        XCTAssertEqual(engine.remaining, 5 * 60)
        XCTAssertEqual(engine.phase, .breakTime)
    }

    func testResetAll() {
        engine.start()
        engine.phase = .breakTime
        engine.completedFocusSessions = 3
        engine.focusSeconds = 30 * 60
        engine.breakSeconds = 10 * 60

        engine.resetAll()

        XCTAssertEqual(engine.phase, .idle)
        XCTAssertEqual(engine.completedFocusSessions, 0)
        XCTAssertEqual(engine.focusSeconds, 25 * 60)
        XCTAssertEqual(engine.breakSeconds, 5 * 60)
        XCTAssertEqual(engine.remaining, 25 * 60)
        XCTAssertFalse(engine.isRunning)
    }

    // MARK: - Set Time From Input

    func testSetTimeFromInput_ValidMMSS() {
        engine.setTimeFromInput("30:00")
        XCTAssertEqual(engine.focusSeconds, 30 * 60)
        XCTAssertEqual(engine.remaining, 30 * 60)
    }

    func testSetTimeFromInput_DuringBreak() {
        engine.phase = .breakTime
        engine.setTimeFromInput("10:00")
        XCTAssertEqual(engine.breakSeconds, 10 * 60)
        XCTAssertEqual(engine.remaining, 10 * 60)
    }

    func testSetTimeFromInput_StopsTimer() {
        engine.start()
        XCTAssertTrue(engine.isRunning)

        engine.setTimeFromInput("15:00")
        XCTAssertFalse(engine.isRunning)
    }

    // MARK: - Reset To Default Focus

    func testResetToDefaultFocus() {
        engine.focusSeconds = 45 * 60
        engine.remaining = 20 * 60
        engine.start()

        engine.resetToDefaultFocus()

        XCTAssertEqual(engine.focusSeconds, 25 * 60)
        XCTAssertEqual(engine.remaining, 25 * 60)
        XCTAssertEqual(engine.phase, .idle)
        XCTAssertFalse(engine.isRunning)
    }

    func testResetToDefaultFocus_DuringBreak_KeepsBreak() {
        engine.phase = .breakTime
        engine.remaining = 3 * 60
        engine.focusSeconds = 45 * 60

        engine.resetToDefaultFocus()

        XCTAssertEqual(engine.focusSeconds, 25 * 60)
        XCTAssertEqual(engine.phase, .breakTime) // Stays in break
        XCTAssertEqual(engine.remaining, 3 * 60) // Break time unchanged
    }
}

// MARK: - Time Parsing Tests

final class ParseFlexibleTimeTests: XCTestCase {

    // MARK: - Empty/Invalid Input

    func testEmptyString() {
        XCTAssertNil(parseFlexibleTime(""))
    }

    func testWhitespaceOnly() {
        XCTAssertNil(parseFlexibleTime("   "))
    }

    func testNoDigits() {
        XCTAssertNil(parseFlexibleTime("abc"))
    }

    // MARK: - MM:SS Format

    func testMMSS_Standard() {
        XCTAssertEqual(parseFlexibleTime("25:00"), 25 * 60)
    }

    func testMMSS_WithSeconds() {
        XCTAssertEqual(parseFlexibleTime("10:30"), 10 * 60 + 30)
    }

    func testMMSS_SingleDigitMinutes() {
        XCTAssertEqual(parseFlexibleTime("5:00"), 5 * 60)
    }

    func testMMSS_Zero() {
        XCTAssertEqual(parseFlexibleTime("00:00"), 0)
    }

    func testMMSS_MaxValid() {
        XCTAssertEqual(parseFlexibleTime("99:59"), 99 * 60 + 59)
    }

    func testMMSS_InvalidSeconds() {
        XCTAssertNil(parseFlexibleTime("25:60")) // 60 seconds invalid
    }

    func testMMSS_InvalidMinutes() {
        XCTAssertNil(parseFlexibleTime("100:00")) // 100 minutes invalid
    }

    // MARK: - 1-2 Digit Input (Minutes)

    func testSingleDigit_Minutes() {
        XCTAssertEqual(parseFlexibleTime("5"), 5 * 60)
    }

    func testTwoDigits_Minutes() {
        XCTAssertEqual(parseFlexibleTime("25"), 25 * 60)
    }

    func testTwoDigits_Zero() {
        XCTAssertEqual(parseFlexibleTime("0"), 0)
    }

    func testTwoDigits_Max() {
        XCTAssertEqual(parseFlexibleTime("99"), 99 * 60)
    }

    // MARK: - 3-4 Digit Input (MMSS)

    func testThreeDigits() {
        // "530" -> "0530" -> 05:30
        XCTAssertEqual(parseFlexibleTime("530"), 5 * 60 + 30)
    }

    func testFourDigits() {
        // "2500" -> 25:00
        XCTAssertEqual(parseFlexibleTime("2500"), 25 * 60)
    }

    func testFourDigits_WithSeconds() {
        // "1030" -> 10:30
        XCTAssertEqual(parseFlexibleTime("1030"), 10 * 60 + 30)
    }

    func testThreeDigits_Overflow() {
        // "599" -> "0599" -> 05:99 -> normalizes to 6:39
        XCTAssertEqual(parseFlexibleTime("599"), 6 * 60 + 39)
    }

    func testFourDigits_SecondsOverflow() {
        // "2575" -> 25:75 -> normalizes to 26:15
        XCTAssertEqual(parseFlexibleTime("2575"), 26 * 60 + 15)
    }

    // MARK: - Whitespace Handling

    func testLeadingWhitespace() {
        XCTAssertEqual(parseFlexibleTime("  25:00"), 25 * 60)
    }

    func testTrailingWhitespace() {
        XCTAssertEqual(parseFlexibleTime("25:00  "), 25 * 60)
    }

    // MARK: - Mixed Input

    func testDigitsWithNonDigits() {
        // Filters to just digits
        XCTAssertEqual(parseFlexibleTime("2a5"), 25 * 60) // "25" -> 25 minutes
    }
}
