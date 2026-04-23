import CoreGraphics
import Foundation
import SwiftUI

struct TokenSpeedRocketBurstTrigger: Hashable {
    let timestamp: Date
    let strengthBucket: Int

    init?(launchTimestamp: Date?, launchStrength: Double) {
        guard let launchTimestamp, launchStrength > 0 else { return nil }
        self.timestamp = launchTimestamp
        self.strengthBucket = Int((launchStrength * 1_000).rounded())
    }
}

struct TokenSpeedRocketBurstMotion: Equatable {
    let xOffset: CGFloat
    let yOffset: CGFloat
    let rotation: Double
    let scale: CGFloat

    static let zero = TokenSpeedRocketBurstMotion(
        xOffset: 0,
        yOffset: 0,
        rotation: 0,
        scale: 1)
}

enum TokenSpeedRocketBurstAnimator {
    static let ignitionDuration = Duration.milliseconds(140)
    static let settleDuration = Duration.milliseconds(260)
    static let returnDuration = Duration.milliseconds(220)

    static let ignitionAnimation = Animation.snappy(duration: 0.14, extraBounce: 0.16)
    static let settleAnimation = Animation.smooth(duration: 0.26)
    static let returnAnimation = Animation.smooth(duration: 0.22)

    static func clampedStrength(_ strength: Double) -> CGFloat {
        min(max(CGFloat(strength), 0.28), 1.18)
    }

    static func launchMotion(
        strength: CGFloat,
        allowsHorizontalDrift: Bool)
        -> TokenSpeedRocketBurstMotion
    {
        TokenSpeedRocketBurstMotion(
            xOffset: allowsHorizontalDrift ? (strength * 3.2) : 0,
            yOffset: -8.4 * strength,
            rotation: Double(strength * 11),
            scale: 1 + (strength * 0.11))
    }

    static func settleMotion(
        strength: CGFloat,
        allowsHorizontalDrift: Bool)
        -> TokenSpeedRocketBurstMotion
    {
        TokenSpeedRocketBurstMotion(
            xOffset: allowsHorizontalDrift ? (-strength * 0.8) : 0,
            yOffset: -2.2 * strength,
            rotation: Double(-strength * 3.4),
            scale: 1 + (strength * 0.03))
    }
}
