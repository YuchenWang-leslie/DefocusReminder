import Charts
import SwiftUI

public struct StatsView: View {
    @ObservedObject var model: AppModel
    @State private var days = 30

    public init(model: AppModel) {
        self.model = model
    }

    public var body: some View {
        let data = model.summariesForLastDays(days)
        let period = PeriodStats(summaries: data)

        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L.s("工作与休息统计", "Work and rest stats", model.language))
                        .font(.title3.bold())
                    Text(L.s("关注有效工作时间、有效休息和完成的工作/休息循环。", "Tracks effective work time, effective rests, and completed work/rest cycles.", model.language))
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
                    title: L.s("有效休息", "Effective rests", model.language),
                    value: "\(model.todaySummary.completedBreaks)",
                    color: .green
                )
                metric(
                    title: L.s("有效循环", "Effective cycles", model.language),
                    value: "\(model.todaySummary.completedBreaks)",
                    color: .orange
                )
                metric(
                    title: L.s("今日休息时长", "Break time", model.language),
                    value: L.duration(model.todaySummary.breakSeconds, model.language),
                    color: .mint
                )
            }

            periodSummary(period)

            HStack(alignment: .top, spacing: 14) {
                workChart(data)
                cycleChart(data)
            }
            Spacer()
        }
        .padding(20)
        .preferredColorScheme(.dark)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.09, blue: 0.12),
                    Color(red: 0.13, green: 0.14, blue: 0.18),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func periodSummary(_ period: PeriodStats) -> some View {
        HStack(spacing: 14) {
            summaryItem(
                icon: "clock.fill",
                title: L.s("\(days)天工作", "\(days)d work", model.language),
                value: L.duration(period.workSeconds, model.language),
                color: .blue
            )
            summaryItem(
                icon: "checkmark.circle.fill",
                title: L.s("有效休息", "Effective rests", model.language),
                value: "\(period.completedBreaks)",
                color: .green
            )
            summaryItem(
                icon: "arrow.triangle.2.circlepath.circle.fill",
                title: L.s("有效循环", "Effective cycles", model.language),
                value: "\(period.effectiveCycles)",
                color: .orange
            )
            summaryItem(
                icon: "forward.end.fill",
                title: L.s("跳过", "Skipped", model.language),
                value: "\(period.skippedBreaks)",
                color: .red
            )
        }
        .padding(14)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func workChart(_ data: [DailySummary]) -> some View {
        chartContainer(
            title: L.s("每日有效工作时间", "Daily effective work", model.language),
            subtitle: L.s("只统计计时器实际运行的工作时间。", "Only counts work time while the timer is active.", model.language),
            emptyIcon: "clock.badge.questionmark",
            isEmpty: !data.contains { $0.workSeconds > 0 }
        ) {
            Chart(data) { summary in
                BarMark(
                    x: .value(L.s("日期", "Day", model.language), DateKeys.displayDay(summary.date)),
                    y: .value(L.s("小时", "Hours", model.language), Double(summary.workSeconds) / 3600)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(3)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: days == 7 ? 7 : 5))
            }
        }
    }

    private func cycleChart(_ data: [DailySummary]) -> some View {
        chartContainer(
            title: L.s("每日工作/休息循环", "Daily work/rest cycles", model.language),
            subtitle: L.s("绿色为完成的有效循环，红色为跳过。", "Green shows completed cycles; red shows skipped rests.", model.language),
            emptyIcon: "checklist",
            isEmpty: !data.contains { $0.completedBreaks > 0 || $0.skippedBreaks > 0 }
        ) {
            Chart(data) { summary in
                BarMark(
                    x: .value(L.s("日期", "Day", model.language), DateKeys.displayDay(summary.date)),
                    y: .value(L.s("次数", "Count", model.language), summary.completedBreaks)
                )
                .foregroundStyle(.green.gradient)
                .cornerRadius(3)

                BarMark(
                    x: .value(L.s("日期", "Day", model.language), DateKeys.displayDay(summary.date)),
                    y: .value(L.s("次数", "Count", model.language), summary.skippedBreaks)
                )
                .foregroundStyle(.red.opacity(0.75))
                .cornerRadius(3)
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4))
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: days == 7 ? 7 : 5))
            }
        }
    }

    private func chartContainer<Content: View>(
        title: String,
        subtitle: String,
        emptyIcon: String,
        isEmpty: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            ZStack {
                if isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: emptyIcon)
                            .font(.system(size: 25, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.45))
                        Text(L.s("还没有足够数据", "Not enough data yet", model.language))
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    content()
                }
            }
            .frame(height: 210)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func metric(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    private func summaryItem(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PeriodStats {
    let workSeconds: Int
    let completedBreaks: Int
    let skippedBreaks: Int

    var effectiveCycles: Int {
        completedBreaks
    }

    init(summaries: [DailySummary]) {
        workSeconds = summaries.reduce(0) { $0 + $1.workSeconds }
        completedBreaks = summaries.reduce(0) { $0 + $1.completedBreaks }
        skippedBreaks = summaries.reduce(0) { $0 + $1.skippedBreaks }
    }
}
