import Foundation

@MainActor
enum TokenMenuSpeedMeterFeature {
    static var supportsVisualPresentationOverride: Bool?

    static var supportsVisualPresentation: Bool {
        if let supportsVisualPresentationOverride {
            return supportsVisualPresentationOverride
        }

        if #available(macOS 26, *) {
            return true
        }

        return false
    }
}
