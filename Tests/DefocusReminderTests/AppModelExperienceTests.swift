import XCTest
@testable import DefocusReminderCore

@MainActor
final class AppModelExperienceTests: XCTestCase {
    func testPausedTodayDoesNotAdvanceTimerOrStats() throws {
        var now = date(2026, 5, 20, 10, 0)
        let pausedUntil = date(2026, 5, 21, 0, 0)
        let config = AppConfig(
            workDays: [4],
            workStartTime: "09:00",
            workEndTime: "18:00",
            reminderMode: .menu,
            remindersPausedUntil: pausedUntil
        )
        let store = JSONStore(fileURL: tempURL())
        try store.save(AppSnapshot(config: config))
        let model = AppModel(store: store, nowProvider: { now })
        let startingSeconds = model.engine.remainingSeconds

        model.tickOnce()

        XCTAssertTrue(model.isRemindersPaused)
        XCTAssertEqual(model.engine.remainingSeconds, startingSeconds)
        XCTAssertEqual(model.todaySummary.workSeconds, 0)

        now = date(2026, 5, 21, 9, 0)
        model.tickOnce()

        XCTAssertFalse(model.isRemindersPaused)
    }

    func testSnoozeBreakReturnsToWorkWithoutCountingSkippedBreak() throws {
        let now = date(2026, 5, 20, 10, 0)
        let config = AppConfig(
            workDays: [4],
            workStartTime: "09:00",
            workEndTime: "23:00",
            reminderMode: .menu
        )
        let store = JSONStore(fileURL: tempURL())
        try store.save(AppSnapshot(config: config))
        let model = AppModel(store: store, nowProvider: { now })

        model.requestBreakNow()
        model.snoozeBreak()

        XCTAssertEqual(model.engine.phase, .working)
        XCTAssertEqual(model.engine.remainingSeconds, 5 * 60)
        XCTAssertEqual(model.todaySummary.skippedBreaks, 0)
    }

    func testSystemSessionPauseStopsAndResumesEffectiveWorkTimer() async throws {
        let now = date(2026, 5, 20, 2, 0)
        let config = AppConfig(
            workDays: [4],
            workStartTime: "09:00",
            workEndTime: "18:00",
            reminderMode: .menu
        )
        let store = JSONStore(fileURL: tempURL())
        try store.save(AppSnapshot(config: config))
        let model = AppModel(store: store, nowProvider: { now })
        let startingSeconds = model.engine.remainingSeconds

        NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        await Task.yield()

        XCTAssertEqual(model.engine.phase, .paused)
        model.tickOnce()
        XCTAssertEqual(model.engine.remainingSeconds, startingSeconds)
        XCTAssertEqual(model.todaySummary.workSeconds, 0)

        NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
        await Task.yield()

        XCTAssertEqual(model.engine.phase, .working)
        model.tickOnce()
        XCTAssertEqual(model.engine.remainingSeconds, startingSeconds - 1)
        XCTAssertEqual(model.todaySummary.workSeconds, 1)
    }

    private func tempURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DefocusReminderTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("state.json")
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }
}
