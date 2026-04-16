import AppKit
import SwiftUI

@main
struct CodexBarApp: App {
    @NSApplicationDelegateAdaptor(TokenAppDelegate.self) private var appDelegate
    @State private var settings: SettingsStore
    @State private var store: UsageStore

    init() {
        let settings = SettingsStore()
        let store = UsageStore(settings: settings)
        _settings = State(wrappedValue: settings)
        _store = State(wrappedValue: store)
        self.appDelegate.configure(settings: settings, store: store)
        TokenSettingsWindowCoordinator.configure {
            let controller = NSHostingController(
                rootView: PreferencesView(settings: settings, store: store))
            let window = NSWindow(contentViewController: controller)
            window.title = settings.strings.settings
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 1180, height: 900))
            window.minSize = NSSize(width: 1100, height: 820)
            window.toolbarStyle = .preference
            window.isReleasedWhenClosed = false
            return window
        }
    }

    @SceneBuilder
    var body: some Scene {
        WindowGroup("TokenAppLifecycleKeepalive") {
            TokenHiddenWindowView()
        }
        .defaultSize(width: 20, height: 20)
        .windowStyle(.hiddenTitleBar)
    }
}
