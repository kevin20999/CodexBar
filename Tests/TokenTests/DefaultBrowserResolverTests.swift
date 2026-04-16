import XCTest
@testable import CodexBarCore

final class DefaultBrowserResolverTests: XCTestCase {
    func test_browserForBundleIdentifierRecognizesAtlas() {
        XCTAssertEqual(DefaultBrowserResolver.browser(forBundleIdentifier: "com.openai.atlas"), .chatgptAtlas)
    }

    func test_browserForBundleIdentifierRecognizesChromeFamily() {
        XCTAssertEqual(DefaultBrowserResolver.browser(forBundleIdentifier: "com.google.Chrome"), .chrome)
        XCTAssertEqual(DefaultBrowserResolver.browser(forBundleIdentifier: "com.google.Chrome.beta"), .chromeBeta)
        XCTAssertEqual(DefaultBrowserResolver.browser(forBundleIdentifier: "com.google.Chrome.canary"), .chromeCanary)
    }

    func test_prioritizedCookieImportOrderMovesDefaultBrowserToFront() {
        let ordered = DefaultBrowserResolver.prioritizedCookieImportOrder(
            [.safari, .chrome, .chatgptAtlas, .firefox],
            preferredBrowser: .chatgptAtlas)

        XCTAssertEqual(ordered, [.chatgptAtlas, .safari, .chrome, .firefox])
    }

    func test_prioritizedCookieImportOrderKeepsOriginalOrderWhenPreferredBrowserMissing() throws {
        let safari = try XCTUnwrap(DefaultBrowserResolver.browser(forBundleIdentifier: "com.apple.safari"))
        let chrome = try XCTUnwrap(DefaultBrowserResolver.browser(forBundleIdentifier: "com.google.chrome"))
        let firefox = try XCTUnwrap(DefaultBrowserResolver.browser(forBundleIdentifier: "org.mozilla.firefox"))
        let original = [safari, chrome, firefox]
        let ordered = DefaultBrowserResolver.prioritizedCookieImportOrder(
            original,
            preferredBrowser: .chatgptAtlas)

        XCTAssertEqual(ordered, original)
    }
}
