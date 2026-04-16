import CodexBarCore
import Foundation
import XCTest
@testable import CodexBar

final class RecentTwentyFourHourChartCardViewTests: XCTestCase {
    func test_makeModelUsesSequentialSlotsForFullWindow() throws {
        let latestHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 20,
            hour: 21)))
        let hours = try self.hourlyWindow(endingAt: latestHour)

        let model = RecentTwentyFourHourChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertEqual(model.points.count, RecentTwentyFourHourChartModelBuilder.displayedHourCount)
        XCTAssertEqual(
            model.points.map(\.slotIndex),
            Array(0..<RecentTwentyFourHourChartModelBuilder.displayedHourCount))
        XCTAssertEqual(
            model.points.map(\.slotValue),
            Array(0..<RecentTwentyFourHourChartModelBuilder.displayedHourCount).map(Double.init))
        XCTAssertEqual(
            model.points.first?.hourStart,
            Self.utcCalendar.date(byAdding: .hour, value: -47, to: latestHour))
        XCTAssertEqual(model.points.last?.hourStart, latestHour)
    }

    func test_makeModelPadsShortWindowToFullFortyEightHours() throws {
        let baseHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 20,
            hour: 8)))
        let hours = try [
            XCTUnwrap(Self.hourlyStats(baseHour: baseHour, offset: 0, totalTokens: 18)),
            XCTUnwrap(Self.hourlyStats(baseHour: baseHour, offset: 1, totalTokens: 42)),
        ]

        let model = RecentTwentyFourHourChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertEqual(model.points.count, 48)
        XCTAssertEqual(model.points.map(\.slotIndex), Array(0..<48))
        XCTAssertEqual(model.latestPoint?.slotIndex, 47)
        XCTAssertEqual(model.latestPoint?.slotValue, 47)
        XCTAssertEqual(model.latestPoint?.totalTokens, 42)
    }

    func test_makeModelUsesRealHourAxisMarkersEndingAtLatestHour() throws {
        let latestHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 20,
            hour: 21)))
        let hours = try self.hourlyWindow(endingAt: latestHour)

        let model = RecentTwentyFourHourChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertEqual(model.axisMarkers.count, 48)
        XCTAssertEqual(model.axisMarkers.prefix(3).map(\.text), ["22", "23", "0"])
        XCTAssertEqual(model.axisMarkers.suffix(3).map(\.text), ["19", "20", "21"])
    }

    func test_makeModelWrapsHourAxisMarkersAcrossMidnight() throws {
        let latestHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 20,
            hour: 2)))
        let hours = try self.hourlyWindow(endingAt: latestHour)

        let model = RecentTwentyFourHourChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertEqual(model.axisMarkers.suffix(4).map(\.text), ["23", "0", "1", "2"])
    }

    func test_makeModelCompressesInternalZeroRunOfAtLeastFourHours() throws {
        let latestHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 21,
            hour: 23)))
        var values = Array(repeating: 5, count: 48)
        values.replaceSubrange(24..<30, with: Array(repeating: 0, count: 6))
        let hours = try self.hourlyWindow(endingAt: latestHour, values: values)

        let model = RecentTwentyFourHourChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertEqual(model.points.count, 43)
        XCTAssertEqual(model.latestPoint?.slotIndex, 42)
        XCTAssertEqual(model.latestPoint?.slotValue, 43)

        let compressedPoint = try XCTUnwrap(model.points.first(where: \.isCompressedRange))
        let expectedLabelStart = Self.utcCalendar.date(byAdding: .hour, value: -24, to: latestHour)
        let expectedLabelEnd = Self.utcCalendar.date(byAdding: .hour, value: -17, to: latestHour)

        XCTAssertEqual(compressedPoint.slotIndex, 24)
        XCTAssertEqual(compressedPoint.slotValue, 24.5)
        XCTAssertEqual(compressedPoint.labelStartHour, expectedLabelStart)
        XCTAssertEqual(compressedPoint.labelEndHour, expectedLabelEnd)
        XCTAssertEqual(model.xDomainUpperBound, 43)
        XCTAssertTrue(model.xAxisTickValues.contains(24.5))
        XCTAssertTrue(model.axisMarkers.contains(where: {
            $0.text == "23～6"
                && $0.priority == .compressed
                && $0.slotValue == 24.5
        }))
    }

    func test_makeModelDoesNotCompressZeroRunAtWindowBoundary() throws {
        let latestHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 21,
            hour: 23)))
        var values = Array(repeating: 5, count: 48)
        values.replaceSubrange(0..<6, with: Array(repeating: 0, count: 6))
        let hours = try self.hourlyWindow(endingAt: latestHour, values: values)

        let model = RecentTwentyFourHourChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertEqual(model.points.count, 48)
        XCTAssertFalse(model.axisMarkers.contains(where: { $0.text == "23～6" }))
    }

    func test_makeModelBuildsCompressedAxisLabelAcrossMidnight() throws {
        let latestHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 20,
            hour: 4)))
        var values = Array(repeating: 3, count: 48)
        values.replaceSubrange(18..<22, with: Array(repeating: 0, count: 4))
        let hours = try self.hourlyWindow(endingAt: latestHour, values: values)

        let model = RecentTwentyFourHourChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertTrue(model.axisMarkers.contains(where: { $0.text == "22～3" }))
    }

    func test_makeModelBuildsLongCompressedAxisLabelUsingVisibleBoundaryHours() throws {
        let latestHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 20,
            hour: 21)))
        var values = Array(repeating: 3, count: 48)
        values.replaceSubrange(25..<34, with: Array(repeating: 0, count: 9))
        let hours = try self.hourlyWindow(endingAt: latestHour, values: values)

        let model = RecentTwentyFourHourChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertTrue(model.axisMarkers.contains(where: { $0.text == "22～8" }))
    }

    func test_makeModelPrefersLatestHourWhenPeakValuesTie() throws {
        let baseHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 20,
            hour: 10)))
        let hours = try [
            XCTUnwrap(Self.hourlyStats(baseHour: baseHour, offset: 0, totalTokens: 12)),
            XCTUnwrap(Self.hourlyStats(baseHour: baseHour, offset: 1, totalTokens: 87)),
            XCTUnwrap(Self.hourlyStats(baseHour: baseHour, offset: 2, totalTokens: 87)),
        ]

        let model = RecentTwentyFourHourChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertEqual(model.peakPoint?.slotIndex, 47)
        XCTAssertEqual(model.latestPoint?.slotIndex, 47)
        XCTAssertEqual(model.totalTokens, 186)
        XCTAssertFalse(model.showsSeparatePeakPoint)
    }

    func test_makeModelShowsSeparatePeakPointWhenPeakAndLatestDiffer() throws {
        let baseHour = try XCTUnwrap(Self.utcCalendar.date(from: DateComponents(
            calendar: Self.utcCalendar,
            year: 2026,
            month: 3,
            day: 20,
            hour: 10)))
        let hours = try [
            XCTUnwrap(Self.hourlyStats(baseHour: baseHour, offset: 0, totalTokens: 12)),
            XCTUnwrap(Self.hourlyStats(baseHour: baseHour, offset: 1, totalTokens: 87)),
            XCTUnwrap(Self.hourlyStats(baseHour: baseHour, offset: 2, totalTokens: 41)),
        ]

        let model = RecentTwentyFourHourChartModelBuilder.makeModel(from: hours, calendar: Self.utcCalendar)

        XCTAssertEqual(model.peakPoint?.slotIndex, 46)
        XCTAssertEqual(model.latestPoint?.slotIndex, 47)
        XCTAssertTrue(model.showsSeparatePeakPoint)
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
            XCTAssertEqual(values.count, RecentTwentyFourHourChartModelBuilder.displayedHourCount)
        }

        let baseHour = try XCTUnwrap(
            Self.utcCalendar.date(
                byAdding: .hour,
                value: -(RecentTwentyFourHourChartModelBuilder.displayedHourCount - 1),
                to: latestHour))

        return (0..<RecentTwentyFourHourChartModelBuilder.displayedHourCount).compactMap { offset in
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
