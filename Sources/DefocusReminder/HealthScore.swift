import Foundation

struct HealthScorePoint: Identifiable, Equatable {
    var id: String { summary.date }
    let summary: DailySummary
    let score: Double

    var displayDay: String {
        DateKeys.displayDay(summary.date)
    }
}

enum HealthScoreCalculator {
    static func score(for summary: DailySummary, config: AppConfig) -> Double? {
        let hasAnyData = summary.workSeconds > 0
            || summary.breakSeconds > 0
            || summary.completedBreaks > 0
            || summary.skippedBreaks > 0
        guard hasAnyData else { return nil }

        let cycleCount = summary.completedBreaks + summary.skippedBreaks
        let completionRate = cycleCount > 0
            ? Double(summary.completedBreaks) / Double(cycleCount)
            : 0

        let targetBreakSeconds: Double
        if summary.workSeconds > 0 {
            targetBreakSeconds = Double(summary.workSeconds)
                * Double(config.breakDurationSeconds)
                / Double(max(1, config.workDurationSeconds))
        } else {
            targetBreakSeconds = Double(max(1, config.breakDurationSeconds))
        }

        let restRatio = min(1, Double(summary.breakSeconds) / max(1, targetBreakSeconds))
        let score = completionRate * 65 + restRatio * 35
        return min(100, max(0, score))
    }

    static func points(for summaries: [DailySummary], config: AppConfig) -> [HealthScorePoint] {
        summaries.compactMap { summary in
            guard let score = score(for: summary, config: config) else { return nil }
            return HealthScorePoint(summary: summary, score: score)
        }
    }
}
