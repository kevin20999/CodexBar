import AppKit
import Logging
import Observation
import SwiftUI

enum TokenMenuPanelPlacement {
    static let topGap: CGFloat = 6
    static let screenInset: CGFloat = 8

    static func frame(
        anchorRect: CGRect,
        panelSize: CGSize,
        visibleFrame: CGRect,
        topGap: CGFloat = Self.topGap,
        screenInset: CGFloat = Self.screenInset)
        -> CGRect
    {
        let availableHeight = max(visibleFrame.height - (screenInset * 2), 0)
        let height = min(panelSize.height, availableHeight)
        let minX = visibleFrame.minX + screenInset
        let maxX = visibleFrame.maxX - panelSize.width - screenInset
        let minY = visibleFrame.minY + screenInset
        let maxY = visibleFrame.maxY - height - screenInset

        let centeredX = anchorRect.midX - (panelSize.width / 2)
        let anchoredY = anchorRect.minY - topGap - height

        let originX = min(max(centeredX, minX), maxX)
        let originY = min(max(anchoredY, minY), maxY)

        return CGRect(x: originX, y: originY, width: panelSize.width, height: height)
    }
}

enum TokenMenuBarInteractionPolicy {
    static let mainPanelEvents: NSEvent.EventTypeMask = [.leftMouseDown]
    static let speedPanelEvents: NSEvent.EventTypeMask = [.leftMouseUp]
}

enum TokenMenuPopupAnimationPolicy {
    static let liquidGlassAnimationBehavior: NSWindow.AnimationBehavior = .none
    static let systemPopoverAnimates = true
}

enum TokenMenuPanelHotPath {
    static let measurementDelay: Duration = .milliseconds(3800)
}

private enum TokenMenuPanelSizingSource: String {
    case memory = "memory-hit"
    case persisted = "persisted-hit"
    case fallback = "default-height"
}

@MainActor
final class TokenMenuBarController: NSObject {
    private static let speedButtonHostingViewIdentifier = NSUserInterfaceItemIdentifier(
        "TokenMenuSpeedStatusHostingView")

    private let settings: SettingsStore
    private let store: UsageStore
    private let statusBar: NSStatusBar
    private let statusItem: NSStatusItem
    private let panelController: TokenMenuPanelController
    private let popoverController: TokenMenuPopoverController
    private let speedPanelController: TokenSpeedPanelController
    private let speedFloatingChartStateStore: TokenSpeedFloatingChartStateStore
    private let speedFloatingChartController: TokenSpeedFloatingChartController
    private let speedBubbleController = TokenMenuSpeedBubbleController()
    private let speedStatusItemModel = TokenMenuSpeedStatusItemModel()
    private var speedStatusItem: NSStatusItem?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    private var screenParametersObserver: NSObjectProtocol?
    private var becomeActiveObserver: NSObjectProtocol?
    private var resignActiveObserver: NSObjectProtocol?
    private var suppressSpeedBubbleWhileInactive = false
    private var mainPanelSizingCache: TokenMenuPanelSizingCache?
    private var mainPanelMeasurementTask: Task<Void, Never>?
    private var mainPanelPendingMeasurementHeightCacheKey: TokenMenuPanelHeightCacheKey?
    private var warmedMainPanelSignature: TokenMenuPanelLayoutSignature?
    private let logger = Logger(label: "CodexBar.token-menu-panel")

    init(settings: SettingsStore, store: UsageStore, statusBar: NSStatusBar = .system) {
        let floatingChartStateStore = TokenSpeedFloatingChartStateStore()
        self.settings = settings
        self.store = store
        self.statusBar = statusBar
        self.statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        self.panelController = TokenMenuPanelController(settings: settings, store: store)
        self.popoverController = TokenMenuPopoverController(settings: settings, store: store)
        self.speedPanelController = TokenSpeedPanelController(settings: settings, store: store)
        self.speedFloatingChartStateStore = floatingChartStateStore
        self.speedFloatingChartController = TokenSpeedFloatingChartController(
            settings: settings,
            store: store,
            stateStore: floatingChartStateStore)
        super.init()
        self.panelController.onRequestClose = { [weak self] in
            self?.hideMainPanel()
        }
        self.speedPanelController.onRequestClose = { [weak self] in
            self?.hideSpeedPanel()
        }
        self.speedPanelController.setFloatingChartPresentation(
            isPresented: false,
            onToggle: { [weak self] in
                self?.toggleFloatingChart()
            })
        self.speedFloatingChartController.onVisibilityChange = { [weak self] isVisible in
            self?.updateFloatingChartPresentationState(isPresented: isVisible)
        }
    }

    func start() {
        self.configureStatusItem()
        self.observeLabelState()
        self.observePanelLayoutState()
        self.registerNotifications()
        self.updateStatusItemAppearance()
    }

    private func configureStatusItem() {
        guard let button = self.statusItem.button else { return }
        button.target = self
        button.action = #selector(self.togglePanel(_:))
        button.sendAction(on: TokenMenuBarInteractionPolicy.mainPanelEvents)
        button.imageScaling = .scaleNone
    }

    private func registerNotifications() {
        self.screenParametersObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main)
        { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePanelFrameIfNeeded()
                self?.speedFloatingChartController.reclampToVisibleScreenIfNeeded()
                self?.updateStatusItemAppearance()
            }
        }

        self.resignActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main)
        { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.suppressSpeedBubbleWhileInactive = true
                self?.hideVisiblePanels(restoreSpeedBubble: false)
                self?.hideSpeedBubble(animated: false)
            }
        }

        self.becomeActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main)
        { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.suppressSpeedBubbleWhileInactive = false
                self?.updateStatusItemAppearance()
            }
        }
    }

    private func observeLabelState() {
        withObservationTracking {
            _ = self.settings.appLanguage
            _ = self.settings.menuBarDisplayMode
            _ = self.settings.menuBarQuotaStyle
            _ = self.settings.showsMenuBarTokenSpeedMeter
            _ = self.store.menuBarDisplayMetrics
            _ = self.store.menuBarTokenSpeedMetrics
            _ = self.store.menuBarText(for: self.settings.menuBarDisplayMode)
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.observeLabelState()
                self.updateStatusItemAppearance()
            }
        }
    }

    private func observePanelLayoutState() {
        withObservationTracking {
            _ = MenuContent.panelHeightCacheKey(store: self.store, settings: self.settings)
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.observePanelLayoutState()
                self.updatePanelFrameIfNeeded()
            }
        }
    }

    private var isMainPopupVisible: Bool {
        self.panelController.isVisible || self.popoverController.isVisible
    }

    private func visibleMainPopupStyle() -> MenuPopupStyle? {
        if self.panelController.isVisible {
            return .liquidGlass
        }
        if self.popoverController.isVisible {
            return .systemPopover
        }
        return nil
    }

    private func mainPopupContainerContext(for style: MenuPopupStyle) -> MenuContent.PanelContainerContext {
        switch style {
        case .liquidGlass:
            .anchoredPanel
        case .systemPopover:
            .anchoredSystemPopover
        }
    }

    private func updateStatusItemAppearance() {
        self.updatePrimaryStatusItemAppearance()
        self.updateSpeedStatusItemAppearance()
    }

    private func updatePrimaryStatusItemAppearance() {
        guard let button = self.statusItem.button else { return }

        let labelText = self.store.menuBarText(for: self.settings.menuBarDisplayMode)
        button.toolTip = labelText

        if let rendered = MenuBarDisplayRenderer.render(
            mode: self.settings.menuBarDisplayMode,
            metrics: self.store.menuBarDisplayMetrics,
            quotaStyle: self.settings.menuBarQuotaStyle)
        {
            let image = rendered.image.copy() as? NSImage ?? rendered.image
            image.size = rendered.displaySize
            button.image = image
            button.imagePosition = .imageOnly
            button.title = ""
            button.attributedTitle = NSAttributedString(string: "")
        } else {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            ]
            button.image = nil
            button.imagePosition = .noImage
            button.title = ""
            button.attributedTitle = NSAttributedString(string: labelText, attributes: attributes)
        }
    }

    private func updateSpeedStatusItemAppearance() {
        guard self.settings.showsMenuBarTokenSpeedMeter,
              TokenMenuSpeedMeterFeature.supportsVisualPresentation
        else {
            self.hideFloatingChart()
            self.removeSpeedStatusItem()
            return
        }

        let statusItem = self.speedStatusItem ?? self.makeSpeedStatusItem()
        self.speedStatusItem = statusItem
        statusItem.length = TokenMenuSpeedMeterLayout.statusItemWidth

        guard let button = statusItem.button else { return }
        let metrics = self.store.menuBarTokenSpeedMetrics
        self.updateSpeedStatusButtonHostedView(button: button, metrics: metrics)
        button.toolTip = self.settings.strings.menuBarTokenSpeedTooltip(tokensPerSecond: metrics.tokensPerSecond)

        if self.isMainPopupVisible
            || self.speedPanelController.isVisible
            || self.suppressSpeedBubbleWhileInactive
        {
            self.hideSpeedBubble(animated: false)
            return
        }

        self.updateSpeedBubble(relativeTo: button, metrics: metrics)
    }

    private func makeSpeedStatusItem() -> NSStatusItem {
        let statusItem = self.statusBar.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(self.toggleSpeedPanel(_:))
            button.sendAction(on: TokenMenuBarInteractionPolicy.speedPanelEvents)
            button.imageScaling = .scaleNone
        }
        return statusItem
    }

    private func removeSpeedStatusItem() {
        self.hideSpeedBubble(animated: false)
        guard let speedStatusItem = self.speedStatusItem else { return }
        self.statusBar.removeStatusItem(speedStatusItem)
        self.speedStatusItem = nil
    }

    @objc
    private func togglePanel(_ sender: Any?) {
        let anchorButton = (sender as? NSStatusBarButton) ?? self.statusItem.button
        guard let button = anchorButton else { return }

        if self.isMainPopupVisible {
            self.hideMainPanel()
        } else {
            self.showMainPanel(relativeTo: button)
        }
    }

    @objc
    private func toggleSpeedPanel(_ sender: Any?) {
        let anchorButton = (sender as? NSStatusBarButton) ?? self.speedStatusItem?.button
        guard let button = anchorButton else { return }

        if self.speedPanelController.isVisible {
            self.hideSpeedPanel()
        } else {
            self.showSpeedPanel(relativeTo: button)
        }
    }

    private func showMainPanel(relativeTo button: NSStatusBarButton) {
        guard let anchorRect = self.buttonFrameOnScreen(button) else { return }
        self.hideSpeedPanel(restoreSpeedBubble: false)
        self.hideSpeedBubble(animated: false)

        let popupStyle = self.settings.menuPopupStyle
        let panelContainerContext = self.mainPopupContainerContext(for: popupStyle)
        let visibleFrame = self.visibleFrame(for: anchorRect, button: button)
        let signature = MenuContent.layoutSignature(
            store: self.store,
            settings: self.settings,
            popupStyleOverride: popupStyle)
        let (panelMetrics, sizingSource) = self.cachedMainPanelSizing(
            signature: signature,
            availableScreenHeight: visibleFrame.height)

        let openKind = TokenMenuPanelRenderPhaseResolver.openKind(
            signature: signature,
            warmedSignature: self.warmedMainPanelSignature)
        let renderPhaseMode = TokenMenuPanelRenderPhaseResolver.renderPhaseMode(
            signature: signature,
            warmedSignature: self.warmedMainPanelSignature)
        self.logger.debug("Main panel mouse-down-open requested")
        self.logger.debug("Main panel \(openKind.rawValue) requested")
        switch popupStyle {
        case .liquidGlass:
            let preferredSize = CGSize(
                width: MenuContent.preferredPanelWidth,
                height: panelMetrics.displayHeight)
            let frame = TokenMenuPanelPlacement.frame(
                anchorRect: anchorRect,
                panelSize: preferredSize,
                visibleFrame: visibleFrame)
            self.popoverController.hide()
            self.panelController.present(
                frame: frame,
                allowsScrolling: panelMetrics.allowsScrolling,
                signature: signature,
                renderPhaseMode: renderPhaseMode)
            self.installDismissMonitors()
        case .systemPopover:
            self.panelController.hide()
            self.popoverController.present(
                relativeTo: button,
                displayHeight: panelMetrics.displayHeight,
                allowsScrolling: panelMetrics.allowsScrolling,
                signature: signature,
                renderPhaseMode: renderPhaseMode)
            self.removeDismissMonitors()
        }
        self.warmedMainPanelSignature = signature
        self.logger.debug(
            "Presented main panel [mode: \(openKind.rawValue), sizingSource: \(sizingSource.rawValue), structureKey: \(signature.heightCacheKey.storageKey), displayHeight: \(panelMetrics.displayHeight)]")
        self.scheduleMainPanelMeasurementIfNeeded(
            relativeTo: button,
            signature: signature,
            panelContainerContext: panelContainerContext)
    }

    private func showSpeedPanel(relativeTo button: NSStatusBarButton) {
        guard let anchorRect = self.buttonFrameOnScreen(button) else { return }
        self.hideMainPanel(restoreSpeedBubble: false)
        self.hideSpeedBubble(animated: false)

        let visibleFrame = self.visibleFrame(for: anchorRect, button: button)
        let panelMetrics = TokenSpeedPanelContent.panelMetrics(availableScreenHeight: visibleFrame.height)
        let preferredSize = CGSize(
            width: TokenSpeedPanelContent.preferredPanelWidth,
            height: panelMetrics.displayHeight)
        let frame = TokenMenuPanelPlacement.frame(
            anchorRect: anchorRect,
            panelSize: preferredSize,
            visibleFrame: visibleFrame)

        self.speedPanelController.present(frame: frame)
        self.updateFloatingChartPresentationState(isPresented: self.speedFloatingChartController.isVisible)
        self.installDismissMonitors()
    }

    private func hideMainPanel(restoreSpeedBubble: Bool = true) {
        self.panelController.hide()
        self.popoverController.hide()
        self.mainPanelMeasurementTask?.cancel()
        self.mainPanelMeasurementTask = nil
        self.mainPanelPendingMeasurementHeightCacheKey = nil
        self.removeDismissMonitors()

        if restoreSpeedBubble {
            self.updateStatusItemAppearance()
        }
    }

    private func hideSpeedPanel(restoreSpeedBubble: Bool = true) {
        self.speedPanelController.hide()
        self.removeDismissMonitors()

        if restoreSpeedBubble {
            self.updateStatusItemAppearance()
        }
    }

    private func hideVisiblePanels(restoreSpeedBubble: Bool = true) {
        self.panelController.hide()
        self.popoverController.hide()
        self.speedPanelController.hide()
        self.mainPanelMeasurementTask?.cancel()
        self.mainPanelMeasurementTask = nil
        self.mainPanelPendingMeasurementHeightCacheKey = nil
        self.removeDismissMonitors()

        if restoreSpeedBubble {
            self.updateStatusItemAppearance()
        }
    }

    private func updatePanelFrameIfNeeded() {
        if self.isMainPopupVisible, let button = self.statusItem.button {
            self.refreshVisibleMainPanelLayout(relativeTo: button)
            return
        }

        if self.speedPanelController.isVisible, let button = self.speedStatusItem?.button {
            self.showSpeedPanel(relativeTo: button)
        }
    }

    private func updateFloatingChartPresentationState(isPresented: Bool) {
        self.speedPanelController.setFloatingChartPresentation(
            isPresented: isPresented,
            onToggle: { [weak self] in
                self?.toggleFloatingChart()
            })
    }

    private func updateSpeedStatusButtonHostedView(button: NSStatusBarButton, metrics: MenuBarTokenSpeedMetrics) {
        _ = self.speedHostingView(in: button)
            ?? self.installSpeedHostingView(in: button)
        self.speedStatusItemModel.metrics = metrics
        button.image = nil
        button.imagePosition = .noImage
        button.title = ""
        button.attributedTitle = NSAttributedString(string: "")
    }

    private func installSpeedHostingView(in button: NSStatusBarButton) -> TokenPassThroughHostingView<AnyView> {
        let hostedView = TokenPassThroughHostingView(
            rootView: AnyView(TokenMenuSpeedStatusItemView(model: self.speedStatusItemModel)))
        hostedView.identifier = Self.speedButtonHostingViewIdentifier
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            hostedView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            hostedView.widthAnchor.constraint(equalToConstant: TokenMenuSpeedMeterLayout.statusItemWidth - 6),
            hostedView.heightAnchor.constraint(equalToConstant: TokenMenuSpeedMeterLayout.statusItemHeight),
        ])

        return hostedView
    }

    private func speedHostingView(in button: NSStatusBarButton) -> TokenPassThroughHostingView<AnyView>? {
        button.subviews
            .first { $0.identifier == Self.speedButtonHostingViewIdentifier } as? TokenPassThroughHostingView<
                AnyView,
            >
    }

    private func updateSpeedBubble(relativeTo button: NSStatusBarButton, metrics: MenuBarTokenSpeedMetrics) {
        guard metrics.isActive, let anchorRect = self.buttonFrameOnScreen(button) else {
            self.hideSpeedBubble(animated: true)
            return
        }

        let visibleFrame = self.visibleFrame(for: anchorRect, button: button)
        self.speedBubbleController.present(
            anchorRect: anchorRect,
            visibleFrame: visibleFrame,
            metrics: metrics)
    }

    private func hideSpeedBubble(animated: Bool) {
        self.speedBubbleController.hide(animated: animated)
    }

    private func toggleFloatingChart() {
        if self.speedFloatingChartController.isVisible {
            self.hideFloatingChart()
        } else {
            self.showFloatingChart()
        }
    }

    private func showFloatingChart() {
        let anchorFrame = self.speedPanelController.isVisible
            ? self.speedPanelController.frame
            : self.speedStatusItem?.button.flatMap(self.buttonFrameOnScreen)

        let visibleFrame = self.visibleFrame(forFloatingChartAnchor: anchorFrame)
        self.speedFloatingChartController.present(
            anchorFrame: anchorFrame,
            visibleFrame: visibleFrame)
    }

    private func hideFloatingChart() {
        self.speedFloatingChartController.hide()
    }

    private func installDismissMonitors() {
        guard self.localMouseMonitor == nil, self.globalMouseMonitor == nil else { return }

        self.localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [
            .leftMouseDown,
            .rightMouseDown,
        ]) { [weak self] event in
            guard let self else { return event }
            self.dismissPanelIfNeeded(for: self.screenPoint(for: event))
            return event
        }

        self.globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [
            .leftMouseDown,
            .rightMouseDown,
        ]) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.dismissPanelIfNeeded(for: NSEvent.mouseLocation)
            }
        }
    }

    private func removeDismissMonitors() {
        if let localMouseMonitor = self.localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }

        if let globalMouseMonitor = self.globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
    }

    private func dismissPanelIfNeeded(for screenPoint: CGPoint) {
        guard self.isMainPopupVisible || self.speedPanelController.isVisible else { return }

        if self.panelController.contains(screenPoint: screenPoint)
            || self.popoverController.contains(screenPoint: screenPoint)
            || self.speedPanelController.contains(screenPoint: screenPoint)
            || self.speedFloatingChartController.contains(screenPoint: screenPoint)
            || self
            .statusButtonContains(screenPoint: screenPoint)
        {
            return
        }

        self.hideVisiblePanels()
    }

    private func statusButtonContains(screenPoint: CGPoint) -> Bool {
        let buttons = [self.statusItem.button, self.speedStatusItem?.button].compactMap(\.self)
        for button in buttons {
            if let frame = self.buttonFrameOnScreen(button), frame.contains(screenPoint) {
                return true
            }
        }
        return false
    }

    private func screenPoint(for event: NSEvent) -> CGPoint {
        guard let window = event.window else { return NSEvent.mouseLocation }
        return window.convertPoint(toScreen: event.locationInWindow)
    }

    private func buttonFrameOnScreen(_ button: NSStatusBarButton) -> CGRect? {
        guard let window = button.window else { return nil }
        let frameInWindow = button.convert(button.bounds, to: nil)
        return window.convertToScreen(frameInWindow)
    }

    private func visibleFrame(for anchorRect: CGRect, button: NSStatusBarButton) -> CGRect {
        if let screen = button.window?.screen {
            return screen.visibleFrame
        }

        if let screen = NSScreen.screens.first(where: { $0.frame.contains(CGPoint(
            x: anchorRect.midX,
            y: anchorRect.midY)) })
        {
            return screen.visibleFrame
        }

        return NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }

    private func visibleFrame(forFloatingChartAnchor anchorFrame: CGRect?) -> CGRect {
        if let anchorFrame,
           let screen = NSScreen.screens.first(where: { $0.frame.contains(CGPoint(
               x: anchorFrame.midX,
               y: anchorFrame.midY)) })
        {
            return screen.visibleFrame
        }

        return NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }

    private func refreshVisibleMainPanelLayout(relativeTo button: NSStatusBarButton) {
        guard let anchorRect = self.buttonFrameOnScreen(button) else { return }
        guard let popupStyle = self.visibleMainPopupStyle() else { return }

        let visibleFrame = self.visibleFrame(for: anchorRect, button: button)
        let signature = MenuContent.layoutSignature(
            store: self.store,
            settings: self.settings,
            popupStyleOverride: popupStyle)
        let (panelMetrics, sizingSource) = self.cachedMainPanelSizing(
            signature: signature,
            availableScreenHeight: visibleFrame.height)
        let panelContainerContext = self.mainPopupContainerContext(for: popupStyle)

        let renderPhaseMode = TokenMenuPanelRenderPhaseResolver.renderPhaseMode(
            signature: signature,
            warmedSignature: self.warmedMainPanelSignature)
        switch popupStyle {
        case .liquidGlass:
            let preferredSize = CGSize(
                width: MenuContent.preferredPanelWidth,
                height: panelMetrics.displayHeight)
            let frame = TokenMenuPanelPlacement.frame(
                anchorRect: anchorRect,
                panelSize: preferredSize,
                visibleFrame: visibleFrame)
            self.panelController.present(
                frame: frame,
                allowsScrolling: panelMetrics.allowsScrolling,
                signature: signature,
                renderPhaseMode: renderPhaseMode)
        case .systemPopover:
            self.popoverController.present(
                relativeTo: button,
                displayHeight: panelMetrics.displayHeight,
                allowsScrolling: panelMetrics.allowsScrolling,
                signature: signature,
                renderPhaseMode: renderPhaseMode)
        }
        self.warmedMainPanelSignature = signature
        self.logger.debug(
            "Presented main panel [mode: visible-relayout, sizingSource: \(sizingSource.rawValue), structureKey: \(signature.heightCacheKey.storageKey), displayHeight: \(panelMetrics.displayHeight)]")
        self.scheduleMainPanelMeasurementIfNeeded(
            relativeTo: button,
            signature: signature,
            panelContainerContext: panelContainerContext)
    }

    private func cachedMainPanelSizing(
        signature: TokenMenuPanelLayoutSignature,
        availableScreenHeight: CGFloat)
        -> (TokenMenuPanelSizing, TokenMenuPanelSizingSource)
    {
        let naturalHeight: CGFloat
        let source: TokenMenuPanelSizingSource

        if self.mainPanelSizingCache?.heightCacheKey == signature.heightCacheKey {
            naturalHeight = self.mainPanelSizingCache?.naturalHeight ?? MenuContent.defaultNaturalHeight
            source = .memory
        } else if let persistedHeight = self.settings.storedMainPanelHeight(for: signature.heightCacheKey) {
            naturalHeight = persistedHeight
            self.mainPanelSizingCache = TokenMenuPanelSizingCache(
                heightCacheKey: signature.heightCacheKey,
                naturalHeight: persistedHeight)
            source = .persisted
        } else {
            naturalHeight = MenuContent.defaultNaturalHeight
            source = .fallback
        }

        let sizing = TokenMenuPanelSizing.resolve(
            naturalHeight: naturalHeight,
            availableScreenHeight: availableScreenHeight)
        return (sizing, source)
    }

    private func scheduleMainPanelMeasurementIfNeeded(
        relativeTo button: NSStatusBarButton,
        signature: TokenMenuPanelLayoutSignature,
        panelContainerContext: MenuContent.PanelContainerContext)
    {
        let heightCacheKey = signature.heightCacheKey
        if self.mainPanelSizingCache?.heightCacheKey == heightCacheKey {
            self.logger.debug(
                "Skipped main panel remeasure [reason: memory-hit, structureKey: \(heightCacheKey.storageKey)]")
            return
        }
        if self.settings.storedMainPanelHeight(for: heightCacheKey) != nil {
            self.logger.debug(
                "Skipped main panel remeasure [reason: persisted-hit, structureKey: \(heightCacheKey.storageKey)]")
            return
        }
        guard self.mainPanelPendingMeasurementHeightCacheKey != heightCacheKey else {
            self.logger.debug(
                "Skipped main panel remeasure [reason: already-pending, structureKey: \(heightCacheKey.storageKey)]")
            return
        }

        self.mainPanelMeasurementTask?.cancel()
        self.mainPanelPendingMeasurementHeightCacheKey = heightCacheKey
        self.logger.debug(
            "Scheduled main panel remeasure [reason: cache-miss, structureKey: \(heightCacheKey.storageKey)]")
        self.mainPanelMeasurementTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: TokenMenuPanelHotPath.measurementDelay)
            } catch {
                if self.mainPanelPendingMeasurementHeightCacheKey == heightCacheKey {
                    self.mainPanelPendingMeasurementHeightCacheKey = nil
                }
                return
            }
            guard !Task.isCancelled else {
                if self.mainPanelPendingMeasurementHeightCacheKey == heightCacheKey {
                    self.mainPanelPendingMeasurementHeightCacheKey = nil
                }
                return
            }
            guard self.isMainPopupVisible else {
                if self.mainPanelPendingMeasurementHeightCacheKey == heightCacheKey {
                    self.mainPanelPendingMeasurementHeightCacheKey = nil
                }
                return
            }

            let startedAt = Date()
            self.logger.debug("Starting main panel remeasure [structureKey: \(heightCacheKey.storageKey)]")
            let measured = MenuContent.panelMetrics(
                store: self.store,
                settings: self.settings,
                panelContainerContext: panelContainerContext,
                previewMode: false,
                availableScreenHeight: nil)
            self.mainPanelSizingCache = TokenMenuPanelSizingCache(
                heightCacheKey: heightCacheKey,
                naturalHeight: measured.naturalHeight)
            self.settings.persistMainPanelHeight(measured.naturalHeight, for: heightCacheKey)
            if self.mainPanelPendingMeasurementHeightCacheKey == heightCacheKey {
                self.mainPanelPendingMeasurementHeightCacheKey = nil
            }
            self.logger.debug(
                "Measured main panel sizing [structureKey: \(heightCacheKey.storageKey), naturalHeight: \(measured.naturalHeight), elapsedMs: \(Int(Date().timeIntervalSince(startedAt) * 1000))]")

            guard self.isMainPopupVisible,
                  let anchorRect = self.buttonFrameOnScreen(button)
            else {
                return
            }

            let visibleFrame = self.visibleFrame(for: anchorRect, button: button)
            let resolved = TokenMenuPanelSizing.resolve(
                naturalHeight: measured.naturalHeight,
                availableScreenHeight: visibleFrame.height)
            if self.panelController.isVisible {
                let preferredSize = CGSize(
                    width: MenuContent.preferredPanelWidth,
                    height: resolved.displayHeight)
                let frame = TokenMenuPanelPlacement.frame(
                    anchorRect: anchorRect,
                    panelSize: preferredSize,
                    visibleFrame: visibleFrame)

                let heightDelta = abs(self.panelController.frame.height - frame.height)
                if heightDelta > 6 || self.panelController.currentAllowsScrolling != resolved.allowsScrolling {
                    self.panelController.present(
                        frame: frame,
                        allowsScrolling: resolved.allowsScrolling,
                        signature: signature,
                        renderPhaseMode: TokenMenuPanelRenderPhaseResolver.renderPhaseMode(
                            signature: signature,
                            warmedSignature: self.warmedMainPanelSignature))
                    self.logger.debug(
                        "Applied async main panel remeasure [structureKey: \(heightCacheKey.storageKey), displayHeight: \(resolved.displayHeight), allowsScrolling: \(resolved.allowsScrolling)]")
                }
            } else if self.popoverController.isVisible {
                let heightDelta = abs(self.popoverController.displayHeight - resolved.displayHeight)
                if heightDelta > 6 || self.popoverController.currentAllowsScrolling != resolved.allowsScrolling {
                    self.popoverController.present(
                        relativeTo: button,
                        displayHeight: resolved.displayHeight,
                        allowsScrolling: resolved.allowsScrolling,
                        signature: signature,
                        renderPhaseMode: TokenMenuPanelRenderPhaseResolver.renderPhaseMode(
                            signature: signature,
                            warmedSignature: self.warmedMainPanelSignature))
                    self.logger.debug(
                        "Applied async main popover remeasure [structureKey: \(heightCacheKey.storageKey), displayHeight: \(resolved.displayHeight), allowsScrolling: \(resolved.allowsScrolling)]")
                }
            }
        }
    }
}

@MainActor
@Observable
private final class TokenMenuMainPresentationModel {
    var displayHeight: CGFloat
    var allowsScrolling: Bool
    var layoutSignature: TokenMenuPanelLayoutSignature?
    var renderPhaseMode: MenuContent.TokenMenuPanelRenderPhaseMode

    init(
        displayHeight: CGFloat,
        allowsScrolling: Bool,
        layoutSignature: TokenMenuPanelLayoutSignature? = nil,
        renderPhaseMode: MenuContent.TokenMenuPanelRenderPhaseMode = .warmed)
    {
        self.displayHeight = displayHeight
        self.allowsScrolling = allowsScrolling
        self.layoutSignature = layoutSignature
        self.renderPhaseMode = renderPhaseMode
    }
}

@MainActor
private struct TokenMenuMainRootView: View {
    @Bindable var store: UsageStore
    @Bindable var settings: SettingsStore
    @Bindable var presentationModel: TokenMenuMainPresentationModel
    let panelContainerContext: MenuContent.PanelContainerContext

    var body: some View {
        MenuContent(
            store: self.store,
            settings: self.settings,
            panelContainerContext: self.panelContainerContext,
            layoutMode: .display(
                height: self.presentationModel.displayHeight,
                allowsScrolling: self.presentationModel.allowsScrolling),
            renderPhaseMode: self.presentationModel.renderPhaseMode)
    }
}

@MainActor
private final class TokenMenuPanelController: NSObject {
    private let settings: SettingsStore
    private let store: UsageStore
    private let panel: TokenMenuPanel
    private let presentationModel: TokenMenuMainPresentationModel
    private let hostingController: NSHostingController<TokenMenuMainRootView>
    private var deferredActivationTask: Task<Void, Never>?
    private let logger = Logger(label: "CodexBar.token-menu-panel")
    var onRequestClose: (() -> Void)?
    private(set) var currentAllowsScrolling = false

    init(settings: SettingsStore, store: UsageStore) {
        self.settings = settings
        self.store = store
        let initialFrame = CGRect(
            x: 0,
            y: 0,
            width: MenuContent.preferredPanelWidth,
            height: MenuContent.defaultNaturalHeight)
        self.presentationModel = TokenMenuMainPresentationModel(
            displayHeight: initialFrame.height,
            allowsScrolling: false)
        self.panel = TokenMenuPanel(
            contentRect: initialFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        self.hostingController = NSHostingController(
            rootView: TokenMenuMainRootView(
                store: store,
                settings: settings,
                presentationModel: self.presentationModel,
                panelContainerContext: .anchoredPanel))
        super.init()
        self.configurePanel()
    }

    var isVisible: Bool {
        self.panel.isVisible
    }

    var frame: CGRect {
        self.panel.frame
    }

    func present(
        frame: CGRect,
        allowsScrolling: Bool,
        signature: TokenMenuPanelLayoutSignature,
        renderPhaseMode: MenuContent.TokenMenuPanelRenderPhaseMode)
    {
        self.currentAllowsScrolling = allowsScrolling
        self.presentationModel.displayHeight = frame.height
        self.presentationModel.allowsScrolling = allowsScrolling
        self.presentationModel.layoutSignature = signature
        self.presentationModel.renderPhaseMode = renderPhaseMode
        self.panel.setFrame(frame, display: false)
        self.panel.orderFrontRegardless()
        self.logger.debug("Main panel first visible")
        self.deferredActivationTask?.cancel()
        self.deferredActivationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await Task.yield()
            guard !Task.isCancelled else { return }
            self.logger.debug("Main panel deferred activate")
            NSApp.activate(ignoringOtherApps: true)
            self.panel.makeKey()
        }
    }

    func hide() {
        self.deferredActivationTask?.cancel()
        self.deferredActivationTask = nil
        self.panel.orderOut(nil)
    }

    func contains(screenPoint: CGPoint) -> Bool {
        self.panel.frame.contains(screenPoint)
    }

    private func configurePanel() {
        self.panel.isReleasedWhenClosed = false
        self.panel.isOpaque = false
        self.panel.hasShadow = false
        self.panel.backgroundColor = .clear
        self.panel.level = .statusBar
        self.panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient]
        self.panel.hidesOnDeactivate = false
        self.panel.animationBehavior = TokenMenuPopupAnimationPolicy.liquidGlassAnimationBehavior
        self.panel.isMovableByWindowBackground = false
        self.panel.onEscape = { [weak self] in
            self?.onRequestClose?()
        }
        self.panel.contentViewController = self.hostingController
        self.hostingController.view.wantsLayer = true
        self.hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
    }
}

@MainActor
private final class TokenMenuPopoverController: NSObject {
    private let settings: SettingsStore
    private let store: UsageStore
    private let popover: NSPopover
    private let presentationModel: TokenMenuMainPresentationModel
    private let hostingController: NSHostingController<TokenMenuMainRootView>
    private(set) var currentAllowsScrolling = false

    init(settings: SettingsStore, store: UsageStore) {
        self.settings = settings
        self.store = store
        self.popover = NSPopover()
        self.presentationModel = TokenMenuMainPresentationModel(
            displayHeight: MenuContent.defaultNaturalHeight,
            allowsScrolling: false)
        self.hostingController = NSHostingController(
            rootView: TokenMenuMainRootView(
                store: store,
                settings: settings,
                presentationModel: self.presentationModel,
                panelContainerContext: .anchoredSystemPopover))
        super.init()
        self.configurePopover()
    }

    var isVisible: Bool {
        self.popover.isShown
    }

    var displayHeight: CGFloat {
        self.presentationModel.displayHeight
    }

    func present(
        relativeTo button: NSStatusBarButton,
        displayHeight: CGFloat,
        allowsScrolling: Bool,
        signature: TokenMenuPanelLayoutSignature,
        renderPhaseMode: MenuContent.TokenMenuPanelRenderPhaseMode)
    {
        self.currentAllowsScrolling = allowsScrolling
        self.presentationModel.displayHeight = displayHeight
        self.presentationModel.allowsScrolling = allowsScrolling
        self.presentationModel.layoutSignature = signature
        self.presentationModel.renderPhaseMode = renderPhaseMode
        self.popover.contentSize = CGSize(width: MenuContent.preferredPanelWidth, height: displayHeight)

        guard !self.popover.isShown else { return }
        self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func hide() {
        guard self.popover.isShown else { return }
        self.popover.performClose(nil)
    }

    func contains(screenPoint: CGPoint) -> Bool {
        self.hostingController.view.window?.frame.contains(screenPoint) ?? false
    }

    private func configurePopover() {
        self.popover.behavior = .transient
        self.popover.animates = TokenMenuPopupAnimationPolicy.systemPopoverAnimates
        self.popover.contentViewController = self.hostingController
        self.hostingController.view.wantsLayer = true
        self.hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
    }
}

@MainActor
private final class TokenSpeedPanelController: NSObject {
    private let settings: SettingsStore
    private let store: UsageStore
    private let panel: TokenMenuPanel
    private let hostingController: NSHostingController<TokenSpeedPanelContent>
    private var isFloatingChartPresented = false
    private var onToggleFloatingChart: () -> Void = {}
    var onRequestClose: (() -> Void)?

    init(settings: SettingsStore, store: UsageStore) {
        self.settings = settings
        self.store = store
        let panelMetrics = TokenSpeedPanelContent.panelMetrics(availableScreenHeight: nil)
        let initialFrame = CGRect(
            x: 0,
            y: 0,
            width: TokenSpeedPanelContent.preferredPanelWidth,
            height: panelMetrics.displayHeight)
        self.panel = TokenMenuPanel(
            contentRect: initialFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        self.hostingController = NSHostingController(
            rootView: TokenSpeedPanelContent(
                store: store,
                settings: settings,
                panelHeight: initialFrame.height,
                isFloatingChartPresented: false,
                onToggleFloatingChart: {}))
        super.init()
        self.configurePanel()
    }

    var isVisible: Bool {
        self.panel.isVisible
    }

    var frame: CGRect {
        self.panel.frame
    }

    func present(frame: CGRect) {
        self.updateRootView(panelHeight: frame.height)
        self.panel.setFrame(frame, display: false)
        NSApp.activate(ignoringOtherApps: true)
        self.panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        self.panel.orderOut(nil)
    }

    func contains(screenPoint: CGPoint) -> Bool {
        self.panel.frame.contains(screenPoint)
    }

    func setFloatingChartPresentation(
        isPresented: Bool,
        onToggle: @escaping () -> Void)
    {
        self.isFloatingChartPresented = isPresented
        self.onToggleFloatingChart = onToggle
        self.updateRootView(panelHeight: self.panel.frame.height)
    }

    private func updateRootView(panelHeight: CGFloat) {
        self.hostingController.rootView = TokenSpeedPanelContent(
            store: self.store,
            settings: self.settings,
            panelHeight: panelHeight,
            isFloatingChartPresented: self.isFloatingChartPresented,
            onToggleFloatingChart: self.onToggleFloatingChart)
    }

    private func configurePanel() {
        self.panel.isReleasedWhenClosed = false
        self.panel.isOpaque = false
        self.panel.hasShadow = false
        self.panel.backgroundColor = .clear
        self.panel.level = .statusBar
        self.panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient]
        self.panel.hidesOnDeactivate = false
        self.panel.animationBehavior = TokenMenuPopupAnimationPolicy.liquidGlassAnimationBehavior
        self.panel.isMovableByWindowBackground = false
        self.panel.onEscape = { [weak self] in
            self?.onRequestClose?()
        }
        self.panel.contentViewController = self.hostingController
        self.hostingController.view.wantsLayer = true
        self.hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
    }
}

@MainActor
private final class TokenSpeedFloatingChartController: NSObject {
    private let settings: SettingsStore
    private let store: UsageStore
    private let stateStore: TokenSpeedFloatingChartStateStore
    private let panel: TokenSpeedFloatingChartPanel
    private let hostingController: NSHostingController<TokenSpeedFloatingChartContent>
    private var moveObserver: NSObjectProtocol?
    var onVisibilityChange: ((Bool) -> Void)?

    init(
        settings: SettingsStore,
        store: UsageStore,
        stateStore: TokenSpeedFloatingChartStateStore)
    {
        self.settings = settings
        self.store = store
        self.stateStore = stateStore
        let panelSize = TokenSpeedFloatingChartLayout.size
        let initialFrame = CGRect(
            x: 0,
            y: 0,
            width: panelSize.width,
            height: panelSize.height)
        self.panel = TokenSpeedFloatingChartPanel(
            contentRect: initialFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false)
        self.hostingController = NSHostingController(
            rootView: TokenSpeedFloatingChartContent(
                store: store,
                settings: settings))
        super.init()
        self.configurePanel()
        self.registerMoveObserver()
    }

    var isVisible: Bool {
        self.panel.isVisible
    }

    func present(anchorFrame: CGRect?, visibleFrame: CGRect) {
        let panelSize = TokenSpeedFloatingChartLayout.size
        let frame: CGRect = if let storedOrigin = self.stateStore.loadOrigin() {
            TokenSpeedFloatingChartPlacement.clampedFrame(
                origin: storedOrigin,
                panelSize: panelSize,
                visibleFrame: visibleFrame)
        } else if let anchorFrame {
            TokenSpeedFloatingChartPlacement.defaultFrame(
                anchorFrame: anchorFrame,
                panelSize: panelSize,
                visibleFrame: visibleFrame)
        } else {
            TokenSpeedFloatingChartPlacement.clampedFrame(
                origin: visibleFrame.origin,
                panelSize: panelSize,
                visibleFrame: visibleFrame)
        }

        self.hostingController.rootView = TokenSpeedFloatingChartContent(
            store: self.store,
            settings: self.settings)
        self.panel.setFrame(frame, display: false)
        self.panel.orderFrontRegardless()
        self.stateStore.saveOrigin(frame.origin)
        self.onVisibilityChange?(true)
    }

    func hide() {
        guard self.panel.isVisible else { return }
        self.panel.orderOut(nil)
        self.onVisibilityChange?(false)
    }

    func contains(screenPoint: CGPoint) -> Bool {
        self.panel.frame.contains(screenPoint)
    }

    func reclampToVisibleScreenIfNeeded() {
        guard self.panel.isVisible else { return }
        let visibleFrame = self.panel.screen?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let panelSize = TokenSpeedFloatingChartLayout.size
        let frame = TokenSpeedFloatingChartPlacement.clampedFrame(
            origin: self.panel.frame.origin,
            panelSize: panelSize,
            visibleFrame: visibleFrame)
        self.panel.setFrame(frame, display: false)
        self.stateStore.saveOrigin(frame.origin)
    }

    private func configurePanel() {
        self.panel.isReleasedWhenClosed = false
        self.panel.isOpaque = false
        self.panel.hasShadow = false
        self.panel.backgroundColor = .clear
        self.panel.level = .floating
        self.panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        self.panel.hidesOnDeactivate = false
        self.panel.animationBehavior = TokenMenuPopupAnimationPolicy.liquidGlassAnimationBehavior
        self.panel.isMovableByWindowBackground = true
        self.panel.isExcludedFromWindowsMenu = true
        self.panel.contentViewController = self.hostingController
        self.hostingController.view.wantsLayer = true
        self.hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
    }

    private func registerMoveObserver() {
        self.moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: self.panel,
            queue: .main)
        { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.stateStore.saveOrigin(self.panel.frame.origin)
            }
        }
    }
}

private final class TokenSpeedFloatingChartPanel: NSPanel {
    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}

@MainActor
private final class TokenMenuPanel: NSPanel {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            self.onEscape?()
            return
        }

        super.keyDown(with: event)
    }
}
