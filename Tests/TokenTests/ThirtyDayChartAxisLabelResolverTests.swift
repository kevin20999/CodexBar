import AppKit
import CoreGraphics
import XCTest
@testable import CodexBar

final class ThirtyDayChartAxisLabelResolverTests: XCTestCase {
    func test_resolvePlacementsPinsFirstAndLastLabelsToPlotEdges() {
        let placements = ThirtyDayChartAxisLabelResolver.resolvePlacements(
            labels: [
                .init(id: "first", text: "2/19", centerX: 52, width: 32),
                .init(id: "middle", text: "2/27", centerX: 166, width: 36),
                .init(id: "last", text: "3/15", centerX: 286, width: 34),
            ],
            plotFrame: CGRect(x: 40, y: 10, width: 260, height: 80),
            rowCenterY: 108)

        XCTAssertEqual(placements.map(\.alignment), [.leading, .center, .trailing])
        XCTAssertEqual(placements[0].centerX, 56, accuracy: 0.001)
        XCTAssertEqual(placements[1].centerX, 166, accuracy: 0.001)
        XCTAssertEqual(placements[2].centerX, 283, accuracy: 0.001)
        XCTAssertEqual(placements[0].centerY, 108, accuracy: 0.001)
    }

    func test_resolvePlacementsClampsOversizedMiddleLabelIntoPlotBounds() {
        let placements = ThirtyDayChartAxisLabelResolver.resolvePlacements(
            labels: [
                .init(id: "first", text: "2/19", centerX: 52, width: 32),
                .init(id: "middle", text: "super-wide", centerX: 286, width: 60),
                .init(id: "last", text: "3/15", centerX: 294, width: 34),
            ],
            plotFrame: CGRect(x: 40, y: 10, width: 260, height: 80),
            rowCenterY: 108)

        XCTAssertEqual(placements[1].alignment, .center)
        XCTAssertEqual(placements[1].centerX, 270, accuracy: 0.001)
        XCTAssertLessThanOrEqual(placements[1].centerX + (placements[1].width / 2), 300.001)
    }

    func test_sharedOverlayMetricHelpersUseDashboardStyleConstants() {
        let peakWidth = dashboardThirtyDayPeakLabelWidth(for: "12 次")
        XCTAssertGreaterThanOrEqual(peakWidth, DashboardThirtyDayBarStyle.peakLabelMinWidth)
        XCTAssertLessThanOrEqual(peakWidth, DashboardThirtyDayBarStyle.peakLabelMaxWidth)

        let axisText = "3/21"
        let expectedAxisWidth = dashboardChartTextWidth(
            axisText,
            font: .systemFont(ofSize: DashboardThirtyDayBarStyle.axisLabelFontSize, weight: .medium))
            + (DashboardThirtyDayBarStyle.axisLabelHorizontalPadding * 2)

        XCTAssertEqual(dashboardThirtyDayAxisLabelWidth(for: axisText), expectedAxisWidth, accuracy: 0.001)
    }
}
