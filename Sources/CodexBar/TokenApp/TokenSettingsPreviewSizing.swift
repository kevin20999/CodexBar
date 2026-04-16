import CoreGraphics

struct TokenSettingsPreviewSizing: Equatable {
    let naturalPanelHeight: CGFloat
    let maxDisplayedHeight: CGFloat
    let visibleUnscaledHeight: CGFloat
    let allowsScrolling: Bool

    init(naturalPanelHeight: CGFloat?, availableDisplayHeight: CGFloat, scale: CGFloat) {
        let availableDisplayHeight = max(availableDisplayHeight, 0)
        let scale = max(scale, 0)

        guard let measuredNaturalPanelHeight = naturalPanelHeight else {
            let visibleUnscaledHeight: CGFloat = if scale > 0, availableDisplayHeight > 0 {
                availableDisplayHeight / scale
            } else {
                0
            }

            self.naturalPanelHeight = visibleUnscaledHeight
            self.maxDisplayedHeight = availableDisplayHeight
            self.visibleUnscaledHeight = visibleUnscaledHeight
            self.allowsScrolling = false
            return
        }

        let naturalPanelHeight = max(measuredNaturalPanelHeight, 0)
        let naturalDisplayedHeight = naturalPanelHeight * scale
        let maxDisplayedHeight = min(naturalDisplayedHeight, availableDisplayHeight)
        let visibleUnscaledHeight: CGFloat = if scale > 0, maxDisplayedHeight > 0 {
            min(naturalPanelHeight, maxDisplayedHeight / scale)
        } else {
            0
        }

        self.naturalPanelHeight = naturalPanelHeight
        self.maxDisplayedHeight = maxDisplayedHeight
        self.visibleUnscaledHeight = visibleUnscaledHeight
        self.allowsScrolling = visibleUnscaledHeight + 0.5 < naturalPanelHeight
    }
}
