import Foundation

final class JSONStore {
    let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
            self.fileURL = appSupport
                .appendingPathComponent("DefocusReminder", isDirectory: true)
                .appendingPathComponent("state.json")
        }
    }

    func load() -> AppSnapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return AppSnapshot()
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(AppSnapshot.self, from: data)
        } catch {
            return AppSnapshot()
        }
    }

    func save(_ snapshot: AppSnapshot) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
