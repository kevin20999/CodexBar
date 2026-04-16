import Foundation

enum DashboardModule: String, CaseIterable, Codable, Sendable, Identifiable, Equatable {
    case remainingQuota
    case recentFortyEightHours
    case messageActivity
    case lastThirtyDays
    case usageOverview
    case usageOverviewNumeric
    case codeReview
    case credits
    case usageBreakdown
    case creditsHistory

    var id: String {
        self.rawValue
    }

    static var defaultOrder: [DashboardModule] {
        [
            .remainingQuota,
            .recentFortyEightHours,
            .messageActivity,
            .lastThirtyDays,
            .usageOverview,
            .usageOverviewNumeric,
            .codeReview,
            .credits,
            .usageBreakdown,
            .creditsHistory,
        ]
    }

    static func normalizedOrder(_ modules: [DashboardModule]) -> [DashboardModule] {
        var seen: Set<DashboardModule> = []
        var normalized: [DashboardModule] = []

        for module in modules where seen.insert(module).inserted {
            normalized.append(module)
        }

        for module in Self.defaultOrder where seen.insert(module).inserted {
            normalized.append(module)
        }

        return normalized
    }

    static func normalizedOrder(rawValues: [String]) -> [DashboardModule] {
        self.normalizedOrder(rawValues.compactMap(Self.init(rawValue:)))
    }

    var systemImage: String {
        switch self {
        case .remainingQuota:
            "gauge.open.with.lines.needle.33percent"
        case .recentFortyEightHours:
            "chart.line.uptrend.xyaxis"
        case .messageActivity:
            "paperplane"
        case .lastThirtyDays:
            "calendar"
        case .usageOverview:
            "sum"
        case .usageOverviewNumeric:
            "number.square"
        case .codeReview:
            "checkmark.circle"
        case .credits:
            "creditcard"
        case .usageBreakdown:
            "chart.bar.xaxis"
        case .creditsHistory:
            "clock"
        }
    }

    var isSummaryModule: Bool {
        self == .codeReview || self == .credits
    }

    @MainActor
    func title(strings: AppStrings) -> String {
        switch self {
        case .remainingQuota:
            strings.remainingQuotaTitle
        case .recentFortyEightHours:
            strings.recentFortyEightHoursTitle
        case .messageActivity:
            strings.messageActivityTitle
        case .lastThirtyDays:
            strings.lastThirtyDaysTitle
        case .usageOverview:
            strings.totalsTitle
        case .usageOverviewNumeric:
            strings.totalsNumericTitle
        case .codeReview:
            strings.codeReviewTitle
        case .credits:
            strings.quotaCreditsLabel
        case .usageBreakdown:
            strings.usageBreakdownTitle
        case .creditsHistory:
            strings.creditsHistoryTitle
        }
    }
}
