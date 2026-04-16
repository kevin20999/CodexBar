import AppKit
import Foundation

enum TokenSystemSettingsLinks {
    static func openFullDiskAccess() {
        let urls: [URL] = [
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"),
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy"),
            URL(string: "x-apple.systempreferences:com.apple.preference.security"),
        ].compactMap(\.self)

        for url in urls where NSWorkspace.shared.open(url) {
            return
        }
    }
}
