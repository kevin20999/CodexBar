import XCTest
@testable import CodexBarCore

final class BrowserCookieAccessGateTests: XCTestCase {
    override func tearDown() {
        BrowserCookieAccessGate.resetForTesting()
        super.tearDown()
    }

    func test_chromeKeychainInteractionDoesNotBlockAtlas() {
        let shouldAttemptAtlas = KeychainAccessPreflight.withCheckGenericPasswordOverrideForTesting(
            self.stubOutcome)
        {
            BrowserCookieAccessGate.shouldAttempt(.chatgptAtlas, now: Date(timeIntervalSince1970: 1))
        }

        XCTAssertTrue(shouldAttemptAtlas)
    }

    func test_browserIsBlockedWhenItsOwnSafeStorageNeedsInteraction() {
        let shouldAttemptChrome = KeychainAccessPreflight.withCheckGenericPasswordOverrideForTesting(
            self.stubOutcome)
        {
            BrowserCookieAccessGate.shouldAttempt(.chrome, now: Date(timeIntervalSince1970: 1))
        }

        XCTAssertFalse(shouldAttemptChrome)
    }

    private func stubOutcome(service: String, account _: String?) -> KeychainAccessPreflight.Outcome {
        if service.contains("ChatGPT Atlas") || service.contains("com.openai.atlas") {
            return .allowed
        }
        if service.contains("Chrome Safe Storage") {
            return .interactionRequired
        }
        return .notFound
    }
}
