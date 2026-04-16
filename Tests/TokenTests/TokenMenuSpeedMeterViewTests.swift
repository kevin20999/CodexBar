import XCTest
@testable import CodexBar

@MainActor
final class TokenMenuSpeedMeterViewTests: XCTestCase {
    func test_statusItemAppearanceUsesCoffeeSymbolWhenIdle() {
        let metrics = MenuBarTokenSpeedMetrics(tokensPerSecond: 0)

        XCTAssertEqual(TokenMenuSpeedStatusItemAppearance.symbolName(for: metrics), "cup.and.saucer")
        XCTAssertEqual(TokenMenuSpeedStatusItemAppearance.fontSize(for: metrics), 11)
    }

    func test_statusItemAppearanceUsesRocketSymbolWhenActive() {
        let metrics = MenuBarTokenSpeedMetrics(tokensPerSecond: 42)

        XCTAssertEqual(TokenMenuSpeedStatusItemAppearance.symbolName(for: metrics), "rocket")
        XCTAssertEqual(TokenMenuSpeedStatusItemAppearance.fontSize(for: metrics), 12.5)
    }

    func test_launchMotionUsesVerticalLiftRotationAndScaleOnly() {
        let motion = TokenMenuSpeedStatusItemAnimation.launchMotion(strength: 0.8)

        XCTAssertLessThan(motion.yOffset, 0)
        XCTAssertLessThan(motion.rotation, 0)
        XCTAssertGreaterThan(motion.scale, 1)
    }

    func test_settleMotionKeepsVerticalOffsetButResetsRotationAndScale() {
        let motion = TokenMenuSpeedStatusItemAnimation.settleMotion(strength: 0.8)

        XCTAssertLessThan(motion.yOffset, 0)
        XCTAssertEqual(motion.rotation, 0)
        XCTAssertEqual(motion.scale, 1)
    }
}
