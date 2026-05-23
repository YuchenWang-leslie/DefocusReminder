import XCTest
@testable import DefocusReminderCore

final class JSONStoreTests: XCTestCase {
    func testMissingFileLoadsDefaults() {
        let url = tempURL()
        let store = JSONStore(fileURL: url)

        let snapshot = store.load()

        XCTAssertEqual(snapshot.version, 1)
        XCTAssertEqual(snapshot.config.workMinutes, 50)
        XCTAssertTrue(snapshot.summaries.isEmpty)
    }

    func testSaveAndLoadSnapshot() throws {
        let url = tempURL()
        let store = JSONStore(fileURL: url)
        let snapshot = AppSnapshot(
            config: AppConfig(workMinutes: 45, breakMinutes: 7, reminderMode: .menu),
            summaries: [DailySummary(date: "2026-05-09", workSeconds: 3600, breakSeconds: 300, completedBreaks: 1)]
        )

        try store.save(snapshot)
        let loaded = store.load()

        XCTAssertEqual(loaded.config.workMinutes, 45)
        XCTAssertEqual(loaded.config.breakMinutes, 7)
        XCTAssertEqual(loaded.config.reminderMode, .menu)
        XCTAssertEqual(loaded.summaries.first?.workSeconds, 3600)
    }

    func testOldMissingFieldsDecodeWithDefaults() throws {
        let url = tempURL()
        let json = """
        {
          "version": 1,
          "config": {},
          "summaries": [
            { "date": "2026-05-09" }
          ]
        }
        """
        try json.data(using: .utf8)!.write(to: url)

        let snapshot = JSONStore(fileURL: url).load()

        XCTAssertEqual(snapshot.config.workMinutes, 50)
        XCTAssertEqual(snapshot.config.healthProfile.profession, .general)
        XCTAssertEqual(snapshot.config.menuBarDisplayMode, .iconAndText)
        XCTAssertNil(snapshot.config.remindersPausedUntil)
        XCTAssertEqual(snapshot.summaries.first?.workSeconds, 0)
        XCTAssertEqual(snapshot.summaries.first?.completedBreaks, 0)
    }

    func testMenuBarDisplayModePersists() throws {
        let url = tempURL()
        let config = AppConfig(menuBarDisplayMode: .iconOnly)

        try JSONStore(fileURL: url).save(AppSnapshot(config: config))
        let snapshot = JSONStore(fileURL: url).load()

        XCTAssertEqual(snapshot.config.menuBarDisplayMode, .iconOnly)
    }

    private func tempURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DefocusReminderTests-\(UUID().uuidString)")

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        return directory
            .appendingPathComponent("state.json")
    }
}
