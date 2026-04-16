import CodexBarCore
import Foundation
import XCTest
@testable import CodexBar

final class MessageActivityCardViewTests: XCTestCase {
    func test_makeModelPadsShortWindowToThirtyDays() throws {
        let calendar = Self.utcCalendar
        let today = try XCTUnwrap(calendar.date(from: DateComponents(
            calendar: calendar,
            year: 2026,
            month: 3,
            day: 24)))
        let todayKey = DailyTokenStats.dayKey(for: today, calendar: calendar)
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))
        let yesterdayKey = DailyTokenStats.dayKey(for: yesterday, calendar: calendar)

        let model = MessageActivityCardModelBuilder.makeModel(
            days: [
                DailyOutboundMessageStats(date: yesterdayKey, sentCharacters: 42, sentMessages: 2),
                DailyOutboundMessageStats(date: todayKey, sentCharacters: 80, sentMessages: 3),
            ],
            todayTotal: DailyOutboundMessageStats(date: todayKey, sentCharacters: 80, sentMessages: 3),
            sevenDayTotal: DailyOutboundMessageStats(date: "7d", sentCharacters: 122, sentMessages: 5),
            thirtyDayTotal: DailyOutboundMessageStats(date: "30d", sentCharacters: 122, sentMessages: 5),
            cumulativeTotal: DailyOutboundMessageStats(date: "total", sentCharacters: 122, sentMessages: 5),
            referenceDate: today,
            calendar: calendar)

        XCTAssertEqual(model.points.count, MessageActivityCardModelBuilder.displayedDayCount)
        XCTAssertEqual(model.points.last?.stats.sentCharacters, 80)
        XCTAssertEqual(model.axisDates.count, 5)
        XCTAssertEqual(model.axisMarkers.count, 5)
        XCTAssertEqual(model.axisDates.first, model.points.first?.date)
        XCTAssertEqual(model.axisDates.last, model.points.last?.date)
        XCTAssertEqual(model.axisMarkers.first?.normalizedX, 0, accuracy: 0.0001)
        XCTAssertEqual(model.axisMarkers.last?.normalizedX, 1, accuracy: 0.0001)
        XCTAssertEqual(model.peakPointID, model.points.last?.id)
        XCTAssertEqual(model.cumulativeTotal.sentCharacters, 122)
        XCTAssertEqual(model.todayTotal.sentMessages, 3)
        XCTAssertEqual(model.sevenDayTotal.sentMessages, 5)
    }

    func test_makeModelUsesEmptyDaysWhenNoActivityExists() {
        let model = MessageActivityCardModelBuilder.makeModel(
            days: [],
            todayTotal: DailyOutboundMessageStats(date: "today", sentCharacters: 0, sentMessages: 0),
            sevenDayTotal: DailyOutboundMessageStats(date: "7d", sentCharacters: 0, sentMessages: 0),
            thirtyDayTotal: DailyOutboundMessageStats(date: "30d", sentCharacters: 0, sentMessages: 0),
            cumulativeTotal: DailyOutboundMessageStats(date: "total", sentCharacters: 0, sentMessages: 0),
            referenceDate: Date(timeIntervalSince1970: 0),
            calendar: Self.utcCalendar)

        XCTAssertEqual(model.points.count, MessageActivityCardModelBuilder.displayedDayCount)
        XCTAssertFalse(model.hasData)
        XCTAssertEqual(model.scale.topValue, 2)
        XCTAssertNil(model.peakPointID)
    }

    func test_makeModelChoosesLatestPeakWhenInstructionCountsTie() throws {
        let calendar = Self.utcCalendar
        let today = try XCTUnwrap(calendar.date(from: DateComponents(
            calendar: calendar,
            year: 2026,
            month: 3,
            day: 24)))
        let earlierPeak = try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: today))
        let laterPeak = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))

        let model = MessageActivityCardModelBuilder.makeModel(
            days: [
                DailyOutboundMessageStats(
                    date: DailyTokenStats.dayKey(for: earlierPeak, calendar: calendar),
                    sentCharacters: 120,
                    sentMessages: 2),
                DailyOutboundMessageStats(
                    date: DailyTokenStats.dayKey(for: laterPeak, calendar: calendar),
                    sentCharacters: 30,
                    sentMessages: 2),
            ],
            todayTotal: DailyOutboundMessageStats(date: "today", sentCharacters: 0, sentMessages: 0),
            sevenDayTotal: DailyOutboundMessageStats(date: "7d", sentCharacters: 150, sentMessages: 4),
            thirtyDayTotal: DailyOutboundMessageStats(date: "30d", sentCharacters: 150, sentMessages: 4),
            cumulativeTotal: DailyOutboundMessageStats(date: "total", sentCharacters: 150, sentMessages: 4),
            referenceDate: today,
            calendar: calendar)

        XCTAssertEqual(model.peakPointID, DailyTokenStats.dayKey(for: laterPeak, calendar: calendar))
    }

    func test_sharedThirtyDayBarStyleMatchesDashboardModuleWidth() {
        XCTAssertEqual(DashboardThirtyDayBarStyle.barWidth, 11)
        XCTAssertEqual(DashboardThirtyDayBarStyle.barCornerRadius, 4.5)
    }

    func test_summaryLayoutUsesStackedMetricColumns() {
        XCTAssertFalse(MessageActivityCardLayoutMetrics.usesInsetSummaryBackground)
        XCTAssertFalse(MessageActivityCardLayoutMetrics.showsChartSubtitle)
        XCTAssertTrue(MessageActivityCardLayoutMetrics.usesStackedSummaryColumns)
        XCTAssertEqual(MessageActivityCardLayoutMetrics.summaryColumnCount, 4)
        XCTAssertEqual(MessageActivityCardLayoutMetrics.summaryRowCount, 1)
        XCTAssertEqual(MessageActivityCardLayoutMetrics.metricValueFontSize, 21)
        XCTAssertGreaterThan(
            MessageActivityCardLayoutMetrics.metricValueFontSize,
            MessageActivityCardLayoutMetrics.metricLabelFontSize)
        XCTAssertEqual(MessageActivityCardLayoutMetrics.miniChartSpacing, 0)
        XCTAssertEqual(MessageActivityCardLayoutMetrics.miniChartHeight, 78)
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()
}
