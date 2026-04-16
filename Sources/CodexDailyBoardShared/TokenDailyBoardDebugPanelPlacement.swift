import CoreGraphics

package enum TokenDailyBoardDebugPanelPlacementRules {
    package static let defaultPanelSize = CGSize(width: 320, height: 520)
    package static let initialHorizontalSpacing: CGFloat = 16

    package static func initialFrame(
        nearMainWindow mainWindowFrame: CGRect,
        panelSize: CGSize = Self.defaultPanelSize,
        visibleFrame: CGRect)
        -> CGRect
    {
        let preferredOrigin = CGPoint(
            x: mainWindowFrame.maxX + self.initialHorizontalSpacing,
            y: min(
                max(mainWindowFrame.maxY - panelSize.height, visibleFrame.minY),
                visibleFrame.maxY - panelSize.height))
        return self.restoredFrame(
            savedOrigin: preferredOrigin,
            panelSize: panelSize,
            visibleFrame: visibleFrame)
    }

    package static func restoredFrame(
        savedOrigin: CGPoint,
        panelSize: CGSize = Self.defaultPanelSize,
        visibleFrame: CGRect)
        -> CGRect
    {
        let maxX = max(visibleFrame.minX, visibleFrame.maxX - panelSize.width)
        let maxY = max(visibleFrame.minY, visibleFrame.maxY - panelSize.height)
        let clampedOrigin = CGPoint(
            x: min(max(savedOrigin.x, visibleFrame.minX), maxX).rounded(),
            y: min(max(savedOrigin.y, visibleFrame.minY), maxY).rounded())
        return CGRect(origin: clampedOrigin, size: panelSize)
    }
}

package enum TokenDailyBoardDebugPanelPresentationRules {
    package static func shouldRemainAvailable(
        displayMode: TokenDailyBoardDisplayMode,
        titlebarControlsCollapsed: Bool)
        -> Bool
    {
        TokenDailyBoardConversationOnlyDebugRules.shouldShowPositionDebugger(for: displayMode)
            && !titlebarControlsCollapsed
    }
}
