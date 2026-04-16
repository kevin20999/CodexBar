import Foundation

public struct OpenAIDashboardSettings: Sendable, Equatable {
    public let cookieSource: ProviderCookieSource
    public let manualCookieHeader: String
    public let backgroundBrowserAutoImportEnabled: Bool

    public init(
        cookieSource: ProviderCookieSource,
        manualCookieHeader: String,
        backgroundBrowserAutoImportEnabled: Bool)
    {
        self.cookieSource = cookieSource
        self.manualCookieHeader = manualCookieHeader
        self.backgroundBrowserAutoImportEnabled = backgroundBrowserAutoImportEnabled
    }
}

public enum OpenAIDashboardRefreshError: LocalizedError, Equatable, Sendable {
    case browserImportDeferredUntilUserAction
    case manualRefreshRequiredUntilUserAction

    public var errorDescription: String? {
        switch self {
        case .browserImportDeferredUntilUserAction:
            "Browser session import was deferred until user action."
        case .manualRefreshRequiredUntilUserAction:
            "Manual OpenAI web refresh was deferred until user action."
        }
    }
}

public struct OpenAIDashboardRefreshResult: Sendable {
    public let snapshot: OpenAIDashboardSnapshot
    public let targetEmail: String?
    public let cookieImportResult: OpenAIDashboardBrowserCookieImporter.ImportResult?
    public let usedCache: Bool

    public init(
        snapshot: OpenAIDashboardSnapshot,
        targetEmail: String?,
        cookieImportResult: OpenAIDashboardBrowserCookieImporter.ImportResult?,
        usedCache: Bool)
    {
        self.snapshot = snapshot
        self.targetEmail = targetEmail
        self.cookieImportResult = cookieImportResult
        self.usedCache = usedCache
    }
}

@MainActor
protocol OpenAIDashboardFetching {
    func loadLatestDashboard(
        accountEmail: String?,
        logger: ((String) -> Void)?,
        debugDumpHTML: Bool,
        timeout: TimeInterval) async throws -> OpenAIDashboardSnapshot
}

extension OpenAIDashboardFetcher: OpenAIDashboardFetching {}

@MainActor
protocol OpenAIDashboardBrowserCookieImporting {
    func importBestCookies(
        intoAccountEmail targetEmail: String?,
        allowAnyAccount: Bool,
        logger: ((String) -> Void)?) async throws -> OpenAIDashboardBrowserCookieImporter.ImportResult
    func importSafariCookies(
        intoAccountEmail targetEmail: String?,
        allowAnyAccount: Bool,
        logger: ((String) -> Void)?) async throws -> OpenAIDashboardBrowserCookieImporter.ImportResult
    func importManualCookies(
        cookieHeader: String,
        intoAccountEmail targetEmail: String?,
        allowAnyAccount: Bool,
        logger: ((String) -> Void)?) async throws -> OpenAIDashboardBrowserCookieImporter.ImportResult
}

extension OpenAIDashboardBrowserCookieImporter: OpenAIDashboardBrowserCookieImporting {}

@MainActor
public protocol OpenAIDashboardProviding: AnyObject {
    func loadCachedDashboard() throws -> OpenAIDashboardCache?
    func loadAccountInfo() -> CodexAccountInfo
    func refresh(
        settings: OpenAIDashboardSettings,
        force: Bool,
        logger: ((String) -> Void)?) async throws -> OpenAIDashboardRefreshResult
}

@MainActor
public final class OpenAIDashboardProvider: OpenAIDashboardProviding {
    private static let defaultBackgroundAutoImportCooldown: TimeInterval = 5 * 60

    private let browserDetection: BrowserDetection
    private let fetcher: any OpenAIDashboardFetching
    private let accountReader: any CodexAuthAccountReading
    private let backgroundAutoImportCooldown: TimeInterval
    private let loadCachedDashboardClosure: () -> OpenAIDashboardCache?
    private let saveCachedDashboardClosure: (OpenAIDashboardCache) -> Void
    private let cookieImporterFactory: (BrowserDetection) -> any OpenAIDashboardBrowserCookieImporting
    private let now: @Sendable () -> Date
    private let refreshTTL: TimeInterval
    private var lastNetworkRefreshAt: Date?
    private var lastAutomaticImportAttemptAtByTarget: [String: Date] = [:]
    private var lastObservedAutoImportTargetKey: String?

    public init(
        browserDetection: BrowserDetection = BrowserDetection(),
        fetcher: OpenAIDashboardFetcher = OpenAIDashboardFetcher(),
        accountReader: any CodexAuthAccountReading = CodexAuthAccountReader(),
        refreshTTL: TimeInterval = 5 * 60,
        now: @escaping @Sendable () -> Date = Date.init)
    {
        self.browserDetection = browserDetection
        self.fetcher = fetcher
        self.accountReader = accountReader
        self.backgroundAutoImportCooldown = Self.defaultBackgroundAutoImportCooldown
        self.loadCachedDashboardClosure = { OpenAIDashboardCacheStore.load() }
        self.saveCachedDashboardClosure = { cache in
            OpenAIDashboardCacheStore.save(cache)
        }
        self.cookieImporterFactory = { detection in
            OpenAIDashboardBrowserCookieImporter(browserDetection: detection)
        }
        self.refreshTTL = refreshTTL
        self.now = now
    }

    init(
        browserDetection: BrowserDetection = BrowserDetection(),
        fetcher: any OpenAIDashboardFetching,
        accountReader: any CodexAuthAccountReading,
        refreshTTL: TimeInterval = 5 * 60,
        backgroundAutoImportCooldown: TimeInterval = 5 * 60,
        loadCachedDashboard: @escaping () -> OpenAIDashboardCache? = { OpenAIDashboardCacheStore.load() },
        saveCachedDashboard: @escaping (OpenAIDashboardCache) -> Void = { cache in
            OpenAIDashboardCacheStore.save(cache)
        },
        now: @escaping @Sendable () -> Date = Date.init,
        cookieImporterFactory: @escaping (BrowserDetection) -> any OpenAIDashboardBrowserCookieImporting = {
            detection in OpenAIDashboardBrowserCookieImporter(browserDetection: detection)
        })
    {
        self.browserDetection = browserDetection
        self.fetcher = fetcher
        self.accountReader = accountReader
        self.backgroundAutoImportCooldown = backgroundAutoImportCooldown
        self.loadCachedDashboardClosure = loadCachedDashboard
        self.saveCachedDashboardClosure = saveCachedDashboard
        self.cookieImporterFactory = cookieImporterFactory
        self.refreshTTL = refreshTTL
        self.now = now
    }

    public func loadCachedDashboard() throws -> OpenAIDashboardCache? {
        self.loadCachedDashboardClosure()
    }

    public func loadAccountInfo() -> CodexAccountInfo {
        self.accountReader.loadAccountInfo()
    }

    public func refresh(
        settings: OpenAIDashboardSettings,
        force: Bool,
        logger: ((String) -> Void)?) async throws -> OpenAIDashboardRefreshResult
    {
        let accountInfo = self.accountReader.loadAccountInfo()
        let targetEmail = self.normalizedEmail(accountInfo.email)
        self.resetAutomaticImportCooldownIfNeeded(targetEmail: targetEmail)

        if !force,
           let cached = self.loadCachedDashboardClosure(),
           self.normalizedEmail(cached.accountEmail) == targetEmail,
           self.now().timeIntervalSince(self.lastNetworkRefreshAt ?? cached.snapshot.updatedAt) < self.refreshTTL
        {
            return OpenAIDashboardRefreshResult(
                snapshot: cached.snapshot,
                targetEmail: self.normalizedEmail(cached.accountEmail),
                cookieImportResult: nil,
                usedCache: true)
        }

        let allowAnyAccount = targetEmail == nil
        let log: (String) -> Void = { message in
            logger?(message)
        }

        var effectiveEmail = targetEmail
        var savedSessionError: Error?
        var savedSessionMismatchFound: [OpenAIDashboardBrowserCookieImporter.FoundAccount] = []

        do {
            log("Trying saved OpenAI web session.")
            let savedSnapshot = try await self.fetcher.loadLatestDashboard(
                accountEmail: effectiveEmail,
                logger: logger,
                debugDumpHTML: false,
                timeout: 15)
            if !self.dashboardEmailMismatch(expected: targetEmail, actual: savedSnapshot.signedInEmail) {
                self.persist(snapshot: savedSnapshot, accountEmail: effectiveEmail)
                return OpenAIDashboardRefreshResult(
                    snapshot: savedSnapshot,
                    targetEmail: effectiveEmail,
                    cookieImportResult: nil,
                    usedCache: false)
            }
            if let foundEmail = self.normalizedEmail(savedSnapshot.signedInEmail) {
                savedSessionMismatchFound = [.init(sourceLabel: "Saved session", email: foundEmail)]
            }
            if [.auto, .safari].contains(settings.cookieSource), !force, !settings.backgroundBrowserAutoImportEnabled {
                log(
                    "Saved OpenAI web session does not match the current Codex account. " +
                        "Background auto-import is disabled.")
            } else {
                log("Saved OpenAI web session does not match the current Codex account. Retrying with browser cookies.")
            }
        } catch {
            if settings.cookieSource == .off {
                throw error
            }
            savedSessionError = error
            log("Saved OpenAI web session fetch failed: \(error.localizedDescription)")
        }

        if !force {
            if [.auto, .safari].contains(settings.cookieSource), !settings.backgroundBrowserAutoImportEnabled {
                log("Skipping automatic browser cookie import until the user refreshes manually.")
                throw OpenAIDashboardRefreshError.browserImportDeferredUntilUserAction
            }

            if settings.cookieSource == .manual {
                log("Skipping manual cookie import until the user refreshes manually.")
                throw OpenAIDashboardRefreshError.manualRefreshRequiredUntilUserAction
            }
        }

        if [.auto, .safari].contains(settings.cookieSource), !force {
            guard self.shouldAttemptAutomaticBrowserImport(targetEmail: targetEmail) else {
                log("Skipping automatic browser cookie import during cooldown.")
                if let savedSessionError {
                    throw savedSessionError
                }
                throw OpenAIDashboardBrowserCookieImporter.ImportError
                    .noMatchingAccount(found: savedSessionMismatchFound)
            }
            self.recordAutomaticBrowserImportAttempt(targetEmail: targetEmail)
        }

        let importer = self.cookieImporterFactory(self.browserDetection)
        let importResult: OpenAIDashboardBrowserCookieImporter.ImportResult = switch settings.cookieSource {
        case .auto:
            try await importer.importBestCookies(
                intoAccountEmail: targetEmail,
                allowAnyAccount: allowAnyAccount,
                logger: logger)
        case .safari:
            try await importer.importSafariCookies(
                intoAccountEmail: targetEmail,
                allowAnyAccount: allowAnyAccount,
                logger: logger)
        case .manual:
            try await importer.importManualCookies(
                cookieHeader: settings.manualCookieHeader,
                intoAccountEmail: targetEmail,
                allowAnyAccount: allowAnyAccount,
                logger: logger)
        case .off:
            throw OpenAIDashboardFetcher.FetchError.loginRequired
        }

        effectiveEmail = self.normalizedEmail(importResult.signedInEmail) ?? targetEmail
        log("Browser cookies imported from \(importResult.sourceLabel). Refreshing OpenAI dashboard.")

        let snapshot = try await self.fetcher.loadLatestDashboard(
            accountEmail: effectiveEmail,
            logger: logger,
            debugDumpHTML: false,
            timeout: 60)

        if self.dashboardEmailMismatch(expected: targetEmail, actual: snapshot.signedInEmail) {
            let foundEmail = self.normalizedEmail(snapshot.signedInEmail) ?? self
                .normalizedEmail(importResult.signedInEmail)
            if let foundEmail {
                throw OpenAIDashboardBrowserCookieImporter.ImportError.noMatchingAccount(
                    found: [.init(sourceLabel: importResult.sourceLabel, email: foundEmail)])
            }
            throw OpenAIDashboardBrowserCookieImporter.ImportError.noMatchingAccount(found: [])
        }

        self.persist(snapshot: snapshot, accountEmail: effectiveEmail)
        return OpenAIDashboardRefreshResult(
            snapshot: snapshot,
            targetEmail: effectiveEmail,
            cookieImportResult: importResult,
            usedCache: false)
    }

    private func normalizedEmail(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value.lowercased()
    }

    private func dashboardEmailMismatch(expected: String?, actual: String?) -> Bool {
        guard let expected, !expected.isEmpty else { return false }
        guard let actual = self.normalizedEmail(actual) else { return false }
        return actual != expected
    }

    private func persist(snapshot: OpenAIDashboardSnapshot, accountEmail: String?) {
        self.saveCachedDashboardClosure(OpenAIDashboardCache(accountEmail: accountEmail, snapshot: snapshot))
        self.lastNetworkRefreshAt = self.now()
    }

    private func automaticImportTargetKey(for targetEmail: String?) -> String {
        targetEmail ?? "__allow-any-account__"
    }

    private func resetAutomaticImportCooldownIfNeeded(targetEmail: String?) {
        let key = self.automaticImportTargetKey(for: targetEmail)
        guard self.lastObservedAutoImportTargetKey != key else { return }
        self.lastObservedAutoImportTargetKey = key
        self.lastAutomaticImportAttemptAtByTarget.removeAll()
    }

    private func shouldAttemptAutomaticBrowserImport(targetEmail: String?) -> Bool {
        let key = self.automaticImportTargetKey(for: targetEmail)
        guard let lastAttempt = self.lastAutomaticImportAttemptAtByTarget[key] else {
            return true
        }
        return self.now().timeIntervalSince(lastAttempt) >= self.backgroundAutoImportCooldown
    }

    private func recordAutomaticBrowserImportAttempt(targetEmail: String?) {
        let key = self.automaticImportTargetKey(for: targetEmail)
        self.lastAutomaticImportAttemptAtByTarget[key] = self.now()
    }
}
