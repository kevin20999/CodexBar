import Foundation

public struct CodexAccountInfo: Equatable, Sendable {
    public let email: String?
    public let plan: String?

    public init(email: String?, plan: String?) {
        self.email = email
        self.plan = plan
    }
}

public protocol CodexAuthAccountReading: Sendable {
    func loadAccountInfo() -> CodexAccountInfo
}

public struct CodexAuthAccountReader: CodexAuthAccountReading {
    private let environment: [String: String]

    public init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        self.environment = environment
    }

    public func loadAccountInfo() -> CodexAccountInfo {
        let home = self.environment["CODEX_HOME"] ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex")
            .path
        let authURL = URL(fileURLWithPath: home).appendingPathComponent("auth.json")

        guard let data = try? Data(contentsOf: authURL),
              let auth = try? JSONDecoder().decode(AuthFile.self, from: data),
              let idToken = auth.tokens?.idToken,
              let payload = Self.parseJWT(idToken)
        else {
            return CodexAccountInfo(email: nil, plan: nil)
        }

        let authDict = payload["https://api.openai.com/auth"] as? [String: Any]
        let profileDict = payload["https://api.openai.com/profile"] as? [String: Any]
        let plan = (authDict?["chatgpt_plan_type"] as? String)
            ?? (payload["chatgpt_plan_type"] as? String)
        let email = (payload["email"] as? String)
            ?? (profileDict?["email"] as? String)

        return CodexAccountInfo(
            email: email?.trimmingCharacters(in: .whitespacesAndNewlines),
            plan: plan?.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func parseJWT(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }

        var padded = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while padded.count % 4 != 0 {
            padded.append("=")
        }

        guard let data = Data(base64Encoded: padded),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        return json
    }
}

private struct AuthFile: Decodable {
    struct Tokens: Decodable {
        let idToken: String?

        private enum CodingKeys: String, CodingKey {
            case idToken = "id_token"
        }
    }

    let tokens: Tokens?
}
