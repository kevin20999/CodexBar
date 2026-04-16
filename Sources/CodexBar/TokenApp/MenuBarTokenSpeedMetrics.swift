import Foundation

struct MenuBarTokenSpeedMetrics: Equatable, Sendable {
    let tokensPerSecond: Int
    let launchStrength: Double
    let launchDate: Date?

    static let zero = MenuBarTokenSpeedMetrics(tokensPerSecond: 0)

    init(
        tokensPerSecond: Int,
        previousTokensPerSecond: Int = 0,
        sampleDate: Date? = nil)
    {
        self.tokensPerSecond = tokensPerSecond
        self.launchStrength = Self.launchStrength(
            for: tokensPerSecond,
            previousTokensPerSecond: previousTokensPerSecond)
        self.launchDate = self.launchStrength > 0 ? sampleDate : nil
    }

    var icon: String {
        Self.menuBarIcon(for: self.tokensPerSecond)
    }

    var speedText: String {
        "\(self.tokensPerSecond) token/s"
    }

    var isActive: Bool {
        self.tokensPerSecond > 0
    }

    var displayText: String {
        "\(self.icon) \(self.speedText)"
    }

    var usesRocketIcon: Bool {
        self.tokensPerSecond > 0
    }

    var isBursting: Bool {
        self.launchStrength >= 0.66
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.tokensPerSecond == rhs.tokensPerSecond
    }

    static func menuBarIcon(for tokensPerSecond: Int) -> String {
        tokensPerSecond > 0 ? "🚀" : "☕️"
    }

    static func historyIcon(for tokensPerSecond: Int) -> String {
        switch tokensPerSecond {
        case ...0:
            "🐢"
        case 1...4:
            "🚶"
        case 5...11:
            "🐇"
        case 12...24:
            "🐆"
        case 25...39:
            "🚲"
        case 40...79:
            "🚆"
        case 80...159:
            "✈️"
        default:
            "🚀"
        }
    }

    static func launchStrength(
        for tokensPerSecond: Int,
        previousTokensPerSecond: Int)
        -> Double
    {
        guard tokensPerSecond > 0 else { return 0 }

        let positiveDelta = max(tokensPerSecond - previousTokensPerSecond, 0)
        let normalizedRise = Double(positiveDelta) / Double(max(tokensPerSecond, 1))
        let riseComponent = normalizedRise * 0.45
        let freshLaunchComponent = previousTokensPerSecond <= 0 ? 0.25 : 0
        let burstComponent = positiveDelta >= 48 ? 0.25 : 0

        return min(1, riseComponent + freshLaunchComponent + burstComponent)
    }
}
