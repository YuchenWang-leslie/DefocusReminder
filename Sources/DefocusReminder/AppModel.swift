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
    private let nowProvider: () -> Date
    private let presenter = ReminderPresenter()
    private var timer: Timer?
    private var ticksSinceSave = 0
    private var notificationTokens: [NSObjectProtocol] = []
    private var workspaceNotificationTokens: [NSObjectProtocol] = []
    private var systemPauseActive = false

    public convenience init() {
        self.init(store: JSONStore())
    }

    init(store: JSONStore, nowProvider: @escaping () -> Date = Date.init) {
        self.store = store
        self.nowProvider = nowProvider
        let snapshot = store.load()
        let loadedConfig = snapshot.config
        let loadedSummaries = snapshot.summaries.sorted { $0.date < $1.date }
        let isWorkTime = SchedulePolicy.isWithinWorkSchedule(at: nowProvider(), config: loadedConfig)

        config = loadedConfig
        summaries = loadedSummaries
        engine = TimerEngine(config: loadedConfig, isWorkTime: isWorkTime)
        currentRecommendation = RecommendationEngine.recommendation(
            for: loadedConfig.healthProfile,
            durationSeconds: loadedConfig.breakDurationSeconds,
            language: loadedConfig.language
        )

        notificationTokens.append(NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.persist(force: true) }
        })

        installSystemPauseObservers()
    }

    deinit {
        timer?.invalidate()
        for token in notificationTokens {
            NotificationCenter.default.removeObserver(token)
        }
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        for token in workspaceNotificationTokens {
            workspaceCenter.removeObserver(token)
        }
    }

    public var language: AppLanguage {
        config.language
    }

    public var menuBarDisplayMode: MenuBarDisplayMode {
        config.menuBarDisplayMode
    }

    var isWorkTimeNow: Bool {
        SchedulePolicy.isWithinWorkSchedule(at: nowProvider(), config: config)
    }

    var formattedRemaining: String {
        Self.formatClock(engine.remainingSeconds)
    }

    public var menuBarTitle: String {
        if isRemindersPaused {
            return L.s("今日暂停", "Paused today", language)
        }

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
        let today = DateKeys.dayString(for: nowProvider())
        return summaries.first(where: { $0.date == today }) ?? DailySummary(date: today)
    }

    var isRemindersPaused: Bool {
        guard let until = config.remindersPausedUntil else { return false }
        return until > nowProvider()
    }

    public var menuBarStatusIcon: String {
        if isRemindersPaused { return "pause.circle.fill" }
        switch engine.phase {
        case .offDuty:
            return "moon.zzz.fill"
        case .working:
            return "timer"
        case .breakPrompt:
            return engine.promptKind == .finishBreak ? "checkmark.circle.fill" : "bell.badge.fill"
        case .breaking:
            return "cup.and.saucer.fill"
        case .paused:
            return "pause.circle.fill"
        }
    }

    public func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tickOnce() }
        }
    }

    func updateConfig(_ mutate: (inout AppConfig) -> Void) {
        mutate(&config)
        engine.applyConfig(config)
        refreshRecommendation()
        if config.reminderMode == .menu || isRemindersPaused {
            presenter.hide()
        } else if engine.phase == .breakPrompt || engine.phase == .breaking {
            presenter.show(model: self)
        }
        persist(force: true)
    }

    func pauseOrResume() {
        systemPauseActive = false
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
        guard !isRemindersPaused, engine.phase == .working || engine.phase == .paused else { return }
        engine.requestBreak()
        refreshRecommendation()
        showReminderIfNeeded()
        persist(force: true)
    }

    func startBreak() {
        guard !isRemindersPaused, engine.phase == .breakPrompt, engine.promptKind == .startBreak else { return }
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
        if config.remindersPausedUntil != nil {
            config.remindersPausedUntil = nil
        }
        presenter.hide()
        if isWorkTimeNow {
            engine.startWork(config: config)
        } else {
            engine.enterOffDuty()
        }
        persist(force: true)
    }

    func snoozeBreak(minutes: Int = 5) {
        guard engine.phase == .breakPrompt, engine.promptKind == .startBreak else { return }
        presenter.hide()
        engine.snoozeBreak(seconds: minutes * 60)
        persist(force: true)
    }

    func pauseRemindersForToday() {
        let now = nowProvider()
        let tomorrow = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: now)
        ) ?? now.addingTimeInterval(24 * 60 * 60)
        config.remindersPausedUntil = tomorrow
        presenter.hide()
        persist(force: true)
    }

    func resumeReminders() {
        config.remindersPausedUntil = nil
        resetCycle()
    }

    func summariesForLastDays(_ days: Int, calendar: Calendar = .current) -> [DailySummary] {
        let today = nowProvider()
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

    func tickOnce() {
        clearExpiredReminderPause()
        if isRemindersPaused {
            presenter.hide()
            persist()
            return
        }

        let now = nowProvider()
        let isWorkTime = SchedulePolicy.isWithinWorkSchedule(at: now, config: config)
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
        let seed = Int.random(in: 0..<10_000)
        currentRecommendation = RecommendationEngine.recommendation(
            for: config.healthProfile,
            durationSeconds: config.breakDurationSeconds,
            language: config.language,
            seed: seed,
            avoiding: currentRecommendation.id
        )
    }

    private func showReminderIfNeeded() {
        guard !isRemindersPaused else {
            presenter.hide()
            return
        }

        if config.reminderMode == .floating {
            presenter.show(model: self)
        } else {
            presenter.hide()
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    private func mutateToday(_ mutate: (inout DailySummary) -> Void) {
        let today = DateKeys.dayString(for: nowProvider())
        if let index = summaries.firstIndex(where: { $0.date == today }) {
            mutate(&summaries[index])
            summaries[index].updatedAt = nowProvider()
        } else {
            var summary = DailySummary(date: today)
            mutate(&summary)
            summary.updatedAt = nowProvider()
            summaries.append(summary)
            summaries.sort { $0.date < $1.date }
        }
    }

    private func clearExpiredReminderPause() {
        guard let until = config.remindersPausedUntil, until <= nowProvider() else { return }
        config.remindersPausedUntil = nil
    }

    private func installSystemPauseObservers() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let pauseNotifications: [Notification.Name] = [
            NSWorkspace.willSleepNotification,
            NSWorkspace.screensDidSleepNotification,
            NSWorkspace.sessionDidResignActiveNotification,
        ]
        let resumeNotifications: [Notification.Name] = [
            NSWorkspace.didWakeNotification,
            NSWorkspace.screensDidWakeNotification,
            NSWorkspace.sessionDidBecomeActiveNotification,
        ]

        for name in pauseNotifications {
            workspaceNotificationTokens.append(workspaceCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.pauseForSystemInactivity() }
            })
        }

        for name in resumeNotifications {
            workspaceNotificationTokens.append(workspaceCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.resumeAfterSystemInactivity() }
            })
        }
    }

    private func pauseForSystemInactivity() {
        guard !systemPauseActive else { return }
        guard engine.phase == .working || engine.phase == .breaking || engine.phase == .breakPrompt else {
            persist(force: true)
            return
        }

        engine.pause()
        systemPauseActive = true
        presenter.hide()
        persist(force: true)
    }

    private func resumeAfterSystemInactivity() {
        guard systemPauseActive else { return }
        systemPauseActive = false

        if isRemindersPaused {
            presenter.hide()
            persist(force: true)
            return
        }

        if isWorkTimeNow {
            engine.resume()
            if engine.phase == .breakPrompt || engine.phase == .breaking {
                showReminderIfNeeded()
            } else {
                presenter.hide()
            }
        } else {
            engine.enterOffDuty()
            presenter.hide()
        }
        persist(force: true)
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
