import AppKit
import Foundation

public enum CodexDailyDockIconAnimationRules {
    public static let targetIconSize: CGFloat = 256

    public static func variantSlots(from slots: [CodexDailyAvatarResolvedSlot]) -> [CodexDailyAvatarResolvedSlot] {
        slots
            .filter { $0.slot.variantIndex != nil && $0.image != nil }
            .sorted { lhs, rhs in
                (lhs.slot.variantIndex ?? Int.min) < (rhs.slot.variantIndex ?? Int.min)
            }
    }
}
