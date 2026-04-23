import XCTest
@testable import CodexBar

final class TokenSpeedRocketBurstAnimatorTests: XCTestCase {
    func test_triggerRequiresPositiveLaunchStrength() {
        XCTAssertNil(TokenSpeedRocketBurstTrigger(launchTimestamp: Date(), launchStrength: 0))
        XCTAssertNil(TokenSpeedRocketBurstTrigger(launchTimestamp: nil, launchStrength: 0.4))
    }

    func test_triggerQuantizesLaunchStrengthForStableTaskIdentity() throws {
        let timestamp = Date(timeIntervalSince1970: 1_800_000_000)
        let trigger = try XCTUnwrap(
            TokenSpeedRocketBurstTrigger(
                launchTimestamp: timestamp,
                launchStrength: 0.4564))

        XCTAssertEqual(trigger.timestamp, timestamp)
        XCTAssertEqual(trigger.strengthBucket, 456)
    }

    func test_panelLaunchMotionUsesHorizontalDrift() {
        let motion = TokenSpeedRocketBurstAnimator.launchMotion(
            strength: 0.8,
            allowsHorizontalDrift: true)

        XCTAssertGreaterThan(motion.xOffset, 0)
        XCTAssertLessThan(motion.yOffset, 0)
        XCTAssertGreaterThan(motion.scale, 1)
    }

    func test_floatingLaunchMotionStaysOnSameHorizontalAxis() {
        let motion = TokenSpeedRocketBurstAnimator.launchMotion(
            strength: 0.8,
            allowsHorizontalDrift: false)

        XCTAssertEqual(motion.xOffset, 0, accuracy: 0.001)
        XCTAssertLessThan(motion.yOffset, 0)
    }

    func test_settleMotionReturnsTowardRestPose() {
        let launch = TokenSpeedRocketBurstAnimator.launchMotion(
            strength: 0.8,
            allowsHorizontalDrift: true)
        let settle = TokenSpeedRocketBurstAnimator.settleMotion(
            strength: 0.8,
            allowsHorizontalDrift: true)

        XCTAssertLessThan(abs(settle.xOffset), abs(launch.xOffset))
        XCTAssertLessThan(abs(settle.yOffset), abs(launch.yOffset))
        XCTAssertLessThan(abs(settle.rotation), abs(launch.rotation))
        XCTAssertLessThan(settle.scale, launch.scale)
    }
}
