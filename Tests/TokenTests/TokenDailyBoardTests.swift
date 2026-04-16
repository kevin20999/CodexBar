import CodexBarCore
import Foundation
import XCTest
@testable import CodexDailyKit

final class TokenDailyBoardTests: XCTestCase {
    func test_modelBuilderProducesCurrentMonthDaysInDescendingOrder() throws {
        let calendar = self.calendar()
        let referenceDate = try self.date(year: 2026, month: 4, day: 7, hour: 15, minute: 30, calendar: calendar)
        let todayStart = calendar.startOfDay(for: referenceDate)
        let yesterdayStart = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: todayStart))
        let todayBucketStart = try self.bucketStart(dayStart: todayStart, hour: 3, minute: 10, calendar: calendar)
        let yesterdayBucketStart = try self.bucketStart(
            dayStart: yesterdayStart,
            hour: 18,
            minute: 20,
            calendar: calendar)

        let model = TokenDailyBoardModelBuilder.makeModel(
            tokenDays: [
                DailyTokenStats(
                    date: DailyTokenStats.dayKey(for: todayStart, calendar: calendar),
                    inputTokens: 120,
                    outputTokens: 80,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 200),
            ],
            regularTokenDays: [],
            fiveMinuteBuckets: [
                FiveMinuteTokenStats(
                    bucketStart: todayBucketStart,
                    inputTokens: 0,
                    outputTokens: 0,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 12),
                FiveMinuteTokenStats(
                    bucketStart: yesterdayBucketStart,
                    inputTokens: 0,
                    outputTokens: 0,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 9),
            ],
            outboundMessageDays: [],
            selectedYear: 2026,
            selectedMonth: 4,
            referenceDate: referenceDate,
            calendar: calendar)

        XCTAssertEqual(model.days.count, 7)
        XCTAssertEqual(model.selectedYear, 2026)
        XCTAssertEqual(model.selectedMonth, 4)
        XCTAssertEqual(model.days.first?.dayKey, "2026-04-07")
        XCTAssertEqual(model.days.last?.dayKey, "2026-04-01")
        XCTAssertEqual(model.days.first?.relativeDayOffset, 0)
        XCTAssertEqual(model.days.dropFirst().first?.relativeDayOffset, 1)
        XCTAssertEqual(model.days.last?.relativeDayOffset, 6)
        XCTAssertTrue(model.days.allSatisfy { $0.fiveMinutePoints.count == 24 * 12 })
        XCTAssertEqual(model.days.first?.fiveMinutePoints.first?.bucketIndex, 0)
        XCTAssertEqual(model.days.first?.fiveMinutePoints.last?.bucketIndex, (24 * 12) - 1)
    }

    func test_modelBuilderBuildsFullHistoricalMonthWhenMonthHasData() throws {
        let calendar = self.calendar()
        let referenceDate = try self.date(year: 2026, month: 4, day: 7, hour: 10, minute: 0, calendar: calendar)
        let historicalDay = try self.date(year: 2026, month: 2, day: 10, hour: 12, minute: 0, calendar: calendar)

        let model = TokenDailyBoardModelBuilder.makeModel(
            tokenDays: [
                DailyTokenStats(
                    date: DailyTokenStats.dayKey(for: historicalDay, calendar: calendar),
                    inputTokens: 50,
                    outputTokens: 50,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 100),
            ],
            regularTokenDays: [],
            fiveMinuteBuckets: [],
            outboundMessageDays: [],
            selectedYear: 2026,
            selectedMonth: 2,
            referenceDate: referenceDate,
            calendar: calendar)

        XCTAssertEqual(model.days.count, 28)
        XCTAssertEqual(model.days.first?.dayKey, "2026-02-28")
        XCTAssertEqual(model.days.last?.dayKey, "2026-02-01")
        XCTAssertEqual(model.availableMonthsWithData, Set([2]))
    }

    func test_modelBuilderUsesPerDayTotalsAndShowsRocketOnlyForActualToday() throws {
        let calendar = self.calendar()
        let referenceDate = try self.date(year: 2026, month: 4, day: 7, hour: 10, minute: 0, calendar: calendar)
        let todayStart = calendar.startOfDay(for: referenceDate)
        let yesterdayStart = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: todayStart))
        let todayEarlyBucket = try self.bucketStart(dayStart: todayStart, hour: 5, minute: 0, calendar: calendar)
        let todayLateBucket = try self.bucketStart(dayStart: todayStart, hour: 21, minute: 15, calendar: calendar)
        let yesterdayBucket = try self.bucketStart(dayStart: yesterdayStart, hour: 23, minute: 55, calendar: calendar)

        let model = TokenDailyBoardModelBuilder.makeModel(
            tokenDays: [
                DailyTokenStats(
                    date: DailyTokenStats.dayKey(for: todayStart, calendar: calendar),
                    inputTokens: 3200,
                    outputTokens: 1800,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 5000),
                DailyTokenStats(
                    date: DailyTokenStats.dayKey(for: yesterdayStart, calendar: calendar),
                    inputTokens: 750,
                    outputTokens: 250,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 1000),
            ],
            regularTokenDays: [
                DailyTokenStats(
                    date: DailyTokenStats.dayKey(for: todayStart, calendar: calendar),
                    inputTokens: 1200,
                    outputTokens: 600,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 1800),
                DailyTokenStats(
                    date: DailyTokenStats.dayKey(for: yesterdayStart, calendar: calendar),
                    inputTokens: 500,
                    outputTokens: 100,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 600),
            ],
            fiveMinuteBuckets: [
                FiveMinuteTokenStats(
                    bucketStart: todayEarlyBucket,
                    inputTokens: 0,
                    outputTokens: 0,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 50),
                FiveMinuteTokenStats(
                    bucketStart: todayLateBucket,
                    inputTokens: 0,
                    outputTokens: 0,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 400),
                FiveMinuteTokenStats(
                    bucketStart: yesterdayBucket,
                    inputTokens: 0,
                    outputTokens: 0,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 300),
            ],
            outboundMessageDays: [
                DailyOutboundMessageStats(
                    date: DailyTokenStats.dayKey(for: todayStart, calendar: calendar),
                    sentCharacters: 0,
                    sentMessages: 8),
                DailyOutboundMessageStats(
                    date: DailyTokenStats.dayKey(for: yesterdayStart, calendar: calendar),
                    sentCharacters: 0,
                    sentMessages: 3),
            ],
            selectedYear: 2026,
            selectedMonth: 4,
            referenceDate: referenceDate,
            calendar: calendar)

        let today = try XCTUnwrap(model.days.first)
        let yesterday = try XCTUnwrap(model.days.dropFirst().first)

        XCTAssertEqual(today.totalTokens, 5000)
        XCTAssertEqual(today.mainThreadTokens, 1800)
        XCTAssertEqual(today.instructionCount, 8)
        XCTAssertEqual(today.rocketBucketIndex, (21 * 12) + 3)

        XCTAssertEqual(yesterday.totalTokens, 1000)
        XCTAssertEqual(yesterday.mainThreadTokens, 600)
        XCTAssertEqual(yesterday.instructionCount, 3)
        XCTAssertNil(yesterday.rocketBucketIndex)
        XCTAssertGreaterThan(model.scaleTopValue, 1)
    }

    func test_modelBuilderReturnsEmptyMonthButPreservesMonthAvailability() throws {
        let calendar = self.calendar()
        let referenceDate = try self.date(year: 2026, month: 4, day: 7, hour: 8, minute: 0, calendar: calendar)
        let aprilDay = try self.date(year: 2026, month: 4, day: 7, hour: 8, minute: 0, calendar: calendar)

        let model = TokenDailyBoardModelBuilder.makeModel(
            tokenDays: [
                DailyTokenStats(
                    date: DailyTokenStats.dayKey(for: aprilDay, calendar: calendar),
                    inputTokens: 40,
                    outputTokens: 60,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 100),
            ],
            regularTokenDays: [],
            fiveMinuteBuckets: [],
            outboundMessageDays: [],
            selectedYear: 2026,
            selectedMonth: 3,
            referenceDate: referenceDate,
            calendar: calendar)

        XCTAssertTrue(model.days.isEmpty)
        XCTAssertEqual(model.selectedMonth, 3)
        XCTAssertEqual(model.availableYears, [2026])
        XCTAssertEqual(model.availableMonthsWithData, Set([4]))
        XCTAssertFalse(model.hasDataInSelectedMonth)
    }

    private func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh-Hans")
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        return calendar
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        calendar: Calendar)
        throws
        -> Date
    {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return try XCTUnwrap(calendar.date(from: components))
    }

    private func bucketStart(
        dayStart: Date,
        hour: Int,
        minute: Int,
        calendar: Calendar)
        throws
        -> Date
    {
        let hourStart = try XCTUnwrap(calendar.date(byAdding: .hour, value: hour, to: dayStart))
        let date = try XCTUnwrap(calendar.date(byAdding: .minute, value: minute, to: hourStart))
        return FiveMinuteTokenStats.bucketStart(for: date, calendar: calendar)
    }
}
