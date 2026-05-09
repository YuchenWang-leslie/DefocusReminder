import XCTest
@testable import DefocusReminderCore

final class SchedulePolicyTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testWeekdayInsideWorkHoursIsActive() {
        let config = AppConfig(workDays: [2, 3, 4, 5, 6], workStartTime: "09:00", workEndTime: "18:00")
        XCTAssertTrue(SchedulePolicy.isWithinWorkSchedule(at: date(2026, 1, 5, 10, 0), config: config, calendar: calendar))
    }

    func testWeekendIsInactive() {
        let config = AppConfig(workDays: [2, 3, 4, 5, 6], workStartTime: "09:00", workEndTime: "18:00")
        XCTAssertFalse(SchedulePolicy.isWithinWorkSchedule(at: date(2026, 1, 4, 10, 0), config: config, calendar: calendar))
    }

    func testOutsideWorkHoursIsInactive() {
        let config = AppConfig(workDays: [2, 3, 4, 5, 6], workStartTime: "09:00", workEndTime: "18:00")
        XCTAssertFalse(SchedulePolicy.isWithinWorkSchedule(at: date(2026, 1, 5, 8, 59), config: config, calendar: calendar))
        XCTAssertFalse(SchedulePolicy.isWithinWorkSchedule(at: date(2026, 1, 5, 18, 0), config: config, calendar: calendar))
    }

    func testCrossMidnightShiftUsesStartDayAsWorkDay() {
        let config = AppConfig(workDays: [2], workStartTime: "22:00", workEndTime: "06:00")

        XCTAssertTrue(SchedulePolicy.isWithinWorkSchedule(at: date(2026, 1, 5, 23, 0), config: config, calendar: calendar))
        XCTAssertTrue(SchedulePolicy.isWithinWorkSchedule(at: date(2026, 1, 6, 3, 0), config: config, calendar: calendar))
        XCTAssertFalse(SchedulePolicy.isWithinWorkSchedule(at: date(2026, 1, 6, 7, 0), config: config, calendar: calendar))
    }

    func testNextWorkStartFindsUpcomingStart() {
        let config = AppConfig(workDays: [2, 3, 4, 5, 6], workStartTime: "09:00", workEndTime: "18:00")
        let next = SchedulePolicy.nextWorkStart(after: date(2026, 1, 4, 12, 0), config: config, calendar: calendar)

        XCTAssertEqual(calendar.component(.weekday, from: next!), 2)
        XCTAssertEqual(calendar.component(.hour, from: next!), 9)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        calendar.date(from: DateComponents(
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
