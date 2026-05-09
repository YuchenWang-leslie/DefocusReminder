import Foundation

public enum L {
    public static func s(_ zh: String, _ en: String, _ language: AppLanguage) -> String {
        language.resolved == .zh ? zh : en
    }

    static func phase(_ phase: AppPhase, _ language: AppLanguage) -> String {
        switch phase {
        case .offDuty:
            return s("下班", "Off duty", language)
        case .working:
            return s("工作", "Work", language)
        case .breakPrompt:
            return s("该休息了", "Break due", language)
        case .breaking:
            return s("休息", "Break", language)
        case .paused:
            return s("暂停", "Paused", language)
        }
    }

    static func shortPhase(_ phase: AppPhase, _ language: AppLanguage) -> String {
        switch phase {
        case .offDuty: return s("下班", "Off", language)
        case .working: return s("工作", "Work", language)
        case .breakPrompt: return s("休息", "Rest", language)
        case .breaking: return s("休息", "Break", language)
        case .paused: return s("暂停", "Pause", language)
        }
    }

    static func weekdayName(_ weekday: Int, _ language: AppLanguage) -> String {
        let zh = [1: "日", 2: "一", 3: "二", 4: "三", 5: "四", 6: "五", 7: "六"]
        let en = [1: "Sun", 2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri", 7: "Sat"]
        return language.resolved == .zh ? (zh[weekday] ?? "?") : (en[weekday] ?? "?")
    }

    static func duration(_ seconds: Int, _ language: AppLanguage) -> String {
        let minutes = seconds / 60
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return language.resolved == .zh ? "\(hours)小时\(mins)分" : "\(hours)h \(mins)m"
        }
        return language.resolved == .zh ? "\(minutes)分钟" : "\(minutes)m"
    }
}
