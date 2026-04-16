import XCTest
@testable import CodexBar

final class TokenMenuPanelPlacementTests: XCTestCase {
    func test_centeredAnchorKeepsPanelCenteredWhenSpaceAllows() {
        let frame = TokenMenuPanelPlacement.frame(
            anchorRect: CGRect(x: 500, y: 1000, width: 20, height: 24),
            panelSize: CGSize(width: 438, height: 640),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 1040))

        XCTAssertEqual(frame.origin.x, 291)
        XCTAssertEqual(frame.origin.y, 354)
        XCTAssertEqual(frame.size.width, 438)
        XCTAssertEqual(frame.size.height, 640)
    }

    func test_rightEdgeClampKeepsPanelInsideVisibleFrame() {
        let frame = TokenMenuPanelPlacement.frame(
            anchorRect: CGRect(x: 1388, y: 1000, width: 24, height: 24),
            panelSize: CGSize(width: 438, height: 640),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 1040))

        XCTAssertEqual(frame.origin.x, 994)
    }

    func test_leftEdgeClampKeepsPanelInsideVisibleFrame() {
        let frame = TokenMenuPanelPlacement.frame(
            anchorRect: CGRect(x: 6, y: 1000, width: 24, height: 24),
            panelSize: CGSize(width: 438, height: 640),
            visibleFrame: CGRect(x: 0, y: 0, width: 1440, height: 1040))

        XCTAssertEqual(frame.origin.x, 8)
    }

    func test_verticalClampShrinksPanelToAvailableHeight() {
        let frame = TokenMenuPanelPlacement.frame(
            anchorRect: CGRect(x: 500, y: 540, width: 20, height: 24),
            panelSize: CGSize(width: 438, height: 760),
            visibleFrame: CGRect(x: 0, y: 0, width: 900, height: 560))

        XCTAssertEqual(frame.origin.x, 291)
        XCTAssertEqual(frame.origin.y, 8)
        XCTAssertEqual(frame.size.width, 438)
        XCTAssertEqual(frame.size.height, 544)
    }
}
