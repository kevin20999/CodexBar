import Foundation

public enum TokenRefreshFrequency: String, CaseIterable, Codable, Sendable, Identifiable {
    case fiveSeconds
    case tenSeconds
    case fifteenSeconds
    case oneMinute
    case manual

    public var id: String {
        self.rawValue
    }

    public var interval: TimeInterval? {
        switch self {
        case .fiveSeconds:
            5
        case .tenSeconds:
            10
        case .fifteenSeconds:
            15
        case .oneMinute:
            60
        case .manual:
            nil
        }
    }
}
