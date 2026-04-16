import XCTest
@testable import CodexBar

@MainActor
final class TokenSpeedFloatingChartTests: XCTestCase {
    func test_widgetUsesSingleFixedSize() {
        XCTAssertEqual(TokenSpeedFloatingChartLayout.size, CGSize(width: 192, height: 192))
    }

    func test_defaultPlacementAnchorsNearRightSideAndClampsToScreen() {
        let frame = TokenSpeedFloatingChartPlacement.defaultFrame(
            anchorFrame: CGRect(x: 900, y: 700, width: 438, height: 404),
            panelSize: TokenSpeedFloatingChartLayout.size,
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900))

        XCTAssertEqual(frame.size.width, 192)
        XCTAssertEqual(frame.size.height, 192)
        XCTAssertEqual(frame.origin.x, 1240)
        XCTAssertEqual(frame.origin.y, 700)
    }

    func test_clampedPlacementKeepsStoredOriginInsideVisibleFrame() {
        let frame = TokenSpeedFloatingChartPlacement.clampedFrame(
            origin: CGPoint(x: 1400, y: 850),
            panelSize: TokenSpeedFloatingChartLayout.size,
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 900))

        XCTAssertEqual(frame.origin.x, 1240)
        XCTAssertEqual(frame.origin.y, 700)
    }

    func test_stateStoreRoundTripsSavedOrigin() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let store = TokenSpeedFloatingChartStateStore(defaults: defaults)

        XCTAssertNil(store.loadOrigin())

        store.saveOrigin(CGPoint(x: 321, y: 654))

        XCTAssertEqual(store.loadOrigin(), CGPoint(x: 321, y: 654))
    }

    func test_tokenFormatterUsesYiForLargeChineseValues() {
        let strings = AppStrings(language: .zhHans)

        XCTAssertEqual(
            TokenSpeedFloatingValueFormatter.tokenParts(for: 10_000_000, strings: strings),
            TokenSpeedFloatingValueParts(magnitude: "0.1", suffix: "亿"))
        XCTAssertEqual(
            TokenSpeedFloatingValueFormatter.tokenParts(for: 100_000_000, strings: strings),
            TokenSpeedFloatingValueParts(magnitude: "1", suffix: "亿"))
        XCTAssertEqual(
            TokenSpeedFloatingValueFormatter.tokenParts(for: 110_000_000, strings: strings),
            TokenSpeedFloatingValueParts(magnitude: "1.1", suffix: "亿"))
    }

    func test_instructionFormatterKeepsExactIntegerWithLocalizedSuffix() {
        let parts = TokenSpeedFloatingValueFormatter.instructionParts(
            for: 29,
            strings: AppStrings(language: .zhHans))

        XCTAssertEqual(parts, TokenSpeedFloatingValueParts(magnitude: "29", suffix: "次"))
    }

    func test_rocketAlignsToRightmostBurstSpikeInFloatingWidget() {
        let points = [
            TokenSpeedDisplayPoint(timestamp: Date(), rawTokens: 0, displayValue: 0),
            TokenSpeedDisplayPoint(timestamp: Date().addingTimeInterval(1), rawTokens: 18, displayValue: 1),
            TokenSpeedDisplayPoint(timestamp: Date().addingTimeInterval(2), rawTokens: 0, displayValue: 0),
            TokenSpeedDisplayPoint(timestamp: Date().addingTimeInterval(3), rawTokens: 42, displayValue: 1.4),
            TokenSpeedDisplayPoint(timestamp: Date().addingTimeInterval(4), rawTokens: 0, displayValue: 0),
        ].enumerated().map { (offset: $0.offset, point: $0.element) }

        let rocketX = TokenSpeedFloatingRocketPlacement.xPosition(
            for: points,
            horizontalInset: 8,
            usableWidth: 176,
            fallbackX: 174)

        XCTAssertEqual(rocketX, 140, accuracy: 0.001)
    }

    func test_rocketUsesFallbackAnchorWhenThereAreNoBursts() {
        let points = [
            TokenSpeedDisplayPoint(timestamp: Date(), rawTokens: 0, displayValue: 0),
            TokenSpeedDisplayPoint(timestamp: Date().addingTimeInterval(1), rawTokens: 0, displayValue: 0),
        ].enumerated().map { (offset: $0.offset, point: $0.element) }

        let rocketX = TokenSpeedFloatingRocketPlacement.xPosition(
            for: points,
            horizontalInset: 8,
            usableWidth: 176,
            fallbackX: 174)

        XCTAssertEqual(rocketX, 174, accuracy: 0.001)
    }

    func test_rocketUsesFixedCounterclockwiseBaseAngle() {
        XCTAssertEqual(TokenSpeedFloatingRocketPlacement.baseAngle, -45, accuracy: 0.001)
    }

    func test_rocketMotionHasNoHorizontalOffset() {
        XCTAssertEqual(TokenSpeedFloatingRocketMotion.zero.xOffset, 0, accuracy: 0.001)
    }

    func test_widgetThemeUsesDarkTextInLightModeAndLightTextInDarkMode() throws {
        let lightPalette = TokenSpeedFloatingWidgetTheme.palette(for: .light)
        let darkPalette = TokenSpeedFloatingWidgetTheme.palette(for: .dark)

        let lightText = try XCTUnwrap(lightPalette.textColor.usingColorSpace(.sRGB))
        let darkText = try XCTUnwrap(darkPalette.textColor.usingColorSpace(.sRGB))

        XCTAssertEqual(lightText.redComponent, 31.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(lightText.greenComponent, 35.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(lightText.blueComponent, 42.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(lightText.alphaComponent, 0.96, accuracy: 0.001)

        XCTAssertEqual(darkText.redComponent, 1, accuracy: 0.001)
        XCTAssertEqual(darkText.greenComponent, 1, accuracy: 0.001)
        XCTAssertEqual(darkText.blueComponent, 1, accuracy: 0.001)
        XCTAssertEqual(darkText.alphaComponent, 0.98, accuracy: 0.001)
    }

    func test_widgetThemeUsesGraphiteLinesInLightModeAndWhiteLinesInDarkMode() throws {
        let lightPalette = TokenSpeedFloatingWidgetTheme.palette(for: .light)
        let darkPalette = TokenSpeedFloatingWidgetTheme.palette(for: .dark)

        let lightBaseline = try XCTUnwrap(lightPalette.baselineColor.usingColorSpace(.sRGB))
        let lightGuide = try XCTUnwrap(lightPalette.guideLineColor.usingColorSpace(.sRGB))
        let darkBaseline = try XCTUnwrap(darkPalette.baselineColor.usingColorSpace(.sRGB))
        let darkGuide = try XCTUnwrap(darkPalette.guideLineColor.usingColorSpace(.sRGB))

        XCTAssertEqual(lightBaseline.redComponent, 31.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(lightBaseline.greenComponent, 35.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(lightBaseline.blueComponent, 42.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(lightBaseline.alphaComponent, 0.78, accuracy: 0.001)

        XCTAssertEqual(lightGuide.redComponent, 31.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(lightGuide.greenComponent, 35.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(lightGuide.blueComponent, 42.0 / 255.0, accuracy: 0.001)
        XCTAssertEqual(lightGuide.alphaComponent, 0.14, accuracy: 0.001)

        XCTAssertEqual(darkBaseline.redComponent, 1, accuracy: 0.001)
        XCTAssertEqual(darkBaseline.greenComponent, 1, accuracy: 0.001)
        XCTAssertEqual(darkBaseline.blueComponent, 1, accuracy: 0.001)
        XCTAssertEqual(darkBaseline.alphaComponent, 0.96, accuracy: 0.001)

        XCTAssertEqual(darkGuide.redComponent, 1, accuracy: 0.001)
        XCTAssertEqual(darkGuide.greenComponent, 1, accuracy: 0.001)
        XCTAssertEqual(darkGuide.blueComponent, 1, accuracy: 0.001)
        XCTAssertEqual(darkGuide.alphaComponent, 0.11, accuracy: 0.001)
    }
}
