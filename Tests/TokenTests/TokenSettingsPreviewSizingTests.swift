import CoreGraphics
import XCTest
@testable import CodexBar

final class TokenSettingsPreviewSizingTests: XCTestCase {
    func test_sizingUsesViewportFallbackBeforePreviewIsMeasured() {
        let scale: CGFloat = 0.78
        let sizing = TokenSettingsPreviewSizing(
            naturalPanelHeight: nil,
            availableDisplayHeight: 320,
            scale: scale)

        XCTAssertEqual(sizing.maxDisplayedHeight, 320, accuracy: 0.001)
        XCTAssertEqual(sizing.visibleUnscaledHeight, 410.256, accuracy: 0.001)
        XCTAssertEqual(sizing.naturalPanelHeight, sizing.visibleUnscaledHeight, accuracy: 0.001)
        XCTAssertFalse(sizing.allowsScrolling)
    }

    func test_sizingKeepsFullPanelWhenViewportCanFitScaledPreview() {
        let sizing = TokenSettingsPreviewSizing(
            naturalPanelHeight: 640,
            availableDisplayHeight: 560,
            scale: 0.78)

        XCTAssertEqual(sizing.maxDisplayedHeight, 499.2, accuracy: 0.001)
        XCTAssertEqual(sizing.visibleUnscaledHeight, 640, accuracy: 0.001)
        XCTAssertFalse(sizing.allowsScrolling)
    }

    func test_sizingClampsPanelAndEnablesScrollingWhenViewportIsShort() {
        let sizing = TokenSettingsPreviewSizing(
            naturalPanelHeight: 640,
            availableDisplayHeight: 300,
            scale: 0.78)

        XCTAssertEqual(sizing.maxDisplayedHeight, 300, accuracy: 0.001)
        XCTAssertEqual(sizing.visibleUnscaledHeight, 384.615, accuracy: 0.001)
        XCTAssertTrue(sizing.allowsScrolling)
    }

    func test_scaledViewportMatchesVisibleUnscaledHeight() {
        let scale: CGFloat = 0.78
        let sizing = TokenSettingsPreviewSizing(
            naturalPanelHeight: 820,
            availableDisplayHeight: 320,
            scale: scale)

        XCTAssertEqual(sizing.visibleUnscaledHeight * scale, sizing.maxDisplayedHeight, accuracy: 0.001)
    }
}
