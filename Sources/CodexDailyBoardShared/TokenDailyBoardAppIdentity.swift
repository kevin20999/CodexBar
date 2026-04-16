import CodexBarCore
import Foundation

public enum CodexDailyAppIdentity {
    public static let appDisplayName = "CodexDaily"
    public static let appBundleName = "\(appDisplayName).app"
    public static let executableName = "CodexDaily"
    public static let bundleIdentifier = "com.kevin.codexdaily"
    public static let applicationSupportDirectoryName = "CodexDaily"
    public static let defaultsSuiteName = bundleIdentifier
    public static let keychainServiceName = bundleIdentifier

    public static var applicationSupportDirectoryURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(
                "Library/Application Support",
                isDirectory: true)
        return baseURL.appendingPathComponent(self.applicationSupportDirectoryName, isDirectory: true)
    }

    public static var historyFileURL: URL {
        self.applicationSupportDirectoryURL.appendingPathComponent("token_stats.json", isDirectory: false)
    }

    public static var tokenSpeedHistoryFileURL: URL {
        self.applicationSupportDirectoryURL.appendingPathComponent("token_speed_history.json", isDirectory: false)
    }

    public static var instructionEventHistoryFileURL: URL {
        self.applicationSupportDirectoryURL.appendingPathComponent("instruction_event_history.json", isDirectory: false)
    }

    public static var narrativeUserCatalogFileURL: URL {
        self.applicationSupportDirectoryURL.appendingPathComponent(
            "DailyBoardPersonaUserCatalog.json",
            isDirectory: false)
    }

    public static var avatarCustomizationFileURL: URL {
        self.applicationSupportDirectoryURL.appendingPathComponent(
            "DailyBoardAvatarCustomization.json",
            isDirectory: false)
    }

    public static var avatarAssetsDirectoryURL: URL {
        self.applicationSupportDirectoryURL.appendingPathComponent("Avatars", isDirectory: true)
    }

    public static var legacyHistoryImportCandidateURLs: [URL] {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(
                "Library/Application Support",
                isDirectory: true)

        return [
            TokenHistoryStore.defaultFileURL,
            baseURL
                .appendingPathComponent("CodexDailyBoard", isDirectory: true)
                .appendingPathComponent("token_stats.json", isDirectory: false),
            baseURL
                .appendingPathComponent("CodexTokenBar Daily Board", isDirectory: true)
                .appendingPathComponent("token_stats.json", isDirectory: false),
        ]
    }
}

public typealias TokenDailyBoardAppIdentity = CodexDailyAppIdentity
