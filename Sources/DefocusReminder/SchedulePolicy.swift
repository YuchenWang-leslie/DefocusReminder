import Foundation

struct TimeOfDay: Comparable, Equatable {
    let minuteOfDay: Int

    static func parse(_ value: String) -> TimeOfDay? {
        let parts = value.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        guard (0...23).contains(parts[0]), (0...59).contains(parts[1]) else { return nil }
        return TimeOfDay(minuteOfDay: parts[0] * 60 + parts[1])
    }

    static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        lhs.minuteOfDay < rhs.minuteOfDay
    }
}

enum SchedulePolicy {
    static func isWithinWorkSchedule(
        at date: Date,
        config: AppConfig,
        calendar: Calendar = .current
    ) -> Bool {
        guard let start = TimeOfDay.parse(config.workStartTime),
              let end = TimeOfDay.parse(config.workEndTime) else {
            return true
        }

        let minute = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
        let today = calendar.component(.weekday, from: date)

        if start.minuteOfDay <= end.minuteOfDay {
            return config.workDays.contains(today)
                && minute >= start.minuteOfDay
                && minute < end.minuteOfDay
        }

        if config.workDays.contains(today), minute >= start.minuteOfDay {
            return true
        }

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else {
            return false
        }
        let yesterdayWeekday = calendar.component(.weekday, from: yesterday)
        return config.workDays.contains(yesterdayWeekday) && minute < end.minuteOfDay
    }

    static func nextWorkStart(
        after date: Date,
        config: AppConfig,
        calendar: Calendar = .current
    ) -> Date? {
        guard let start = TimeOfDay.parse(config.workStartTime) else { return nil }

        for dayOffset in 0...14 {
            guard let candidateDay = calendar.date(byAdding: .day, value: dayOffset, to: date) else {
                continue
            }
            let weekday = calendar.component(.weekday, from: candidateDay)
            guard config.workDays.contains(weekday) else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: candidateDay)
            components.hour = start.minuteOfDay / 60
            components.minute = start.minuteOfDay % 60
            components.second = 0

            guard let candidate = calendar.date(from: components), candidate > date else {
                continue
            }
            return candidate
        }

        return nil
    }
}
