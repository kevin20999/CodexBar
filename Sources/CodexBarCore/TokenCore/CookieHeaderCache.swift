import Foundation

public enum CookieHeaderCache {
    public struct Entry: Codable, Sendable, Equatable {
        public let cookieHeader: String
        public let storedAt: Date
        public let sourceLabel: String

        public init(cookieHeader: String, storedAt: Date, sourceLabel: String) {
            self.cookieHeader = cookieHeader
            self.storedAt = storedAt
            self.sourceLabel = sourceLabel
        }
    }

    public static func load() -> Entry? {
        guard let data = try? Data(contentsOf: self.fileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Entry.self, from: data)
    }

    public static func store(cookieHeader: String, sourceLabel: String, now: Date = Date()) {
        guard let normalized = CookieHeaderNormalizer.normalize(cookieHeader), !normalized.isEmpty else {
            self.clear()
            return
        }

        do {
            try FileManager.default.createDirectory(
                at: self.fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(Entry(cookieHeader: normalized, storedAt: now, sourceLabel: sourceLabel))
            try data.write(to: self.fileURL, options: [.atomic])
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: self.fileURL.path)
        } catch {
            // Best-effort cache only.
        }
    }

    public static func clear() {
        try? FileManager.default.removeItem(at: self.fileURL)
    }

    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent(TokenAppIdentity.applicationSupportDirectoryName, isDirectory: true)
            .appendingPathComponent("codex_cookie_cache.json")
    }
}
