import XCTest
@testable import CodexBar

final class ThirtyDayChartScaleResolverTests: XCTestCase {
    func test_topValueReturnsMinimumWhenPeakIsZero() {
        XCTAssertEqual(ThirtyDayChartScaleResolver.topValue(forPeakValue: 0), 2)
    }

    func test_topValueReturnsMinimumWhenPeakIsVerySmall() {
        XCTAssertEqual(ThirtyDayChartScaleResolver.topValue(forPeakValue: 1), 2)
    }

    func test_topValueTargetsVisualPeakHeightInsteadOfRoundedCeiling() {
        let topValue = ThirtyDayChartScaleResolver.topValue(forPeakValue: 290_000_000)

        XCTAssertLessThan(topValue, 400_000_000)
        XCTAssertEqual(
            Double(290_000_000) / topValue,
            ThirtyDayChartScaleResolver.targetPeakHeightRatio,
            accuracy: 0.000001)
        XCTAssertEqual(ThirtyDayChartScaleResolver.targetPeakHeightRatio, 0.96, accuracy: 0.000001)
    }
}
