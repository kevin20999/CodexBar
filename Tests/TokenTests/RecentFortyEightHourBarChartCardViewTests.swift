import CodexBarCore
import Foundation
import XCTest
@testable import CodexBar

final class RecentFortyEightHourBarChartCardViewTests: XCTestCase {
    func test_makeModelPadsShortWindowToFortyEightHours() throws {
        let baseHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 24,
            hour: 8)))
        let hours = try [
            XCTUnwrap(Self.hourlyStats(baseHour: baseHour, offset: 0, totalTokens: 18)),
            XCTUnwrap(Self.hourlyStats(baseHour: baseHour, offset: 1, totalTokens: 42)),
        ]

        let model = RecentFortyEightHourBarChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertEqual(model.points.count, RecentFortyEightHourBarChartModelBuilder.displayedHourCount)
        XCTAssertEqual(model.points.first?.slotIndex, 0)
        XCTAssertEqual(model.points.last?.slotIndex, 47)
        XCTAssertEqual(model.points.last?.totalTokens, 42)
    }

    func test_makeModelCompressesInternalZeroRunAndKeepsCompressedLabel() throws {
        let latestHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 21,
            hour: 23)))
        var values = Array(repeating: 5, count: 48)
        values.replaceSubrange(24..<30, with: Array(repeating: 0, count: 6))
        let hours = try self.hourlyWindow(endingAt: latestHour, values: values)

        let model = RecentFortyEightHourBarChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertEqual(model.points.count, 43)
        XCTAssertEqual(model.latestPoint?.slotIndex, 42)
        XCTAssertEqual(model.latestPoint?.slotValue, 43)

        let compressedPoint = try XCTUnwrap(model.points.first(where: \.isCompressedRange))
        XCTAssertEqual(compressedPoint.slotIndex, 24)
        XCTAssertEqual(compressedPoint.slotValue, 24.5)
        XCTAssertEqual(compressedPoint.totalTokens, 0)
        XCTAssertTrue(model.xAxisTickValues.contains(24.5))
        XCTAssertTrue(model.axisMarkers.contains(where: {
            $0.text == "23～6"
                && $0.priority == .compressed
                && $0.slotValue == 24.5
        }))
    }

    func test_makeModelPrefersLatestHourWhenPeakValuesTie() throws {
        let baseHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 24,
            hour: 10)))
        let hours = try [
            XCTUnwrap(Self.hourlyStats(baseHour: baseHour, offset: 0, totalTokens: 12)),
            XCTUnwrap(Self.hourlyStats(baseHour: baseHour, offset: 1, totalTokens: 87)),
            XCTUnwrap(Self.hourlyStats(baseHour: baseHour, offset: 2, totalTokens: 87)),
        ]

        let model = RecentFortyEightHourBarChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertEqual(model.peakPoint?.slotIndex, 47)
        XCTAssertEqual(model.totalTokens, 186)
    }

    func test_makeModelKeepsBoundaryAndIntermediateHourMarkers() throws {
        let latestHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 24,
            hour: 21)))
        let hours = try self.hourlyWindow(endingAt: latestHour)

        let model = RecentFortyEightHourBarChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertEqual(model.axisMarkers.first?.text, "22")
        XCTAssertEqual(model.axisMarkers.last?.text, "21")
        XCTAssertTrue(model.xAxisTickValues.contains(0))
        XCTAssertTrue(model.xAxisTickValues.contains(model.xDomainUpperBound))
    }

    func test_axisStripMarkerBuilderKeepsMarkersInsideNormalizedBounds() {
        let markers = RecentFortyEightHourBarChartAxisStripMarkerBuilder.makeMarkers(
            from: [
                RecentTwentyFourHourChartAxisMarker(slotValue: 0, text: "22", priority: .boundary),
                RecentTwentyFourHourChartAxisMarker(slotValue: 24.5, text: "22～8", priority: .compressed),
                RecentTwentyFourHourChartAxisMarker(slotValue: 43, text: "14", priority: .boundary),
            ],
            xDomainUpperBound: 43)

        XCTAssertEqual(markers.count, 3)
        XCTAssertEqual(markers.first?.priority, .boundary)
        XCTAssertEqual(markers[1].priority, .compressed)
        XCTAssertEqual(markers.last?.priority, .boundary)
        XCTAssertTrue(markers.allSatisfy { $0.normalizedX >= 0 && $0.normalizedX <= 1 })
        XCTAssertLessThan(markers.first?.normalizedX ?? 1, markers[1].normalizedX)
        XCTAssertLessThan(markers[1].normalizedX, markers.last?.normalizedX ?? 0)
    }

    private static func hourlyStats(baseHour: Date, offset: Int, totalTokens: Int) -> HourlyTokenStats? {
        guard let hourStart = self.utcCalendar.date(byAdding: .hour, value: offset, to: baseHour) else {
            return nil
        }
        return HourlyTokenStats(
            hourStart: hourStart,
            inputTokens: totalTokens,
            outputTokens: 0,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: totalTokens)
    }

    private func hourlyWindow(endingAt latestHour: Date, values: [Int]? = nil) throws -> [HourlyTokenStats] {
        if let values {
            XCTAssertEqual(values.count, RecentFortyEightHourBarChartModelBuilder.displayedHourCount)
        }

        let baseHour = try XCTUnwrap(
            Self.utcCalendar.date(
                byAdding: .hour,
                value: -(RecentFortyEightHourBarChartModelBuilder.displayedHourCount - 1),
                to: latestHour))

        return (0..<RecentFortyEightHourBarChartModelBuilder.displayedHourCount).compactMap { offset in
            let totalTokens = values?[offset] ?? (offset + 1)
            return Self.hourlyStats(baseHour: baseHour, offset: offset, totalTokens: totalTokens)
        }
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()
}
