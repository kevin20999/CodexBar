import AppKit
import CodexDailyKit
import Observation
import SwiftUI

extension Notification.Name {
    fileprivate static let codexDailyNarrativeCustomize = Notification.Name("CodexDailyNarrativeCustomize")
    fileprivate static let codexDailyConversationOnlyDebugPanelToggle = Notification.Name(
        "CodexDailyConversationOnlyDebugPanelToggle")
}

@MainActor
@main
enum CodexDailyLauncher {
    private static var retainedDelegate: CodexDailyAppDelegate?

    static func main() {
        let app = NSApplication.shared
        let delegate = CodexDailyAppDelegate()
        self.retainedDelegate = delegate
        app.setActivationPolicy(.regular)
        app.delegate = delegate
        app.run()
    }
}

@MainActor
final class CodexDailyAppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let store = TokenDailyBoardStore()
    private let strings = TokenDailyBoardStrings()
    private let dockIconAnimator = CodexDailyDockIconAnimator()
    private var window: NSWindow?
    private var windowHoverTracker: CodexDailyConversationOnlyWindowHoverTracker?
    private var windowChromeAutoHideTask: Task<Void, Never>?
    private var displayModeAccessoryController: CodexDailyDisplayModeAccessoryController?
    private var debugPanelController: CodexDailyConversationOnlyDebugPanelController?
    private var debugPanelToggleObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        self.observeDockIconState()
        self.observeWindowPinState()
        self.observeTitlebarAutoHideState()
        self.observeWindowChromeVisibilityState()
        self.observeDebugPanelAvailability()
        self.observeDebugPanelToggleRequests()
        self.dockIconAnimator.updateSlots(self.store.avatarResolvedSlots)
        self.presentWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        self.presentWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let debugPanelToggleObserver {
            NotificationCenter.default.removeObserver(debugPanelToggleObserver)
            self.debugPanelToggleObserver = nil
        }
        self.windowHoverTracker?.detach()
        self.windowHoverTracker = nil
        self.cancelWindowChromeAutoHide()
        self.debugPanelController?.close()
        self.store.stopMonitoring()
    }

    func windowWillClose(_ notification: Notification) {
        if let closingWindow = notification.object as? NSWindow, closingWindow === self.window {
            self.windowHoverTracker?.detach()
            self.windowHoverTracker = nil
            self.cancelWindowChromeAutoHide()
            self.debugPanelController?.close()
            self.window = nil
            self.displayModeAccessoryController = nil
        }
    }

    func windowDidChangeScreen(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === self.window else { return }
        TokenDailyBoardWindowLayout.applyDisplayMode(
            self.store.boardDisplayMode,
            to: window,
            animated: false,
            tuning: self.store.conversationOnlyDebugTuning)
        self.applyConversationOnlyPinStateIfNeeded(to: window)
        self.applyWindowChromeVisibilityIfNeeded(to: window)
        self.displayModeAccessoryController?.updateWindowWidth(window.frame.width)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === self.window else { return }
        self.cancelWindowChromeAutoHide()
        self.store.setWindowChromeVisible(true)
        self.applyConversationOnlyPinStateIfNeeded(to: window)
        self.applyWindowChromeVisibilityIfNeeded(to: window)
    }

    func windowDidResize(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === self.window else { return }
        self.displayModeAccessoryController?.updateWindowWidth(window.frame.width)
    }

    func windowDidMove(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === self.window else { return }
        self.persistWindowPosition(window)
    }

    private func presentWindow() {
        let window = self.resolveWindow()

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func resolveWindow() -> NSWindow {
        if let window = self.window {
            return window
        }

        let visibleFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let initialSize = TokenDailyBoardWindowLayout.defaultSize(
            for: visibleFrame,
            displayMode: self.store.boardDisplayMode,
            tuning: self.store.conversationOnlyDebugTuning)
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: initialSize),
            styleMask: [.titled],
            backing: .buffered,
            defer: false)
        TokenDailyBoardWindowLayout.configureWindow(
            window,
            title: self.strings.dailyBoardWindowTitle,
            initialSize: initialSize,
            displayMode: self.store.boardDisplayMode,
            tuning: self.store.conversationOnlyDebugTuning)
        let chromeMetrics = TokenDailyBoardWindowLayout.chromeMetrics(for: window)
        let controller = NSHostingController(
            rootView: TokenDailyBoardView(
                store: self.store,
                strings: self.strings,
                chromeMetrics: chromeMetrics))
        window.contentViewController = controller
        window.delegate = self
        self.installDisplayModeAccessory(on: window, chromeMetrics: chromeMetrics)
        self.installConversationOnlyHoverTracking(on: window)
        TokenDailyBoardWindowLayout.applyDisplayMode(
            self.store.boardDisplayMode,
            to: window,
            animated: false,
            tuning: self.store.conversationOnlyDebugTuning)
        self.applyConversationOnlyPinStateIfNeeded(to: window)
        self.store.setWindowChromeVisible(true)
        self.store.setConversationOnlyWindowHovered(true)
        self.applyWindowChromeVisibilityIfNeeded(to: window)
        if !self.restoreSavedWindowPositionIfAvailable(window) {
            self.center(window)
        }
        self.window = window
        return window
    }

    private func center(_ window: NSWindow) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main
        guard let screen else { return }

        let targetFrame = TokenDailyBoardWindowLayout.centeredFrame(
            for: window.frame,
            in: screen.visibleFrame)
        window.setFrame(targetFrame, display: true)
    }

    private func restoreSavedWindowPositionIfAvailable(_ window: NSWindow) -> Bool {
        guard let savedOrigin = self.store.windowOrigin else { return false }
        let visibleFrame = TokenDailyBoardWindowLayout.resolvedVisibleFrame(for: window)
        let restoredFrame = TokenDailyBoardWindowLayout.restoredFrame(
            for: window.frame,
            savedOrigin: savedOrigin,
            in: visibleFrame)
        window.setFrame(restoredFrame, display: true)
        return true
    }

    private func persistWindowPosition(_ window: NSWindow) {
        self.store.setWindowOrigin(window.frame.origin)
    }

    private func applyConversationOnlyPinStateIfNeeded(to window: NSWindow) {
        window.level = TokenDailyBoardWindowPinRules.level(
            for: self.store.boardDisplayMode,
            isConversationOnlyPinned: self.store.isConversationOnlyPinned)
    }

    private func installDisplayModeAccessory(
        on window: NSWindow,
        chromeMetrics: TokenDailyBoardWindowChromeMetrics)
    {
        guard self.displayModeAccessoryController == nil else { return }
        let controller = CodexDailyDisplayModeAccessoryController(
            store: self.store,
            buttonDiameter: max(chromeMetrics.buttonDiameter + 10, 24),
            windowWidth: window.frame.width)
        window.addTitlebarAccessoryViewController(controller)
        self.displayModeAccessoryController = controller
    }

    private func installConversationOnlyHoverTracking(on window: NSWindow) {
        let tracker = self.windowHoverTracker
            ?? CodexDailyConversationOnlyWindowHoverTracker { [weak self] isHovered in
                guard let self else { return }
                self.handleConversationOnlyWindowHoverChange(isHovered)
            }
        self.windowHoverTracker = tracker
        tracker.attach(to: window)
    }

    private func handleConversationOnlyWindowHoverChange(_ isHovered: Bool) {
        self.store.setConversationOnlyWindowHovered(isHovered)

        guard TokenDailyBoardTitlebarAutoHideRules.shouldUseDelayedAutoHide(displayMode: self.store.boardDisplayMode)
        else {
            self.cancelWindowChromeAutoHide()
            self.store.setWindowChromeVisible(true)
            return
        }

        if isHovered {
            self.cancelWindowChromeAutoHide()
            self.store.setWindowChromeVisible(true)
        } else {
            self.scheduleWindowChromeAutoHide()
        }
    }

    private func scheduleWindowChromeAutoHide() {
        self.cancelWindowChromeAutoHide()
        self.windowChromeAutoHideTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: TokenDailyBoardTitlebarAutoHideRules.delayedAutoHideDelay)
            guard let self else { return }
            guard TokenDailyBoardTitlebarAutoHideRules.shouldUseDelayedAutoHide(
                displayMode: self.store.boardDisplayMode)
            else {
                return
            }
            guard !self.store.isConversationOnlyWindowHovered else { return }
            self.store.setWindowChromeVisible(false)
        }
    }

    private func cancelWindowChromeAutoHide() {
        self.windowChromeAutoHideTask?.cancel()
        self.windowChromeAutoHideTask = nil
    }

    private func applyWindowChromeVisibilityIfNeeded(to window: NSWindow) {
        TokenDailyBoardWindowLayout.styleSystemWindowButtons(
            window,
            displayMode: self.store.boardDisplayMode,
            isChromeVisible: self.store.windowChromeVisible,
            animated: true)
    }

    private func observeDockIconState() {
        withObservationTracking {
            _ = self.store.avatarResolvedSlots
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.dockIconAnimator.updateSlots(self.store.avatarResolvedSlots)
                self.observeDockIconState()
            }
        }
    }

    private func observeWindowPinState() {
        withObservationTracking {
            _ = self.store.boardDisplayMode
            _ = self.store.isConversationOnlyPinned
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let window = self.window {
                    self.applyConversationOnlyPinStateIfNeeded(to: window)
                }
                self.observeWindowPinState()
            }
        }
    }

    private func observeTitlebarAutoHideState() {
        withObservationTracking {
            _ = self.store.boardDisplayMode
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.cancelWindowChromeAutoHide()
                self.store.setConversationOnlyWindowHovered(true)
                self.store.setWindowChromeVisible(true)
                if let window = self.window {
                    self.applyWindowChromeVisibilityIfNeeded(to: window)
                }
                self.observeTitlebarAutoHideState()
            }
        }
    }

    private func observeWindowChromeVisibilityState() {
        withObservationTracking {
            _ = self.store.boardDisplayMode
            _ = self.store.windowChromeVisible
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let window = self.window {
                    self.applyWindowChromeVisibilityIfNeeded(to: window)
                }
                self.observeWindowChromeVisibilityState()
            }
        }
    }

    private func observeDebugPanelAvailability() {
        withObservationTracking {
            _ = self.store.boardDisplayMode
            _ = self.store.titlebarControlsCollapsed
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if !TokenDailyBoardDebugPanelPresentationRules.shouldRemainAvailable(
                    displayMode: self.store.boardDisplayMode,
                    titlebarControlsCollapsed: self.store.titlebarControlsCollapsed)
                {
                    self.debugPanelController?.close()
                }
                self.observeDebugPanelAvailability()
            }
        }
    }

    private func observeDebugPanelToggleRequests() {
        guard self.debugPanelToggleObserver == nil else { return }

        self.debugPanelToggleObserver = NotificationCenter.default.addObserver(
            forName: .codexDailyConversationOnlyDebugPanelToggle,
            object: nil,
            queue: .main)
        { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard TokenDailyBoardDebugPanelPresentationRules.shouldRemainAvailable(
                    displayMode: self.store.boardDisplayMode,
                    titlebarControlsCollapsed: self.store.titlebarControlsCollapsed)
                else {
                    return
                }
                let debugPanelController = self.debugPanelController
                    ?? CodexDailyConversationOnlyDebugPanelController(store: self.store)
                self.debugPanelController = debugPanelController
                debugPanelController.toggle(near: self.window ?? self.resolveWindow())
            }
        }
    }
}

@MainActor
private final class CodexDailyConversationOnlyWindowHoverTracker: NSObject {
    private let onHoverChange: (Bool) -> Void
    private weak var trackedView: NSView?
    private var trackingArea: NSTrackingArea?

    init(onHoverChange: @escaping (Bool) -> Void) {
        self.onHoverChange = onHoverChange
    }

    func attach(to window: NSWindow) {
        guard let trackedView = (window.contentView?.superview ?? window.contentView) else { return }
        guard self.trackedView !== trackedView else { return }
        self.detach()
        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil)
        trackedView.addTrackingArea(trackingArea)
        self.trackedView = trackedView
        self.trackingArea = trackingArea
    }

    func detach() {
        if let trackedView, let trackingArea {
            trackedView.removeTrackingArea(trackingArea)
        }
        self.trackedView = nil
        self.trackingArea = nil
    }

    @objc
    func mouseEntered(with event: NSEvent) {
        self.onHoverChange(true)
    }

    @objc
    func mouseExited(with event: NSEvent) {
        self.onHoverChange(false)
    }
}

@MainActor
private final class CodexDailyConversationOnlyDebugPanelController: NSObject, NSWindowDelegate {
    private let store: TokenDailyBoardStore
    private var panel: NSPanel?

    init(store: TokenDailyBoardStore) {
        self.store = store
    }

    func toggle(near mainWindow: NSWindow?) {
        if self.panel?.isVisible == true {
            self.close()
        } else {
            self.show(near: mainWindow)
        }
    }

    func show(near mainWindow: NSWindow?) {
        let panel = self.resolvePanel()
        let frame: CGRect

        if let savedOrigin = self.store.debugPanelOrigin {
            let visibleFrame = self.visibleFrame(
                for: savedOrigin,
                fallbackWindow: mainWindow ?? panel)
            frame = TokenDailyBoardDebugPanelPlacementRules.restoredFrame(
                savedOrigin: savedOrigin,
                panelSize: TokenDailyBoardDebugPanelPlacementRules.defaultPanelSize,
                visibleFrame: visibleFrame)
        } else if let mainWindow {
            let visibleFrame = TokenDailyBoardWindowLayout.resolvedVisibleFrame(for: mainWindow)
            frame = TokenDailyBoardDebugPanelPlacementRules.initialFrame(
                nearMainWindow: mainWindow.frame,
                panelSize: TokenDailyBoardDebugPanelPlacementRules.defaultPanelSize,
                visibleFrame: visibleFrame)
        } else {
            let visibleFrame = TokenDailyBoardWindowLayout.resolvedVisibleFrame(for: panel)
            frame = TokenDailyBoardWindowLayout.centeredFrame(
                for: CGRect(origin: .zero, size: TokenDailyBoardDebugPanelPlacementRules.defaultPanelSize),
                in: visibleFrame)
        }

        panel.setFrame(frame, display: true)
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        self.panel?.close()
    }

    func windowDidMove(_ notification: Notification) {
        guard let movedWindow = notification.object as? NSWindow, movedWindow === self.panel else { return }
        self.store.setDebugPanelOrigin(movedWindow.frame.origin)
    }

    func windowWillClose(_ notification: Notification) {
        guard let closingWindow = notification.object as? NSWindow, closingWindow === self.panel else { return }
        self.store.setDebugPanelOrigin(closingWindow.frame.origin)
    }

    private func resolvePanel() -> NSPanel {
        if let panel = self.panel {
            return panel
        }

        let panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: TokenDailyBoardDebugPanelPlacementRules.defaultPanelSize),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        panel.title = "位置调试"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.level = .normal
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.toolbar = nil
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isEnabled = false

        let contentController = NSHostingController(
            rootView: CodexDailyConversationOnlyPositionDebugPopover(store: self.store))
        panel.contentViewController = contentController

        self.panel = panel
        return panel
    }

    private func visibleFrame(for savedOrigin: CGPoint, fallbackWindow: NSWindow?) -> CGRect {
        NSScreen.screens.first(where: { $0.frame.contains(savedOrigin) })?.visibleFrame
            ?? TokenDailyBoardWindowLayout.resolvedVisibleFrame(for: fallbackWindow)
    }
}

@MainActor
private final class CodexDailyDockIconAnimator {
    private static let iconInset: CGFloat = 14
    private static let iconCornerRadius: CGFloat = 46

    private var slots: [CodexDailyAvatarResolvedSlot] = []
    private var cachedImages: [String: NSImage] = [:]

    func updateSlots(_ slots: [CodexDailyAvatarResolvedSlot]) {
        self.slots = slots
        self.cachedImages.removeAll()
        self.applyDefaultIcon()
    }

    private func applyDefaultIcon() {
        guard let defaultSlot = self.slots.first(where: { $0.slot == CodexDailyAvatarSlot.defaultAvatar }),
              let image = self.renderedDockIcon(for: defaultSlot)
        else {
            return
        }
        NSApp.applicationIconImage = image
    }

    private func renderedDockIcon(for slot: CodexDailyAvatarResolvedSlot) -> NSImage? {
        let cacheKey = "\(slot.slot.rawValue)-\(slot.isMirrored)"
        if let cached = self.cachedImages[cacheKey] {
            return cached
        }

        guard let sourceImage = slot.image ?? slot.conversationOnlyImage else { return nil }
        let targetSize = NSSize(
            width: CodexDailyDockIconAnimationRules.targetIconSize,
            height: CodexDailyDockIconAnimationRules.targetIconSize)
        let renderedImage = NSImage(size: targetSize)
        renderedImage.lockFocus()
        defer { renderedImage.unlockFocus() }

        guard let context = NSGraphicsContext.current else { return nil }
        context.imageInterpolation = .high
        let drawRect = NSRect(origin: .zero, size: targetSize)
        let insetRect = drawRect.insetBy(dx: Self.iconInset, dy: Self.iconInset)
        let clipPath = NSBezierPath(
            roundedRect: insetRect,
            xRadius: Self.iconCornerRadius,
            yRadius: Self.iconCornerRadius)

        NSGraphicsContext.saveGraphicsState()
        clipPath.addClip()

        if slot.isMirrored {
            let transform = NSAffineTransform()
            transform.translateX(by: insetRect.maxX + insetRect.minX, yBy: 0)
            transform.scaleX(by: -1, yBy: 1)
            transform.concat()
            sourceImage.draw(
                in: insetRect,
                from: NSRect(origin: .zero, size: sourceImage.size),
                operation: NSCompositingOperation.sourceOver,
                fraction: 1)
        } else {
            sourceImage.draw(
                in: insetRect,
                from: NSRect(origin: .zero, size: sourceImage.size),
                operation: NSCompositingOperation.sourceOver,
                fraction: 1)
        }
        NSGraphicsContext.restoreGraphicsState()

        self.cachedImages[cacheKey] = renderedImage
        return renderedImage
    }
}

@MainActor
private final class CodexDailyDisplayModeAccessoryController: NSTitlebarAccessoryViewController {
    private let store: TokenDailyBoardStore
    private let hostView: NSHostingView<CodexDailyTitlebarModeSwitcher>
    private let buttonDiameter: CGFloat
    private var trailingInset: CGFloat

    init(store: TokenDailyBoardStore, buttonDiameter: CGFloat, windowWidth: CGFloat) {
        self.store = store
        self.buttonDiameter = buttonDiameter
        self.trailingInset = TokenDailyBoardWindowChromeStyleRules.trailingInset(for: windowWidth)
        self.hostView = NSHostingView(
            rootView: CodexDailyTitlebarModeSwitcher(
                store: store,
                buttonDiameter: buttonDiameter,
                trailingInset: self.trailingInset))
        super.init(nibName: nil, bundle: nil)
        self.view = self.hostView
        self.layoutAttribute = .right
        self.fullScreenMinHeight = max(buttonDiameter, 24)
        self.refreshPreferredSize()
        self.observePreferredSize()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func observePreferredSize() {
        withObservationTracking {
            _ = self.store.cacheState
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.refreshPreferredSize()
                self?.observePreferredSize()
            }
        }
    }

    private func refreshPreferredSize() {
        let layoutMetrics = TokenDailyBoardTitlebarAccessoryLayoutRules.metrics(
            for: self.store.boardDisplayMode,
            isReady: self.store.cacheState == .ready,
            buttonDiameter: self.buttonDiameter,
            trailingInset: self.trailingInset)
        let resolvedSize = NSSize(
            width: max(layoutMetrics.accessoryWidth, 1),
            height: max(self.buttonDiameter, 24))
        self.hostView.frame = NSRect(origin: .zero, size: resolvedSize)
        self.preferredContentSize = resolvedSize
        self.fullScreenMinHeight = resolvedSize.height
    }

    func updateWindowWidth(_ width: CGFloat) {
        let resolvedInset = TokenDailyBoardWindowChromeStyleRules.trailingInset(for: width)
        guard abs(resolvedInset - self.trailingInset) > 0.001 else { return }
        self.trailingInset = resolvedInset
        self.hostView.rootView = CodexDailyTitlebarModeSwitcher(
            store: self.store,
            buttonDiameter: self.buttonDiameter,
            trailingInset: resolvedInset)
        self.refreshPreferredSize()
    }
}

private struct CodexDailyTitlebarModeSwitcher: View {
    @Bindable var store: TokenDailyBoardStore
    let buttonDiameter: CGFloat
    let trailingInset: CGFloat

    private var isVisible: Bool {
        TokenDailyBoardTitlebarAutoHideRules.shouldShowAccessory(
            displayMode: self.store.boardDisplayMode,
            isWindowHovered: self.store.isConversationOnlyWindowHovered,
            windowChromeVisible: self.store.windowChromeVisible)
    }

    private var layoutMetrics: TokenDailyBoardTitlebarAccessoryLayoutMetrics {
        TokenDailyBoardTitlebarAccessoryLayoutRules.metrics(
            for: self.store.boardDisplayMode,
            isReady: self.store.cacheState == .ready,
            buttonDiameter: self.buttonDiameter,
            trailingInset: self.trailingInset)
    }

    private var titlebarRevealAnimation: Animation {
        .snappy(duration: 0.22, extraBounce: 0)
    }

    var body: some View {
        Group {
            if self.store.cacheState == .ready {
                ZStack(alignment: .leading) {
                    self.expandedButtonCluster
                        .frame(width: self.layoutMetrics.clusterTrackWidth, alignment: .trailing)
                        .mask(alignment: .trailing) {
                            Rectangle()
                                .frame(
                                    width: self.store.titlebarControlsCollapsed
                                        ? self.layoutMetrics.clusterRevealCollapsedWidth
                                        : self.layoutMetrics.clusterRevealExpandedWidth,
                                    height: self.buttonDiameter)
                        }
                        .allowsHitTesting(
                            TokenDailyBoardTitlebarAutoHideRules.effectiveExpandedClusterHitTesting(
                                displayMode: self.store.boardDisplayMode,
                                isWindowHovered: self.store.isConversationOnlyWindowHovered,
                                windowChromeVisible: self.store.windowChromeVisible,
                                titlebarControlsCollapsed: self.store.titlebarControlsCollapsed))

                    self.toggleButton(
                        symbol: self.store.titlebarControlsCollapsed ? "chevron.right" : "chevron.left",
                        helpText: self.store.titlebarControlsCollapsed ? "展开顶部按钮" : "收起顶部按钮",
                        isCollapsed: self.store.titlebarControlsCollapsed ? false : true)
                        .frame(width: self.layoutMetrics.toggleSlotWidth, height: self.buttonDiameter)
                        .offset(x: self.layoutMetrics.toggleAnchorX)
                        .zIndex(1)
                }
                .frame(width: self.layoutMetrics.contentWidth, alignment: .leading)
            } else {
                Color.clear.frame(width: self.layoutMetrics.contentWidth, height: self.buttonDiameter)
            }
        }
        .opacity(self.isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.18), value: self.store.windowChromeVisible)
        .animation(self.titlebarRevealAnimation, value: self.store.titlebarControlsCollapsed)
        .allowsHitTesting(self.isVisible)
        .padding(.trailing, self.trailingInset)
        .frame(width: self.layoutMetrics.accessoryWidth, alignment: .leading)
    }

    private var expandedButtonCluster: some View {
        HStack(spacing: self.layoutMetrics.clusterButtonSpacing) {
            self.button(symbol: "ellipsis.bubble", mode: .conversationOnly)
            self.button(symbol: "bubble.left.and.bubble.right", mode: .conversationAndToday)
            self.button(symbol: "rectangle.grid.1x2", mode: .fullBoard)

            if TokenDailyBoardConversationOnlyDebugRules.shouldShowPositionDebugger(for: self.store.boardDisplayMode) {
                self.pinButton
                self.positionDebugButton
                self.actionButton(
                    symbol: "slider.horizontal.3",
                    helpText: "自定义文案",
                    notificationName: .codexDailyNarrativeCustomize)
            }
        }
    }

    private func button(symbol: String, mode: TokenDailyBoardDisplayMode) -> some View {
        Button {
            self.store.setBoardDisplayMode(mode)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: max(self.buttonDiameter * 0.46, 8), weight: .semibold))
                .foregroundStyle(self.textColor(for: mode))
                .frame(width: self.buttonDiameter, height: self.buttonDiameter)
        }
        .buttonStyle(TitlebarCircleButtonStyle())
        .disabled(self.store.isBoardDisplayModeTransitioning)
        .help(self.helpText(for: mode))
    }

    private func actionButton(symbol: String, helpText: String, notificationName: Notification.Name) -> some View {
        Button {
            NotificationCenter.default.post(name: notificationName, object: nil)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: max(self.buttonDiameter * 0.44, 8), weight: .semibold))
                .foregroundStyle(Color.primary.opacity(TokenDailyBoardWindowChromeStyleRules.actionButtonOpacity))
                .frame(width: self.buttonDiameter, height: self.buttonDiameter)
        }
        .buttonStyle(TitlebarCircleButtonStyle())
        .help(helpText)
    }

    private func toggleButton(symbol: String, helpText: String, isCollapsed: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                self.store.setTitlebarControlsCollapsed(isCollapsed)
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: max(self.buttonDiameter * 0.42, 8), weight: .semibold))
                .foregroundStyle(Color.primary.opacity(TokenDailyBoardWindowChromeStyleRules.toggleButtonOpacity))
                .frame(width: self.buttonDiameter, height: self.buttonDiameter)
        }
        .buttonStyle(TitlebarCircleButtonStyle())
        .help(helpText)
    }

    private var positionDebugButton: some View {
        Button {
            NotificationCenter.default.post(name: .codexDailyConversationOnlyDebugPanelToggle, object: nil)
        } label: {
            Image(systemName: TokenDailyBoardConversationOnlyDebugRules.buttonSymbol)
                .font(.system(size: max(self.buttonDiameter * 0.44, 8), weight: .semibold))
                .foregroundStyle(Color.primary.opacity(TokenDailyBoardWindowChromeStyleRules.actionButtonOpacity))
                .frame(width: self.buttonDiameter, height: self.buttonDiameter)
        }
        .buttonStyle(TitlebarCircleButtonStyle())
        .help("调试模式 1 位置")
    }

    private var pinButton: some View {
        Button {
            self.store.setConversationOnlyPinned(!self.store.isConversationOnlyPinned)
        } label: {
            Image(systemName: self.store.isConversationOnlyPinned ? "pin.fill" : "pin")
                .font(.system(size: max(self.buttonDiameter * 0.44, 8), weight: .semibold))
                .foregroundStyle(Color.primary.opacity(TokenDailyBoardWindowChromeStyleRules.actionButtonOpacity))
                .frame(width: self.buttonDiameter, height: self.buttonDiameter)
        }
        .buttonStyle(TitlebarCircleButtonStyle())
        .help(self.store.isConversationOnlyPinned ? "取消置顶窗口" : "置顶窗口")
    }

    private func textColor(for mode: TokenDailyBoardDisplayMode) -> Color {
        Color.primary.opacity(
            TokenDailyBoardWindowChromeStyleRules.modeButtonOpacity(
                isSelected: self.store.boardDisplayMode == mode))
    }

    private func helpText(for mode: TokenDailyBoardDisplayMode) -> String {
        switch mode {
        case .conversationOnly:
            "只显示对话气泡"
        case .conversationAndToday:
            "显示对话气泡和今天"
        case .fullBoard:
            "显示完整月视图"
        }
    }
}

private struct TitlebarCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TitlebarCircleButtonStyleBody(configuration: configuration)
    }
}

private struct TitlebarCircleButtonStyleBody: View {
    let configuration: ButtonStyleConfiguration

    @State private var isHovered = false

    private var isHighlighted: Bool {
        self.isHovered || self.configuration.isPressed
    }

    private var fillOpacity: Double {
        if self.configuration.isPressed {
            return TokenDailyBoardWindowChromeStyleRules.pressedFillOpacity
        }
        if self.isHovered {
            return TokenDailyBoardWindowChromeStyleRules.hoverFillOpacity
        }
        return 0
    }

    var body: some View {
        self.configuration.label
            .background {
                Circle()
                    .fill(Color.primary.opacity(self.fillOpacity))
                    .overlay {
                        Circle()
                            .strokeBorder(
                                Color.primary.opacity(self.isHighlighted
                                    ? TokenDailyBoardWindowChromeStyleRules.hoverStrokeOpacity
                                    : 0),
                                lineWidth: 0.5)
                    }
            }
            .contentShape(Circle())
            .scaleEffect(self.configuration.isPressed ? TokenDailyBoardWindowChromeStyleRules.pressedScale : 1)
            .animation(.easeOut(duration: 0.14), value: self.isHovered)
            .animation(.easeOut(duration: 0.12), value: self.configuration.isPressed)
            .onHover { hovering in
                self.isHovered = hovering
            }
    }
}

private struct CodexDailyConversationOnlyPositionDebugPopover: View {
    @Bindable var store: TokenDailyBoardStore

    private var tuning: TokenDailyBoardConversationOnlyDebugTuning {
        self.store.conversationOnlyDebugTuning
    }

    private func binding(
        get value: @escaping (TokenDailyBoardConversationOnlyDebugTuning) -> CGFloat,
        set update: @escaping (inout TokenDailyBoardConversationOnlyDebugTuning, CGFloat) -> Void)
        -> Binding<Double>
    {
        Binding(
            get: { Double(value(self.store.conversationOnlyDebugTuning)) },
            set: {
                var tuning = self.store.conversationOnlyDebugTuning
                update(&tuning, CGFloat($0))
                self.store.setConversationOnlyDebugTuning(tuning)
            })
    }

    private func boolBinding(
        get value: @escaping (TokenDailyBoardConversationOnlyDebugTuning) -> Bool,
        set update: @escaping (inout TokenDailyBoardConversationOnlyDebugTuning, Bool) -> Void)
        -> Binding<Bool>
    {
        Binding(
            get: { value(self.store.conversationOnlyDebugTuning) },
            set: {
                var tuning = self.store.conversationOnlyDebugTuning
                update(&tuning, $0)
                self.store.setConversationOnlyDebugTuning(tuning)
            })
    }

    private var contentOffsetXBinding: Binding<Double> {
        self.binding(
            get: { $0.contentOffset.width },
            set: { $0.contentOffset.width = $1 })
    }

    private var contentOffsetYBinding: Binding<Double> {
        self.binding(
            get: { $0.contentOffset.height },
            set: { $0.contentOffset.height = $1 })
    }

    private var windowWidthBinding: Binding<Double> {
        self.binding(
            get: { $0.windowWidth },
            set: { $0.windowWidth = $1 })
    }

    private var windowGlassOpacityBinding: Binding<Double> {
        self.binding(
            get: { $0.windowGlassOpacity },
            set: { $0.windowGlassOpacity = $1 })
    }

    private var windowGlassBlurBinding: Binding<Double> {
        self.binding(
            get: { $0.windowGlassBlur },
            set: { $0.windowGlassBlur = $1 })
    }

    private var enablesPreNarrativeWindowPulseBinding: Binding<Bool> {
        self.boolBinding(
            get: { $0.enablesPreNarrativeWindowPulse },
            set: { $0.enablesPreNarrativeWindowPulse = $1 })
    }

    private var enablesAvatarReplacementAnimationBinding: Binding<Bool> {
        self.boolBinding(
            get: { $0.enablesAvatarReplacementAnimation },
            set: { $0.enablesAvatarReplacementAnimation = $1 })
    }

    private var animationPresetBinding: Binding<TokenDailyBoardConversationOnlyAnimationPreset> {
        Binding(
            get: { self.store.conversationOnlyDebugTuning.animationPreset },
            set: {
                var tuning = self.store.conversationOnlyDebugTuning
                tuning.animationPreset = $0
                self.store.setConversationOnlyDebugTuning(tuning)
            })
    }

    private var pulseDurationScaleBinding: Binding<Double> {
        self.binding(
            get: { $0.pulseDurationScale },
            set: { $0.pulseDurationScale = $1 })
    }

    private var avatarIntensityScaleBinding: Binding<Double> {
        self.binding(
            get: { $0.avatarIntensityScale },
            set: { $0.avatarIntensityScale = $1 })
    }

    private var bodyTypewriterSpeedScaleBinding: Binding<Double> {
        self.binding(
            get: { $0.bodyTypewriterSpeedScale },
            set: { $0.bodyTypewriterSpeedScale = $1 })
    }

    private var metadataTypewriterSpeedScaleBinding: Binding<Double> {
        self.binding(
            get: { $0.metadataTypewriterSpeedScale },
            set: { $0.metadataTypewriterSpeedScale = $1 })
    }

    private var avatarSizeBinding: Binding<Double> {
        self.binding(
            get: { $0.avatarSize },
            set: { $0.avatarSize = $1 })
    }

    private var bodyFontSizeBinding: Binding<Double> {
        self.binding(
            get: { $0.bodyFontSize },
            set: { $0.bodyFontSize = $1 })
    }

    private var textColumnOffsetXBinding: Binding<Double> {
        self.binding(
            get: { $0.textColumnOffset.width },
            set: { $0.textColumnOffset.width = $1 })
    }

    private var textColumnOffsetYBinding: Binding<Double> {
        self.binding(
            get: { $0.textColumnOffset.height },
            set: { $0.textColumnOffset.height = $1 })
    }

    private var textColumnWidthBinding: Binding<Double> {
        self.binding(
            get: { $0.textColumnWidth },
            set: { $0.textColumnWidth = $1 })
    }

    private var bodyLineSpacingBinding: Binding<Double> {
        self.binding(
            get: { $0.bodyLineSpacing },
            set: { $0.bodyLineSpacing = $1 })
    }

    private var metadataFontSizeBinding: Binding<Double> {
        self.binding(
            get: { $0.metadataFontSize },
            set: { $0.metadataFontSize = $1 })
    }

    private var metadataOpacityBinding: Binding<Double> {
        self.binding(
            get: { $0.metadataOpacity },
            set: { $0.metadataOpacity = $1 })
    }

    private var isResetDisabled: Bool {
        self.tuning == TokenDailyBoardConversationOnlyDebugRules.defaultTuning
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("位置调试")
                    .font(.system(size: 14, weight: .semibold))

                self.section(
                    "整体",
                    content: Group {
                        self.sliderRow(
                            title: "水平",
                            binding: self.contentOffsetXBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.overallOffsetRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.overallOffsetStep)
                        self.sliderRow(
                            title: "垂直",
                            binding: self.contentOffsetYBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.overallOffsetRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.overallOffsetStep)
                    })

                self.section(
                    "窗口",
                    content: Group {
                        self.sliderRow(
                            title: "宽度",
                            binding: self.windowWidthBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.windowWidthRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.windowWidthStep,
                            formatter: self.decimalFormatter(digits: 0))
                        self.sliderRow(
                            title: "玻璃透明",
                            binding: self.windowGlassOpacityBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.windowGlassOpacityRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.windowGlassOpacityStep,
                            formatter: self.decimalFormatter(digits: 2))
                        self.sliderRow(
                            title: "玻璃模糊",
                            binding: self.windowGlassBlurBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.windowGlassBlurRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.windowGlassBlurStep,
                            formatter: self.decimalFormatter(digits: 0))
                    })

                self.section(
                    "动画",
                    content: Group {
                        self.toggleRow(
                            title: "对话前窗口能量动画",
                            isOn: self.enablesPreNarrativeWindowPulseBinding)
                        self.toggleRow(
                            title: "头像替换动画",
                            isOn: self.enablesAvatarReplacementAnimationBinding)
                    })

                self.section(
                    "组合动画",
                    content: Group {
                        self.presetRow
                        self.sliderRow(
                            title: "光效时长",
                            binding: self.pulseDurationScaleBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.pulseDurationScaleRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.pulseDurationScaleStep,
                            formatter: self.decimalFormatter(digits: 2))
                        self.sliderRow(
                            title: "头像强度",
                            binding: self.avatarIntensityScaleBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.avatarIntensityScaleRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.avatarIntensityScaleStep,
                            formatter: self.decimalFormatter(digits: 2))
                        self.sliderRow(
                            title: "正文速度",
                            binding: self.bodyTypewriterSpeedScaleBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.bodyTypewriterSpeedScaleRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.bodyTypewriterSpeedScaleStep,
                            formatter: self.decimalFormatter(digits: 2))
                        self.sliderRow(
                            title: "时间速度",
                            binding: self.metadataTypewriterSpeedScaleBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.metadataTypewriterSpeedScaleRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.metadataTypewriterSpeedScaleStep,
                            formatter: self.decimalFormatter(digits: 2))
                    })

                self.section(
                    "头像",
                    content: Group {
                        self.sliderRow(
                            title: "大小",
                            binding: self.avatarSizeBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.avatarSizeRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.avatarSizeStep,
                            formatter: self.decimalFormatter(digits: 0))
                    })

                self.section(
                    "正文",
                    content: Group {
                        self.sliderRow(
                            title: "字号",
                            binding: self.bodyFontSizeBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.bodyFontSizeRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.bodyFontSizeStep)
                        self.sliderRow(
                            title: "列 X",
                            binding: self.textColumnOffsetXBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.textColumnOffsetXRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.textColumnOffsetStep,
                            formatter: self.decimalFormatter(digits: 0))
                        self.sliderRow(
                            title: "列 Y",
                            binding: self.textColumnOffsetYBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.textColumnOffsetYRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.textColumnOffsetStep,
                            formatter: self.decimalFormatter(digits: 0))
                        self.sliderRow(
                            title: "宽度",
                            binding: self.textColumnWidthBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.textColumnWidthRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.textColumnWidthStep,
                            formatter: self.decimalFormatter(digits: 0))
                        self.sliderRow(
                            title: "行距",
                            binding: self.bodyLineSpacingBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.bodyLineSpacingRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.bodyLineSpacingStep)
                    })

                self.section(
                    "时间和 Token",
                    content: Group {
                        self.sliderRow(
                            title: "字号",
                            binding: self.metadataFontSizeBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.metadataFontSizeRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.metadataFontSizeStep)
                        self.sliderRow(
                            title: "透明",
                            binding: self.metadataOpacityBinding,
                            range: TokenDailyBoardConversationOnlyDebugRules.metadataOpacityRange,
                            step: TokenDailyBoardConversationOnlyDebugRules.metadataOpacityStep,
                            formatter: self.decimalFormatter(digits: 2))
                    })

                HStack {
                    Spacer(minLength: 0)

                    Button("重置") {
                        self.store.resetConversationOnlyDebugTuning()
                    }
                    .disabled(self.isResetDisabled)
                }
            }
        }
        .padding(14)
        .frame(width: 320, height: 520)
    }

    private func section(_ title: String, content: some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            content
        }
    }

    private var presetRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("预设")
                .font(.system(size: 12, weight: .medium))

            Picker("动画预设", selection: self.animationPresetBinding) {
                ForEach(TokenDailyBoardConversationOnlyAnimationPreset.allCases, id: \.self) { preset in
                    Text(self.title(for: preset))
                        .tag(preset)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func sliderRow(
        title: String,
        binding: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        formatter: @escaping (Double) -> String = { String(format: "%.1f", $0) })
        -> some View
    {
        HStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 56, alignment: .leading)

            Slider(
                value: binding,
                in: range,
                step: step)

            Text(formatter(binding.wrappedValue))
                .font(.system(size: 12, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
        }
        .toggleStyle(.switch)
    }

    private func decimalFormatter(digits: Int) -> (Double) -> String {
        { value in
            String(format: "%.\(digits)f", value)
        }
    }

    private func title(for preset: TokenDailyBoardConversationOnlyAnimationPreset) -> String {
        switch preset {
        case .cinematic:
            "电影感"
        case .aggressive:
            "狠快"
        case .gentle:
            "轻稳"
        }
    }
}
