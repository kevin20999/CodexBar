import CodexBarCore
import Foundation
import Logging
import Observation

enum OpenAIDashboardDisplayState: Equatable {
    case fresh
    case cachedNeedsManualRefresh(message: String)
    case realError(message: String, requiresLogin: Bool)
}

struct RemainingQuotaSectionPresentation {
    let codexQuotaModel: CodexQuotaOverviewModel
    let codexQuotaMessage: String
    let sparkQuotaItems: [QuotaProgressPresentation]
    let sparkHasQuotaData: Bool
    let sparkMessage: String
    let sparkErrorMessage: String?
}

struct MessageActivitySectionPresentation: Equatable {
    let days: [DailyOutboundMessageStats]
    let todayTotal: DailyOutboundMessageStats
    let sevenDayTotal: DailyOutboundMessageStats
    let thirtyDayTotal: DailyOutboundMessageStats
    let cumulativeTotal: DailyOutboundMessageStats

    static let empty = MessageActivitySectionPresentation(
        days: [],
        todayTotal: .empty(for: "today"),
        sevenDayTotal: .empty(for: "seven-day"),
        thirtyDayTotal: .empty(for: "thirty-day"),
        cumulativeTotal: .empty(for: "total"))
}

struct RecentFortyEightHourSectionPresentation: Equatable {
    let hours: [HourlyTokenStats]
    let headerTotalText: String

    static let empty = RecentFortyEightHourSectionPresentation(hours: [], headerTotalText: "--")
}

struct SummaryCardPresentation: Equatable {
    let valueText: String
    let detailText: String
}

@MainActor
@Observable
final class UsageStore {
    var days: [DailyTokenStats]
    var regularDays: [DailyTokenStats]
    var hours: [HourlyTokenStats]
    var regularHours: [HourlyTokenStats]
    var fiveMinuteBuckets: [FiveMinuteTokenStats]
    var outboundMessageDays: [DailyOutboundMessageStats]
    var sessionSnapshots: [String: SessionUsageSnapshot]
    var codexQuotaSnapshot: CodexQuotaSnapshot?
    var codexQuotaErrorMessage: String?
    var menuBarTokenSpeedMetrics: MenuBarTokenSpeedMetrics
    var recentTokenSpeedSamples: [TokenSpeedSample]
    var tokenSpeedHistoryEntries: [TokenSpeedHistoryEntry]
    var lastRefreshAt: Date?
    var openAIDashboard: OpenAIDashboardSnapshot?
    var openAIAccountPlanFallback: String?
    var openAIDashboardIsStale: Bool
    var openAIDashboardRequiresLogin: Bool
    var openAIDashboardPermissionDenied: Bool
    var openAIDashboardCookieImportStatus: String?
    var openAIDashboardCookieImportDebugLog: String?
    var openAIDashboardDisplayState: OpenAIDashboardDisplayState
    var lastOpenAIDashboardError: String?
    var isRefreshing: Bool
    var lastError: String?
    var remainingQuotaPresentation: RemainingQuotaSectionPresentation
    var messageActivityPresentation: MessageActivitySectionPresentation
    var thirtyDayChartDaysPresentation: [DailyTokenStats]
    var recentFortyEightHourPresentation: RecentFortyEightHourSectionPresentation
    var usageOverviewRowsPresentation: [UsageOverviewCardView.Row]
    var usageOverviewNumericItemsPresentation: [UsageOverviewNumericItem]
    var codeReviewCardPresentation: SummaryCardPresentation?
    var creditsCardPresentation: SummaryCardPresentation?
    var usageBreakdownPresentation: [OpenAIDashboardDailyBreakdown]
    var creditsHistoryPresentation: [OpenAIDashboardDailyBreakdown]

    @ObservationIgnored let settings: SettingsStore
    @ObservationIgnored private let provider: CodexSessionTokenProvider
    @ObservationIgnored private let codexQuotaProvider: any CodexQuotaProviding
    @ObservationIgnored private let dashboardProvider: any OpenAIDashboardProviding
    @ObservationIgnored private let historyStore: TokenHistoryStore
    @ObservationIgnored private let tokenRateMonitor: any CodexLiveTokenRateMonitoring
    @ObservationIgnored private let tokenSpeedHistoryStore: TokenSpeedHistoryStore
    @ObservationIgnored private let logger = Logger(label: "CodexBar.UsageStore")
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var tokenSpeedTask: Task<Void, Never>?
    @ObservationIgnored private var lastOpenAIDashboardSnapshot: OpenAIDashboardSnapshot?
    @ObservationIgnored private var lastOpenAIDashboardTargetEmail: String?
    @ObservationIgnored private var openAIWebDebugLines: [String] = []
    @ObservationIgnored var onSectionPresentationPublished: ((TokenMenuContentSection) -> Void)?

    init(
        settings: SettingsStore,
        provider: CodexSessionTokenProvider = CodexSessionTokenProvider(),
        codexQuotaProvider: any CodexQuotaProviding = CodexQuotaProvider(),
        dashboardProvider: any OpenAIDashboardProviding = OpenAIDashboardProvider(),
        tokenRateMonitor: (any CodexLiveTokenRateMonitoring)? = nil,
        tokenSpeedHistoryStore: TokenSpeedHistoryStore = TokenSpeedHistoryStore(
            fileURL: TokenSpeedHistoryStore.defaultFileURL(
                applicationSupportDirectoryName: TokenAppIdentity.applicationSupportDirectoryName)),
        startupRefresh: Bool = true)
    {
        self.settings = settings
        self.provider = provider
        self.codexQuotaProvider = codexQuotaProvider
        self.dashboardProvider = dashboardProvider
        self.historyStore = provider.historyStore
        self.tokenRateMonitor = tokenRateMonitor
            ?? CodexLiveTokenRateMonitor(sessionRootURL: provider.sessionRootURL)
        self.tokenSpeedHistoryStore = tokenSpeedHistoryStore
        self.days = []
        self.regularDays = []
        self.hours = []
        self.regularHours = []
        self.fiveMinuteBuckets = []
        self.outboundMessageDays = []
        self.sessionSnapshots = [:]
        self.codexQuotaSnapshot = nil
        self.codexQuotaErrorMessage = nil
        self.menuBarTokenSpeedMetrics = .zero
        self.recentTokenSpeedSamples = Self.makeRecentTokenSpeedTimeline(from: [], endingAt: Date())
        self.tokenSpeedHistoryEntries = []
        self.lastRefreshAt = nil
        self.openAIDashboard = nil
        self.openAIAccountPlanFallback = Self.cleanedAccountPlan(self.dashboardProvider.loadAccountInfo().plan)
        self.openAIDashboardIsStale = false
        self.openAIDashboardRequiresLogin = false
        self.openAIDashboardPermissionDenied = false
        self.openAIDashboardCookieImportStatus = nil
        self.openAIDashboardCookieImportDebugLog = nil
        self.openAIDashboardDisplayState = .fresh
        self.lastOpenAIDashboardError = nil
        self.isRefreshing = false
        self.lastError = nil
        self.remainingQuotaPresentation = RemainingQuotaSectionPresentation(
            codexQuotaModel: CodexQuotaOverviewModel(snapshot: nil, strings: settings.strings),
            codexQuotaMessage: settings.strings.codexQuotaUnavailableMessage,
            sparkQuotaItems: [],
            sparkHasQuotaData: false,
            sparkMessage: settings.strings.sparkQuotaUnavailableMessage,
            sparkErrorMessage: nil)
        self.messageActivityPresentation = .empty
        self.thirtyDayChartDaysPresentation = []
        self.recentFortyEightHourPresentation = .empty
        self.usageOverviewRowsPresentation = []
        self.usageOverviewNumericItemsPresentation = []
        self.codeReviewCardPresentation = nil
        self.creditsCardPresentation = nil
        self.usageBreakdownPresentation = []
        self.creditsHistoryPresentation = []

        self.loadCachedDashboard()
        self.loadPersistedHistory()
        self.loadPersistedTokenSpeedHistory()
        self.rebuildModulePresentationsImmediately()
        self.observeRefreshSettings()
        self.observeDashboardSettings()
        self.observePresentationSettings()
        self.observeTokenSpeedSettings()
        self.configureTokenSpeedMonitoring()

        guard startupRefresh else { return }
        self.startTimer()
        Task { [weak self] in
            await self?.refresh(forceDashboard: false)
        }
    }

    deinit {
        self.refreshTask?.cancel()
        self.tokenSpeedTask?.cancel()
    }

    var today: DailyTokenStats {
        self.day(for: Date(), in: self.days)
    }

    var regularToday: DailyTokenStats {
        self.day(for: Date(), in: self.regularDays)
    }

    var trailingSevenDays: [DailyTokenStats] {
        self.series(dayCount: 7, from: self.days)
    }

    var regularTrailingSevenDays: [DailyTokenStats] {
        self.series(dayCount: 7, from: self.regularDays)
    }

    var trailingThirtyDays: [DailyTokenStats] {
        self.series(dayCount: 30, from: self.days)
    }

    var regularTrailingThirtyDays: [DailyTokenStats] {
        self.series(dayCount: 30, from: self.regularDays)
    }

    var trailingTwentyFourHours: [HourlyTokenStats] {
        self.hourSeries(hourCount: 24, from: self.hours)
    }

    var trailingFortyEightHours: [HourlyTokenStats] {
        self.hourSeries(hourCount: 48, from: self.hours)
    }

    var regularTrailingFortyEightHours: [HourlyTokenStats] {
        self.hourSeries(hourCount: 48, from: self.regularHours)
    }

    var sevenDayTotal: DailyTokenStats {
        self.sum(self.trailingSevenDays)
    }

    var regularSevenDayTotal: DailyTokenStats {
        self.sum(self.regularTrailingSevenDays)
    }

    var thirtyDayTotal: DailyTokenStats {
        self.sum(self.trailingThirtyDays)
    }

    var regularThirtyDayTotal: DailyTokenStats {
        self.sum(self.regularTrailingThirtyDays)
    }

    var cumulativeTotal: DailyTokenStats {
        self.sum(self.days)
    }

    var regularCumulativeTotal: DailyTokenStats {
        self.sum(self.regularDays)
    }

    var todayOutboundMessages: DailyOutboundMessageStats {
        let key = DailyTokenStats.dayKey(for: Date(), calendar: Calendar.current)
        return self.outboundMessageDays.first(where: { $0.date == key }) ?? .empty(for: key)
    }

    var trailingThirtyOutboundMessageDays: [DailyOutboundMessageStats] {
        self.outboundMessageSeries(dayCount: 30)
    }

    var trailingSevenOutboundMessageDays: [DailyOutboundMessageStats] {
        self.outboundMessageSeries(dayCount: 7)
    }

    var sevenDayOutboundMessageTotal: DailyOutboundMessageStats {
        self.sumOutboundMessages(self.trailingSevenOutboundMessageDays)
    }

    var thirtyDayOutboundMessageTotal: DailyOutboundMessageStats {
        self.sumOutboundMessages(self.trailingThirtyOutboundMessageDays)
    }

    var cumulativeOutboundMessageTotal: DailyOutboundMessageStats {
        self.sumOutboundMessages(self.outboundMessageDays)
    }

    var menuBarText: String {
        self.menuBarText(for: self.settings.menuBarDisplayMode)
    }

    var menuBarDisplayMetrics: MenuBarDisplayMetrics {
        let primaryWindow = self.menuBarPrimaryQuotaWindow
        let secondaryWindow = self.menuBarSecondaryQuotaWindow
        return MenuBarDisplayMetrics(
            inputText: Self.shortTokenText(self.today.inputTokens),
            outputText: Self.shortTokenText(self.today.outputTokens),
            primaryQuota: self.menuBarQuotaMetrics(
                for: primaryWindow,
                fallbackShortLabel: "H",
                fallbackSummaryLabel: self.settings.strings.durationLabel(for: 5 * 60, fallbackPrimary: true)),
            secondaryQuota: secondaryWindow.map { window in
                self.menuBarQuotaMetrics(
                    for: window,
                    fallbackShortLabel: Self.compactWindowLabel(for: window.windowMinutes ?? (7 * 24 * 60)),
                    fallbackSummaryLabel: self.settings.strings.durationLabel(
                        for: window.windowMinutes ?? (7 * 24 * 60),
                        fallbackPrimary: false))
            },
            quotaIsStale: false)
    }

    var lastRefreshDescription: String {
        guard let lastRefreshAt else { return "--" }
        return self.settings.strings.updatedDescription(from: lastRefreshAt)
    }

    var dashboardRefreshDescription: String {
        guard let openAIDashboard else { return "--" }
        return self.settings.strings.updatedDescription(from: openAIDashboard.updatedAt)
    }

    var codexQuotaRefreshDescription: String {
        guard let codexQuotaSnapshot else { return "--" }
        return self.settings.strings.updatedDescription(from: codexQuotaSnapshot.updatedAt)
    }

    var isOpenAIWebEnabled: Bool {
        self.settings.openAIWebAccessEnabled && self.settings.codexCookieSource != .off
    }

    var isSparkQuotaFeatureEnabled: Bool {
        self.settings.showRemainingQuotaCard && self.settings.showSparkQuotaCard
    }

    var shouldRefreshOpenAIWebData: Bool {
        guard self.isOpenAIWebEnabled else { return false }

        return self.settings.showCodeReviewCard
            || self.settings.showCreditsCard
            || self.settings.showUsageBreakdownCard
            || self.settings.showCreditsHistoryCard
    }

    var hasStructuredSparkQuotaData: Bool {
        self.codexQuotaSnapshot?.sparkPrimary != nil || self.codexQuotaSnapshot?.sparkSecondary != nil
    }

    var shouldRefreshSparkQuotaFallback: Bool {
        guard self.isOpenAIWebEnabled, self.isSparkQuotaFeatureEnabled else { return false }
        return !self.hasStructuredSparkQuotaData
    }

    var sparkQuotaUsesOpenAIWebFallback: Bool {
        guard self.shouldRefreshSparkQuotaFallback else { return false }
        return self.openAIDashboard?.sparkPrimaryLimit != nil || self.openAIDashboard?.sparkSecondaryLimit != nil
    }

    var sparkPrimaryQuotaWindow: RateWindow? {
        self.codexQuotaSnapshot?
            .sparkPrimary ?? (self.sparkQuotaUsesOpenAIWebFallback ? self.openAIDashboard?.sparkPrimaryLimit : nil)
    }

    var sparkSecondaryQuotaWindow: RateWindow? {
        self.codexQuotaSnapshot?
            .sparkSecondary ?? (self.sparkQuotaUsesOpenAIWebFallback ? self.openAIDashboard?.sparkSecondaryLimit : nil)
    }

    var sparkQuotaHasData: Bool {
        self.sparkPrimaryQuotaWindow != nil || self.sparkSecondaryQuotaWindow != nil
    }

    var sparkQuotaIsStale: Bool {
        self.sparkQuotaUsesOpenAIWebFallback && self.openAIDashboardIsStale
    }

    var sparkQuotaCardErrorMessage: String? {
        guard self.sparkQuotaUsesOpenAIWebFallback else { return nil }
        return self.openAIDashboardQuotaCardErrorMessage
    }

    private func codexQuotaMessage(strings: AppStrings) -> String {
        if let message = self.codexQuotaErrorMessage, !message.isEmpty {
            return message
        }
        return strings.codexQuotaUnavailableMessage
    }

    private func sparkQuotaMessage(strings: AppStrings) -> String {
        if let message = self.sparkQuotaCardMessage, !message.isEmpty {
            return message
        }
        return strings.sparkQuotaUnavailableMessage
    }

    var sparkQuotaCardMessage: String? {
        if self.sparkQuotaUsesOpenAIWebFallback,
           let message = self.openAIDashboardQuotaCardMessage,
           !message.isEmpty
        {
            return message
        }

        if let message = self.codexQuotaErrorMessage, !message.isEmpty {
            return message
        }

        return nil
    }

    var openAIDashboardQuotaCardErrorMessage: String? {
        guard case let .realError(message, _) = self.openAIDashboardDisplayState else { return nil }
        return message
    }

    var openAIDashboardQuotaCardMessage: String? {
        switch self.openAIDashboardDisplayState {
        case .fresh:
            nil
        case let .cachedNeedsManualRefresh(message), let .realError(message, _):
            message
        }
    }

    func menuBarText(for displayMode: MenuBarDisplayMode) -> String {
        let strings = self.settings.strings
        let metrics = self.menuBarDisplayMetrics

        switch displayMode {
        case .todayIO:
            return strings.menuBarTodaySummary(input: metrics.inputText, output: metrics.outputText)
        case .quota5h:
            return strings.menuBarQuotaSummary(percentText: metrics.quotaPercentText)
        case .quotaDualCompact, .quotaDualKnockout:
            return strings.menuBarDualQuotaSummary(
                primaryLabel: metrics.primaryQuota.summaryLabel,
                primaryPercentText: metrics.primaryQuota.percentText,
                secondaryLabel: metrics.secondaryQuota?.summaryLabel,
                secondaryPercentText: metrics.secondaryQuota?.percentText)
        }
    }

    func refresh(forceDashboard: Bool = false) async {
        guard !self.isRefreshing else { return }
        self.isRefreshing = true
        defer { self.isRefreshing = false }

        await self.refreshTokenHistory()
        await self.refreshCodexQuota()
        await self.refreshOpenAIDashboard(
            force: forceDashboard,
            bypassFeatureGate: self.shouldRefreshSparkQuotaFallback)
        await self.publishModulePresentationsSequentially()
    }

    func forceRefreshOpenAIDashboardFromSafari() async {
        guard !self.isRefreshing else { return }
        self.isRefreshing = true
        defer { self.isRefreshing = false }

        await self.refreshOpenAIDashboard(
            force: true,
            overrideCookieSource: .safari,
            bypassFeatureGate: true)
    }

    func rebuildCache() async {
        guard !self.isRefreshing else { return }
        self.isRefreshing = true
        defer { self.isRefreshing = false }

        do {
            let outcome = try await TokenHistoryRefreshExecutor.rebuild(
                provider: self.provider,
                historyStore: self.historyStore)
            self.apply(document: outcome.document)
            self.lastError = outcome.firstError
            await self.publishModulePresentationsSequentially()
        } catch {
            self.logger.error("Rebuild failed: \(error.localizedDescription)")
            self.lastError = error.localizedDescription
        }
    }

    private func refreshTokenHistory() async {
        do {
            let outcome = try await TokenHistoryRefreshExecutor.refresh(
                provider: self.provider,
                historyStore: self.historyStore)
            self.apply(document: outcome.document)
            self.lastError = outcome.firstError
        } catch {
            self.logger.error("Refresh failed: \(error.localizedDescription)")
            self.lastError = error.localizedDescription
        }
    }

    private func refreshCodexQuota() async {
        do {
            self.codexQuotaSnapshot = try await self.codexQuotaProvider.loadQuotaSnapshot()
            self.codexQuotaErrorMessage = nil
        } catch {
            self.logger.warning("Codex quota refresh failed: \(error.localizedDescription)")
            self.codexQuotaSnapshot = nil
            self.codexQuotaErrorMessage = error.localizedDescription
        }
    }

    private func refreshOpenAIDashboard(
        force: Bool,
        overrideCookieSource: ProviderCookieSource? = nil,
        bypassFeatureGate: Bool = false) async
    {
        guard self.isOpenAIWebEnabled, bypassFeatureGate || self.shouldRefreshOpenAIWebData else {
            self.resetDisplayedDashboard()
            return
        }

        let strings = self.settings.strings
        let accountInfo = self.dashboardProvider.loadAccountInfo()
        let targetEmail = self.normalizedEmail(accountInfo.email)
        self.openAIAccountPlanFallback = Self.cleanedAccountPlan(accountInfo.plan)

        if self.lastOpenAIDashboardTargetEmail != targetEmail {
            self.lastOpenAIDashboardTargetEmail = targetEmail
            self.openAIDashboardRequiresLogin = false
        }

        self.resetOpenAIWebDebugLog()
        self.openAIDashboardPermissionDenied = false
        let log: (String) -> Void = { [weak self] line in
            self?.appendOpenAIWebDebug(line)
        }

        do {
            let effectiveSettings = OpenAIDashboardSettings(
                cookieSource: overrideCookieSource ?? self.settings.openAIDashboardSettings.cookieSource,
                manualCookieHeader: self.settings.openAIDashboardSettings.manualCookieHeader,
                backgroundBrowserAutoImportEnabled: self.settings
                    .openAIDashboardSettings
                    .backgroundBrowserAutoImportEnabled)
            let result = try await self.dashboardProvider.refresh(
                settings: effectiveSettings,
                force: force,
                logger: log)
            self.openAIDashboard = result.snapshot
            self.lastOpenAIDashboardSnapshot = result.snapshot
            self.openAIDashboardIsStale = false
            self.openAIDashboardRequiresLogin = false
            self.openAIDashboardPermissionDenied = false
            self.openAIDashboardDisplayState = .fresh
            self.lastOpenAIDashboardError = nil
            self.lastOpenAIDashboardTargetEmail = self.normalizedEmail(result.targetEmail) ?? targetEmail

            if let cookieImportResult = result.cookieImportResult {
                self.openAIDashboardCookieImportStatus = strings.cookieImportStatusText(
                    sourceLabel: cookieImportResult.sourceLabel,
                    cookieCount: cookieImportResult.cookieCount,
                    signedInEmail: cookieImportResult.signedInEmail,
                    matchesCodex: cookieImportResult.matchesCodexEmail,
                    allowAnyAccount: targetEmail == nil)
            } else {
                self.openAIDashboardCookieImportStatus = strings.usingSavedSessionMessage(
                    email: result.snapshot.signedInEmail ?? result.targetEmail)
            }
            self.flushOpenAIWebDebugLog()
        } catch let error as OpenAIDashboardBrowserCookieImporter.ImportError {
            self.handleDashboardImportError(error, strings: strings, targetEmail: targetEmail)
        } catch let error as OpenAIDashboardRefreshError {
            self.handleDashboardRefreshError(error, strings: strings)
        } catch let error as OpenAIDashboardFetcher.FetchError {
            self.handleDashboardFetchError(error, strings: strings, targetEmail: targetEmail)
        } catch {
            self.applyDashboardFailure(message: error.localizedDescription, requiresLogin: false)
        }
    }

    private func handleDashboardImportError(
        _ error: OpenAIDashboardBrowserCookieImporter.ImportError,
        strings: AppStrings,
        targetEmail: String?)
    {
        let foundAccounts: String = switch error {
        case let .noMatchingAccount(found):
            found
                .sorted { lhs, rhs in
                    if lhs.sourceLabel == rhs.sourceLabel { return lhs.email < rhs.email }
                    return lhs.sourceLabel < rhs.sourceLabel
                }
                .map { "\($0.sourceLabel): \($0.email)" }
                .joined(separator: " • ")
        default:
            ""
        }

        switch error {
        case .noCookiesFound, .dashboardStillRequiresLogin:
            self.openAIDashboardCookieImportStatus = strings.noSignedInSessionFoundMessage(found: foundAccounts)
            self.applyDashboardFailure(message: strings.quotaNeedsLoginMessage, requiresLogin: true)
        case let .browserAccessDenied(details):
            self.openAIDashboardCookieImportStatus = strings.cookieImportFailedMessage(details)
            self.openAIDashboardPermissionDenied = true
            self.applyDashboardFailure(message: strings.browserAccessDeniedMessage, requiresLogin: false)
        case .manualCookieHeaderInvalid:
            self.openAIDashboardCookieImportStatus = strings.manualCookieInvalidMessage
            self.applyDashboardFailure(message: strings.manualCookieInvalidMessage, requiresLogin: true)
        case .noMatchingAccount:
            self.openAIDashboardCookieImportStatus = strings.noSignedInSessionFoundMessage(found: foundAccounts)
            self.applyDashboardFailure(
                message: strings.accountMismatchMessage(
                    expected: targetEmail,
                    found: foundAccounts.isEmpty ? "unknown" : foundAccounts),
                requiresLogin: true)
        }
        self.flushOpenAIWebDebugLog()
    }

    private func handleDashboardRefreshError(_ error: OpenAIDashboardRefreshError, strings: AppStrings) {
        switch error {
        case .browserImportDeferredUntilUserAction:
            self.openAIDashboardCookieImportStatus = strings.openAIWebAutoImportDeferredMessage
            self.applyDashboardManualRefreshState(message: strings.openAIWebAutoImportDeferredMessage)
        case .manualRefreshRequiredUntilUserAction:
            self.openAIDashboardCookieImportStatus = strings.manualDashboardRefreshRequiredMessage
            self.applyDashboardManualRefreshState(message: strings.manualDashboardRefreshRequiredMessage)
        }
        self.flushOpenAIWebDebugLog()
    }

    private func handleDashboardFetchError(
        _ error: OpenAIDashboardFetcher.FetchError,
        strings: AppStrings,
        targetEmail: String?)
    {
        switch error {
        case .loginRequired:
            self.applyDashboardFailure(message: strings.quotaNeedsLoginMessage, requiresLogin: true)
        case let .noDashboardData(body):
            let message = self.looksLikeSignedOutHomepage(body)
                ? strings.quotaNeedsLoginMessage
                : self.friendlyUnavailableMessage(body: body, strings: strings, targetEmail: targetEmail)
            self.applyDashboardFailure(message: message, requiresLogin: self.looksLikeSignedOutHomepage(body))
        }
        self.flushOpenAIWebDebugLog()
    }

    private func friendlyUnavailableMessage(body: String, strings: AppStrings, targetEmail: String?) -> String {
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return strings.quotaUnavailableMessage
        }
        if self.looksLikeSignedOutHomepage(body) {
            return strings.quotaNeedsLoginMessage
        }
        if let targetEmail, !targetEmail.isEmpty,
           body.localizedCaseInsensitiveContains(targetEmail) == false,
           body.localizedCaseInsensitiveContains("chatgpt"), body.localizedCaseInsensitiveContains("login")
        {
            return strings.accountMismatchMessage(expected: targetEmail, found: "browser session")
        }
        return strings.quotaUnavailableMessage
    }

    private func looksLikeSignedOutHomepage(_ body: String) -> Bool {
        let lower = body.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lower.isEmpty { return false }
        let english = ["sign in", "log in", "create account", "continue with google", "skip to content", "chatgpt"]
        let chinese = ["登录", "免费注册", "历史聊天记录", "新聊天", "搜索聊天", "获取为你量身定制的回答"]
        let japanese = ["ログイン", "サインアップ", "新しいチャット", "チャットを検索"]
        return english.contains(where: lower.contains) || chinese.contains(where: lower.contains) || japanese
            .contains(where: lower.contains)
    }

    private func applyDashboardFailure(message: String, requiresLogin: Bool) {
        self.logger.warning("OpenAI dashboard refresh failed: \(message)")
        if let cached = self.lastOpenAIDashboardSnapshot ?? (try? self.dashboardProvider.loadCachedDashboard())?
            .snapshot
        {
            self.openAIDashboard = cached
            self.lastOpenAIDashboardSnapshot = cached
            self.openAIDashboardIsStale = true
        } else {
            self.openAIDashboard = nil
            self.openAIDashboardIsStale = false
        }
        self.openAIDashboardDisplayState = .realError(message: message, requiresLogin: requiresLogin)
        self.lastOpenAIDashboardError = message
        self.openAIDashboardRequiresLogin = requiresLogin
        if requiresLogin {
            self.openAIDashboardPermissionDenied = false
        }
    }

    private func applyDashboardManualRefreshState(message: String) {
        self.logger.notice("OpenAI dashboard refresh deferred until manual refresh: \(message)")
        if let cached = self.lastOpenAIDashboardSnapshot ?? (try? self.dashboardProvider.loadCachedDashboard())?
            .snapshot
        {
            self.openAIDashboard = cached
            self.lastOpenAIDashboardSnapshot = cached
            self.openAIDashboardIsStale = true
        } else {
            self.openAIDashboard = nil
            self.openAIDashboardIsStale = false
        }
        self.openAIDashboardDisplayState = .cachedNeedsManualRefresh(message: message)
        self.lastOpenAIDashboardError = nil
        self.openAIDashboardRequiresLogin = false
        self.openAIDashboardPermissionDenied = false
    }

    private func loadPersistedHistory() {
        do {
            let document = try self.historyStore.load()
            self.apply(document: document)
        } catch {
            self.lastError = error.localizedDescription
            self.logger.warning("Failed to load persisted history: \(error.localizedDescription)")
        }
    }

    private func loadCachedDashboard() {
        guard self.shouldRefreshOpenAIWebData else { return }
        do {
            if let cache = try self.dashboardProvider.loadCachedDashboard() {
                self.openAIDashboard = cache.snapshot
                self.lastOpenAIDashboardSnapshot = cache.snapshot
                self.lastOpenAIDashboardTargetEmail = self.normalizedEmail(cache.accountEmail)
            }
        } catch {
            self.logger.warning("Failed to load cached dashboard: \(error.localizedDescription)")
        }
    }

    private static func cleanedAccountPlan(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return UsageFormatter.cleanPlanName(value)
    }

    private func apply(document: TokenHistoryDocument) {
        self.sessionSnapshots = document.sessions
        self.days = document.days.sorted { $0.date < $1.date }
        self.regularDays = Self.aggregateDailyBuckets(from: document.sessions.values.compactMap { snapshot in
            guard snapshot.sessionOriginKind == .regular else { return nil }
            return snapshot.dailyBuckets
        })
        self.hours = document.hours.sorted { $0.hourStart < $1.hourStart }
        self.regularHours = Self.aggregateHourlyBuckets(from: document.sessions.values.compactMap { snapshot in
            guard snapshot.sessionOriginKind == .regular else { return nil }
            return snapshot.hourlyBuckets
        })
        self.fiveMinuteBuckets = document.fiveMinuteBuckets.sorted { $0.bucketStart < $1.bucketStart }
        self.outboundMessageDays = document.outboundMessageDays.sorted { $0.date < $1.date }
        self.lastRefreshAt = document.lastRefreshAt
    }

    func refreshModulePresentationsForCurrentState() async {
        await self.publishModulePresentationsSequentially()
    }

    private func rebuildModulePresentationsImmediately() {
        for section in self.presentationSections() {
            self.applyPresentationPayload(self.makePresentationPayload(for: section))
        }
    }

    private func publishModulePresentationsSequentially() async {
        for section in self.presentationSections() {
            self.applyPresentationPayload(self.makePresentationPayload(for: section))
            await Task.yield()
        }
    }

    private func presentationSections() -> [TokenMenuContentSection] {
        TokenMenuContentLayoutState(
            orderedModules: self.settings.dashboardModuleOrder,
            showsRemainingQuotaCard: self.settings.showRemainingQuotaCard,
            showsThirtyDayChartCard: self.settings.showThirtyDayChartCard,
            showsRecentTwentyFourHourChartCard: self.settings.showRecentTwentyFourHourChartCard,
            showsMessageActivityCard: self.settings.showMessageActivityCard,
            showsUsageOverviewCard: self.settings.showUsageOverviewCard,
            showsUsageOverviewNumericCard: self.settings.showUsageOverviewNumericCard,
            usageOverviewRowCount: self.configuredUsageOverviewRowCount,
            showsCodeReviewCard: self.settings.showCodeReviewCard,
            showsCreditsCard: self.settings.showCreditsCard,
            showsUsageBreakdownCard: self.settings.showUsageBreakdownCard,
            showsCreditsHistoryCard: self.settings.showCreditsHistoryCard,
            previewMode: false)
            .sections
            .filter { $0 != .footer }
    }

    private var configuredUsageOverviewRowCount: Int {
        [
            self.settings.showTodayUsageCard,
            self.settings.showSevenDayUsageCard,
            self.settings.showThirtyDayUsageCard,
            self.settings.showAllTimeUsageCard,
        ]
            .count(where: { $0 })
    }

    private enum PresentationPayload {
        case remainingQuota(RemainingQuotaSectionPresentation)
        case messageActivity(MessageActivitySectionPresentation)
        case thirtyDayChart([DailyTokenStats])
        case recentFortyEightHours(RecentFortyEightHourSectionPresentation)
        case usageOverview([UsageOverviewCardView.Row])
        case usageOverviewNumeric([UsageOverviewNumericItem])
        case summaryPair(
            first: DashboardModule,
            second: DashboardModule,
            codeReview: SummaryCardPresentation?,
            credits: SummaryCardPresentation?)
        case codeReview(SummaryCardPresentation?)
        case credits(SummaryCardPresentation?)
        case usageBreakdown([OpenAIDashboardDailyBreakdown])
        case creditsHistory([OpenAIDashboardDailyBreakdown])
    }

    private func makePresentationPayload(for section: TokenMenuContentSection) -> PresentationPayload {
        let strings = self.settings.strings

        switch section {
        case .remainingQuota:
            let dashboardModel = DashboardOverviewModel(
                snapshot: self.openAIDashboard,
                sparkPrimaryLimit: self.sparkPrimaryQuotaWindow,
                sparkSecondaryLimit: self.sparkSecondaryQuotaWindow,
                accountPlanFallback: self.openAIAccountPlanFallback,
                strings: strings,
                isStale: self.openAIDashboardIsStale,
                sparkIsStale: self.sparkQuotaIsStale)

            return .remainingQuota(
                RemainingQuotaSectionPresentation(
                    codexQuotaModel: CodexQuotaOverviewModel(snapshot: self.codexQuotaSnapshot, strings: strings),
                    codexQuotaMessage: self.codexQuotaMessage(strings: strings),
                    sparkQuotaItems: dashboardModel.sparkQuotaItems,
                    sparkHasQuotaData: dashboardModel.sparkHasQuotaData,
                    sparkMessage: self.sparkQuotaMessage(strings: strings),
                    sparkErrorMessage: self.sparkQuotaCardErrorMessage))
        case .messageActivity:
            return .messageActivity(
                MessageActivitySectionPresentation(
                    days: self.trailingThirtyOutboundMessageDays,
                    todayTotal: self.todayOutboundMessages,
                    sevenDayTotal: self.sevenDayOutboundMessageTotal,
                    thirtyDayTotal: self.thirtyDayOutboundMessageTotal,
                    cumulativeTotal: self.cumulativeOutboundMessageTotal))
        case .thirtyDayChart:
            return .thirtyDayChart(self.regularTrailingThirtyDays)
        case .recentTwentyFourHourChart:
            let hours = self.regularTrailingFortyEightHours
            let totalTokens = hours.reduce(into: 0) { partialResult, stats in
                partialResult += stats.totalTokens
            }
            return .recentFortyEightHours(
                RecentFortyEightHourSectionPresentation(
                    hours: hours,
                    headerTotalText: strings.recentFortyEightHourHeaderTotalText(totalTokens)))
        case .usageOverview:
            return .usageOverview(
                UsageOverviewPresentationBuilder.rows(store: self, settings: self.settings, strings: strings))
        case .usageOverviewNumeric:
            return .usageOverviewNumeric(
                UsageOverviewPresentationBuilder.numericItems(store: self, strings: strings))
        case let .summaryPair(first, second):
            return .summaryPair(
                first: first,
                second: second,
                codeReview: self.codeReviewSummaryIfNeeded(for: first, strings: strings)
                    ?? self.codeReviewSummaryIfNeeded(for: second, strings: strings),
                credits: self.creditsSummaryIfNeeded(for: first, strings: strings)
                    ?? self.creditsSummaryIfNeeded(for: second, strings: strings))
        case .codeReview:
            return .codeReview(self.makeCodeReviewCardPresentation(strings: strings))
        case .credits:
            return .credits(self.makeCreditsCardPresentation(strings: strings))
        case .usageBreakdown:
            return .usageBreakdown(self.openAIDashboard?.usageBreakdown ?? [])
        case .creditsHistory:
            return .creditsHistory(self.openAIDashboard?.dailyBreakdown ?? [])
        case .footer:
            return .usageOverview(self.usageOverviewRowsPresentation)
        }
    }

    private func applyPresentationPayload(_ payload: PresentationPayload) {
        switch payload {
        case let .remainingQuota(presentation):
            self.remainingQuotaPresentation = presentation
            self.onSectionPresentationPublished?(.remainingQuota)
        case let .messageActivity(presentation):
            self.messageActivityPresentation = presentation
            self.onSectionPresentationPublished?(.messageActivity)
        case let .thirtyDayChart(days):
            self.thirtyDayChartDaysPresentation = days
            self.onSectionPresentationPublished?(.thirtyDayChart)
        case let .recentFortyEightHours(presentation):
            self.recentFortyEightHourPresentation = presentation
            self.onSectionPresentationPublished?(.recentTwentyFourHourChart)
        case let .usageOverview(rows):
            self.usageOverviewRowsPresentation = rows
            self.onSectionPresentationPublished?(.usageOverview)
        case let .usageOverviewNumeric(items):
            self.usageOverviewNumericItemsPresentation = items
            self.onSectionPresentationPublished?(.usageOverviewNumeric)
        case let .summaryPair(first, second, codeReview, credits):
            self.codeReviewCardPresentation = codeReview
            self.creditsCardPresentation = credits
            self.onSectionPresentationPublished?(.summaryPair(first: first, second: second))
        case let .codeReview(presentation):
            self.codeReviewCardPresentation = presentation
            self.onSectionPresentationPublished?(.codeReview)
        case let .credits(presentation):
            self.creditsCardPresentation = presentation
            self.onSectionPresentationPublished?(.credits)
        case let .usageBreakdown(breakdown):
            self.usageBreakdownPresentation = breakdown
            self.onSectionPresentationPublished?(.usageBreakdown)
        case let .creditsHistory(history):
            self.creditsHistoryPresentation = history
            self.onSectionPresentationPublished?(.creditsHistory)
        }
    }

    private func codeReviewSummaryIfNeeded(
        for module: DashboardModule,
        strings: AppStrings)
        -> SummaryCardPresentation?
    {
        guard module == .codeReview else { return nil }
        return self.makeCodeReviewCardPresentation(strings: strings)
    }

    private func creditsSummaryIfNeeded(
        for module: DashboardModule,
        strings: AppStrings)
        -> SummaryCardPresentation?
    {
        guard module == .credits else { return nil }
        return self.makeCreditsCardPresentation(strings: strings)
    }

    private func makeCodeReviewCardPresentation(strings: AppStrings) -> SummaryCardPresentation? {
        guard let snapshot = self.openAIDashboard else { return nil }
        let dashboardModel = DashboardOverviewModel(
            snapshot: snapshot,
            sparkPrimaryLimit: self.sparkPrimaryQuotaWindow,
            sparkSecondaryLimit: self.sparkSecondaryQuotaWindow,
            accountPlanFallback: self.openAIAccountPlanFallback,
            strings: strings,
            isStale: self.openAIDashboardIsStale,
            sparkIsStale: self.sparkQuotaIsStale)
        guard let presentation = dashboardModel.codeReview else { return nil }
        return SummaryCardPresentation(
            valueText: "\(Int(presentation.remainingPercent.rounded()))%",
            detailText: presentation.resetText)
    }

    private func makeCreditsCardPresentation(strings: AppStrings) -> SummaryCardPresentation? {
        let dashboardModel = DashboardOverviewModel(
            snapshot: self.openAIDashboard,
            sparkPrimaryLimit: self.sparkPrimaryQuotaWindow,
            sparkSecondaryLimit: self.sparkSecondaryQuotaWindow,
            accountPlanFallback: self.openAIAccountPlanFallback,
            strings: strings,
            isStale: self.openAIDashboardIsStale,
            sparkIsStale: self.sparkQuotaIsStale)
        guard let presentation = dashboardModel.credits else { return nil }
        return SummaryCardPresentation(
            valueText: presentation.valueText,
            detailText: dashboardModel.updatedDescription ?? " ")
    }

    private func observeRefreshSettings() {
        withObservationTracking {
            _ = self.settings.refreshFrequency
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.observeRefreshSettings()
                self.startTimer()
            }
        }
    }

    private func observeDashboardSettings() {
        withObservationTracking {
            _ = self.settings.openAIWebAccessEnabled
            _ = self.settings.backgroundBrowserAutoImportEnabled
            _ = self.settings.codexCookieSource
            _ = self.settings.showRemainingQuotaCard
            _ = self.settings.showSparkQuotaCard
            _ = self.settings.showCodeReviewCard
            _ = self.settings.showCreditsCard
            _ = self.settings.showUsageBreakdownCard
            _ = self.settings.showCreditsHistoryCard
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.observeDashboardSettings()
                await self.refresh(forceDashboard: false)
            }
        }
    }

    private func observePresentationSettings() {
        withObservationTracking {
            _ = self.settings.appLanguage
            _ = self.settings.dashboardModuleOrder
            _ = self.settings.showRemainingQuotaCard
            _ = self.settings.showSparkQuotaCard
            _ = self.settings.showThirtyDayChartCard
            _ = self.settings.showRecentTwentyFourHourChartCard
            _ = self.settings.showMessageActivityCard
            _ = self.settings.showUsageOverviewCard
            _ = self.settings.showUsageOverviewNumericCard
            _ = self.settings.showTodayUsageCard
            _ = self.settings.showSevenDayUsageCard
            _ = self.settings.showThirtyDayUsageCard
            _ = self.settings.showAllTimeUsageCard
            _ = self.settings.showCodeReviewCard
            _ = self.settings.showCreditsCard
            _ = self.settings.showUsageBreakdownCard
            _ = self.settings.showCreditsHistoryCard
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.observePresentationSettings()
                self.rebuildModulePresentationsImmediately()
            }
        }
    }

    private func observeTokenSpeedSettings() {
        withObservationTracking {
            _ = self.settings.showsMenuBarTokenSpeedMeter
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.observeTokenSpeedSettings()
                self.configureTokenSpeedMonitoring()
            }
        }
    }

    private func startTimer() {
        self.refreshTask?.cancel()
        guard let interval = self.settings.refreshFrequency.interval else {
            self.refreshTask = nil
            return
        }

        self.refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(interval))
                } catch {
                    return
                }

                guard !Task.isCancelled else { return }
                await self?.refresh(forceDashboard: false)
            }
        }
    }

    private func configureTokenSpeedMonitoring() {
        self.tokenSpeedTask?.cancel()

        guard self.settings.showsMenuBarTokenSpeedMeter,
              TokenMenuSpeedMeterFeature.supportsVisualPresentation
        else {
            self.menuBarTokenSpeedMetrics = .zero
            self.recentTokenSpeedSamples = Self.makeRecentTokenSpeedTimeline(
                from: self.tokenSpeedHistoryEntries.map(Self.sample(from:)),
                endingAt: Date())
            let tokenRateMonitor = self.tokenRateMonitor
            Task {
                await tokenRateMonitor.reset()
            }
            self.tokenSpeedTask = nil
            return
        }

        self.menuBarTokenSpeedMetrics = .zero
        let tokenRateMonitor = self.tokenRateMonitor
        let tokenSpeedHistoryStore = self.tokenSpeedHistoryStore
        self.tokenSpeedTask = Task { [weak self] in
            guard let self else { return }
            await tokenRateMonitor.reset()

            while !Task.isCancelled {
                let sample = await tokenRateMonitor.sample()
                guard !Task.isCancelled else { return }

                if sample.tokens > 0 {
                    do {
                        _ = try tokenSpeedHistoryStore.upsert(sample: sample)
                    } catch {
                        self.logger.error("Failed to persist token speed sample: \(error.localizedDescription)")
                    }
                }

                await MainActor.run {
                    let previousTokensPerSecond = self.menuBarTokenSpeedMetrics.tokensPerSecond
                    self.menuBarTokenSpeedMetrics = MenuBarTokenSpeedMetrics(
                        tokensPerSecond: sample.tokens,
                        previousTokensPerSecond: previousTokensPerSecond,
                        sampleDate: sample.timestamp)
                    self.applyTokenSpeedSample(sample)
                }

                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
            }
        }
    }

    private func day(for date: Date, in days: [DailyTokenStats]) -> DailyTokenStats {
        let key = DailyTokenStats.dayKey(for: date, calendar: Calendar.current)
        return days.first(where: { $0.date == key }) ?? .empty(for: key)
    }

    private func series(dayCount: Int, from days: [DailyTokenStats]) -> [DailyTokenStats] {
        let calendar = Calendar.current
        let knownDays = Dictionary(uniqueKeysWithValues: days.map { ($0.date, $0) })
        let today = calendar.startOfDay(for: Date())

        return (0..<dayCount).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return nil
            }
            let key = DailyTokenStats.dayKey(for: day, calendar: calendar)
            return knownDays[key] ?? .empty(for: key)
        }
    }

    private func loadPersistedTokenSpeedHistory(referenceDate: Date = Date()) {
        do {
            let samples = try self.tokenSpeedHistoryStore.load().sorted { $0.timestamp > $1.timestamp }
            self.tokenSpeedHistoryEntries = samples.map(TokenSpeedHistoryEntry.init(sample:))
            self.recentTokenSpeedSamples = Self.makeRecentTokenSpeedTimeline(
                from: samples,
                endingAt: referenceDate)
        } catch {
            self.logger.error("Failed to load token speed history: \(error.localizedDescription)")
            self.tokenSpeedHistoryEntries = []
            self.recentTokenSpeedSamples = Self.makeRecentTokenSpeedTimeline(from: [], endingAt: referenceDate)
        }
    }

    private func applyTokenSpeedSample(_ sample: TokenSpeedSample) {
        self.recentTokenSpeedSamples = Self.makeRecentTokenSpeedTimeline(
            from: self.recentTokenSpeedSamples + [sample],
            endingAt: sample.timestamp)

        guard sample.tokens > 0 else { return }

        let entry = TokenSpeedHistoryEntry(sample: sample)
        if let existingIndex = self.tokenSpeedHistoryEntries.firstIndex(where: { $0.timestamp == entry.timestamp }) {
            self.tokenSpeedHistoryEntries[existingIndex] = entry
        } else {
            self.tokenSpeedHistoryEntries.append(entry)
        }
        self.tokenSpeedHistoryEntries.sort { $0.timestamp > $1.timestamp }
    }

    private static func makeRecentTokenSpeedTimeline(
        from samples: [TokenSpeedSample],
        endingAt date: Date,
        count: Int = 600)
        -> [TokenSpeedSample]
    {
        let end = TokenSpeedSample.secondStart(for: date)
        var keyedSamples: [Date: TokenSpeedSample] = [:]
        for sample in samples {
            keyedSamples[TokenSpeedSample.secondStart(for: sample.timestamp)] = sample
        }

        return (0..<count).reversed().compactMap { offset in
            guard let second = Calendar.current.date(byAdding: .second, value: -offset, to: end) else {
                return nil
            }
            return keyedSamples[second] ?? TokenSpeedSample(timestamp: second, tokens: 0)
        }
    }

    private static func sample(from entry: TokenSpeedHistoryEntry) -> TokenSpeedSample {
        TokenSpeedSample(timestamp: entry.timestamp, tokens: entry.tokens)
    }

    private func hourSeries(hourCount: Int, from hours: [HourlyTokenStats]) -> [HourlyTokenStats] {
        let calendar = Calendar.current
        guard let currentHourStart = calendar.dateInterval(of: .hour, for: Date())?.start else {
            return []
        }
        let knownHours = Dictionary(uniqueKeysWithValues: hours.map { (Int($0.hourStart.timeIntervalSince1970), $0) })

        return (0..<hourCount).reversed().compactMap { offset in
            guard let hourStart = calendar.date(byAdding: .hour, value: -offset, to: currentHourStart) else {
                return nil
            }
            let key = Int(hourStart.timeIntervalSince1970)
            return knownHours[key] ?? .empty(for: hourStart)
        }
    }

    private func outboundMessageSeries(dayCount: Int) -> [DailyOutboundMessageStats] {
        let calendar = Calendar.current
        let knownDays = Dictionary(uniqueKeysWithValues: self.outboundMessageDays.map { ($0.date, $0) })
        let today = calendar.startOfDay(for: Date())

        return (0..<dayCount).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return nil
            }
            let key = DailyTokenStats.dayKey(for: day, calendar: calendar)
            return knownDays[key] ?? .empty(for: key)
        }
    }

    private func sum(_ values: [DailyTokenStats]) -> DailyTokenStats {
        values.reduce(.empty(for: "total")) { partialResult, item in
            var result = partialResult
            result.merge(item)
            return result
        }
    }

    private static func aggregateDailyBuckets(from bucketCollections: [[DailyTokenStats]]) -> [DailyTokenStats] {
        var mergedByDay: [String: DailyTokenStats] = [:]
        for buckets in bucketCollections {
            for bucket in buckets {
                if var existing = mergedByDay[bucket.date] {
                    existing.merge(bucket)
                    mergedByDay[bucket.date] = existing
                } else {
                    mergedByDay[bucket.date] = bucket
                }
            }
        }

        return mergedByDay.values.sorted { $0.date < $1.date }
    }

    private static func aggregateHourlyBuckets(from bucketCollections: [[HourlyTokenStats]]) -> [HourlyTokenStats] {
        var mergedByHour: [Date: HourlyTokenStats] = [:]
        for buckets in bucketCollections {
            for bucket in buckets {
                if var existing = mergedByHour[bucket.hourStart] {
                    existing.merge(bucket)
                    mergedByHour[bucket.hourStart] = existing
                } else {
                    mergedByHour[bucket.hourStart] = bucket
                }
            }
        }

        return mergedByHour.values.sorted { $0.hourStart < $1.hourStart }
    }

    private func sumOutboundMessages(_ values: [DailyOutboundMessageStats]) -> DailyOutboundMessageStats {
        values.reduce(.empty(for: "total")) { partialResult, item in
            var result = partialResult
            result.merge(item)
            return result
        }
    }

    private func resetDisplayedDashboard() {
        self.openAIDashboard = nil
        self.openAIDashboardIsStale = false
        self.openAIDashboardRequiresLogin = false
        self.openAIDashboardPermissionDenied = false
        self.openAIDashboardCookieImportStatus = nil
        self.openAIDashboardCookieImportDebugLog = nil
        self.openAIDashboardDisplayState = .fresh
        self.lastOpenAIDashboardError = nil
    }

    private func resetOpenAIWebDebugLog() {
        self.openAIWebDebugLines.removeAll(keepingCapacity: true)
        self.openAIDashboardCookieImportDebugLog = nil
    }

    private func appendOpenAIWebDebug(_ message: String) {
        let singleLine = message.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !singleLine.isEmpty else { return }
        self.openAIWebDebugLines.append(singleLine)
        if self.openAIWebDebugLines.count > 240 {
            self.openAIWebDebugLines.removeFirst(self.openAIWebDebugLines.count - 240)
        }
    }

    private func flushOpenAIWebDebugLog() {
        self.openAIDashboardCookieImportDebugLog = self.openAIWebDebugLines.isEmpty
            ? nil
            : self.openAIWebDebugLines.joined(separator: "\n")
    }

    private func normalizedEmail(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value.lowercased()
    }

    private var menuBarPrimaryQuotaWindow: RateWindow? {
        let candidates = [
            self.codexQuotaSnapshot?.primary,
            self.codexQuotaSnapshot?.secondary,
        ].compactMap(\.self)

        if let exactMatch = candidates.first(where: { $0.windowMinutes == 5 * 60 }) {
            return exactMatch
        }
        return candidates.first
    }

    private var menuBarSecondaryQuotaWindow: RateWindow? {
        guard let secondary = self.codexQuotaSnapshot?.secondary else { return nil }
        guard secondary != self.menuBarPrimaryQuotaWindow else { return nil }
        return secondary
    }

    private func menuBarQuotaMetrics(
        for window: RateWindow?,
        fallbackShortLabel: String,
        fallbackSummaryLabel: String) -> MenuBarQuotaMetrics
    {
        let clampedPercent = window.map { min(max($0.remainingPercent, 0), 100) }
        let resolvedShortLabel = window.map {
            Self.compactWindowLabel(for: $0.windowMinutes ?? 5 * 60)
        } ?? fallbackShortLabel
        let resolvedSummaryLabel = window.map {
            if let windowMinutes = $0.windowMinutes {
                return self.settings.strings.durationLabel(
                    for: windowMinutes,
                    fallbackPrimary: windowMinutes == 5 * 60)
            }
            return fallbackSummaryLabel
        } ?? fallbackSummaryLabel

        return MenuBarQuotaMetrics(
            shortLabel: resolvedShortLabel,
            summaryLabel: resolvedSummaryLabel,
            percentText: clampedPercent.map { "\(Int($0.rounded()))%" } ?? "--",
            compactPercentText: clampedPercent.map { "\(Int($0.rounded()))" } ?? "--",
            fraction: clampedPercent.map { $0 / 100 })
    }

    private static func compactWindowLabel(for windowMinutes: Int) -> String {
        if windowMinutes == 5 * 60 {
            return "H"
        }

        let weekMinutes = 7 * 24 * 60
        if windowMinutes.isMultiple(of: weekMinutes) {
            let weeks = windowMinutes / weekMinutes
            return weeks == 1 ? "W" : "\(weeks)W"
        }

        let dayMinutes = 24 * 60
        if windowMinutes.isMultiple(of: dayMinutes) {
            return "\(windowMinutes / dayMinutes)D"
        }

        if windowMinutes.isMultiple(of: 60) {
            return "\(windowMinutes / 60)H"
        }

        return "\(windowMinutes)M"
    }

    static func shortTokenText(_ value: Int) -> String {
        switch value {
        case 1_000_000...:
            String(format: "%.1fm", Double(value) / 1_000_000).replacingOccurrences(of: ".0", with: "")
        case 1000...:
            String(format: "%.1fk", Double(value) / 1000).replacingOccurrences(of: ".0", with: "")
        default:
            "\(value)"
        }
    }

    nonisolated static func exactTokenText(_ value: Int, locale: Locale = .autoupdatingCurrent) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
