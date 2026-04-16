import AppKit
import XCTest
@testable import CodexDailyKit

@MainActor
final class TokenDailyBoardWindowCoordinatorTests: XCTestCase {
    func test_defaultSizeUsesVisibleFrameWidthRatioAndHeightClamp() {
        XCTAssertEqual(
            TokenDailyBoardWindowLayout.minimumWidth(for: CGRect(x: 0, y: 0, width: 1512, height: 982)),
            TokenDailyBoardWindowLayout.fixedLayoutMinimumWidth,
            accuracy: 0.001)

        let size = TokenDailyBoardWindowLayout.defaultSize(
            for: CGRect(x: 0, y: 0, width: 1512, height: 982))

        XCTAssertEqual(size.width, 1331, accuracy: 0.001)
        XCTAssertEqual(size.height, TokenDailyBoardWindowLayout.defaultHeight, accuracy: 0.001)
    }

    func test_displayModeTargetHeightsUseFixedTiers() {
        let visibleFrame = CGRect(x: 0, y: 0, width: 1512, height: 982)
        let compactSize = TokenDailyBoardConversationOnlyLayoutRules.defaultCompactWindowSize

        XCTAssertEqual(
            TokenDailyBoardWindowLayout.targetHeight(for: .conversationOnly, visibleFrame: visibleFrame),
            compactSize.height,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardWindowLayout.targetHeight(for: .conversationAndToday, visibleFrame: visibleFrame),
            TokenDailyBoardWindowLayout.conversationAndTodayHeight,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardWindowLayout.targetHeight(for: .fullBoard, visibleFrame: visibleFrame),
            TokenDailyBoardWindowLayout.defaultHeight,
            accuracy: 0.001)
        XCTAssertLessThan(
            TokenDailyBoardWindowLayout.targetHeight(for: .conversationOnly, visibleFrame: visibleFrame),
            TokenDailyBoardWindowLayout.targetHeight(for: .conversationAndToday, visibleFrame: visibleFrame))
        XCTAssertLessThan(
            TokenDailyBoardWindowLayout.targetHeight(for: .conversationAndToday, visibleFrame: visibleFrame),
            TokenDailyBoardWindowLayout.targetHeight(for: .fullBoard, visibleFrame: visibleFrame))
        XCTAssertEqual(
            TokenDailyBoardWindowLayout.defaultSize(
                for: visibleFrame,
                displayMode: .conversationOnly).width,
            compactSize.width,
            accuracy: 0.001)

        var tuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        tuning.windowWidth = 820
        XCTAssertEqual(
            TokenDailyBoardWindowLayout.defaultSize(
                for: visibleFrame,
                displayMode: .conversationOnly,
                tuning: tuning).width,
            820,
            accuracy: 0.001)
    }

    func test_centeredFrameStaysInsideVisibleFrame() {
        let centered = TokenDailyBoardWindowLayout.centeredFrame(
            for: CGRect(x: 0, y: 0, width: 1331, height: 764),
            in: CGRect(x: 1440, y: 25, width: 1512, height: 982))

        XCTAssertEqual(centered.origin.x, 1531)
        XCTAssertEqual(centered.origin.y, 134)
        XCTAssertGreaterThanOrEqual(centered.minX, 1440)
        XCTAssertGreaterThanOrEqual(centered.minY, 25)
        XCTAssertLessThanOrEqual(centered.maxX, 2952)
        XCTAssertLessThanOrEqual(centered.maxY, 1007)
    }

    func test_restoredFrameUsesSavedOriginWhenAlreadyVisible() {
        let restored = TokenDailyBoardWindowLayout.restoredFrame(
            for: CGRect(x: 0, y: 0, width: 600, height: 400),
            savedOrigin: CGPoint(x: 180, y: 140),
            in: CGRect(x: 0, y: 25, width: 1440, height: 875))

        XCTAssertEqual(restored.origin.x, 180, accuracy: 0.001)
        XCTAssertEqual(restored.origin.y, 140, accuracy: 0.001)
        XCTAssertEqual(restored.size.width, 600, accuracy: 0.001)
        XCTAssertEqual(restored.size.height, 400, accuracy: 0.001)
    }

    func test_restoredFrameClampsSavedOriginIntoVisibleFrame() {
        let restored = TokenDailyBoardWindowLayout.restoredFrame(
            for: CGRect(x: 0, y: 0, width: 900, height: 700),
            savedOrigin: CGPoint(x: 1800, y: -120),
            in: CGRect(x: 100, y: 40, width: 1200, height: 820))

        XCTAssertEqual(restored.origin.x, 400, accuracy: 0.001)
        XCTAssertEqual(restored.origin.y, 40, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(restored.minX, 100)
        XCTAssertGreaterThanOrEqual(restored.minY, 40)
        XCTAssertLessThanOrEqual(restored.maxX, 1300)
        XCTAssertLessThanOrEqual(restored.maxY, 860)
    }

    func test_configureWindowEnablesFullSizeContentAndStylesSystemButtons() {
        let window = self.makeWindow(
            title: "Original",
            styleMask: [.titled],
            frame: NSRect(x: 0, y: 0, width: 600, height: 400))

        TokenDailyBoardWindowLayout.configureWindow(
            window,
            title: "Daily Board",
            initialSize: CGSize(width: 1331, height: 764),
            displayMode: .fullBoard)

        XCTAssertEqual(window.title, "Daily Board")
        XCTAssertTrue(window.styleMask.contains(.fullSizeContentView))
        XCTAssertEqual(window.titleVisibility, .hidden)
        XCTAssertTrue(window.titlebarAppearsTransparent)
        XCTAssertFalse(window.collectionBehavior.contains(.fullScreenPrimary))
        let expectedMinimumWidth = TokenDailyBoardWindowLayout.minimumWidth(
            for: TokenDailyBoardWindowLayout.resolvedVisibleFrame(for: window))
        XCTAssertEqual(window.minSize.width, expectedMinimumWidth, accuracy: 0.001)
        XCTAssertEqual(window.minSize.height, TokenDailyBoardWindowLayout.minimumHeight, accuracy: 0.001)
        XCTAssertFalse(window.isOpaque)
        XCTAssertEqual(window.backgroundColor, .clear)

        let closeButton = try XCTUnwrap(window.standardWindowButton(.closeButton))
        let miniButton = try XCTUnwrap(window.standardWindowButton(.miniaturizeButton))
        let zoomButton = try XCTUnwrap(window.standardWindowButton(.zoomButton))
        XCTAssertEqual(closeButton.alphaValue, TokenDailyBoardWindowChromeStyleRules.trafficLightAlpha, accuracy: 0.001)
        XCTAssertEqual(miniButton.alphaValue, TokenDailyBoardWindowChromeStyleRules.trafficLightAlpha, accuracy: 0.001)
        XCTAssertTrue(zoomButton.isHidden)
        XCTAssertFalse(zoomButton.isEnabled)
    }

    func test_updateMinimumSizeUsesDisplayModeHeight() {
        let window = self.makeWindow(
            title: "Daily Board",
            styleMask: [.titled],
            frame: NSRect(x: 0, y: 0, width: 900, height: 700))

        TokenDailyBoardWindowLayout.updateMinimumSize(for: window, displayMode: .conversationOnly)
        let visibleFrame = TokenDailyBoardWindowLayout.resolvedVisibleFrame(for: window)

        XCTAssertEqual(
            window.minSize.height,
            TokenDailyBoardWindowLayout.minimumHeight(for: .conversationOnly, visibleFrame: visibleFrame),
            accuracy: 0.001)
    }

    func test_chromeMetricsUseVisibleTrafficLightClusterWidth() throws {
        let window = self.makeWindow(
            title: "Daily Board",
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            frame: NSRect(x: 0, y: 0, width: 900, height: 700))
        TokenDailyBoardWindowLayout.configureWindow(
            window,
            title: "Daily Board",
            initialSize: CGSize(width: 900, height: 700),
            displayMode: .fullBoard)

        let metrics = TokenDailyBoardWindowLayout.chromeMetrics(for: window)
        let miniButton = try XCTUnwrap(window.standardWindowButton(.miniaturizeButton))

        XCTAssertEqual(metrics.titleLeadingInset, miniButton.frame.maxX + 16, accuracy: 0.001)
        XCTAssertEqual(metrics.buttonDiameter, 14, accuracy: 0.001)
    }

    func test_hourRulerBoundariesMatchChartBoundariesWithSharedInset() {
        let contentWidth: CGFloat = 1280
        let markerHour = 18
        let chartHorizontalInset = TokenDailyBoardAlignmentRules.chartHorizontalInset

        let rulerX = TokenDailyBoardChartGeometry.boundaryX(
            for: markerHour,
            containerWidth: contentWidth,
            horizontalInset: chartHorizontalInset)
        let chartX = TokenDailyBoardChartGeometry.boundaryX(
            for: markerHour,
            containerWidth: contentWidth,
            horizontalInset: chartHorizontalInset)

        XCTAssertEqual(rulerX, chartX, accuracy: 0.001)
    }

    func test_chartRailsFillTheRightContentColumn() {
        let contentWidth: CGFloat = 1280
        let inset = TokenDailyBoardAlignmentRules.chartHorizontalInset

        XCTAssertEqual(
            TokenDailyBoardChartGeometry.boundaryX(
                for: 0,
                containerWidth: contentWidth,
                horizontalInset: inset),
            inset,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardChartGeometry.boundaryX(
                for: 24,
                containerWidth: contentWidth,
                horizontalInset: inset),
            contentWidth,
            accuracy: 0.001)
    }

    func test_contentChromeIsHiddenWhenCacheIsReady() {
        XCTAssertFalse(TokenDailyBoardPresentationRules.showsContentChrome(for: .ready))
        XCTAssertTrue(TokenDailyBoardPresentationRules.showsContentChrome(for: .missing))
        XCTAssertTrue(TokenDailyBoardPresentationRules.showsContentChrome(for: .failed(message: "boom")))
    }

    func test_surfacePresentationDoesNotRenderCustomGlassSurfaces() {
        XCTAssertTrue(TokenDailyBoardSurfacePresentationRules.usesGlass(for: .conversationPanel))
        XCTAssertFalse(TokenDailyBoardSurfacePresentationRules.usesGlass(for: .panel))
        XCTAssertFalse(TokenDailyBoardSurfacePresentationRules.usesGlass(for: .hero))
        XCTAssertFalse(TokenDailyBoardSurfacePresentationRules.usesGlass(for: .secondary))
        XCTAssertFalse(TokenDailyBoardSurfacePresentationRules.usesGlass(for: .compact))
    }

    func test_conversationOnlyUsesIndependentCompactHeightTier() {
        let compactSize = TokenDailyBoardConversationOnlyLayoutRules.defaultCompactWindowSize

        XCTAssertLessThan(
            TokenDailyBoardWindowLayout.conversationOnlyHeight,
            TokenDailyBoardWindowLayout.conversationAndTodayHeight)
        XCTAssertEqual(TokenDailyBoardWindowLayout.conversationOnlyHeight, compactSize.height, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardWindowLayout.conversationOnlyWidth, compactSize.width, accuracy: 0.001)
        XCTAssertNotEqual(TokenDailyBoardWindowLayout.conversationOnlyHeight, 142, accuracy: 0.001)
        XCTAssertNotEqual(TokenDailyBoardWindowLayout.conversationOnlyWidth, 441, accuracy: 0.001)
    }

    func test_conversationOnlyCompactsAvatarAndTextSpacing() {
        XCTAssertEqual(TokenDailyBoardNarrativeLayout.conversationOnlyAvatarSize, 56, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardNarrativeLayout.conversationOnlyAvatarToContentSpacing, 12, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardNarrativeLayout.conversationOnlyMetadataTopSpacing, 6, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardNarrativeLayout.conversationOnlyMetadataFontSize, 12, accuracy: 0.001)
    }

    func test_conversationOnlyAvailableTextWidthUsesContentRectWidth() {
        let availableWidth = TokenDailyBoardConversationOnlyLayoutRules.availableTextWidth

        XCTAssertEqual(availableWidth, 515, accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyLayoutRules.contentWidth,
            583,
            accuracy: 0.001)
    }

    func test_conversationOnlyUsesCompactContentFrameForOverlay() {
        let tuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        let frame = TokenDailyBoardConversationOnlyLayoutRules.compactContentFrame(
            in: TokenDailyBoardConversationOnlyLayoutRules.compactWindowSize(for: tuning),
            tuning: tuning)
        let naturalContentSize = TokenDailyBoardConversationOnlyLayoutRules.naturalContentSize(for: tuning)

        XCTAssertEqual(frame.origin.x, 4, accuracy: 0.001)
        XCTAssertEqual(frame.origin.y, 4, accuracy: 0.001)
        XCTAssertEqual(frame.width, naturalContentSize.width, accuracy: 0.001)
        XCTAssertEqual(frame.height, naturalContentSize.height, accuracy: 0.001)
    }

    func test_conversationModesTwoAndThreeShowTodayModule() {
        XCTAssertFalse(TokenDailyBoardDisplayContentRules.showsTodayModule(for: .conversationOnly))
        XCTAssertTrue(TokenDailyBoardDisplayContentRules.showsTodayModule(for: .conversationAndToday))
        XCTAssertTrue(TokenDailyBoardDisplayContentRules.showsTodayModule(for: .fullBoard))
    }

    func test_conversationOnlyLocksWindowToFixedSizeAndDisablesResize() {
        let window = self.makeWindow(
            title: "Daily Board",
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            frame: NSRect(x: 50, y: 50, width: 1331, height: 764))
        let compactSize = TokenDailyBoardConversationOnlyLayoutRules.defaultCompactWindowSize

        TokenDailyBoardWindowLayout.applyDisplayMode(.conversationOnly, to: window, animated: false)

        XCTAssertFalse(window.styleMask.contains(.resizable))
        XCTAssertEqual(window.frame.width, compactSize.width, accuracy: 0.001)
        XCTAssertEqual(window.frame.height, compactSize.height, accuracy: 0.001)
        XCTAssertEqual(window.minSize.width, compactSize.width, accuracy: 0.001)
        XCTAssertEqual(window.minSize.height, compactSize.height, accuracy: 0.001)
        XCTAssertEqual(window.maxSize.width, compactSize.width, accuracy: 0.001)
        XCTAssertEqual(window.maxSize.height, compactSize.height, accuracy: 0.001)
    }

    func test_conversationOnlyWidthTuningReCentersWindow() {
        let window = self.makeWindow(
            title: "Daily Board",
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            frame: NSRect(x: 50, y: 50, width: 1331, height: 764))
        let visibleFrame = TokenDailyBoardWindowLayout.resolvedVisibleFrame(for: window)
        var tuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        tuning.windowWidth = 812
        let expectedHeight = TokenDailyBoardConversationOnlyLayoutRules.compactWindowSize(for: tuning).height

        TokenDailyBoardWindowLayout.applyDisplayMode(
            .conversationOnly,
            to: window,
            animated: false,
            tuning: tuning)

        let expectedFrame = TokenDailyBoardWindowLayout.centeredFrame(
            for: CGRect(
                origin: .zero,
                size: CGSize(width: 812, height: expectedHeight)),
            in: visibleFrame)

        XCTAssertEqual(window.frame.width, 812, accuracy: 0.001)
        XCTAssertEqual(window.frame.height, expectedHeight, accuracy: 0.001)
        XCTAssertEqual(window.frame.origin.x, expectedFrame.origin.x, accuracy: 0.001)
        XCTAssertEqual(window.frame.origin.y, expectedFrame.origin.y, accuracy: 0.001)
        XCTAssertEqual(window.minSize.width, 812, accuracy: 0.001)
        XCTAssertEqual(window.maxSize.width, 812, accuracy: 0.001)
    }

    func test_nonConversationModesRemainResizable() {
        let window = self.makeWindow(
            title: "Daily Board",
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            frame: NSRect(x: 50, y: 50, width: 672, height: 148))

        TokenDailyBoardWindowLayout.applyDisplayMode(.conversationAndToday, to: window, animated: false)

        XCTAssertTrue(window.styleMask.contains(.resizable))
        XCTAssertGreaterThan(window.maxSize.width, window.minSize.width)
    }

    func test_switchingAwayFromConversationOnlyDoesNotReuseTunedWidth() {
        let window = self.makeWindow(
            title: "Daily Board",
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            frame: NSRect(x: 50, y: 50, width: 1331, height: 764))
        let visibleFrame = TokenDailyBoardWindowLayout.resolvedVisibleFrame(for: window)
        var tuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        tuning.windowWidth = 812

        TokenDailyBoardWindowLayout.applyDisplayMode(
            .conversationOnly,
            to: window,
            animated: false,
            tuning: tuning)
        TokenDailyBoardWindowLayout.applyDisplayMode(
            .conversationAndToday,
            to: window,
            animated: false,
            tuning: tuning)

        let expectedWidth = TokenDailyBoardWindowLayout.defaultSize(
            for: visibleFrame,
            displayMode: .conversationAndToday,
            tuning: tuning).width

        XCTAssertEqual(window.frame.width, expectedWidth, accuracy: 0.001)
        XCTAssertNotEqual(window.frame.width, 812, accuracy: 0.001)
    }

    func test_windowChromeVisibilityRulesAlwaysKeepWindowChromeVisible() {
        XCTAssertTrue(TokenDailyBoardChromeVisibilityRules.shouldShowWindowChrome(
            displayMode: .conversationOnly,
            isKeyWindow: true,
            isMouseInsideWindow: true))
        XCTAssertTrue(TokenDailyBoardChromeVisibilityRules.shouldShowWindowChrome(
            displayMode: .conversationOnly,
            isKeyWindow: true,
            isMouseInsideWindow: false))
        XCTAssertTrue(TokenDailyBoardChromeVisibilityRules.shouldShowWindowChrome(
            displayMode: .conversationOnly,
            isKeyWindow: false,
            isMouseInsideWindow: true))
        XCTAssertTrue(TokenDailyBoardChromeVisibilityRules.shouldShowWindowChrome(
            displayMode: .conversationAndToday,
            isKeyWindow: false,
            isMouseInsideWindow: false))
        XCTAssertTrue(TokenDailyBoardChromeVisibilityRules.shouldShowWindowChrome(
            displayMode: .fullBoard,
            isKeyWindow: false,
            isMouseInsideWindow: false))
        XCTAssertTrue(TokenDailyBoardChromeVisibilityRules.isVisible(
            for: .conversationOnly,
            storedVisibility: false))
    }

    func test_mainContentDoesNotRenderCustomPanelBackground() {
        XCTAssertFalse(TokenDailyBoardPresentationRules.rendersCustomPanelBackground)
    }

    func test_rootBackgroundUsesSingleFullBleedGlassLayer() {
        XCTAssertTrue(TokenDailyBoardBackgroundPresentationRules.usesFullBleedGlassBackground)
        XCTAssertFalse(TokenDailyBoardBackgroundPresentationRules.usesCustomPanelSurface)
    }

    func test_allDisplayModesUseWindowGlassBackground() {
        XCTAssertTrue(TokenDailyBoardBackgroundPresentationRules.usesWindowGlassBackground(for: .conversationOnly))
        XCTAssertTrue(TokenDailyBoardBackgroundPresentationRules.usesWindowGlassBackground(for: .conversationAndToday))
        XCTAssertTrue(TokenDailyBoardBackgroundPresentationRules.usesWindowGlassBackground(for: .fullBoard))
    }

    func test_titlebarChromeRulesClampTrailingInsetAndButtonOpacity() {
        XCTAssertEqual(TokenDailyBoardWindowChromeStyleRules.trailingInset(for: 500), 12, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardWindowChromeStyleRules.trailingInset(for: 800), 16, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardWindowChromeStyleRules.trailingInset(for: 1600), 24, accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardWindowChromeStyleRules.modeButtonOpacity(isSelected: true),
            0.46,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardWindowChromeStyleRules.modeButtonOpacity(isSelected: false),
            0.18,
            accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardWindowChromeStyleRules.actionButtonOpacity, 0.14, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardWindowChromeStyleRules.toggleButtonOpacity, 0.22, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardWindowChromeStyleRules.hoverFillOpacity, 0.10, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardWindowChromeStyleRules.pressedFillOpacity, 0.16, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardWindowChromeStyleRules.hoverStrokeOpacity, 0.14, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardWindowChromeStyleRules.pressedScale, 0.985, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardWindowChromeStyleRules.trafficLightAlpha, 0.40, accuracy: 0.001)
    }

    func test_titlebarAccessoryLayoutRulesReserveExpandedWidthPerMode() {
        let modeOneMetrics = TokenDailyBoardTitlebarAccessoryLayoutRules.metrics(
            for: .conversationOnly,
            isReady: true,
            buttonDiameter: 34,
            trailingInset: 16)
        let modeTwoMetrics = TokenDailyBoardTitlebarAccessoryLayoutRules.metrics(
            for: .conversationAndToday,
            isReady: true,
            buttonDiameter: 34,
            trailingInset: 16)
        let loadingMetrics = TokenDailyBoardTitlebarAccessoryLayoutRules.metrics(
            for: .conversationOnly,
            isReady: false,
            buttonDiameter: 34,
            trailingInset: 16)

        XCTAssertEqual(modeOneMetrics.toggleSlotWidth, 34, accuracy: 0.001)
        XCTAssertEqual(modeOneMetrics.clusterButtonCount, 6)
        XCTAssertEqual(modeTwoMetrics.clusterButtonCount, 3)
        XCTAssertEqual(modeOneMetrics.clusterTrackWidth, 234, accuracy: 0.001)
        XCTAssertEqual(modeTwoMetrics.clusterTrackWidth, 234, accuracy: 0.001)
        XCTAssertEqual(modeOneMetrics.clusterWidth, 234, accuracy: 0.001)
        XCTAssertEqual(modeTwoMetrics.clusterWidth, 114, accuracy: 0.001)
        XCTAssertEqual(modeOneMetrics.clusterTrailingSpacing, 10, accuracy: 0.001)
        XCTAssertEqual(modeTwoMetrics.clusterTrailingSpacing, 10, accuracy: 0.001)
        XCTAssertEqual(modeOneMetrics.toggleAnchorX, 244, accuracy: 0.001)
        XCTAssertEqual(modeTwoMetrics.toggleAnchorX, 244, accuracy: 0.001)
        XCTAssertEqual(modeOneMetrics.clusterRevealCollapsedWidth, 0, accuracy: 0.001)
        XCTAssertEqual(modeTwoMetrics.clusterRevealCollapsedWidth, 0, accuracy: 0.001)
        XCTAssertEqual(modeOneMetrics.clusterRevealExpandedWidth, 234, accuracy: 0.001)
        XCTAssertEqual(modeTwoMetrics.clusterRevealExpandedWidth, 114, accuracy: 0.001)
        XCTAssertEqual(modeOneMetrics.contentWidth, 278, accuracy: 0.001)
        XCTAssertEqual(modeTwoMetrics.contentWidth, 278, accuracy: 0.001)
        XCTAssertEqual(modeOneMetrics.accessoryWidth, 294, accuracy: 0.001)
        XCTAssertEqual(modeTwoMetrics.accessoryWidth, 294, accuracy: 0.001)

        XCTAssertEqual(loadingMetrics.clusterButtonCount, 0)
        XCTAssertEqual(loadingMetrics.clusterTrackWidth, 0, accuracy: 0.001)
        XCTAssertEqual(loadingMetrics.contentWidth, 1, accuracy: 0.001)
        XCTAssertEqual(loadingMetrics.accessoryWidth, 17, accuracy: 0.001)
        XCTAssertEqual(loadingMetrics.toggleAnchorX, 0, accuracy: 0.001)
        XCTAssertEqual(loadingMetrics.clusterRevealExpandedWidth, 0, accuracy: 0.001)
    }

    func test_windowPinRulesOnlyFloatModeOneWhenPinned() {
        XCTAssertEqual(
            TokenDailyBoardWindowPinRules.level(
                for: .conversationOnly,
                isConversationOnlyPinned: true),
            .floating)
        XCTAssertEqual(
            TokenDailyBoardWindowPinRules.level(
                for: .conversationOnly,
                isConversationOnlyPinned: false),
            .normal)
        XCTAssertEqual(
            TokenDailyBoardWindowPinRules.level(
                for: .conversationAndToday,
                isConversationOnlyPinned: true),
            .normal)
        XCTAssertEqual(
            TokenDailyBoardWindowPinRules.level(
                for: .fullBoard,
                isConversationOnlyPinned: true),
            .normal)
    }

    func test_debugPanelPresentationRulesOnlyAllowModeOneWhileExpanded() {
        XCTAssertTrue(
            TokenDailyBoardDebugPanelPresentationRules.shouldRemainAvailable(
                displayMode: .conversationOnly,
                titlebarControlsCollapsed: false))
        XCTAssertFalse(
            TokenDailyBoardDebugPanelPresentationRules.shouldRemainAvailable(
                displayMode: .conversationOnly,
                titlebarControlsCollapsed: true))
        XCTAssertFalse(
            TokenDailyBoardDebugPanelPresentationRules.shouldRemainAvailable(
                displayMode: .conversationAndToday,
                titlebarControlsCollapsed: false))
        XCTAssertFalse(
            TokenDailyBoardDebugPanelPresentationRules.shouldRemainAvailable(
                displayMode: .fullBoard,
                titlebarControlsCollapsed: false))
    }

    func test_debugPanelPlacementRulesPlacePanelToTheRightAndClampToVisibleFrame() {
        let visibleFrame = CGRect(x: 100, y: 40, width: 1000, height: 700)
        let mainWindowFrame = CGRect(x: 760, y: 260, width: 320, height: 220)
        let frame = TokenDailyBoardDebugPanelPlacementRules.initialFrame(
            nearMainWindow: mainWindowFrame,
            panelSize: CGSize(width: 320, height: 520),
            visibleFrame: visibleFrame)

        XCTAssertEqual(frame.origin.x, 780, accuracy: 0.001)
        XCTAssertEqual(frame.origin.y, 40, accuracy: 0.001)
        XCTAssertEqual(frame.width, 320, accuracy: 0.001)
        XCTAssertEqual(frame.height, 520, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(frame.minX, visibleFrame.minX)
        XCTAssertGreaterThanOrEqual(frame.minY, visibleFrame.minY)
        XCTAssertLessThanOrEqual(frame.maxX, visibleFrame.maxX)
        XCTAssertLessThanOrEqual(frame.maxY, visibleFrame.maxY)
    }

    func test_debugPanelPlacementRulesRestoreSavedOriginWithinVisibleFrame() {
        let visibleFrame = CGRect(x: 0, y: 25, width: 1280, height: 800)
        let restored = TokenDailyBoardDebugPanelPlacementRules.restoredFrame(
            savedOrigin: CGPoint(x: 1400, y: -80),
            panelSize: CGSize(width: 320, height: 520),
            visibleFrame: visibleFrame)

        XCTAssertEqual(restored.origin.x, 960, accuracy: 0.001)
        XCTAssertEqual(restored.origin.y, 25, accuracy: 0.001)
        XCTAssertLessThanOrEqual(restored.maxX, visibleFrame.maxX)
        XCTAssertLessThanOrEqual(restored.maxY, visibleFrame.maxY)
    }

    func test_titlebarAutoHideRulesOnlyHideModeOneWhenPointerLeavesWindow() {
        XCTAssertTrue(
            TokenDailyBoardTitlebarAutoHideRules.shouldUseDelayedAutoHide(displayMode: .conversationOnly))
        XCTAssertFalse(
            TokenDailyBoardTitlebarAutoHideRules.shouldUseDelayedAutoHide(displayMode: .conversationAndToday))
        XCTAssertFalse(
            TokenDailyBoardTitlebarAutoHideRules.shouldUseDelayedAutoHide(displayMode: .fullBoard))

        XCTAssertTrue(
            TokenDailyBoardTitlebarAutoHideRules.shouldShowAccessory(
                displayMode: .conversationOnly,
                isWindowHovered: true,
                windowChromeVisible: true))
        XCTAssertFalse(
            TokenDailyBoardTitlebarAutoHideRules.shouldShowAccessory(
                displayMode: .conversationOnly,
                isWindowHovered: false,
                windowChromeVisible: false))
        XCTAssertTrue(
            TokenDailyBoardTitlebarAutoHideRules.shouldShowAccessory(
                displayMode: .conversationOnly,
                isWindowHovered: false,
                windowChromeVisible: true))
        XCTAssertTrue(
            TokenDailyBoardTitlebarAutoHideRules.shouldShowAccessory(
                displayMode: .conversationAndToday,
                isWindowHovered: false,
                windowChromeVisible: false))
        XCTAssertTrue(
            TokenDailyBoardTitlebarAutoHideRules.shouldShowAccessory(
                displayMode: .fullBoard,
                isWindowHovered: false,
                windowChromeVisible: false))
    }

    func test_titlebarAutoHideRulesKeepManualCollapsePriorityWhenPointerReturns() {
        XCTAssertFalse(
            TokenDailyBoardTitlebarAutoHideRules.effectiveExpandedClusterHitTesting(
                displayMode: .conversationOnly,
                isWindowHovered: true,
                windowChromeVisible: true,
                titlebarControlsCollapsed: true))
        XCTAssertFalse(
            TokenDailyBoardTitlebarAutoHideRules.effectiveExpandedClusterHitTesting(
                displayMode: .conversationOnly,
                isWindowHovered: false,
                windowChromeVisible: false,
                titlebarControlsCollapsed: false))
        XCTAssertTrue(
            TokenDailyBoardTitlebarAutoHideRules.effectiveExpandedClusterHitTesting(
                displayMode: .conversationOnly,
                isWindowHovered: true,
                windowChromeVisible: true,
                titlebarControlsCollapsed: false))
        XCTAssertTrue(
            TokenDailyBoardTitlebarAutoHideRules.effectiveExpandedClusterHitTesting(
                displayMode: .conversationAndToday,
                isWindowHovered: false,
                windowChromeVisible: false,
                titlebarControlsCollapsed: false))
        XCTAssertEqual(
            TokenDailyBoardTitlebarAutoHideRules.trafficLightAlpha(
                displayMode: .conversationOnly,
                windowChromeVisible: false),
            0,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardTitlebarAutoHideRules.trafficLightAlpha(
                displayMode: .conversationOnly,
                windowChromeVisible: true),
            TokenDailyBoardWindowChromeStyleRules.trafficLightAlpha,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardTitlebarAutoHideRules.trafficLightAlpha(
                displayMode: .conversationAndToday,
                windowChromeVisible: false),
            TokenDailyBoardWindowChromeStyleRules.trafficLightAlpha,
            accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardTitlebarAutoHideRules.delayedAutoHideDelay, .seconds(3))
    }

    func test_displayModeTransitionRulesDisableAnimatedWindowFramesAndGateNarrativeUpdates() {
        XCTAssertFalse(TokenDailyBoardDisplayModeTransitionRules.usesAnimatedWindowFrame)
        XCTAssertFalse(
            TokenDailyBoardDisplayModeTransitionRules.shouldSuppressNarrativeAutoAnimations(
                isSwitchingDisplayMode: false,
                suppressesNarrativeAutoAnimations: false))
        XCTAssertTrue(
            TokenDailyBoardDisplayModeTransitionRules.shouldSuppressNarrativeAutoAnimations(
                isSwitchingDisplayMode: true,
                suppressesNarrativeAutoAnimations: false))
        XCTAssertTrue(
            TokenDailyBoardDisplayModeTransitionRules.shouldSuppressNarrativeAutoAnimations(
                isSwitchingDisplayMode: false,
                suppressesNarrativeAutoAnimations: true))
        XCTAssertEqual(TokenDailyBoardDisplayModeTransitionRules.fadeOutDuration, 0.08, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardDisplayModeTransitionRules.fadeInDuration, 0.14, accuracy: 0.001)
    }

    func test_conversationOnlyWindowAppearanceOnlyAppliesInModeOne() {
        var tuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        tuning.windowWidth = 812
        tuning.windowGlassOpacity = 0.55
        tuning.windowGlassBlur = 12

        let modeOneAppearance = TokenDailyBoardConversationOnlyDebugRules.resolvedWindowAppearance(
            tuning,
            for: .conversationOnly)
        let modeTwoAppearance = TokenDailyBoardConversationOnlyDebugRules.resolvedWindowAppearance(
            tuning,
            for: .conversationAndToday)

        XCTAssertEqual(modeOneAppearance.resolvedWindowWidth, 812, accuracy: 0.001)
        XCTAssertEqual(modeOneAppearance.resolvedGlassOpacity, 0.55, accuracy: 0.001)
        XCTAssertEqual(modeOneAppearance.resolvedGlassBlur, 12, accuracy: 0.001)
        XCTAssertEqual(modeOneAppearance.blurOverlayOpacity, 0.275, accuracy: 0.001)
        XCTAssertEqual(
            modeTwoAppearance.resolvedWindowWidth,
            TokenDailyBoardWindowLayout.conversationOnlyWidth,
            accuracy: 0.001)
        XCTAssertEqual(modeTwoAppearance.resolvedGlassOpacity, 1, accuracy: 0.001)
        XCTAssertEqual(modeTwoAppearance.resolvedGlassBlur, 0, accuracy: 0.001)
        XCTAssertEqual(modeTwoAppearance.blurOverlayOpacity, 0, accuracy: 0.001)
    }

    func test_narrativeWindowPulseAppliesAcrossAllModes() {
        var tuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        tuning.enablesPreNarrativeWindowPulse = true

        XCTAssertTrue(TokenDailyBoardConversationOnlyWindowPulseRules.isEnabled(tuning, for: .conversationOnly))
        XCTAssertTrue(TokenDailyBoardConversationOnlyWindowPulseRules.isEnabled(tuning, for: .conversationAndToday))
        XCTAssertTrue(TokenDailyBoardConversationOnlyWindowPulseRules.isEnabled(tuning, for: .fullBoard))
        XCTAssertEqual(TokenDailyBoardConversationOnlyWindowPulseRules.duration, 1.0, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardConversationOnlyWindowPulseRules.fadeOutDuration, 0.36, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardConversationOnlyAvatarSequenceRules.minimumDuration, 3.0, accuracy: 0.001)
        XCTAssertEqual(CodexDailyDockIconAnimationRules.targetIconSize, 256, accuracy: 0.001)
        XCTAssertLessThan(
            TokenDailyBoardConversationOnlyWindowPulseRules.fillPeakOpacity(for: .standardRealtime),
            0.18)
        XCTAssertLessThan(
            TokenDailyBoardConversationOnlyWindowPulseRules.sweepPeakOpacity(for: .standardRealtime),
            0.82)
    }

    func test_narrativeWindowPulseStillUsesSessionPhaseState() {
        let configuration = TokenDailyBoardNarrativePulseMotionConfiguration(
            style: .standardRealtime,
            duration: 0.6,
            fadeOutDuration: 0.24)
        let activePhase = TokenDailyBoardNarrativeWindowPulsePhase.active(21, configuration)
        let fadePhase = TokenDailyBoardNarrativeWindowPulsePhase.fadingOut(21, configuration)

        XCTAssertEqual(activePhase, .active(21, configuration))
        XCTAssertEqual(fadePhase, .fadingOut(21, configuration))
        XCTAssertNotEqual(activePhase, fadePhase)
        XCTAssertNotEqual(activePhase, .inactive)
        XCTAssertEqual(activePhase.motionConfiguration.duration, 0.6, accuracy: 0.001)
        XCTAssertEqual(fadePhase.motionConfiguration.fadeOutDuration, 0.24, accuracy: 0.001)
    }

    func test_idlePulseUsesSeparatePulseStyleAndAvatarBehavior() {
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyWindowPulseRules.style(for: .idlePulse),
            .idlePulse)
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyWindowPulseRules.sweepAxis(for: .idlePulse),
            .vertical)
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyWindowPulseRules.paletteName(for: .idlePulse),
            "plumRose")
        XCTAssertNotEqual(
            TokenDailyBoardConversationOnlyWindowPulseRules.fillPeakOpacity(for: .idlePulse),
            TokenDailyBoardConversationOnlyWindowPulseRules.fillPeakOpacity(for: .standardRealtime))
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyAvatarSequenceRules.style(
                for: .idlePulse,
                animationEnabled: true),
            .defaultGroupIntro)
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyAvatarSequenceRules.style(
                for: .throughputPulse,
                animationEnabled: true),
            .variantReplacement)
    }

    func test_narrativePresentationTimelineWaitsForFadeReturnAndQueueGap() {
        let startedAt = Date(timeIntervalSinceReferenceDate: 500)
        let typewriterDone = startedAt.addingTimeInterval(1.6)
        let metadataIntroCompletedAt = typewriterDone
            .addingTimeInterval(TokenDailyBoardNarrativeMetadataAnimationRules.transitionDuration)
        let completionDate = TokenDailyBoardNarrativePresentationTimelineRules.completionDate(
            typewriterCompletedAt: typewriterDone,
            startedAt: startedAt,
            includesPulse: true,
            includesAvatarReturn: true,
            includesIdleShake: false,
            includesMetadata: true,
            metadataIntroCompletedAt: metadataIntroCompletedAt)
        let returnEnd = TokenDailyBoardNarrativePresentationTimelineRules.avatarReturnEndDate(
            typewriterCompletedAt: typewriterDone,
            startedAt: startedAt,
            includesPulse: true,
            includesMetadata: true,
            metadataIntroCompletedAt: metadataIntroCompletedAt)
        let contentOutroEnd = TokenDailyBoardNarrativePresentationTimelineRules.contentOutroEndDate(
            typewriterCompletedAt: typewriterDone,
            startedAt: startedAt,
            includesPulse: true,
            includesMetadata: true,
            metadataIntroCompletedAt: metadataIntroCompletedAt,
            includesAvatarReturn: true,
            includesIdleShake: false)

        XCTAssertEqual(
            completionDate.timeIntervalSince(startedAt),
            max(returnEnd, contentOutroEnd)
                .addingTimeInterval(TokenDailyBoardNarrativePresentationTimelineRules.queueGapDuration)
                .timeIntervalSince(startedAt),
            accuracy: 0.001)
    }

    func test_scrollPresentationUsesSingleTopInsetWithoutMask() {
        XCTAssertEqual(
            TokenDailyBoardScrollPresentationRules.topContentInset,
            TokenDailyBoardNarrativeLayout.avatarSize * 1.1,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardScrollPresentationRules.topContentInset(layoutScaleMultiplier: 0.84),
            TokenDailyBoardScrollPresentationRules.topContentInset,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardScrollPresentationRules.topContentInset(layoutScaleMultiplier: 1.0),
            TokenDailyBoardScrollPresentationRules.topContentInset,
            accuracy: 0.001)
        XCTAssertGreaterThan(TokenDailyBoardScrollPresentationRules.bottomContentInset, 0)
        XCTAssertFalse(TokenDailyBoardScrollPresentationRules.usesScrollMask)
    }

    func test_narrativeRailUsesFixedTwoLinePresentationRules() {
        let baselineMetrics = TokenDailyBoardNarrativeSizingRules.metrics(fontScaleMultiplier: 1.0)
        XCTAssertEqual(TokenDailyBoardNarrativeLayout.maxLines, 2)
        XCTAssertEqual(TokenDailyBoardNarrativeSizingRules.fontSizes, baselineMetrics.fontSizes)
        XCTAssertEqual(
            TokenDailyBoardNarrativeSizingRules.minimumFontSize,
            baselineMetrics.minimumFontSize,
            accuracy: 0.001)
        XCTAssertGreaterThan(TokenDailyBoardNarrativeSizingRules.railHeight, 0)
        XCTAssertEqual(TokenDailyBoardNarrativeLayout.avatarCornerRadius, 18, accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardNarrativeLayout.avatarSize,
            ceil(TokenDailyBoardNarrativeLayout.bubbleBodyHeight),
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardNarrativeSizingRules.bubbleHeight,
            TokenDailyBoardNarrativeLayout.avatarSize,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardNarrativeSizingRules.railHeight,
            TokenDailyBoardNarrativeSizingRules.bubbleHeight
                + TokenDailyBoardNarrativeLayout.controlsTopSpacing
                + TokenDailyBoardNarrativeSizingRules.controlsRowHeight,
            accuracy: 0.001)
        XCTAssertGreaterThan(
            TokenDailyBoardNarrativeSizingRules.conversationOnlyShellHeight(fontScaleMultiplier: 1.0),
            TokenDailyBoardNarrativeSizingRules.railHeight)
        XCTAssertFalse(TokenDailyBoardNarrativePresentationRules.showsNamePrefix)
        XCTAssertTrue(TokenDailyBoardNarrativePresentationRules.avatarUsesRoundedSquare)
        XCTAssertTrue(TokenDailyBoardNarrativePresentationRules.avatarIsMirrored)
        XCTAssertFalse(TokenDailyBoardNarrativePresentationRules.showsBubbleTail)
        XCTAssertTrue(TokenDailyBoardNarrativePresentationRules.controlsRowIsOutsideBubble)
        XCTAssertFalse(TokenDailyBoardNarrativePresentationRules.usesPreviousAndNextButtons)
        XCTAssertTrue(TokenDailyBoardNarrativePresentationRules.usesFixedOverlay)
        XCTAssertFalse(TokenDailyBoardNarrativePresentationRules.followsScrollPosition)
        XCTAssertTrue(TokenDailyBoardNarrativePresentationRules.contentScrollsUnderOverlay)
        XCTAssertEqual(TokenDailyBoardNarrativeLayout.customizeButtonSymbol, "slider.horizontal.3")
        XCTAssertGreaterThan(TokenDailyBoardNarrativeLayout.defaultAvatarContentScale, 1)
        XCTAssertEqual(
            TokenDailyBoardNarrativeSizingRules.controlsButtonClusterWidth,
            TokenDailyBoardNarrativeSizingRules.buttonReservedWidth,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardNarrativeSizingRules.conversationOnlyBubbleWidthSnapStep,
            8,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyDebugRules.buttonSymbol,
            "arrow.up.and.down.and.arrow.left.and.right")
        XCTAssertGreaterThan(
            TokenDailyBoardNarrativeSizingRules.conversationOnlyTrailingSafetyInset,
            TokenDailyBoardNarrativeLayout.conversationOnlyAvatarAnimationPushDistance)
        XCTAssertEqual(
            TokenDailyBoardNarrativeLayout.avatarSize,
            TokenDailyBoardNarrativeSizingRules.bubbleHeight,
            accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardNarrativeAnimationRules.bodyWeight, .light)
        XCTAssertEqual(TokenDailyBoardNarrativeAnimationRules.avatarPeakScale, 1, accuracy: 0.001)
        XCTAssertTrue(TokenDailyBoardNarrativeAnimationRules.triggersOnlyForAutomaticRealtimeSwitches)
    }

    func test_conversationOnlyPositionDebugRulesOnlyApplyToModeOne() {
        var tuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        tuning.contentOffset = CGSize(width: 12, height: -8)
        tuning.windowWidth = 812
        tuning.textColumnWidth = 440

        XCTAssertTrue(
            TokenDailyBoardConversationOnlyDebugRules.shouldShowPositionDebugger(for: .conversationOnly))
        XCTAssertFalse(
            TokenDailyBoardConversationOnlyDebugRules.shouldShowPositionDebugger(for: .conversationAndToday))
        XCTAssertFalse(
            TokenDailyBoardConversationOnlyDebugRules.shouldShowPositionDebugger(for: .fullBoard))
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyDebugRules.resolvedTuning(tuning, for: .conversationOnly),
            TokenDailyBoardConversationOnlyDebugRules.clamp(tuning))
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyDebugRules.resolvedTuning(tuning, for: .conversationAndToday),
            TokenDailyBoardConversationOnlyDebugRules.defaultTuning)
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyDebugRules.resolvedTuning(tuning, for: .fullBoard),
            TokenDailyBoardConversationOnlyDebugRules.defaultTuning)
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyDebugRules.resolvedWindowWidth(812, visibleFrameWidth: 700),
            700,
            accuracy: 0.001)
    }

    func test_narrativeFontScaleDoesNotChangeOverlayGeometry() {
        let baselineMetrics = TokenDailyBoardNarrativeSizingRules.metrics(fontScaleMultiplier: 1.0)
        let enlargedMetrics = TokenDailyBoardNarrativeSizingRules.metrics(fontScaleMultiplier: 1.3)
        let reducedMetrics = TokenDailyBoardNarrativeSizingRules.metrics(fontScaleMultiplier: 0.7)

        XCTAssertGreaterThan(enlargedMetrics.fontSizes[0], baselineMetrics.fontSizes[0])
        XCTAssertLessThan(reducedMetrics.fontSizes[0], baselineMetrics.fontSizes[0])
        XCTAssertEqual(enlargedMetrics.avatarSize, baselineMetrics.avatarSize, accuracy: 0.001)
        XCTAssertEqual(enlargedMetrics.bubbleHeight, baselineMetrics.bubbleHeight, accuracy: 0.001)
        XCTAssertEqual(enlargedMetrics.railHeight, baselineMetrics.railHeight, accuracy: 0.001)
        XCTAssertEqual(reducedMetrics.avatarSize, baselineMetrics.avatarSize, accuracy: 0.001)
        XCTAssertEqual(reducedMetrics.bubbleHeight, baselineMetrics.bubbleHeight, accuracy: 0.001)
        XCTAssertEqual(reducedMetrics.railHeight, baselineMetrics.railHeight, accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardScrollPresentationRules.topContentInset(layoutScaleMultiplier: 0.84),
            TokenDailyBoardScrollPresentationRules.topContentInset,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardScrollPresentationRules.topContentInset(layoutScaleMultiplier: 1.0),
            TokenDailyBoardScrollPresentationRules.topContentInset,
            accuracy: 0.001)
    }

    func test_responsiveMetricsUseFixedWideMediumCompactTiers() {
        let wide = TokenDailyBoardResponsiveMetrics(containerWidth: 1200)
        let medium = TokenDailyBoardResponsiveMetrics(containerWidth: 960)
        let compact = TokenDailyBoardResponsiveMetrics(containerWidth: 640)

        XCTAssertEqual(wide.tier, .wide)
        XCTAssertEqual(medium.tier, .medium)
        XCTAssertEqual(compact.tier, .compact)
        XCTAssertEqual(wide.fontScale, 1, accuracy: 0.001)
        XCTAssertEqual(medium.fontScale, 1, accuracy: 0.001)
        XCTAssertEqual(compact.fontScale, 1, accuracy: 0.001)
        XCTAssertEqual(wide.monthPagerFontScale, 1, accuracy: 0.001)
        XCTAssertEqual(medium.monthPagerFontScale, 1, accuracy: 0.001)
        XCTAssertEqual(compact.monthPagerFontScale, 1, accuracy: 0.001)
        XCTAssertEqual(wide.contentInset, medium.contentInset, accuracy: 0.001)
        XCTAssertEqual(medium.contentInset, compact.contentInset, accuracy: 0.001)
        XCTAssertEqual(wide.dateColumnWidth, medium.dateColumnWidth, accuracy: 0.001)
        XCTAssertEqual(medium.dateColumnWidth, compact.dateColumnWidth, accuracy: 0.001)
        XCTAssertEqual(wide.dataColumnWidth, medium.dataColumnWidth, accuracy: 0.001)
        XCTAssertEqual(medium.dataColumnWidth, compact.dataColumnWidth, accuracy: 0.001)
        XCTAssertEqual(wide.heroChartHeight, TokenDailyBoardLayout.heroChartHeight, accuracy: 0.001)
        XCTAssertEqual(medium.heroChartHeight, TokenDailyBoardLayout.heroChartHeight, accuracy: 0.001)
        XCTAssertEqual(compact.heroChartHeight, TokenDailyBoardLayout.heroChartHeight, accuracy: 0.001)
        XCTAssertEqual(wide.secondaryChartHeight, TokenDailyBoardLayout.secondaryChartHeight, accuracy: 0.001)
        XCTAssertEqual(medium.secondaryChartHeight, TokenDailyBoardLayout.secondaryChartHeight, accuracy: 0.001)
        XCTAssertEqual(compact.secondaryChartHeight, TokenDailyBoardLayout.secondaryChartHeight, accuracy: 0.001)
        XCTAssertEqual(wide.compactChartHeight, TokenDailyBoardLayout.compactChartHeight, accuracy: 0.001)
        XCTAssertEqual(medium.compactChartHeight, TokenDailyBoardLayout.compactChartHeight, accuracy: 0.001)
        XCTAssertEqual(compact.compactChartHeight, TokenDailyBoardLayout.compactChartHeight, accuracy: 0.001)
        XCTAssertEqual(wide.monthPagerMonthSpacing, medium.monthPagerMonthSpacing, accuracy: 0.001)
        XCTAssertEqual(medium.monthPagerMonthSpacing, compact.monthPagerMonthSpacing, accuracy: 0.001)
    }

    func test_heroPresentationDoesNotUseBoxedInsight() {
        XCTAssertFalse(TokenDailyBoardHeroPresentationRules.showsBoxedInsight)
    }

    func test_comparisonPresentationUsesPlainTextInsteadOfCapsule() {
        XCTAssertFalse(TokenDailyBoardComparisonPresentationRules.usesCapsule)
    }

    func test_themeAccentsStayMonochromeInLightAndDarkModes() {
        self.assertNearZeroSaturation(TokenDailyBoardTheme.palette(for: .light).positiveAccentColor)
        self.assertNearZeroSaturation(TokenDailyBoardTheme.palette(for: .light).warningAccentColor)
        self.assertNearZeroSaturation(TokenDailyBoardTheme.palette(for: .light).neutralAccentColor)
        self.assertNearZeroSaturation(TokenDailyBoardTheme.palette(for: .light).windowAccentColor)

        self.assertNearZeroSaturation(TokenDailyBoardTheme.palette(for: .dark).positiveAccentColor)
        self.assertNearZeroSaturation(TokenDailyBoardTheme.palette(for: .dark).warningAccentColor)
        self.assertNearZeroSaturation(TokenDailyBoardTheme.palette(for: .dark).neutralAccentColor)
        self.assertNearZeroSaturation(TokenDailyBoardTheme.palette(for: .dark).windowAccentColor)
    }

    func test_sectionGridUsesFixedDateAndDataColumns() {
        XCTAssertEqual(TokenDailyBoardAlignmentRules.dateColumnWidth, 160, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardAlignmentRules.dataColumnWidth, 320, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardAlignmentRules.sectionColumnSpacing, 24, accuracy: 0.001)
    }

    func test_typographyUsesSingleSystemFamilyAndMonospacedDigitsOnlyForNumbers() {
        XCTAssertEqual(TokenDailyBoardTypography.todayDate.design, .default)
        XCTAssertEqual(TokenDailyBoardTypography.secondaryDate.design, .default)
        XCTAssertEqual(TokenDailyBoardTypography.archiveDate.design, .default)
        XCTAssertEqual(TokenDailyBoardTypography.heroTotal.design, .default)
        XCTAssertEqual(TokenDailyBoardTypography.heroMainThread.design, .default)
        XCTAssertEqual(TokenDailyBoardTypography.heroInstructionCount.design, .default)
        XCTAssertEqual(TokenDailyBoardTypography.secondaryInstructionCount.design, .default)
        XCTAssertEqual(TokenDailyBoardTypography.archiveInstructionCount.design, .default)
        XCTAssertTrue(TokenDailyBoardTypography.heroTotal.usesMonospacedDigits)
        XCTAssertTrue(TokenDailyBoardTypography.heroMainThread.usesMonospacedDigits)
        XCTAssertFalse(TokenDailyBoardTypography.heroInstructionCount.usesMonospacedDigits)
        XCTAssertFalse(TokenDailyBoardTypography.secondaryInstructionCount.usesMonospacedDigits)
        XCTAssertFalse(TokenDailyBoardTypography.archiveInstructionCount.usesMonospacedDigits)
    }

    func test_dataRailShowsInstructionCountButNoSummaryForEverySection() {
        XCTAssertTrue(TokenDailyBoardDataRailPresentationRules.showsInstructionCountInAllSections)
        XCTAssertFalse(TokenDailyBoardDataRailPresentationRules.showsSummaryInAllSections)
    }

    private func makeWindow(title: String, styleMask: NSWindow.StyleMask, frame: NSRect) -> NSWindow {
        let window = NSWindow(
            contentRect: frame,
            styleMask: styleMask,
            backing: .buffered,
            defer: false)
        window.title = title
        return window
    }

    private func assertNearZeroSaturation(_ color: NSColor, file: StaticString = #filePath, line: UInt = #line) {
        let srgb = color.usingColorSpace(.sRGB) ?? color
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        srgb.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        XCTAssertLessThanOrEqual(saturation, 0.03, file: file, line: line)
    }
}
