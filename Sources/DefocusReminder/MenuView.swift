import SwiftUI

public struct MenuPanelView: View {
    @ObservedObject var model: AppModel
    private let openSettings: () -> Void
    private let openStats: () -> Void

    public init(
        model: AppModel,
        openSettings: @escaping () -> Void = {},
        openStats: @escaping () -> Void = {}
    ) {
        self.model = model
        self.openSettings = openSettings
        self.openStats = openStats
    }

    public var body: some View {
        VStack(spacing: 14) {
            header
            timerCircle

            if model.engine.phase == .breakPrompt || model.engine.phase == .breaking {
                recommendationCard
            } else {
                todayCard
            }

            controls
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 280)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("DefocusReminder")
                    .font(.headline)
                Text(statusLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .fill(phaseColor)
                .frame(width: 10, height: 10)
        }
    }

    private var timerCircle: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(phaseColor.gradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 5) {
                Text(mainTimeText)
                    .font(.system(size: 30, weight: .light, design: .monospaced))
                    .monospacedDigit()
                Text(L.phase(model.engine.phase, model.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 132, height: 132)
    }

    private var todayCard: some View {
        HStack(spacing: 12) {
            metric(
                icon: "laptopcomputer",
                label: L.s("今日工作", "Work today", model.language),
                value: L.duration(model.todaySummary.workSeconds, model.language),
                color: .blue
            )
            metric(
                icon: "cup.and.saucer.fill",
                label: L.s("今日休息", "Break today", model.language),
                value: L.duration(model.todaySummary.breakSeconds, model.language),
                color: .green
            )
        }
    }

    private var recommendationCard: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: model.currentRecommendation.icon)
                .foregroundStyle(.green)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text(model.currentRecommendation.title(language: model.language))
                    .font(.system(size: 13, weight: .semibold))
                Text(model.currentRecommendation.detail(language: model.language))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private var controls: some View {
        VStack(spacing: 8) {
            switch model.engine.phase {
            case .offDuty:
                Button(L.s("重新检查排班", "Check schedule", model.language)) {
                    model.resetCycle()
                }
                .buttonStyle(.bordered)
            case .working:
                HStack {
                    Button(L.s("暂停", "Pause", model.language)) { model.pauseOrResume() }
                    Button(L.s("立即休息", "Rest now", model.language)) { model.requestBreakNow() }
                        .buttonStyle(.borderedProminent)
                }
            case .paused:
                HStack {
                    Button(L.s("继续", "Resume", model.language)) { model.pauseOrResume() }
                        .buttonStyle(.borderedProminent)
                    Button(L.s("重置", "Reset", model.language)) { model.resetCycle() }
                }
            case .breakPrompt:
                if model.engine.promptKind == .finishBreak {
                    Button(L.s("我回来了", "I'm back", model.language)) { model.finishBreak() }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                } else {
                    HStack {
                        Button(L.s("开始休息", "Start break", model.language)) { model.startBreak() }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        Button(L.s("跳过", "Skip", model.language)) { model.skipBreak() }
                    }
                }
            case .breaking:
                HStack {
                    Button(L.s("暂停", "Pause", model.language)) { model.pauseOrResume() }
                    Button(L.s("跳过", "Skip", model.language)) { model.skipBreak() }
                }
            }

            HStack(spacing: 8) {
                Button(action: openSettings) {
                    Label(L.s("设置", "Settings", model.language), systemImage: "gearshape")
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)

                Button(action: openStats) {
                    Label(L.s("统计", "Stats", model.language), systemImage: "chart.bar")
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .focusable(false)
    }

    private var footer: some View {
        Button {
            model.persist(force: true)
            NSApp.terminate(nil)
        } label: {
            Text(L.s("退出", "Quit", model.language))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderless)
    }

    private func metric(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    private var statusLine: String {
        if model.engine.phase == .offDuty {
            if let next = SchedulePolicy.nextWorkStart(after: Date(), config: model.config) {
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d HH:mm"
                return L.s("下次开始 \(formatter.string(from: next))", "Next start \(formatter.string(from: next))", model.language)
            }
            return L.s("非工作时间", "Outside work hours", model.language)
        }
        if model.config.activityDetectionEnabled, model.engine.phase == .breaking {
            return L.s("活动检测已开启", "Activity detection on", model.language)
        }
        return L.s("干净轻量的休息提醒", "A clean lightweight break reminder", model.language)
    }

    private var mainTimeText: String {
        switch model.engine.phase {
        case .offDuty:
            return "--:--"
        case .breakPrompt:
            return model.engine.promptKind == .finishBreak ? "Done" : "Rest"
        default:
            return model.formattedRemaining
        }
    }

    private var phaseColor: Color {
        switch model.engine.phase {
        case .offDuty: return .gray
        case .working: return .blue
        case .breakPrompt: return model.engine.promptKind == .finishBreak ? .green : .orange
        case .breaking: return .orange
        case .paused: return .purple
        }
    }

    private var progress: Double {
        switch model.engine.phase {
        case .working, .paused:
            return Double(model.engine.remainingSeconds) / Double(max(1, model.config.workDurationSeconds))
        case .breaking:
            return Double(model.engine.remainingSeconds) / Double(max(1, model.engine.currentBreakTotalSeconds))
        default:
            return 0
        }
    }
}
