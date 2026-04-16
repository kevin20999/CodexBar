import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct CodexQuotaSnapshot: Equatable, Sendable {
    public let primary: RateWindow?
    public let secondary: RateWindow?
    public let sparkPrimary: RateWindow?
    public let sparkSecondary: RateWindow?
    public let updatedAt: Date
    public let accountEmail: String?
    public let accountPlan: String?

    public init(
        primary: RateWindow?,
        secondary: RateWindow?,
        sparkPrimary: RateWindow? = nil,
        sparkSecondary: RateWindow? = nil,
        updatedAt: Date,
        accountEmail: String?,
        accountPlan: String?)
    {
        self.primary = primary
        self.secondary = secondary
        self.sparkPrimary = sparkPrimary
        self.sparkSecondary = sparkSecondary
        self.updatedAt = updatedAt
        self.accountEmail = accountEmail
        self.accountPlan = accountPlan
    }
}

public protocol CodexQuotaProviding: Sendable {
    func loadQuotaSnapshot() async throws -> CodexQuotaSnapshot
}

public struct CodexQuotaProvider: CodexQuotaProviding, Sendable {
    public init() {}

    public func loadQuotaSnapshot() async throws -> CodexQuotaSnapshot {
        var credentials = try CodexQuotaCredentialsStore.load()

        if credentials.needsRefresh, !credentials.refreshToken.isEmpty {
            credentials = try await CodexQuotaTokenRefresher.refresh(credentials)
            try CodexQuotaCredentialsStore.save(credentials)
        }

        let usage = try await CodexQuotaUsageFetcher.fetchUsage(
            accessToken: credentials.accessToken,
            accountId: credentials.accountId)

        return CodexQuotaSnapshotMapper.mapUsage(usage, credentials: credentials)
    }
}

private struct CodexQuotaCredentials: Sendable {
    let accessToken: String
    let refreshToken: String
    let idToken: String?
    let accountId: String?
    let lastRefresh: Date?

    var needsRefresh: Bool {
        guard let lastRefresh else { return true }
        let eightDays: TimeInterval = 8 * 24 * 60 * 60
        return Date().timeIntervalSince(lastRefresh) > eightDays
    }
}

private enum CodexQuotaCredentialsError: LocalizedError, Sendable {
    case notFound
    case decodeFailed(String)
    case missingTokens

    var errorDescription: String? {
        switch self {
        case .notFound:
            "Codex auth.json not found. Run `codex` to log in."
        case let .decodeFailed(message):
            "Failed to decode Codex credentials: \(message)"
        case .missingTokens:
            "Codex auth.json exists but contains no tokens."
        }
    }
}

private enum CodexQuotaCredentialsStore {
    private static var authFilePath: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        if let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"]?.trimmingCharacters(
            in: .whitespacesAndNewlines),
            !codexHome.isEmpty
        {
            return URL(fileURLWithPath: codexHome).appendingPathComponent("auth.json")
        }
        return home.appendingPathComponent(".codex").appendingPathComponent("auth.json")
    }

    static func load() throws -> CodexQuotaCredentials {
        let url = self.authFilePath
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CodexQuotaCredentialsError.notFound
        }

        let data = try Data(contentsOf: url)
        return try self.parse(data: data)
    }

    static func save(_ credentials: CodexQuotaCredentials) throws {
        let url = self.authFilePath

        var json: [String: Any] = [:]
        if let data = try? Data(contentsOf: url),
           let existing = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            json = existing
        }

        var tokens: [String: Any] = [
            "access_token": credentials.accessToken,
            "refresh_token": credentials.refreshToken,
        ]
        if let idToken = credentials.idToken {
            tokens["id_token"] = idToken
        }
        if let accountId = credentials.accountId {
            tokens["account_id"] = accountId
        }

        json["tokens"] = tokens
        json["last_refresh"] = ISO8601DateFormatter().string(from: Date())

        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    private static func parse(data: Data) throws -> CodexQuotaCredentials {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CodexQuotaCredentialsError.decodeFailed("Invalid JSON")
        }

        if let apiKey = json["OPENAI_API_KEY"] as? String,
           !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return CodexQuotaCredentials(
                accessToken: apiKey,
                refreshToken: "",
                idToken: nil,
                accountId: nil,
                lastRefresh: nil)
        }

        guard let tokens = json["tokens"] as? [String: Any] else {
            throw CodexQuotaCredentialsError.missingTokens
        }
        guard let accessToken = tokens["access_token"] as? String,
              let refreshToken = tokens["refresh_token"] as? String,
              !accessToken.isEmpty
        else {
            throw CodexQuotaCredentialsError.missingTokens
        }

        let idToken = tokens["id_token"] as? String
        let accountId = tokens["account_id"] as? String
        let lastRefresh = self.parseLastRefresh(from: json["last_refresh"])

        return CodexQuotaCredentials(
            accessToken: accessToken,
            refreshToken: refreshToken,
            idToken: idToken,
            accountId: accountId,
            lastRefresh: lastRefresh)
    }

    private static func parseLastRefresh(from raw: Any?) -> Date? {
        guard let value = raw as? String, !value.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

private enum CodexQuotaTokenRefresher {
    private static let refreshEndpoint = URL(string: "https://auth.openai.com/oauth/token")!
    private static let clientID = "app_EMoamEEZ73f0CkXaXp7hrann"

    enum RefreshError: LocalizedError, Sendable {
        case expired
        case revoked
        case reused
        case networkError(Error)
        case invalidResponse(String)

        var errorDescription: String? {
            switch self {
            case .expired:
                "Refresh token expired. Please run `codex` to log in again."
            case .revoked:
                "Refresh token was revoked. Please run `codex` to log in again."
            case .reused:
                "Refresh token was already used. Please run `codex` to log in again."
            case let .networkError(error):
                "Network error during token refresh: \(error.localizedDescription)"
            case let .invalidResponse(message):
                "Invalid refresh response: \(message)"
            }
        }
    }

    static func refresh(_ credentials: CodexQuotaCredentials) async throws -> CodexQuotaCredentials {
        guard !credentials.refreshToken.isEmpty else {
            return credentials
        }

        var request = URLRequest(url: Self.refreshEndpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "client_id": Self.clientID,
            "grant_type": "refresh_token",
            "refresh_token": credentials.refreshToken,
            "scope": "openid profile email",
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw RefreshError.invalidResponse("No HTTP response")
            }

            if http.statusCode == 401 {
                if let errorCode = Self.extractErrorCode(from: data) {
                    switch errorCode.lowercased() {
                    case "refresh_token_expired": throw RefreshError.expired
                    case "refresh_token_reused": throw RefreshError.reused
                    case "refresh_token_invalidated": throw RefreshError.revoked
                    default: throw RefreshError.expired
                    }
                }
                throw RefreshError.expired
            }

            guard http.statusCode == 200 else {
                throw RefreshError.invalidResponse("Status \(http.statusCode)")
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw RefreshError.invalidResponse("Invalid JSON")
            }

            let newAccessToken = json["access_token"] as? String ?? credentials.accessToken
            let newRefreshToken = json["refresh_token"] as? String ?? credentials.refreshToken
            let newIdToken = json["id_token"] as? String ?? credentials.idToken

            return CodexQuotaCredentials(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
                idToken: newIdToken,
                accountId: credentials.accountId,
                lastRefresh: Date())
        } catch let error as RefreshError {
            throw error
        } catch {
            throw RefreshError.networkError(error)
        }
    }

    private static func extractErrorCode(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        if let error = json["error"] as? [String: Any], let code = error["code"] as? String { return code }
        if let error = json["error"] as? String { return error }
        return json["code"] as? String
    }
}

private struct CodexQuotaUsageResponse: Decodable, Sendable {
    let planType: PlanType?
    let rateLimit: RateLimitDetails?
    let additionalRateLimits: [AdditionalRateLimit]?

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case rateLimit = "rate_limit"
        case additionalRateLimits = "additional_rate_limits"
    }

    enum PlanType: Sendable, Decodable, Equatable {
        case guest
        case free
        case go
        case plus
        case pro
        case freeWorkspace
        case team
        case business
        case education
        case quorum
        case k12
        case enterprise
        case edu
        case unknown(String)

        var rawValue: String {
            switch self {
            case .guest: "guest"
            case .free: "free"
            case .go: "go"
            case .plus: "plus"
            case .pro: "pro"
            case .freeWorkspace: "free_workspace"
            case .team: "team"
            case .business: "business"
            case .education: "education"
            case .quorum: "quorum"
            case .k12: "k12"
            case .enterprise: "enterprise"
            case .edu: "edu"
            case let .unknown(value): value
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            switch value {
            case "guest": self = .guest
            case "free": self = .free
            case "go": self = .go
            case "plus": self = .plus
            case "pro": self = .pro
            case "free_workspace": self = .freeWorkspace
            case "team": self = .team
            case "business": self = .business
            case "education": self = .education
            case "quorum": self = .quorum
            case "k12": self = .k12
            case "enterprise": self = .enterprise
            case "edu": self = .edu
            default: self = .unknown(value)
            }
        }
    }

    struct RateLimitDetails: Decodable, Sendable {
        let primaryWindow: WindowSnapshot?
        let secondaryWindow: WindowSnapshot?

        enum CodingKeys: String, CodingKey {
            case primaryWindow = "primary_window"
            case secondaryWindow = "secondary_window"
        }
    }

    struct WindowSnapshot: Decodable, Sendable {
        let usedPercent: Int
        let resetAt: Int
        let limitWindowSeconds: Int

        enum CodingKeys: String, CodingKey {
            case usedPercent = "used_percent"
            case resetAt = "reset_at"
            case limitWindowSeconds = "limit_window_seconds"
        }
    }

    struct AdditionalRateLimit: Decodable, Sendable {
        let limitName: String?
        let meteredFeature: String?
        let rateLimit: RateLimitDetails?

        enum CodingKeys: String, CodingKey {
            case limitName = "limit_name"
            case meteredFeature = "metered_feature"
            case rateLimit = "rate_limit"
        }
    }
}

private enum CodexQuotaUsageFetcher {
    private static let defaultChatGPTBaseURL = "https://chatgpt.com/backend-api/"
    private static let chatGPTUsagePath = "/wham/usage"
    private static let codexUsagePath = "/api/codex/usage"

    static func fetchUsage(accessToken: String, accountId: String?) async throws -> CodexQuotaUsageResponse {
        var request = URLRequest(url: Self.resolveUsageURL())
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("CodexTokenBar", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let accountId, !accountId.isEmpty {
            request.setValue(accountId, forHTTPHeaderField: "ChatGPT-Account-Id")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CodexQuotaFetchError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            do {
                return try JSONDecoder().decode(CodexQuotaUsageResponse.self, from: data)
            } catch {
                throw CodexQuotaFetchError.invalidResponse
            }
        case 401, 403:
            throw CodexQuotaFetchError.unauthorized
        default:
            let body = String(data: data, encoding: .utf8)
            throw CodexQuotaFetchError.serverError(http.statusCode, body)
        }
    }

    private static func resolveUsageURL() -> URL {
        let baseURL = self.resolveChatGPTBaseURL(env: ProcessInfo.processInfo.environment)
        let normalized = self.normalizeChatGPTBaseURL(baseURL)
        let path = normalized.contains("/backend-api") ? Self.chatGPTUsagePath : Self.codexUsagePath
        let full = normalized + path
        return URL(string: full) ?? URL(string: Self.defaultChatGPTBaseURL + Self.chatGPTUsagePath)!
    }

    private static func resolveChatGPTBaseURL(env: [String: String]) -> String {
        guard let contents = self.loadConfigContents(env: env),
              let parsed = self.parseChatGPTBaseURL(from: contents)
        else {
            return self.defaultChatGPTBaseURL
        }
        return parsed
    }

    private static func normalizeChatGPTBaseURL(_ value: String) -> String {
        var trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { trimmed = self.defaultChatGPTBaseURL }
        while trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        if trimmed.hasPrefix("https://chatgpt.com") || trimmed.hasPrefix("https://chat.openai.com"),
           !trimmed.contains("/backend-api")
        {
            trimmed += "/backend-api"
        }
        return trimmed
    }

    private static func parseChatGPTBaseURL(from contents: String) -> String? {
        for rawLine in contents.split(whereSeparator: \.isNewline) {
            let line = rawLine.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: true).first
            let trimmed = line?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            guard key == "chatgpt_base_url" else { continue }
            var value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            if value.hasPrefix("\""), value.hasSuffix("\"") {
                value = String(value.dropFirst().dropLast())
            } else if value.hasPrefix("'"), value.hasSuffix("'") {
                value = String(value.dropFirst().dropLast())
            }
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    private static func loadConfigContents(env: [String: String]) -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let codexHome = env["CODEX_HOME"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let root = (codexHome?.isEmpty == false) ? URL(fileURLWithPath: codexHome!) : home
            .appendingPathComponent(".codex")
        let url = root.appendingPathComponent("config.toml")
        return try? String(contentsOf: url, encoding: .utf8)
    }
}

private enum CodexQuotaFetchError: LocalizedError, Sendable {
    case unauthorized
    case invalidResponse
    case serverError(Int, String?)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Codex OAuth token expired or invalid. Run `codex` to re-authenticate."
        case .invalidResponse:
            return "Invalid response from Codex usage API."
        case let .serverError(code, message):
            if let message, !message.isEmpty {
                return "Codex API error \(code): \(message)"
            }
            return "Codex API error \(code)."
        }
    }
}

private enum CodexQuotaSnapshotMapper {
    static func mapUsage(
        _ response: CodexQuotaUsageResponse,
        credentials: CodexQuotaCredentials)
        -> CodexQuotaSnapshot
    {
        let accountInfo = self.accountInfo(from: credentials, response: response)
        let sparkRateLimit = response.additionalRateLimits?.first(where: self.isSparkRateLimit)?.rateLimit
        return CodexQuotaSnapshot(
            primary: self.makeWindow(response.rateLimit?.primaryWindow),
            secondary: self.makeWindow(response.rateLimit?.secondaryWindow),
            sparkPrimary: self.makeWindow(sparkRateLimit?.primaryWindow),
            sparkSecondary: self.makeWindow(sparkRateLimit?.secondaryWindow),
            updatedAt: Date(),
            accountEmail: accountInfo.email,
            accountPlan: accountInfo.plan)
    }

    fileprivate static func makeWindow(_ window: CodexQuotaUsageResponse.WindowSnapshot?) -> RateWindow? {
        guard let window else { return nil }
        let resetDate = Date(timeIntervalSince1970: TimeInterval(window.resetAt))
        return RateWindow(
            usedPercent: Double(window.usedPercent),
            windowMinutes: window.limitWindowSeconds / 60,
            resetsAt: resetDate,
            resetDescription: UsageFormatter.resetDescription(from: resetDate))
    }

    fileprivate static func isSparkRateLimit(_ value: CodexQuotaUsageResponse.AdditionalRateLimit) -> Bool {
        if let limitName = value.limitName?.trimmingCharacters(in: .whitespacesAndNewlines),
           limitName.caseInsensitiveCompare("gpt-5.3-codex-spark") == .orderedSame
        {
            return true
        }

        if let meteredFeature = value.meteredFeature?.trimmingCharacters(in: .whitespacesAndNewlines),
           meteredFeature.caseInsensitiveCompare("codex_bengalfox") == .orderedSame
        {
            return true
        }

        return false
    }

    private static func accountInfo(
        from credentials: CodexQuotaCredentials,
        response: CodexQuotaUsageResponse)
        -> CodexAccountInfo
    {
        let email: String?
        let plan: String?

        if let idToken = credentials.idToken,
           let payload = CodexAuthAccountReader.parseJWT(idToken)
        {
            let authDict = payload["https://api.openai.com/auth"] as? [String: Any]
            let profileDict = payload["https://api.openai.com/profile"] as? [String: Any]
            email = ((payload["email"] as? String) ?? (profileDict?["email"] as? String))?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            plan = ((authDict?["chatgpt_plan_type"] as? String) ?? (payload["chatgpt_plan_type"] as? String))?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            email = nil
            plan = nil
        }

        let resolvedPlan = response.planType?.rawValue ?? plan
        return CodexAccountInfo(email: email, plan: resolvedPlan)
    }
}

#if DEBUG
extension CodexQuotaProvider {
    static func debugSnapshot(
        fromUsageResponseData data: Data,
        accountEmail: String? = nil,
        accountPlan: String? = nil) throws -> CodexQuotaSnapshot
    {
        let response = try JSONDecoder().decode(CodexQuotaUsageResponse.self, from: data)
        return CodexQuotaSnapshot(
            primary: CodexQuotaSnapshotMapper.makeWindow(response.rateLimit?.primaryWindow),
            secondary: CodexQuotaSnapshotMapper.makeWindow(response.rateLimit?.secondaryWindow),
            sparkPrimary: CodexQuotaSnapshotMapper.makeWindow(
                response.additionalRateLimits?.first(where: CodexQuotaSnapshotMapper.isSparkRateLimit)?.rateLimit?
                    .primaryWindow),
            sparkSecondary: CodexQuotaSnapshotMapper.makeWindow(
                response.additionalRateLimits?.first(where: CodexQuotaSnapshotMapper.isSparkRateLimit)?.rateLimit?
                    .secondaryWindow),
            updatedAt: Date(),
            accountEmail: accountEmail,
            accountPlan: accountPlan ?? response.planType?.rawValue)
    }
}
#endif
