import CodexBarCore
import Foundation

struct UsageOverviewSegment: Identifiable, Equatable {
    let id: String
    let title: String
    let inputTokens: Int
    let outputTokens: Int
    let inputFraction: Double
    let outputFraction: Double
}

enum UsageOverviewSegmentation {
    static func normalizedFraction(value: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        return min(max(Double(value) / Double(total), 0), 1)
    }

    static func rollingWeekSegments(
        days: [DailyTokenStats],
        strings: AppStrings,
        calendar: Calendar = Calendar.current)
        -> [UsageOverviewSegment]
    {
        guard !days.isEmpty else { return [] }

        let sortedDays = days.sorted { $0.date < $1.date }
        let inputTotal = sortedDays.reduce(0) { $0 + $1.inputTokens }
        let outputTotal = sortedDays.reduce(0) { $0 + $1.outputTokens }

        return stride(from: 0, to: sortedDays.count, by: 7).compactMap { startIndex in
            let endIndex = min(startIndex + 7, sortedDays.count)
            let bucket = Array(sortedDays[startIndex..<endIndex])
            guard let firstDay = bucket.first,
                  let lastDay = bucket.last,
                  let firstDate = self.parsedDate(for: firstDay, calendar: calendar),
                  let lastDate = self.parsedDate(for: lastDay, calendar: calendar)
            else {
                return nil
            }

            let inputTokens = bucket.reduce(0) { $0 + $1.inputTokens }
            let outputTokens = bucket.reduce(0) { $0 + $1.outputTokens }

            return UsageOverviewSegment(
                id: "week-\(bucket.first?.date ?? "")-\(bucket.last?.date ?? "")",
                title: self.weekRangeTitle(
                    start: firstDate,
                    end: lastDate,
                    strings: strings,
                    calendar: calendar),
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                inputFraction: self.normalizedFraction(value: inputTokens, total: inputTotal),
                outputFraction: self.normalizedFraction(value: outputTokens, total: outputTotal))
        }
    }

    static func monthlySegments(
        days: [DailyTokenStats],
        strings: AppStrings,
        calendar: Calendar = Calendar.current)
        -> [UsageOverviewSegment]
    {
        let sortedDays = days.sorted { $0.date < $1.date }
        guard !sortedDays.isEmpty else { return [] }

        let inputTotal = sortedDays.reduce(0) { $0 + $1.inputTokens }
        let outputTotal = sortedDays.reduce(0) { $0 + $1.outputTokens }

        var grouped: [(key: String, monthDate: Date, days: [DailyTokenStats])] = []

        for day in sortedDays {
            guard let date = self.parsedDate(for: day, calendar: calendar) else { continue }
            let key = self.monthKey(for: date, calendar: calendar)

            if let lastIndex = grouped.indices.last, grouped[lastIndex].key == key {
                grouped[lastIndex].days.append(day)
            } else {
                grouped.append((key: key, monthDate: date, days: [day]))
            }
        }

        return grouped.map { group in
            let inputTokens = group.days.reduce(0) { $0 + $1.inputTokens }
            let outputTokens = group.days.reduce(0) { $0 + $1.outputTokens }

            return UsageOverviewSegment(
                id: "month-\(group.key)",
                title: self.monthTitle(for: group.monthDate, strings: strings),
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                inputFraction: self.normalizedFraction(value: inputTokens, total: inputTotal),
                outputFraction: self.normalizedFraction(value: outputTokens, total: outputTotal))
        }
    }

    private static func monthKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }

    private static func parsedDate(for day: DailyTokenStats, calendar: Calendar) -> Date? {
        let parts = day.date.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let date = Int(parts[2])
        else {
            return nil
        }

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = date
        return components.date
    }

    private static func resolvedLanguage(for strings: AppStrings) -> AppLanguage {
        switch strings.language {
        case .system:
            .zhHans
        case let value:
            value
        }
    }

    private static func monthTitle(for date: Date, strings: AppStrings) -> String {
        let formatter = DateFormatter()
        formatter.locale = strings.locale
        formatter.timeZone = TimeZone.current

        switch self.resolvedLanguage(for: strings) {
        case .en:
            formatter.dateFormat = "MMM yyyy"
        case .ja, .zhHans:
            formatter.dateFormat = "yyyy年M月"
        default:
            formatter.dateFormat = "yyyy年M月"
        }

        return formatter.string(from: date)
    }

    private static func weekRangeTitle(start: Date, end: Date, strings: AppStrings, calendar: Calendar) -> String {
        let language = self.resolvedLanguage(for: strings)
        let sameMonth = calendar.component(.month, from: start) == calendar.component(.month, from: end)
            && calendar.component(.year, from: start) == calendar.component(.year, from: end)

        let startFormatter = DateFormatter()
        startFormatter.locale = strings.locale
        startFormatter.timeZone = TimeZone.current

        let endFormatter = DateFormatter()
        endFormatter.locale = strings.locale
        endFormatter.timeZone = TimeZone.current

        switch language {
        case .en:
            startFormatter.dateFormat = "MMM d"
            endFormatter.dateFormat = sameMonth ? "d" : "MMM d"
        case .ja, .zhHans:
            startFormatter.dateFormat = "M月d日"
            endFormatter.dateFormat = sameMonth ? "d日" : "M月d日"
        default:
            startFormatter.dateFormat = "M月d日"
            endFormatter.dateFormat = sameMonth ? "d日" : "M月d日"
        }

        return "\(startFormatter.string(from: start))-\(endFormatter.string(from: end))"
    }
}
