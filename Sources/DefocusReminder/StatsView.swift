import Charts
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
                    Text(L.s("健康趋势", "Health trend", model.language))
                        .font(.title3.bold())
                    Text(L.s("综合完成率和休息达标度。", "Combines completion rate and rest coverage.", model.language))
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
                    title: L.s("今日循环", "Cycles today", model.language),
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

    private var chart: some View {
        let data = model.summariesForLastDays(days)
        let points = HealthScoreCalculator.points(for: data, config: model.config)

        return ZStack {
            if points.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))
                    Text(L.s("还没有足够数据", "Not enough data yet", model.language))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.72))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value(L.s("日期", "Day", model.language), point.displayDay),
                        y: .value(L.s("健康分", "Health score", model.language), point.score)
                    )
                    .foregroundStyle(.mint)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    PointMark(
                        x: .value(L.s("日期", "Day", model.language), point.displayDay),
                        y: .value(L.s("健康分", "Health score", model.language), point.score)
                    )
                    .foregroundStyle(.orange)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 25, 50, 75, 100])
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: days == 7 ? 7 : 6))
                }
            }
        }
        .frame(height: 230)
        .padding(.horizontal, 8)
        .padding(.vertical, 14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: .mint, text: L.s("综合健康分", "Health score", model.language))
            legendItem(color: .orange, text: L.s("每日记录点", "Daily points", model.language))
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
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
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

}
