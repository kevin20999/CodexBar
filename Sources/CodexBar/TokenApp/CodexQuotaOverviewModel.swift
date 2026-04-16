import CodexBarCore
import Foundation

struct CodexQuotaOverviewModel {
    let quotaItems: [QuotaProgressPresentation]
    let accountEmail: String?
    let accountHeaderText: String?
    let accountPlan: String?
    let updatedDescription: String?
    let hasQuotaData: Bool

    init(snapshot: CodexQuotaSnapshot?, strings: AppStrings, now: Date = .init()) {
        guard let snapshot else {
            self.quotaItems = []
            self.accountEmail = nil
            self.accountHeaderText = nil
            self.accountPlan = nil
            self.updatedDescription = nil
            self.hasQuotaData = false
            return
        }

        var quotaItems: [QuotaProgressPresentation] = []
        if let primary = snapshot.primary {
            quotaItems.append(Self.makeQuotaWindow(
                window: primary,
                title: strings.durationLabel(for: primary.windowMinutes, fallbackPrimary: true),
                accent: .primary,
                resetText: strings.quotaDetailText(for: primary, now: now)))
        }
        if let secondary = snapshot.secondary {
            quotaItems.append(Self.makeQuotaWindow(
                window: secondary,
                title: strings.durationLabel(for: secondary.windowMinutes, fallbackPrimary: false),
                accent: .secondary,
                resetText: strings.quotaDetailText(for: secondary, now: now)))
        }

        let accountEmail = Self.cleanedText(snapshot.accountEmail)
        let accountPlan = Self.cleanedPlan(snapshot.accountPlan)

        self.quotaItems = quotaItems
        self.accountEmail = accountEmail
        self.accountHeaderText = Self.accountHeaderText(from: accountEmail)
        self.accountPlan = accountPlan
        self.updatedDescription = strings.updatedDescription(from: snapshot.updatedAt)
        self.hasQuotaData = !quotaItems.isEmpty
    }

    private static func makeQuotaWindow(
        window: RateWindow,
        title: String,
        accent: QuotaProgressPresentation.Accent,
        resetText: String)
        -> QuotaProgressPresentation
    {
        let remainingPercent = min(max(window.remainingPercent, 0), 100)
        return QuotaProgressPresentation(
            title: title,
            remainingPercent: remainingPercent,
            progressFraction: min(max(remainingPercent / 100, 0), 1),
            resetText: resetText,
            accent: accent,
            isStale: false)
    }

    private static func cleanedText(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }

    private static func cleanedPlan(_ value: String?) -> String? {
        guard let value = self.cleanedText(value) else { return nil }
        return UsageFormatter.cleanPlanName(value)
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
