import Foundation

enum BreakPromptKind: String, Codable, Equatable {
    case startBreak
    case finishBreak
}

enum TimerEngineEvent: Equatable {
    case workCompleted
    case breakCompleted
    case enteredOffDuty
    case resumedWork
}

struct TimerEngine: Equatable {
    var phase: AppPhase
    var remainingSeconds: Int
    var currentBreakTotalSeconds: Int
    var promptKind: BreakPromptKind?
    private(set) var pausedPhase: AppPhase?
    private(set) var pausedPromptKind: BreakPromptKind?

    init(config: AppConfig = AppConfig(), isWorkTime: Bool = true) {
        if isWorkTime {
            phase = .working
            remainingSeconds = config.workDurationSeconds
        } else {
            phase = .offDuty
            remainingSeconds = 0
        }
        currentBreakTotalSeconds = config.breakDurationSeconds
        promptKind = nil
        pausedPhase = nil
        pausedPromptKind = nil
    }

    mutating func applySchedule(isWorkTime: Bool, config: AppConfig) -> TimerEngineEvent? {
        if !isWorkTime {
            guard phase != .offDuty else { return nil }
            enterOffDuty()
            return .enteredOffDuty
        }

        if phase == .offDuty {
            startWork(config: config)
            return .resumedWork
        }

        return nil
    }

    mutating func applyConfig(_ config: AppConfig) {
        currentBreakTotalSeconds = config.breakDurationSeconds
        switch phase {
        case .working:
            remainingSeconds = min(max(1, remainingSeconds), config.workDurationSeconds)
        case .breaking:
            remainingSeconds = min(max(1, remainingSeconds), config.breakDurationSeconds)
        default:
            break
        }
    }

    mutating func tick(config: AppConfig, isWorkTime: Bool, activityDetected: Bool = false) -> TimerEngineEvent? {
        if let scheduleEvent = applySchedule(isWorkTime: isWorkTime, config: config) {
            return scheduleEvent
        }

        switch phase {
        case .working:
            remainingSeconds = max(0, remainingSeconds - 1)
            if remainingSeconds == 0 {
                phase = .breakPrompt
                promptKind = .startBreak
                return .workCompleted
            }
        case .breaking:
            guard !activityDetected else { return nil }
            remainingSeconds = max(0, remainingSeconds - 1)
            if remainingSeconds == 0 {
                phase = .breakPrompt
                promptKind = .finishBreak
                return .breakCompleted
            }
        case .offDuty, .breakPrompt, .paused:
            break
        }

        return nil
    }

    mutating func startWork(config: AppConfig) {
        phase = .working
        remainingSeconds = config.workDurationSeconds
        currentBreakTotalSeconds = config.breakDurationSeconds
        promptKind = nil
        pausedPhase = nil
        pausedPromptKind = nil
    }

    mutating func requestBreak() {
        phase = .breakPrompt
        remainingSeconds = 0
        promptKind = .startBreak
        pausedPhase = nil
        pausedPromptKind = nil
    }

    mutating func snoozeBreak(seconds: Int) {
        phase = .working
        remainingSeconds = max(1, seconds)
        promptKind = nil
        pausedPhase = nil
        pausedPromptKind = nil
    }

    mutating func startBreak(config: AppConfig) {
        phase = .breaking
        currentBreakTotalSeconds = config.breakDurationSeconds
        remainingSeconds = config.breakDurationSeconds
        promptKind = nil
        pausedPhase = nil
        pausedPromptKind = nil
    }

    mutating func finishBreak(config: AppConfig) {
        startWork(config: config)
    }

    mutating func skipBreak(config: AppConfig) {
        startWork(config: config)
    }

    mutating func pause() {
        guard phase == .working || phase == .breaking || phase == .breakPrompt else { return }
        pausedPhase = phase
        pausedPromptKind = promptKind
        phase = .paused
    }

    mutating func resume() {
        guard let pausedPhase else { return }
        phase = pausedPhase
        promptKind = pausedPromptKind
        self.pausedPhase = nil
        pausedPromptKind = nil
    }

    mutating func enterOffDuty() {
        phase = .offDuty
        remainingSeconds = 0
        promptKind = nil
        pausedPhase = nil
        pausedPromptKind = nil
    }
}
