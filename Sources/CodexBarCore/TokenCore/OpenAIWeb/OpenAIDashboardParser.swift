import Foundation

public enum OpenAIDashboardParser {
    public struct ParsedRateLimits: Equatable, Sendable {
        public let primary: RateWindow?
        public let secondary: RateWindow?
        public let sparkPrimary: RateWindow?
        public let sparkSecondary: RateWindow?

        public init(
            primary: RateWindow?,
            secondary: RateWindow?,
            sparkPrimary: RateWindow?,
            sparkSecondary: RateWindow?)
        {
            self.primary = primary
            self.secondary = secondary
            self.sparkPrimary = sparkPrimary
            self.sparkSecondary = sparkSecondary
        }
    }

    /// Extracts the signed-in email from the embedded `client-bootstrap` JSON payload, if present.
    ///
    /// The Codex usage dashboard currently ships a JSON blob in:
    /// `<script type="application/json" id="client-bootstrap">…</script>`.
    /// WebKit `document.body.innerText` often does not include the email, so we parse it from HTML.
    public static func parseSignedInEmailFromClientBootstrap(html: String) -> String? {
        guard let data = self.clientBootstrapJSONData(fromHTML: html) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }

        // Fast path: common structure.
        if let dict = json as? [String: Any] {
            if let session = dict["session"] as? [String: Any],
               let user = session["user"] as? [String: Any],
               let email = user["email"] as? String,
               email.contains("@")
            {
                return email.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            if let user = dict["user"] as? [String: Any],
               let email = user["email"] as? String,
               email.contains("@")
            {
                return email.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        // Fallback: BFS scan for an email key/value.
        var queue: [Any] = [json]
        var seen = 0
        while !queue.isEmpty, seen < 4000 {
            let cur = queue.removeFirst()
            seen += 1
            if let dict = cur as? [String: Any] {
                for (k, v) in dict {
                    if k.lowercased() == "email", let email = v as? String, email.contains("@") {
                        return email.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    queue.append(v)
                }
            } else if let arr = cur as? [Any] {
                queue.append(contentsOf: arr)
            }
        }
        return nil
    }

    /// Extracts the auth status from `client-bootstrap`, if present.
    /// Expected values include `logged_in` and `logged_out`.
    public static func parseAuthStatusFromClientBootstrap(html: String) -> String? {
        guard let data = self.clientBootstrapJSONData(fromHTML: html) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }
        guard let dict = json as? [String: Any] else { return nil }
        if let authStatus = dict["authStatus"] as? String, !authStatus.isEmpty {
            return authStatus.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    public static func parseCodeReviewRemainingPercent(bodyText: String) -> Double? {
        let cleaned = bodyText.replacingOccurrences(of: "\r", with: "\n")
        for regex in self.codeReviewRegexes {
            let range = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
            guard let match = regex.firstMatch(in: cleaned, options: [], range: range),
                  match.numberOfRanges >= 2,
                  let r = Range(match.range(at: 1), in: cleaned)
            else { continue }
            if let val = Double(cleaned[r]) { return min(100, max(0, val)) }
        }
        return nil
    }

    public static func parseCreditsRemaining(bodyText: String) -> Double? {
        let cleaned = bodyText.replacingOccurrences(of: "\r", with: "\n")
        let patterns = [
            #"credits\s*remaining[^0-9]*([0-9][0-9.,]*)"#,
            #"remaining\s*credits[^0-9]*([0-9][0-9.,]*)"#,
            #"credit\s*balance[^0-9]*([0-9][0-9.,]*)"#,
            #"剩余\s*credits[^0-9]*([0-9][0-9.,]*)"#,
            #"credits\s*剩余[^0-9]*([0-9][0-9.,]*)"#,
            #"剩余\s*额度[^0-9]*([0-9][0-9.,]*)"#,
            #"残り\s*credits[^0-9]*([0-9][0-9.,]*)"#,
            #"credits\s*残り[^0-9]*([0-9][0-9.,]*)"#,
        ]
        for pattern in patterns {
            if let val = TextParsing.firstNumber(pattern: pattern, text: cleaned) { return val }
        }
        return nil
    }

    public static func parseRateLimits(
        bodyText: String,
        now: Date = .init()) -> (primary: RateWindow?, secondary: RateWindow?)
    {
        let parsed = self.parseGroupedRateLimits(bodyText: bodyText, now: now)
        return (parsed.primary, parsed.secondary)
    }

    public static func parseGroupedRateLimits(
        bodyText: String,
        now: Date = .init()) -> ParsedRateLimits
    {
        let cleaned = bodyText.replacingOccurrences(of: "\r", with: "\n")
        let lines = cleaned
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var primary: RateWindow?
        var secondary: RateWindow?
        var sparkPrimary: RateWindow?
        var sparkSecondary: RateWindow?

        for index in lines.indices {
            let line = lines[index]
            if self.isFiveHourLimitLine(line) {
                let window = self.parseRateWindow(
                    lines: lines,
                    startIndex: index,
                    windowMinutes: 5 * 60,
                    now: now)
                switch self.limitBucket(lines: lines, index: index) {
                case .general:
                    if primary == nil {
                        primary = window
                    }
                case .spark:
                    if sparkPrimary == nil {
                        sparkPrimary = window
                    }
                }
                continue
            }

            guard self.isWeeklyLimitLine(line) else { continue }
            let window = self.parseRateWindow(
                lines: lines,
                startIndex: index,
                windowMinutes: 7 * 24 * 60,
                now: now)
            switch self.limitBucket(lines: lines, index: index) {
            case .general:
                if secondary == nil {
                    secondary = window
                }
            case .spark:
                if sparkSecondary == nil {
                    sparkSecondary = window
                }
            }
        }

        return ParsedRateLimits(
            primary: primary,
            secondary: secondary,
            sparkPrimary: sparkPrimary,
            sparkSecondary: sparkSecondary)
    }

    public static func parsePlanFromHTML(html: String) -> String? {
        if let data = self.clientBootstrapJSONData(fromHTML: html),
           let plan = self.findPlan(in: data)
        {
            return plan
        }
        if let data = self.nextDataJSONData(fromHTML: html),
           let plan = self.findPlan(in: data)
        {
            return plan
        }
        return nil
    }

    public static func parseCreditEvents(rows: [[String]]) -> [CreditEvent] {
        let formatter = self.creditDateFormatter()

        return rows.compactMap { row in
            guard row.count >= 3 else { return nil }
            let dateString = row[0]
            let service = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let amountString = row[2]
            guard let date = formatter.date(from: dateString) else { return nil }
            let creditsUsed = Self.parseCreditsUsed(amountString)
            return CreditEvent(date: date, service: service, creditsUsed: creditsUsed)
        }
        .sorted { $0.date > $1.date }
    }

    private static func parseCreditsUsed(_ text: String) -> Double {
        let cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "credits", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned) ?? 0
    }

    // MARK: - Private

    private static let codeReviewRegexes: [NSRegularExpression] = {
        let patterns = [
            #"Code\s*review[^0-9%]*([0-9]{1,3})%\s*remaining"#,
            #"Core\s*review[^0-9%]*([0-9]{1,3})%\s*remaining"#,
            #"Code\s*review(?:[^0-9%]|\n)*([0-9]{1,3})%\s*(?:remaining|left|剩余|残り)"#,
            #"Core\s*review(?:[^0-9%]|\n)*([0-9]{1,3})%\s*(?:remaining|left|剩余|残り)"#,
            #"([0-9]{1,3})%\s*(?:remaining|left|剩余|残り)(?:[^A-Za-z%]|\n)*Code\s*review"#,
            #"([0-9]{1,3})%\s*(?:remaining|left|剩余|残り)(?:[^A-Za-z%]|\n)*Core\s*review"#,
        ]
        return patterns.compactMap { pattern in
            try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        }
    }()

    private static let creditDateFormatterKey = "OpenAIDashboardParser.creditDateFormatter"
    private static let clientBootstrapNeedle = Data("id=\"client-bootstrap\"".utf8)
    private static let nextDataNeedle = Data("id=\"__NEXT_DATA__\"".utf8)
    private static let scriptCloseNeedle = Data("</script>".utf8)

    private static func creditDateFormatter() -> DateFormatter {
        let threadDict = Thread.current.threadDictionary
        if let cached = threadDict[self.creditDateFormatterKey] as? DateFormatter {
            return cached
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy"
        threadDict[self.creditDateFormatterKey] = formatter
        return formatter
    }

    private static func clientBootstrapJSONData(fromHTML html: String) -> Data? {
        let data = Data(html.utf8)
        guard let idRange = data.range(of: self.clientBootstrapNeedle) else { return nil }

        guard let openTagEnd = data[idRange.upperBound...].firstIndex(of: UInt8(ascii: ">")) else { return nil }
        let contentStart = data.index(after: openTagEnd)
        guard let closeRange = data.range(
            of: self.scriptCloseNeedle,
            options: [],
            in: contentStart..<data.endIndex)
        else {
            return nil
        }
        let rawData = data[contentStart..<closeRange.lowerBound]
        let trimmed = self.trimASCIIWhitespace(Data(rawData))
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func nextDataJSONData(fromHTML html: String) -> Data? {
        let data = Data(html.utf8)
        guard let idRange = data.range(of: self.nextDataNeedle) else { return nil }

        guard let openTagEnd = data[idRange.upperBound...].firstIndex(of: UInt8(ascii: ">")) else { return nil }
        let contentStart = data.index(after: openTagEnd)
        guard let closeRange = data.range(
            of: self.scriptCloseNeedle,
            options: [],
            in: contentStart..<data.endIndex)
        else {
            return nil
        }
        let rawData = data[contentStart..<closeRange.lowerBound]
        let trimmed = self.trimASCIIWhitespace(Data(rawData))
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func trimASCIIWhitespace(_ data: Data) -> Data {
        guard !data.isEmpty else { return data }
        var start = data.startIndex
        var end = data.endIndex

        while start < end, data[start].isASCIIWhitespace {
            start = data.index(after: start)
        }
        while end > start {
            let prev = data.index(before: end)
            if data[prev].isASCIIWhitespace {
                end = prev
            } else {
                break
            }
        }
        return data.subdata(in: start..<end)
    }

    private enum LimitBucket {
        case general
        case spark
    }

    private static func limitBucket(lines: [String], index: Int) -> LimitBucket {
        let contextRange = max(0, index - 1)...min(lines.count - 1, index + 1)
        let context = contextRange
            .map { lines[$0].lowercased() }
            .joined(separator: " ")
        return context.contains("spark") || context.contains("gpt-5.3-codex-spark") ? .spark : .general
    }

    private static func parseRateWindow(
        lines: [String],
        startIndex: Int,
        windowMinutes: Int,
        now: Date) -> RateWindow?
    {
        guard lines.indices.contains(startIndex) else { return nil }
        let end = min(lines.count - 1, startIndex + 5)
        let windowLines = Array(lines[startIndex...end])

        var percentValue: Double?
        var isRemaining = true
        var percentLineIndex: Int?
        for (offset, line) in windowLines.enumerated() {
            if let percent = self.parsePercent(from: line) {
                percentValue = percent.value
                isRemaining = percent.isRemaining
                percentLineIndex = offset
                break
            }
        }

        guard let percentValue else { return nil }
        let usedPercent = isRemaining ? max(0, min(100, 100 - percentValue)) : max(0, min(100, percentValue))

        let resetSearchStart = min(windowLines.count - 1, (percentLineIndex ?? 0) + 1)
        let trailingResetLine = windowLines[resetSearchStart...].first(where: self.isLikelyResetLine)
        let resetLine = trailingResetLine ?? windowLines.first(where: self.isLikelyResetLine)
        let resetDescription = resetLine?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resetsAt = resetLine.flatMap { self.parseResetDate(from: $0, now: now) }
        let fallbackDescription = resetsAt.map { UsageFormatter.resetDescription(from: $0) }

        return RateWindow(
            usedPercent: usedPercent,
            windowMinutes: windowMinutes,
            resetsAt: resetsAt,
            resetDescription: resetDescription ?? fallbackDescription)
    }

    private static func parsePercent(from line: String) -> (value: Double, isRemaining: Bool)? {
        guard let percent = TextParsing.firstNumber(pattern: #"([0-9]{1,3})\s*%"#, text: line) else { return nil }
        let lower = line.lowercased()
        let isRemaining = lower.contains("remaining")
            || lower.contains("left")
            || line.contains("剩余")
            || line.contains("残り")
        let isUsed = lower.contains("used")
            || lower.contains("spent")
            || lower.contains("consumed")
            || line.contains("已用")
            || line.contains("已使用")
            || line.contains("消耗")
            || line.contains("使用済")
        if isUsed { return (percent, false) }
        if isRemaining { return (percent, true) }
        return (percent, true)
    }

    private static func isFiveHourLimitLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        if lower.contains("5h") { return true }
        if lower.contains("5-hour") { return true }
        if lower.contains("5 hour") { return true }
        if line.range(of: #"5\s*(小时|小時|時間)"#, options: .regularExpression) != nil { return true }
        return false
    }

    private static func isWeeklyLimitLine(_ line: String) -> Bool {
        let lower = line.lowercased()
        if lower.contains("weekly") { return true }
        if lower.contains("7-day") { return true }
        if lower.contains("7 day") { return true }
        if lower.contains("7d") { return true }
        if line.contains("每周") || line.contains("每週") { return true }
        if line.range(of: #"(?:2|7)\s*(周|週|天|日|週間)"#, options: .regularExpression) != nil { return true }
        return false
    }

    private static func parseResetDate(from line: String, now: Date) -> Date? {
        var raw = line.trimmingCharacters(in: .whitespacesAndNewlines)
        raw = raw.replacingOccurrences(of: #"(?i)^resets?:?\s*"#, with: "", options: .regularExpression)
        raw = raw.replacingOccurrences(of: #"^(?:重置|更新|刷新|リセット)[:：]?\s*"#, with: "", options: .regularExpression)
        raw = raw.replacingOccurrences(of: " at ", with: " ", options: .caseInsensitive)
        raw = raw.replacingOccurrences(of: " on ", with: " ", options: .caseInsensitive)
        raw = raw.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let calendar = Calendar(identifier: .gregorian)
        let monthDayFormatter = DateFormatter()
        monthDayFormatter.locale = Locale(identifier: "en_US_POSIX")
        monthDayFormatter.timeZone = TimeZone.current
        monthDayFormatter.dateFormat = "MMM d"

        var candidate = raw
        let lower = candidate.lowercased()
        var usedRelativeDay = false

        if lower.contains("today") {
            usedRelativeDay = true
            let dateText = monthDayFormatter.string(from: now)
            candidate = candidate.replacingOccurrences(of: "today", with: dateText, options: .caseInsensitive)
        } else if lower.contains("tomorrow") {
            usedRelativeDay = true
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
                let dateText = monthDayFormatter.string(from: tomorrow)
                candidate = candidate.replacingOccurrences(of: "tomorrow", with: dateText, options: .caseInsensitive)
            }
        }
        if candidate.contains("今天") || candidate.contains("今日") {
            usedRelativeDay = true
            let dateText = monthDayFormatter.string(from: now)
            candidate = candidate.replacingOccurrences(of: "今天", with: dateText)
            candidate = candidate.replacingOccurrences(of: "今日", with: dateText)
        } else if candidate.contains("明天") || candidate.contains("明日") {
            usedRelativeDay = true
            if let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) {
                let dateText = monthDayFormatter.string(from: tomorrow)
                candidate = candidate.replacingOccurrences(of: "明天", with: dateText)
                candidate = candidate.replacingOccurrences(of: "明日", with: dateText)
            }
        }

        candidate = candidate.replacingOccurrences(
            of: #"(\d{4})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日"#,
            with: "$1-$2-$3",
            options: .regularExpression)
        candidate = candidate.replacingOccurrences(
            of: #"(\d{1,2})\s*月\s*(\d{1,2})\s*日"#,
            with: "$1/$2",
            options: .regularExpression)
        candidate = candidate.replacingOccurrences(of: "号", with: "")

        if let timeOnly = self.parseTimeOnly(candidate, now: now, calendar: calendar) {
            return timeOnly
        }

        if let weekdayMatch = self.weekdayMatch(in: candidate) {
            usedRelativeDay = true
            let target = self.nextWeekdayDate(weekday: weekdayMatch.weekday, now: now, calendar: calendar)
            let dateText = monthDayFormatter.string(from: target)
            candidate = candidate.replacingOccurrences(
                of: weekdayMatch.matched,
                with: dateText,
                options: .caseInsensitive)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.defaultDate = now

        let formats = [
            "MMM d h:mma",
            "MMM d, h:mma",
            "MMM d h:mm a",
            "MMM d, h:mm a",
            "MMM d HH:mm",
            "MMM d, HH:mm",
            "MMM d",
            "M/d h:mma",
            "M/d h:mm a",
            "M/d/yyyy h:mm a",
            "M/d/yy h:mm a",
            "M/d",
            "yyyy-M-d HH:mm",
            "yyyy-M-d h:mm a",
            "yyyy-M-d",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd h:mm a",
            "yyyy-MM-dd",
        ]

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: candidate) {
                if usedRelativeDay, date < now {
                    if lower.contains("today"),
                       let bumped = calendar.date(byAdding: .day, value: 1, to: date)
                    {
                        return bumped
                    }
                    if let bumped = calendar.date(byAdding: .day, value: 7, to: date) {
                        return bumped
                    }
                }
                return date
            }
        }
        return nil
    }

    private static func isLikelyResetLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed.contains("%") { return false }

        let lower = trimmed.lowercased()
        if lower.contains("reset")
            || trimmed.contains("重置")
            || trimmed.contains("更新")
            || trimmed.contains("刷新")
            || trimmed.contains("リセット")
            || lower.contains("today")
            || lower.contains("tomorrow")
            || trimmed.contains("今天")
            || trimmed.contains("明天")
            || trimmed.contains("今日")
            || trimmed.contains("明日")
        {
            return true
        }

        let patterns = [
            #"(?:^|\b)\d{1,2}:\d{2}(?:\s*[ap]m)?(?:\b|$)"#,
            #"(?:^|\b)(?:jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\s+\d{1,2}(?:\b|$)"#,
            #"(?:^|\b)\d{1,2}/\d{1,2}(?:/\d{2,4})?(?:\b|$)"#,
            #"\d{1,2}\s*月\s*\d{1,2}\s*日"#,
            #"\d{4}\s*年\s*\d{1,2}\s*月\s*\d{1,2}\s*日"#,
        ]
        return patterns.contains { pattern in
            trimmed.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private static func parseTimeOnly(_ candidate: String, now: Date, calendar: Calendar) -> Date? {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.range(
            of: #"^\d{1,2}:\d{2}(?:\s*[ap]m)?$"#,
            options: [.regularExpression, .caseInsensitive]) != nil
        else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        let formats = ["HH:mm", "h:mma", "h:mm a"]

        for format in formats {
            formatter.dateFormat = format
            guard let parsed = formatter.date(from: trimmed) else { continue }
            let components = calendar.dateComponents([.hour, .minute], from: parsed)
            guard let hour = components.hour, let minute = components.minute else { continue }

            var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.second = 0
            guard let date = calendar.date(from: dateComponents) else { continue }
            if date >= now { return date }
            return calendar.date(byAdding: .day, value: 1, to: date)
        }
        return nil
    }

    private struct WeekdayMatch {
        let matched: String
        let weekday: Int
    }

    private static func weekdayMatch(in text: String) -> WeekdayMatch? {
        let pattern = #"\b(mon|tue|tues|wed|thu|thur|thurs|fri|sat|sun)(day)?\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let r = Range(match.range(at: 0), in: text)
        else { return nil }
        let matched = String(text[r])
        let lower = matched.lowercased()
        let weekday = switch lower.prefix(3) {
        case "mon": 2
        case "tue": 3
        case "wed": 4
        case "thu": 5
        case "fri": 6
        case "sat": 7
        default: 1
        }
        return WeekdayMatch(matched: matched, weekday: weekday)
    }

    private static func nextWeekdayDate(weekday: Int, now: Date, calendar: Calendar) -> Date {
        let currentWeekday = calendar.component(.weekday, from: now)
        var delta = weekday - currentWeekday
        if delta < 0 { delta += 7 }
        guard let next = calendar.date(byAdding: .day, value: delta, to: calendar.startOfDay(for: now)) else {
            return now
        }
        return next
    }

    private static func findPlan(in data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else { return nil }
        return self.findPlan(in: json)
    }

    private static func findPlan(in json: Any) -> String? {
        var queue: [Any] = [json]
        var seen = 0
        while !queue.isEmpty, seen < 6000 {
            let cur = queue.removeFirst()
            seen += 1
            if let dict = cur as? [String: Any] {
                for (k, v) in dict {
                    if let plan = self.planCandidate(forKey: k, value: v) { return plan }
                    queue.append(v)
                }
            } else if let arr = cur as? [Any] {
                queue.append(contentsOf: arr)
            }
        }
        return nil
    }

    private static func planCandidate(forKey key: String, value: Any) -> String? {
        guard self.isPlanKey(key) else { return nil }
        if let str = value as? String {
            return self.normalizePlanValue(str)
        }
        if let dict = value as? [String: Any] {
            if let name = dict["name"] as? String, let plan = self.normalizePlanValue(name) { return plan }
            if let display = dict["displayName"] as? String, let plan = self.normalizePlanValue(display) { return plan }
            if let tier = dict["tier"] as? String, let plan = self.normalizePlanValue(tier) { return plan }
        }
        return nil
    }

    private static func isPlanKey(_ key: String) -> Bool {
        let lower = key.lowercased()
        return lower.contains("plan") || lower.contains("tier") || lower.contains("subscription")
    }

    private static func normalizePlanValue(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lower = trimmed.lowercased()
        let allowed = [
            "free",
            "plus",
            "pro",
            "team",
            "enterprise",
            "business",
            "edu",
            "education",
            "gov",
            "premium",
            "essential",
        ]
        guard allowed.contains(where: { lower.contains($0) }) else { return nil }
        return UsageFormatter.cleanPlanName(trimmed)
    }
}

extension UInt8 {
    fileprivate var isASCIIWhitespace: Bool {
        switch self {
        case 9, 10, 13, 32: true
        default: false
        }
    }
}
