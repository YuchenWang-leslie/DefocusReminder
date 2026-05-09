import XCTest
@testable import DefocusReminderCore

final class TimerEngineTests: XCTestCase {
    func testWorkCompletesToStartBreakPrompt() {
        let config = AppConfig(workMinutes: 1, breakMinutes: 1)
        var engine = TimerEngine(config: config)
        engine.remainingSeconds = 1

        let event = engine.tick(config: config, isWorkTime: true)

        XCTAssertEqual(event, .workCompleted)
        XCTAssertEqual(engine.phase, .breakPrompt)
        XCTAssertEqual(engine.promptKind, .startBreak)
    }

    func testStartAndFinishBreakReturnsToWork() {
        let config = AppConfig(workMinutes: 1, breakMinutes: 1)
        var engine = TimerEngine(config: config)

        engine.requestBreak()
        engine.startBreak(config: config)
        XCTAssertEqual(engine.phase, .breaking)
        XCTAssertEqual(engine.remainingSeconds, 60)

        engine.remainingSeconds = 1
        let event = engine.tick(config: config, isWorkTime: true)

        XCTAssertEqual(event, .breakCompleted)
        XCTAssertEqual(engine.phase, .breakPrompt)
        XCTAssertEqual(engine.promptKind, .finishBreak)

        engine.finishBreak(config: config)
        XCTAssertEqual(engine.phase, .working)
        XCTAssertEqual(engine.remainingSeconds, 60)
    }

    func testPauseAndResumePreservesPhaseAndRemainingTime() {
        let config = AppConfig(workMinutes: 10, breakMinutes: 2)
        var engine = TimerEngine(config: config)
        engine.remainingSeconds = 123

        engine.pause()
        XCTAssertEqual(engine.phase, .paused)
        XCTAssertEqual(engine.remainingSeconds, 123)

        engine.resume()
        XCTAssertEqual(engine.phase, .working)
        XCTAssertEqual(engine.remainingSeconds, 123)
    }

    func testActivityDetectionPausesBreakCountdown() {
        let config = AppConfig(workMinutes: 1, breakMinutes: 1)
        var engine = TimerEngine(config: config)
        engine.requestBreak()
        engine.startBreak(config: config)
        engine.remainingSeconds = 30

        let event = engine.tick(config: config, isWorkTime: true, activityDetected: true)

        XCTAssertNil(event)
        XCTAssertEqual(engine.phase, .breaking)
        XCTAssertEqual(engine.remainingSeconds, 30)
    }

    func testNonWorkTimeEntersOffDutyAndWorkTimeResumesFreshCycle() {
        let config = AppConfig(workMinutes: 25, breakMinutes: 5)
        var engine = TimerEngine(config: config)

        XCTAssertEqual(engine.applySchedule(isWorkTime: false, config: config), .enteredOffDuty)
        XCTAssertEqual(engine.phase, .offDuty)

        XCTAssertEqual(engine.applySchedule(isWorkTime: true, config: config), .resumedWork)
        XCTAssertEqual(engine.phase, .working)
        XCTAssertEqual(engine.remainingSeconds, 25 * 60)
    }
}
