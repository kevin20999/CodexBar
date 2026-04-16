import CodexBarCore
import XCTest
@testable import CodexBar

@MainActor
final class UsageOverviewCardViewTests: XCTestCase {
    func test_leadingSubtitleIsRemovedEvenWhenSecondaryStatsExist() {
        let row = UsageOverviewCardView.Row(
            id: "today",
            title: "今日",
            stats: DailyTokenStats(
                id: "2026-04-11",
                date: Date(timeIntervalSince1970: 0),
                inputTokens: 10,
                outputTokens: 5,
                cachedInputTokens: 0,
                reasoningOutputTokens: 0),
            secondaryStats: DailyTokenStats(
                id: "2026-04-11",
                date: Date(timeIntervalSince1970: 0),
                inputTokens: 4,
                outputTokens: 2,
                cachedInputTokens: 0,
                reasoningOutputTokens: 0),
            inputFraction: 1,
            outputFraction: 1)

        XCTAssertNil(UsageOverviewCardView.leadingSubtitle(for: row, strings: AppStrings(language: .zhHans)))
        XCTAssertNil(UsageOverviewCardView.leadingSubtitle(for: row, strings: AppStrings(language: .en)))
    }
}
