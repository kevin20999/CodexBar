import AppKit
import XCTest
@testable import CodexBar

@MainActor
final class TokenSettingsWindowCoordinatorTests: XCTestCase {
    override func tearDown() {
        TokenSettingsWindowCoordinator.resetForTesting()
        super.tearDown()
    }

    func test_settingsWindowSkipsNonTaggedWindows() {
        let untitled = self.makeWindow(
            title: "",
            styleMask: [.titled, .closable],
            frame: NSRect(x: 0, y: 0, width: 320, height: 240))

        let settings = self.makeWindow(
            title: "Settings",
            styleMask: [.titled, .closable, .miniaturizable],
            frame: NSRect(x: 120, y: 90, width: 560, height: 720))
        settings.identifier = NSUserInterfaceItemIdentifier("TokenSettingsWindow")

        let resolved = TokenSettingsWindowCoordinator.settingsWindow(from: [untitled, settings])

        XCTAssertTrue(resolved === settings)
    }

    func test_centeredFrameStaysInsideVisibleFrame() {
        let windowFrame = CGRect(x: 0, y: 0, width: 560, height: 720)
        let visibleFrame = CGRect(x: 1440, y: 25, width: 1280, height: 775)

        let centered = TokenSettingsWindowCoordinator.centeredFrame(for: windowFrame, in: visibleFrame)

        XCTAssertEqual(centered.origin.x, 1800)
        XCTAssertEqual(centered.origin.y, 53)
        XCTAssertGreaterThanOrEqual(centered.minX, visibleFrame.minX)
        XCTAssertGreaterThanOrEqual(centered.minY, visibleFrame.minY)
        XCTAssertLessThanOrEqual(centered.maxX, visibleFrame.maxX)
        XCTAssertLessThanOrEqual(centered.maxY, visibleFrame.maxY)
    }

    func test_requestOpenSettingsCreatesWindowViaFactory() {
        var createdWindowCount = 0
        let window = self.makeWindow(
            title: "Settings",
            styleMask: [.titled, .closable, .miniaturizable],
            frame: NSRect(x: 120, y: 90, width: 560, height: 720))

        TokenSettingsWindowCoordinator.configure {
            createdWindowCount += 1
            return window
        }

        TokenSettingsWindowCoordinator.requestOpenSettings()

        XCTAssertEqual(createdWindowCount, 1)
        XCTAssertEqual(window.identifier?.rawValue, "TokenSettingsWindow")
    }

    func test_requestOpenSettingsReusesExistingWindow() {
        var createdWindowCount = 0
        let existingWindow = self.makeWindow(
            title: "Settings",
            styleMask: [.titled, .closable, .miniaturizable],
            frame: NSRect(x: 120, y: 90, width: 560, height: 720))
        existingWindow.identifier = NSUserInterfaceItemIdentifier("TokenSettingsWindow")

        TokenSettingsWindowCoordinator.registerWindowForTesting(existingWindow)
        TokenSettingsWindowCoordinator.configure {
            createdWindowCount += 1
            return self.makeWindow(
                title: "Settings",
                styleMask: [.titled, .closable, .miniaturizable],
                frame: NSRect(x: 80, y: 80, width: 520, height: 680))
        }

        TokenSettingsWindowCoordinator.requestOpenSettings()

        XCTAssertEqual(createdWindowCount, 0)
    }

    private func makeWindow(title: String, styleMask: NSWindow.StyleMask, frame: NSRect) -> NSWindow {
        let window = NSWindow(
            contentRect: frame,
            styleMask: styleMask,
            backing: .buffered,
            defer: false)
        window.title = title
        return window
    }
}
