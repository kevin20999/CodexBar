import AppKit
import CodexBarCore
import SwiftUI

extension Notification.Name {
    fileprivate static let codexDailyNarrativeCustomize = Notification.Name("CodexDailyNarrativeCustomize")
}

@MainActor
public enum TokenDailyBoardWindowLayout {
    static let defaultWidthRatio: CGFloat = 0.88
    static let minimumWidthRatio: CGFloat = 0.20
    static let fixedLayoutMinimumWidth: CGFloat = 640
    static let maximumWidth: CGFloat = 1800
    static let conversationOnlyWidth: CGFloat =
        TokenDailyBoardConversationOnlyLayoutRules.defaultCompactWindowSize.width
    static let defaultHeight: CGFloat = 764
    static let minimumHeight: CGFloat = 680
    static let conversationOnlyHeight: CGFloat =
        TokenDailyBoardConversationOnlyLayoutRules.defaultCompactWindowSize.height
    static let conversationAndTodayHeight: CGFloat = 392
    static let fallbackVisibleFrame = CGRect(x: 0, y: 0, width: 1440, height: 900)

    public static func minimumWidth(for visibleFrame: CGRect) -> CGFloat {
        max(
            (visibleFrame.width * self.minimumWidthRatio).rounded(.toNearestOrAwayFromZero),
            self.fixedLayoutMinimumWidth)
    }

    public static func resolvedVisibleFrame(for window: NSWindow?) -> CGRect {
        window?.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? self.fallbackVisibleFrame
    }

    public static func defaultSize(for visibleFrame: CGRect) -> CGSize {
        self.defaultSize(for: visibleFrame, displayMode: .fullBoard)
    }

    public static func defaultSize(for visibleFrame: CGRect, displayMode: TokenDailyBoardDisplayMode) -> CGSize {
        self.defaultSize(
            for: visibleFrame,
            displayMode: displayMode,
            tuning: self.defaultConversationOnlyTuning())
    }

    package static func defaultSize(
        for visibleFrame: CGRect,
        displayMode: TokenDailyBoardDisplayMode,
        tuning: TokenDailyBoardConversationOnlyDebugTuning)
        -> CGSize
    {
        if displayMode == .conversationOnly {
            return self.fixedConversationOnlySize(for: visibleFrame, tuning: tuning)
        }

        let minimumWidth = self.minimumWidth(for: visibleFrame)
        let resolvedWidth = min(
            max((visibleFrame.width * self.defaultWidthRatio).rounded(.toNearestOrAwayFromZero), minimumWidth),
            min(self.maximumWidth, visibleFrame.width))
        return CGSize(width: resolvedWidth, height: self.targetHeight(for: displayMode, visibleFrame: visibleFrame))
    }

    public static func centeredFrame(for windowFrame: CGRect, in visibleFrame: CGRect) -> CGRect {
        let x = min(
            max(visibleFrame.midX - (windowFrame.width / 2), visibleFrame.minX),
            visibleFrame.maxX - windowFrame.width)
        let y = min(
            max(visibleFrame.midY - (windowFrame.height / 2), visibleFrame.minY),
            visibleFrame.maxY - windowFrame.height)

        return CGRect(origin: CGPoint(x: x.rounded(), y: y.rounded()), size: windowFrame.size)
    }

    package static func restoredFrame(
        for windowFrame: CGRect,
        savedOrigin: CGPoint,
        in visibleFrame: CGRect)
        -> CGRect
    {
        let maxX = max(visibleFrame.minX, visibleFrame.maxX - windowFrame.width)
        let maxY = max(visibleFrame.minY, visibleFrame.maxY - windowFrame.height)
        let clampedOrigin = CGPoint(
            x: min(max(savedOrigin.x, visibleFrame.minX), maxX).rounded(),
            y: min(max(savedOrigin.y, visibleFrame.minY), maxY).rounded())
        return CGRect(origin: clampedOrigin, size: windowFrame.size)
    }

    public static func configureWindow(
        _ window: NSWindow,
        title: String,
        initialSize: CGSize,
        displayMode: TokenDailyBoardDisplayMode = .fullBoard)
    {
        self.configureWindow(
            window,
            title: title,
            initialSize: initialSize,
            displayMode: displayMode,
            tuning: self.defaultConversationOnlyTuning())
    }

    package static func configureWindow(
        _ window: NSWindow,
        title: String,
        initialSize: CGSize,
        displayMode: TokenDailyBoardDisplayMode,
        tuning: TokenDailyBoardConversationOnlyDebugTuning)
    {
        window.title = title
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.toolbar = nil
        window.setContentSize(initialSize)
        self.applyWindowSizingBehavior(
            for: displayMode,
            to: window,
            visibleFrame: self.resolvedVisibleFrame(for: window),
            tuning: tuning)
        window.collectionBehavior = []
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        self.styleSystemWindowButtons(window, displayMode: displayMode)
    }

    public static func minimumHeight(for displayMode: TokenDailyBoardDisplayMode, visibleFrame: CGRect) -> CGFloat {
        let maximumHeight = max(visibleFrame.height - 36, 220)
        let target = switch displayMode {
        case .conversationOnly:
            self.fixedConversationOnlySize(
                for: visibleFrame,
                tuning: self.defaultConversationOnlyTuning()).height
        case .conversationAndToday:
            self.conversationAndTodayHeight
        case .fullBoard:
            self.minimumHeight
        }
        return min(target, maximumHeight)
    }

    public static func targetHeight(for displayMode: TokenDailyBoardDisplayMode, visibleFrame: CGRect) -> CGFloat {
        let maximumHeight = max(visibleFrame.height - 36, 220)
        let target = switch displayMode {
        case .conversationOnly:
            self.fixedConversationOnlySize(
                for: visibleFrame,
                tuning: self.defaultConversationOnlyTuning()).height
        case .conversationAndToday:
            self.conversationAndTodayHeight
        case .fullBoard:
            max(self.defaultHeight, self.minimumHeight)
        }
        return min(target, maximumHeight)
    }

    public static func updateMinimumSize(
        for window: NSWindow,
        displayMode: TokenDailyBoardDisplayMode = .fullBoard)
    {
        self.updateMinimumSize(
            for: window,
            displayMode: displayMode,
            tuning: self.defaultConversationOnlyTuning())
    }

    package static func updateMinimumSize(
        for window: NSWindow,
        displayMode: TokenDailyBoardDisplayMode,
        tuning: TokenDailyBoardConversationOnlyDebugTuning)
    {
        let visibleFrame = self.resolvedVisibleFrame(for: window)
        self.applyWindowSizingBehavior(
            for: displayMode,
            to: window,
            visibleFrame: visibleFrame,
            tuning: tuning)
    }

    public static func applyDisplayMode(
        _ displayMode: TokenDailyBoardDisplayMode,
        to window: NSWindow,
        animated: Bool)
    {
        self.applyDisplayMode(
            displayMode,
            to: window,
            animated: animated,
            tuning: self.defaultConversationOnlyTuning())
    }

    package static func applyDisplayMode(
        _ displayMode: TokenDailyBoardDisplayMode,
        to window: NSWindow,
        animated: Bool,
        tuning: TokenDailyBoardConversationOnlyDebugTuning)
    {
        let visibleFrame = self.resolvedVisibleFrame(for: window)
        let wasConversationOnlyLocked = self.isConversationOnlyLocked(window, visibleFrame: visibleFrame)
        self.applyWindowSizingBehavior(
            for: displayMode,
            to: window,
            visibleFrame: visibleFrame,
            tuning: tuning)

        let targetSize: CGSize
        switch displayMode {
        case .conversationOnly:
            targetSize = self.fixedConversationOnlySize(for: visibleFrame, tuning: tuning)
        case .conversationAndToday, .fullBoard:
            let defaultWidth = self.defaultSize(
                for: visibleFrame,
                displayMode: displayMode,
                tuning: tuning).width
            targetSize = CGSize(
                width: wasConversationOnlyLocked
                    ? defaultWidth
                    : max(window.frame.width, self.minimumWidth(for: visibleFrame)),
                height: self.targetHeight(for: displayMode, visibleFrame: visibleFrame))
        }

        if displayMode == .conversationOnly {
            let frame = self.centeredFrame(
                for: CGRect(origin: window.frame.origin, size: targetSize),
                in: visibleFrame)
            window.setFrame(frame.integral, display: true, animate: animated)
        } else {
            var frame = window.frame
            let topEdge = frame.maxY
            frame.size = targetSize
            frame.origin.x = min(max(frame.origin.x, visibleFrame.minX), visibleFrame.maxX - frame.size.width)
            frame.origin.y = min(
                max(topEdge - targetSize.height, visibleFrame.minY),
                visibleFrame.maxY - frame.size.height)
            window.setFrame(frame.integral, display: true, animate: animated)
        }
        self.styleSystemWindowButtons(window, displayMode: displayMode)
    }

    private static func resolvedConversationOnlyWidth(
        for visibleFrame: CGRect,
        tuning: TokenDailyBoardConversationOnlyDebugTuning)
        -> CGFloat
    {
        let naturalWidth = TokenDailyBoardConversationOnlyLayoutRules.compactWindowSize(for: tuning).width
        let manualWidth = TokenDailyBoardConversationOnlyDebugRules.resolvedWindowWidth(
            tuning.windowWidth,
            visibleFrameWidth: visibleFrame.width)
        return min(max(manualWidth, naturalWidth), visibleFrame.width)
    }

    private static func resolvedConversationOnlyHeight(
        for visibleFrame: CGRect,
        tuning: TokenDailyBoardConversationOnlyDebugTuning)
        -> CGFloat
    {
        min(TokenDailyBoardConversationOnlyLayoutRules.compactWindowSize(for: tuning).height, visibleFrame.height)
    }

    private static func fixedConversationOnlySize(
        for visibleFrame: CGRect,
        tuning: TokenDailyBoardConversationOnlyDebugTuning)
        -> CGSize
    {
        CGSize(
            width: self.resolvedConversationOnlyWidth(for: visibleFrame, tuning: tuning),
            height: self.resolvedConversationOnlyHeight(for: visibleFrame, tuning: tuning))
    }

    private static func applyWindowSizingBehavior(
        for displayMode: TokenDailyBoardDisplayMode,
        to window: NSWindow,
        visibleFrame: CGRect,
        tuning: TokenDailyBoardConversationOnlyDebugTuning)
    {
        switch displayMode {
        case .conversationOnly:
            let fixedSize = self.fixedConversationOnlySize(for: visibleFrame, tuning: tuning)
            window.styleMask.remove(.resizable)
            window.minSize = fixedSize
            window.maxSize = fixedSize
        case .conversationAndToday, .fullBoard:
            window.styleMask.insert(.resizable)
            window.minSize = CGSize(
                width: self.minimumWidth(for: visibleFrame),
                height: self.minimumHeight(for: displayMode, visibleFrame: visibleFrame))
            window.maxSize = CGSize(
                width: min(self.maximumWidth, visibleFrame.width),
                height: max(visibleFrame.height - 36, self.defaultHeight))
        }
    }

    private static func isConversationOnlyLocked(_ window: NSWindow, visibleFrame: CGRect) -> Bool {
        _ = visibleFrame
        return abs(window.minSize.width - window.maxSize.width) < 0.001
            && abs(window.minSize.height - window.maxSize.height) < 0.001
    }

    private static func defaultConversationOnlyTuning() -> TokenDailyBoardConversationOnlyDebugTuning {
        TokenDailyBoardConversationOnlyDebugRules.defaultTuning
    }

    package static func styleSystemWindowButtons(
        _ window: NSWindow,
        displayMode: TokenDailyBoardDisplayMode,
        isChromeVisible: Bool = true,
        animated: Bool = false)
    {
        let closeButton = window.standardWindowButton(.closeButton)
        let miniButton = window.standardWindowButton(.miniaturizeButton)
        let zoomButton = window.standardWindowButton(.zoomButton)
        let resolvedAlpha = TokenDailyBoardTitlebarAutoHideRules.trafficLightAlpha(
            displayMode: displayMode,
            windowChromeVisible: isChromeVisible)

        zoomButton?.isHidden = true
        zoomButton?.isEnabled = false
        zoomButton?.alphaValue = 0

        let buttons = [closeButton, miniButton].compactMap(\.self)
        for button in buttons {
            button.contentTintColor = TokenDailyBoardWindowChromeStyleRules.trafficLightTintColor
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                for button in buttons {
                    button.animator().alphaValue = resolvedAlpha
                }
            }
        } else {
            for button in buttons {
                button.alphaValue = resolvedAlpha
            }
        }
    }

    public static func chromeMetrics(for window: NSWindow) -> TokenDailyBoardWindowChromeMetrics {
        let buttons = [
            window.standardWindowButton(.closeButton),
            window.standardWindowButton(.miniaturizeButton),
            window.standardWindowButton(.zoomButton),
        ].compactMap(\.self).filter { !$0.isHidden }
        let leadingInset =
            buttons.map(\.frame.maxX).max().map { $0 + 16 } ?? TokenDailyBoardWindowChromeMetrics.fallbackLeadingInset
        let buttonDiameter =
            buttons.map { max($0.frame.width, $0.frame.height) }.max()
            ?? TokenDailyBoardWindowChromeMetrics.fallbackButtonDiameter
        return TokenDailyBoardWindowChromeMetrics(
            titleLeadingInset: leadingInset,
            buttonDiameter: buttonDiameter)
    }
}

public struct TokenDailyBoardWindowChromeMetrics: Equatable {
    public static let fallbackLeadingInset: CGFloat = 72
    public static let fallbackButtonDiameter: CGFloat = 14

    public let titleLeadingInset: CGFloat
    public let buttonDiameter: CGFloat

    public init(titleLeadingInset: CGFloat, buttonDiameter: CGFloat = Self.fallbackButtonDiameter) {
        self.titleLeadingInset = titleLeadingInset
        self.buttonDiameter = buttonDiameter
    }
}

package enum TokenDailyBoardWindowChromeStyleRules {
    package static let trailingInsetMinimum: CGFloat = 12
    package static let trailingInsetMaximum: CGFloat = 24
    package static let trailingInsetWidthFactor: CGFloat = 0.02
    package static let selectedModeButtonOpacity: Double = 0.46
    package static let unselectedModeButtonOpacity: Double = 0.18
    package static let actionButtonOpacity: Double = 0.14
    package static let toggleButtonOpacity: Double = 0.22
    package static let hoverFillOpacity: Double = 0.10
    package static let pressedFillOpacity: Double = 0.16
    package static let hoverStrokeOpacity: Double = 0.14
    package static let pressedScale: CGFloat = 0.985
    package static let trafficLightAlpha: CGFloat = 0.40
    package static let trafficLightTintColor = NSColor.tertiaryLabelColor

    package static func trailingInset(for windowWidth: CGFloat) -> CGFloat {
        min(
            max(windowWidth * self.trailingInsetWidthFactor, self.trailingInsetMinimum),
            self.trailingInsetMaximum)
    }

    package static func modeButtonOpacity(isSelected: Bool) -> Double {
        isSelected ? self.selectedModeButtonOpacity : self.unselectedModeButtonOpacity
    }
}

package struct TokenDailyBoardTitlebarAccessoryLayoutMetrics: Equatable {
    package let toggleSlotWidth: CGFloat
    package let clusterButtonCount: Int
    package let clusterButtonSpacing: CGFloat
    package let clusterTrackWidth: CGFloat
    package let clusterWidth: CGFloat
    package let clusterTrailingSpacing: CGFloat
    package let toggleAnchorX: CGFloat
    package let clusterRevealCollapsedWidth: CGFloat
    package let clusterRevealExpandedWidth: CGFloat
    package let contentWidth: CGFloat
    package let accessoryWidth: CGFloat
}

package enum TokenDailyBoardTitlebarAccessoryLayoutRules {
    package static let loadingPlaceholderWidth: CGFloat = 1
    package static let toggleToClusterSpacing: CGFloat = 10
    package static let clusterButtonSpacing: CGFloat = 6
    package static let conversationOnlyExpandedButtonCount = 6
    package static let standardExpandedButtonCount = 3

    package static var maximumExpandedButtonCount: Int {
        max(self.conversationOnlyExpandedButtonCount, self.standardExpandedButtonCount)
    }

    package static func expandedButtonCount(for displayMode: TokenDailyBoardDisplayMode) -> Int {
        TokenDailyBoardConversationOnlyDebugRules.shouldShowPositionDebugger(for: displayMode)
            ? self.conversationOnlyExpandedButtonCount
            : self.standardExpandedButtonCount
    }

    package static func metrics(
        for displayMode: TokenDailyBoardDisplayMode,
        isReady: Bool,
        buttonDiameter: CGFloat,
        trailingInset: CGFloat)
        -> TokenDailyBoardTitlebarAccessoryLayoutMetrics
    {
        guard isReady else {
            return TokenDailyBoardTitlebarAccessoryLayoutMetrics(
                toggleSlotWidth: buttonDiameter,
                clusterButtonCount: 0,
                clusterButtonSpacing: self.clusterButtonSpacing,
                clusterTrackWidth: 0,
                clusterWidth: 0,
                clusterTrailingSpacing: 0,
                toggleAnchorX: 0,
                clusterRevealCollapsedWidth: 0,
                clusterRevealExpandedWidth: 0,
                contentWidth: self.loadingPlaceholderWidth,
                accessoryWidth: self.loadingPlaceholderWidth + trailingInset)
        }

        let clusterButtonCount = self.expandedButtonCount(for: displayMode)
        let clusterTrackWidth = (CGFloat(self.maximumExpandedButtonCount) * buttonDiameter)
            + (CGFloat(max(self.maximumExpandedButtonCount - 1, 0)) * self.clusterButtonSpacing)
        let clusterWidth = (CGFloat(clusterButtonCount) * buttonDiameter)
            + (CGFloat(max(clusterButtonCount - 1, 0)) * self.clusterButtonSpacing)
        let contentWidth = buttonDiameter + self.toggleToClusterSpacing + clusterTrackWidth
        return TokenDailyBoardTitlebarAccessoryLayoutMetrics(
            toggleSlotWidth: buttonDiameter,
            clusterButtonCount: clusterButtonCount,
            clusterButtonSpacing: self.clusterButtonSpacing,
            clusterTrackWidth: clusterTrackWidth,
            clusterWidth: clusterWidth,
            clusterTrailingSpacing: self.toggleToClusterSpacing,
            toggleAnchorX: contentWidth - buttonDiameter,
            clusterRevealCollapsedWidth: 0,
            clusterRevealExpandedWidth: clusterWidth,
            contentWidth: contentWidth,
            accessoryWidth: contentWidth + trailingInset)
    }
}

package enum TokenDailyBoardWindowPinRules {
    package static func level(
        for displayMode: TokenDailyBoardDisplayMode,
        isConversationOnlyPinned: Bool)
        -> NSWindow.Level
    {
        displayMode == .conversationOnly && isConversationOnlyPinned ? .floating : .normal
    }
}

package enum TokenDailyBoardTitlebarAutoHideRules {
    package static let delayedAutoHideDelay: Duration = .seconds(3)

    package static func shouldUseDelayedAutoHide(displayMode: TokenDailyBoardDisplayMode) -> Bool {
        displayMode == .conversationOnly
    }

    package static func resolvedChromeVisibility(
        displayMode: TokenDailyBoardDisplayMode,
        isWindowHovered: Bool,
        windowChromeVisible: Bool)
        -> Bool
    {
        guard self.shouldUseDelayedAutoHide(displayMode: displayMode) else { return true }
        return isWindowHovered || windowChromeVisible
    }

    package static func shouldShowAccessory(
        displayMode: TokenDailyBoardDisplayMode,
        isWindowHovered: Bool,
        windowChromeVisible: Bool)
        -> Bool
    {
        self.resolvedChromeVisibility(
            displayMode: displayMode,
            isWindowHovered: isWindowHovered,
            windowChromeVisible: windowChromeVisible)
    }

    package static func effectiveExpandedClusterHitTesting(
        displayMode: TokenDailyBoardDisplayMode,
        isWindowHovered: Bool,
        windowChromeVisible: Bool,
        titlebarControlsCollapsed: Bool)
        -> Bool
    {
        self.shouldShowAccessory(
            displayMode: displayMode,
            isWindowHovered: isWindowHovered,
            windowChromeVisible: windowChromeVisible)
            && !titlebarControlsCollapsed
    }

    package static func trafficLightAlpha(
        displayMode: TokenDailyBoardDisplayMode,
        windowChromeVisible: Bool)
        -> CGFloat
    {
        self.shouldUseDelayedAutoHide(displayMode: displayMode) && !windowChromeVisible
            ? 0
            : TokenDailyBoardWindowChromeStyleRules.trafficLightAlpha
    }
}

enum TokenDailyBoardAlignmentRules {
    static let contentInset: CGFloat = 24
    static let dateColumnWidth: CGFloat = 160
    static let dataColumnWidth: CGFloat = 320
    static let sectionColumnSpacing: CGFloat = 24
    static let chartHorizontalInset: CGFloat = 0
}

struct TokenDailyBoardResponsiveMetrics: Equatable {
    enum Tier: Equatable {
        case wide
        case medium
        case compact
    }

    static let wideThresholdWidth: CGFloat = 1040
    static let mediumThresholdWidth: CGFloat = 720

    private struct TierConfiguration {
        let fontScale: CGFloat
        let contentInset: CGFloat
        let dateColumnWidth: CGFloat
        let dataColumnWidth: CGFloat
        let sectionColumnSpacing: CGFloat
        let sectionSpacing: CGFloat
        let heroVerticalPadding: CGFloat
        let secondaryVerticalPadding: CGFloat
        let compactVerticalPadding: CGFloat
        let heroChartHeight: CGFloat
        let secondaryChartHeight: CGFloat
        let compactChartHeight: CGFloat
        let hourLabelWidth: CGFloat
        let hourRulerHeight: CGFloat
        let monthPagerOuterSpacing: CGFloat
        let monthPagerMonthSpacing: CGFloat
        let monthPagerFontScale: CGFloat
        let chromeTopPadding: CGFloat
    }

    let containerWidth: CGFloat
    let tier: Tier
    let fontScale: CGFloat
    let contentInset: CGFloat
    let dateColumnWidth: CGFloat
    let dataColumnWidth: CGFloat
    let sectionColumnSpacing: CGFloat
    let sectionSpacing: CGFloat
    let heroVerticalPadding: CGFloat
    let secondaryVerticalPadding: CGFloat
    let compactVerticalPadding: CGFloat
    let heroChartHeight: CGFloat
    let secondaryChartHeight: CGFloat
    let compactChartHeight: CGFloat
    let hourLabelWidth: CGFloat
    let hourRulerHeight: CGFloat
    let monthPagerOuterSpacing: CGFloat
    let monthPagerMonthSpacing: CGFloat
    let monthPagerFontScale: CGFloat
    let chromeTopPadding: CGFloat

    init(containerWidth: CGFloat) {
        let clampedWidth = max(containerWidth, 1)
        let tier = Self.tier(for: clampedWidth)
        let configuration = Self.configuration(for: tier)

        self.containerWidth = clampedWidth
        self.tier = tier
        self.fontScale = configuration.fontScale
        self.contentInset = configuration.contentInset
        self.dateColumnWidth = configuration.dateColumnWidth
        self.dataColumnWidth = configuration.dataColumnWidth
        self.sectionColumnSpacing = configuration.sectionColumnSpacing
        self.sectionSpacing = configuration.sectionSpacing
        self.heroVerticalPadding = configuration.heroVerticalPadding
        self.secondaryVerticalPadding = configuration.secondaryVerticalPadding
        self.compactVerticalPadding = configuration.compactVerticalPadding
        self.heroChartHeight = configuration.heroChartHeight
        self.secondaryChartHeight = configuration.secondaryChartHeight
        self.compactChartHeight = configuration.compactChartHeight
        self.hourLabelWidth = configuration.hourLabelWidth
        self.hourRulerHeight = configuration.hourRulerHeight
        self.monthPagerOuterSpacing = configuration.monthPagerOuterSpacing
        self.monthPagerMonthSpacing = configuration.monthPagerMonthSpacing
        self.monthPagerFontScale = configuration.monthPagerFontScale
        self.chromeTopPadding = configuration.chromeTopPadding
    }

    func scaled(_ style: TokenDailyBoardTextStyle) -> TokenDailyBoardTextStyle {
        style.scaled(by: self.fontScale)
    }

    static func tier(for width: CGFloat) -> Tier {
        if width >= self.wideThresholdWidth {
            return .wide
        }
        if width >= self.mediumThresholdWidth {
            return .medium
        }
        return .compact
    }

    private static func configuration(for tier: Tier) -> TierConfiguration {
        switch tier {
        case .wide:
            TierConfiguration(
                fontScale: 1,
                contentInset: TokenDailyBoardAlignmentRules.contentInset,
                dateColumnWidth: TokenDailyBoardAlignmentRules.dateColumnWidth,
                dataColumnWidth: TokenDailyBoardAlignmentRules.dataColumnWidth,
                sectionColumnSpacing: TokenDailyBoardAlignmentRules.sectionColumnSpacing,
                sectionSpacing: TokenDailyBoardLayout.sectionSpacing,
                heroVerticalPadding: TokenDailyBoardLayout.heroVerticalPadding,
                secondaryVerticalPadding: TokenDailyBoardLayout.secondaryVerticalPadding,
                compactVerticalPadding: TokenDailyBoardLayout.compactVerticalPadding,
                heroChartHeight: TokenDailyBoardLayout.heroChartHeight,
                secondaryChartHeight: TokenDailyBoardLayout.secondaryChartHeight,
                compactChartHeight: TokenDailyBoardLayout.compactChartHeight,
                hourLabelWidth: TokenDailyBoardLayout.hourLabelWidth,
                hourRulerHeight: TokenDailyBoardLayout.hourRulerHeight,
                monthPagerOuterSpacing: 12,
                monthPagerMonthSpacing: 8,
                monthPagerFontScale: 1,
                chromeTopPadding: 2)
        case .medium:
            TierConfiguration(
                fontScale: 1,
                contentInset: TokenDailyBoardAlignmentRules.contentInset,
                dateColumnWidth: TokenDailyBoardAlignmentRules.dateColumnWidth,
                dataColumnWidth: TokenDailyBoardAlignmentRules.dataColumnWidth,
                sectionColumnSpacing: TokenDailyBoardAlignmentRules.sectionColumnSpacing,
                sectionSpacing: TokenDailyBoardLayout.sectionSpacing,
                heroVerticalPadding: TokenDailyBoardLayout.heroVerticalPadding,
                secondaryVerticalPadding: TokenDailyBoardLayout.secondaryVerticalPadding,
                compactVerticalPadding: TokenDailyBoardLayout.compactVerticalPadding,
                heroChartHeight: TokenDailyBoardLayout.heroChartHeight,
                secondaryChartHeight: TokenDailyBoardLayout.secondaryChartHeight,
                compactChartHeight: TokenDailyBoardLayout.compactChartHeight,
                hourLabelWidth: TokenDailyBoardLayout.hourLabelWidth,
                hourRulerHeight: TokenDailyBoardLayout.hourRulerHeight,
                monthPagerOuterSpacing: 12,
                monthPagerMonthSpacing: 8,
                monthPagerFontScale: 1,
                chromeTopPadding: 2)
        case .compact:
            TierConfiguration(
                fontScale: 1,
                contentInset: TokenDailyBoardAlignmentRules.contentInset,
                dateColumnWidth: TokenDailyBoardAlignmentRules.dateColumnWidth,
                dataColumnWidth: TokenDailyBoardAlignmentRules.dataColumnWidth,
                sectionColumnSpacing: TokenDailyBoardAlignmentRules.sectionColumnSpacing,
                sectionSpacing: TokenDailyBoardLayout.sectionSpacing,
                heroVerticalPadding: TokenDailyBoardLayout.heroVerticalPadding,
                secondaryVerticalPadding: TokenDailyBoardLayout.secondaryVerticalPadding,
                compactVerticalPadding: TokenDailyBoardLayout.compactVerticalPadding,
                heroChartHeight: TokenDailyBoardLayout.heroChartHeight,
                secondaryChartHeight: TokenDailyBoardLayout.secondaryChartHeight,
                compactChartHeight: TokenDailyBoardLayout.compactChartHeight,
                hourLabelWidth: TokenDailyBoardLayout.hourLabelWidth,
                hourRulerHeight: TokenDailyBoardLayout.hourRulerHeight,
                monthPagerOuterSpacing: 12,
                monthPagerMonthSpacing: 8,
                monthPagerFontScale: 1,
                chromeTopPadding: 2)
        }
    }
}

private struct TokenDailyBoardResponsiveMetricsEnvironmentKey: EnvironmentKey {
    static let defaultValue = TokenDailyBoardResponsiveMetrics(
        containerWidth: TokenDailyBoardResponsiveMetrics.wideThresholdWidth)
}

// swiftformat:disable all
extension EnvironmentValues {
    var tokenDailyBoardResponsiveMetrics: TokenDailyBoardResponsiveMetrics {
        get { self[TokenDailyBoardResponsiveMetricsEnvironmentKey.self] }
        set { self[TokenDailyBoardResponsiveMetricsEnvironmentKey.self] = newValue }
    }
}
// swiftformat:enable all

private enum TokenDailyBoardLayout {
    static let windowHorizontalPadding: CGFloat = 0
    static let windowVerticalPadding: CGFloat = 0
    static let titleBarTopPadding: CGFloat = 0
    static let titleBarHiddenTopPadding: CGFloat = 8
    static let narrativeOverlayTopInset: CGFloat = -8
    static let conversationModeContentTopInset: CGFloat =
        TokenDailyBoardNarrativeSizingRules.railHeight + 12
    static let conversationModeBottomInset: CGFloat = 16
    static let conversationOnlyPanelInset: CGFloat = 0
    static let conversationOnlyTopInset: CGFloat = 28
    static let conversationOnlyOuterInset: CGFloat = 21
    static let conversationOnlyPanelMinWidth: CGFloat = 720
    static let conversationOnlyPanelMaxWidth: CGFloat = 1080
    static let contentSpacing: CGFloat = 18
    static let sectionSpacing: CGFloat = 28
    static let secondarySpacing: CGFloat = 0
    static let compactRowSpacing: CGFloat = 0
    static let glassSurfaceSpacing: CGFloat = 26
    static let boardPanelTopInset: CGFloat = 58
    static let boardPanelChromeTopInset: CGFloat = 18
    static let boardPanelBottomInset: CGFloat = 16
    static let boardPanelCornerRadius: CGFloat = 56
    static let heroCornerRadius: CGFloat = 34
    static let secondaryCornerRadius: CGFloat = 24
    static let compactCornerRadius: CGFloat = 18
    static let secondaryVerticalPadding: CGFloat = 20
    static let heroVerticalPadding: CGFloat = 24
    static let compactVerticalPadding: CGFloat = 14
    static let heroChartHeight: CGFloat = 104
    static let secondaryChartHeight: CGFloat = 68
    static let compactChartHeight: CGFloat = 36
    static let chartTopInset: CGFloat = 10
    static let chartHorizontalInset: CGFloat = TokenDailyBoardAlignmentRules.chartHorizontalInset
    static let hourRulerHeight: CGFloat = 16
    static let hourLabelWidth: CGFloat = 34
    static let titleFontSize: CGFloat = 16
    static let statusFontSize: CGFloat = 10
    static let fiveMinuteBucketsPerDay = 24 * 12
    static let chartGuides = [0, 6, 12, 18, 24]
    static let sectionDividerOpacity: Double = 0.12
    static let sectionDividerThickness: CGFloat = 0.75
}

enum TokenDailyBoardConversationOnlyLayoutRules {
    static let contentWidth: CGFloat = 583
    static let contentHeight: CGFloat = 93
    static let compactWindowEdgeInset: CGFloat = 4
    static let compactWindowInsets = CGSize(
        width: Self.compactWindowEdgeInset * 2,
        height: Self.compactWindowEdgeInset * 2)
    static let defaultCompactWindowSize = Self.compactWindowSize(
        for: TokenDailyBoardConversationOnlyDebugRules.defaultTuning)

    static var availableTextWidth: CGFloat {
        self.contentWidth
            - TokenDailyBoardNarrativeLayout.conversationOnlyAvatarSize
            - TokenDailyBoardNarrativeLayout.conversationOnlyAvatarToContentSpacing
    }

    static func naturalContentSize(for tuning: TokenDailyBoardConversationOnlyDebugTuning) -> CGSize {
        let resolvedTuning = TokenDailyBoardConversationOnlyDebugRules.clamp(tuning)
        let textColumnWidth = TokenDailyBoardConversationOnlyDebugRules.resolvedTextColumnWidth(
            resolvedTuning.textColumnWidth,
            avatarSize: resolvedTuning.avatarSize)

        return CGSize(
            width: resolvedTuning.avatarSize
                + TokenDailyBoardNarrativeLayout.conversationOnlyAvatarToContentSpacing
                + textColumnWidth,
            height: TokenDailyBoardNarrativeSizingRules.conversationOnlyContentHeight(
                avatarSize: resolvedTuning.avatarSize,
                bodyFontSize: resolvedTuning.bodyFontSize,
                lineSpacing: resolvedTuning.bodyLineSpacing,
                metadataFontSize: resolvedTuning.metadataFontSize,
                hasMetadata: true))
    }

    static func compactWindowSize(for tuning: TokenDailyBoardConversationOnlyDebugTuning) -> CGSize {
        let contentSize = self.naturalContentSize(for: tuning)
        return CGSize(
            width: contentSize.width + self.compactWindowInsets.width,
            height: contentSize.height + self.compactWindowInsets.height)
    }

    static func compactContentFrame(
        in containerSize: CGSize,
        tuning: TokenDailyBoardConversationOnlyDebugTuning)
        -> CGRect
    {
        let naturalSize = self.naturalContentSize(for: tuning)
        return CGRect(
            x: self.compactWindowEdgeInset,
            y: self.compactWindowEdgeInset,
            width: min(naturalSize.width, max(containerSize.width - self.compactWindowInsets.width, 0)),
            height: min(naturalSize.height, max(containerSize.height - self.compactWindowInsets.height, 0)))
    }

    static func panelContentRect(
        in containerSize: CGSize,
        contentInset: CGFloat,
        topInset: CGFloat,
        bottomInset: CGFloat = TokenDailyBoardLayout.boardPanelBottomInset)
        -> CGRect
    {
        CGRect(
            x: contentInset,
            y: topInset,
            width: max(containerSize.width - (contentInset * 2), 0),
            height: max(containerSize.height - topInset - bottomInset, 0))
    }

    static func centeredContentFrame(in contentRect: CGRect) -> CGRect {
        CGRect(
            x: contentRect.minX + ((contentRect.width - self.contentWidth) / 2),
            y: contentRect.minY + ((contentRect.height - self.contentHeight) / 2),
            width: self.contentWidth,
            height: self.contentHeight)
    }
}

enum TokenDailyBoardScrollPresentationRules {
    static let topContentInset: CGFloat = TokenDailyBoardNarrativeLayout.avatarSize * 1.1
    static let bottomContentInset: CGFloat = 80
    static let usesScrollMask = false

    static func topContentInset(layoutScaleMultiplier: CGFloat) -> CGFloat {
        self.topContentInset
    }
}

enum TokenDailyBoardFontDesign: Equatable {
    case `default`
    case serif
    case rounded
}

struct TokenDailyBoardTextStyle: Equatable {
    let size: CGFloat
    let weight: Font.Weight
    let design: TokenDailyBoardFontDesign
    let usesMonospacedDigits: Bool

    init(
        size: CGFloat,
        weight: Font.Weight,
        design: TokenDailyBoardFontDesign = .default,
        usesMonospacedDigits: Bool = false)
    {
        self.size = size
        self.weight = weight
        self.design = design
        self.usesMonospacedDigits = usesMonospacedDigits
    }

    var font: Font {
        switch self.design {
        case .default:
            .system(size: self.size, weight: self.weight)
        case .serif:
            .system(size: self.size, weight: self.weight, design: .serif)
        case .rounded:
            .system(size: self.size, weight: self.weight, design: .rounded)
        }
    }

    func scaled(by multiplier: CGFloat) -> TokenDailyBoardTextStyle {
        TokenDailyBoardTextStyle(
            size: self.size * multiplier,
            weight: self.weight,
            design: self.design,
            usesMonospacedDigits: self.usesMonospacedDigits)
    }
}

enum TokenDailyBoardTypography {
    static let windowTitle = TokenDailyBoardTextStyle(size: TokenDailyBoardLayout.titleFontSize, weight: .semibold)
    static let chromeStatus = TokenDailyBoardTextStyle(
        size: TokenDailyBoardLayout.statusFontSize,
        weight: .medium,
        usesMonospacedDigits: true)
    static let comparison = TokenDailyBoardTextStyle(size: 12, weight: .medium)
    static let hourLabel = TokenDailyBoardTextStyle(size: 10, weight: .medium)
    static let emptyTitle = TokenDailyBoardTextStyle(size: 16, weight: .semibold)
    static let emptyMessage = TokenDailyBoardTextStyle(size: 13, weight: .regular)
    static let todayDate = TokenDailyBoardTextStyle(size: 28, weight: .semibold)
    static let secondaryDate = TokenDailyBoardTextStyle(size: 19, weight: .semibold)
    static let archiveDate = TokenDailyBoardTextStyle(size: 15, weight: .medium)
    static let heroTotal = TokenDailyBoardTextStyle(size: 24, weight: .bold, usesMonospacedDigits: true)
    static let heroMainThread = TokenDailyBoardTextStyle(size: 16, weight: .semibold, usesMonospacedDigits: true)
    static let heroInstructionCount = TokenDailyBoardTextStyle(size: 12, weight: .medium)
    static let secondaryInstructionCount = TokenDailyBoardTextStyle(size: 12, weight: .medium)
    static let secondaryTotal = TokenDailyBoardTextStyle(size: 15, weight: .bold, usesMonospacedDigits: true)
    static let secondaryMainThread = TokenDailyBoardTextStyle(
        size: 13,
        weight: .semibold,
        usesMonospacedDigits: true)
    static let archiveInstructionCount = TokenDailyBoardTextStyle(size: 11, weight: .medium)
    static let archiveTotal = TokenDailyBoardTextStyle(size: 12, weight: .semibold, usesMonospacedDigits: true)
    static let archiveMainThread = TokenDailyBoardTextStyle(
        size: 11,
        weight: .medium,
        usesMonospacedDigits: true)
    static let summary = TokenDailyBoardTextStyle(size: 12, weight: .regular)
    static let archiveSummary = TokenDailyBoardTextStyle(size: 11, weight: .regular)
}

struct TokenDailyBoardPalette {
    let textColor: NSColor
    let mutedTextColor: NSColor
    let guideLineColor: NSColor
    let baselineColor: NSColor
    let spikeColor: NSColor
    let windowBaseColor: NSColor
    let windowGlowColor: NSColor
    let windowAccentColor: NSColor
    let heroCardFillColor: NSColor
    let secondaryCardFillColor: NSColor
    let compactCardFillColor: NSColor
    let heroStrokeColor: NSColor
    let cardStrokeColor: NSColor
    let positiveAccentColor: NSColor
    let warningAccentColor: NSColor
    let neutralAccentColor: NSColor
    let shadowColor: NSColor

    var text: Color {
        Color(nsColor: self.textColor)
    }

    var mutedText: Color {
        Color(nsColor: self.mutedTextColor)
    }

    var guideLine: Color {
        Color(nsColor: self.guideLineColor)
    }

    var baseline: Color {
        Color(nsColor: self.baselineColor)
    }

    var spike: Color {
        Color(nsColor: self.spikeColor)
    }

    var windowBase: Color {
        Color(nsColor: self.windowBaseColor)
    }

    var windowGlow: Color {
        Color(nsColor: self.windowGlowColor)
    }

    var windowAccent: Color {
        Color(nsColor: self.windowAccentColor)
    }

    var heroCardFill: Color {
        Color(nsColor: self.heroCardFillColor)
    }

    var secondaryCardFill: Color {
        Color(nsColor: self.secondaryCardFillColor)
    }

    var compactCardFill: Color {
        Color(nsColor: self.compactCardFillColor)
    }

    var heroStroke: Color {
        Color(nsColor: self.heroStrokeColor)
    }

    var cardStroke: Color {
        Color(nsColor: self.cardStrokeColor)
    }

    var positiveAccent: Color {
        Color(nsColor: self.positiveAccentColor)
    }

    var warningAccent: Color {
        Color(nsColor: self.warningAccentColor)
    }

    var neutralAccent: Color {
        Color(nsColor: self.neutralAccentColor)
    }

    var shadow: Color {
        Color(nsColor: self.shadowColor)
    }
}

enum TokenDailyBoardTheme {
    static func palette(for colorScheme: ColorScheme) -> TokenDailyBoardPalette {
        switch colorScheme {
        case .light:
            return TokenDailyBoardPalette(
                textColor: NSColor(white: 0.08, alpha: 0.97),
                mutedTextColor: NSColor(white: 0.28, alpha: 0.82),
                guideLineColor: NSColor(white: 0.0, alpha: 0.10),
                baselineColor: NSColor(white: 0.0, alpha: 0.62),
                spikeColor: NSColor(white: 0.0, alpha: 0.84),
                windowBaseColor: NSColor(white: 0.98, alpha: 1),
                windowGlowColor: NSColor(white: 1.0, alpha: 0),
                windowAccentColor: NSColor(white: 1.0, alpha: 0),
                heroCardFillColor: NSColor(white: 0.96, alpha: 1),
                secondaryCardFillColor: NSColor(white: 0.94, alpha: 1),
                compactCardFillColor: NSColor(white: 0.92, alpha: 1),
                heroStrokeColor: NSColor(white: 0.0, alpha: 0.14),
                cardStrokeColor: NSColor(white: 0.0, alpha: 0.10),
                positiveAccentColor: NSColor(white: 0.10, alpha: 0.88),
                warningAccentColor: NSColor(white: 0.22, alpha: 0.78),
                neutralAccentColor: NSColor(white: 0.34, alpha: 0.70),
                shadowColor: NSColor.black.withAlphaComponent(0.16))
        case .dark:
            return TokenDailyBoardPalette(
                textColor: NSColor(white: 0.95, alpha: 0.97),
                mutedTextColor: NSColor(white: 0.72, alpha: 0.82),
                guideLineColor: NSColor(white: 1.0, alpha: 0.12),
                baselineColor: NSColor(white: 1.0, alpha: 0.72),
                spikeColor: NSColor(white: 1.0, alpha: 0.88),
                windowBaseColor: NSColor(white: 0.08, alpha: 1),
                windowGlowColor: NSColor(white: 1.0, alpha: 0),
                windowAccentColor: NSColor(white: 1.0, alpha: 0),
                heroCardFillColor: NSColor(white: 0.16, alpha: 1),
                secondaryCardFillColor: NSColor(white: 0.13, alpha: 1),
                compactCardFillColor: NSColor(white: 0.11, alpha: 1),
                heroStrokeColor: NSColor(white: 1.0, alpha: 0.18),
                cardStrokeColor: NSColor(white: 1.0, alpha: 0.12),
                positiveAccentColor: NSColor(white: 0.96, alpha: 0.90),
                warningAccentColor: NSColor(white: 0.82, alpha: 0.82),
                neutralAccentColor: NSColor(white: 0.70, alpha: 0.74),
                shadowColor: NSColor.black.withAlphaComponent(0.34))
        @unknown default:
            return self.palette(for: .dark)
        }
    }
}

enum TokenDailyBoardChartGeometry {
    static func usableWidth(containerWidth: CGFloat, horizontalInset: CGFloat) -> CGFloat {
        max(containerWidth - (horizontalInset * 2), 1)
    }

    static func boundaryX(for markerHour: Int, containerWidth: CGFloat, horizontalInset: CGFloat) -> CGFloat {
        let progress = CGFloat(markerHour) / 24
        let usableWidth = self.usableWidth(containerWidth: containerWidth, horizontalInset: horizontalInset)
        return horizontalInset + (usableWidth * progress)
    }

    static func spikeCenterX(for bucketIndex: Int, containerWidth: CGFloat, horizontalInset: CGFloat) -> CGFloat {
        let progress = (CGFloat(bucketIndex) + 0.5) / CGFloat(TokenDailyBoardLayout.fiveMinuteBucketsPerDay)
        let usableWidth = self.usableWidth(containerWidth: containerWidth, horizontalInset: horizontalInset)
        return horizontalInset + (usableWidth * progress)
    }
}

struct TokenDailyBoardFiveMinutePoint: Equatable {
    let bucketIndex: Int
    let rawTokens: Int
    let displayValue: Double
}

struct TokenDailyBoardDayModel: Identifiable, Equatable {
    let date: Date
    let dayKey: String
    let relativeDayOffset: Int
    let totalTokens: Int
    let mainThreadTokens: Int
    let instructionCount: Int
    let fiveMinutePoints: [TokenDailyBoardFiveMinutePoint]
    let rocketBucketIndex: Int?

    var id: String {
        self.dayKey
    }
}

struct TokenDailyBoardMonthKey: Hashable, Comparable {
    let year: Int
    let month: Int

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        return lhs.month < rhs.month
    }
}

struct TokenDailyBoardModel: Equatable {
    let days: [TokenDailyBoardDayModel]
    let scaleTopValue: Double
    let selectedYear: Int
    let selectedMonth: Int
    let availableYears: [Int]
    let availableMonthsWithData: Set<Int>

    var hasDataInSelectedMonth: Bool {
        !self.days.isEmpty
    }
}

private enum TokenDailyBoardComparisonState: Equatable {
    case higher(percentage: Int)
    case lower(percentage: Int)
    case steady
    case newActivity
    case idle
}

private enum TokenDailyBoardComparisonBuilder {
    static func make(today: Int, yesterday: Int) -> TokenDailyBoardComparisonState {
        if today == 0, yesterday == 0 {
            return .idle
        }
        if yesterday == 0 {
            return .newActivity
        }

        let deltaRatio = Double(today - yesterday) / Double(yesterday)
        if abs(deltaRatio) < 0.12 {
            return .steady
        }

        let percentage = max(Int((abs(deltaRatio) * 100).rounded()), 1)
        return deltaRatio > 0 ? .higher(percentage: percentage) : .lower(percentage: percentage)
    }
}

enum TokenDailyBoardDayTitleFormatter {
    static func title(
        for day: TokenDailyBoardDayModel,
        strings: TokenDailyBoardStrings,
        usesRelativeTitles: Bool)
        -> String
    {
        guard usesRelativeTitles else {
            return self.formattedDate(day.date, locale: strings.locale)
        }

        switch day.relativeDayOffset {
        case 0:
            return strings.dailyBoardTodayTitle
        case 1:
            return strings.dailyBoardYesterdayTitle
        case 2:
            return strings.dailyBoardDayBeforeYesterdayTitle
        default:
            return self.formattedDate(day.date, locale: strings.locale)
        }
    }

    private static func formattedDate(_ date: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar.current
        formatter.timeZone = Calendar.current.timeZone
        formatter.setLocalizedDateFormatFromTemplate("M/d")
        return formatter.string(from: date)
    }
}

enum TokenDailyBoardActivitySummaryBuilder {
    static func dominantHour(for day: TokenDailyBoardDayModel) -> Int? {
        guard let point = day.fiveMinutePoints.max(by: { $0.rawTokens < $1.rawTokens }), point.rawTokens > 0 else {
            return nil
        }

        return point.bucketIndex / 12
    }
}

enum TokenDailyBoardModelBuilder {
    static func makeModel(
        tokenDays: [DailyTokenStats],
        regularTokenDays: [DailyTokenStats],
        fiveMinuteBuckets: [FiveMinuteTokenStats],
        outboundMessageDays: [DailyOutboundMessageStats],
        selectedYear: Int,
        selectedMonth: Int,
        referenceDate: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent)
        -> TokenDailyBoardModel
    {
        let normalizedCalendar = calendar
        let allDayModels = self.allAvailableDayModels(
            tokenDays: tokenDays,
            regularTokenDays: regularTokenDays,
            fiveMinuteBuckets: fiveMinuteBuckets,
            outboundMessageDays: outboundMessageDays,
            referenceDate: referenceDate,
            calendar: normalizedCalendar)
        let availableMonthKeys = self.availableMonthKeys(from: allDayModels, calendar: normalizedCalendar)
        let availableYears = Array(Set(availableMonthKeys.map(\.year))).sorted()
        let availableMonthsWithData = Set(
            availableMonthKeys
                .filter { $0.year == selectedYear }
                .map(\.month))
        let dayModels = self.makeMonthDayModels(
            tokenDays: tokenDays,
            regularTokenDays: regularTokenDays,
            fiveMinuteBuckets: fiveMinuteBuckets,
            outboundMessageDays: outboundMessageDays,
            selectedYear: selectedYear,
            selectedMonth: selectedMonth,
            referenceDate: referenceDate,
            calendar: normalizedCalendar,
            availableMonthKeys: Set(availableMonthKeys))

        let peakDisplayValue = dayModels
            .flatMap(\.fiveMinutePoints)
            .map(\.displayValue)
            .max() ?? 0

        return TokenDailyBoardModel(
            days: dayModels,
            scaleTopValue: self.chartCeiling(for: peakDisplayValue),
            selectedYear: selectedYear,
            selectedMonth: selectedMonth,
            availableYears: availableYears,
            availableMonthsWithData: availableMonthsWithData)
    }

    static func allAvailableDayModels(
        tokenDays: [DailyTokenStats],
        regularTokenDays: [DailyTokenStats],
        fiveMinuteBuckets: [FiveMinuteTokenStats],
        outboundMessageDays: [DailyOutboundMessageStats],
        referenceDate: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent)
        -> [TokenDailyBoardDayModel]
    {
        let normalizedCalendar = calendar
        let tokenDayMap = Dictionary(uniqueKeysWithValues: tokenDays.map { ($0.date, $0) })
        let regularTokenDayMap = Dictionary(uniqueKeysWithValues: regularTokenDays.map { ($0.date, $0) })
        let outboundDayMap = Dictionary(uniqueKeysWithValues: outboundMessageDays.map { ($0.date, $0) })
        let bucketsByDay = self.fiveMinuteBucketsByDay(fiveMinuteBuckets, calendar: normalizedCalendar)
        let allDayKeys = Set(tokenDayMap.keys)
            .union(regularTokenDayMap.keys)
            .union(outboundDayMap.keys)
            .union(bucketsByDay.keys)

        return allDayKeys.compactMap { dayKey in
            self.makeDayModel(
                dayKey: dayKey,
                tokenStats: tokenDayMap[dayKey] ?? .empty(for: dayKey),
                regularTokenStats: regularTokenDayMap[dayKey] ?? .empty(for: dayKey),
                outboundStats: outboundDayMap[dayKey] ?? .empty(for: dayKey),
                bucketMap: bucketsByDay[dayKey] ?? [:],
                referenceDate: referenceDate,
                calendar: normalizedCalendar)
        }
        .sorted { lhs, rhs in
            lhs.date > rhs.date
        }
    }

    static func makeModel(
        tokenDays: [DailyTokenStats],
        regularTokenDays: [DailyTokenStats],
        fiveMinuteBuckets: [FiveMinuteTokenStats],
        outboundMessageDays: [DailyOutboundMessageStats],
        referenceDate: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent)
        -> TokenDailyBoardModel
    {
        let components = calendar.dateComponents([.year, .month], from: referenceDate)
        return self.makeModel(
            tokenDays: tokenDays,
            regularTokenDays: regularTokenDays,
            fiveMinuteBuckets: fiveMinuteBuckets,
            outboundMessageDays: outboundMessageDays,
            selectedYear: components.year ?? 1970,
            selectedMonth: components.month ?? 1,
            referenceDate: referenceDate,
            calendar: calendar)
    }

    private static func makeMonthDayModels(
        tokenDays: [DailyTokenStats],
        regularTokenDays: [DailyTokenStats],
        fiveMinuteBuckets: [FiveMinuteTokenStats],
        outboundMessageDays: [DailyOutboundMessageStats],
        selectedYear: Int,
        selectedMonth: Int,
        referenceDate: Date,
        calendar: Calendar,
        availableMonthKeys: Set<TokenDailyBoardMonthKey>)
        -> [TokenDailyBoardDayModel]
    {
        let selectedMonthKey = TokenDailyBoardMonthKey(year: selectedYear, month: selectedMonth)
        guard availableMonthKeys.contains(selectedMonthKey) else {
            return []
        }

        let tokenDayMap = Dictionary(uniqueKeysWithValues: tokenDays.map { ($0.date, $0) })
        let regularTokenDayMap = Dictionary(uniqueKeysWithValues: regularTokenDays.map { ($0.date, $0) })
        let outboundDayMap = Dictionary(uniqueKeysWithValues: outboundMessageDays.map { ($0.date, $0) })
        let bucketsByDay = self.fiveMinuteBucketsByDay(fiveMinuteBuckets, calendar: calendar)
        let range = self.dayRange(
            forYear: selectedYear,
            month: selectedMonth,
            referenceDate: referenceDate,
            calendar: calendar)

        return Array(range.reversed()).compactMap { day in
            var components = DateComponents()
            components.calendar = calendar
            components.timeZone = calendar.timeZone
            components.year = selectedYear
            components.month = selectedMonth
            components.day = day
            guard let dayDate = calendar.date(from: components) else {
                return nil
            }
            let dayKey = DailyTokenStats.dayKey(for: dayDate, calendar: calendar)
            return self.makeDayModel(
                dayKey: dayKey,
                tokenStats: tokenDayMap[dayKey] ?? .empty(for: dayKey),
                regularTokenStats: regularTokenDayMap[dayKey] ?? .empty(for: dayKey),
                outboundStats: outboundDayMap[dayKey] ?? .empty(for: dayKey),
                bucketMap: bucketsByDay[dayKey] ?? [:],
                referenceDate: referenceDate,
                calendar: calendar)
        }
    }

    private static func makeDayModel(
        dayKey: String,
        tokenStats: DailyTokenStats,
        regularTokenStats: DailyTokenStats,
        outboundStats: DailyOutboundMessageStats,
        bucketMap: [Int: FiveMinuteTokenStats],
        referenceDate: Date,
        calendar: Calendar)
        -> TokenDailyBoardDayModel?
    {
        guard let dayDate = self.date(for: dayKey, calendar: calendar) else {
            return nil
        }
        let todayStart = calendar.startOfDay(for: referenceDate)
        let dayStart = calendar.startOfDay(for: dayDate)
        let relativeDayOffset = calendar.dateComponents([.day], from: dayStart, to: todayStart).day ?? 0
        let fiveMinutePoints = (0..<TokenDailyBoardLayout.fiveMinuteBucketsPerDay).map { bucketIndex in
            let rawTokens = bucketMap[bucketIndex]?.totalTokens ?? 0
            return TokenDailyBoardFiveMinutePoint(
                bucketIndex: bucketIndex,
                rawTokens: rawTokens,
                displayValue: log10(Double(rawTokens) + 1))
        }

        return TokenDailyBoardDayModel(
            date: dayDate,
            dayKey: dayKey,
            relativeDayOffset: relativeDayOffset,
            totalTokens: tokenStats.totalTokens,
            mainThreadTokens: regularTokenStats.totalTokens,
            instructionCount: outboundStats.instructionCount,
            fiveMinutePoints: fiveMinutePoints,
            rocketBucketIndex: relativeDayOffset == 0 ? fiveMinutePoints.last(where: { $0.rawTokens > 0 })?
                .bucketIndex : nil)
    }

    private static func fiveMinuteBucketsByDay(
        _ buckets: [FiveMinuteTokenStats],
        calendar: Calendar)
        -> [String: [Int: FiveMinuteTokenStats]]
    {
        var bucketsByDay: [String: [Int: FiveMinuteTokenStats]] = [:]

        for bucket in buckets {
            let dayKey = DailyTokenStats.dayKey(for: bucket.bucketStart, calendar: calendar)
            let bucketIndex = self.bucketIndex(for: bucket.bucketStart, calendar: calendar)
            bucketsByDay[dayKey, default: [:]][bucketIndex] = bucket
        }

        return bucketsByDay
    }

    private static func bucketIndex(for date: Date, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let bucketIndex = (hour * 12) + (minute / 5)
        return max(0, min(TokenDailyBoardLayout.fiveMinuteBucketsPerDay - 1, bucketIndex))
    }

    private static func chartCeiling(for peakDisplayValue: Double) -> Double {
        guard peakDisplayValue > 0 else { return 1 }
        let paddedPeak = peakDisplayValue * 1.14
        return max(1, ceil(paddedPeak * 10) / 10)
    }

    private static func availableMonthKeys(
        from days: [TokenDailyBoardDayModel],
        calendar: Calendar)
        -> [TokenDailyBoardMonthKey]
    {
        Array(
            Set(days.compactMap { day in
                let components = calendar.dateComponents([.year, .month], from: day.date)
                guard let year = components.year, let month = components.month else {
                    return nil
                }
                return TokenDailyBoardMonthKey(year: year, month: month)
            }))
            .sorted()
    }

    private static func date(for dayKey: String, calendar: Calendar) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dayKey)
    }

    private static func dayRange(
        forYear year: Int,
        month: Int,
        referenceDate: Date,
        calendar: Calendar)
        -> ClosedRange<Int>
    {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = 1
        let monthStart = calendar.date(from: components) ?? calendar.startOfDay(for: referenceDate)
        let currentComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        let isCurrentMonth = currentComponents.year == year && currentComponents.month == month
        let upperBound: Int = if isCurrentMonth {
            currentComponents.day ?? 1
        } else {
            calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 31
        }

        return 1...upperBound
    }
}

private struct TokenDailyBoardValueParts: Equatable {
    let magnitude: String
    let suffix: String?
}

private enum TokenDailyBoardValueFormatter {
    static func tokenParts(for value: Int, strings: TokenDailyBoardStrings) -> TokenDailyBoardValueParts {
        switch strings.resolvedLanguage {
        case .zhHans:
            if value >= 10_000_000 {
                return self.localizedLargeNumberParts(
                    value: value,
                    divisor: 100_000_000,
                    unit: "亿",
                    locale: strings.locale)
            }
        case .ja:
            if value >= 10_000_000 {
                return self.localizedLargeNumberParts(
                    value: value,
                    divisor: 100_000_000,
                    unit: "億",
                    locale: strings.locale)
            }
        case .en:
            if value >= 1_000_000_000 {
                return self.localizedLargeNumberParts(
                    value: value,
                    divisor: 1_000_000_000,
                    unit: "B",
                    locale: strings.locale)
            }
            if value >= 1_000_000 {
                return self.localizedLargeNumberParts(
                    value: value,
                    divisor: 1_000_000,
                    unit: "M",
                    locale: strings.locale)
            }
        case .system:
            break
        }

        return TokenDailyBoardValueParts(
            magnitude: self.exactNumberText(value, locale: strings.locale),
            suffix: nil)
    }

    static func instructionParts(for value: Int, strings: TokenDailyBoardStrings) -> TokenDailyBoardValueParts {
        let suffix: String? = switch strings.resolvedLanguage {
        case .zhHans:
            "次"
        case .ja:
            "回"
        case .en:
            nil
        case .system:
            nil
        }

        return TokenDailyBoardValueParts(
            magnitude: self.exactNumberText(value, locale: strings.locale),
            suffix: suffix)
    }

    private static func exactNumberText(_ value: Int, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private static func localizedLargeNumberParts(
        value: Int,
        divisor: Double,
        unit: String,
        locale: Locale)
        -> TokenDailyBoardValueParts
    {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1

        let scaledValue = Double(value) / divisor
        let magnitude = formatter.string(from: NSNumber(value: scaledValue))
            ?? String(format: "%.1f", scaledValue)
        return TokenDailyBoardValueParts(magnitude: magnitude, suffix: unit)
    }
}

private struct TokenDailyBoardWindowBackground: View {
    let usesGlass: Bool
    let appearance: TokenDailyBoardConversationOnlyWindowAppearance

    var body: some View {
        if self.usesGlass {
            ZStack {
                if self.appearance.blurOverlayOpacity > 0.001 {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(self.appearance.blurOverlayOpacity)
                        .blur(radius: self.appearance.resolvedGlassBlur)
                }

                if #available(macOS 26, *) {
                    Rectangle()
                        .fill(.clear)
                        .glassEffect(.regular, in: Rectangle())
                        .backgroundExtensionEffect()
                        .opacity(self.appearance.resolvedGlassOpacity)
                } else {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(self.appearance.resolvedGlassOpacity)
                }
            }
        } else {
            Rectangle()
                .fill(.clear)
        }
    }
}

package enum TokenDailyBoardConversationOnlyWindowPulseRules {
    package static let duration: TimeInterval = 1.0
    package static let fadeOutDuration: TimeInterval = 0.36
    package static let fillPeakOpacity: Double = 0.08
    package static let sweepPeakOpacity: Double = 0.36
    package static let sweepBlurRadius: CGFloat = 24
    package static let sweepWidthMultiplier: CGFloat = 0.74
    package static let sweepStartX: CGFloat = -0.58
    package static let sweepMidX: CGFloat = 0.26
    package static let sweepEndX: CGFloat = 1.28
    package static let idleFillPeakOpacity: Double = 0.052
    package static let idleSweepPeakOpacity: Double = 0.22
    package static let idleSweepHeightMultiplier: CGFloat = 0.68
    package static let idleSweepStartY: CGFloat = 1.18
    package static let idleSweepEndY: CGFloat = -0.22

    package static func isEnabled(
        _ tuning: TokenDailyBoardConversationOnlyDebugTuning,
        for displayMode: TokenDailyBoardDisplayMode)
        -> Bool
    {
        switch displayMode {
        case .conversationOnly, .conversationAndToday, .fullBoard:
            tuning.enablesPreNarrativeWindowPulse
        }
    }

    static func style(for eventKind: TokenDailyBoardNarrativeEventKind?) -> TokenDailyBoardNarrativePulseStyle? {
        switch eventKind {
        case .throughputPulse, .instructionPulse:
            .standardRealtime
        case .idlePulse:
            .idlePulse
        case .none, .quiet, .sendCount, .burst, .combo:
            nil
        }
    }

    static func sweepAxis(for style: TokenDailyBoardNarrativePulseStyle) -> TokenDailyBoardNarrativePulseSweepAxis {
        switch style {
        case .standardRealtime:
            .horizontal
        case .idlePulse:
            .vertical
        }
    }

    static func paletteName(for style: TokenDailyBoardNarrativePulseStyle) -> String {
        switch style {
        case .standardRealtime:
            "warmRed"
        case .idlePulse:
            "plumRose"
        }
    }

    static func fillPeakOpacity(for style: TokenDailyBoardNarrativePulseStyle) -> Double {
        switch style {
        case .standardRealtime:
            self.fillPeakOpacity
        case .idlePulse:
            self.idleFillPeakOpacity
        }
    }

    static func sweepPeakOpacity(for style: TokenDailyBoardNarrativePulseStyle) -> Double {
        switch style {
        case .standardRealtime:
            self.sweepPeakOpacity
        case .idlePulse:
            self.idleSweepPeakOpacity
        }
    }
}

package enum TokenDailyBoardConversationOnlyAvatarSequenceRules {
    package static let minimumDuration = TokenDailyBoardNarrativeAvatarReplacementAnimationRules.duration

    static func style(
        for eventKind: TokenDailyBoardNarrativeEventKind?,
        animationEnabled: Bool)
        -> TokenDailyBoardNarrativeAvatarTriggerStyle
    {
        guard animationEnabled else { return .none }
        switch eventKind {
        case .throughputPulse, .instructionPulse:
            return .variantReplacement
        case .idlePulse:
            return .defaultGroupIntro
        case .none, .quiet, .sendCount, .burst, .combo:
            return .none
        }
    }

    static func nextVariantSelection(
        currentVariantCycleIndex: Int?,
        slots: [CodexDailyAvatarResolvedSlot],
        displayMode: TokenDailyBoardDisplayMode,
        animationEnabled: Bool,
        eventKind: TokenDailyBoardNarrativeEventKind?)
        -> (slot: CodexDailyAvatarResolvedSlot, nextVariantCycleIndex: Int)?
    {
        switch displayMode {
        case .conversationOnly, .conversationAndToday, .fullBoard:
            break
        }
        guard self.style(for: eventKind, animationEnabled: animationEnabled) == .variantReplacement else { return nil }
        guard let nextVariantCycleIndex = TokenDailyBoardNarrativeVariantAvatarRules.nextVariantCycleIndex(
            current: currentVariantCycleIndex,
            slots: slots),
            let slot = TokenDailyBoardNarrativeVariantAvatarRules.activeSlot(
                from: slots,
                variantCycleIndex: nextVariantCycleIndex),
            slot.slot != .defaultAvatar
        else {
            return nil
        }

        return (slot, nextVariantCycleIndex)
    }
}

package enum TokenDailyBoardDisplayModeTransitionRules {
    package static let usesAnimatedWindowFrame = false
    package static let fadeOutDuration: TimeInterval = 0.08
    package static let fadeInDuration: TimeInterval = 0.14

    package static func shouldSuppressNarrativeAutoAnimations(
        isSwitchingDisplayMode: Bool,
        suppressesNarrativeAutoAnimations: Bool)
        -> Bool
    {
        isSwitchingDisplayMode || suppressesNarrativeAutoAnimations
    }
}

struct TokenDailyBoardNarrativePresentationQueueItem: Identifiable {
    let id: Int
    let sourceItem: TokenDailyBoardNarrativePresentationSourceItem
    let preferredAvatarSlot: CodexDailyAvatarResolvedSlot?
    let avatarTriggerStyle: TokenDailyBoardNarrativeAvatarTriggerStyle
    let pulseStyle: TokenDailyBoardNarrativePulseStyle?

    var signature: String {
        self.sourceItem.signature
    }

    var sentence: TokenDailyBoardNarrativeSentence {
        self.sourceItem.sentence
    }

    var isAutomaticRealtimeSwitch: Bool {
        self.sourceItem.isAutomaticRealtime
    }

    var realtimeEventKind: TokenDailyBoardNarrativeEventKind? {
        self.sourceItem.realtimeEventKind
    }

    var sourceID: String {
        self.sourceItem.sourceID
    }

    var groupKind: TokenDailyBoardNarrativePresentationGroupKind {
        self.sourceItem.groupKind
    }

    init(
        id: Int,
        sourceItem: TokenDailyBoardNarrativePresentationSourceItem,
        preferredAvatarSlot: CodexDailyAvatarResolvedSlot? = nil,
        avatarTriggerStyle: TokenDailyBoardNarrativeAvatarTriggerStyle = .none,
        pulseStyle: TokenDailyBoardNarrativePulseStyle? = nil)
    {
        self.id = id
        self.sourceItem = sourceItem
        self.preferredAvatarSlot = preferredAvatarSlot
        self.avatarTriggerStyle = avatarTriggerStyle
        self.pulseStyle = pulseStyle
    }
}

struct TokenDailyBoardNarrativePresentationSession {
    let item: TokenDailyBoardNarrativePresentationQueueItem
    let startedAt: Date
    let typewriterStartAt: Date
    let avatarIntroStartAt: Date
    let avatarReplacementSequenceID: Int
    let pulseMotion: TokenDailyBoardNarrativePulseMotionConfiguration?
    let avatarMotionConfiguration: TokenDailyBoardNarrativeAvatarMotionConfiguration
    let bodyCharactersPerSecond: Double
    let metadataCharactersPerSecond: Double
    var typewriterCompletedAt: Date?
    var pulseFadeStartAt: Date?
    var metadataIntroStartedAt: Date?
    var metadataIntroCompletedAt: Date?
    var avatarReturnStartAt: Date?
    var completedAt: Date?
    var hasActivatedAvatarIntro = false
    var hasStartedReturn = false

    init(
        item: TokenDailyBoardNarrativePresentationQueueItem,
        startedAt: Date,
        typewriterStartAt: Date,
        avatarIntroStartAt: Date,
        avatarTriggerStyle: TokenDailyBoardNarrativeAvatarTriggerStyle = .none,
        preferredAvatarSlot: CodexDailyAvatarResolvedSlot? = nil,
        avatarReplacementSequenceID: Int,
        avatarIdleShakeSequenceID: Int = 0,
        pulseStyle: TokenDailyBoardNarrativePulseStyle? = nil,
        pulseMotion: TokenDailyBoardNarrativePulseMotionConfiguration? = nil,
        avatarMotionConfiguration: TokenDailyBoardNarrativeAvatarMotionConfiguration = .standard,
        bodyCharactersPerSecond: Double = TokenDailyBoardNarrativeLayout.typewriterCharactersPerSecond,
        metadataCharactersPerSecond: Double = TokenDailyBoardNarrativeLayout.typewriterCharactersPerSecond,
        typewriterCompletedAt: Date? = nil,
        pulseFadeStartAt: Date? = nil,
        metadataIntroStartedAt: Date? = nil,
        metadataIntroCompletedAt: Date? = nil,
        avatarReturnStartAt: Date? = nil,
        completedAt: Date? = nil,
        hasActivatedAvatarIntro: Bool = false,
        hasStartedReturn: Bool = false)
    {
        _ = avatarTriggerStyle
        _ = preferredAvatarSlot
        _ = avatarIdleShakeSequenceID
        _ = pulseStyle
        self.item = item
        self.startedAt = startedAt
        self.typewriterStartAt = typewriterStartAt
        self.avatarIntroStartAt = avatarIntroStartAt
        self.avatarReplacementSequenceID = avatarReplacementSequenceID
        self.pulseMotion = pulseMotion
        self.avatarMotionConfiguration = avatarMotionConfiguration
        self.bodyCharactersPerSecond = bodyCharactersPerSecond
        self.metadataCharactersPerSecond = metadataCharactersPerSecond
        self.typewriterCompletedAt = typewriterCompletedAt
        self.pulseFadeStartAt = pulseFadeStartAt
        self.metadataIntroStartedAt = metadataIntroStartedAt
        self.metadataIntroCompletedAt = metadataIntroCompletedAt
        self.avatarReturnStartAt = avatarReturnStartAt
        self.completedAt = completedAt
        self.hasActivatedAvatarIntro = hasActivatedAvatarIntro
        self.hasStartedReturn = hasStartedReturn
    }
}

enum TokenDailyBoardNarrativePulseStyle: Equatable {
    case standardRealtime
    case idlePulse
}

enum TokenDailyBoardNarrativePulseSweepAxis: Equatable {
    case horizontal
    case vertical
}

enum TokenDailyBoardNarrativeAvatarTriggerStyle: Equatable {
    case none
    case defaultGroupIntro
    case variantReplacement
}

enum TokenDailyBoardNarrativeAvatarPhase: Equatable {
    case resting
    case introDefault
    case holdingDefault
    case settlingDefault
    case introVariant
    case holdingVariant
    case settlingVariant
}

enum TokenDailyBoardNarrativeWindowPulsePhase: Equatable {
    case inactive
    case active(Int, TokenDailyBoardNarrativePulseMotionConfiguration)
    case fadingOut(Int, TokenDailyBoardNarrativePulseMotionConfiguration)
}

extension TokenDailyBoardNarrativeWindowPulsePhase {
    var style: TokenDailyBoardNarrativePulseStyle {
        switch self {
        case let .active(_, configuration), let .fadingOut(_, configuration):
            configuration.style
        case .inactive:
            .standardRealtime
        }
    }

    var motionConfiguration: TokenDailyBoardNarrativePulseMotionConfiguration {
        switch self {
        case let .active(_, configuration), let .fadingOut(_, configuration):
            configuration
        case .inactive:
            TokenDailyBoardNarrativePulseMotionConfiguration(
                style: .standardRealtime,
                duration: TokenDailyBoardConversationOnlyWindowPulseRules.duration,
                fadeOutDuration: TokenDailyBoardConversationOnlyWindowPulseRules.fadeOutDuration)
        }
    }
}

enum TokenDailyBoardNarrativePresentationQueueRules {
    static func newSourceItems(
        from sourceItems: [TokenDailyBoardNarrativePresentationSourceItem],
        knownSourceIDs: Set<String>)
        -> [TokenDailyBoardNarrativePresentationSourceItem]
    {
        sourceItems.filter { !knownSourceIDs.contains($0.sourceID) }
    }

    static func enqueue(
        _ item: TokenDailyBoardNarrativePresentationQueueItem,
        existingQueue: [TokenDailyBoardNarrativePresentationQueueItem],
        activeSignature: String?)
        -> [TokenDailyBoardNarrativePresentationQueueItem]
    {
        if existingQueue.last?.signature == item.signature || activeSignature == item.signature {
            return existingQueue
        }
        return [item]
    }

    static func typewriterDuration(for sentence: TokenDailyBoardNarrativeSentence) -> TimeInterval {
        TokenDailyBoardNarrativeAnimationRules.typewriterDuration(for: sentence.text)
    }

    static func metadataTypewriterDuration(for metadataText: String?) -> TimeInterval {
        TokenDailyBoardNarrativeAnimationRules.typewriterDuration(for: metadataText ?? "")
    }
}

struct TokenDailyBoardConversationOnlyResolvedAnimationProfile: Equatable {
    let eventPulseDuration: TimeInterval
    let waitingPulseDuration: TimeInterval
    let eventBodyStartDelay: TimeInterval
    let waitingBodyStartDelay: TimeInterval
    let eventMetadataStartDelay: TimeInterval
    let waitingMetadataStartDelay: TimeInterval
    let bodyCharactersPerSecond: Double
    let metadataCharactersPerSecond: Double
    let avatarMotionConfiguration: TokenDailyBoardNarrativeAvatarMotionConfiguration

    func pulseMotion(
        for style: TokenDailyBoardNarrativePulseStyle?)
        -> TokenDailyBoardNarrativePulseMotionConfiguration?
    {
        guard let style else { return nil }
        let duration = switch style {
        case .standardRealtime: self.eventPulseDuration
        case .idlePulse: self.waitingPulseDuration
        }
        return TokenDailyBoardNarrativePulseMotionConfiguration(
            style: style,
            duration: duration,
            fadeOutDuration: TokenDailyBoardConversationOnlyAnimationProfileRules.fadeOutDuration(
                forPreludeDuration: duration))
    }

    func bodyStartDelay(for groupKind: TokenDailyBoardNarrativePresentationGroupKind) -> TimeInterval {
        switch groupKind {
        case .waitingGroup: self.waitingBodyStartDelay
        case .eventGroup: self.eventBodyStartDelay
        }
    }

    func metadataStartDelay(for groupKind: TokenDailyBoardNarrativePresentationGroupKind) -> TimeInterval {
        switch groupKind {
        case .waitingGroup: self.waitingMetadataStartDelay
        case .eventGroup: self.eventMetadataStartDelay
        }
    }
}

enum TokenDailyBoardConversationOnlyAnimationProfileRules {
    private static let baseCharactersPerSecond = TokenDailyBoardNarrativeLayout.typewriterCharactersPerSecond

    static func fadeOutDuration(forPreludeDuration duration: TimeInterval) -> TimeInterval {
        min(max(duration * 0.4, 0.14), 0.24)
    }

    static func resolvedProfile(
        tuning: TokenDailyBoardConversationOnlyDebugTuning)
        -> TokenDailyBoardConversationOnlyResolvedAnimationProfile
    {
        let resolvedTuning = TokenDailyBoardConversationOnlyDebugRules.clamp(tuning)
        let preset = resolvedTuning.animationPreset

        let eventPulseDuration: TimeInterval
        let waitingPulseDuration: TimeInterval
        let bodySpeedScale: Double
        let metadataSpeedScale: Double
        let variantPeakScale: CGFloat
        let variantShakeAmplitude: CGFloat
        let defaultPeakScale: CGFloat

        switch preset {
        case .cinematic:
            eventPulseDuration = 0.60
            waitingPulseDuration = 0.36
            bodySpeedScale = 1.0
            metadataSpeedScale = 1.0
            variantPeakScale = 1.12
            variantShakeAmplitude = 3.0
            defaultPeakScale = 1.035
        case .aggressive:
            eventPulseDuration = 0.42
            waitingPulseDuration = 0.30
            bodySpeedScale = 1.20
            metadataSpeedScale = 1.15
            variantPeakScale = 1.16
            variantShakeAmplitude = 4.05
            defaultPeakScale = 1.045
        case .gentle:
            eventPulseDuration = 0.50
            waitingPulseDuration = 0.32
            bodySpeedScale = 0.95
            metadataSpeedScale = 0.90
            variantPeakScale = 1.08
            variantShakeAmplitude = 1.8
            defaultPeakScale = 1.02
        }

        func scaledPeak(_ base: CGFloat) -> CGFloat {
            1 + ((base - 1) * resolvedTuning.avatarIntensityScale)
        }

        return TokenDailyBoardConversationOnlyResolvedAnimationProfile(
            eventPulseDuration: eventPulseDuration * resolvedTuning.pulseDurationScale,
            waitingPulseDuration: waitingPulseDuration * resolvedTuning.pulseDurationScale,
            eventBodyStartDelay: 0.08,
            waitingBodyStartDelay: 0.06,
            eventMetadataStartDelay: 0.10,
            waitingMetadataStartDelay: 0.08,
            bodyCharactersPerSecond: self.baseCharactersPerSecond
                * bodySpeedScale
                * resolvedTuning.bodyTypewriterSpeedScale,
            metadataCharactersPerSecond: self.baseCharactersPerSecond
                * metadataSpeedScale
                * resolvedTuning.metadataTypewriterSpeedScale,
            avatarMotionConfiguration: TokenDailyBoardNarrativeAvatarMotionConfiguration(
                defaultPeakScale: scaledPeak(defaultPeakScale),
                defaultShakeAmplitude: 0,
                variantPeakScale: scaledPeak(variantPeakScale),
                variantShakeAmplitude: variantShakeAmplitude * resolvedTuning.avatarIntensityScale))
    }
}

enum TokenDailyBoardNarrativeIdlePulseRules {
    static func countdownAnchor(
        lastNonIdleNarrativeCompletionAt: Date?,
        lastPresentedIdleAt: Date?)
        -> Date?
    {
        switch (lastNonIdleNarrativeCompletionAt, lastPresentedIdleAt) {
        case let (lhs?, rhs?):
            max(lhs, rhs)
        case let (lhs?, nil):
            lhs
        case let (nil, rhs?):
            rhs
        case (nil, nil):
            nil
        }
    }

    static func shouldArmCountdown(
        hasEligibleRealtimeActivity: Bool,
        activeSession: TokenDailyBoardNarrativePresentationSession?,
        queuedItems: [TokenDailyBoardNarrativePresentationQueueItem],
        suppressesNarrativeChanges: Bool,
        countdownAnchor: Date?)
        -> Bool
    {
        hasEligibleRealtimeActivity
            && activeSession == nil
            && queuedItems.isEmpty
            && !suppressesNarrativeChanges
            && countdownAnchor != nil
    }

    static func deadline(from anchor: Date) -> Date {
        anchor.addingTimeInterval(TokenDailyBoardNarrativeBuilder.idlePulseInterval)
    }

    static func shouldTrigger(
        now: Date,
        expectedAnchor: Date,
        currentAnchor: Date?,
        hasEligibleRealtimeActivity: Bool,
        activeSession: TokenDailyBoardNarrativePresentationSession?,
        queuedItems: [TokenDailyBoardNarrativePresentationQueueItem],
        suppressesNarrativeChanges: Bool)
        -> Bool
    {
        guard currentAnchor == expectedAnchor else { return false }
        guard hasEligibleRealtimeActivity else { return false }
        guard activeSession == nil, queuedItems.isEmpty else { return false }
        guard !suppressesNarrativeChanges else { return false }
        return now >= self.deadline(from: expectedAnchor)
    }

    static func shouldPersistAfterCompletion(
        eventKind: TokenDailyBoardNarrativeEventKind?,
        queuedItems: [TokenDailyBoardNarrativePresentationQueueItem])
        -> Bool
    {
        eventKind == .idlePulse && queuedItems.isEmpty
    }

    static func shouldDismissPresentedIdleForIncomingNarrative(
        renderedSourceItem: TokenDailyBoardNarrativePresentationSourceItem?,
        activeSession: TokenDailyBoardNarrativePresentationSession?)
        -> Bool
    {
        activeSession == nil && renderedSourceItem?.realtimeEventKind == .idlePulse
    }

    static func shouldRefreshPresentedIdle(
        renderedSourceItem: TokenDailyBoardNarrativePresentationSourceItem?,
        activeSession: TokenDailyBoardNarrativePresentationSession?,
        queuedItems: [TokenDailyBoardNarrativePresentationQueueItem],
        suppressesNarrativeChanges: Bool)
        -> Bool
    {
        renderedSourceItem?.realtimeEventKind == .idlePulse
            && activeSession == nil
            && queuedItems.isEmpty
            && !suppressesNarrativeChanges
    }
}

enum TokenDailyBoardNarrativeIdleHandoffRules {
    static let dismissDuration: TimeInterval = 0.18
    static let dismissDurationNanoseconds: UInt64 = 180_000_000
    static let dismissAnimation = Animation.easeOut(duration: dismissDuration)
    static let dismissVerticalOffset: CGFloat = 0
}

enum TokenDailyBoardNarrativePresentationTimelineRules {
    static let pulseStartDelay: TimeInterval = 0
    static let typewriterStartDelayAfterAvatarIntro: TimeInterval = 0
    static let avatarReturnDelayAfterTypewriter: TimeInterval = 0
    static let queueGapDuration: TimeInterval = 0
    static let immediateIdleHandoffGapDuration: TimeInterval = 0

    static func pulsePreludeEndDate(startedAt: Date, includesPulse: Bool = true) -> Date {
        if includesPulse {
            startedAt.addingTimeInterval(TokenDailyBoardConversationOnlyWindowPulseRules.duration)
        } else {
            startedAt
        }
    }

    static func typewriterStartDate(startedAt: Date, includesPulse: Bool = true) -> Date {
        self.avatarIntroStartDate(startedAt: startedAt, includesPulse: includesPulse)
            .addingTimeInterval(self.typewriterStartDelayAfterAvatarIntro)
    }

    static func avatarIntroStartDate(startedAt: Date, includesPulse: Bool = true) -> Date {
        self.pulsePreludeEndDate(startedAt: startedAt, includesPulse: includesPulse)
    }

    static func avatarIntroEndDate(startedAt: Date, includesPulse: Bool = true) -> Date {
        self.avatarIntroStartDate(startedAt: startedAt, includesPulse: includesPulse)
            .addingTimeInterval(TokenDailyBoardNarrativeAvatarReplacementAnimationRules.introDuration)
    }

    static func metadataIntroStartDate(
        typewriterCompletedAt: Date,
        includesMetadata: Bool)
        -> Date
    {
        includesMetadata ? typewriterCompletedAt : .distantPast
    }

    static func metadataIntroEndDate(
        typewriterCompletedAt: Date,
        includesMetadata: Bool,
        metadataIntroCompletedAt: Date? = nil)
        -> Date
    {
        guard includesMetadata else { return typewriterCompletedAt }
        return metadataIntroCompletedAt ?? typewriterCompletedAt
    }

    static func avatarReturnStartDate(
        typewriterCompletedAt: Date,
        startedAt: Date,
        includesPulse: Bool = true,
        includesMetadata: Bool,
        metadataIntroCompletedAt: Date? = nil)
        -> Date
    {
        max(
            typewriterCompletedAt.addingTimeInterval(self.avatarReturnDelayAfterTypewriter),
            self.avatarIntroEndDate(startedAt: startedAt, includesPulse: includesPulse),
            self.metadataIntroEndDate(
                typewriterCompletedAt: typewriterCompletedAt,
                includesMetadata: includesMetadata,
                metadataIntroCompletedAt: metadataIntroCompletedAt))
    }

    static func avatarReturnEndDate(
        typewriterCompletedAt: Date,
        startedAt: Date,
        includesPulse: Bool = true,
        includesMetadata: Bool,
        metadataIntroCompletedAt: Date? = nil,
        avatarReturnStartAt: Date? = nil)
        -> Date
    {
        let startAt = avatarReturnStartAt
            ?? self.avatarReturnStartDate(
                typewriterCompletedAt: typewriterCompletedAt,
                startedAt: startedAt,
                includesPulse: includesPulse,
                includesMetadata: includesMetadata,
                metadataIntroCompletedAt: metadataIntroCompletedAt)
        return startAt.addingTimeInterval(TokenDailyBoardNarrativeAvatarReplacementAnimationRules.returnDuration)
    }

    static func metadataOutroStartDate(
        typewriterCompletedAt: Date,
        startedAt: Date,
        includesPulse: Bool,
        includesMetadata: Bool,
        metadataIntroCompletedAt: Date? = nil,
        includesAvatarReturn: Bool,
        avatarReturnStartAt: Date? = nil,
        includesIdleShake: Bool)
        -> Date
    {
        let metadataIntroEnd = self.metadataIntroEndDate(
            typewriterCompletedAt: typewriterCompletedAt,
            includesMetadata: includesMetadata,
            metadataIntroCompletedAt: metadataIntroCompletedAt)
        let avatarReturnEnd = includesAvatarReturn
            ? self.avatarReturnEndDate(
                typewriterCompletedAt: typewriterCompletedAt,
                startedAt: startedAt,
                includesPulse: includesPulse,
                includesMetadata: includesMetadata,
                metadataIntroCompletedAt: metadataIntroCompletedAt,
                avatarReturnStartAt: avatarReturnStartAt)
            : typewriterCompletedAt
        let idleShakeEnd = includesIdleShake
            ? self.avatarIntroStartDate(startedAt: startedAt, includesPulse: includesPulse)
            .addingTimeInterval(TokenDailyBoardNarrativeAvatarReplacementAnimationRules.returnDuration)
            : typewriterCompletedAt
        return max(metadataIntroEnd, avatarReturnEnd, idleShakeEnd)
    }

    static func contentOutroStartDate(
        typewriterCompletedAt: Date,
        startedAt: Date,
        includesPulse: Bool,
        includesMetadata: Bool,
        metadataIntroCompletedAt: Date? = nil,
        includesAvatarReturn: Bool,
        avatarReturnStartAt: Date? = nil,
        includesIdleShake: Bool)
        -> Date
    {
        self.metadataOutroStartDate(
            typewriterCompletedAt: typewriterCompletedAt,
            startedAt: startedAt,
            includesPulse: includesPulse,
            includesMetadata: includesMetadata,
            metadataIntroCompletedAt: metadataIntroCompletedAt,
            includesAvatarReturn: includesAvatarReturn,
            avatarReturnStartAt: avatarReturnStartAt,
            includesIdleShake: includesIdleShake)
    }

    static func contentOutroEndDate(
        typewriterCompletedAt: Date,
        startedAt: Date,
        includesPulse: Bool,
        includesMetadata: Bool,
        metadataIntroCompletedAt: Date? = nil,
        includesAvatarReturn: Bool,
        avatarReturnStartAt: Date? = nil,
        includesIdleShake: Bool,
        contentOutroCompletedAt: Date? = nil)
        -> Date
    {
        contentOutroCompletedAt
            ?? self.contentOutroStartDate(
                typewriterCompletedAt: typewriterCompletedAt,
                startedAt: startedAt,
                includesPulse: includesPulse,
                includesMetadata: includesMetadata,
                metadataIntroCompletedAt: metadataIntroCompletedAt,
                includesAvatarReturn: includesAvatarReturn,
                avatarReturnStartAt: avatarReturnStartAt,
                includesIdleShake: includesIdleShake)
    }

    static func idlePresentationReadyDate(
        typewriterCompletedAt: Date,
        startedAt: Date,
        includesPulse: Bool,
        includesMetadata: Bool,
        metadataIntroCompletedAt: Date? = nil,
        includesIdleShake: Bool)
        -> Date
    {
        self.contentOutroEndDate(
            typewriterCompletedAt: typewriterCompletedAt,
            startedAt: startedAt,
            includesPulse: includesPulse,
            includesMetadata: includesMetadata,
            metadataIntroCompletedAt: metadataIntroCompletedAt,
            includesAvatarReturn: false,
            avatarReturnStartAt: nil,
            includesIdleShake: includesIdleShake)
    }

    static func pulseFadeEndDate(startedAt: Date, includesPulse: Bool = true) -> Date {
        self.pulsePreludeEndDate(startedAt: startedAt, includesPulse: includesPulse)
    }

    static func completionDate(
        typewriterCompletedAt: Date,
        startedAt: Date,
        includesPulse: Bool,
        includesAvatarReturn: Bool,
        includesIdleShake: Bool,
        includesMetadata: Bool,
        metadataIntroCompletedAt: Date? = nil,
        avatarReturnStartAt: Date? = nil,
        contentOutroCompletedAt: Date? = nil,
        includesQueueGap: Bool = true)
        -> Date
    {
        let pulseEnd = includesPulse
            ? self.pulseFadeEndDate(startedAt: startedAt, includesPulse: true)
            : typewriterCompletedAt
        let contentOutroEnd = self.contentOutroEndDate(
            typewriterCompletedAt: typewriterCompletedAt,
            startedAt: startedAt,
            includesPulse: includesPulse,
            includesMetadata: includesMetadata,
            metadataIntroCompletedAt: metadataIntroCompletedAt,
            includesAvatarReturn: includesAvatarReturn,
            avatarReturnStartAt: avatarReturnStartAt,
            includesIdleShake: includesIdleShake,
            contentOutroCompletedAt: contentOutroCompletedAt)
        let endDate = max(pulseEnd, contentOutroEnd)
        return includesQueueGap ? endDate.addingTimeInterval(self.queueGapDuration) : endDate
    }
}

private struct TokenDailyBoardConversationOnlyWindowPulseOverlay: View {
    let phase: TokenDailyBoardNarrativeWindowPulsePhase

    @State private var fillOpacity = 0.0
    @State private var sweepOpacity = 0.0
    @State private var sweepProgress = TokenDailyBoardConversationOnlyWindowPulseRules.sweepStartX
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { proxy in
            let configuration = self.phase.motionConfiguration
            let style = configuration.style
            let horizontalSweepWidth = max(
                proxy.size.width * TokenDailyBoardConversationOnlyWindowPulseRules.sweepWidthMultiplier,
                1)
            let verticalSweepHeight = max(
                proxy.size.height * TokenDailyBoardConversationOnlyWindowPulseRules.idleSweepHeightMultiplier,
                1)
            let horizontalTravel = proxy.size.width + horizontalSweepWidth
            let verticalTravel = proxy.size.height + verticalSweepHeight
            let horizontalOffset = (self.sweepProgress * horizontalTravel) - horizontalSweepWidth
            let verticalOffset = (self.sweepProgress * verticalTravel) - verticalSweepHeight

            ZStack {
                self.fillGradient(for: style)
                    .opacity(self.fillOpacity)

                self.sweepGradient(for: style)
                    .frame(
                        width: style == .idlePulse ? proxy.size.width * 1.2 : horizontalSweepWidth,
                        height: style == .idlePulse ? verticalSweepHeight : proxy.size.height * 1.28)
                    .offset(x: style == .idlePulse ? 0 : horizontalOffset, y: style == .idlePulse ? verticalOffset : 0)
                    .blur(radius: TokenDailyBoardConversationOnlyWindowPulseRules.sweepBlurRadius)
                    .opacity(self.sweepOpacity)
                    .blendMode(.plusLighter)
            }
            .compositingGroup()
        }
        .onAppear {
            self.handlePhaseChange(self.phase)
        }
        .onChange(of: self.phase) { _, newValue in
            self.handlePhaseChange(newValue)
        }
        .onDisappear {
            self.animationTask?.cancel()
            self.animationTask = nil
            self.resetAnimationState()
        }
    }

    private func handlePhaseChange(_ phase: TokenDailyBoardNarrativeWindowPulsePhase) {
        self.animationTask?.cancel()
        self.animationTask = nil

        switch phase {
        case .inactive:
            self.resetAnimationState()
        case let .active(sessionID, configuration):
            self.startLoop(for: sessionID, configuration: configuration)
        case let .fadingOut(_, configuration):
            self.startFadeOut(configuration: configuration)
        }
    }

    private func startLoop(for sessionID: Int, configuration: TokenDailyBoardNarrativePulseMotionConfiguration) {
        _ = sessionID
        self.animationTask = Task { @MainActor in
            self.prepareLoopStart(style: configuration.style)
            self.sweepProgress = self.startProgress(for: configuration.style)

            withAnimation(.easeOut(duration: configuration.duration * 0.24)) {
                self.fillOpacity = TokenDailyBoardConversationOnlyWindowPulseRules.fillPeakOpacity(
                    for: configuration.style)
                self.sweepOpacity = TokenDailyBoardConversationOnlyWindowPulseRules.sweepPeakOpacity(
                    for: configuration.style)
            }

            withAnimation(.linear(duration: configuration.duration)) {
                self.sweepProgress = self.endProgress(for: configuration.style)
            }

            let fadeDelay = max(configuration.duration - configuration.fadeOutDuration, 0)
            if fadeDelay > 0 {
                try? await Task.sleep(
                    nanoseconds: UInt64(fadeDelay * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: configuration.fadeOutDuration)) {
                self.fillOpacity = 0
                self.sweepOpacity = 0
                self.sweepProgress = self.endProgress(for: configuration.style)
            }

            try? await Task.sleep(
                nanoseconds: UInt64(configuration.fadeOutDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.resetAnimationState()
            self.animationTask = nil
        }
    }

    private func startFadeOut(configuration: TokenDailyBoardNarrativePulseMotionConfiguration) {
        self.animationTask = Task { @MainActor in
            withAnimation(.easeOut(duration: configuration.fadeOutDuration)) {
                self.fillOpacity = 0
                self.sweepOpacity = 0
                self.sweepProgress = self.endProgress(for: configuration.style)
            }

            try? await Task.sleep(
                nanoseconds: UInt64(configuration.fadeOutDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.resetAnimationState()
            self.animationTask = nil
        }
    }

    private func prepareLoopStart(style: TokenDailyBoardNarrativePulseStyle) {
        if self.fillOpacity == 0, self.sweepOpacity == 0 {
            self.sweepProgress = self.startProgress(for: style)
            self.fillOpacity = TokenDailyBoardConversationOnlyWindowPulseRules.fillPeakOpacity(for: style) * 0.7
            self.sweepOpacity = TokenDailyBoardConversationOnlyWindowPulseRules.sweepPeakOpacity(for: style) * 0.2
        }
    }

    private func resetAnimationState() {
        self.fillOpacity = 0
        self.sweepOpacity = 0
        self.sweepProgress = self.startProgress(for: self.phase.style)
    }

    private func startProgress(for style: TokenDailyBoardNarrativePulseStyle) -> CGFloat {
        switch style {
        case .standardRealtime:
            TokenDailyBoardConversationOnlyWindowPulseRules.sweepStartX
        case .idlePulse:
            TokenDailyBoardConversationOnlyWindowPulseRules.idleSweepStartY
        }
    }

    private func endProgress(for style: TokenDailyBoardNarrativePulseStyle) -> CGFloat {
        switch style {
        case .standardRealtime:
            TokenDailyBoardConversationOnlyWindowPulseRules.sweepEndX
        case .idlePulse:
            TokenDailyBoardConversationOnlyWindowPulseRules.idleSweepEndY
        }
    }

    private func fillGradient(for style: TokenDailyBoardNarrativePulseStyle) -> LinearGradient {
        switch style {
        case .standardRealtime:
            LinearGradient(
                colors: [
                    Color(red: 0.26, green: 0.08, blue: 0.10),
                    Color(red: 0.47, green: 0.18, blue: 0.18),
                    Color(red: 0.88, green: 0.82, blue: 0.76),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
        case .idlePulse:
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.08, blue: 0.16),
                    Color(red: 0.28, green: 0.12, blue: 0.24),
                    Color(red: 0.72, green: 0.56, blue: 0.68),
                ],
                startPoint: .bottom,
                endPoint: .top)
        }
    }

    private func sweepGradient(for style: TokenDailyBoardNarrativePulseStyle) -> LinearGradient {
        switch style {
        case .standardRealtime:
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: Color(red: 0.52, green: 0.16, blue: 0.16).opacity(0.26), location: 0.22),
                    .init(color: Color(red: 0.78, green: 0.42, blue: 0.34).opacity(0.36), location: 0.48),
                    .init(color: Color(red: 0.96, green: 0.92, blue: 0.86).opacity(0.42), location: 0.66),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing)
        case .idlePulse:
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: Color(red: 0.30, green: 0.14, blue: 0.32).opacity(0.18), location: 0.24),
                    .init(color: Color(red: 0.52, green: 0.30, blue: 0.56).opacity(0.24), location: 0.56),
                    .init(color: Color(red: 0.90, green: 0.82, blue: 0.90).opacity(0.26), location: 0.74),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .bottom,
                endPoint: .top)
        }
    }
}

enum TokenDailyBoardBackgroundPresentationRules {
    static let usesFullBleedGlassBackground = true
    static let usesCustomPanelSurface = false

    static func usesWindowGlassBackground(for displayMode: TokenDailyBoardDisplayMode) -> Bool {
        _ = displayMode
        return true
    }
}

private enum TokenDailyBoardSurfaceStyle {
    case panel
    case conversationPanel
    case hero
    case secondary
    case compact

    var cornerRadius: CGFloat {
        switch self {
        case .panel:
            TokenDailyBoardLayout.boardPanelCornerRadius
        case .conversationPanel:
            34
        case .hero:
            TokenDailyBoardLayout.heroCornerRadius
        case .secondary:
            TokenDailyBoardLayout.secondaryCornerRadius
        case .compact:
            TokenDailyBoardLayout.compactCornerRadius
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .panel:
            0
        case .conversationPanel:
            0
        case .hero:
            10
        case .secondary:
            7
        case .compact:
            2
        }
    }

    var shadowYOffset: CGFloat {
        switch self {
        case .panel:
            0
        case .conversationPanel:
            0
        case .hero:
            3
        case .secondary:
            3
        case .compact:
            1
        }
    }

    var usesGlass: Bool {
        TokenDailyBoardSurfacePresentationRules.usesGlass(for: self.role)
    }

    var tintOpacity: Double {
        switch self {
        case .panel:
            0
        case .conversationPanel:
            0
        case .hero:
            0
        case .secondary:
            0
        case .compact:
            0
        }
    }

    var fallbackFillOpacity: Double {
        switch self {
        case .panel:
            0.02
        case .conversationPanel:
            0.015
        case .hero:
            0.98
        case .secondary:
            0.94
        case .compact:
            0.84
        }
    }

    var strokeLineWidth: CGFloat {
        switch self {
        case .panel:
            0.45
        case .conversationPanel:
            0.4
        case .hero:
            0.78
        case .secondary, .compact:
            0.68
        }
    }

    var strokeOpacity: Double {
        switch self {
        case .panel:
            0.018
        case .conversationPanel:
            0.08
        case .hero:
            0.18
        case .secondary:
            0.18
        case .compact:
            0.14
        }
    }

    var role: TokenDailyBoardSurfaceRole {
        switch self {
        case .panel:
            .panel
        case .conversationPanel:
            .conversationPanel
        case .hero:
            .hero
        case .secondary:
            .secondary
        case .compact:
            .compact
        }
    }
}

enum TokenDailyBoardSurfacePresentationRules {
    static func usesGlass(for style: TokenDailyBoardSurfaceRole) -> Bool {
        switch style {
        case .conversationPanel:
            true
        case .panel, .hero, .secondary, .compact:
            false
        }
    }
}

enum TokenDailyBoardSurfaceRole {
    case panel
    case conversationPanel
    case hero
    case secondary
    case compact
}

private struct TokenDailyBoardGlassSurfaceModifier<ShapeType: InsettableShape>: ViewModifier {
    let shape: ShapeType
    let tint: Color
    let tintOpacity: Double
    let fallbackFill: Color
    let fallbackFillOpacity: Double
    let stroke: Color
    let strokeLineWidth: CGFloat
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowYOffset: CGFloat

    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .glassEffect(.regular, in: self.shape)
                .overlay {
                    if self.tintOpacity > 0 {
                        self.shape
                            .fill(self.tint.opacity(self.tintOpacity))
                    }
                }
                .overlay {
                    if self.strokeLineWidth > 0 {
                        self.shape
                            .stroke(self.stroke, lineWidth: self.strokeLineWidth)
                    }
                }
                .shadow(color: self.shadowColor, radius: self.shadowRadius, x: 0, y: self.shadowYOffset)
        } else {
            content
                .background(.ultraThinMaterial, in: self.shape)
                .overlay {
                    if self.fallbackFillOpacity > 0 {
                        self.shape
                            .fill(self.fallbackFill.opacity(self.fallbackFillOpacity))
                    }
                }
                .overlay {
                    if self.strokeLineWidth > 0 {
                        self.shape
                            .stroke(self.stroke, lineWidth: self.strokeLineWidth)
                    }
                }
                .shadow(color: self.shadowColor, radius: self.shadowRadius, x: 0, y: self.shadowYOffset)
        }
    }
}

private struct TokenDailyBoardSurfaceBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    let style: TokenDailyBoardSurfaceStyle

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: self.style.cornerRadius, style: .continuous)
    }

    var body: some View {
        let palette = TokenDailyBoardTheme.palette(for: self.colorScheme)
        let fillColor: Color = switch self.style {
        case .panel:
            palette.windowBase
        case .conversationPanel:
            palette.windowBase
        case .hero:
            palette.heroCardFill
        case .secondary:
            palette.secondaryCardFill
        case .compact:
            palette.compactCardFill
        }
        if self.style.usesGlass {
            self.shape
                .fill(.clear)
                .modifier(
                    TokenDailyBoardGlassSurfaceModifier(
                        shape: self.shape,
                        tint: self.tintColor(for: palette),
                        tintOpacity: self.style.tintOpacity,
                        fallbackFill: fillColor,
                        fallbackFillOpacity: self.style.fallbackFillOpacity,
                        stroke: self.strokeColor(for: palette).opacity(self.style.strokeOpacity),
                        strokeLineWidth: self.style.strokeLineWidth,
                        shadowColor: palette.shadow.opacity(0.03),
                        shadowRadius: self.style.shadowRadius,
                        shadowYOffset: self.style.shadowYOffset))
        } else {
            self.shape
                .fill(self.solidFill(for: palette))
                .overlay {
                    self.shape
                        .stroke(
                            self.strokeColor(for: palette).opacity(self.style.strokeOpacity),
                            lineWidth: self.style.strokeLineWidth)
                }
                .shadow(
                    color: palette.shadow.opacity(self.style == .panel ? 0.03 : 0.10),
                    radius: self.style.shadowRadius,
                    x: 0,
                    y: self.style.shadowYOffset)
        }
    }

    private func tintColor(for palette: TokenDailyBoardPalette) -> Color {
        switch self.style {
        case .panel:
            palette.windowGlow
        case .conversationPanel:
            palette.windowGlow
        case .hero:
            palette.heroCardFill
        case .secondary:
            palette.secondaryCardFill
        case .compact:
            palette.compactCardFill
        }
    }

    private func strokeColor(for palette: TokenDailyBoardPalette) -> Color {
        if self.style == .hero {
            return palette.heroStroke
        }
        return palette.cardStroke
    }

    private func solidFill(for palette: TokenDailyBoardPalette) -> AnyShapeStyle {
        switch self.style {
        case .panel:
            AnyShapeStyle(palette.windowBase.opacity(0.02))
        case .conversationPanel:
            AnyShapeStyle(palette.windowBase.opacity(0.012))
        case .compact:
            AnyShapeStyle(palette.compactCardFill.opacity(0.88))
        case .secondary:
            AnyShapeStyle(palette.secondaryCardFill.opacity(0.96))
        case .hero:
            AnyShapeStyle(palette.heroCardFill.opacity(0.985))
        }
    }
}

private struct TokenDailyBoardChromeBarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.tokenDailyBoardResponsiveMetrics) private var responsiveMetrics

    let strings: TokenDailyBoardStrings
    let statusText: String?
    let chromeMetrics: TokenDailyBoardWindowChromeMetrics

    private var palette: TokenDailyBoardPalette {
        TokenDailyBoardTheme.palette(for: self.colorScheme)
    }

    private var titleLeadingInset: CGFloat {
        max(
            self.chromeMetrics.titleLeadingInset
                - TokenDailyBoardLayout.windowHorizontalPadding
                - self.responsiveMetrics.contentInset,
            0)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(self.strings.dailyBoardWindowTitle)
                .font(self.responsiveMetrics.scaled(TokenDailyBoardTypography.windowTitle).font)
                .tracking(0.2)
                .foregroundStyle(self.palette.text)
                .lineLimit(1)

            Spacer(minLength: 0)

            if let statusText, !statusText.isEmpty {
                Text(statusText)
                    .font(self.responsiveMetrics.scaled(TokenDailyBoardTypography.chromeStatus).font)
                    .modifier(TokenDailyBoardDigitsModifier(usesMonospacedDigits: true))
                    .foregroundStyle(self.palette.mutedText)
                    .lineLimit(1)
            }
        }
        .padding(.leading, self.titleLeadingInset)
        .padding(.top, self.responsiveMetrics.chromeTopPadding)
    }
}

private struct TokenDailyBoardDigitsModifier: ViewModifier {
    let usesMonospacedDigits: Bool

    func body(content: Content) -> some View {
        if self.usesMonospacedDigits {
            content.monospacedDigit()
        } else {
            content
        }
    }
}

enum TokenDailyBoardPresentationRules {
    static let rendersCustomPanelBackground = false

    static func showsContentChrome(for cacheState: TokenDailyBoardCacheState) -> Bool {
        switch cacheState {
        case .ready:
            false
        case .missing, .failed:
            true
        }
    }
}

enum TokenDailyBoardDisplayContentRules {
    static func showsTodayModule(for displayMode: TokenDailyBoardDisplayMode) -> Bool {
        displayMode != .conversationOnly
    }
}

public enum TokenDailyBoardChromeVisibilityRules {
    public static func shouldShowWindowChrome(
        displayMode: TokenDailyBoardDisplayMode,
        isKeyWindow: Bool,
        isMouseInsideWindow: Bool)
        -> Bool
    {
        _ = displayMode
        _ = isKeyWindow
        _ = isMouseInsideWindow
        return true
    }

    public static func isVisible(
        for displayMode: TokenDailyBoardDisplayMode,
        storedVisibility: Bool)
        -> Bool
    {
        _ = displayMode
        _ = storedVisibility
        return true
    }
}

private struct TokenDailyBoardBoardPanelContainer<Content: View>: View {
    @Environment(\.tokenDailyBoardResponsiveMetrics) private var responsiveMetrics
    let topInset: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        let baseContent = self.content
            .padding(.horizontal, self.responsiveMetrics.contentInset)
            .padding(.top, self.topInset)
            .padding(.bottom, TokenDailyBoardLayout.boardPanelBottomInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        if TokenDailyBoardPresentationRules.rendersCustomPanelBackground {
            baseContent.background(TokenDailyBoardSurfaceBackground(style: .panel))
        } else {
            baseContent
        }
    }
}

private struct TokenDailyBoardConversationPanelContainer<Content: View>: View {
    let panelWidth: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        self.content
            .frame(width: self.panelWidth, alignment: .topLeading)
    }
}

enum TokenDailyBoardHeroPresentationRules {
    static let showsBoxedInsight = false
}

enum TokenDailyBoardDataRailPresentationRules {
    static let showsInstructionCountInAllSections = true
    static let showsSummaryInAllSections = false
}

private enum TokenDailyBoardMetricScale {
    case hero
    case secondary
    case compact
    case callout

    var labelFontSize: CGFloat {
        switch self {
        case .hero:
            12
        case .secondary:
            11
        case .compact:
            10
        case .callout:
            11
        }
    }

    var valueFontSize: CGFloat {
        switch self {
        case .hero:
            31
        case .secondary:
            23
        case .compact:
            16
        case .callout:
            20
        }
    }

    var suffixFontSize: CGFloat {
        switch self {
        case .hero:
            16
        case .secondary:
            13
        case .compact:
            11
        case .callout:
            12
        }
    }

    var detailFontSize: CGFloat {
        switch self {
        case .hero:
            11
        case .secondary, .callout:
            10
        case .compact:
            9
        }
    }
}

private struct TokenDailyBoardValueGroup: View {
    let label: String
    let value: TokenDailyBoardValueParts
    let scale: TokenDailyBoardMetricScale
    let textColor: Color
    let mutedTextColor: Color
    let alignment: HorizontalAlignment

    init(
        label: String,
        value: TokenDailyBoardValueParts,
        scale: TokenDailyBoardMetricScale,
        textColor: Color,
        mutedTextColor: Color,
        alignment: HorizontalAlignment = .leading)
    {
        self.label = label
        self.value = value
        self.scale = scale
        self.textColor = textColor
        self.mutedTextColor = mutedTextColor
        self.alignment = alignment
    }

    var body: some View {
        VStack(alignment: self.alignment, spacing: 3) {
            Text(self.label)
                .font(.system(size: self.scale.labelFontSize, weight: .medium))
                .tracking(0.15)
                .foregroundStyle(self.mutedTextColor)
                .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(self.value.magnitude)
                    .font(.system(size: self.scale.valueFontSize, weight: .semibold))
                    .foregroundStyle(self.textColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.56)

                if let suffix = self.value.suffix {
                    Text(suffix)
                        .font(.system(size: self.scale.suffixFontSize, weight: .semibold))
                        .foregroundStyle(self.textColor)
                        .lineLimit(1)
                }
            }
        }
    }
}

private struct TokenDailyBoardUsageSummaryView: View {
    let totalText: String
    let mainThreadText: String
    let primaryColor: Color
    let secondaryColor: Color
    let totalStyle: TokenDailyBoardTextStyle
    let mainThreadStyle: TokenDailyBoardTextStyle
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: self.alignment, spacing: 6) {
            Text(self.totalText)
                .font(self.totalStyle.font)
                .foregroundStyle(self.primaryColor)
                .modifier(TokenDailyBoardDigitsModifier(usesMonospacedDigits: self.totalStyle.usesMonospacedDigits))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(self.alignment == .trailing ? .trailing : .leading)

            Text(self.mainThreadText)
                .font(self.mainThreadStyle.font)
                .foregroundStyle(self.secondaryColor)
                .modifier(
                    TokenDailyBoardDigitsModifier(usesMonospacedDigits: self.mainThreadStyle.usesMonospacedDigits))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(self.alignment == .trailing ? .trailing : .leading)
        }
    }
}

private struct TokenDailyBoardCompactMetricView: View {
    let label: String
    let value: TokenDailyBoardValueParts
    let textColor: Color
    let mutedTextColor: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(self.formattedValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(self.textColor)
                .monospacedDigit()

            Text(self.label)
                .font(.system(size: 10, weight: .medium))
                .tracking(0.12)
                .foregroundStyle(self.mutedTextColor)
        }
    }

    private var formattedValue: String {
        if let suffix = self.value.suffix {
            return "\(self.value.magnitude)\(suffix)"
        }

        return self.value.magnitude
    }
}

private struct TokenDailyBoardInlineHeaderRow: View {
    @Environment(\.tokenDailyBoardResponsiveMetrics) private var responsiveMetrics
    let titleText: String
    let countText: String
    let totalText: String
    let mainThreadLabel: String
    let mainThreadText: String
    let titleStyle: TokenDailyBoardTextStyle
    let countStyle: TokenDailyBoardTextStyle
    let totalStyle: TokenDailyBoardTextStyle
    let detailStyle: TokenDailyBoardTextStyle
    let primaryColor: Color
    let secondaryColor: Color
    let titleTracking: CGFloat

    var body: some View {
        TokenDailyBoardModuleTopRow {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(self.titleText)
                    .font(self.responsiveMetrics.scaled(self.titleStyle).font)
                    .tracking(self.titleTracking)
                    .foregroundStyle(self.primaryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                if !self.countText.isEmpty {
                    self.separator

                    Text(self.countText)
                        .font(self.responsiveMetrics.scaled(self.countStyle).font)
                        .foregroundStyle(self.secondaryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
            }
        } dataContent: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(self.totalText)
                    .font(self.responsiveMetrics.scaled(self.totalStyle).font)
                    .foregroundStyle(self.primaryColor)
                    .modifier(TokenDailyBoardDigitsModifier(usesMonospacedDigits: self.totalStyle.usesMonospacedDigits))
                    .lineLimit(1)
                    .minimumScaleFactor(0.64)

                self.separator

                Text(self.mainThreadLabel)
                    .font(self.responsiveMetrics.scaled(self.detailStyle).font)
                    .foregroundStyle(self.secondaryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                self.separator

                Text(self.mainThreadText)
                    .font(self.responsiveMetrics.scaled(self.detailStyle).font)
                    .foregroundStyle(self.secondaryColor)
                    .modifier(TokenDailyBoardDigitsModifier(usesMonospacedDigits: self.detailStyle
                            .usesMonospacedDigits))
                    .lineLimit(1)
                    .minimumScaleFactor(0.64)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var separator: some View {
        Text("·")
            .font(self.responsiveMetrics.scaled(self.detailStyle).font)
            .foregroundStyle(self.secondaryColor.opacity(0.82))
            .lineLimit(1)
    }
}

private enum TokenDailyBoardChartStyle {
    case hero
    case secondary
    case compact

    var guideOpacity: Double {
        switch self {
        case .hero:
            0.16
        case .secondary:
            0.04
        case .compact:
            0
        }
    }

    var baselineOpacity: Double {
        switch self {
        case .hero:
            0.94
        case .secondary:
            0.72
        case .compact:
            0.52
        }
    }

    var spikeOpacity: Double {
        switch self {
        case .hero:
            0.96
        case .secondary:
            0.78
        case .compact:
            0.60
        }
    }

    var minimumSpikeHeight: CGFloat {
        switch self {
        case .hero:
            10
        case .secondary:
            8
        case .compact:
            7
        }
    }

    var baselineLineWidth: CGFloat {
        switch self {
        case .hero:
            2.4
        case .secondary:
            1.9
        case .compact:
            1.4
        }
    }

    func spikeLineWidth(for tier: TokenDailyBoardResponsiveMetrics.Tier) -> CGFloat {
        _ = tier
        return switch self {
        case .hero:
            0.82
        case .secondary:
            0.70
        case .compact:
            0.58
        }
    }
}

private struct TokenDailyBoardSpikeChart: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.tokenDailyBoardResponsiveMetrics) private var responsiveMetrics

    let day: TokenDailyBoardDayModel
    let scaleTopValue: Double
    let style: TokenDailyBoardChartStyle

    private var palette: TokenDailyBoardPalette {
        TokenDailyBoardTheme.palette(for: self.colorScheme)
    }

    private var guideColor: Color {
        switch self.style {
        case .hero:
            switch self.colorScheme {
            case .light:
                return Color(nsColor: NSColor(white: 0.0, alpha: 1))
            case .dark:
                return Color(nsColor: NSColor(white: 1.0, alpha: 1))
            @unknown default:
                return self.palette.guideLine
            }
        case .secondary, .compact:
            return self.palette.guideLine
        }
    }

    private var baselineColor: Color {
        switch self.style {
        case .hero:
            switch self.colorScheme {
            case .light:
                return Color(nsColor: NSColor(white: 0.0, alpha: 1))
            case .dark:
                return Color(nsColor: NSColor(white: 1.0, alpha: 1))
            @unknown default:
                return self.palette.baseline
            }
        case .secondary, .compact:
            return self.palette.baseline
        }
    }

    private var spikeColor: Color {
        switch self.style {
        case .hero:
            switch self.colorScheme {
            case .light:
                return Color(nsColor: NSColor(white: 0.0, alpha: 1))
            case .dark:
                return Color(nsColor: NSColor(white: 1.0, alpha: 1))
            @unknown default:
                return self.palette.spike
            }
        case .secondary, .compact:
            return self.palette.spike
        }
    }

    var body: some View {
        GeometryReader { geo in
            let baselineY = geo.size.height - 8
            let horizontalInset = TokenDailyBoardLayout.chartHorizontalInset
            let usableWidth = TokenDailyBoardChartGeometry.usableWidth(
                containerWidth: geo.size.width,
                horizontalInset: horizontalInset)
            let usableHeight = max(baselineY - TokenDailyBoardLayout.chartTopInset, 1)
            let spikeWidth = min(
                self.style.spikeLineWidth(for: self.responsiveMetrics.tier),
                max(usableWidth / CGFloat(TokenDailyBoardLayout.fiveMinuteBucketsPerDay), 0.58))

            ZStack(alignment: .topLeading) {
                if self.style.guideOpacity > 0 {
                    Path { path in
                        for marker in TokenDailyBoardLayout.chartGuides {
                            let x = TokenDailyBoardChartGeometry.boundaryX(
                                for: marker,
                                containerWidth: geo.size.width,
                                horizontalInset: horizontalInset)
                            path.move(to: CGPoint(x: x, y: TokenDailyBoardLayout.chartTopInset))
                            path.addLine(to: CGPoint(x: x, y: baselineY))
                        }
                    }
                    .stroke(
                        self.guideColor.opacity(self.style.guideOpacity),
                        style: StrokeStyle(lineWidth: 0.6, dash: [3, 5]))
                }

                Path { path in
                    path.move(to: CGPoint(x: horizontalInset, y: baselineY))
                    path.addLine(to: CGPoint(x: geo.size.width - horizontalInset, y: baselineY))
                }
                .stroke(
                    self.baselineColor.opacity(self.style.baselineOpacity),
                    style: StrokeStyle(
                        lineWidth: self.style.baselineLineWidth,
                        lineCap: .round,
                        lineJoin: .round))

                Path { path in
                    for point in self.day.fiveMinutePoints where point.rawTokens > 0 {
                        let x = TokenDailyBoardChartGeometry.spikeCenterX(
                            for: point.bucketIndex,
                            containerWidth: geo.size.width,
                            horizontalInset: horizontalInset)
                        let spikeHeight = self.spikeHeight(for: point, usableHeight: usableHeight)
                        path.move(to: CGPoint(x: x, y: baselineY))
                        path.addLine(to: CGPoint(x: x, y: baselineY - spikeHeight))
                    }
                }
                .stroke(
                    self.spikeColor.opacity(self.style.spikeOpacity),
                    style: StrokeStyle(lineWidth: spikeWidth, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private func spikeHeight(for point: TokenDailyBoardFiveMinutePoint, usableHeight: CGFloat) -> CGFloat {
        guard self.scaleTopValue > 0 else { return self.style.minimumSpikeHeight }
        let normalized = CGFloat(point.displayValue / self.scaleTopValue)
        return max(self.style.minimumSpikeHeight, usableHeight * normalized)
    }
}

private struct TokenDailyBoardEmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.tokenDailyBoardResponsiveMetrics) private var responsiveMetrics

    let title: String
    let message: String

    private var palette: TokenDailyBoardPalette {
        TokenDailyBoardTheme.palette(for: self.colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(self.title)
                .font(self.responsiveMetrics.scaled(TokenDailyBoardTypography.emptyTitle).font)
                .foregroundStyle(self.palette.text)

            Text(self.message)
                .font(self.responsiveMetrics.scaled(TokenDailyBoardTypography.emptyMessage).font)
                .foregroundStyle(self.palette.mutedText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, self.responsiveMetrics.secondaryVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TokenDailyBoardHourRuler: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.tokenDailyBoardResponsiveMetrics) private var responsiveMetrics

    let horizontalInset: CGFloat
    let textColor: Color?

    init(horizontalInset: CGFloat = TokenDailyBoardLayout.chartHorizontalInset, textColor: Color? = nil) {
        self.horizontalInset = horizontalInset
        self.textColor = textColor
    }

    private var palette: TokenDailyBoardPalette {
        TokenDailyBoardTheme.palette(for: self.colorScheme)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(TokenDailyBoardLayout.chartGuides, id: \.self) { marker in
                    let boundaryX = TokenDailyBoardChartGeometry.boundaryX(
                        for: marker,
                        containerWidth: geo.size.width,
                        horizontalInset: self.horizontalInset)

                    Text("\(marker)")
                        .font(self.responsiveMetrics.scaled(TokenDailyBoardTypography.hourLabel).font)
                        .foregroundStyle(self.textColor ?? self.palette.mutedText)
                        .frame(width: self.responsiveMetrics.hourLabelWidth, alignment: self.textAlignment(for: marker))
                        .offset(x: self.labelOriginX(for: marker, boundaryX: boundaryX))
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(height: self.responsiveMetrics.hourRulerHeight)
    }

    private func textAlignment(for marker: Int) -> Alignment {
        if marker == 0 {
            return .leading
        }
        if marker == 24 {
            return .trailing
        }
        return .center
    }

    private func labelOriginX(for marker: Int, boundaryX: CGFloat) -> CGFloat {
        if marker == 0 {
            return boundaryX
        }
        if marker == 24 {
            return boundaryX - self.responsiveMetrics.hourLabelWidth
        }
        return boundaryX - (self.responsiveMetrics.hourLabelWidth / 2)
    }
}

private struct TokenDailyBoardSectionDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    private var palette: TokenDailyBoardPalette {
        TokenDailyBoardTheme.palette(for: self.colorScheme)
    }

    var body: some View {
        Rectangle()
            .fill(self.palette.guideLine.opacity(TokenDailyBoardLayout.sectionDividerOpacity))
            .frame(height: TokenDailyBoardLayout.sectionDividerThickness)
    }
}

enum TokenDailyBoardComparisonPresentationRules {
    static let usesCapsule = false
}

private struct TokenDailyBoardComparisonBadge: View {
    let text: String
    let accentColor: Color

    var body: some View {
        Text(self.text)
            .font(TokenDailyBoardTypography.comparison.font)
            .foregroundStyle(self.accentColor)
            .lineLimit(1)
    }
}

private struct TokenDailyBoardModuleTopRow<DateContent: View, DataContent: View>: View {
    @Environment(\.tokenDailyBoardResponsiveMetrics) private var responsiveMetrics
    @ViewBuilder let dateContent: DateContent
    @ViewBuilder let dataContent: DataContent

    var body: some View {
        HStack(alignment: .top, spacing: self.responsiveMetrics.sectionColumnSpacing) {
            self.dateContent
                .frame(width: self.responsiveMetrics.dateColumnWidth, alignment: .leading)

            Spacer(minLength: self.responsiveMetrics.sectionColumnSpacing)

            self.dataContent
                .frame(width: self.responsiveMetrics.dataColumnWidth, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TokenDailyBoardHeroDayCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.tokenDailyBoardResponsiveMetrics) private var responsiveMetrics

    let today: TokenDailyBoardDayModel
    let scaleTopValue: Double
    let strings: TokenDailyBoardStrings
    let usesRelativeTitles: Bool

    private var palette: TokenDailyBoardPalette {
        TokenDailyBoardTheme.palette(for: self.colorScheme)
    }

    private var totalUsageText: String {
        self.strings.compactTokenText(self.today.totalTokens)
    }

    private var mainThreadUsageText: String {
        self.strings.compactTokenText(self.today.mainThreadTokens)
    }

    private var humanInstructionText: String {
        self.strings.dailyBoardShortInstructionCountText(self.today.instructionCount)
    }

    private var inkTextColor: Color {
        switch self.colorScheme {
        case .light:
            return Color(nsColor: NSColor(white: 0.08, alpha: 0.98))
        case .dark:
            return Color(nsColor: NSColor(white: 0.95, alpha: 0.98))
        @unknown default:
            return self.palette.text
        }
    }

    private var inkMutedTextColor: Color {
        switch self.colorScheme {
        case .light:
            return Color(nsColor: NSColor(white: 0.30, alpha: 0.86))
        case .dark:
            return Color(nsColor: NSColor(white: 0.72, alpha: 0.82))
        @unknown default:
            return self.palette.mutedText
        }
    }

    private var titleText: String {
        TokenDailyBoardDayTitleFormatter.title(
            for: self.today,
            strings: self.strings,
            usesRelativeTitles: self.usesRelativeTitles)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TokenDailyBoardInlineHeaderRow(
                titleText: self.titleText,
                countText: self.humanInstructionText,
                totalText: self.totalUsageText,
                mainThreadLabel: self.strings.dailyBoardMainThreadLabel,
                mainThreadText: self.mainThreadUsageText,
                titleStyle: TokenDailyBoardTypography.todayDate,
                countStyle: TokenDailyBoardTypography.heroInstructionCount,
                totalStyle: TokenDailyBoardTypography.heroTotal,
                detailStyle: TokenDailyBoardTypography.heroMainThread,
                primaryColor: self.inkTextColor,
                secondaryColor: self.inkMutedTextColor,
                titleTracking: -0.24)
                .padding(.top, self.responsiveMetrics.heroVerticalPadding)
                .padding(.bottom, 18)

            TokenDailyBoardHourRuler(
                horizontalInset: TokenDailyBoardLayout.chartHorizontalInset,
                textColor: self.inkMutedTextColor)
                .padding(.bottom, 14)

            TokenDailyBoardSpikeChart(day: self.today, scaleTopValue: self.scaleTopValue, style: .hero)
                .frame(height: self.responsiveMetrics.heroChartHeight)
                .padding(.bottom, self.responsiveMetrics.heroVerticalPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TokenDailyBoardSecondaryDayCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.tokenDailyBoardResponsiveMetrics) private var responsiveMetrics

    let day: TokenDailyBoardDayModel
    let scaleTopValue: Double
    let strings: TokenDailyBoardStrings
    let usesRelativeTitles: Bool

    private var palette: TokenDailyBoardPalette {
        TokenDailyBoardTheme.palette(for: self.colorScheme)
    }

    private var totalUsageText: String {
        self.strings.compactTokenText(self.day.totalTokens)
    }

    private var mainThreadUsageText: String {
        self.strings.compactTokenText(self.day.mainThreadTokens)
    }

    private var humanInstructionText: String {
        self.strings.dailyBoardShortInstructionCountText(self.day.instructionCount)
    }

    private var titleText: String {
        TokenDailyBoardDayTitleFormatter.title(
            for: self.day,
            strings: self.strings,
            usesRelativeTitles: self.usesRelativeTitles)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TokenDailyBoardInlineHeaderRow(
                titleText: self.titleText,
                countText: self.humanInstructionText,
                totalText: self.totalUsageText,
                mainThreadLabel: self.strings.dailyBoardMainThreadLabel,
                mainThreadText: self.mainThreadUsageText,
                titleStyle: TokenDailyBoardTypography.secondaryDate,
                countStyle: TokenDailyBoardTypography.secondaryInstructionCount,
                totalStyle: TokenDailyBoardTypography.secondaryTotal,
                detailStyle: TokenDailyBoardTypography.secondaryMainThread,
                primaryColor: self.palette.text,
                secondaryColor: self.palette.mutedText,
                titleTracking: -0.1)
                .padding(.top, self.responsiveMetrics.secondaryVerticalPadding)
                .padding(.bottom, 16)

            TokenDailyBoardSpikeChart(day: self.day, scaleTopValue: self.scaleTopValue, style: .secondary)
                .frame(height: self.responsiveMetrics.secondaryChartHeight)
                .padding(.bottom, self.responsiveMetrics.secondaryVerticalPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TokenDailyBoardCompactDayRowView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.tokenDailyBoardResponsiveMetrics) private var responsiveMetrics

    let day: TokenDailyBoardDayModel
    let scaleTopValue: Double
    let strings: TokenDailyBoardStrings
    let usesRelativeTitles: Bool

    private var palette: TokenDailyBoardPalette {
        TokenDailyBoardTheme.palette(for: self.colorScheme)
    }

    private var totalUsageText: String {
        self.strings.compactTokenText(self.day.totalTokens)
    }

    private var mainThreadUsageText: String {
        self.strings.compactTokenText(self.day.mainThreadTokens)
    }

    private var humanInstructionText: String {
        self.strings.dailyBoardShortInstructionCountText(self.day.instructionCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TokenDailyBoardInlineHeaderRow(
                titleText: TokenDailyBoardDayTitleFormatter.title(
                    for: self.day,
                    strings: self.strings,
                    usesRelativeTitles: self.usesRelativeTitles),
                countText: self.humanInstructionText,
                totalText: self.totalUsageText,
                mainThreadLabel: self.strings.dailyBoardMainThreadLabel,
                mainThreadText: self.mainThreadUsageText,
                titleStyle: TokenDailyBoardTypography.archiveDate,
                countStyle: TokenDailyBoardTypography.archiveInstructionCount,
                totalStyle: TokenDailyBoardTypography.archiveTotal,
                detailStyle: TokenDailyBoardTypography.archiveMainThread,
                primaryColor: self.palette.text,
                secondaryColor: self.palette.mutedText,
                titleTracking: 0)
                .padding(.top, self.responsiveMetrics.compactVerticalPadding)
                .padding(.bottom, 10)

            TokenDailyBoardSpikeChart(day: self.day, scaleTopValue: self.scaleTopValue, style: .compact)
                .frame(maxWidth: .infinity)
                .frame(height: self.responsiveMetrics.compactChartHeight)
                .padding(.bottom, self.responsiveMetrics.compactVerticalPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TokenDailyBoardGlassCircleButton<Label: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let size: CGFloat
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void
    @ViewBuilder let label: Label

    private var shape: Circle {
        Circle()
    }

    private var strokeColor: Color {
        switch self.colorScheme {
        case .light:
            return Color.black.opacity(self.isSelected ? 0.16 : 0.08)
        case .dark:
            return Color.white.opacity(self.isSelected ? 0.20 : 0.10)
        @unknown default:
            return Color.primary.opacity(0.10)
        }
    }

    private var shadowColor: Color {
        switch self.colorScheme {
        case .light:
            return Color.black.opacity(0.04)
        case .dark:
            return Color.black.opacity(0.18)
        @unknown default:
            return Color.black.opacity(0.08)
        }
    }

    var body: some View {
        Button(action: self.action) {
            self.label
                .frame(width: self.size, height: self.size)
                .background {
                    if #available(macOS 26, *) {
                        Color.clear
                            .glassEffect(.regular, in: self.shape)
                    } else {
                        self.shape
                            .fill(.ultraThinMaterial)
                    }
                }
                .overlay {
                    self.shape
                        .stroke(self.strokeColor, lineWidth: self.isSelected ? 0.9 : 0.7)
                }
                .shadow(color: self.shadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!self.isEnabled)
        .opacity(self.isEnabled ? 1 : 0.26)
    }
}

private struct TokenDailyBoardMonthPagerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.tokenDailyBoardResponsiveMetrics) private var responsiveMetrics

    let selectedYear: Int
    let selectedMonth: Int
    let availableMonthsWithData: Set<Int>
    let previousYear: Int?
    let nextYear: Int?
    let buttonDiameter: CGFloat
    let onSelectMonth: (Int) -> Void
    let onSelectPreviousYear: () -> Void
    let onSelectNextYear: () -> Void

    private var textColor: Color {
        switch self.colorScheme {
        case .light:
            return Color.black.opacity(0.82)
        case .dark:
            return Color.white.opacity(0.88)
        @unknown default:
            return .primary
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: self.responsiveMetrics.monthPagerOuterSpacing) {
            self.yearButton(symbol: "chevron.left", targetYear: self.previousYear, action: self.onSelectPreviousYear)

            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: self.responsiveMetrics.monthPagerMonthSpacing) {
                ForEach(1...12, id: \.self) { month in
                    TokenDailyBoardGlassCircleButton(
                        size: self.buttonDiameter,
                        isSelected: month == self.selectedMonth,
                        isEnabled: month == self.selectedMonth || self.availableMonthsWithData.contains(month))
                    {
                        self.onSelectMonth(month)
                    } label: {
                        Text("\(month)")
                            .font(.system(
                                size: max((self.buttonDiameter * 0.42) * self.responsiveMetrics.monthPagerFontScale, 6),
                                weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(self.textColor)
                    }
                }
            }

            Spacer(minLength: 0)

            self.yearButton(symbol: "chevron.right", targetYear: self.nextYear, action: self.onSelectNextYear)
        }
    }

    @ViewBuilder
    private func yearButton(symbol: String, targetYear: Int?, action: @escaping () -> Void) -> some View {
        if targetYear != nil {
            TokenDailyBoardGlassCircleButton(
                size: self.buttonDiameter,
                isSelected: false,
                isEnabled: true,
                action: action)
            {
                Image(systemName: symbol)
                    .font(.system(
                        size: max((self.buttonDiameter * 0.5) * self.responsiveMetrics.monthPagerFontScale, 7),
                        weight: .semibold))
                    .foregroundStyle(self.textColor)
            }
        } else {
            Color.clear
                .frame(width: self.buttonDiameter, height: self.buttonDiameter)
        }
    }
}

private struct TokenDailyBoardWindowAccessor: NSViewRepresentable {
    let onResolveWindow: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            self.onResolveWindow(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            self.onResolveWindow(nsView.window)
        }
    }
}

@MainActor
public struct TokenDailyBoardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var store: TokenDailyBoardStore
    let strings: TokenDailyBoardStrings
    let chromeMetrics: TokenDailyBoardWindowChromeMetrics
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var focusedNarrativeSequenceSignature = ""
    @State private var focusedNarrativeRealtimeSignature = ""
    @State private var conversationOnlyVariantCycleIndex: Int?
    @State private var conversationOnlyPreferredAvatarSlot: CodexDailyAvatarResolvedSlot?
    @State private var conversationOnlyAvatarReplacementSequenceID = 0
    @State private var conversationOnlyAvatarIdleShakeSequenceID = 0
    @State private var knownNarrativeSourceIDs: Set<String> = []
    @State private var renderedNarrativeSourceItem: TokenDailyBoardNarrativePresentationSourceItem?
    @State private var renderedNarrativePreferredAvatarSlot: CodexDailyAvatarResolvedSlot?
    @State private var narrativePresentationQueue: [TokenDailyBoardNarrativePresentationQueueItem] = []
    @State private var activeNarrativeSession: TokenDailyBoardNarrativePresentationSession?
    @State private var nextNarrativePresentationItemID = 0
    @State private var pendingNarrativePulsePreludeTask: Task<Void, Never>?
    @State private var pendingNarrativeAvatarIntroTask: Task<Void, Never>?
    @State private var pendingNarrativeMetadataIntroTask: Task<Void, Never>?
    @State private var pendingNarrativeAvatarReturnTask: Task<Void, Never>?
    @State private var pendingNarrativeContentOutroTask: Task<Void, Never>?
    @State private var pendingNarrativeSessionCompletionTask: Task<Void, Never>?
    @State private var pendingIdlePulseTask: Task<Void, Never>?
    @State private var pendingIdleDismissalTask: Task<Void, Never>?
    @State private var narrativeWindowPulsePhase: TokenDailyBoardNarrativeWindowPulsePhase = .inactive
    @State private var idleCountdownAnchor: Date?
    @State private var lastNonIdleNarrativeCompletionAt: Date?
    @State private var lastPresentedIdleAt: Date?
    @State private var idlePersistentContentOpacity = 1.0
    @State private var idlePersistentContentVerticalOffset: CGFloat = 0
    @State private var hasBootstrappedNarrativePresentation = false
    @State private var showsNarrativeEditor = false
    @State private var hostWindow: NSWindow?
    @State private var renderedDisplayMode: TokenDailyBoardDisplayMode
    @State private var isSwitchingDisplayMode = false
    @State private var suppressesNarrativeAutoAnimations = false
    @State private var displayModeContentOpacity = 1.0
    @State private var pendingDisplayModeTransitionTask: Task<Void, Never>?

    public init(
        store: TokenDailyBoardStore,
        strings: TokenDailyBoardStrings = TokenDailyBoardStrings(),
        chromeMetrics: TokenDailyBoardWindowChromeMetrics = .init(
            titleLeadingInset: TokenDailyBoardWindowChromeMetrics.fallbackLeadingInset))
    {
        let components = Calendar.autoupdatingCurrent.dateComponents([.year, .month], from: Date())
        self.store = store
        self.strings = strings
        self.chromeMetrics = chromeMetrics
        self._selectedYear = State(initialValue: components.year ?? 1970)
        self._selectedMonth = State(initialValue: components.month ?? 1)
        self._renderedDisplayMode = State(initialValue: store.boardDisplayMode)
    }

    private var model: TokenDailyBoardModel {
        TokenDailyBoardModelBuilder.makeModel(
            tokenDays: self.store.days,
            regularTokenDays: self.store.regularDays,
            fiveMinuteBuckets: self.store.fiveMinuteBuckets,
            outboundMessageDays: self.store.outboundMessageDays,
            selectedYear: self.selectedYear,
            selectedMonth: self.selectedMonth)
    }

    private var allNarrativeDays: [TokenDailyBoardDayModel] {
        TokenDailyBoardModelBuilder.allAvailableDayModels(
            tokenDays: self.store.days,
            regularTokenDays: self.store.regularDays,
            fiveMinuteBuckets: self.store.fiveMinuteBuckets,
            outboundMessageDays: self.store.outboundMessageDays)
    }

    private var palette: TokenDailyBoardPalette {
        TokenDailyBoardTheme.palette(for: self.colorScheme)
    }

    private var narrativeCatalog: TokenDailyBoardNarrativeCatalog {
        TokenDailyBoardNarrativeCatalog(userEntries: self.store.narrativeUserEntries)
    }

    private var activeDisplayMode: TokenDailyBoardDisplayMode {
        self.renderedDisplayMode
    }

    private var suppressesNarrativeChanges: Bool {
        TokenDailyBoardDisplayModeTransitionRules.shouldSuppressNarrativeAutoAnimations(
            isSwitchingDisplayMode: self.isSwitchingDisplayMode,
            suppressesNarrativeAutoAnimations: self.suppressesNarrativeAutoAnimations)
    }

    private var chromeStatusText: String? {
        switch self.store.cacheState {
        case .ready:
            nil
        case .missing:
            self.strings.cacheMissingTitle
        case let .failed(message):
            self.strings.cacheErrorTitle(message)
        }
    }

    private var emptyState: (title: String, message: String)? {
        switch self.store.cacheState {
        case .ready:
            nil
        case .missing:
            (self.strings.cacheMissingTitle, self.strings.cacheMissingMessage)
        case let .failed(message):
            (self.strings.cacheErrorTitle(message), self.strings.cacheErrorMessage(message))
        }
    }

    private var monthEmptyState: (title: String, message: String)? {
        guard self.store.cacheState == .ready, !self.model.hasDataInSelectedMonth else { return nil }
        return (
            self.strings.dailyBoardEmptyMonthTitle,
            self.strings.dailyBoardEmptyMonthMessage(year: self.selectedYear, month: self.selectedMonth))
    }

    private var heroDay: TokenDailyBoardDayModel? {
        self.model.days.first
    }

    private var comparisonReferenceDay: TokenDailyBoardDayModel? {
        self.model.days.dropFirst().first
    }

    private var secondaryDays: [TokenDailyBoardDayModel] {
        Array(self.model.days.dropFirst().prefix(2))
    }

    private var compactDays: [TokenDailyBoardDayModel] {
        Array(self.model.days.dropFirst(3))
    }

    private var showsContentChrome: Bool {
        TokenDailyBoardPresentationRules.showsContentChrome(for: self.store.cacheState)
    }

    private var usesRelativeTitles: Bool {
        let components = Calendar.autoupdatingCurrent.dateComponents([.year, .month], from: Date())
        return self.selectedYear == components.year && self.selectedMonth == components.month
    }

    private var focusedNarrativeSourceItems: [TokenDailyBoardNarrativePresentationSourceItem] {
        self.store.realtimeNarrativeProjection.sourceItems
    }

    private var focusedRealtimeSourceItems: [TokenDailyBoardNarrativePresentationSourceItem] {
        self.store.realtimeNarrativeProjection.sourceItems
    }

    private var hasEligibleIdleRealtimeActivity: Bool {
        self.store.realtimeNarrativeProjection.hasEligibleIdleRealtimeActivity
    }

    private var displayedNarrativeSentence: TokenDailyBoardNarrativeSentence? {
        self.activeNarrativeSession?.item.sentence ?? self.renderedNarrativeSourceItem?.sentence
    }

    private var showsPersistentIdlePresentation: Bool {
        self.activeNarrativeSession == nil
            && self.renderedNarrativeSourceItem?.groupKind == .waitingGroup
    }

    private var focusedNarrativeSignature: String {
        self.store.realtimeNarrativeProjection.sequenceSignature
    }

    private var realtimeNarrativeSignature: String {
        self.store.realtimeNarrativeProjection.sequenceSignature
    }

    private func narrativeTopContentInset(for responsiveMetrics: TokenDailyBoardResponsiveMetrics) -> CGFloat {
        _ = responsiveMetrics
        return TokenDailyBoardScrollPresentationRules.topContentInset
    }

    private var topContentPadding: CGFloat {
        if self.showsContentChrome {
            return TokenDailyBoardLayout.titleBarTopPadding
        }

        return TokenDailyBoardLayout.titleBarHiddenTopPadding
    }

    private var boardTopInset: CGFloat {
        self.showsContentChrome ? TokenDailyBoardLayout.boardPanelChromeTopInset : 0
    }

    private var monthButtonDiameter: CGFloat {
        max(self.chromeMetrics.buttonDiameter, TokenDailyBoardWindowChromeMetrics.fallbackButtonDiameter)
    }

    private var previousAvailableYear: Int? {
        self.model.availableYears.last(where: { $0 < self.selectedYear })
    }

    private var nextAvailableYear: Int? {
        self.model.availableYears.first(where: { $0 > self.selectedYear })
    }

    private var showsMonthPager: Bool {
        self.store.cacheState == .ready
            && self.activeDisplayMode == .fullBoard
            && !self.model.availableYears.isEmpty
    }

    private var showsHeroDay: Bool {
        TokenDailyBoardDisplayContentRules.showsTodayModule(for: self.activeDisplayMode)
    }

    private var showsSecondaryDays: Bool {
        self.activeDisplayMode == .fullBoard
    }

    private var showsCompactDays: Bool {
        self.activeDisplayMode == .fullBoard
    }

    private var showsNarrativeOverlay: Bool {
        true
    }

    private var showsModeChromeButtons: Bool {
        true
    }

    private var usesWindowGlassBackground: Bool {
        TokenDailyBoardBackgroundPresentationRules.usesWindowGlassBackground(
            for: self.activeDisplayMode)
    }

    private var conversationOnlyWindowAppearance: TokenDailyBoardConversationOnlyWindowAppearance {
        TokenDailyBoardConversationOnlyDebugRules.resolvedWindowAppearance(
            self.store.conversationOnlyDebugTuning,
            for: self.activeDisplayMode)
    }

    private var showsNarrativeWindowPulse: Bool {
        TokenDailyBoardConversationOnlyWindowPulseRules.isEnabled(
            self.store.conversationOnlyDebugTuning,
            for: self.activeDisplayMode)
    }

    private var showsNarrativeAvatarReplacementAnimation: Bool {
        TokenDailyBoardNarrativeAvatarReplacementAnimationRules.isEnabled(
            self.store.conversationOnlyDebugTuning,
            displayMode: self.activeDisplayMode)
    }

    private var activeNarrativeAvatarSlot: CodexDailyAvatarResolvedSlot? {
        if let session = self.activeNarrativeSession {
            switch self.activeNarrativeAvatarPhase {
            case .resting:
                return self.renderedNarrativePreferredAvatarSlot
            case .introDefault, .holdingDefault, .settlingDefault:
                return nil
            case .introVariant, .holdingVariant, .settlingVariant:
                return session.item.preferredAvatarSlot
            }
        }

        return self.renderedNarrativePreferredAvatarSlot
    }

    private var activeNarrativeAvatarReplacementSequenceID: Int {
        self.conversationOnlyAvatarReplacementSequenceID
    }

    private var activeNarrativeAvatarIdleShakeSequenceID: Int {
        self.conversationOnlyAvatarIdleShakeSequenceID
    }

    private var activeNarrativeTypewriterCompletionToken: String {
        self.activeNarrativeSession.map { "session-\($0.item.id)" } ?? "idle"
    }

    private var activeNarrativeMetadataCompletionToken: String {
        self.activeNarrativeSession.map { "session-\($0.item.id)-metadata" } ?? "idle-metadata"
    }

    private var conversationOnlyAnimationProfile: TokenDailyBoardConversationOnlyResolvedAnimationProfile {
        TokenDailyBoardConversationOnlyAnimationProfileRules.resolvedProfile(
            tuning: TokenDailyBoardConversationOnlyDebugRules.resolvedTuning(
                self.store.conversationOnlyDebugTuning,
                for: .conversationOnly))
    }

    private var activeNarrativeTypewriterStartDelay: TimeInterval {
        if let session = self.activeNarrativeSession {
            max(session.typewriterStartAt.timeIntervalSince(session.startedAt), 0)
        } else {
            0
        }
    }

    private var activeNarrativeMetadataStartDelay: TimeInterval {
        if let session = self.activeNarrativeSession,
           let metadataStartedAt = session.metadataIntroStartedAt
        {
            return max(metadataStartedAt.timeIntervalSince(session.startedAt), 0)
        }
        return 0
    }

    private var activeNarrativeBodyCharactersPerSecond: Double {
        self.activeNarrativeSession?.bodyCharactersPerSecond
            ?? TokenDailyBoardNarrativeLayout.typewriterCharactersPerSecond
    }

    private var activeNarrativeMetadataCharactersPerSecond: Double {
        self.activeNarrativeSession?.metadataCharactersPerSecond
            ?? TokenDailyBoardNarrativeLayout.typewriterCharactersPerSecond
    }

    private var activeNarrativeAvatarMotionConfiguration: TokenDailyBoardNarrativeAvatarMotionConfiguration {
        self.activeNarrativeSession?.avatarMotionConfiguration ?? .standard
    }

    private var activeNarrativeDisplayedMetadataText: String? {
        if let session = self.activeNarrativeSession,
           let metadataText = session.item.sentence.metadataText,
           !metadataText.isEmpty
        {
            return metadataText
        }

        if let renderedSourceItem = self.renderedNarrativeSourceItem,
           let metadataText = renderedSourceItem.sentence.metadataText,
           !metadataText.isEmpty
        {
            return metadataText
        }

        return nil
    }

    private var activeNarrativeContentOpacity: Double {
        if self.showsPersistentIdlePresentation {
            return self.idlePersistentContentOpacity
        }

        return 1
    }

    private var activeNarrativeContentVerticalOffset: CGFloat {
        if self.showsPersistentIdlePresentation {
            return TokenDailyBoardNarrativeIdleHandoffRules.dismissVerticalOffset
        }

        return 0
    }

    private var activeNarrativeAvatarPhase: TokenDailyBoardNarrativeAvatarPhase {
        guard let session = self.activeNarrativeSession else { return .resting }

        switch session.item.avatarTriggerStyle {
        case .none:
            return .resting
        case .defaultGroupIntro:
            if session.hasStartedReturn {
                return .settlingDefault
            }
            guard session.hasActivatedAvatarIntro else { return .resting }
            let introEndAt = session.avatarIntroStartAt
                .addingTimeInterval(TokenDailyBoardNarrativeAvatarReplacementAnimationRules.introDuration)
            if Date() < introEndAt {
                return .introDefault
            }
            return .holdingDefault
        case .variantReplacement:
            if session.hasStartedReturn {
                return .settlingVariant
            }
            guard session.hasActivatedAvatarIntro else { return .resting }
            let introEndAt = session.avatarIntroStartAt
                .addingTimeInterval(TokenDailyBoardNarrativeAvatarReplacementAnimationRules.introDuration)
            if Date() < introEndAt {
                return .introVariant
            }
            return .holdingVariant
        }
    }

    private var animatesDisplayedNarrativeTypewriter: Bool {
        self.activeNarrativeSession != nil
    }

    private func conversationOnlyNarrativeOverlay(
        sentence: TokenDailyBoardNarrativeSentence,
        containerSize: CGSize,
        responsiveMetrics: TokenDailyBoardResponsiveMetrics)
        -> some View
    {
        let debugTuning = TokenDailyBoardConversationOnlyDebugRules.resolvedTuning(
            self.store.conversationOnlyDebugTuning,
            for: self.activeDisplayMode)
        let contentFrame = TokenDailyBoardConversationOnlyLayoutRules.compactContentFrame(
            in: containerSize,
            tuning: debugTuning)
        _ = responsiveMetrics

        return TokenDailyBoardConversationOnlyNarrativeView(
            sentence: sentence,
            fontScaleMultiplier: self.store.narrativeBodyFontScale,
            avatarSlots: self.store.avatarResolvedSlots,
            preferredAvatarSlot: self.activeNarrativeAvatarSlot,
            avatarPhase: self.activeNarrativeAvatarPhase,
            avatarReplacementSequenceID: self.activeNarrativeAvatarReplacementSequenceID,
            avatarIdleShakeSequenceID: self.activeNarrativeAvatarIdleShakeSequenceID,
            animatesTypewriter: self.animatesDisplayedNarrativeTypewriter,
            typewriterStartDelay: self.activeNarrativeTypewriterStartDelay,
            typewriterCompletionToken: self.activeNarrativeTypewriterCompletionToken,
            onTypewriterComplete: {
                self.handleTypewriterCompletion(for: self.activeNarrativeTypewriterCompletionToken)
            },
            displayedMetadataText: self.activeNarrativeDisplayedMetadataText,
            animatesMetadataTypewriter: self.activeNarrativeSession != nil,
            metadataStartDelay: self.activeNarrativeMetadataStartDelay,
            metadataCompletionToken: self.activeNarrativeMetadataCompletionToken,
            contentOpacity: self.activeNarrativeContentOpacity,
            contentVerticalOffset: self.activeNarrativeContentVerticalOffset,
            tuning: debugTuning,
            bodyCharactersPerSecond: self.activeNarrativeBodyCharactersPerSecond,
            metadataCharactersPerSecond: self.activeNarrativeMetadataCharactersPerSecond,
            avatarMotionConfiguration: self.activeNarrativeAvatarMotionConfiguration,
            textColor: self.palette.text,
            mutedTextColor: self.palette.mutedText)
            .frame(
                width: contentFrame.width,
                height: contentFrame.height,
                alignment: .center)
            .position(x: contentFrame.midX, y: contentFrame.midY)
            .offset(x: debugTuning.contentOffset.width, y: debugTuning.contentOffset.height)
    }

    private func resetConversationOnlyAvatarSequence() {
        self.conversationOnlyPreferredAvatarSlot = nil
    }

    private func nextNarrativeAvatarSelection() -> (slot: CodexDailyAvatarResolvedSlot, nextVariantCycleIndex: Int)? {
        TokenDailyBoardConversationOnlyAvatarSequenceRules.nextVariantSelection(
            currentVariantCycleIndex: self.conversationOnlyVariantCycleIndex,
            slots: self.store.avatarResolvedSlots,
            displayMode: self.activeDisplayMode,
            animationEnabled: self.showsNarrativeAvatarReplacementAnimation,
            eventKind: self.activeNarrativeSession?.item.realtimeEventKind)
    }

    private func nextNarrativeAvatarSelection(
        for eventKind: TokenDailyBoardNarrativeEventKind?)
        -> (slot: CodexDailyAvatarResolvedSlot, nextVariantCycleIndex: Int)?
    {
        TokenDailyBoardConversationOnlyAvatarSequenceRules.nextVariantSelection(
            currentVariantCycleIndex: self.conversationOnlyVariantCycleIndex,
            slots: self.store.avatarResolvedSlots,
            displayMode: self.activeDisplayMode,
            animationEnabled: self.showsNarrativeAvatarReplacementAnimation,
            eventKind: eventKind)
    }

    private func renderedAvatarSelection(
        for sourceItem: TokenDailyBoardNarrativePresentationSourceItem?)
        -> CodexDailyAvatarResolvedSlot?
    {
        guard let sourceItem else { return nil }
        guard sourceItem.groupKind == .eventGroup else { return nil }
        let selection = self.nextNarrativeAvatarSelection(for: sourceItem.realtimeEventKind)
        self.conversationOnlyVariantCycleIndex = selection?.nextVariantCycleIndex
        return selection?.slot
    }

    private func makeNarrativePresentationQueueItem(
        sourceItem: TokenDailyBoardNarrativePresentationSourceItem)
        -> TokenDailyBoardNarrativePresentationQueueItem
    {
        let avatarTriggerStyle = TokenDailyBoardConversationOnlyAvatarSequenceRules.style(
            for: sourceItem.realtimeEventKind,
            animationEnabled: self.showsNarrativeAvatarReplacementAnimation)
        let selection = self.nextNarrativeAvatarSelection(for: sourceItem.realtimeEventKind)
        if avatarTriggerStyle == .variantReplacement {
            self.conversationOnlyVariantCycleIndex = selection?.nextVariantCycleIndex
        }
        return TokenDailyBoardNarrativePresentationQueueItem(
            id: self.nextNarrativePresentationItemID,
            sourceItem: sourceItem,
            preferredAvatarSlot: selection?.slot,
            avatarTriggerStyle: avatarTriggerStyle,
            pulseStyle: sourceItem.isAutomaticRealtime && self.showsNarrativeWindowPulse
                ? TokenDailyBoardConversationOnlyWindowPulseRules.style(for: sourceItem.realtimeEventKind)
                : nil)
    }

    private func bootstrapNarrativePresentation(
        signature: String,
        sourceItems: [TokenDailyBoardNarrativePresentationSourceItem])
    {
        self.cancelNarrativeTransientTasks()
        self.restorePersistentIdlePresentationVisualState()
        self.narrativePresentationQueue.removeAll()
        self.activeNarrativeSession = nil
        self.narrativeWindowPulsePhase = .inactive
        self.focusedNarrativeSequenceSignature = signature
        self.knownNarrativeSourceIDs = Set(sourceItems.map(\.sourceID))
        self.renderedNarrativeSourceItem = nil
        self.renderedNarrativePreferredAvatarSlot = nil
        self.idleCountdownAnchor = nil

        let sourceItem = sourceItems.last ?? TokenDailyBoardNarrativeBuilder.idlePresentationSourceItem(
            strings: self.strings,
            catalog: self.narrativeCatalog)
        let item = self.makeNarrativePresentationQueueItem(sourceItem: sourceItem)
        self.nextNarrativePresentationItemID += 1
        self.startNarrativePresentation(item)
    }

    private func enqueueNarrativePresentation(
        sourceItem: TokenDailyBoardNarrativePresentationSourceItem)
    {
        if sourceItem.realtimeEventKind != .idlePulse {
            self.cancelIdlePulseCountdown()
        }
        let item = self.makeNarrativePresentationQueueItem(sourceItem: sourceItem)
        self.nextNarrativePresentationItemID += 1
        let activeSignature = self.activeNarrativeSession?.item.signature
        self.narrativePresentationQueue = TokenDailyBoardNarrativePresentationQueueRules.enqueue(
            item,
            existingQueue: self.narrativePresentationQueue,
            activeSignature: activeSignature)
        if sourceItem.realtimeEventKind != .idlePulse,
           TokenDailyBoardNarrativeIdlePulseRules.shouldDismissPresentedIdleForIncomingNarrative(
               renderedSourceItem: self.renderedNarrativeSourceItem,
               activeSession: self.activeNarrativeSession)
        {
            self.dismissPresentedIdleNarrativeIfNeeded()
        } else {
            self.startNextNarrativePresentationIfNeeded()
        }
    }

    private func startNextNarrativePresentationIfNeeded() {
        guard self.activeNarrativeSession == nil else { return }
        guard !self.narrativePresentationQueue.isEmpty else { return }
        guard !self.showsPersistentIdlePresentation else { return }

        let item = self.narrativePresentationQueue.removeFirst()
        self.startNarrativePresentation(item)
    }

    private func startNarrativePresentation(_ item: TokenDailyBoardNarrativePresentationQueueItem) {
        self.cancelIdlePulseCountdown()
        let startedAt = Date()
        let hasMetadata = self.narrativeSessionHasMetadataText(item.sentence)
        let pulseMotion: TokenDailyBoardNarrativePulseMotionConfiguration?
        let avatarMotionConfiguration: TokenDailyBoardNarrativeAvatarMotionConfiguration
        let bodyCharactersPerSecond: Double
        let metadataCharactersPerSecond: Double
        let avatarIntroStartAt: Date
        let typewriterStartAt: Date
        let metadataStartedAt: Date?
        let metadataCompletedAt: Date
        let avatarReturnStartAt: Date
        let completedAt: Date
        let typewriterCompletedAt: Date

        if self.activeDisplayMode == .conversationOnly {
            let profile = self.conversationOnlyAnimationProfile
            pulseMotion = item.pulseStyle.flatMap { profile.pulseMotion(for: $0) }
            avatarMotionConfiguration = profile.avatarMotionConfiguration
            bodyCharactersPerSecond = profile.bodyCharactersPerSecond
            metadataCharactersPerSecond = profile.metadataCharactersPerSecond
            let pulseEndAt = pulseMotion.map { startedAt.addingTimeInterval($0.duration) } ?? startedAt
            avatarIntroStartAt = pulseEndAt
            typewriterStartAt = avatarIntroStartAt.addingTimeInterval(
                profile.bodyStartDelay(for: item.groupKind))
            let bodyDuration = TokenDailyBoardNarrativeAnimationRules.typewriterDuration(
                for: item.sentence.text,
                charactersPerSecond: bodyCharactersPerSecond)
            typewriterCompletedAt = typewriterStartAt.addingTimeInterval(bodyDuration)
            if hasMetadata, let metadataText = item.sentence.metadataText, !metadataText.isEmpty {
                let startAt = typewriterCompletedAt.addingTimeInterval(
                    profile.metadataStartDelay(for: item.groupKind))
                metadataStartedAt = startAt
                metadataCompletedAt = startAt.addingTimeInterval(
                    TokenDailyBoardNarrativeAnimationRules.typewriterDuration(
                        for: metadataText,
                        charactersPerSecond: metadataCharactersPerSecond))
            } else {
                metadataStartedAt = nil
                metadataCompletedAt = typewriterCompletedAt
            }
            avatarReturnStartAt = max(
                metadataCompletedAt,
                avatarIntroStartAt.addingTimeInterval(
                    TokenDailyBoardNarrativeAvatarReplacementAnimationRules.introDuration))
            completedAt = TokenDailyBoardNarrativePresentationTimelineRules.completionDate(
                typewriterCompletedAt: typewriterCompletedAt,
                startedAt: startedAt,
                includesPulse: pulseMotion != nil,
                includesAvatarReturn: item.avatarTriggerStyle != .none,
                includesIdleShake: false,
                includesMetadata: hasMetadata,
                metadataIntroCompletedAt: metadataCompletedAt,
                avatarReturnStartAt: avatarReturnStartAt,
                includesQueueGap: false)
        } else {
            let includesPulse = item.pulseStyle != nil
            pulseMotion = item.pulseStyle.map {
                TokenDailyBoardNarrativePulseMotionConfiguration(
                    style: $0,
                    duration: TokenDailyBoardConversationOnlyWindowPulseRules.duration,
                    fadeOutDuration: TokenDailyBoardConversationOnlyWindowPulseRules.fadeOutDuration)
            }
            avatarMotionConfiguration = .standard
            bodyCharactersPerSecond = TokenDailyBoardNarrativeLayout.typewriterCharactersPerSecond
            metadataCharactersPerSecond = TokenDailyBoardNarrativeLayout.typewriterCharactersPerSecond
            typewriterStartAt = TokenDailyBoardNarrativePresentationTimelineRules
                .typewriterStartDate(startedAt: startedAt, includesPulse: includesPulse)
            avatarIntroStartAt = TokenDailyBoardNarrativePresentationTimelineRules
                .avatarIntroStartDate(startedAt: startedAt, includesPulse: includesPulse)
            let bodyDuration = TokenDailyBoardNarrativeAnimationRules.typewriterDuration(for: item.sentence.text)
            typewriterCompletedAt = typewriterStartAt.addingTimeInterval(bodyDuration)
            let metadataDuration = TokenDailyBoardNarrativeAnimationRules.typewriterDuration(
                for: item.sentence.metadataText ?? "")
            metadataStartedAt = hasMetadata ? typewriterCompletedAt : nil
            metadataCompletedAt = metadataStartedAt?.addingTimeInterval(metadataDuration) ?? typewriterCompletedAt
            avatarReturnStartAt = TokenDailyBoardNarrativePresentationTimelineRules.avatarReturnStartDate(
                typewriterCompletedAt: typewriterCompletedAt,
                startedAt: startedAt,
                includesPulse: includesPulse,
                includesMetadata: hasMetadata,
                metadataIntroCompletedAt: metadataCompletedAt)
            completedAt = TokenDailyBoardNarrativePresentationTimelineRules.completionDate(
                typewriterCompletedAt: typewriterCompletedAt,
                startedAt: startedAt,
                includesPulse: includesPulse,
                includesAvatarReturn: item.avatarTriggerStyle != .none,
                includesIdleShake: false,
                includesMetadata: hasMetadata,
                metadataIntroCompletedAt: metadataCompletedAt,
                avatarReturnStartAt: avatarReturnStartAt,
                includesQueueGap: false)
        }
        let avatarReplacementSequenceID = item.avatarTriggerStyle == .none
            ? self.conversationOnlyAvatarReplacementSequenceID
            : self.conversationOnlyAvatarReplacementSequenceID + 1

        let session = TokenDailyBoardNarrativePresentationSession(
            item: item,
            startedAt: startedAt,
            typewriterStartAt: typewriterStartAt,
            avatarIntroStartAt: avatarIntroStartAt,
            avatarReplacementSequenceID: avatarReplacementSequenceID,
            pulseMotion: pulseMotion,
            avatarMotionConfiguration: avatarMotionConfiguration,
            bodyCharactersPerSecond: bodyCharactersPerSecond,
            metadataCharactersPerSecond: metadataCharactersPerSecond,
            typewriterCompletedAt: typewriterCompletedAt,
            metadataIntroStartedAt: metadataStartedAt,
            metadataIntroCompletedAt: metadataCompletedAt,
            avatarReturnStartAt: avatarReturnStartAt,
            completedAt: completedAt)
        self.activeNarrativeSession = session

        self.narrativeWindowPulsePhase = pulseMotion.map { .active(item.id, $0) } ?? .inactive

        self.scheduleNarrativePulsePreludeCompletionIfNeeded(sessionID: item.id)
        self.scheduleNarrativeAvatarIntroIfNeeded(sessionID: item.id)
        self.scheduleNarrativeAvatarReturnIfNeeded(sessionID: item.id)
        self.scheduleNarrativeSessionCompletionIfNeeded(sessionID: item.id)
    }

    private func scheduleNarrativePulsePreludeCompletionIfNeeded(sessionID: Int) {
        self.pendingNarrativePulsePreludeTask?.cancel()
        self.pendingNarrativePulsePreludeTask = nil
        guard let session = self.activeNarrativeSession,
              session.item.id == sessionID,
              let pulseMotion = session.pulseMotion
        else { return }

        let pulseEndAt = session.startedAt.addingTimeInterval(pulseMotion.duration)
        let delay = max(pulseEndAt.timeIntervalSinceNow, 0)
        self.pendingNarrativePulsePreludeTask = Task { @MainActor in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            self.pendingNarrativePulsePreludeTask = nil
            self.finishNarrativePulsePreludeIfNeeded(sessionID: sessionID)
        }
    }

    private func finishNarrativePulsePreludeIfNeeded(sessionID: Int) {
        guard var session = self.activeNarrativeSession,
              session.item.id == sessionID
        else { return }

        session.pulseFadeStartAt = Date()
        self.activeNarrativeSession = session
        if case let .active(activeSessionID, _) = self.narrativeWindowPulsePhase,
           activeSessionID == sessionID
        {
            self.narrativeWindowPulsePhase = .inactive
        }
    }

    private func cancelIdlePulseCountdown() {
        self.pendingIdlePulseTask?.cancel()
        self.pendingIdlePulseTask = nil
        self.idleCountdownAnchor = nil
    }

    private func armIdlePulseCountdownIfNeeded() {
        let countdownAnchor = TokenDailyBoardNarrativeIdlePulseRules.countdownAnchor(
            lastNonIdleNarrativeCompletionAt: self.lastNonIdleNarrativeCompletionAt,
            lastPresentedIdleAt: self.lastPresentedIdleAt)
        guard TokenDailyBoardNarrativeIdlePulseRules.shouldArmCountdown(
            hasEligibleRealtimeActivity: self.hasEligibleIdleRealtimeActivity,
            activeSession: self.activeNarrativeSession,
            queuedItems: self.narrativePresentationQueue,
            suppressesNarrativeChanges: self.suppressesNarrativeChanges,
            countdownAnchor: countdownAnchor)
        else {
            self.cancelIdlePulseCountdown()
            return
        }
        guard let countdownAnchor else { return }

        let deadline = TokenDailyBoardNarrativeIdlePulseRules.deadline(from: countdownAnchor)
        self.pendingIdlePulseTask?.cancel()
        self.pendingIdlePulseTask = nil
        self.idleCountdownAnchor = countdownAnchor
        self.pendingIdlePulseTask = Task { @MainActor in
            let delay = max(deadline.timeIntervalSinceNow, 0)
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            self.pendingIdlePulseTask = nil
            self.triggerIdlePulseIfStillEligible(expectedAnchor: countdownAnchor)
        }
    }

    private func triggerIdlePulseIfStillEligible(expectedAnchor: Date) {
        guard TokenDailyBoardNarrativeIdlePulseRules.shouldTrigger(
            now: Date(),
            expectedAnchor: expectedAnchor,
            currentAnchor: self.idleCountdownAnchor,
            hasEligibleRealtimeActivity: self.hasEligibleIdleRealtimeActivity,
            activeSession: self.activeNarrativeSession,
            queuedItems: self.narrativePresentationQueue,
            suppressesNarrativeChanges: self.suppressesNarrativeChanges)
        else { return }

        let sourceItem = TokenDailyBoardNarrativeBuilder.idlePresentationSourceItem(
            strings: self.strings,
            catalog: self.narrativeCatalog)
        let item = self.makeNarrativePresentationQueueItem(sourceItem: sourceItem)
        self.nextNarrativePresentationItemID += 1
        self.idleCountdownAnchor = nil
        if TokenDailyBoardNarrativeIdlePulseRules.shouldRefreshPresentedIdle(
            renderedSourceItem: self.renderedNarrativeSourceItem,
            activeSession: self.activeNarrativeSession,
            queuedItems: self.narrativePresentationQueue,
            suppressesNarrativeChanges: self.suppressesNarrativeChanges)
        {
            self.refreshPresentedIdleNarrative(with: sourceItem, presentedAt: Date())
        } else {
            self.startNarrativePresentation(item)
        }
    }

    private func handleTypewriterCompletion(for token: String) {
        _ = token
    }

    private func narrativeSessionHasMetadata(_ session: TokenDailyBoardNarrativePresentationSession) -> Bool {
        self.narrativeSessionHasMetadataText(session.item.sentence)
    }

    private func narrativeSessionHasMetadataText(_ sentence: TokenDailyBoardNarrativeSentence) -> Bool {
        sentence.metadataText?.isEmpty == false
    }

    private func startNarrativeMetadataIntroIfNeeded(sessionID: Int) {
        _ = sessionID
    }

    private func finishNarrativeMetadataIntroIfNeeded(sessionID: Int) {
        _ = sessionID
    }

    private func scheduleNarrativeAvatarIntroIfNeeded(sessionID: Int) {
        self.pendingNarrativeAvatarIntroTask?.cancel()
        self.pendingNarrativeAvatarIntroTask = nil
        let avatarIntroIsNeeded = if let session = self.activeNarrativeSession, session.item.id == sessionID {
            session.item.avatarTriggerStyle != .none
        } else {
            false
        }
        guard let session = self.activeNarrativeSession,
              session.item.id == sessionID,
              avatarIntroIsNeeded
        else { return }

        let delay = max(session.avatarIntroStartAt.timeIntervalSinceNow, 0)
        self.pendingNarrativeAvatarIntroTask = Task { @MainActor in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            self.pendingNarrativeAvatarIntroTask = nil
            self.activateNarrativeAvatarIntroIfNeeded(sessionID: sessionID)
        }
    }

    private func activateNarrativeAvatarIntroIfNeeded(sessionID: Int) {
        guard var session = self.activeNarrativeSession,
              session.item.id == sessionID,
              !session.hasActivatedAvatarIntro
        else { return }

        session.hasActivatedAvatarIntro = true
        self.activeNarrativeSession = session
        self.conversationOnlyPreferredAvatarSlot = session.item.preferredAvatarSlot
        if self.conversationOnlyAvatarReplacementSequenceID != session.avatarReplacementSequenceID {
            self.conversationOnlyAvatarReplacementSequenceID = session.avatarReplacementSequenceID
        }
    }

    private func scheduleNarrativeAvatarReturnIfNeeded(sessionID: Int) {
        self.pendingNarrativeAvatarReturnTask?.cancel()
        self.pendingNarrativeAvatarReturnTask = nil
        guard let session = self.activeNarrativeSession,
              session.item.id == sessionID,
              !session.hasStartedReturn,
              session.item.avatarTriggerStyle != .none,
              let typewriterCompletedAt = session.typewriterCompletedAt
        else { return }

        let returnStartAt = TokenDailyBoardNarrativePresentationTimelineRules.avatarReturnStartDate(
            typewriterCompletedAt: typewriterCompletedAt,
            startedAt: session.startedAt,
            includesPulse: session.item.pulseStyle != nil,
            includesMetadata: self.narrativeSessionHasMetadata(session),
            metadataIntroCompletedAt: session.metadataIntroCompletedAt)
        let delay = max(returnStartAt.timeIntervalSinceNow, 0)
        self.pendingNarrativeAvatarReturnTask = Task { @MainActor in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            self.pendingNarrativeAvatarReturnTask = nil
            self.startActiveNarrativeAvatarReturnIfNeeded(sessionID: sessionID)
        }
    }

    private func startActiveNarrativeAvatarReturnIfNeeded(sessionID: Int) {
        guard var session = self.activeNarrativeSession,
              session.item.id == sessionID,
              !session.hasStartedReturn
        else { return }

        session.hasStartedReturn = true
        session.avatarReturnStartAt = Date()
        self.activeNarrativeSession = session
        self.scheduleNarrativeSessionCompletionIfNeeded(sessionID: sessionID)
    }

    private func scheduleNarrativeContentOutroIfNeeded(sessionID: Int) {
        _ = sessionID
    }

    private func startNarrativeContentOutroIfNeeded(sessionID: Int) {
        _ = sessionID
    }

    private func finishNarrativeContentOutroIfNeeded(sessionID: Int) {
        _ = sessionID
    }

    private func scheduleNarrativeSessionCompletionIfNeeded(sessionID: Int) {
        guard var session = self.activeNarrativeSession,
              session.item.id == sessionID,
              let typewriterCompletedAt = session.typewriterCompletedAt
        else { return }

        let includesPulse = session.item.pulseStyle != nil
        let includesAvatarReturn = session.item.avatarTriggerStyle != .none
        let includesIdleShake = false
        let includesMetadata = self.narrativeSessionHasMetadata(session)
        let completedAt: Date
        if includesAvatarReturn, session.avatarReturnStartAt == nil {
            return
        }
        completedAt = TokenDailyBoardNarrativePresentationTimelineRules.completionDate(
            typewriterCompletedAt: typewriterCompletedAt,
            startedAt: session.startedAt,
            includesPulse: includesPulse,
            includesAvatarReturn: includesAvatarReturn,
            includesIdleShake: includesIdleShake,
            includesMetadata: includesMetadata,
            metadataIntroCompletedAt: session.metadataIntroCompletedAt,
            avatarReturnStartAt: session.avatarReturnStartAt,
            includesQueueGap: false)
        session.completedAt = completedAt
        self.activeNarrativeSession = session
        self.pendingNarrativeSessionCompletionTask?.cancel()
        self.pendingNarrativeSessionCompletionTask = Task { @MainActor in
            let delay = max(completedAt.timeIntervalSinceNow, 0)
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            self.pendingNarrativeSessionCompletionTask = nil
            self.finishActiveNarrativeSessionIfNeeded(sessionID: sessionID)
        }
    }

    private func finishActiveNarrativeSessionIfNeeded(sessionID: Int) {
        guard let session = self.activeNarrativeSession, session.item.id == sessionID else { return }
        let completionDate = session.completedAt ?? Date()
        self.activeNarrativeSession = nil
        self.narrativeWindowPulsePhase = .inactive
        if session.item.groupKind == .waitingGroup {
            self.lastPresentedIdleAt = completionDate
            self.renderedNarrativePreferredAvatarSlot = nil
        } else {
            self.lastNonIdleNarrativeCompletionAt = completionDate
            self.renderedNarrativePreferredAvatarSlot = session.item.preferredAvatarSlot
        }

        if self.narrativePresentationQueue.isEmpty {
            self.renderedNarrativeSourceItem = session.item.sourceItem
            self.restorePersistentIdlePresentationVisualState()
            self.armIdlePulseCountdownIfNeeded()
        } else {
            self.renderedNarrativeSourceItem = nil
            self.renderedNarrativePreferredAvatarSlot = nil
            self.startNextNarrativePresentationIfNeeded()
        }
    }

    private func restorePersistentIdlePresentationVisualState() {
        self.idlePersistentContentOpacity = 1
        self.idlePersistentContentVerticalOffset = 0
    }

    private func refreshPresentedIdleNarrative(
        with sourceItem: TokenDailyBoardNarrativePresentationSourceItem,
        presentedAt: Date)
    {
        self.renderedNarrativeSourceItem = sourceItem
        self.renderedNarrativePreferredAvatarSlot = nil
        self.restorePersistentIdlePresentationVisualState()
        self.lastPresentedIdleAt = presentedAt
        self.armIdlePulseCountdownIfNeeded()
    }

    private func dismissPresentedIdleNarrativeIfNeeded() {
        guard TokenDailyBoardNarrativeIdlePulseRules.shouldDismissPresentedIdleForIncomingNarrative(
            renderedSourceItem: self.renderedNarrativeSourceItem,
            activeSession: self.activeNarrativeSession)
        else {
            self.startNextNarrativePresentationIfNeeded()
            return
        }
        guard self.pendingIdleDismissalTask == nil else { return }

        withAnimation(TokenDailyBoardNarrativeIdleHandoffRules.dismissAnimation) {
            self.idlePersistentContentOpacity = 0
            self.idlePersistentContentVerticalOffset = TokenDailyBoardNarrativeIdleHandoffRules.dismissVerticalOffset
        }

        self.pendingIdleDismissalTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: TokenDailyBoardNarrativeIdleHandoffRules.dismissDurationNanoseconds)
            guard !Task.isCancelled else { return }
            self.pendingIdleDismissalTask = nil
            self.renderedNarrativeSourceItem = nil
            self.renderedNarrativePreferredAvatarSlot = nil
            self.restorePersistentIdlePresentationVisualState()
            self.startNextNarrativePresentationIfNeeded()
        }
    }

    private func syncNarrativeSourceItemsImmediately(
        signature: String,
        sourceItems: [TokenDailyBoardNarrativePresentationSourceItem])
    {
        let resolvedSourceItem = sourceItems.last ?? TokenDailyBoardNarrativeBuilder.idlePresentationSourceItem(
            strings: self.strings,
            catalog: self.narrativeCatalog)
        self.cancelNarrativeTransientTasks()
        self.restorePersistentIdlePresentationVisualState()
        self.narrativePresentationQueue.removeAll()
        self.activeNarrativeSession = nil
        self.narrativeWindowPulsePhase = .inactive
        self.knownNarrativeSourceIDs = Set(sourceItems.map(\.sourceID))
        self.renderedNarrativeSourceItem = resolvedSourceItem
        self.renderedNarrativePreferredAvatarSlot = self.renderedAvatarSelection(for: resolvedSourceItem)
        self.focusedNarrativeSequenceSignature = signature
        self.idleCountdownAnchor = nil
        self.lastPresentedIdleAt = resolvedSourceItem.groupKind == .waitingGroup ? Date() : nil
        if resolvedSourceItem.groupKind == .eventGroup {
            self.lastNonIdleNarrativeCompletionAt = Date()
        } else if sourceItems.isEmpty {
            self.lastNonIdleNarrativeCompletionAt = nil
        }
        if resolvedSourceItem.groupKind == .waitingGroup {
            self.resetConversationOnlyAvatarSequence()
            self.conversationOnlyAvatarIdleShakeSequenceID = 0
        }
        self.armIdlePulseCountdownIfNeeded()
    }

    private func selectMonth(_ month: Int) {
        guard self.model.availableMonthsWithData.contains(month) else { return }
        self.selectedMonth = month
    }

    private func selectPreviousYear() {
        guard let previousAvailableYear else { return }
        self.selectedYear = previousAvailableYear
    }

    private func selectNextYear() {
        guard let nextAvailableYear else { return }
        self.selectedYear = nextAvailableYear
    }

    private func resolveHostWindow(_ window: NSWindow?) {
        guard self.hostWindow !== window else { return }
        self.hostWindow = window
    }

    private func applyDisplayModeToWindow(
        displayMode: TokenDailyBoardDisplayMode? = nil,
        animated: Bool)
    {
        guard let hostWindow else { return }
        TokenDailyBoardWindowLayout.applyDisplayMode(
            displayMode ?? self.activeDisplayMode,
            to: hostWindow,
            animated: animated,
            tuning: self.store.conversationOnlyDebugTuning)
    }

    private func cancelNarrativeTransientTasks() {
        self.pendingNarrativePulsePreludeTask?.cancel()
        self.pendingNarrativePulsePreludeTask = nil
        self.pendingNarrativeAvatarIntroTask?.cancel()
        self.pendingNarrativeAvatarIntroTask = nil
        self.pendingNarrativeMetadataIntroTask?.cancel()
        self.pendingNarrativeMetadataIntroTask = nil
        self.pendingNarrativeAvatarReturnTask?.cancel()
        self.pendingNarrativeAvatarReturnTask = nil
        self.pendingNarrativeContentOutroTask?.cancel()
        self.pendingNarrativeContentOutroTask = nil
        self.pendingNarrativeSessionCompletionTask?.cancel()
        self.pendingNarrativeSessionCompletionTask = nil
        self.pendingIdlePulseTask?.cancel()
        self.pendingIdlePulseTask = nil
        self.pendingIdleDismissalTask?.cancel()
        self.pendingIdleDismissalTask = nil
        self.restorePersistentIdlePresentationVisualState()
    }

    private func resetNarrativeTransientState() {
        self.cancelNarrativeTransientTasks()
        self.conversationOnlyVariantCycleIndex = nil
        self.conversationOnlyPreferredAvatarSlot = nil
        self.conversationOnlyAvatarReplacementSequenceID = 0
        self.conversationOnlyAvatarIdleShakeSequenceID = 0
        self.knownNarrativeSourceIDs.removeAll()
        self.renderedNarrativeSourceItem = nil
        self.renderedNarrativePreferredAvatarSlot = nil
        self.narrativePresentationQueue.removeAll()
        self.activeNarrativeSession = nil
        self.narrativeWindowPulsePhase = .inactive
        self.idleCountdownAnchor = nil
        self.lastNonIdleNarrativeCompletionAt = nil
        self.lastPresentedIdleAt = nil
        self.restorePersistentIdlePresentationVisualState()
    }

    private func synchronizeNarrativeSignaturesToCurrentState() {
        self.focusedNarrativeRealtimeSignature = self.realtimeNarrativeSignature
        self.focusedNarrativeSequenceSignature = self.focusedNarrativeSignature
    }

    private func restoreDisplayModeTransitionState() {
        self.displayModeContentOpacity = 1
        self.isSwitchingDisplayMode = false
        self.suppressesNarrativeAutoAnimations = false
        self.store.setBoardDisplayModeTransitioning(false)
    }

    private func performDisplayModeTransition(to displayMode: TokenDailyBoardDisplayMode) {
        self.pendingDisplayModeTransitionTask?.cancel()
        self.pendingDisplayModeTransitionTask = nil
        self.restoreDisplayModeTransitionState()

        self.pendingDisplayModeTransitionTask = Task { @MainActor in
            self.isSwitchingDisplayMode = true
            self.suppressesNarrativeAutoAnimations = true
            self.store.setBoardDisplayModeTransitioning(true)
            self.resetNarrativeTransientState()
            self.synchronizeNarrativeSignaturesToCurrentState()
            self.syncNarrativeSourceItemsImmediately(
                signature: self.focusedNarrativeSignature,
                sourceItems: self.focusedNarrativeSourceItems)

            withAnimation(.easeOut(duration: TokenDailyBoardDisplayModeTransitionRules.fadeOutDuration)) {
                self.displayModeContentOpacity = 0
            }

            try? await Task.sleep(
                nanoseconds: UInt64(
                    TokenDailyBoardDisplayModeTransitionRules.fadeOutDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }

            self.renderedDisplayMode = displayMode
            self.applyDisplayModeToWindow(
                displayMode: displayMode,
                animated: TokenDailyBoardDisplayModeTransitionRules.usesAnimatedWindowFrame)

            withAnimation(.easeOut(duration: TokenDailyBoardDisplayModeTransitionRules.fadeInDuration)) {
                self.displayModeContentOpacity = 1
            }

            try? await Task.sleep(
                nanoseconds: UInt64(
                    TokenDailyBoardDisplayModeTransitionRules.fadeInDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }

            self.isSwitchingDisplayMode = false
            self.suppressesNarrativeAutoAnimations = false
            self.store.setBoardDisplayModeTransitioning(false)
            self.pendingDisplayModeTransitionTask = nil
        }
    }

    private func normalizeSelectedYearIfNeeded() {
        guard !self.model.availableYears.isEmpty else { return }
        if !self.model.availableYears.contains(self.selectedYear),
           let latestYear = self.model.availableYears.max()
        {
            self.selectedYear = latestYear
        }
    }

    private func mainBoardContent(
        responsiveMetrics: TokenDailyBoardResponsiveMetrics)
        -> some View
    {
        Group {
            if let emptyState {
                VStack(alignment: .leading, spacing: 0) {
                    TokenDailyBoardEmptyStateView(
                        title: emptyState.title,
                        message: emptyState.message)

                    Spacer(minLength: 0)
                }
            } else {
                switch self.activeDisplayMode {
                case .conversationOnly:
                    self.conversationOnlyContent
                case .conversationAndToday:
                    self.conversationAndTodayContent
                case .fullBoard:
                    self.fullBoardContent(responsiveMetrics: responsiveMetrics)
                }
            }
        }
    }

    private var conversationOnlyContent: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var conversationAndTodayContent: some View {
        self.conversationModeContent(showsHeroDay: true)
    }

    private func conversationModeContent(showsHeroDay: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: TokenDailyBoardLayout.conversationModeContentTopInset)

            if let monthEmptyState {
                TokenDailyBoardEmptyStateView(
                    title: monthEmptyState.title,
                    message: monthEmptyState.message)
            } else if showsHeroDay, let heroDay {
                TokenDailyBoardHeroDayCardView(
                    today: heroDay,
                    scaleTopValue: self.model.scaleTopValue,
                    strings: self.strings,
                    usesRelativeTitles: self.usesRelativeTitles)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.bottom, TokenDailyBoardLayout.conversationModeBottomInset)
    }

    private func fullBoardContent(
        responsiveMetrics: TokenDailyBoardResponsiveMetrics)
        -> some View
    {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: TokenDailyBoardLayout.sectionSpacing) {
                if let monthEmptyState {
                    TokenDailyBoardEmptyStateView(
                        title: monthEmptyState.title,
                        message: monthEmptyState.message)
                } else {
                    if self.showsHeroDay, let heroDay {
                        TokenDailyBoardHeroDayCardView(
                            today: heroDay,
                            scaleTopValue: self.model.scaleTopValue,
                            strings: self.strings,
                            usesRelativeTitles: self.usesRelativeTitles)
                    }

                    if self.showsSecondaryDays, !self.secondaryDays.isEmpty {
                        LazyVStack(
                            alignment: .leading,
                            spacing: TokenDailyBoardLayout.secondarySpacing)
                        {
                            TokenDailyBoardSectionDivider()

                            ForEach(Array(self.secondaryDays.enumerated()), id: \.element.id) {
                                index, day in
                                if index > 0 {
                                    TokenDailyBoardSectionDivider()
                                }

                                TokenDailyBoardSecondaryDayCardView(
                                    day: day,
                                    scaleTopValue: self.model.scaleTopValue,
                                    strings: self.strings,
                                    usesRelativeTitles: self.usesRelativeTitles)
                            }
                        }
                    }

                    if self.showsCompactDays, !self.compactDays.isEmpty {
                        LazyVStack(
                            alignment: .leading,
                            spacing: TokenDailyBoardLayout.compactRowSpacing)
                        {
                            TokenDailyBoardSectionDivider()

                            ForEach(Array(self.compactDays.enumerated()), id: \.element.id) {
                                index, day in
                                if index > 0 {
                                    TokenDailyBoardSectionDivider()
                                }

                                TokenDailyBoardCompactDayRowView(
                                    day: day,
                                    scaleTopValue: self.model.scaleTopValue,
                                    strings: self.strings,
                                    usesRelativeTitles: self.usesRelativeTitles)
                            }
                        }
                    }
                }
            }
            .padding(.top, self.narrativeTopContentInset(for: responsiveMetrics))
            .padding(.bottom, TokenDailyBoardScrollPresentationRules.bottomContentInset)
        }
    }

    public var body: some View {
        GeometryReader { geo in
            let responsiveMetrics = TokenDailyBoardResponsiveMetrics(containerWidth: geo.size.width)

            ZStack {
                TokenDailyBoardWindowBackground(
                    usesGlass: self.usesWindowGlassBackground,
                    appearance: self.conversationOnlyWindowAppearance)
                    .ignoresSafeArea()

                if self.showsNarrativeWindowPulse {
                    TokenDailyBoardConversationOnlyWindowPulseOverlay(phase: self.narrativeWindowPulsePhase)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .id("pulse-\(self.activeDisplayMode.rawValue)")
                }

                TokenDailyBoardBoardPanelContainer(
                    topInset: self.boardTopInset)
                {
                    ZStack(alignment: .topLeading) {
                        VStack(
                            alignment: .leading,
                            spacing: TokenDailyBoardLayout.contentSpacing)
                        {
                            if self.showsContentChrome {
                                TokenDailyBoardChromeBarView(
                                    strings: self.strings,
                                    statusText: self.chromeStatusText,
                                    chromeMetrics: self.chromeMetrics)
                            }

                            self.mainBoardContent(responsiveMetrics: responsiveMetrics)
                        }
                        .id("main-\(self.activeDisplayMode.rawValue)")

                        if self.showsNarrativeOverlay,
                           self.store.cacheState == .ready,
                           let displayedNarrativeSentence
                        {
                            Group {
                                if self.activeDisplayMode == .conversationOnly {
                                    self.conversationOnlyNarrativeOverlay(
                                        sentence: displayedNarrativeSentence,
                                        containerSize: geo.size,
                                        responsiveMetrics: responsiveMetrics)
                                } else {
                                    let overlayID = "overlay-\(self.activeDisplayMode.rawValue)"
                                    TokenDailyBoardNarrativeRailView(
                                        sentence: displayedNarrativeSentence,
                                        fontScaleMultiplier: self.store.narrativeBodyFontScale,
                                        displayMode: self.activeDisplayMode,
                                        avatarSlots: self.store.avatarResolvedSlots,
                                        preferredAvatarSlot: self.activeNarrativeAvatarSlot,
                                        avatarPhase: self.activeNarrativeAvatarPhase,
                                        avatarReplacementSequenceID: self.activeNarrativeAvatarReplacementSequenceID,
                                        avatarIdleShakeSequenceID: self.activeNarrativeAvatarIdleShakeSequenceID,
                                        animatesAvatarReplacement: self.showsNarrativeAvatarReplacementAnimation,
                                        animatesTypewriter: self.animatesDisplayedNarrativeTypewriter,
                                        typewriterStartDelay: self.activeNarrativeTypewriterStartDelay,
                                        typewriterCompletionToken: self.activeNarrativeTypewriterCompletionToken,
                                        onTypewriterComplete: {
                                            self.handleTypewriterCompletion(
                                                for: self.activeNarrativeTypewriterCompletionToken)
                                        },
                                        displayedMetadataText: self.activeNarrativeDisplayedMetadataText,
                                        animatesMetadataTypewriter: self.activeNarrativeSession != nil,
                                        metadataStartDelay: self.activeNarrativeMetadataStartDelay,
                                        metadataCompletionToken: self.activeNarrativeMetadataCompletionToken,
                                        contentOpacity: self.activeNarrativeContentOpacity,
                                        contentVerticalOffset: self.activeNarrativeContentVerticalOffset,
                                        bodyCharactersPerSecond: self.activeNarrativeBodyCharactersPerSecond,
                                        metadataCharactersPerSecond: self.activeNarrativeMetadataCharactersPerSecond,
                                        chromeButtonsVisible: self.showsModeChromeButtons,
                                        onCustomize: {
                                            self.showsNarrativeEditor = true
                                        },
                                        strings: self.strings,
                                        textColor: self.palette.text,
                                        mutedTextColor: self.palette.mutedText)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                        .padding(.top, TokenDailyBoardLayout.narrativeOverlayTopInset)
                                        .id(overlayID)
                                }
                            }
                        }

                        if self.showsMonthPager {
                            VStack {
                                Spacer(minLength: 0)

                                TokenDailyBoardMonthPagerView(
                                    selectedYear: self.selectedYear,
                                    selectedMonth: self.selectedMonth,
                                    availableMonthsWithData: self.model.availableMonthsWithData,
                                    previousYear: self.previousAvailableYear,
                                    nextYear: self.nextAvailableYear,
                                    buttonDiameter: self.monthButtonDiameter,
                                    onSelectMonth: self.selectMonth,
                                    onSelectPreviousYear: self.selectPreviousYear,
                                    onSelectNextYear: self.selectNextYear)
                                    .padding(.bottom, 8)
                            }
                        }
                    }
                    .opacity(self.displayModeContentOpacity)
                }
                .padding(.horizontal, TokenDailyBoardLayout.windowHorizontalPadding)
                .padding(.top, self.topContentPadding)
                .padding(.bottom, TokenDailyBoardLayout.windowVerticalPadding)
            }
            .environment(\.tokenDailyBoardResponsiveMetrics, responsiveMetrics)
            .background(
                TokenDailyBoardWindowAccessor { window in
                    self.resolveHostWindow(window)
                })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.locale, self.strings.locale)
        .sheet(isPresented: self.$showsNarrativeEditor) {
            TokenDailyBoardNarrativeEditorSheet(
                bundledEntries: self.narrativeCatalog.entries,
                entries: self.store.narrativeUserEntries,
                avatarSlots: self.store.avatarResolvedSlots,
                strings: self.strings,
                narrativeBodyFontScale: Binding(
                    get: { Double(self.store.narrativeBodyFontScale) },
                    set: { self.store.setNarrativeBodyFontScale(CGFloat($0)) }),
                saveEntry: { entry in
                    self.store.upsertNarrativeUserEntry(entry)
                },
                deleteEntry: { entry in
                    self.store.deleteNarrativeUserEntry(id: entry.id)
                },
                replaceAvatarImage: { slot, url in
                    self.store.replaceAvatarImage(for: slot, sourceURL: url)
                },
                restoreAvatarSlot: { slot in
                    self.store.restoreAvatarSlot(slot)
                },
                setAvatarMirrored: { slot, isMirrored in
                    self.store.setAvatarMirrored(isMirrored, for: slot)
                },
                currentErrorMessage: self.store.narrativeUserCatalogErrorMessage,
                avatarErrorMessage: self.store.avatarCustomizationErrorMessage)
        }
        .onAppear {
            self.normalizeSelectedYearIfNeeded()
            self.renderedDisplayMode = self.store.boardDisplayMode
            self.synchronizeNarrativeSignaturesToCurrentState()
            if self.hasBootstrappedNarrativePresentation {
                self.syncNarrativeSourceItemsImmediately(
                    signature: self.focusedNarrativeSignature,
                    sourceItems: self.focusedNarrativeSourceItems)
            } else {
                self.bootstrapNarrativePresentation(
                    signature: self.focusedNarrativeSignature,
                    sourceItems: self.focusedNarrativeSourceItems)
                self.hasBootstrappedNarrativePresentation = true
            }
            self.applyDisplayModeToWindow(animated: false)
        }
        .onChange(of: self.hostWindow) { _, _ in
            self.applyDisplayModeToWindow(animated: false)
        }
        .onChange(of: self.store.boardDisplayMode) { _, newValue in
            self.performDisplayModeTransition(to: newValue)
        }
        .onChange(of: self.store.conversationOnlyDebugTuning) { _, _ in
            guard self.activeDisplayMode == .conversationOnly else { return }
            self.applyDisplayModeToWindow(animated: false)
        }
        .onChange(of: self.store.conversationOnlyDebugTuning.enablesAvatarReplacementAnimation) { _, isEnabled in
            if !isEnabled {
                self.pendingNarrativeAvatarIntroTask?.cancel()
                self.pendingNarrativeAvatarIntroTask = nil
                self.pendingNarrativeAvatarReturnTask?.cancel()
                self.pendingNarrativeAvatarReturnTask = nil
                self.resetConversationOnlyAvatarSequence()
                self.conversationOnlyAvatarIdleShakeSequenceID = 0
            }
        }
        .onChange(of: self.model.availableYears) { _, _ in
            self.normalizeSelectedYearIfNeeded()
        }
        .onChange(of: self.realtimeNarrativeSignature) { _, newValue in
            if self.suppressesNarrativeChanges {
                self.focusedNarrativeRealtimeSignature = newValue
                return
            }

            self.focusedNarrativeRealtimeSignature = newValue
        }
        .onChange(of: self.focusedNarrativeSignature) { _, newValue in
            guard newValue != self.focusedNarrativeSequenceSignature else { return }
            let sourceItems = self.focusedNarrativeSourceItems
            if self.suppressesNarrativeChanges {
                self.syncNarrativeSourceItemsImmediately(
                    signature: newValue,
                    sourceItems: sourceItems)
                return
            }
            self.focusedNarrativeSequenceSignature = newValue
            guard !newValue.isEmpty, !sourceItems.isEmpty else {
                self.syncNarrativeSourceItemsImmediately(
                    signature: newValue,
                    sourceItems: sourceItems)
                return
            }
            let newSourceItems = TokenDailyBoardNarrativePresentationQueueRules.newSourceItems(
                from: sourceItems,
                knownSourceIDs: self.knownNarrativeSourceIDs)
            self.knownNarrativeSourceIDs.formUnion(newSourceItems.map(\.sourceID))

            if newSourceItems.isEmpty {
                if self.activeNarrativeSession == nil,
                   self.narrativePresentationQueue.isEmpty,
                   !self.showsPersistentIdlePresentation
                {
                    let resolvedSourceItem = sourceItems.last
                        ?? TokenDailyBoardNarrativeBuilder.idlePresentationSourceItem(
                            strings: self.strings,
                            catalog: self.narrativeCatalog)
                    self.renderedNarrativeSourceItem = resolvedSourceItem
                    self.renderedNarrativePreferredAvatarSlot =
                        self.renderedAvatarSelection(for: resolvedSourceItem)
                    if resolvedSourceItem.groupKind == .waitingGroup {
                        self.lastPresentedIdleAt = Date()
                    }
                    self.armIdlePulseCountdownIfNeeded()
                }
            } else {
                for sourceItem in newSourceItems {
                    self.enqueueNarrativePresentation(sourceItem: sourceItem)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .codexDailyNarrativeCustomize)) { _ in
            guard self.activeDisplayMode == .conversationOnly else { return }
            self.showsNarrativeEditor = true
        }
        .onDisappear {
            self.pendingDisplayModeTransitionTask?.cancel()
            self.pendingDisplayModeTransitionTask = nil
            self.cancelNarrativeTransientTasks()
            self.store.setBoardDisplayModeTransitioning(false)
        }
    }
}
