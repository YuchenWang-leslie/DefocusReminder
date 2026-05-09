import SwiftUI

public struct StatsView: View {
    @ObservedObject var model: AppModel
    @State private var days = 30

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L.s("工作 / 休息趋势", "Work / break trend", model.language))
                        .font(.title3.bold())
                    Text(L.s("按日汇总，保持轻量。", "Daily summaries, kept lightweight.", model.language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: $days) {
                    Text(L.s("7天", "7 days", model.language)).tag(7)
                    Text(L.s("30天", "30 days", model.language)).tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            HStack(spacing: 12) {
                metric(
                    title: L.s("今日工作", "Work today", model.language),
                    value: L.duration(model.todaySummary.workSeconds, model.language),
                    color: .blue
                )
                metric(
                    title: L.s("今日休息", "Break today", model.language),
                    value: L.duration(model.todaySummary.breakSeconds, model.language),
                    color: .green
                )
                metric(
                    title: L.s("完成休息", "Breaks done", model.language),
                    value: "\(model.todaySummary.completedBreaks)",
                    color: .orange
                )
                metric(
                    title: L.s("跳过", "Skipped", model.language),
                    value: "\(model.todaySummary.skippedBreaks)",
                    color: .red
                )
            }

            legend
            chart
            Spacer()
        }
        .padding(20)
    }

    private var chart: some View {
        let data = model.summariesForLastDays(days)
        let maxSeconds = max(60, data.map { max($0.workSeconds, $0.breakSeconds) }.max() ?? 60)

        return HStack(alignment: .bottom, spacing: days == 7 ? 16 : 5) {
            ForEach(data) { item in
                VStack(spacing: 5) {
                    HStack(alignment: .bottom, spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.blue.opacity(item.workSeconds > 0 ? 0.85 : 0.12))
                            .frame(width: days == 7 ? 14 : 6, height: barHeight(item.workSeconds, maxSeconds: maxSeconds))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.green.opacity(item.breakSeconds > 0 ? 0.85 : 0.12))
                            .frame(width: days == 7 ? 14 : 6, height: barHeight(item.breakSeconds, maxSeconds: maxSeconds))
                    }
                    Text(DateKeys.displayDay(item.date))
                        .font(.system(size: days == 7 ? 10 : 8))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .help(helpText(for: item))
            }
        }
        .frame(height: 230)
        .padding(.horizontal, 8)
        .padding(.vertical, 14)
        .background(.quaternary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: .blue, text: L.s("工作时长", "Work time", model.language))
            legendItem(color: .green, text: L.s("休息时长", "Break time", model.language))
            Spacer()
        }
    }

    private func metric(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func barHeight(_ seconds: Int, maxSeconds: Int) -> CGFloat {
        if seconds <= 0 { return 4 }
        return max(8, CGFloat(seconds) / CGFloat(maxSeconds) * 180)
    }

    private func helpText(for item: DailySummary) -> String {
        "\(item.date)\n\(L.s("工作", "Work", model.language)): \(L.duration(item.workSeconds, model.language))\n\(L.s("休息", "Break", model.language)): \(L.duration(item.breakSeconds, model.language))"
    }
}
