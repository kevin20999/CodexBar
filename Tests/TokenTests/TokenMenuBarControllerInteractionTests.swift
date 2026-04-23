import AppKit
import CodexBarCore
import XCTest
@testable import CodexBar

@MainActor
final class TokenMenuBarControllerInteractionTests: XCTestCase {
    func test_primaryStatusItemRenderSignatureIgnoresSpeedMeterInputs() {
        let metrics = MenuBarDisplayMetrics(
            inputText: "12.3k",
            outputText: "987",
            quotaPercentText: "56%",
            quotaFraction: 0.56,
            quotaIsStale: false)

        let first = TokenMenuBarController.makePrimaryStatusItemRenderSignature(
            mode: .quota5h,
            metrics: metrics,
            quotaStyle: .capsule,
            fallbackText: "H 56%",
            targetHeight: 19,
            backingScaleFactor: 2)
        let second = TokenMenuBarController.makePrimaryStatusItemRenderSignature(
            mode: .quota5h,
            metrics: metrics,
            quotaStyle: .capsule,
            fallbackText: "H 56%",
            targetHeight: 19,
            backingScaleFactor: 2)

        XCTAssertEqual(first, second)
    }

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

    func test_controllersStartUninstantiated() throws {
        let controller = try self.makeController()

        XCTAssertFalse(controller.hasMainPanelControllerForTesting)
        XCTAssertFalse(controller.hasPopoverControllerForTesting)
        XCTAssertFalse(controller.hasSpeedPanelControllerForTesting)
        XCTAssertFalse(controller.hasSpeedFloatingChartControllerForTesting)
    }

    func test_hiddenControllersCanBeReleasedAndRecreated() throws {
        let controller = try self.makeController()

        controller.instantiateMainPopupControllerForTesting(style: .liquidGlass)
        controller.instantiateMainPopupControllerForTesting(style: .systemPopover)
        controller.instantiateSpeedControllersForTesting(includeFloatingChart: true)

        XCTAssertTrue(controller.hasMainPanelControllerForTesting)
        XCTAssertTrue(controller.hasPopoverControllerForTesting)
        XCTAssertTrue(controller.hasSpeedPanelControllerForTesting)
        XCTAssertTrue(controller.hasSpeedFloatingChartControllerForTesting)

        controller.releaseAllHiddenControllersForTesting()

        XCTAssertFalse(controller.hasMainPanelControllerForTesting)
        XCTAssertFalse(controller.hasPopoverControllerForTesting)
        XCTAssertFalse(controller.hasSpeedPanelControllerForTesting)
        XCTAssertFalse(controller.hasSpeedFloatingChartControllerForTesting)

        controller.instantiateMainPopupControllerForTesting(style: .liquidGlass)
        controller.instantiateSpeedControllersForTesting(includeFloatingChart: false)

        XCTAssertTrue(controller.hasMainPanelControllerForTesting)
        XCTAssertFalse(controller.hasPopoverControllerForTesting)
        XCTAssertTrue(controller.hasSpeedPanelControllerForTesting)
        XCTAssertFalse(controller.hasSpeedFloatingChartControllerForTesting)
    }

    private func makeController() throws -> TokenMenuBarController {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: FakeTokenMenuBarLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let historyStore = TokenHistoryStore(fileURL: root.appendingPathComponent("token_stats.json"))
        let provider = CodexSessionTokenProvider(
            sessionRootURL: root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: historyStore)
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: OpenAIDashboardProvider(),
            startupRefresh: false)
        return TokenMenuBarController(settings: settings, store: store)
    }
}

private final class FakeTokenMenuBarLaunchAtLoginManager: LaunchAtLoginManaging {
    private var enabled = false

    func isEnabled() -> Bool {
        self.enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        self.enabled = enabled
    }
}
