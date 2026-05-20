import Foundation

public enum AppPhase: String, Codable, CaseIterable, Equatable, Hashable {
    case offDuty
    case working
    case breakPrompt
    case breaking
    case paused
}

enum ReminderMode: String, Codable, CaseIterable, Identifiable, Equatable, Hashable {
    case menu
    case floating

    var id: String { rawValue }

    func label(language: AppLanguage) -> String {
        switch self {
        case .menu:
            return L.s("菜单栏提醒", "Menu reminder", language)
        case .floating:
            return L.s("右上角悬浮", "Top-right floating", language)
        }
    }
}

public enum MenuBarDisplayMode: String, Codable, CaseIterable, Identifiable, Equatable, Hashable {
    case iconAndText
    case iconOnly
    case textOnly

    public var id: String { rawValue }

    func label(language: AppLanguage) -> String {
        switch self {
        case .iconAndText:
            return L.s("图标 + 倒计时", "Icon + timer", language)
        case .iconOnly:
            return L.s("仅图标", "Icon only", language)
        case .textOnly:
            return L.s("仅文字", "Text only", language)
        }
    }
}

public enum AppLanguage: String, Codable, CaseIterable, Identifiable, Equatable, Hashable {
    case system
    case zh
    case en

    public var id: String { rawValue }

    public var resolved: AppLanguage {
        if self != .system { return self }
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("zh") ? .zh : .en
    }

    func label() -> String {
        switch self {
        case .system:
            return resolved == .zh ? "跟随系统" : "System"
        case .zh:
            return "中文"
        case .en:
            return "English"
        }
    }
}

enum ProfessionTag: String, Codable, CaseIterable, Identifiable, Equatable, Hashable {
    case general
    case programmer
    case designer
    case student
    case writer
    case researcher
    case manager

    var id: String { rawValue }

    func label(language: AppLanguage) -> String {
        switch self {
        case .general: return L.s("通用", "General", language)
        case .programmer: return L.s("程序员", "Programmer", language)
        case .designer: return L.s("设计师", "Designer", language)
        case .student: return L.s("学生", "Student", language)
        case .writer: return L.s("写作/编辑", "Writer", language)
        case .researcher: return L.s("研究/分析", "Researcher", language)
        case .manager: return L.s("管理/会议", "Manager", language)
        }
    }
}

enum SymptomTag: String, Codable, CaseIterable, Identifiable, Equatable, Hashable {
    case dryEyes
    case neckShoulder
    case lowerBack
    case wrist
    case sedentary
    case stress
    case fatigue

    var id: String { rawValue }

    func label(language: AppLanguage) -> String {
        switch self {
        case .dryEyes: return L.s("眼干", "Dry eyes", language)
        case .neckShoulder: return L.s("颈肩酸", "Neck/shoulder", language)
        case .lowerBack: return L.s("腰背酸", "Lower back", language)
        case .wrist: return L.s("手腕紧", "Wrist strain", language)
        case .sedentary: return L.s("久坐", "Sedentary", language)
        case .stress: return L.s("压力大", "Stress", language)
        case .fatigue: return L.s("疲劳", "Fatigue", language)
        }
    }
}

struct HealthProfile: Codable, Equatable {
    var profession: ProfessionTag
    var symptoms: Set<SymptomTag>

    init(profession: ProfessionTag = .general, symptoms: Set<SymptomTag> = []) {
        self.profession = profession
        self.symptoms = symptoms
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        profession = try container.decodeIfPresent(ProfessionTag.self, forKey: .profession) ?? .general
        symptoms = try container.decodeIfPresent(Set<SymptomTag>.self, forKey: .symptoms) ?? []
    }
}

struct AppConfig: Codable, Equatable {
    var workDays: Set<Int>
    var workStartTime: String
    var workEndTime: String
    var workMinutes: Int
    var breakMinutes: Int
    var reminderMode: ReminderMode
    var menuBarDisplayMode: MenuBarDisplayMode
    var language: AppLanguage
    var healthProfile: HealthProfile
    var activityDetectionEnabled: Bool
    var remindersPausedUntil: Date?

    init(
        workDays: Set<Int> = [2, 3, 4, 5, 6],
        workStartTime: String = "09:00",
        workEndTime: String = "18:00",
        workMinutes: Int = 50,
        breakMinutes: Int = 5,
        reminderMode: ReminderMode = .floating,
        menuBarDisplayMode: MenuBarDisplayMode = .iconAndText,
        language: AppLanguage = .system,
        healthProfile: HealthProfile = HealthProfile(),
        activityDetectionEnabled: Bool = false,
        remindersPausedUntil: Date? = nil
    ) {
        self.workDays = workDays
        self.workStartTime = workStartTime
        self.workEndTime = workEndTime
        self.workMinutes = workMinutes
        self.breakMinutes = breakMinutes
        self.reminderMode = reminderMode
        self.menuBarDisplayMode = menuBarDisplayMode
        self.language = language
        self.healthProfile = healthProfile
        self.activityDetectionEnabled = activityDetectionEnabled
        self.remindersPausedUntil = remindersPausedUntil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppConfig()
        workDays = try container.decodeIfPresent(Set<Int>.self, forKey: .workDays) ?? defaults.workDays
        workStartTime = try container.decodeIfPresent(String.self, forKey: .workStartTime) ?? defaults.workStartTime
        workEndTime = try container.decodeIfPresent(String.self, forKey: .workEndTime) ?? defaults.workEndTime
        workMinutes = try container.decodeIfPresent(Int.self, forKey: .workMinutes) ?? defaults.workMinutes
        breakMinutes = try container.decodeIfPresent(Int.self, forKey: .breakMinutes) ?? defaults.breakMinutes
        reminderMode = try container.decodeIfPresent(ReminderMode.self, forKey: .reminderMode) ?? defaults.reminderMode
        menuBarDisplayMode = try container.decodeIfPresent(MenuBarDisplayMode.self, forKey: .menuBarDisplayMode) ?? defaults.menuBarDisplayMode
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? defaults.language
        healthProfile = try container.decodeIfPresent(HealthProfile.self, forKey: .healthProfile) ?? defaults.healthProfile
        activityDetectionEnabled = try container.decodeIfPresent(Bool.self, forKey: .activityDetectionEnabled) ?? defaults.activityDetectionEnabled
        remindersPausedUntil = try container.decodeIfPresent(Date.self, forKey: .remindersPausedUntil) ?? defaults.remindersPausedUntil
    }

    var workDurationSeconds: Int {
        max(1, workMinutes) * 60
    }

    var breakDurationSeconds: Int {
        max(1, breakMinutes) * 60
    }
}

struct DailySummary: Codable, Identifiable, Equatable {
    var id: String { date }
    var date: String
    var workSeconds: Int
    var breakSeconds: Int
    var completedBreaks: Int
    var skippedBreaks: Int
    var updatedAt: Date

    init(
        date: String,
        workSeconds: Int = 0,
        breakSeconds: Int = 0,
        completedBreaks: Int = 0,
        skippedBreaks: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.date = date
        self.workSeconds = workSeconds
        self.breakSeconds = breakSeconds
        self.completedBreaks = completedBreaks
        self.skippedBreaks = skippedBreaks
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(String.self, forKey: .date)
        workSeconds = try container.decodeIfPresent(Int.self, forKey: .workSeconds) ?? 0
        breakSeconds = try container.decodeIfPresent(Int.self, forKey: .breakSeconds) ?? 0
        completedBreaks = try container.decodeIfPresent(Int.self, forKey: .completedBreaks) ?? 0
        skippedBreaks = try container.decodeIfPresent(Int.self, forKey: .skippedBreaks) ?? 0
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

struct AppSnapshot: Codable, Equatable {
    var version: Int
    var config: AppConfig
    var summaries: [DailySummary]

    init(version: Int = 1, config: AppConfig = AppConfig(), summaries: [DailySummary] = []) {
        self.version = version
        self.config = config
        self.summaries = summaries
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        config = try container.decodeIfPresent(AppConfig.self, forKey: .config) ?? AppConfig()
        summaries = try container.decodeIfPresent([DailySummary].self, forKey: .summaries) ?? []
    }
}

enum DateKeys {
    static func dayString(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func displayDay(_ dateString: String) -> String {
        let parts = dateString.split(separator: "-")
        guard parts.count == 3 else { return dateString }
        return String(parts[1]) + "/" + String(parts[2])
    }
}
