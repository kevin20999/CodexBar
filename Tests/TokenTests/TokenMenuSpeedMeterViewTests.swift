import XCTest
@testable import CodexBar

@MainActor
final class TokenMenuSpeedMeterViewTests: XCTestCase {
    func test_statusItemAppearanceUsesCoffeeGlyphWhenIdle() {
        let presentation = TokenMenuSpeedPresentationState.idle

        XCTAssertEqual(TokenMenuSpeedStatusItemAppearance.symbolGlyph(for: presentation), .coffee)
        XCTAssertEqual(TokenMenuSpeedStatusItemAppearance.fontSize(for: presentation), 11)
    }

    func test_statusItemAppearanceUsesRocketGlyphWhenActive() {
        let presentation = TokenMenuSpeedPresentationState(
            displayedTokensPerSecond: 42,
            bubbleDisplayText: "42",
            launchStrength: 0.8,
            lastBurstDate: Date(),
            burstID: 1,
            phase: .hold)

        XCTAssertEqual(TokenMenuSpeedStatusItemAppearance.symbolGlyph(for: presentation), .rocket)
        XCTAssertEqual(TokenMenuSpeedStatusItemAppearance.fontSize(for: presentation), 12.5)
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

    func test_bubbleLayoutStartsAtStatusItemCapsuleWidthDuringIgnite() {
        let presentation = TokenMenuSpeedPresentationState(
            displayedTokensPerSecond: 193,
            bubbleDisplayText: "193",
            launchStrength: 0.8,
            lastBurstDate: Date(),
            burstID: 1,
            phase: .ignite)

        XCTAssertEqual(TokenMenuSpeedBubbleLayout.width(for: presentation), TokenMenuSpeedBubbleLayout.compactWidth)
        XCTAssertEqual(TokenMenuSpeedBubbleLayout.size(for: presentation).height, TokenMenuSpeedBubbleLayout.compactHeight)
    }

    func test_bubbleLayoutExpandsInHoldPhase() {
        let presentation = TokenMenuSpeedPresentationState(
            displayedTokensPerSecond: 193,
            bubbleDisplayText: "193",
            launchStrength: 0.8,
            lastBurstDate: Date(),
            burstID: 1,
            phase: .hold)

        XCTAssertGreaterThan(TokenMenuSpeedBubbleLayout.width(for: presentation), TokenMenuSpeedBubbleLayout.compactWidth)
        XCTAssertEqual(TokenMenuSpeedBubbleLayout.overlap(for: presentation), 5)
    }

    func test_bubbleLayoutUsesCompactLocalizedTextForWidthMeasurement() {
        let presentation = TokenMenuSpeedPresentationState(
            displayedTokensPerSecond: 12_345,
            bubbleDisplayText: "1.2 万",
            launchStrength: 0.8,
            lastBurstDate: Date(),
            burstID: 1,
            phase: .hold)

        XCTAssertEqual(TokenMenuSpeedBubbleLayout.expandedWidth(for: presentation.bubbleDisplayText), TokenMenuSpeedBubbleLayout.width(for: presentation))
        XCTAssertLessThan(
            TokenMenuSpeedBubbleLayout.expandedWidth(for: presentation.bubbleDisplayText),
            TokenMenuSpeedBubbleLayout.expandedWidth(for: presentation.numericValueText))
    }
}
