import Foundation

public enum TokenDailyBoardLanguage: String, CaseIterable, Codable, Sendable {
    case system
    case zhHans
    case en
    case ja

    static func resolvePreferredLanguage(_ preferredLanguages: [String]) -> TokenDailyBoardLanguage {
        let first = preferredLanguages.first?.lowercased() ?? ""
        if first.hasPrefix("ja") { return .ja }
        if first.hasPrefix("en") { return .en }
        if first.hasPrefix("zh") { return .zhHans }
        return .zhHans
    }

    var localeIdentifier: String {
        switch self {
        case .system, .zhHans:
            "zh-Hans"
        case .en:
            "en"
        case .ja:
            "ja"
        }
    }
}

public struct TokenDailyBoardStrings {
    let language: TokenDailyBoardLanguage

    public init(language: TokenDailyBoardLanguage = .system) {
        self.language = language
    }

    var resolvedLanguage: TokenDailyBoardLanguage {
        if self.language == .system {
            return TokenDailyBoardLanguage.resolvePreferredLanguage(Locale.preferredLanguages)
        }
        return self.language
    }

    var locale: Locale {
        Locale(identifier: self.resolvedLanguage.localeIdentifier)
    }

    public var dailyBoardWindowTitle: String {
        self.text(zh: "日看板", en: "Daily Board", ja: "日次ボード")
    }

    var dailyBoardTodayTitle: String {
        self.text(zh: "今天", en: "Today", ja: "今日")
    }

    var dailyBoardYesterdayTitle: String {
        self.text(zh: "昨天", en: "Yesterday", ja: "昨日")
    }

    var dailyBoardDayBeforeYesterdayTitle: String {
        self.text(zh: "前天", en: "2 days ago", ja: "一昨日")
    }

    var dailyBoardTotalLabel: String {
        self.text(zh: "总量", en: "Total", ja: "総消費")
    }

    var dailyBoardMainThreadLabel: String {
        self.text(zh: "主线程", en: "Main thread", ja: "メインスレッド")
    }

    var dailyBoardTokenLabel: String {
        self.dailyBoardTotalLabel
    }

    var dailyBoardInstructionLabel: String {
        self.dailyBoardMainThreadLabel
    }

    func dailyBoardTotalTokenText(_ value: Int) -> String {
        "\(self.dailyBoardTotalLabel) \(self.compactTokenText(value))"
    }

    func dailyBoardMainThreadTokenText(_ value: Int) -> String {
        "\(self.dailyBoardMainThreadLabel) \(self.compactTokenText(value))"
    }

    func dailyBoardHumanInstructionCountText(_ value: Int) -> String {
        switch self.resolvedLanguage {
        case .zhHans, .system:
            "人类发送 \(self.exactNumberText(value)) 次"
        case .en:
            "Human sends \(self.exactNumberText(value))"
        case .ja:
            "人間送信 \(self.exactNumberText(value)) 回"
        }
    }

    func dailyBoardShortInstructionCountText(_ value: Int) -> String {
        switch self.resolvedLanguage {
        case .zhHans, .system:
            "\(self.exactNumberText(value)) 次"
        case .en:
            "\(self.exactNumberText(value)) sends"
        case .ja:
            "\(self.exactNumberText(value)) 回"
        }
    }

    var dailyBoardHeroSubtitle: String {
        self.text(
            zh: "你的 Codex 今日轨迹",
            en: "Your Codex activity today",
            ja: "あなたの Codex の今日の軌跡")
    }

    var dailyBoardTodayStatusLabel: String {
        self.text(zh: "今天的状态", en: "today's read", ja: "今日の状態")
    }

    var dailyBoardComparedToYesterdayLabel: String {
        self.text(zh: "与昨天相比", en: "compared with yesterday", ja: "昨日との比較")
    }

    var dailyBoardReferenceDaysLabel: String {
        self.text(zh: "近两天", en: "Recent Days", ja: "直近2日")
    }

    var dailyBoardArchiveDaysLabel: String {
        self.text(zh: "更早记录", en: "Earlier Notes", ja: "それ以前")
    }

    func dailyBoardComparisonHigher(percentage: Int) -> String {
        self.text(
            zh: "比昨天高 \(percentage)%",
            en: "\(percentage)% above yesterday",
            ja: "昨日より \(percentage)% 多い")
    }

    func dailyBoardComparisonLower(percentage: Int) -> String {
        self.text(
            zh: "比昨天低 \(percentage)%",
            en: "\(percentage)% below yesterday",
            ja: "昨日より \(percentage)% 少ない")
    }

    var dailyBoardComparisonSteady: String {
        self.text(zh: "和昨天接近", en: "close to yesterday", ja: "昨日と近い水準")
    }

    var dailyBoardComparisonNewActivity: String {
        self.text(zh: "今天开始活跃", en: "new activity today", ja: "今日からアクティブ")
    }

    var dailyBoardComparisonIdle: String {
        self.text(zh: "今天还没有记录", en: "no activity yet today", ja: "今日はまだ記録なし")
    }

    func dailyBoardActivityClusterText(forHour hour: Int, isToday: Bool) -> String {
        let period = self.activityPeriodText(forHour: hour)
        if isToday {
            return self.text(
                zh: "今天活跃集中在\(period)",
                en: "Today's activity clustered in the \(period)",
                ja: "今日は\(period)に動きが集まりました")
        }

        return self.text(
            zh: "活跃集中在\(period)",
            en: "Activity clustered in the \(period)",
            ja: "\(period)に動きが集まりました")
    }

    func dailyBoardQuietCaption(isToday: Bool) -> String {
        if isToday {
            return self.text(
                zh: "今天还没有形成明显节奏",
                en: "Today has not settled into a rhythm yet",
                ja: "今日はまだはっきりした流れがありません")
        }

        return self.text(
            zh: "这一天整体比较安静",
            en: "That day stayed fairly quiet",
            ja: "この日は全体的に静かでした")
    }

    var cacheMissingTitle: String {
        self.text(zh: "还没有缓存数据", en: "No cached data yet", ja: "キャッシュデータがまだありません")
    }

    var dailyBoardEmptyMonthTitle: String {
        self.text(zh: "这个月还没有统计", en: "No stats for this month", ja: "この月の統計はまだありません")
    }

    func dailyBoardEmptyMonthMessage(year: Int, month: Int) -> String {
        switch self.resolvedLanguage {
        case .zhHans, .system:
            "\(year) 年 \(month) 月还没有记录。"
        case .en:
            "No recorded activity for \(month)/\(year)."
        case .ja:
            "\(year)年\(month)月の記録はまだありません。"
        }
    }

    var cacheMissingMessage: String {
        self.text(
            zh: "还没有本地缓存。先运行 codex 产生会话，CodexDaily 会自行扫描 ~/.codex/sessions 并写入自己的本地缓存。",
            en: "No local cache yet. Run codex to create sessions. "
                + "CodexDaily scans ~/.codex/sessions and writes its own local cache.",
            ja: "ローカルキャッシュはまだありません。まず codex でセッションを作成してください。"
                + "CodexDaily は ~/.codex/sessions を自分で走査してローカルキャッシュを書き込みます。")
    }

    func cacheErrorTitle(_ _: String = "") -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            "缓存读取失败"
        case .en:
            "Failed to read cache"
        case .ja:
            "キャッシュの読み込みに失敗しました"
        case .system:
            "缓存读取失败"
        }
    }

    func cacheErrorMessage(_ message: String) -> String {
        message
    }

    func updatedDescription(from date: Date, now: Date = Date()) -> String {
        if date >= now || now.timeIntervalSince(date) < 5 {
            return self.updatedJustNowDescription
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.locale = self.locale
        formatter.unitsStyle = .short
        let relative = formatter.localizedString(for: date, relativeTo: now)

        switch self.resolvedLanguage {
        case .zhHans:
            return "\(relative)更新"
        case .en:
            return "Updated \(relative)"
        case .ja:
            return "\(relative)に更新"
        case .system:
            return "\(relative)更新"
        }
    }

    private var updatedJustNowDescription: String {
        self.text(
            zh: "刚刚更新",
            en: "Updated just now",
            ja: "たった今更新")
    }

    func dailyBoardNarrativeTimestampText(
        _ date: Date,
        isToday: Bool,
        timeZone: TimeZone = .autoupdatingCurrent)
        -> String
    {
        let formatter = DateFormatter()
        formatter.locale = self.locale
        formatter.timeZone = timeZone
        formatter.dateFormat = isToday ? "HH:mm:ss" : "MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }

    func dailyBoardNarrativeThroughputMetadataText(
        _ date: Date,
        tokens: Int,
        isToday: Bool,
        timeZone: TimeZone = .autoupdatingCurrent)
        -> String
    {
        let timestamp = self.dailyBoardNarrativeTimestampText(date, isToday: isToday, timeZone: timeZone)
        switch self.resolvedLanguage {
        case .zhHans, .system:
            return "\(timestamp) · \(self.exactNumberText(tokens)) tokens"
        case .en:
            return "\(timestamp) · Throughput \(self.exactNumberText(tokens)) tokens"
        case .ja:
            return "\(timestamp) · スループット \(self.exactNumberText(tokens)) tokens"
        }
    }

    func dailyBoardNarrativeInstructionMetadataText(
        _ date: Date,
        ordinal: Int,
        isToday: Bool,
        timeZone: TimeZone = .autoupdatingCurrent)
        -> String
    {
        let timestamp = self.dailyBoardNarrativeTimestampText(date, isToday: isToday, timeZone: timeZone)
        switch self.resolvedLanguage {
        case .zhHans, .system:
            if isToday {
                return "\(timestamp) · 今天第 \(self.exactNumberText(ordinal)) 次发送"
            }
            return "\(timestamp) · 第 \(self.exactNumberText(ordinal)) 次发送"
        case .en:
            if isToday {
                return "\(timestamp) · Today's send #\(self.exactNumberText(ordinal))"
            }
            return "\(timestamp) · Send #\(self.exactNumberText(ordinal))"
        case .ja:
            if isToday {
                return "\(timestamp) · 今日の \(self.exactNumberText(ordinal)) 回目の送信"
            }
            return "\(timestamp) · \(self.exactNumberText(ordinal)) 回目の送信"
        }
    }

    func text(zh: String, en: String, ja: String) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            zh
        case .en:
            en
        case .ja:
            ja
        case .system:
            zh
        }
    }

    private func activityPeriodText(forHour hour: Int) -> String {
        switch self.resolvedLanguage {
        case .zhHans, .system:
            switch hour {
            case 0..<6:
                "凌晨"
            case 6..<12:
                "上午"
            case 12..<18:
                "午后"
            default:
                "晚间"
            }
        case .en:
            switch hour {
            case 0..<6:
                "late night"
            case 6..<12:
                "morning"
            case 12..<18:
                "afternoon"
            default:
                "evening"
            }
        case .ja:
            switch hour {
            case 0..<6:
                "深夜帯"
            case 6..<12:
                "午前"
            case 12..<18:
                "午後"
            default:
                "夜"
            }
        }
    }

    func compactTokenText(_ value: Int) -> String {
        switch self.resolvedLanguage {
        case .zhHans:
            if value >= 100_000_000 {
                return self.localizedCompactNumber(value: value, divisor: 100_000_000, unit: "亿", spacedUnit: true)
            }
            if value >= 10000 {
                return self.localizedCompactNumber(value: value, divisor: 10000, unit: "万", spacedUnit: true)
            }
        case .ja:
            if value >= 100_000_000 {
                return self.localizedCompactNumber(value: value, divisor: 100_000_000, unit: "億", spacedUnit: true)
            }
            if value >= 10000 {
                return self.localizedCompactNumber(value: value, divisor: 10000, unit: "万", spacedUnit: true)
            }
        case .en:
            if value >= 1_000_000_000 {
                return self.localizedCompactNumber(value: value, divisor: 1_000_000_000, unit: "B", spacedUnit: false)
            }
            if value >= 1_000_000 {
                return self.localizedCompactNumber(value: value, divisor: 1_000_000, unit: "M", spacedUnit: false)
            }
            if value >= 1000 {
                return self.localizedCompactNumber(value: value, divisor: 1000, unit: "K", spacedUnit: false)
            }
        case .system:
            break
        }

        return self.exactNumberText(value)
    }

    func narrativeCompactTokenText(_ value: Int) -> String {
        "\(self.compactTokenText(value)) Tokens"
    }

    func narrativeExactTokenText(_ value: Int) -> String {
        "\(self.exactNumberText(value)) Tokens"
    }

    private func localizedCompactNumber(value: Int, divisor: Double, unit: String, spacedUnit: Bool) -> String {
        let formatter = NumberFormatter()
        formatter.locale = self.locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1

        let scaledValue = Double(value) / divisor
        let magnitude = formatter.string(from: NSNumber(value: scaledValue))
            ?? String(format: "%.1f", scaledValue)
        let spacer = spacedUnit ? " " : ""
        return "\(magnitude)\(spacer)\(unit)"
    }

    func exactNumberText(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = self.locale
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
