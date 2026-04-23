import CodexBarCore
import XCTest
@testable import CodexBar

@MainActor
final class TokenSpeedPanelContentTests: XCTestCase {
    func test_speedPanelContentBuildsWithRecentSamplesAndHistory() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: TokenSpeedPanelLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let sandbox = try TokenSpeedPanelSandbox()
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: TokenSpeedPanelDashboardProvider(),
            startupRefresh: false)

        let base = Date(timeIntervalSince1970: 1_800_000_000)
        store.recentTokenSpeedSamples = (0..<600).compactMap { offset in
            let timestamp = base.addingTimeInterval(Double(offset))
            return TokenSpeedSample(timestamp: timestamp, tokens: offset % 5 == 0 ? 40 + offset : 0)
        }
        store.tokenSpeedHistoryEntries = [
            TokenSpeedHistoryEntry(timestamp: base.addingTimeInterval(599), tokens: 99),
            TokenSpeedHistoryEntry(timestamp: base.addingTimeInterval(541), tokens: 48),
        ]

        _ = TokenSpeedPanelContent(
            store: store,
            settings: settings,
            panelHeight: 404).body
    }

    func test_speedPanelMetricsRespectSharedWidth() {
        XCTAssertEqual(TokenSpeedPanelContent.preferredPanelWidth, MenuContent.preferredPanelWidth)
        XCTAssertGreaterThan(TokenSpeedPanelContent.panelMetrics(availableScreenHeight: nil).displayHeight, 0)
    }

    func test_speedPanelContentBuildsAfterThemeSwitch() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let settings = SettingsStore(
            defaults: defaults,
            launchAtLoginManager: TokenSpeedPanelLaunchAtLoginManager(),
            preferredLanguages: { ["en-US"] })
        let sandbox = try TokenSpeedPanelSandbox()
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sandbox.root.appendingPathComponent("sessions", isDirectory: true),
            historyStore: TokenHistoryStore(fileURL: sandbox.fileURL))
        let store = UsageStore(
            settings: settings,
            provider: provider,
            dashboardProvider: TokenSpeedPanelDashboardProvider(),
            startupRefresh: false)

        _ = TokenSpeedPanelContent(store: store, settings: settings, panelHeight: 404).body

        settings.menuVisualTheme = .cyberNeon

        _ = TokenSpeedPanelContent(store: store, settings: settings, panelHeight: 404).body
    }

    func test_panelModelBuilderUsesRawLogScaleWithoutDecayTail() {
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let samples = [
            TokenSpeedSample(timestamp: base, tokens: 0),
            TokenSpeedSample(timestamp: base.addingTimeInterval(1), tokens: 100_000),
            TokenSpeedSample(timestamp: base.addingTimeInterval(2), tokens: 0),
            TokenSpeedSample(timestamp: base.addingTimeInterval(3), tokens: 0),
        ]

        let model = TokenSpeedPanelModelBuilder.makeModel(samples: samples)
        let expectedPeakValue = log10(Double(100_000) + 1)

        XCTAssertEqual(model.points.count, 4)
        XCTAssertEqual(model.points[0].displayValue, 0)
        XCTAssertEqual(model.points[1].displayValue, expectedPeakValue, accuracy: 0.000_001)
        XCTAssertEqual(model.points[2].displayValue, 0)
        XCTAssertEqual(model.points[3].displayValue, 0)
        XCTAssertGreaterThan(model.scaleTopValue, model.points[1].displayValue)
    }

    func test_panelModelBuilderBuildsRocketLiftAndDescentTrack() {
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let samples = [
            TokenSpeedSample(timestamp: base, tokens: 0),
            TokenSpeedSample(timestamp: base.addingTimeInterval(1), tokens: 10000),
            TokenSpeedSample(timestamp: base.addingTimeInterval(2), tokens: 0),
            TokenSpeedSample(timestamp: base.addingTimeInterval(3), tokens: 0),
            TokenSpeedSample(timestamp: base.addingTimeInterval(4), tokens: 80000),
        ]

        let model = TokenSpeedPanelModelBuilder.makeModel(samples: samples)

        XCTAssertEqual(model.rocketPoints.count, samples.count)
        XCTAssertEqual(model.rocketPoints[0].rocketValue, 0)
        XCTAssertGreaterThan(
            model.rocketPoints[1].rocketValue,
            model.points[1].displayValue + 0.17)
        XCTAssertGreaterThan(model.rocketLaunchStrength, 0)
        XCTAssertEqual(model.rocketLaunchTimestamp, samples.last?.timestamp)
        XCTAssertLessThan(model.rocketPoints[2].rocketValue, model.rocketPoints[1].rocketValue)
        XCTAssertGreaterThanOrEqual(model.rocketPoints[2].rocketValue, 0)
        XCTAssertLessThan(model.rocketPoints[3].rocketValue, model.rocketPoints[2].rocketValue)
        XCTAssertGreaterThan(model.rocketPoints[4].rocketValue, model.rocketPoints[3].rocketValue)
        XCTAssertEqual(model.rocketHeadPoint, model.rocketPoints.last)
    }

    func test_panelModelBuilderKeepsRocketOnBaselineForAllZeroWindow() {
        let base = Date(timeIntervalSince1970: 1_800_000_000)
        let samples = (0..<5).map { offset in
            TokenSpeedSample(timestamp: base.addingTimeInterval(Double(offset)), tokens: 0)
        }

        let model = TokenSpeedPanelModelBuilder.makeModel(samples: samples)

        XCTAssertTrue(model.rocketPoints.allSatisfy { $0.rocketValue == 0 })
        XCTAssertEqual(model.rocketHeadPoint.rocketValue, 0)
        XCTAssertEqual(model.rocketHeadPoint.timestamp, samples.last?.timestamp)
        XCTAssertEqual(model.rocketLaunchStrength, 0)
        XCTAssertNil(model.rocketLaunchTimestamp)
    }
}

private struct TokenSpeedPanelSandbox {
    let root: URL
    let fileURL: URL

    init() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        self.root = root
        self.fileURL = root.appendingPathComponent("token_stats.json", isDirectory: false)
    }
}

@MainActor
private final class TokenSpeedPanelDashboardProvider: OpenAIDashboardProviding {
    func loadCachedDashboard() throws -> OpenAIDashboardCache? {
        nil
    }

    func loadAccountInfo() -> CodexAccountInfo {
        CodexAccountInfo(email: "person@example.com", plan: "Plus")
    }

    func refresh(
        settings _: OpenAIDashboardSettings,
        force _: Bool,
        logger _: ((String) -> Void)?) async throws -> OpenAIDashboardRefreshResult
    {
        throw OpenAIDashboardFetcher.FetchError.loginRequired
    }
}

@MainActor
private final class TokenSpeedPanelLaunchAtLoginManager: LaunchAtLoginManaging {
    func isEnabled() -> Bool {
        false
    }

    func setEnabled(_: Bool) throws {}
}
