import Foundation
import XCTest
@testable import CodexDailyKit

final class TokenDailyBoardStringsTests: XCTestCase {
    func test_updatedDescriptionClampsFutureDatesToJustNow() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let futureDate = now.addingTimeInterval(9)

        XCTAssertEqual(
            TokenDailyBoardStrings(language: .zhHans).updatedDescription(from: futureDate, now: now),
            "刚刚更新")
        XCTAssertEqual(
            TokenDailyBoardStrings(language: .en).updatedDescription(from: futureDate, now: now),
            "Updated just now")
        XCTAssertEqual(
            TokenDailyBoardStrings(language: .ja).updatedDescription(from: futureDate, now: now),
            "たった今更新")
    }

    func test_updatedDescriptionUsesPastTenseForPastDates() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let date = now.addingTimeInterval(-34)

        XCTAssertEqual(
            TokenDailyBoardStrings(language: .zhHans).updatedDescription(from: date, now: now),
            "34秒前更新")
        XCTAssertEqual(
            TokenDailyBoardStrings(language: .en).updatedDescription(from: date, now: now),
            "Updated 34 sec. ago")
        XCTAssertEqual(
            TokenDailyBoardStrings(language: .ja).updatedDescription(from: date, now: now),
            "34 秒前に更新")
    }

    func test_comparisonStringsStayLocalized() {
        let zh = TokenDailyBoardStrings(language: .zhHans)
        XCTAssertEqual(zh.dailyBoardHeroSubtitle, "你的 Codex 今日轨迹")
        XCTAssertEqual(zh.dailyBoardComparisonHigher(percentage: 28), "比昨天高 28%")
        XCTAssertEqual(zh.dailyBoardComparisonLower(percentage: 12), "比昨天低 12%")
        XCTAssertEqual(zh.dailyBoardComparisonSteady, "和昨天接近")
        XCTAssertEqual(zh.dailyBoardReferenceDaysLabel, "近两天")
        XCTAssertEqual(zh.dailyBoardArchiveDaysLabel, "更早记录")
        XCTAssertEqual(zh.dailyBoardActivityClusterText(forHour: 14, isToday: true), "今天活跃集中在午后")

        let en = TokenDailyBoardStrings(language: .en)
        XCTAssertEqual(en.dailyBoardHeroSubtitle, "Your Codex activity today")
        XCTAssertEqual(en.dailyBoardComparisonHigher(percentage: 28), "28% above yesterday")
        XCTAssertEqual(en.dailyBoardComparisonLower(percentage: 12), "12% below yesterday")
        XCTAssertEqual(en.dailyBoardComparisonNewActivity, "new activity today")
        XCTAssertEqual(en.dailyBoardReferenceDaysLabel, "Recent Days")
        XCTAssertEqual(en.dailyBoardArchiveDaysLabel, "Earlier Notes")
        XCTAssertEqual(
            en.dailyBoardActivityClusterText(forHour: 21, isToday: false),
            "Activity clustered in the evening")

        let ja = TokenDailyBoardStrings(language: .ja)
        XCTAssertEqual(ja.dailyBoardHeroSubtitle, "あなたの Codex の今日の軌跡")
        XCTAssertEqual(ja.dailyBoardComparisonHigher(percentage: 28), "昨日より 28% 多い")
        XCTAssertEqual(ja.dailyBoardComparisonLower(percentage: 12), "昨日より 12% 少ない")
        XCTAssertEqual(ja.dailyBoardComparisonIdle, "今日はまだ記録なし")
        XCTAssertEqual(ja.dailyBoardReferenceDaysLabel, "直近2日")
        XCTAssertEqual(ja.dailyBoardArchiveDaysLabel, "それ以前")
        XCTAssertEqual(ja.dailyBoardActivityClusterText(forHour: 8, isToday: false), "午前に動きが集まりました")
    }

    func test_cacheMissingMessageUsesIndependentCodexDailyCopy() {
        let zh = TokenDailyBoardStrings(language: .zhHans)
        XCTAssertTrue(zh.cacheMissingMessage.contains("CodexDaily"))
        XCTAssertTrue(zh.cacheMissingMessage.contains("~/.codex/sessions"))
        XCTAssertFalse(zh.cacheMissingMessage.contains("CodexTokenBar"))
    }

    func test_usageSummaryStringsMatchMainAppDualMetricStyle() {
        let zh = TokenDailyBoardStrings(language: .zhHans)
        XCTAssertEqual(zh.dailyBoardTokenLabel, "总量")
        XCTAssertEqual(zh.dailyBoardInstructionLabel, "主线程")
        XCTAssertEqual(zh.dailyBoardTotalTokenText(160_000_000), "总量 1.6 亿")
        XCTAssertEqual(zh.dailyBoardMainThreadTokenText(160_000_000), "主线程 1.6 亿")
        XCTAssertEqual(zh.dailyBoardHumanInstructionCountText(18), "人类发送 18 次")
        XCTAssertEqual(zh.dailyBoardShortInstructionCountText(18), "18 次")

        let en = TokenDailyBoardStrings(language: .en)
        XCTAssertEqual(en.dailyBoardTokenLabel, "Total")
        XCTAssertEqual(en.dailyBoardInstructionLabel, "Main thread")
        XCTAssertEqual(en.dailyBoardTotalTokenText(160_000_000), "Total 160M")
        XCTAssertEqual(en.dailyBoardMainThreadTokenText(160_000_000), "Main thread 160M")
        XCTAssertEqual(en.dailyBoardHumanInstructionCountText(18), "Human sends 18")
        XCTAssertEqual(en.dailyBoardShortInstructionCountText(18), "18 sends")

        let ja = TokenDailyBoardStrings(language: .ja)
        XCTAssertEqual(ja.dailyBoardTokenLabel, "総消費")
        XCTAssertEqual(ja.dailyBoardInstructionLabel, "メインスレッド")
        XCTAssertEqual(ja.dailyBoardTotalTokenText(160_000_000), "総消費 1.6 億")
        XCTAssertEqual(ja.dailyBoardMainThreadTokenText(160_000_000), "メインスレッド 1.6 億")
        XCTAssertEqual(ja.dailyBoardHumanInstructionCountText(18), "人間送信 18 回")
        XCTAssertEqual(ja.dailyBoardShortInstructionCountText(18), "18 回")
    }

    func test_narrativeTimestampTextUsesSecondPrecisionForTodayAndHistoricalDays() {
        let zh = TokenDailyBoardStrings(language: .zhHans)
        let sampleDate = Date(timeIntervalSince1970: 1_776_144_399)
        let gmtPlus8 = TimeZone(secondsFromGMT: 8 * 3600) ?? .autoupdatingCurrent

        XCTAssertEqual(
            zh.dailyBoardNarrativeTimestampText(sampleDate, isToday: true, timeZone: gmtPlus8),
            "23:59:59")
        XCTAssertEqual(
            zh.dailyBoardNarrativeTimestampText(sampleDate, isToday: false, timeZone: gmtPlus8),
            "04-11 23:59:59")
    }

    func test_realtimeNarrativeMetadataStringsIncludeEventValues() {
        let sampleDate = Date(timeIntervalSince1970: 1_776_144_399)
        let gmtPlus8 = TimeZone(secondsFromGMT: 8 * 3600) ?? .autoupdatingCurrent

        XCTAssertEqual(
            TokenDailyBoardStrings(language: .zhHans).dailyBoardNarrativeThroughputMetadataText(
                sampleDate,
                tokens: 173_556,
                isToday: true,
                timeZone: gmtPlus8),
            "23:59:59 · 173,556 tokens")
        XCTAssertEqual(
            TokenDailyBoardStrings(language: .en).dailyBoardNarrativeThroughputMetadataText(
                sampleDate,
                tokens: 173_556,
                isToday: true,
                timeZone: gmtPlus8),
            "23:59:59 · Throughput 173,556 tokens")
        XCTAssertEqual(
            TokenDailyBoardStrings(language: .ja).dailyBoardNarrativeThroughputMetadataText(
                sampleDate,
                tokens: 173_556,
                isToday: true,
                timeZone: gmtPlus8),
            "23:59:59 · スループット 173,556 tokens")
        XCTAssertEqual(
            TokenDailyBoardStrings(language: .zhHans).dailyBoardNarrativeInstructionMetadataText(
                sampleDate,
                ordinal: 86,
                isToday: true,
                timeZone: gmtPlus8),
            "23:59:59 · 今天第 86 次发送")
        XCTAssertEqual(
            TokenDailyBoardStrings(language: .en).dailyBoardNarrativeInstructionMetadataText(
                sampleDate,
                ordinal: 86,
                isToday: true,
                timeZone: gmtPlus8),
            "23:59:59 · Today's send #86")
        XCTAssertEqual(
            TokenDailyBoardStrings(language: .ja).dailyBoardNarrativeInstructionMetadataText(
                sampleDate,
                ordinal: 86,
                isToday: true,
                timeZone: gmtPlus8),
            "23:59:59 · 今日の 86 回目の送信")
    }

    func test_narrativeTokenHelpersAppendTokensUnit() {
        let zh = TokenDailyBoardStrings(language: .zhHans)

        XCTAssertEqual(zh.narrativeCompactTokenText(173_556), "17.4 万 Tokens")
        XCTAssertEqual(zh.narrativeExactTokenText(173_556), "173,556 Tokens")
        XCTAssertEqual(zh.dailyBoardTotalTokenText(173_556), "总量 17.4 万")
    }
}
