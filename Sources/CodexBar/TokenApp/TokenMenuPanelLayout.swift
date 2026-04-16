import CoreGraphics
import Foundation

enum TokenMenuContentSection: Equatable, Hashable {
    case remainingQuota
    case messageActivity
    case thirtyDayChart
    case recentTwentyFourHourChart
    case usageOverview
    case usageOverviewNumeric
    case codeReview
    case credits
    case summaryPair(first: DashboardModule, second: DashboardModule)
    case usageBreakdown
    case creditsHistory
    case footer
}

struct TokenMenuContentLayoutState: Equatable {
    let sections: [TokenMenuContentSection]

    init(
        orderedModules: [DashboardModule],
        showsRemainingQuotaCard: Bool,
        showsThirtyDayChartCard: Bool,
        showsRecentTwentyFourHourChartCard: Bool,
        showsMessageActivityCard: Bool,
        showsUsageOverviewCard: Bool,
        showsUsageOverviewNumericCard: Bool,
        usageOverviewRowCount: Int,
        showsCodeReviewCard: Bool,
        showsCreditsCard: Bool,
        showsUsageBreakdownCard: Bool,
        showsCreditsHistoryCard: Bool,
        previewMode: Bool)
    {
        let visibleModules = orderedModules.filter { module in
            switch module {
            case .remainingQuota:
                showsRemainingQuotaCard
            case .recentFortyEightHours:
                showsRecentTwentyFourHourChartCard
            case .messageActivity:
                showsMessageActivityCard
            case .lastThirtyDays:
                showsThirtyDayChartCard
            case .usageOverview:
                showsUsageOverviewCard && usageOverviewRowCount > 0
            case .usageOverviewNumeric:
                showsUsageOverviewNumericCard
            case .codeReview:
                showsCodeReviewCard
            case .credits:
                showsCreditsCard
            case .usageBreakdown:
                showsUsageBreakdownCard
            case .creditsHistory:
                showsCreditsHistoryCard
            }
        }

        var sections: [TokenMenuContentSection] = []
        var index = 0

        while index < visibleModules.count {
            let module = visibleModules[index]

            if module.isSummaryModule,
               index + 1 < visibleModules.count
            {
                let nextModule = visibleModules[index + 1]
                if nextModule.isSummaryModule, nextModule != module {
                    sections.append(.summaryPair(first: module, second: nextModule))
                    index += 2
                    continue
                }
            }

            switch module {
            case .remainingQuota:
                sections.append(.remainingQuota)
            case .recentFortyEightHours:
                sections.append(.recentTwentyFourHourChart)
            case .messageActivity:
                sections.append(.messageActivity)
            case .lastThirtyDays:
                sections.append(.thirtyDayChart)
            case .usageOverview:
                sections.append(.usageOverview)
            case .usageOverviewNumeric:
                sections.append(.usageOverviewNumeric)
            case .codeReview:
                sections.append(.codeReview)
            case .credits:
                sections.append(.credits)
            case .usageBreakdown:
                sections.append(.usageBreakdown)
            case .creditsHistory:
                sections.append(.creditsHistory)
            }
            index += 1
        }

        if !previewMode {
            sections.append(.footer)
        }

        self.sections = sections
    }

    var showsRemainingQuotaCard: Bool {
        self.sections.contains(.remainingQuota)
    }

    var showsThirtyDayChartCard: Bool {
        self.sections.contains(.thirtyDayChart)
    }

    var showsUsageOverviewCard: Bool {
        self.sections.contains(.usageOverview)
    }

    var showsUsageOverviewNumericCard: Bool {
        self.sections.contains(.usageOverviewNumeric)
    }

    var showsRecentTwentyFourHourChartCard: Bool {
        self.sections.contains(.recentTwentyFourHourChart)
    }

    var showsFooterBar: Bool {
        self.sections.contains(.footer)
    }
}

struct TokenMenuPanelSizing: Equatable {
    static let screenMargin: CGFloat = 120

    let naturalHeight: CGFloat
    let displayHeight: CGFloat
    let allowsScrolling: Bool

    static func resolve(
        naturalHeight: CGFloat,
        availableScreenHeight: CGFloat?,
        screenMargin: CGFloat = Self.screenMargin)
        -> TokenMenuPanelSizing
    {
        let normalizedNaturalHeight = max(naturalHeight.rounded(.up), 0)
        guard let availableScreenHeight else {
            return TokenMenuPanelSizing(
                naturalHeight: normalizedNaturalHeight,
                displayHeight: normalizedNaturalHeight,
                allowsScrolling: false)
        }

        let maxDisplayHeight = max((availableScreenHeight - screenMargin).rounded(.down), 1)
        let displayHeight = min(normalizedNaturalHeight, maxDisplayHeight)
        return TokenMenuPanelSizing(
            naturalHeight: normalizedNaturalHeight,
            displayHeight: displayHeight,
            allowsScrolling: normalizedNaturalHeight > maxDisplayHeight)
    }
}

struct TokenMenuPanelHeightCacheKey: Equatable, Hashable {
    let menuPanelVersion: String
    let menuPopupStyle: String
    let sections: [TokenMenuContentSection]
    let usageOverviewRowCount: Int
    let showsSparkQuotaCard: Bool

    var storageKey: String {
        let sectionIdentity = self.sections.map(Self.identityToken(for:)).joined(separator: ",")
        return [
            self.menuPanelVersion,
            self.menuPopupStyle,
            sectionIdentity,
            "\(self.usageOverviewRowCount)",
            self.showsSparkQuotaCard ? "spark" : "no-spark",
        ]
            .joined(separator: "|")
    }

    private static func identityToken(for section: TokenMenuContentSection) -> String {
        switch section {
        case .remainingQuota:
            "remaining-quota"
        case .messageActivity:
            "message-activity"
        case .thirtyDayChart:
            "thirty-day-chart"
        case .recentTwentyFourHourChart:
            "recent-forty-eight-hour-chart"
        case .usageOverview:
            "usage-overview"
        case .usageOverviewNumeric:
            "usage-overview-numeric"
        case .codeReview:
            "code-review"
        case .credits:
            "credits"
        case let .summaryPair(first, second):
            "summary-\(first.rawValue)-\(second.rawValue)"
        case .usageBreakdown:
            "usage-breakdown"
        case .creditsHistory:
            "credits-history"
        case .footer:
            "footer"
        }
    }
}

struct TokenMenuPanelHeightCacheEntry: Codable, Equatable {
    let naturalHeight: CGFloat
    let updatedAt: TimeInterval
}

struct TokenMenuPanelLayoutSignature: Equatable {
    let heightCacheKey: TokenMenuPanelHeightCacheKey
    let menuPanelVersion: String
    let menuPopupStyle: String
    let sections: [TokenMenuContentSection]
    let usageOverviewRowCount: Int
    let showsSparkQuotaCard: Bool
    let hasCodexQuotaData: Bool
    let sparkHasQuotaData: Bool
    let showsDashboardError: Bool
    let showsHistoryError: Bool

    var renderPhaseIdentity: String {
        [
            self.heightCacheKey.storageKey,
            self.hasCodexQuotaData ? "quota" : "no-quota",
            self.sparkHasQuotaData ? "spark-quota" : "no-spark-quota",
            self.showsDashboardError ? "dashboard-error" : "dashboard-ok",
            self.showsHistoryError ? "history-error" : "history-ok",
        ]
            .joined(separator: "|")
    }
}

struct TokenMenuPanelSizingCache: Equatable {
    let heightCacheKey: TokenMenuPanelHeightCacheKey
    let naturalHeight: CGFloat
}

enum TokenMenuPanelOpenKind: String, Equatable {
    case coldOpen = "cold-open"
    case warmReopen = "warm-reopen"
}

enum TokenMenuPanelRenderPhaseResolver {
    static func openKind(
        signature: TokenMenuPanelLayoutSignature,
        warmedSignature: TokenMenuPanelLayoutSignature?)
        -> TokenMenuPanelOpenKind
    {
        warmedSignature == signature ? .warmReopen : .coldOpen
    }

    static func renderPhaseMode(
        signature: TokenMenuPanelLayoutSignature,
        warmedSignature: TokenMenuPanelLayoutSignature?)
        -> MenuContent.TokenMenuPanelRenderPhaseMode
    {
        switch self.openKind(signature: signature, warmedSignature: warmedSignature) {
        case .coldOpen:
            .coldStart(signatureIdentity: signature.renderPhaseIdentity)
        case .warmReopen:
            .warmed
        }
    }
}
