import AppKit
import SwiftUI

@MainActor
final class TokenAppDelegate: NSObject, NSApplicationDelegate {
    private var didFinishLaunching = false
    private var menuBarController: TokenMenuBarController?
    private weak var settings: SettingsStore?
    private weak var store: UsageStore?

    func configure(settings: SettingsStore, store: UsageStore) {
        self.settings = settings
        self.store = store
        self.startMenuBarControllerIfPossible()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        self.didFinishLaunching = true
        self.startMenuBarControllerIfPossible()
    }

    private func startMenuBarControllerIfPossible() {
        guard self.didFinishLaunching,
              self.menuBarController == nil,
              let settings = self.settings,
              let store = self.store
        else {
            return
        }

        let controller = TokenMenuBarController(settings: settings, store: store)
        controller.start()
        self.menuBarController = controller
    }
}
