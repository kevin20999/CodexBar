#if os(macOS)
import AppKit
import SweetCookieKit

enum DefaultBrowserResolver {
    static func currentDefaultBrowser() -> Browser? {
        self.browser(forBundleIdentifier: self.currentDefaultBrowserBundleIdentifier())
    }

    static func prioritizedCookieImportOrder(_ browsers: [Browser]) -> [Browser] {
        self.prioritizedCookieImportOrder(
            browsers,
            preferredBrowser: self.currentDefaultBrowser())
    }

    static func prioritizedCookieImportOrder(_ browsers: [Browser], preferredBrowser: Browser?) -> [Browser] {
        guard let preferred = preferredBrowser,
              let index = browsers.firstIndex(of: preferred)
        else {
            return browsers
        }

        var reordered = browsers
        reordered.remove(at: index)
        reordered.insert(preferred, at: 0)
        return reordered
    }

    static func browser(forBundleIdentifier bundleIdentifier: String?) -> Browser? {
        guard let normalized = bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !normalized.isEmpty
        else {
            return nil
        }

        if let browser = self.exactBundleIdentifierMap[normalized] {
            return browser
        }
        return self.patternRules.first { rule in
            rule.requiredSubstrings.allSatisfy(normalized.contains)
        }?.browser
    }

    private static func currentDefaultBrowserBundleIdentifier() -> String? {
        guard let url = URL(string: "https://chatgpt.com"),
              let appURL = NSWorkspace.shared.urlForApplication(toOpen: url),
              let bundleIdentifier = Bundle(url: appURL)?.bundleIdentifier
        else {
            return nil
        }
        return bundleIdentifier
    }

    private static let exactBundleIdentifierMap: [String: Browser] = [
        "com.apple.safari": .safari,
        "com.google.chrome": .chrome,
        "com.google.chrome.beta": .chromeBeta,
        "com.google.chrome.canary": .chromeCanary,
        "company.thebrowser.browser": .arc,
        "company.thebrowser.beta": .arcBeta,
        "company.thebrowser.canary": .arcCanary,
        "com.openai.atlas": .chatgptAtlas,
        "org.chromium.chromium": .chromium,
        "org.mozilla.firefox": .firefox,
        "app.zen-browser.zen": .zen,
        "com.brave.browser": .brave,
        "com.brave.browser.beta": .braveBeta,
        "com.brave.browser.nightly": .braveNightly,
        "com.microsoft.edgemac": .edge,
        "com.microsoft.edgemac.beta": .edgeBeta,
        "com.microsoft.edgemac.canary": .edgeCanary,
        "net.imput.helium": .helium,
        "com.vivaldi.vivaldi": .vivaldi,
        "app.dia.desktop": .dia,
    ]

    private static let patternRules: [(browser: Browser, requiredSubstrings: [String])] = [
        (.chatgptAtlas, ["openai.atlas"]),
        (.chatgptAtlas, [".atlas"]),
        (.safari, ["safari"]),
        (.chromeCanary, ["chrome.canary"]),
        (.chromeBeta, ["chrome.beta"]),
        (.chrome, ["chrome"]),
        (.arcCanary, ["arc.canary"]),
        (.arcBeta, ["arc.beta"]),
        (.arc, ["thebrowser"]),
        (.arc, [".arc"]),
        (.braveNightly, ["brave", "nightly"]),
        (.braveBeta, ["brave", "beta"]),
        (.brave, ["brave"]),
        (.edgeCanary, ["edge", "canary"]),
        (.edgeBeta, ["edge", "beta"]),
        (.edge, ["edge"]),
        (.firefox, ["firefox"]),
        (.zen, ["zen"]),
        (.chromium, ["chromium"]),
        (.vivaldi, ["vivaldi"]),
        (.helium, ["helium"]),
        (.dia, ["dia"]),
    ]
}
#else
enum DefaultBrowserResolver {
    static func currentDefaultBrowser() -> Browser? {
        nil
    }

    static func prioritizedCookieImportOrder(_ browsers: [Browser]) -> [Browser] {
        browsers
    }

    static func browser(forBundleIdentifier _: String?) -> Browser? {
        nil
    }
}
#endif
