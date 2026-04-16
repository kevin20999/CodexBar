import Foundation
import XCTest
@testable import CodexBarCore

@MainActor
final class OpenAIDashboardProviderTests: XCTestCase {
    func test_backgroundAutoImportRetriesSavedSessionFailureOnlyOncePerCooldownWindow() async throws {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
        let accountReader = TestAccountReader(email: "person@example.com")
        let fetcher = TestDashboardFetcher(steps: [
            .failure(OpenAIDashboardFetcher.FetchError.loginRequired),
            .success(Self.makeSnapshot(email: "person@example.com", updatedAt: now)),
            .failure(OpenAIDashboardFetcher.FetchError.loginRequired),
        ])
        let importer = TestCookieImporter(autoResults: [
            .success(Self.makeImportResult(email: "person@example.com")),
        ])
        var cache: OpenAIDashboardCache?
        let provider = OpenAIDashboardProvider(
            fetcher: fetcher,
            accountReader: accountReader,
            refreshTTL: 0,
            backgroundAutoImportCooldown: 5 * 60,
            loadCachedDashboard: { cache },
            saveCachedDashboard: { cache = $0 },
            now: { now },
            cookieImporterFactory: { _ in importer })
        let settings = OpenAIDashboardSettings(
            cookieSource: .auto,
            manualCookieHeader: "",
            backgroundBrowserAutoImportEnabled: true)

        let first = try await provider.refresh(settings: settings, force: false, logger: nil)

        XCTAssertEqual(first.cookieImportResult?.sourceLabel, "Safari")
        XCTAssertEqual(importer.autoImportTargets, ["person@example.com"])

        now = now.addingTimeInterval(60)

        do {
            _ = try await provider.refresh(settings: settings, force: false, logger: nil)
            XCTFail("Expected background refresh during cooldown to rethrow saved-session failure.")
        } catch let error as OpenAIDashboardFetcher.FetchError {
            guard case .loginRequired = error else {
                return XCTFail("Unexpected fetch error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(importer.autoImportTargets, ["person@example.com"])
    }

    func test_manualRefreshBypassesBackgroundAutoImportCooldown() async throws {
        var now = Date(timeIntervalSince1970: 1_800_000_100)
        let accountReader = TestAccountReader(email: "person@example.com")
        let fetcher = TestDashboardFetcher(steps: [
            .failure(OpenAIDashboardFetcher.FetchError.loginRequired),
            .success(Self.makeSnapshot(email: "person@example.com", updatedAt: now)),
            .failure(OpenAIDashboardFetcher.FetchError.loginRequired),
            .success(Self.makeSnapshot(email: "person@example.com", updatedAt: now.addingTimeInterval(120))),
        ])
        let importer = TestCookieImporter(autoResults: [
            .success(Self.makeImportResult(email: "person@example.com")),
            .success(Self.makeImportResult(email: "person@example.com", sourceLabel: "Chrome")),
        ])
        var cache: OpenAIDashboardCache?
        let provider = OpenAIDashboardProvider(
            fetcher: fetcher,
            accountReader: accountReader,
            refreshTTL: 0,
            backgroundAutoImportCooldown: 5 * 60,
            loadCachedDashboard: { cache },
            saveCachedDashboard: { cache = $0 },
            now: { now },
            cookieImporterFactory: { _ in importer })
        let settings = OpenAIDashboardSettings(
            cookieSource: .auto,
            manualCookieHeader: "",
            backgroundBrowserAutoImportEnabled: true)

        _ = try await provider.refresh(settings: settings, force: false, logger: nil)
        now = now.addingTimeInterval(60)
        let manual = try await provider.refresh(settings: settings, force: true, logger: nil)

        XCTAssertEqual(importer.autoImportTargets, ["person@example.com", "person@example.com"])
        XCTAssertEqual(manual.cookieImportResult?.sourceLabel, "Chrome")
    }

    func test_accountSwitchClearsBackgroundAutoImportCooldown() async throws {
        var now = Date(timeIntervalSince1970: 1_800_000_200)
        let accountReader = TestAccountReader(email: "one@example.com")
        let fetcher = TestDashboardFetcher(steps: [
            .failure(OpenAIDashboardFetcher.FetchError.loginRequired),
            .success(Self.makeSnapshot(email: "one@example.com", updatedAt: now)),
            .failure(OpenAIDashboardFetcher.FetchError.loginRequired),
            .success(Self.makeSnapshot(email: "two@example.com", updatedAt: now.addingTimeInterval(120))),
        ])
        let importer = TestCookieImporter(autoResults: [
            .success(Self.makeImportResult(email: "one@example.com", sourceLabel: "Safari")),
            .success(Self.makeImportResult(email: "two@example.com", sourceLabel: "Chrome")),
        ])
        var cache: OpenAIDashboardCache?
        let provider = OpenAIDashboardProvider(
            fetcher: fetcher,
            accountReader: accountReader,
            refreshTTL: 0,
            backgroundAutoImportCooldown: 5 * 60,
            loadCachedDashboard: { cache },
            saveCachedDashboard: { cache = $0 },
            now: { now },
            cookieImporterFactory: { _ in importer })
        let settings = OpenAIDashboardSettings(
            cookieSource: .auto,
            manualCookieHeader: "",
            backgroundBrowserAutoImportEnabled: true)

        _ = try await provider.refresh(settings: settings, force: false, logger: nil)
        accountReader.email = "two@example.com"
        now = now.addingTimeInterval(60)
        let second = try await provider.refresh(settings: settings, force: false, logger: nil)

        XCTAssertEqual(importer.autoImportTargets, ["one@example.com", "two@example.com"])
        XCTAssertEqual(second.targetEmail, "two@example.com")
    }

    func test_backgroundAutoImportDisabledStillDefersUntilManualRefresh() async throws {
        let accountReader = TestAccountReader(email: "person@example.com")
        let fetcher = TestDashboardFetcher(steps: [
            .failure(OpenAIDashboardFetcher.FetchError.loginRequired),
        ])
        let importer = TestCookieImporter(autoResults: [])
        var cache: OpenAIDashboardCache?
        let provider = OpenAIDashboardProvider(
            fetcher: fetcher,
            accountReader: accountReader,
            refreshTTL: 0,
            backgroundAutoImportCooldown: 5 * 60,
            loadCachedDashboard: { cache },
            saveCachedDashboard: { cache = $0 },
            now: { Date(timeIntervalSince1970: 1_800_000_300) },
            cookieImporterFactory: { _ in importer })
        let settings = OpenAIDashboardSettings(
            cookieSource: .auto,
            manualCookieHeader: "",
            backgroundBrowserAutoImportEnabled: false)

        do {
            _ = try await provider.refresh(settings: settings, force: false, logger: nil)
            XCTFail("Expected deferred auto-import error.")
        } catch let error as OpenAIDashboardRefreshError {
            XCTAssertEqual(error, .browserImportDeferredUntilUserAction)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(importer.autoImportTargets.isEmpty)
    }

    func test_manualCookieModeDefersUntilManualRefresh() async throws {
        let accountReader = TestAccountReader(email: "person@example.com")
        let fetcher = TestDashboardFetcher(steps: [
            .failure(OpenAIDashboardFetcher.FetchError.loginRequired),
        ])
        let importer = TestCookieImporter(autoResults: [])
        importer.manualResults = [
            .success(Self.makeImportResult(email: "person@example.com", sourceLabel: "Manual cookie header")),
        ]
        var cache: OpenAIDashboardCache?
        let provider = OpenAIDashboardProvider(
            fetcher: fetcher,
            accountReader: accountReader,
            refreshTTL: 0,
            backgroundAutoImportCooldown: 5 * 60,
            loadCachedDashboard: { cache },
            saveCachedDashboard: { cache = $0 },
            now: { Date(timeIntervalSince1970: 1_800_000_320) },
            cookieImporterFactory: { _ in importer })
        let settings = OpenAIDashboardSettings(
            cookieSource: .manual,
            manualCookieHeader: "oai-did=example;",
            backgroundBrowserAutoImportEnabled: false)

        do {
            _ = try await provider.refresh(settings: settings, force: false, logger: nil)
            XCTFail("Expected manual refresh required error.")
        } catch let error as OpenAIDashboardRefreshError {
            XCTAssertEqual(error, .manualRefreshRequiredUntilUserAction)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(importer.manualImportCallCount, 0)
    }

    func test_safariCookieModeUsesSafariImporterOnly() async throws {
        let accountReader = TestAccountReader(email: "person@example.com")
        let fetcher = TestDashboardFetcher(steps: [
            .failure(OpenAIDashboardFetcher.FetchError.loginRequired),
            .success(Self.makeSnapshot(
                email: "person@example.com",
                updatedAt: Date(timeIntervalSince1970: 1_800_000_340))),
        ])
        let importer = TestCookieImporter(autoResults: [])
        importer.safariResults = [
            .success(Self.makeImportResult(email: "person@example.com", sourceLabel: "Safari")),
        ]
        var cache: OpenAIDashboardCache?
        let provider = OpenAIDashboardProvider(
            fetcher: fetcher,
            accountReader: accountReader,
            refreshTTL: 0,
            backgroundAutoImportCooldown: 5 * 60,
            loadCachedDashboard: { cache },
            saveCachedDashboard: { cache = $0 },
            now: { Date(timeIntervalSince1970: 1_800_000_340) },
            cookieImporterFactory: { _ in importer })
        let settings = OpenAIDashboardSettings(
            cookieSource: .safari,
            manualCookieHeader: "",
            backgroundBrowserAutoImportEnabled: true)

        let result = try await provider.refresh(settings: settings, force: false, logger: nil)

        XCTAssertEqual(result.cookieImportResult?.sourceLabel, "Safari")
        XCTAssertEqual(importer.safariImportTargets, ["person@example.com"])
        XCTAssertTrue(importer.autoImportTargets.isEmpty)
        XCTAssertEqual(importer.manualImportCallCount, 0)
    }

    private static func makeSnapshot(email: String, updatedAt: Date) -> OpenAIDashboardSnapshot {
        OpenAIDashboardSnapshot(
            signedInEmail: email,
            codeReviewRemainingPercent: 72,
            creditEvents: [],
            dailyBreakdown: [],
            usageBreakdown: [],
            creditsPurchaseURL: nil,
            primaryLimit: RateWindow(
                usedPercent: 44,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: nil),
            secondaryLimit: nil,
            creditsRemaining: 12,
            accountPlan: "Plus",
            updatedAt: updatedAt)
    }

    private static func makeImportResult(
        email: String,
        sourceLabel: String = "Safari") -> OpenAIDashboardBrowserCookieImporter.ImportResult
    {
        OpenAIDashboardBrowserCookieImporter.ImportResult(
            sourceLabel: sourceLabel,
            cookieCount: 5,
            signedInEmail: email,
            matchesCodexEmail: true)
    }
}

@MainActor
private final class TestDashboardFetcher: OpenAIDashboardFetching {
    enum Step {
        case success(OpenAIDashboardSnapshot)
        case failure(Error)
    }

    var steps: [Step]
    var requestedEmails: [String?] = []

    init(steps: [Step]) {
        self.steps = steps
    }

    func loadLatestDashboard(
        accountEmail: String?,
        logger _: ((String) -> Void)?,
        debugDumpHTML _: Bool,
        timeout _: TimeInterval) async throws -> OpenAIDashboardSnapshot
    {
        self.requestedEmails.append(accountEmail)
        guard !self.steps.isEmpty else {
            XCTFail("No fetch step configured.")
            throw OpenAIDashboardFetcher.FetchError.loginRequired
        }

        let step = self.steps.removeFirst()
        switch step {
        case let .success(snapshot):
            return snapshot
        case let .failure(error):
            throw error
        }
    }
}

@MainActor
private final class TestCookieImporter: OpenAIDashboardBrowserCookieImporting {
    var autoResults: [Result<OpenAIDashboardBrowserCookieImporter.ImportResult, Error>]
    var safariResults: [Result<OpenAIDashboardBrowserCookieImporter.ImportResult, Error>] = []
    var manualResults: [Result<OpenAIDashboardBrowserCookieImporter.ImportResult, Error>] = []
    var autoImportTargets: [String?] = []
    var safariImportTargets: [String?] = []
    var manualImportCallCount = 0

    init(autoResults: [Result<OpenAIDashboardBrowserCookieImporter.ImportResult, Error>]) {
        self.autoResults = autoResults
    }

    func importBestCookies(
        intoAccountEmail targetEmail: String?,
        allowAnyAccount _: Bool,
        logger _: ((String) -> Void)?) async throws -> OpenAIDashboardBrowserCookieImporter.ImportResult
    {
        self.autoImportTargets.append(targetEmail)
        guard !self.autoResults.isEmpty else {
            XCTFail("No auto import result configured.")
            throw OpenAIDashboardBrowserCookieImporter.ImportError.noCookiesFound
        }
        return try self.autoResults.removeFirst().get()
    }

    func importSafariCookies(
        intoAccountEmail targetEmail: String?,
        allowAnyAccount _: Bool,
        logger _: ((String) -> Void)?) async throws -> OpenAIDashboardBrowserCookieImporter.ImportResult
    {
        self.safariImportTargets.append(targetEmail)
        guard !self.safariResults.isEmpty else {
            XCTFail("No Safari import result configured.")
            throw OpenAIDashboardBrowserCookieImporter.ImportError.noCookiesFound
        }
        return try self.safariResults.removeFirst().get()
    }

    func importManualCookies(
        cookieHeader _: String,
        intoAccountEmail _: String?,
        allowAnyAccount _: Bool,
        logger _: ((String) -> Void)?) async throws -> OpenAIDashboardBrowserCookieImporter.ImportResult
    {
        self.manualImportCallCount += 1
        guard !self.manualResults.isEmpty else {
            XCTFail("No manual import result configured.")
            throw OpenAIDashboardBrowserCookieImporter.ImportError.manualCookieHeaderInvalid
        }
        return try self.manualResults.removeFirst().get()
    }
}

@MainActor
private final class TestAccountReader: CodexAuthAccountReading {
    var email: String?

    init(email: String?) {
        self.email = email
    }

    func loadAccountInfo() -> CodexAccountInfo {
        CodexAccountInfo(email: self.email, plan: "Plus")
    }
}
