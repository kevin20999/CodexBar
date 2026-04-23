import Foundation
import Logging

public struct TokenHistoryDisplayDocument: Sendable, Equatable {
    public let days: [DailyTokenStats]
    public let regularDays: [DailyTokenStats]
    public let hours: [HourlyTokenStats]
    public let regularHours: [HourlyTokenStats]
    public let outboundMessageDays: [DailyOutboundMessageStats]
    public let lastRefreshAt: Date?

    public init(
        days: [DailyTokenStats] = [],
        regularDays: [DailyTokenStats] = [],
        hours: [HourlyTokenStats] = [],
        regularHours: [HourlyTokenStats] = [],
        outboundMessageDays: [DailyOutboundMessageStats] = [],
        lastRefreshAt: Date? = nil)
    {
        self.days = days
        self.regularDays = regularDays
        self.hours = hours
        self.regularHours = regularHours
        self.outboundMessageDays = outboundMessageDays
        self.lastRefreshAt = lastRefreshAt
    }

    public static let empty = TokenHistoryDisplayDocument()
}

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

    public func loadForDisplay() throws -> TokenHistoryDisplayDocument {
        guard FileManager.default.fileExists(atPath: self.fileURL.path) else {
            return .empty
        }

        let data = try Data(contentsOf: self.fileURL)
        let decoder = JSONDecoder()
        let document = try decoder.decode(DisplayDecodableDocument.self, from: data)
        guard document.schemaVersion == TokenHistoryDocument.currentSchemaVersion else {
            self.logger.warning("Ignoring cached history with unsupported schema version \(document.schemaVersion)")
            return .empty
        }

        return TokenHistoryDisplayDocument(
            days: document.days.sorted { $0.date < $1.date },
            regularDays: Self.aggregateDailyBuckets(from: document.sessions.values.compactMap { snapshot in
                guard snapshot.sessionOriginKind == .regular else { return nil }
                return snapshot.dailyBuckets
            }),
            hours: document.hours.sorted { $0.hourStart < $1.hourStart },
            regularHours: Self.aggregateHourlyBuckets(from: document.sessions.values.compactMap { snapshot in
                guard snapshot.sessionOriginKind == .regular else { return nil }
                return snapshot.hourlyBuckets
            }),
            outboundMessageDays: document.outboundMessageDays.sorted { $0.date < $1.date },
            lastRefreshAt: document.lastRefreshAt)
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

    private static func aggregateDailyBuckets(from bucketSets: [[DailyTokenStats]]) -> [DailyTokenStats] {
        var days: [String: DailyTokenStats] = [:]
        for buckets in bucketSets {
            for bucket in buckets {
                var existing = days[bucket.date] ?? DailyTokenStats.empty(for: bucket.date)
                existing.merge(bucket)
                days[bucket.date] = existing
            }
        }
        return days.values.sorted { $0.date < $1.date }
    }

    private static func aggregateHourlyBuckets(from bucketSets: [[HourlyTokenStats]]) -> [HourlyTokenStats] {
        var hours: [Date: HourlyTokenStats] = [:]
        for buckets in bucketSets {
            for bucket in buckets {
                var existing = hours[bucket.hourStart] ?? HourlyTokenStats.empty(for: bucket.hourStart)
                existing.merge(bucket)
                hours[bucket.hourStart] = existing
            }
        }
        return hours.values.sorted { $0.hourStart < $1.hourStart }
    }
}

private struct DisplaySessionSnapshot: Decodable, Sendable {
    let sessionOriginKind: SessionOriginKind
    let dailyBuckets: [DailyTokenStats]
    let hourlyBuckets: [HourlyTokenStats]

    private enum CodingKeys: String, CodingKey {
        case sessionOriginKind
        case dailyBuckets
        case hourlyBuckets
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sessionOriginKind = try container.decodeIfPresent(
            SessionOriginKind.self,
            forKey: .sessionOriginKind) ?? .regular
        self.dailyBuckets = try container.decodeIfPresent([DailyTokenStats].self, forKey: .dailyBuckets) ?? []
        self.hourlyBuckets = try container.decodeIfPresent([HourlyTokenStats].self, forKey: .hourlyBuckets) ?? []
    }
}

private struct DisplayDecodableDocument: Decodable, Sendable {
    let schemaVersion: Int
    let sessions: [String: DisplaySessionSnapshot]
    let days: [DailyTokenStats]
    let hours: [HourlyTokenStats]
    let outboundMessageDays: [DailyOutboundMessageStats]
    let lastRefreshAt: Date?

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case sessions
        case days
        case hours
        case outboundMessageDays
        case lastRefreshAt
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        self.sessions = try container.decodeIfPresent([String: DisplaySessionSnapshot].self, forKey: .sessions) ?? [:]
        self.days = try container.decodeIfPresent([DailyTokenStats].self, forKey: .days) ?? []
        self.hours = try container.decodeIfPresent([HourlyTokenStats].self, forKey: .hours) ?? []
        self.outboundMessageDays = try container.decodeIfPresent(
            [DailyOutboundMessageStats].self,
            forKey: .outboundMessageDays) ?? []
        self.lastRefreshAt = try container.decodeIfPresent(Date.self, forKey: .lastRefreshAt)
    }
}
