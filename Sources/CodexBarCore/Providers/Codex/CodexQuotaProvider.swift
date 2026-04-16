import Foundation

public protocol CodexQuotaProviding: Sendable {
    func loadQuotaSnapshot() async throws -> UsageSnapshot
}

public struct CodexQuotaProvider: CodexQuotaProviding, Sendable {
    public init() {}

    public func loadQuotaSnapshot() async throws -> UsageSnapshot {
        var credentials = try CodexOAuthCredentialsStore.load()

        if credentials.needsRefresh, !credentials.refreshToken.isEmpty {
            credentials = try await CodexTokenRefresher.refresh(credentials)
            try CodexOAuthCredentialsStore.save(credentials)
        }

        let usage = try await CodexOAuthUsageFetcher.fetchUsage(
            accessToken: credentials.accessToken,
            accountId: credentials.accountId)

        return CodexQuotaSnapshotMapper.mapUsage(usage, credentials: credentials)
    }
}

enum CodexQuotaSnapshotMapper {
    static func mapUsage(_ response: CodexUsageResponse, credentials: CodexOAuthCredentials) -> UsageSnapshot {
        let primary = self.makeWindow(response.rateLimit?.primaryWindow)
        let secondary = self.makeWindow(response.rateLimit?.secondaryWindow)

        let identity = ProviderIdentitySnapshot(
            providerID: .codex,
            accountEmail: self.resolveAccountEmail(from: credentials),
            accountOrganization: nil,
            loginMethod: self.resolvePlan(response: response, credentials: credentials))

        return UsageSnapshot(
            primary: primary ?? RateWindow(usedPercent: 0, windowMinutes: nil, resetsAt: nil, resetDescription: nil),
            secondary: secondary,
            tertiary: nil,
            updatedAt: Date(),
            identity: identity)
    }

    static func mapCredits(_ credits: CodexUsageResponse.CreditDetails?) -> CreditsSnapshot? {
        guard let credits, let balance = credits.balance else { return nil }
        return CreditsSnapshot(remaining: balance, events: [], updatedAt: Date())
    }

    private static func makeWindow(_ window: CodexUsageResponse.WindowSnapshot?) -> RateWindow? {
        guard let window else { return nil }
        let resetDate = Date(timeIntervalSince1970: TimeInterval(window.resetAt))
        let resetDescription = UsageFormatter.resetDescription(from: resetDate)
        return RateWindow(
            usedPercent: Double(window.usedPercent),
            windowMinutes: window.limitWindowSeconds / 60,
            resetsAt: resetDate,
            resetDescription: resetDescription)
    }

    private static func resolveAccountEmail(from credentials: CodexOAuthCredentials) -> String? {
        guard let idToken = credentials.idToken,
              let payload = UsageFetcher.parseJWT(idToken)
        else {
            return nil
        }

        let profileDict = payload["https://api.openai.com/profile"] as? [String: Any]
        let email = (payload["email"] as? String) ?? (profileDict?["email"] as? String)
        return email?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func resolvePlan(response: CodexUsageResponse, credentials: CodexOAuthCredentials) -> String? {
        if let plan = response.planType?.rawValue, !plan.isEmpty { return plan }
        guard let idToken = credentials.idToken,
              let payload = UsageFetcher.parseJWT(idToken)
        else {
            return nil
        }
        let authDict = payload["https://api.openai.com/auth"] as? [String: Any]
        let plan = (authDict?["chatgpt_plan_type"] as? String) ?? (payload["chatgpt_plan_type"] as? String)
        return plan?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
