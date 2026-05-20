import AppKit
import Combine
import Foundation

@MainActor
public final class AppModel: ObservableObject {
    @Published private(set) var engine: TimerEngine
    @Published private(set) var summaries: [DailySummary]
    @Published var config: AppConfig
    @Published private(set) var currentRecommendation: RestRecommendation

    private let store: JSONStore
    private let presenter = ReminderPresenter()
    private var timer: Timer?
    private var ticksSinceSave = 0

    public convenience init() {
        self.init(store: JSONStore())
    }

    init(store: JSONStore) {
        self.store = store
        let snapshot = store.load()
        let loadedConfig = snapshot.config
        let loadedSummaries = snapshot.summaries.sorted { $0.date < $1.date }
        let isWorkTime = SchedulePolicy.isWithinWorkSchedule(at: Date(), config: loadedConfig)

        config = loadedConfig
        summaries = loadedSummaries
        engine = TimerEngine(config: loadedConfig, isWorkTime: isWorkTime)
        currentRecommendation = RecommendationEngine.recommendation(
            for: loadedConfig.healthProfile,
            durationSeconds: loadedConfig.breakDurationSeconds,
            language: loadedConfig.language
        )

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.persist(force: true) }
        }
    }

    deinit {
        timer?.invalidate()
    }

    public var language: AppLanguage {
        config.language
    }

    var isWorkTimeNow: Bool {
        SchedulePolicy.isWithinWorkSchedule(at: Date(), config: config)
    }

    var formattedRemaining: String {
        Self.formatClock(engine.remainingSeconds)
    }

    public var menuBarTitle: String {
        switch engine.phase {
        case .offDuty:
            return L.phase(.offDuty, language)
        case .working:
            return "\(L.shortPhase(.working, language)) \(formattedRemaining)"
        case .breaking:
            return "\(L.shortPhase(.breaking, language)) \(formattedRemaining)"
        case .breakPrompt:
            if engine.promptKind == .finishBreak {
                return L.s("休息结束", "Break done", language)
            }
            return L.s("该休息", "Rest due", language)
        case .paused:
            return "\(L.shortPhase(.paused, language)) \(formattedRemaining)"
        }
    }

    var todaySummary: DailySummary {
        let today = DateKeys.dayString()
        return summaries.first(where: { $0.date == today }) ?? DailySummary(date: today)
    }

    public func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func updateConfig(_ mutate: (inout AppConfig) -> Void) {
        mutate(&config)
        engine.applyConfig(config)
        refreshRecommendation()
        if config.reminderMode == .menu {
            presenter.hide()
        } else if engine.phase == .breakPrompt || engine.phase == .breaking {
            presenter.show(model: self)
        }
        persist(force: true)
    }

    func pauseOrResume() {
        if engine.phase == .paused {
            engine.resume()
            if config.reminderMode == .floating, engine.phase == .breakPrompt || engine.phase == .breaking {
                presenter.show(model: self)
            }
        } else {
            engine.pause()
            presenter.hide()
        }
        persist(force: true)
    }

    func requestBreakNow() {
        guard engine.phase == .working || engine.phase == .paused else { return }
        engine.requestBreak()
        refreshRecommendation()
        showReminderIfNeeded()
        persist(force: true)
    }

    func startBreak() {
        guard engine.phase == .breakPrompt, engine.promptKind == .startBreak else { return }
        engine.startBreak(config: config)
        refreshRecommendation()
        showReminderIfNeeded()
        persist(force: true)
    }

    func finishBreak() {
        guard engine.phase == .breakPrompt, engine.promptKind == .finishBreak else { return }
        mutateToday { $0.completedBreaks += 1 }
        presenter.hide()
        engine.finishBreak(config: config)
        persist(force: true)
    }

    func skipBreak() {
        guard engine.phase == .breakPrompt || engine.phase == .breaking else { return }
        mutateToday { $0.skippedBreaks += 1 }
        presenter.hide()
        engine.skipBreak(config: config)
        persist(force: true)
    }

    func resetCycle() {
        presenter.hide()
        if isWorkTimeNow {
            engine.startWork(config: config)
        } else {
            engine.enterOffDuty()
        }
        persist(force: true)
    }

    func summariesForLastDays(_ days: Int, calendar: Calendar = .current) -> [DailySummary] {
        let today = Date()
        let map = Dictionary(uniqueKeysWithValues: summaries.map { ($0.date, $0) })
        return stride(from: days - 1, through: 0, by: -1).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return nil
            }
            let key = DateKeys.dayString(for: date, calendar: calendar)
            return map[key] ?? DailySummary(date: key)
        }
    }

    func persist(force: Bool = false) {
        if !force {
            ticksSinceSave += 1
            guard ticksSinceSave >= 10 else { return }
        }
        ticksSinceSave = 0
        let snapshot = AppSnapshot(config: config, summaries: summaries)
        try? store.save(snapshot)
    }

    private func tick() {
        let isWorkTime = SchedulePolicy.isWithinWorkSchedule(at: Date(), config: config)
        let previousPhase = engine.phase
        let activityDetected = config.activityDetectionEnabled
            && previousPhase == .breaking
            && ReminderPresenter.userIsActive

        let event = engine.tick(
            config: config,
            isWorkTime: isWorkTime,
            activityDetected: activityDetected
        )

        if previousPhase == .working, isWorkTime {
            mutateToday { $0.workSeconds += 1 }
        } else if previousPhase == .breaking, isWorkTime, !activityDetected {
            mutateToday { $0.breakSeconds += 1 }
        }

        switch event {
        case .workCompleted:
            refreshRecommendation()
            showReminderIfNeeded()
        case .breakCompleted:
            showReminderIfNeeded()
        case .enteredOffDuty:
            presenter.hide()
        case .resumedWork:
            presenter.hide()
        case nil:
            break
        }

        persist()
    }

    private func refreshRecommendation() {
        let seed = todaySummary.completedBreaks + todaySummary.skippedBreaks + todaySummary.workSeconds / 60
        currentRecommendation = RecommendationEngine.recommendation(
            for: config.healthProfile,
            durationSeconds: config.breakDurationSeconds,
            language: config.language,
            seed: seed
        )
    }

    private func showReminderIfNeeded() {
        if config.reminderMode == .floating {
            presenter.show(model: self)
        } else {
            presenter.hide()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func mutateToday(_ mutate: (inout DailySummary) -> Void) {
        let today = DateKeys.dayString()
        if let index = summaries.firstIndex(where: { $0.date == today }) {
            mutate(&summaries[index])
            summaries[index].updatedAt = Date()
        } else {
            var summary = DailySummary(date: today)
            mutate(&summary)
            summary.updatedAt = Date()
            summaries.append(summary)
            summaries.sort { $0.date < $1.date }
        }
    }

    static func formatClock(_ seconds: Int) -> String {
        let seconds = max(0, seconds)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}
