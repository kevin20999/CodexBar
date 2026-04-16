import Foundation

public enum ProviderCookieSource: String, CaseIterable, Identifiable, Sendable, Codable {
    case auto
    case safari
    case manual
    case off

    public var id: String {
        self.rawValue
    }

    public var displayName: String {
        switch self {
        case .auto: "Auto"
        case .safari: "Safari"
        case .manual: "Manual"
        case .off: "Off"
        }
    }

    public var isEnabled: Bool {
        switch self {
        case .off: false
        case .auto, .safari, .manual: true
        }
    }
}
