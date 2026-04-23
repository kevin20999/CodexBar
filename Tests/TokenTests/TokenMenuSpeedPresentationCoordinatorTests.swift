import XCTest
@testable import CodexBar

@MainActor
final class TokenMenuSpeedPresentationCoordinatorTests: XCTestCase {
    func test_consumePositiveSampleImmediatelyShowsRocketBurst() {
        let coordinator = TokenMenuSpeedPresentationCoordinator(timing: .test)

        coordinator.consume(
            rawMetrics: MenuBarTokenSpeedMetrics(
                tokensPerSecond: 42,
                previousTokensPerSecond: 0,
                sampleDate: Date(timeIntervalSince1970: 10)),
            bubbleDisplayText: "42")

        XCTAssertEqual(coordinator.state.phase, .ignite)
        XCTAssertTrue(coordinator.state.usesRocketIcon)
        XCTAssertTrue(coordinator.state.bubblePresented)
        XCTAssertEqual(coordinator.state.displayedTokensPerSecond, 42)
        XCTAssertEqual(coordinator.state.bubbleDisplayText, "42")
    }

    func test_zeroSampleDoesNotCancelActiveBurstSynchronously() {
        let coordinator = TokenMenuSpeedPresentationCoordinator(timing: .test)
        coordinator.consume(
            rawMetrics: MenuBarTokenSpeedMetrics(tokensPerSecond: 18, previousTokensPerSecond: 0),
            bubbleDisplayText: "18")
        let activeBurstID = coordinator.state.burstID

        coordinator.consume(rawMetrics: .zero, bubbleDisplayText: "0")

        XCTAssertEqual(coordinator.state.burstID, activeBurstID)
        XCTAssertTrue(coordinator.state.usesRocketIcon)
        XCTAssertEqual(coordinator.state.displayedTokensPerSecond, 18)
        XCTAssertEqual(coordinator.state.bubbleDisplayText, "18")
    }

    func test_retriggerDuringHoldRefreshesBurstAndDisplayedValue() async {
        let coordinator = TokenMenuSpeedPresentationCoordinator(timing: .test)
        coordinator.consume(
            rawMetrics: MenuBarTokenSpeedMetrics(tokensPerSecond: 12, previousTokensPerSecond: 0),
            bubbleDisplayText: "1.2 万")

        try? await Task.sleep(for: .milliseconds(40))
        XCTAssertEqual(coordinator.state.phase, .hold)
        let firstBurstID = coordinator.state.burstID

        coordinator.consume(
            rawMetrics: MenuBarTokenSpeedMetrics(tokensPerSecond: 44, previousTokensPerSecond: 12),
            bubbleDisplayText: "44")

        XCTAssertEqual(coordinator.state.phase, .ignite)
        XCTAssertGreaterThan(coordinator.state.burstID, firstBurstID)
        XCTAssertEqual(coordinator.state.displayedTokensPerSecond, 44)
        XCTAssertEqual(coordinator.state.bubbleDisplayText, "44")
    }

    func test_burstEventuallyReturnsToIdleAfterDismiss() async {
        let coordinator = TokenMenuSpeedPresentationCoordinator(timing: .test)
        coordinator.consume(
            rawMetrics: MenuBarTokenSpeedMetrics(tokensPerSecond: 22, previousTokensPerSecond: 0),
            bubbleDisplayText: "22")

        try? await Task.sleep(for: .milliseconds(140))

        XCTAssertEqual(coordinator.state, .idle)
    }

    func test_dismissingPhaseKeepsBubblePresentedUntilIdle() async {
        let coordinator = TokenMenuSpeedPresentationCoordinator(timing: .test)
        coordinator.consume(
            rawMetrics: MenuBarTokenSpeedMetrics(tokensPerSecond: 22, previousTokensPerSecond: 0),
            bubbleDisplayText: "22")

        try? await Task.sleep(for: .milliseconds(70))

        XCTAssertEqual(coordinator.state.phase, .dismissing)
        XCTAssertTrue(coordinator.state.bubblePresented)
    }
}

private extension TokenMenuSpeedPresentationCoordinator.Timing {
    static let test = TokenMenuSpeedPresentationCoordinator.Timing(
        igniteDuration: .milliseconds(10),
        thrustDuration: .milliseconds(10),
        holdDuration: .milliseconds(40),
        dismissDuration: .milliseconds(10))
}
