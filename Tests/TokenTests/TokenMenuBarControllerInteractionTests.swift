import AppKit
import XCTest
@testable import CodexBar

final class TokenMenuBarControllerInteractionTests: XCTestCase {
    func test_mainPanelUsesMouseDownInteraction() {
        XCTAssertEqual(TokenMenuBarInteractionPolicy.mainPanelEvents, [.leftMouseDown])
    }

    func test_speedPanelKeepsMouseUpInteraction() {
        XCTAssertEqual(TokenMenuBarInteractionPolicy.speedPanelEvents, [.leftMouseUp])
    }

    func test_mainPanelMeasurementUsesDeferredHotPathDelay() {
        XCTAssertEqual(TokenMenuPanelHotPath.measurementDelay, .milliseconds(3800))
    }

    func test_systemPopoverUsesNativeAnimation() {
        XCTAssertTrue(TokenMenuPopupAnimationPolicy.systemPopoverAnimates)
    }

    func test_liquidGlassPopupRemainsStatic() {
        XCTAssertEqual(TokenMenuPopupAnimationPolicy.liquidGlassAnimationBehavior, .none)
    }
}
