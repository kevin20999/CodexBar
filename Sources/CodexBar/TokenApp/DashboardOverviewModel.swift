import CodexBarCore
import Foundation
import SwiftUI

struct QuotaProgressPresentation: Identifiable {
    enum Accent: String, Equatable, Sendable {
        case primary
        case secondary
        case review

        var color: Color {
            switch self {
            case .primary:
                TokenMenuTheme.primaryQuotaTint
            case .secondary:
                TokenMenuTheme.secondaryQuotaTint
            case .review:
                TokenMenuTheme.reviewTint
            }
        }
    }

    let title: String
    let remainingPercent: Double
    let progressFraction: Double
    let resetText: String
    let accent: Accent
    let isStale: Bool

    var id: String {
        "\(self.accent.rawValue)-\(self.title)"
    }

    var accentColor: Color {
        self.accent.color
    }
}

struct DashboardCreditsSummary {
    let title: String
    let valueText: String
}

struct DashboardOverviewModel {
    let sparkQuotaItems: [QuotaProgressPresentation]
    let codeReview: QuotaProgressPresentation?
    let credits: DashboardCreditsSummary?
    let usageBreakdown: [OpenAIDashboardDailyBreakdown]
    let creditsHistory: [OpenAIDashboardDailyBreakdown]
    let accountEmail: String?
    let accountHeaderText: String?
    let effectiveAccountPlan: String?
    let showsAccountHeader: Bool
    let updatedDescription: String?
    let sparkHasQuotaData: Bool
    let showsSparkQuotaCard: Bool

    var accountPlan: String? {
        self.effectiveAccountPlan
    }

    init(
        snapshot: OpenAIDashboardSnapshot?,
        sparkPrimaryLimit: RateWindow? = nil,
        sparkSecondaryLimit: RateWindow? = nil,
        accountPlanFallback: String? = nil,
        strings: AppStrings,
        isStale: Bool,
        sparkIsStale: Bool? = nil,
        now: Date = .init())
    {
        let effectiveAccountPlan = Self.cleanedText(snapshot?.accountPlan) ?? Self.cleanedText(accountPlanFallback)
        let resolvedSparkPrimary = sparkPrimaryLimit ?? snapshot?.sparkPrimaryLimit
        let resolvedSparkSecondary = sparkSecondaryLimit ?? snapshot?.sparkSecondaryLimit
        let resolvedSparkIsStale = sparkIsStale ?? isStale

        var sparkQuotaItems: [QuotaProgressPresentation] = []
        if let primary = resolvedSparkPrimary {
            sparkQuotaItems.append(Self.makeQuotaWindow(
                window: primary,
                title: strings.durationLabel(for: primary.windowMinutes, fallbackPrimary: true),
                accent: .primary,
                resetText: strings.quotaDetailText(for: primary, now: now),
                isStale: resolvedSparkIsStale))
        }
        if let secondary = resolvedSparkSecondary {
            sparkQuotaItems.append(Self.makeQuotaWindow(
                window: secondary,
                title: strings.durationLabel(for: secondary.windowMinutes, fallbackPrimary: false),
                accent: .secondary,
                resetText: strings.quotaDetailText(for: secondary, now: now),
                isStale: resolvedSparkIsStale))
        }

        guard let snapshot else {
            self.sparkQuotaItems = sparkQuotaItems
            self.codeReview = nil
            self.credits = nil
            self.usageBreakdown = []
            self.creditsHistory = []
            self.accountEmail = nil
            self.accountHeaderText = nil
            self.effectiveAccountPlan = effectiveAccountPlan
            self.showsAccountHeader = effectiveAccountPlan != nil
            self.updatedDescription = nil
            self.sparkHasQuotaData = !sparkQuotaItems.isEmpty
            self.showsSparkQuotaCard = !sparkQuotaItems.isEmpty
            return
        }

        self.sparkQuotaItems = sparkQuotaItems
        self.codeReview = snapshot.codeReviewRemainingPercent.map { percent in
            QuotaProgressPresentation(
                title: strings.codeReviewTitle,
                remainingPercent: percent,
                progressFraction: min(max(percent / 100, 0), 1),
                resetText: strings.updatedDescription(from: snapshot.updatedAt),
                accent: .review,
                isStale: isStale)
        }
        self.credits = snapshot.creditsRemaining.map { remaining in
            DashboardCreditsSummary(
                title: strings.quotaCreditsLabel,
                valueText: Self.formatCredits(remaining, locale: strings.locale))
        }
        self.usageBreakdown = snapshot.usageBreakdown
        self.creditsHistory = snapshot.dailyBreakdown
        self.accountEmail = Self.cleanedText(snapshot.signedInEmail)
        self.accountHeaderText = Self.accountHeaderText(from: snapshot.signedInEmail)
        self.effectiveAccountPlan = effectiveAccountPlan
        self.showsAccountHeader = self.accountEmail != nil || self.effectiveAccountPlan != nil
        self.updatedDescription = strings.updatedDescription(from: snapshot.updatedAt)
        self.sparkHasQuotaData = !sparkQuotaItems.isEmpty
        self.showsSparkQuotaCard = !sparkQuotaItems.isEmpty
    }

    private static func makeQuotaWindow(
        window: RateWindow,
        title: String,
        accent: QuotaProgressPresentation.Accent,
        resetText: String,
        isStale: Bool) -> QuotaProgressPresentation
    {
        let remainingPercent = min(max(window.remainingPercent, 0), 100)
        return QuotaProgressPresentation(
            title: title,
            remainingPercent: remainingPercent,
            progressFraction: min(max(remainingPercent / 100, 0), 1),
            resetText: resetText,
            accent: accent,
            isStale: isStale)
    }

    private static func formatCredits(_ value: Double, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? value.formatted()
    }

    private static func cleanedText(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func accountHeaderText(from value: String?) -> String? {
        guard let value = self.cleanedText(value) else { return nil }

        if let atIndex = value.firstIndex(of: "@"), atIndex > value.startIndex {
            let localPart = String(value[..<atIndex])
            return self.truncatedHeaderIdentifier(localPart)
        }

        return self.truncatedHeaderIdentifier(value)
    }

    private static func truncatedHeaderIdentifier(_ value: String) -> String {
        let maxLength = 10
        guard value.count > maxLength else { return value }
        return String(value.prefix(maxLength)) + "…"
    }
}
