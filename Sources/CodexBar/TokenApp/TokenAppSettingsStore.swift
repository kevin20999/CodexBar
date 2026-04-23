import CodexBarCore
import Foundation
import Observation

typealias RefreshFrequency = TokenRefreshFrequency

enum UsageStatisticsRefreshFrequency: String, CaseIterable, Codable, Sendable, Identifiable {
    case fifteenMinutes
    case thirtyMinutes
    case sixtyMinutes
    case manual

    var id: String {
        self.rawValue
    }

    var interval: TimeInterval? {
        switch self {
        case .fifteenMinutes:
            15 * 60
        case .thirtyMinutes:
            30 * 60
        case .sixtyMinutes:
            60 * 60
        case .manual:
            nil
        }
    }
}

enum MenuBarDisplayMode: String, CaseIterable, Codable, Sendable, Identifiable {
    case todayIO
    case quota5h
    case quotaDualCompact
    case quotaDualKnockout

    var id: String {
        self.rawValue
    }
}

enum MenuBarQuotaStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case capsule
    case split
    case meter
    case outline
    case codexMinimal

    var id: String {
        self.rawValue
    }
}

enum MenuBarAppearanceOption: String, CaseIterable, Sendable, Identifiable {
    case todayIO
    case classicCapsule
    case splitBadge
    case slimMeter
    case lightOutline
    case codexMinimal
    case dualCompact
    case dualKnockout

    var id: String {
        self.rawValue
    }

    init(mode: MenuBarDisplayMode, quotaStyle: MenuBarQuotaStyle) {
        switch mode {
        case .todayIO:
            self = .todayIO
        case .quota5h:
            switch quotaStyle {
            case .capsule:
                self = .classicCapsule
            case .split:
                self = .splitBadge
            case .meter:
                self = .slimMeter
            case .outline:
                self = .lightOutline
            case .codexMinimal:
                self = .codexMinimal
            }
        case .quotaDualCompact:
            self = .dualCompact
        case .quotaDualKnockout:
            self = .dualKnockout
        }
    }

    var menuBarDisplayMode: MenuBarDisplayMode {
        switch self {
        case .todayIO:
            .todayIO
        case .classicCapsule, .splitBadge, .slimMeter, .lightOutline, .codexMinimal:
            .quota5h
        case .dualCompact:
            .quotaDualCompact
        case .dualKnockout:
            .quotaDualKnockout
        }
    }

    var selectedQuotaStyle: MenuBarQuotaStyle? {
        switch self {
        case .todayIO:
            nil
        case .classicCapsule:
            .capsule
        case .splitBadge:
            .split
        case .slimMeter:
            .meter
        case .lightOutline:
            .outline
        case .codexMinimal:
            .codexMinimal
        case .dualCompact:
            nil
        case .dualKnockout:
            nil
        }
    }

    var previewQuotaStyle: MenuBarQuotaStyle {
        self.selectedQuotaStyle ?? .capsule
    }
}

enum RemainingQuotaCardStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case glass
    case fitness

    var id: String {
        self.rawValue
    }
}

enum RecentFortyEightHourChartStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case bars
    case wave

    var id: String {
        self.rawValue
    }
}

enum MenuPanelVersion: String, CaseIterable, Codable, Sendable, Identifiable {
    case current
    case unifiedCompact

    var id: String {
        self.rawValue
    }
}

enum MenuPopupStyle: String, CaseIterable, Codable, Sendable, Identifiable {
    case liquidGlass
    case systemPopover

    var id: String {
        self.rawValue
    }
}

@MainActor
@Observable
final class SettingsStore {
    var appLanguage: AppLanguage {
        didSet { self.persistAppLanguage() }
    }

    var refreshFrequency: RefreshFrequency {
        didSet { self.persistRefreshFrequency() }
    }

    var usageStatisticsRefreshFrequency: UsageStatisticsRefreshFrequency {
        didSet { self.persistUsageStatisticsRefreshFrequency() }
    }

    var menuBarDisplayMode: MenuBarDisplayMode {
        didSet { self.persistMenuBarDisplayMode() }
    }

    var menuBarQuotaStyle: MenuBarQuotaStyle {
        didSet { self.persistMenuBarQuotaStyle() }
    }

    var showsMenuBarTokenSpeedMeter: Bool {
        didSet { self.persistShowsMenuBarTokenSpeedMeter() }
    }

    var menuBarAppearanceOption: MenuBarAppearanceOption {
        get {
            MenuBarAppearanceOption(
                mode: self.menuBarDisplayMode,
                quotaStyle: self.menuBarQuotaStyle)
        }
        set {
            self.menuBarDisplayMode = newValue.menuBarDisplayMode
            if let quotaStyle = newValue.selectedQuotaStyle {
                self.menuBarQuotaStyle = quotaStyle
            }
        }
    }

    var remainingQuotaCardStyle: RemainingQuotaCardStyle {
        didSet { self.persistRemainingQuotaCardStyle() }
    }

    var recentFortyEightHourChartStyle: RecentFortyEightHourChartStyle {
        didSet { self.persistRecentFortyEightHourChartStyle() }
    }

    var menuPanelVersion: MenuPanelVersion {
        didSet { self.persistMenuPanelVersion() }
    }

    var menuPopupStyle: MenuPopupStyle {
        didSet { self.persistMenuPopupStyle() }
    }

    var menuVisualTheme: MenuVisualTheme {
        didSet {
            MenuVisualThemeProvider.currentTheme = self.menuVisualTheme
            self.persistMenuVisualTheme()
        }
    }

    var launchAtLoginEnabled: Bool {
        didSet {
            self.persistLaunchAtLoginPreference()
            self.applyLaunchAtLoginPreference()
        }
    }

    var openAIWebAccessEnabled: Bool {
        didSet { self.persistOpenAIWebAccessEnabled() }
    }

    var backgroundBrowserAutoImportEnabled: Bool {
        didSet { self.persistBackgroundBrowserAutoImportEnabled() }
    }

    var codexCookieSource: ProviderCookieSource {
        didSet { self.persistCodexCookieSource() }
    }

    var codexCookieHeader: String {
        didSet { self.persistCodexCookieHeader() }
    }

    var showRemainingQuotaCard: Bool {
        didSet { self.persistShowRemainingQuotaCard() }
    }

    var showSparkQuotaCard: Bool {
        didSet { self.persistShowSparkQuotaCard() }
    }

    var showCodeReviewCard: Bool {
        didSet { self.persistShowCodeReviewCard() }
    }

    var showCreditsCard: Bool {
        didSet { self.persistShowCreditsCard() }
    }

    var showUsageBreakdownCard: Bool {
        didSet { self.persistShowUsageBreakdownCard() }
    }

    var showCreditsHistoryCard: Bool {
        didSet { self.persistShowCreditsHistoryCard() }
    }

    var showThirtyDayChartCard: Bool {
        didSet { self.persistShowThirtyDayChartCard() }
    }

    var showRecentTwentyFourHourChartCard: Bool {
        didSet { self.persistShowRecentTwentyFourHourChartCard() }
    }

    var showMessageActivityCard: Bool {
        didSet { self.persistShowMessageActivityCard() }
    }

    var showUsageOverviewCard: Bool {
        didSet { self.persistShowUsageOverviewCard() }
    }

    var showUsageOverviewNumericCard: Bool {
        didSet { self.persistShowUsageOverviewNumericCard() }
    }

    var showTodayUsageCard: Bool {
        didSet { self.persistShowTodayUsageCard() }
    }

    var showSevenDayUsageCard: Bool {
        didSet { self.persistShowSevenDayUsageCard() }
    }

    var showThirtyDayUsageCard: Bool {
        didSet { self.persistShowThirtyDayUsageCard() }
    }

    var showAllTimeUsageCard: Bool {
        didSet { self.persistShowAllTimeUsageCard() }
    }

    private(set) var dashboardModuleOrder: [DashboardModule]

    var launchAtLoginError: String?

    private enum Keys {
        static let appLanguage = "tokenAppLanguage"
        static let refreshFrequency = "tokenRefreshFrequency"
        static let usageStatisticsRefreshFrequency = "tokenUsageStatisticsRefreshFrequency"
        static let menuBarDisplayMode = "tokenMenuBarDisplayMode"
        static let menuBarQuotaStyle = "tokenMenuBarQuotaStyle"
        static let showsMenuBarTokenSpeedMeter = "tokenShowsMenuBarTokenSpeedMeter"
        static let remainingQuotaCardStyle = "tokenRemainingQuotaCardStyle"
        static let recentFortyEightHourChartStyle = "tokenRecentFortyEightHourChartStyle"
        static let menuPanelVersion = "tokenMenuPanelVersion"
        static let menuPopupStyle = "tokenMenuPopupStyle"
        static let menuVisualTheme = "tokenMenuVisualTheme"
        static let refreshFrequencyMigratedToOneMinute = "tokenRefreshFrequencyMigratedToOneMinute"
        static let launchAtLoginEnabled = "tokenLaunchAtLoginEnabled"
        static let openAIWebAccessEnabled = "tokenOpenAIWebAccessEnabled"
        static let backgroundBrowserAutoImportEnabled = "tokenBackgroundBrowserAutoImportEnabled"
        static let codexCookieSource = "tokenCodexCookieSource"
        static let codexCookieHeader = "tokenCodexCookieHeader"
        static let showRemainingQuotaCard = "tokenShowRemainingQuotaCard"
        static let showSparkQuotaCard = "tokenShowSparkQuotaCard"
        static let showCodeReviewCard = "tokenShowCodeReviewCard"
        static let showCreditsCard = "tokenShowCreditsCard"
        static let showUsageBreakdownCard = "tokenShowUsageBreakdownCard"
        static let showCreditsHistoryCard = "tokenShowCreditsHistoryCard"
        static let showThirtyDayChartCard = "tokenShowThirtyDayChartCard"
        static let showRecentTwentyFourHourChartCard = "tokenShowRecentTwentyFourHourChartCard"
        static let showMessageActivityCard = "tokenShowMessageActivityCard"
        static let showUsageOverviewCard = "tokenShowUsageOverviewCard"
        static let showUsageOverviewNumericCard = "tokenShowUsageOverviewNumericCard"
        static let showTodayUsageCard = "tokenShowTodayUsageCard"
        static let showSevenDayUsageCard = "tokenShowSevenDayUsageCard"
        static let showThirtyDayUsageCard = "tokenShowThirtyDayUsageCard"
        static let showAllTimeUsageCard = "tokenShowAllTimeUsageCard"
        static let dashboardModuleOrder = "tokenDashboardModuleOrder"
        static let mainPanelHeightCache = "tokenMainPanelHeightCache"
    }

    private static let maxMainPanelHeightCacheEntries = 24

    private let defaults: UserDefaults
    private let launchAtLoginManager: any LaunchAtLoginManaging
    private let preferredLanguages: @Sendable () -> [String]

    init(
        defaults: UserDefaults = .standard,
        launchAtLoginManager: any LaunchAtLoginManaging = LaunchAtLoginManager(),
        preferredLanguages: @escaping @Sendable () -> [String] = { Locale.preferredLanguages })
    {
        self.defaults = defaults
        self.launchAtLoginManager = launchAtLoginManager
        self.preferredLanguages = preferredLanguages
        self.appLanguage = Self.loadAppLanguage(defaults: defaults)
        Self.migrateRefreshFrequencyIfNeeded(defaults: defaults)
        self.refreshFrequency = Self.loadRefreshFrequency(defaults: defaults)
        self.usageStatisticsRefreshFrequency = Self.loadUsageStatisticsRefreshFrequency(defaults: defaults)
        self.menuBarDisplayMode = Self.loadDisplayMode(defaults: defaults)
        self.menuBarQuotaStyle = Self.loadMenuBarQuotaStyle(defaults: defaults)
        self.showsMenuBarTokenSpeedMeter = Self.loadBool(
            defaults: defaults,
            key: Keys.showsMenuBarTokenSpeedMeter,
            defaultValue: false)
        self.remainingQuotaCardStyle = Self.loadRemainingQuotaCardStyle(defaults: defaults)
        self.recentFortyEightHourChartStyle = Self.loadRecentFortyEightHourChartStyle(defaults: defaults)
        self.menuPanelVersion = Self.loadMenuPanelVersion(defaults: defaults)
        self.menuPopupStyle = Self.loadMenuPopupStyle(defaults: defaults)
        let loadedMenuVisualTheme = Self.loadMenuVisualTheme(defaults: defaults)
        self.menuVisualTheme = loadedMenuVisualTheme
        MenuVisualThemeProvider.currentTheme = loadedMenuVisualTheme
        let savedLaunchAtLogin = defaults.object(forKey: Keys.launchAtLoginEnabled) as? Bool
        self.launchAtLoginEnabled = savedLaunchAtLogin ?? launchAtLoginManager.isEnabled()
        self.openAIWebAccessEnabled = Self.loadOpenAIWebAccessEnabled(defaults: defaults)
        self.backgroundBrowserAutoImportEnabled = Self.loadBackgroundBrowserAutoImportEnabled(defaults: defaults)
        self.codexCookieSource = Self.loadCodexCookieSource(defaults: defaults)
        self.codexCookieHeader = defaults.string(forKey: Keys.codexCookieHeader) ?? ""
        self.showRemainingQuotaCard = Self.loadBool(
            defaults: defaults,
            key: Keys.showRemainingQuotaCard,
            defaultValue: true)
        self.showSparkQuotaCard = Self.loadBool(
            defaults: defaults,
            key: Keys.showSparkQuotaCard,
            defaultValue: true)
        self.showCodeReviewCard = Self.loadBool(defaults: defaults, key: Keys.showCodeReviewCard, defaultValue: false)
        self.showCreditsCard = Self.loadBool(defaults: defaults, key: Keys.showCreditsCard, defaultValue: false)
        self.showUsageBreakdownCard = Self.loadBool(
            defaults: defaults,
            key: Keys.showUsageBreakdownCard,
            defaultValue: false)
        self.showCreditsHistoryCard = Self.loadBool(
            defaults: defaults,
            key: Keys.showCreditsHistoryCard,
            defaultValue: false)
        self.showThirtyDayChartCard = Self.loadBool(
            defaults: defaults,
            key: Keys.showThirtyDayChartCard,
            defaultValue: true)
        self.showRecentTwentyFourHourChartCard = Self.loadBool(
            defaults: defaults,
            key: Keys.showRecentTwentyFourHourChartCard,
            defaultValue: true)
        self.showMessageActivityCard = Self.loadBool(
            defaults: defaults,
            key: Keys.showMessageActivityCard,
            defaultValue: true)
        self.showUsageOverviewCard = Self.loadBool(
            defaults: defaults,
            key: Keys.showUsageOverviewCard,
            defaultValue: true)
        self.showUsageOverviewNumericCard = Self.loadBool(
            defaults: defaults,
            key: Keys.showUsageOverviewNumericCard,
            defaultValue: false)
        self.showTodayUsageCard = Self.loadBool(defaults: defaults, key: Keys.showTodayUsageCard, defaultValue: true)
        self.showSevenDayUsageCard = Self.loadBool(
            defaults: defaults,
            key: Keys.showSevenDayUsageCard,
            defaultValue: true)
        self.showThirtyDayUsageCard = Self.loadBool(
            defaults: defaults,
            key: Keys.showThirtyDayUsageCard,
            defaultValue: true)
        self.showAllTimeUsageCard = Self.loadBool(
            defaults: defaults,
            key: Keys.showAllTimeUsageCard,
            defaultValue: true)
        self.dashboardModuleOrder = Self.loadDashboardModuleOrder(defaults: defaults)
        self.launchAtLoginError = nil
        if savedLaunchAtLogin == nil {
            defaults.set(self.launchAtLoginEnabled, forKey: Keys.launchAtLoginEnabled)
        }
    }

    var resolvedLanguage: AppLanguage {
        switch self.appLanguage {
        case .system:
            AppLanguage.resolvePreferredLanguage(self.preferredLanguages())
        case .zhHans, .en, .ja:
            self.appLanguage
        }
    }

    var strings: AppStrings {
        AppStrings(language: self.resolvedLanguage)
    }

    var openAIDashboardSettings: OpenAIDashboardSettings {
        OpenAIDashboardSettings(
            cookieSource: self.codexCookieSource,
            manualCookieHeader: self.codexCookieHeader,
            backgroundBrowserAutoImportEnabled: self.backgroundBrowserAutoImportEnabled)
    }

    private static func loadAppLanguage(defaults: UserDefaults) -> AppLanguage {
        guard let rawValue = defaults.string(forKey: Keys.appLanguage),
              let language = AppLanguage(rawValue: rawValue)
        else {
            return .system
        }
        return language
    }

    private static func loadRefreshFrequency(defaults: UserDefaults) -> RefreshFrequency {
        guard let rawValue = defaults.string(forKey: Keys.refreshFrequency),
              let frequency = RefreshFrequency(rawValue: rawValue)
        else {
            return .oneMinute
        }
        return frequency
    }

    private static func loadUsageStatisticsRefreshFrequency(defaults: UserDefaults) -> UsageStatisticsRefreshFrequency {
        guard let rawValue = defaults.string(forKey: Keys.usageStatisticsRefreshFrequency),
              let frequency = UsageStatisticsRefreshFrequency(rawValue: rawValue)
        else {
            return .thirtyMinutes
        }
        return frequency
    }

    private static func migrateRefreshFrequencyIfNeeded(defaults: UserDefaults) {
        guard !defaults.bool(forKey: Keys.refreshFrequencyMigratedToOneMinute) else {
            return
        }
        defer {
            defaults.set(true, forKey: Keys.refreshFrequencyMigratedToOneMinute)
        }

        guard let rawValue = defaults.string(forKey: Keys.refreshFrequency),
              let frequency = RefreshFrequency(rawValue: rawValue)
        else {
            return
        }

        switch frequency {
        case .fiveSeconds, .tenSeconds, .fifteenSeconds:
            defaults.set(RefreshFrequency.oneMinute.rawValue, forKey: Keys.refreshFrequency)
        case .oneMinute, .manual:
            break
        }
    }

    private static func loadDisplayMode(defaults: UserDefaults) -> MenuBarDisplayMode {
        guard let rawValue = defaults.string(forKey: Keys.menuBarDisplayMode) else {
            return .todayIO
        }
        if let mode = MenuBarDisplayMode(rawValue: rawValue) {
            return mode
        }
        switch rawValue {
        case "compact", "verbose":
            return .todayIO
        default:
            return .todayIO
        }
    }

    private static func loadOpenAIWebAccessEnabled(defaults: UserDefaults) -> Bool {
        defaults.object(forKey: Keys.openAIWebAccessEnabled) as? Bool ?? false
    }

    private static func loadBackgroundBrowserAutoImportEnabled(defaults: UserDefaults) -> Bool {
        defaults.object(forKey: Keys.backgroundBrowserAutoImportEnabled) as? Bool ?? false
    }

    private static func loadMenuBarQuotaStyle(defaults: UserDefaults) -> MenuBarQuotaStyle {
        guard let rawValue = defaults.string(forKey: Keys.menuBarQuotaStyle),
              let style = MenuBarQuotaStyle(rawValue: rawValue)
        else {
            return .capsule
        }
        return style
    }

    private static func loadRemainingQuotaCardStyle(defaults: UserDefaults) -> RemainingQuotaCardStyle {
        guard let rawValue = defaults.string(forKey: Keys.remainingQuotaCardStyle),
              let style = RemainingQuotaCardStyle(rawValue: rawValue)
        else {
            return .glass
        }
        return style
    }

    private static func loadRecentFortyEightHourChartStyle(defaults: UserDefaults) -> RecentFortyEightHourChartStyle {
        guard let rawValue = defaults.string(forKey: Keys.recentFortyEightHourChartStyle),
              let style = RecentFortyEightHourChartStyle(rawValue: rawValue)
        else {
            return .bars
        }
        return style
    }

    private static func loadMenuPanelVersion(defaults: UserDefaults) -> MenuPanelVersion {
        guard let rawValue = defaults.string(forKey: Keys.menuPanelVersion),
              let version = MenuPanelVersion(rawValue: rawValue)
        else {
            return .current
        }
        return version
    }

    private static func loadMenuPopupStyle(defaults: UserDefaults) -> MenuPopupStyle {
        guard let rawValue = defaults.string(forKey: Keys.menuPopupStyle),
              let style = MenuPopupStyle(rawValue: rawValue)
        else {
            return .liquidGlass
        }
        return style
    }

    private static func loadMenuVisualTheme(defaults: UserDefaults) -> MenuVisualTheme {
        guard let rawValue = defaults.string(forKey: Keys.menuVisualTheme),
              let theme = MenuVisualTheme(rawValue: rawValue)
        else {
            return .liquidGlassClassic
        }
        return theme
    }

    private static func loadCodexCookieSource(defaults: UserDefaults) -> ProviderCookieSource {
        guard let rawValue = defaults.string(forKey: Keys.codexCookieSource),
              let source = ProviderCookieSource(rawValue: rawValue)
        else {
            return .manual
        }
        return source
    }

    private static func loadBool(defaults: UserDefaults, key: String, defaultValue: Bool) -> Bool {
        defaults.object(forKey: key) as? Bool ?? defaultValue
    }

    private static func loadDashboardModuleOrder(defaults: UserDefaults) -> [DashboardModule] {
        let rawValues = defaults.stringArray(forKey: Keys.dashboardModuleOrder) ?? []
        return DashboardModule.normalizedOrder(rawValues: rawValues)
    }

    private func persistAppLanguage() {
        self.defaults.set(self.appLanguage.rawValue, forKey: Keys.appLanguage)
    }

    private func persistRefreshFrequency() {
        self.defaults.set(self.refreshFrequency.rawValue, forKey: Keys.refreshFrequency)
    }

    private func persistUsageStatisticsRefreshFrequency() {
        self.defaults.set(
            self.usageStatisticsRefreshFrequency.rawValue,
            forKey: Keys.usageStatisticsRefreshFrequency)
    }

    private func persistMenuBarDisplayMode() {
        self.defaults.set(self.menuBarDisplayMode.rawValue, forKey: Keys.menuBarDisplayMode)
    }

    private func persistMenuBarQuotaStyle() {
        self.defaults.set(self.menuBarQuotaStyle.rawValue, forKey: Keys.menuBarQuotaStyle)
    }

    private func persistShowsMenuBarTokenSpeedMeter() {
        self.defaults.set(self.showsMenuBarTokenSpeedMeter, forKey: Keys.showsMenuBarTokenSpeedMeter)
    }

    private func persistRemainingQuotaCardStyle() {
        self.defaults.set(self.remainingQuotaCardStyle.rawValue, forKey: Keys.remainingQuotaCardStyle)
    }

    private func persistRecentFortyEightHourChartStyle() {
        self.defaults.set(self.recentFortyEightHourChartStyle.rawValue, forKey: Keys.recentFortyEightHourChartStyle)
    }

    private func persistMenuPanelVersion() {
        self.defaults.set(self.menuPanelVersion.rawValue, forKey: Keys.menuPanelVersion)
    }

    private func persistMenuPopupStyle() {
        self.defaults.set(self.menuPopupStyle.rawValue, forKey: Keys.menuPopupStyle)
    }

    private func persistMenuVisualTheme() {
        self.defaults.set(self.menuVisualTheme.rawValue, forKey: Keys.menuVisualTheme)
    }

    private func persistLaunchAtLoginPreference() {
        self.defaults.set(self.launchAtLoginEnabled, forKey: Keys.launchAtLoginEnabled)
    }

    private func persistOpenAIWebAccessEnabled() {
        self.defaults.set(self.openAIWebAccessEnabled, forKey: Keys.openAIWebAccessEnabled)
    }

    private func persistBackgroundBrowserAutoImportEnabled() {
        self.defaults.set(
            self.backgroundBrowserAutoImportEnabled,
            forKey: Keys.backgroundBrowserAutoImportEnabled)
    }

    private func persistCodexCookieSource() {
        self.defaults.set(self.codexCookieSource.rawValue, forKey: Keys.codexCookieSource)
    }

    private func persistCodexCookieHeader() {
        self.defaults.set(self.codexCookieHeader, forKey: Keys.codexCookieHeader)
    }

    private func persistShowRemainingQuotaCard() {
        self.defaults.set(self.showRemainingQuotaCard, forKey: Keys.showRemainingQuotaCard)
    }

    private func persistShowSparkQuotaCard() {
        self.defaults.set(self.showSparkQuotaCard, forKey: Keys.showSparkQuotaCard)
    }

    private func persistShowCodeReviewCard() {
        self.defaults.set(self.showCodeReviewCard, forKey: Keys.showCodeReviewCard)
    }

    private func persistShowCreditsCard() {
        self.defaults.set(self.showCreditsCard, forKey: Keys.showCreditsCard)
    }

    private func persistShowUsageBreakdownCard() {
        self.defaults.set(self.showUsageBreakdownCard, forKey: Keys.showUsageBreakdownCard)
    }

    private func persistShowCreditsHistoryCard() {
        self.defaults.set(self.showCreditsHistoryCard, forKey: Keys.showCreditsHistoryCard)
    }

    private func persistShowThirtyDayChartCard() {
        self.defaults.set(self.showThirtyDayChartCard, forKey: Keys.showThirtyDayChartCard)
    }

    private func persistShowRecentTwentyFourHourChartCard() {
        self.defaults.set(self.showRecentTwentyFourHourChartCard, forKey: Keys.showRecentTwentyFourHourChartCard)
    }

    private func persistShowMessageActivityCard() {
        self.defaults.set(self.showMessageActivityCard, forKey: Keys.showMessageActivityCard)
    }

    private func persistShowUsageOverviewCard() {
        self.defaults.set(self.showUsageOverviewCard, forKey: Keys.showUsageOverviewCard)
    }

    private func persistShowUsageOverviewNumericCard() {
        self.defaults.set(self.showUsageOverviewNumericCard, forKey: Keys.showUsageOverviewNumericCard)
    }

    private func persistShowTodayUsageCard() {
        self.defaults.set(self.showTodayUsageCard, forKey: Keys.showTodayUsageCard)
    }

    private func persistShowSevenDayUsageCard() {
        self.defaults.set(self.showSevenDayUsageCard, forKey: Keys.showSevenDayUsageCard)
    }

    private func persistShowThirtyDayUsageCard() {
        self.defaults.set(self.showThirtyDayUsageCard, forKey: Keys.showThirtyDayUsageCard)
    }

    private func persistShowAllTimeUsageCard() {
        self.defaults.set(self.showAllTimeUsageCard, forKey: Keys.showAllTimeUsageCard)
    }

    private func persistDashboardModuleOrder() {
        self.defaults.set(self.dashboardModuleOrder.map(\.rawValue), forKey: Keys.dashboardModuleOrder)
    }

    func storedMainPanelHeight(for key: TokenMenuPanelHeightCacheKey) -> CGFloat? {
        self.mainPanelHeightCacheEntries()[key.storageKey]?.naturalHeight
    }

    func persistMainPanelHeight(_ naturalHeight: CGFloat, for key: TokenMenuPanelHeightCacheKey) {
        var entries = self.mainPanelHeightCacheEntries()
        entries[key.storageKey] = TokenMenuPanelHeightCacheEntry(
            naturalHeight: naturalHeight,
            updatedAt: Date().timeIntervalSince1970)
        self.persistMainPanelHeightCacheEntries(entries)
    }

    private func mainPanelHeightCacheEntries() -> [String: TokenMenuPanelHeightCacheEntry] {
        guard let data = self.defaults.data(forKey: Keys.mainPanelHeightCache) else {
            return [:]
        }

        return (try? JSONDecoder().decode([String: TokenMenuPanelHeightCacheEntry].self, from: data)) ?? [:]
    }

    private func persistMainPanelHeightCacheEntries(_ entries: [String: TokenMenuPanelHeightCacheEntry]) {
        let trimmedEntries: [String: TokenMenuPanelHeightCacheEntry]
        if entries.count <= Self.maxMainPanelHeightCacheEntries {
            trimmedEntries = entries
        } else {
            let retainedKeys = entries
                .sorted(by: { lhs, rhs in
                    lhs.value.updatedAt > rhs.value.updatedAt
                })
                .prefix(Self.maxMainPanelHeightCacheEntries)
                .map(\.key)
            trimmedEntries = entries.filter { retainedKeys.contains($0.key) }
        }

        guard let encoded = try? JSONEncoder().encode(trimmedEntries) else { return }
        self.defaults.set(encoded, forKey: Keys.mainPanelHeightCache)
    }

    private func applyLaunchAtLoginPreference() {
        do {
            try self.launchAtLoginManager.setEnabled(self.launchAtLoginEnabled)
            self.launchAtLoginError = nil
        } catch {
            self.launchAtLoginError = error.localizedDescription
        }
    }

    func isDashboardModuleVisible(_ module: DashboardModule) -> Bool {
        switch module {
        case .remainingQuota:
            self.showRemainingQuotaCard
        case .recentFortyEightHours:
            self.showRecentTwentyFourHourChartCard
        case .messageActivity:
            self.showMessageActivityCard
        case .lastThirtyDays:
            self.showThirtyDayChartCard
        case .usageOverview:
            self.showUsageOverviewCard
        case .usageOverviewNumeric:
            self.showUsageOverviewNumericCard
        case .codeReview:
            self.showCodeReviewCard
        case .credits:
            self.showCreditsCard
        case .usageBreakdown:
            self.showUsageBreakdownCard
        case .creditsHistory:
            self.showCreditsHistoryCard
        }
    }

    func setDashboardModuleVisible(_ isVisible: Bool, for module: DashboardModule) {
        switch module {
        case .remainingQuota:
            self.showRemainingQuotaCard = isVisible
        case .recentFortyEightHours:
            self.showRecentTwentyFourHourChartCard = isVisible
        case .messageActivity:
            self.showMessageActivityCard = isVisible
        case .lastThirtyDays:
            self.showThirtyDayChartCard = isVisible
        case .usageOverview:
            self.showUsageOverviewCard = isVisible
        case .usageOverviewNumeric:
            self.showUsageOverviewNumericCard = isVisible
        case .codeReview:
            self.showCodeReviewCard = isVisible
        case .credits:
            self.showCreditsCard = isVisible
        case .usageBreakdown:
            self.showUsageBreakdownCard = isVisible
        case .creditsHistory:
            self.showCreditsHistoryCard = isVisible
        }
    }

    func moveDashboardModules(fromOffsets: IndexSet, toOffset: Int) {
        var updated = self.dashboardModuleOrder
        let movingIndices = fromOffsets.sorted()
        let movingModules = movingIndices.map { updated[$0] }

        for index in movingIndices.reversed() {
            updated.remove(at: index)
        }

        let removedBeforeDestination = movingIndices.count(where: { $0 < toOffset })
        let destination = max(0, min(toOffset - removedBeforeDestination, updated.count))
        updated.insert(contentsOf: movingModules, at: destination)
        self.setDashboardModuleOrder(updated)
    }

    func setDashboardModuleOrder(_ modules: [DashboardModule]) {
        let normalized = DashboardModule.normalizedOrder(modules)
        guard normalized != self.dashboardModuleOrder else { return }
        self.dashboardModuleOrder = normalized
        self.persistDashboardModuleOrder()
    }
}
