import AppKit
import SwiftUI

enum TokenMenuSpeedBubblePlacement {
    static let screenInset: CGFloat = 8

    static func frame(anchorRect: CGRect, bubbleSize: CGSize, visibleFrame: CGRect) -> CGRect {
        let minX = visibleFrame.minX + Self.screenInset
        let maxX = visibleFrame.maxX - bubbleSize.width - Self.screenInset
        let overlap = TokenMenuSpeedMeterLayout.bubbleAttachmentOverlap
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
    private var hideTask: Task<Void, Never>?

    init() {
        self.hostingController = NSHostingController(rootView: TokenMenuSpeedBubbleView(model: self.model))
        self.panel = TokenMenuSpeedBubblePanel(
            contentRect: CGRect(x: 0, y: 0, width: 96, height: 48),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        self.configurePanel()
    }

    func present(anchorRect: CGRect, visibleFrame: CGRect, metrics: MenuBarTokenSpeedMetrics) {
        guard metrics.isActive else {
            self.hide(animated: true)
            return
        }

        self.hideTask?.cancel()
        self.model.metrics = metrics
        let targetSize = self.fittingSize(for: metrics)
        let frame = TokenMenuSpeedBubblePlacement.frame(
            anchorRect: anchorRect,
            bubbleSize: targetSize,
            visibleFrame: visibleFrame)
        let wasVisible = self.panel.isVisible

        self.panel.setFrame(frame, display: false)
        self.panel.orderFrontRegardless()

        if wasVisible {
            self.model.isPresented = true
        } else {
            self.model.isPresented = false
            Task { @MainActor [weak self] in
                self?.model.isPresented = true
            }
        }
    }

    func hide(animated: Bool) {
        self.hideTask?.cancel()

        guard animated else {
            self.model.isPresented = false
            self.panel.orderOut(nil)
            return
        }

        self.model.isPresented = false
        self.hideTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(240))
            } catch {
                return
            }

            await MainActor.run {
                guard let self else { return }
                if !self.model.isPresented {
                    self.panel.orderOut(nil)
                }
            }
        }
    }

    private func fittingSize(for metrics: MenuBarTokenSpeedMetrics) -> CGSize {
        self.model.metrics = metrics
        self.hostingController.view.layoutSubtreeIfNeeded()
        let size = self.hostingController.sizeThatFits(in: NSSize(width: 180, height: 80))
        return CGSize(width: max(size.width, TokenMenuSpeedMeterLayout.bubbleMinimumWidth), height: size.height)
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
