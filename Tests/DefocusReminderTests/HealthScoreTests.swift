import XCTest
@testable import DefocusReminderCore

final class HealthScoreTests: XCTestCase {
    func testNoDataHasNoHealthScore() {
        XCTAssertNil(HealthScoreCalculator.score(for: DailySummary(date: "2026-05-20"), config: AppConfig()))
    }

    func testAllCompletedAndRestedScoresHigh() {
        let config = AppConfig(workMinutes: 50, breakMinutes: 5)
        let summary = DailySummary(
            date: "2026-05-20",
            workSeconds: 50 * 60,
            breakSeconds: 5 * 60,
            completedBreaks: 1
        )

        XCTAssertEqual(try XCTUnwrap(HealthScoreCalculator.score(for: summary, config: config)), 100, accuracy: 0.001)
    }

    func testAllSkippedScoresLowEvenWithSomeRest() {
        let config = AppConfig(workMinutes: 50, breakMinutes: 5)
        let summary = DailySummary(
            date: "2026-05-20",
            workSeconds: 50 * 60,
            breakSeconds: 2 * 60,
            skippedBreaks: 1
        )

        XCTAssertEqual(try XCTUnwrap(HealthScoreCalculator.score(for: summary, config: config)), 14, accuracy: 0.001)
    }

    func testPartialRestRatioContributesToScore() {
        let config = AppConfig(workMinutes: 50, breakMinutes: 5)
        let summary = DailySummary(
            date: "2026-05-20",
            workSeconds: 50 * 60,
            breakSeconds: 150,
            completedBreaks: 1,
            skippedBreaks: 1
        )

        XCTAssertEqual(try XCTUnwrap(HealthScoreCalculator.score(for: summary, config: config)), 50, accuracy: 0.001)
    }
}
