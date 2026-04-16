import AppKit
import SwiftUI

@MainActor
enum TokenSettingsWindowCoordinator {
    private weak static var cachedWindow: NSWindow?
    private static var windowFactory: (() -> NSWindow)?

    static func configure(windowFactory: @escaping () -> NSWindow) {
        self.windowFactory = windowFactory
    }

    static func requestOpenSettings() {
        let window = self.resolveWindow()
        self.present(window)
    }

    @discardableResult
    static func raiseAndCenterSettingsWindow(
        windows: [NSWindow] = NSApp.windows,
        mouseLocation: NSPoint = NSEvent.mouseLocation,
        screens: [NSScreen] = NSScreen.screens) -> Bool
    {
        guard let window = self.settingsWindow(from: windows) else { return false }
        self.present(window, mouseLocation: mouseLocation, screens: screens)
        return true
    }

    static func settingsWindow(from windows: [NSWindow]) -> NSWindow? {
        let candidates = windows.filter(self.isSettingsWindowCandidate)
        if let keyWindow = candidates.first(where: { $0.isKeyWindow }) {
            return keyWindow
        }
        if let mainWindow = candidates.first(where: { $0.isMainWindow }) {
            return mainWindow
        }
        return candidates.first
    }

    static func isSettingsWindowCandidate(_ window: NSWindow) -> Bool {
        guard window.identifier?.rawValue == self.windowIdentifier else { return false }
        guard window.alphaValue > 0.01 else { return false }
        guard window.frame.width > 120, window.frame.height > 120 else { return false }
        return true
    }

    static func screenContaining(point: NSPoint, screens: [NSScreen]) -> NSScreen? {
        screens.first { $0.frame.contains(point) }
    }

    static func centeredFrame(for windowFrame: CGRect, in visibleFrame: CGRect) -> CGRect {
        let x: CGFloat
        if windowFrame.width >= visibleFrame.width {
            x = visibleFrame.minX
        } else {
            let centered = visibleFrame.midX - (windowFrame.width / 2)
            x = min(max(centered, visibleFrame.minX), visibleFrame.maxX - windowFrame.width)
        }

        let y: CGFloat
        if windowFrame.height >= visibleFrame.height {
            y = visibleFrame.minY
        } else {
            let centered = visibleFrame.midY - (windowFrame.height / 2)
            y = min(max(centered, visibleFrame.minY), visibleFrame.maxY - windowFrame.height)
        }

        return CGRect(origin: CGPoint(x: x.rounded(), y: y.rounded()), size: windowFrame.size)
    }

    static func resetForTesting() {
        self.cachedWindow = nil
        self.windowFactory = nil
    }

    static func registerWindowForTesting(_ window: NSWindow) {
        self.cachedWindow = window
    }

    private static var windowIdentifier: String {
        "TokenSettingsWindow"
    }

    private static func resolveWindow() -> NSWindow {
        if let existingWindow = self.cachedWindow, existingWindow.isReleasedWhenClosed == false {
            return existingWindow
        }

        if let liveWindow = self.settingsWindow(from: NSApp.windows) {
            self.cachedWindow = liveWindow
            return liveWindow
        }

        guard let windowFactory = self.windowFactory else {
            fatalError("TokenSettingsWindowCoordinator windowFactory is not configured")
        }

        let window = windowFactory()
        window.identifier = NSUserInterfaceItemIdentifier(self.windowIdentifier)
        window.isReleasedWhenClosed = false
        window.delegate = SettingsWindowLifecycleDelegate.shared
        self.cachedWindow = window
        return window
    }

    private static func present(
        _ window: NSWindow,
        mouseLocation: NSPoint = NSEvent.mouseLocation,
        screens: [NSScreen] = NSScreen.screens)
    {
        if let screen =
            self.screenContaining(point: mouseLocation, screens: screens)
            ?? NSScreen.main
            ?? screens.first
        {
            window.setFrame(self.centeredFrame(for: window.frame, in: screen.visibleFrame), display: true)
        }

        var collectionBehavior = window.collectionBehavior
        collectionBehavior.insert(.moveToActiveSpace)
        window.collectionBehavior = collectionBehavior

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    @MainActor
    private final class SettingsWindowLifecycleDelegate: NSObject, NSWindowDelegate {
        static let shared = SettingsWindowLifecycleDelegate()

        func windowWillClose(_ notification: Notification) {
            guard let window = notification.object as? NSWindow else { return }
            if TokenSettingsWindowCoordinator.cachedWindow === window {
                TokenSettingsWindowCoordinator.cachedWindow = nil
            }
        }
    }
}
