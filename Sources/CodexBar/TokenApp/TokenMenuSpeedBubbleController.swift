import AppKit
import SwiftUI

enum TokenMenuSpeedBubblePlacement {
    static let screenInset: CGFloat = 8

    static func frame(
        anchorRect: CGRect,
        bubbleSize: CGSize,
        visibleFrame: CGRect,
        presentation: TokenMenuSpeedPresentationState)
        -> CGRect
    {
        let minX = visibleFrame.minX + Self.screenInset
        let maxX = visibleFrame.maxX - bubbleSize.width - Self.screenInset
        let overlap = TokenMenuSpeedBubbleLayout.overlap(for: presentation)
        let originX = min(max(anchorRect.midX - (bubbleSize.width / 2), minX), maxX)
        let originY = anchorRect.minY + overlap - bubbleSize.height

        return CGRect(
            x: originX.rounded(.toNearestOrAwayFromZero),
            y: originY.rounded(.toNearestOrAwayFromZero),
            width: bubbleSize.width.rounded(.up),
            height: bubbleSize.height.rounded(.up))
    }
}

@MainActor
final class TokenMenuSpeedBubbleController {
    private let model = TokenMenuSpeedBubbleModel()
    private let panel: TokenMenuSpeedBubblePanel
    private let hostingController: NSHostingController<TokenMenuSpeedBubbleView>

    init() {
        self.hostingController = NSHostingController(rootView: TokenMenuSpeedBubbleView(model: self.model))
        self.panel = TokenMenuSpeedBubblePanel(
            contentRect: CGRect(x: 0, y: 0, width: 96, height: 48),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        self.configurePanel()
    }

    func update(
        anchorRect: CGRect,
        visibleFrame: CGRect,
        presentation: TokenMenuSpeedPresentationState)
    {
        guard presentation.keepsBubbleMounted else {
            self.hideNow()
            return
        }

        let targetSize = self.fittingSize(for: presentation)
        let frame = TokenMenuSpeedBubblePlacement.frame(
            anchorRect: anchorRect,
            bubbleSize: targetSize,
            visibleFrame: visibleFrame,
            presentation: presentation)
        let wasVisible = self.panel.isVisible

        self.model.presentation = presentation

        if !wasVisible, !presentation.bubblePresented {
            self.model.isPresented = false
            self.panel.orderOut(nil)
            return
        }

        if wasVisible {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = TokenMenuSpeedBubbleAnimation.panelAnimationDuration(for: presentation)
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.panel.animator().setFrame(frame, display: false)
            }
        } else {
            self.panel.setFrame(frame, display: false)
            self.panel.orderFrontRegardless()
        }

        if wasVisible {
            self.model.isPresented = presentation.bubblePresented
        } else {
            self.model.isPresented = false
            Task { @MainActor [weak self] in
                self?.model.isPresented = presentation.bubblePresented
            }
        }
    }

    func hide() {
        self.model.isPresented = false
    }

    func hideNow() {
        self.model.presentation = .idle
        self.model.isPresented = false
        self.panel.orderOut(nil)
    }

    private func fittingSize(for presentation: TokenMenuSpeedPresentationState) -> CGSize {
        TokenMenuSpeedBubbleLayout.size(for: presentation)
    }

    private func configurePanel() {
        self.panel.isReleasedWhenClosed = false
        self.panel.isOpaque = false
        self.panel.hasShadow = false
        self.panel.backgroundColor = .clear
        self.panel.level = .statusBar
        self.panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .transient]
        self.panel.hidesOnDeactivate = false
        self.panel.animationBehavior = .none
        self.panel.ignoresMouseEvents = true
        self.panel.contentViewController = self.hostingController
        self.hostingController.view.wantsLayer = true
        self.hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
    }
}

private final class TokenMenuSpeedBubblePanel: NSPanel {
    override var canBecomeKey: Bool {
        false
    }

    override var canBecomeMain: Bool {
        false
    }
}
