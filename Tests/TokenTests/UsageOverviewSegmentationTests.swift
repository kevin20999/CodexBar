import CodexBarCore
import Foundation
import XCTest
@testable import CodexBar

final class UsageOverviewSegmentationTests: XCTestCase {
    func test_normalizedFractionReturnsZeroWhenTotalIsZero() {
        XCTAssertEqual(UsageOverviewSegmentation.normalizedFraction(value: 12, total: 0), 0)
        XCTAssertEqual(UsageOverviewSegmentation.normalizedFraction(value: -5, total: 10), 0)
        XCTAssertEqual(UsageOverviewSegmentation.normalizedFraction(value: 15, total: 10), 1)
    }

    func test_rollingWeekSegmentsCreatesSequentialBuckets() {
        let strings = AppStrings(language: .en)
        let calendar = self.gregorianCalendar()
        let days = (1...10).map { day in
            DailyTokenStats(
                date: String(format: "2026-03-%02d", day),
                inputTokens: day * 10,
                outputTokens: day * 5,
                cachedInputTokens: 0,
                reasoningOutputTokens: 0,
                totalTokens: day * 15)
        }

        let segments = UsageOverviewSegmentation.rollingWeekSegments(
            days: days,
            strings: strings,
            calendar: calendar)

        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments.map(\.title), ["Mar 1-7", "Mar 8-10"])
        XCTAssertEqual(segments.map(\.inputTokens), [280, 270])
        XCTAssertEqual(segments.map(\.outputTokens), [140, 135])
        self.assertFractionsEqual(segments.map(\.inputFraction), [280.0 / 550.0, 270.0 / 550.0])
        self.assertFractionsEqual(segments.map(\.outputFraction), [140.0 / 275.0, 135.0 / 275.0])
    }

    func test_monthlySegmentsAggregateNaturalMonthsInOrder() {
        let strings = AppStrings(language: .zhHans)
        let calendar = self.gregorianCalendar()
        let days = [
            DailyTokenStats(
                date: "2026-01-28",
                inputTokens: 100,
                outputTokens: 50,
                cachedInputTokens: 0,
                reasoningOutputTokens: 0,
                totalTokens: 150),
            DailyTokenStats(
                date: "2026-01-31",
                inputTokens: 200,
                outputTokens: 80,
                cachedInputTokens: 0,
                reasoningOutputTokens: 0,
                totalTokens: 280),
            DailyTokenStats(
                date: "2026-02-01",
                inputTokens: 300,
                outputTokens: 90,
                cachedInputTokens: 0,
                reasoningOutputTokens: 0,
                totalTokens: 390),
            DailyTokenStats(
                date: "2026-02-14",
                inputTokens: 400,
                outputTokens: 180,
                cachedInputTokens: 0,
                reasoningOutputTokens: 0,
                totalTokens: 580),
            DailyTokenStats(
                date: "2026-03-03",
                inputTokens: 500,
                outputTokens: 300,
                cachedInputTokens: 0,
                reasoningOutputTokens: 0,
                totalTokens: 800),
        ]

        let segments = UsageOverviewSegmentation.monthlySegments(
            days: days,
            strings: strings,
            calendar: calendar)

        XCTAssertEqual(segments.map(\.id), ["month-2026-01", "month-2026-02", "month-2026-03"])
        XCTAssertEqual(segments.map(\.title), ["2026年1月", "2026年2月", "2026年3月"])
        XCTAssertEqual(segments.map(\.inputTokens), [300, 700, 500])
        XCTAssertEqual(segments.map(\.outputTokens), [130, 270, 300])
        self.assertFractionsEqual(segments.map(\.inputFraction), [0.2, 700.0 / 1500.0, 1.0 / 3.0])
        self.assertFractionsEqual(segments.map(\.outputFraction), [130.0 / 700.0, 270.0 / 700.0, 300.0 / 700.0])
    }

    private func gregorianCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    private func assertFractionsEqual(_ actual: [Double], _ expected: [Double], accuracy: Double = 0.0001) {
        XCTAssertEqual(actual.count, expected.count)
        for (actualValue, expectedValue) in zip(actual, expected) {
            XCTAssertEqual(actualValue, expectedValue, accuracy: accuracy)
        }
    }
}
