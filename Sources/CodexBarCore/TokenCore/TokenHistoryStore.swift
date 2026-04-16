import Foundation
import Logging

public struct TokenHistoryStore: Sendable {
    public static let defaultFileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return appSupport
            .appendingPathComponent(TokenAppIdentity.applicationSupportDirectoryName, isDirectory: true)
            .appendingPathComponent("token_stats.json", isDirectory: false)
    }()

    public let fileURL: URL

    private let logger = Logger(label: "CodexBar.TokenHistoryStore")

    public init(fileURL: URL = TokenHistoryStore.defaultFileURL) {
        self.fileURL = fileURL
    }

    public func load() throws -> TokenHistoryDocument {
        guard FileManager.default.fileExists(atPath: self.fileURL.path) else {
            return .empty
        }

        let data = try Data(contentsOf: self.fileURL)
        let decoder = JSONDecoder()
        let document = try decoder.decode(TokenHistoryDocument.self, from: data)
        guard document.schemaVersion == TokenHistoryDocument.currentSchemaVersion else {
            self.logger.warning("Ignoring cached history with unsupported schema version \(document.schemaVersion)")
            return .empty
        }

        return document
    }

    @discardableResult
    public func merge(refreshResult: TokenRefreshResult) throws -> TokenHistoryDocument {
        let document = TokenHistoryDocument(
            sessions: refreshResult.sessions,
            days: refreshResult.days,
            hours: refreshResult.hours,
            fiveMinuteBuckets: refreshResult.fiveMinuteBuckets,
            outboundMessageDays: refreshResult.outboundMessageDays,
            lastRefreshAt: refreshResult.refreshedAt)
        try self.write(document)
        return document
    }

    @discardableResult
    public func rebuild(from refreshResult: TokenRefreshResult) throws -> TokenHistoryDocument {
        try self.merge(refreshResult: refreshResult)
    }

    public func reset() throws {
        try self.write(.empty)
    }

    private func write(_ document: TokenHistoryDocument) throws {
        let directoryURL = self.fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directoryURL.path)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)
        try data.write(to: self.fileURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: self.fileURL.path)
    }
}
