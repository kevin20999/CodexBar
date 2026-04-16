import CodexBarCore
import XCTest
@testable import CodexBar

final class ThirtyDayChartPeakResolverTests: XCTestCase {
    func test_peakDayIDUsesHighestTotalTokens() {
        let days = [
            self.day("2026-03-16", totalTokens: 120_000_000),
            self.day("2026-03-17", totalTokens: 310_000_000),
            self.day("2026-03-18", totalTokens: 260_000_000),
        ]

        XCTAssertEqual(ThirtyDayChartPeakResolver.peakDayID(from: days), "2026-03-17")
    }

    func test_peakDayIDPrefersLatestDateWhenTotalsTie() {
        let days = [
            self.day("2026-03-16", totalTokens: 310_000_000),
            self.day("2026-03-17", totalTokens: 120_000_000),
            self.day("2026-03-18", totalTokens: 310_000_000),
        ]

        XCTAssertEqual(ThirtyDayChartPeakResolver.peakDayID(from: days), "2026-03-18")
    }

    func test_peakDayIDReturnsNilWhenAllTotalsAreZero() {
        let days = [
            self.day("2026-03-16", totalTokens: 0),
            self.day("2026-03-17", totalTokens: 0),
            self.day("2026-03-18", totalTokens: 0),
        ]

        XCTAssertNil(ThirtyDayChartPeakResolver.peakDayID(from: days))
    }

    private func day(_ date: String, totalTokens: Int) -> DailyTokenStats {
        DailyTokenStats(
            date: date,
            inputTokens: 0,
            outputTokens: 0,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: totalTokens)
    }
}
