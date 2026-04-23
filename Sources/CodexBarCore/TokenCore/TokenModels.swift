import Foundation

public struct TokenUsageEvent: Sendable, Equatable {
    public let timestamp: Date
    public let inputTokens: Int
    public let outputTokens: Int
    public let cachedInputTokens: Int
    public let reasoningOutputTokens: Int
    public let totalTokens: Int

    public init(
        timestamp: Date,
        inputTokens: Int,
        outputTokens: Int,
        cachedInputTokens: Int,
        reasoningOutputTokens: Int,
        totalTokens: Int)
    {
        self.timestamp = timestamp
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cachedInputTokens = cachedInputTokens
        self.reasoningOutputTokens = reasoningOutputTokens
        self.totalTokens = totalTokens
    }
}

public struct OutboundMessageUsageEvent: Codable, Sendable, Equatable {
    public let timestamp: Date
    public let sentCharacters: Int
    public let sentMessages: Int

    public init(timestamp: Date, sentCharacters: Int, sentMessages: Int) {
        self.timestamp = timestamp
        self.sentCharacters = sentCharacters
        self.sentMessages = sentMessages
    }

    public var characterCount: Int {
        self.sentCharacters
    }

    public var instructionCount: Int {
        self.sentMessages
    }
}

public struct DailyTokenStats: Codable, Sendable, Equatable, Identifiable {
    public let date: String
    public var inputTokens: Int
    public var outputTokens: Int
    public var cachedInputTokens: Int
    public var reasoningOutputTokens: Int
    public var totalTokens: Int

    public init(
        date: String,
        inputTokens: Int,
        outputTokens: Int,
        cachedInputTokens: Int,
        reasoningOutputTokens: Int,
        totalTokens: Int)
    {
        self.date = date
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cachedInputTokens = cachedInputTokens
        self.reasoningOutputTokens = reasoningOutputTokens
        self.totalTokens = totalTokens
    }

    public var id: String {
        self.date
    }

    public static func empty(for date: String) -> DailyTokenStats {
        DailyTokenStats(
            date: date,
            inputTokens: 0,
            outputTokens: 0,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: 0)
    }

    public mutating func add(_ event: TokenUsageEvent) {
        self.inputTokens += event.inputTokens
        self.outputTokens += event.outputTokens
        self.cachedInputTokens += event.cachedInputTokens
        self.reasoningOutputTokens += event.reasoningOutputTokens
        self.totalTokens += event.totalTokens
    }

    public mutating func merge(_ other: DailyTokenStats) {
        self.inputTokens += other.inputTokens
        self.outputTokens += other.outputTokens
        self.cachedInputTokens += other.cachedInputTokens
        self.reasoningOutputTokens += other.reasoningOutputTokens
        self.totalTokens += other.totalTokens
    }

    public static func + (lhs: DailyTokenStats, rhs: DailyTokenStats) -> DailyTokenStats {
        var combined = lhs
        combined.merge(rhs)
        return combined
    }

    public static func dayKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents(in: calendar.timeZone, from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0)
    }

    public var chartDate: Date? {
        let parts = self.date.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else {
            return nil
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.calendar = Calendar.current
        components.timeZone = Calendar.current.timeZone
        return components.date
    }
}

public struct DailyOutboundMessageStats: Codable, Sendable, Equatable, Identifiable {
    public let date: String
    public var sentCharacters: Int
    public var sentMessages: Int

    public init(date: String, sentCharacters: Int, sentMessages: Int) {
        self.date = date
        self.sentCharacters = sentCharacters
        self.sentMessages = sentMessages
    }

    public var id: String {
        self.date
    }

    public var characterCount: Int {
        self.sentCharacters
    }

    public var instructionCount: Int {
        self.sentMessages
    }

    public static func empty(for date: String) -> DailyOutboundMessageStats {
        DailyOutboundMessageStats(date: date, sentCharacters: 0, sentMessages: 0)
    }

    public mutating func add(_ event: OutboundMessageUsageEvent) {
        self.sentCharacters += event.sentCharacters
        self.sentMessages += event.sentMessages
    }

    public mutating func merge(_ other: DailyOutboundMessageStats) {
        self.sentCharacters += other.sentCharacters
        self.sentMessages += other.sentMessages
    }

    public static func + (lhs: DailyOutboundMessageStats, rhs: DailyOutboundMessageStats) -> DailyOutboundMessageStats {
        var combined = lhs
        combined.merge(rhs)
        return combined
    }

    public var chartDate: Date? {
        let parts = self.date.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else {
            return nil
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.calendar = Calendar.current
        components.timeZone = Calendar.current.timeZone
        return components.date
    }
}

public struct HourlyTokenStats: Codable, Sendable, Equatable, Identifiable {
    public let hourStart: Date
    public var inputTokens: Int
    public var outputTokens: Int
    public var cachedInputTokens: Int
    public var reasoningOutputTokens: Int
    public var totalTokens: Int

    public init(
        hourStart: Date,
        inputTokens: Int,
        outputTokens: Int,
        cachedInputTokens: Int,
        reasoningOutputTokens: Int,
        totalTokens: Int)
    {
        self.hourStart = hourStart
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cachedInputTokens = cachedInputTokens
        self.reasoningOutputTokens = reasoningOutputTokens
        self.totalTokens = totalTokens
    }

    public var id: Date {
        self.hourStart
    }

    public static func empty(for hourStart: Date) -> HourlyTokenStats {
        HourlyTokenStats(
            hourStart: hourStart,
            inputTokens: 0,
            outputTokens: 0,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: 0)
    }

    public mutating func add(_ event: TokenUsageEvent) {
        self.inputTokens += event.inputTokens
        self.outputTokens += event.outputTokens
        self.cachedInputTokens += event.cachedInputTokens
        self.reasoningOutputTokens += event.reasoningOutputTokens
        self.totalTokens += event.totalTokens
    }

    public mutating func merge(_ other: HourlyTokenStats) {
        self.inputTokens += other.inputTokens
        self.outputTokens += other.outputTokens
        self.cachedInputTokens += other.cachedInputTokens
        self.reasoningOutputTokens += other.reasoningOutputTokens
        self.totalTokens += other.totalTokens
    }

    public static func + (lhs: HourlyTokenStats, rhs: HourlyTokenStats) -> HourlyTokenStats {
        var combined = lhs
        combined.merge(rhs)
        return combined
    }

    public static func hourStart(for date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .hour, for: date)?.start ?? date
    }
}

public struct FiveMinuteTokenStats: Codable, Sendable, Equatable, Identifiable {
    public let bucketStart: Date
    public var inputTokens: Int
    public var outputTokens: Int
    public var cachedInputTokens: Int
    public var reasoningOutputTokens: Int
    public var totalTokens: Int

    public init(
        bucketStart: Date,
        inputTokens: Int,
        outputTokens: Int,
        cachedInputTokens: Int,
        reasoningOutputTokens: Int,
        totalTokens: Int)
    {
        self.bucketStart = bucketStart
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cachedInputTokens = cachedInputTokens
        self.reasoningOutputTokens = reasoningOutputTokens
        self.totalTokens = totalTokens
    }

    public var id: Date {
        self.bucketStart
    }

    public static func empty(for bucketStart: Date) -> FiveMinuteTokenStats {
        FiveMinuteTokenStats(
            bucketStart: bucketStart,
            inputTokens: 0,
            outputTokens: 0,
            cachedInputTokens: 0,
            reasoningOutputTokens: 0,
            totalTokens: 0)
    }

    public mutating func add(_ event: TokenUsageEvent) {
        self.inputTokens += event.inputTokens
        self.outputTokens += event.outputTokens
        self.cachedInputTokens += event.cachedInputTokens
        self.reasoningOutputTokens += event.reasoningOutputTokens
        self.totalTokens += event.totalTokens
    }

    public mutating func merge(_ other: FiveMinuteTokenStats) {
        self.inputTokens += other.inputTokens
        self.outputTokens += other.outputTokens
        self.cachedInputTokens += other.cachedInputTokens
        self.reasoningOutputTokens += other.reasoningOutputTokens
        self.totalTokens += other.totalTokens
    }

    public static func + (lhs: FiveMinuteTokenStats, rhs: FiveMinuteTokenStats) -> FiveMinuteTokenStats {
        var combined = lhs
        combined.merge(rhs)
        return combined
    }

    public static func bucketStart(for date: Date, calendar: Calendar) -> Date {
        let minuteStart = calendar.dateInterval(of: .minute, for: date)?.start ?? date
        let minute = calendar.component(.minute, from: minuteStart)
        let bucketMinute = (minute / 5) * 5
        let startOfHour = calendar.dateInterval(of: .hour, for: minuteStart)?.start ?? minuteStart
        return calendar.date(byAdding: .minute, value: bucketMinute, to: startOfHour) ?? minuteStart
    }
}

public enum SessionOriginKind: String, Codable, Sendable, Equatable {
    case regular
    case subagentThreadSpawn
}

public struct SessionRunningTokenTotals: Codable, Sendable, Equatable {
    public let inputTokens: Int
    public let outputTokens: Int
    public let cachedInputTokens: Int
    public let reasoningOutputTokens: Int

    public init(
        inputTokens: Int,
        outputTokens: Int,
        cachedInputTokens: Int,
        reasoningOutputTokens: Int)
    {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cachedInputTokens = cachedInputTokens
        self.reasoningOutputTokens = reasoningOutputTokens
    }

    public static let zero = SessionRunningTokenTotals(
        inputTokens: 0,
        outputTokens: 0,
        cachedInputTokens: 0,
        reasoningOutputTokens: 0)
}

public enum SessionInstructionCandidateSource: String, Codable, Sendable, Equatable {
    case responseItem
    case eventMessage
}

public struct SessionInstructionCandidate: Codable, Sendable, Equatable {
    public let source: SessionInstructionCandidateSource
    public let signature: String
    public let event: OutboundMessageUsageEvent

    public init(
        source: SessionInstructionCandidateSource,
        signature: String,
        event: OutboundMessageUsageEvent)
    {
        self.source = source
        self.signature = signature
        self.event = event
    }
}

public struct SessionIncrementalMigrationProgress: Codable, Sendable, Equatable {
    public let lastScannedByteOffset: Int64
    public let sourceFileIdentity: String?
    public let observedFileSize: Int64?
    public let observedModificationTime: Date?
    public let scanVersion: Int
    public let runningTokenTotals: SessionRunningTokenTotals?
    public let seenTokenCountFingerprints: [String]
    public let lastEventAt: Date?
    public let dailyBuckets: [DailyTokenStats]
    public let hourlyBuckets: [HourlyTokenStats]
    public let fiveMinuteBuckets: [FiveMinuteTokenStats]
    public let instructionCandidates: [SessionInstructionCandidate]

    public init(
        lastScannedByteOffset: Int64,
        sourceFileIdentity: String? = nil,
        observedFileSize: Int64? = nil,
        observedModificationTime: Date? = nil,
        scanVersion: Int,
        runningTokenTotals: SessionRunningTokenTotals? = nil,
        seenTokenCountFingerprints: [String] = [],
        lastEventAt: Date? = nil,
        dailyBuckets: [DailyTokenStats] = [],
        hourlyBuckets: [HourlyTokenStats] = [],
        fiveMinuteBuckets: [FiveMinuteTokenStats] = [],
        instructionCandidates: [SessionInstructionCandidate] = [])
    {
        self.lastScannedByteOffset = lastScannedByteOffset
        self.sourceFileIdentity = sourceFileIdentity
        self.observedFileSize = observedFileSize
        self.observedModificationTime = observedModificationTime
        self.scanVersion = scanVersion
        self.runningTokenTotals = runningTokenTotals
        self.seenTokenCountFingerprints = seenTokenCountFingerprints
        self.lastEventAt = lastEventAt
        self.dailyBuckets = dailyBuckets.sorted { $0.date < $1.date }
        self.hourlyBuckets = hourlyBuckets.sorted { $0.hourStart < $1.hourStart }
        self.fiveMinuteBuckets = fiveMinuteBuckets.sorted { $0.bucketStart < $1.bucketStart }
        self.instructionCandidates = instructionCandidates.sorted { lhs, rhs in
            if lhs.event.timestamp != rhs.event.timestamp {
                return lhs.event.timestamp < rhs.event.timestamp
            }
            return lhs.signature < rhs.signature
        }
    }
}

public struct SessionUsageSnapshot: Codable, Sendable, Equatable {
    public let sessionID: String
    public let sessionOriginKind: SessionOriginKind
    public let sourceFile: String
    public let sourceFileIdentity: String?
    public let sourceFileSize: Int64?
    public let sourceFileModificationTime: Date?
    public let lastEventAt: Date?
    public let scanVersion: Int
    public let lastScannedByteOffset: Int64?
    public let runningTokenTotals: SessionRunningTokenTotals?
    public let seenTokenCountFingerprints: [String]
    public let incrementalMigrationProgress: SessionIncrementalMigrationProgress?
    public let dailyBuckets: [DailyTokenStats]
    public let hourlyBuckets: [HourlyTokenStats]
    public let fiveMinuteBuckets: [FiveMinuteTokenStats]
    public let outboundMessageDailyBuckets: [DailyOutboundMessageStats]

    public init(
        sessionID: String,
        sessionOriginKind: SessionOriginKind = .regular,
        sourceFile: String,
        sourceFileIdentity: String? = nil,
        sourceFileSize: Int64?,
        sourceFileModificationTime: Date?,
        lastEventAt: Date?,
        scanVersion: Int = 0,
        lastScannedByteOffset: Int64? = nil,
        runningTokenTotals: SessionRunningTokenTotals? = nil,
        seenTokenCountFingerprints: [String] = [],
        incrementalMigrationProgress: SessionIncrementalMigrationProgress? = nil,
        dailyBuckets: [DailyTokenStats],
        hourlyBuckets: [HourlyTokenStats] = [],
        fiveMinuteBuckets: [FiveMinuteTokenStats] = [],
        outboundMessageDailyBuckets: [DailyOutboundMessageStats] = [])
    {
        self.sessionID = sessionID
        self.sessionOriginKind = sessionOriginKind
        self.sourceFile = sourceFile
        self.sourceFileIdentity = sourceFileIdentity
        self.sourceFileSize = sourceFileSize
        self.sourceFileModificationTime = sourceFileModificationTime
        self.lastEventAt = lastEventAt
        self.scanVersion = scanVersion
        self.lastScannedByteOffset = lastScannedByteOffset ?? sourceFileSize
        self.runningTokenTotals = runningTokenTotals
        self.seenTokenCountFingerprints = seenTokenCountFingerprints
        self.incrementalMigrationProgress = incrementalMigrationProgress
        self.dailyBuckets = dailyBuckets.sorted { $0.date < $1.date }
        self.hourlyBuckets = hourlyBuckets.sorted { $0.hourStart < $1.hourStart }
        self.fiveMinuteBuckets = fiveMinuteBuckets.sorted { $0.bucketStart < $1.bucketStart }
        self.outboundMessageDailyBuckets = outboundMessageDailyBuckets.sorted { $0.date < $1.date }
    }

    private enum CodingKeys: String, CodingKey {
        case sessionID
        case sessionOriginKind
        case sourceFile
        case sourceFileIdentity
        case sourceFileSize
        case sourceFileModificationTime
        case lastEventAt
        case scanVersion
        case lastScannedByteOffset
        case runningTokenTotals
        case seenTokenCountFingerprints
        case incrementalMigrationProgress
        case dailyBuckets
        case hourlyBuckets
        case fiveMinuteBuckets
        case outboundMessageDailyBuckets
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sessionID = try container.decode(String.self, forKey: .sessionID)
        self.sessionOriginKind = try container.decodeIfPresent(
            SessionOriginKind.self,
            forKey: .sessionOriginKind) ?? .regular
        self.sourceFile = try container.decode(String.self, forKey: .sourceFile)
        self.sourceFileIdentity = try container.decodeIfPresent(String.self, forKey: .sourceFileIdentity)
        self.sourceFileSize = try container.decodeIfPresent(Int64.self, forKey: .sourceFileSize)
        self.sourceFileModificationTime = try container.decodeIfPresent(Date.self, forKey: .sourceFileModificationTime)
        self.lastEventAt = try container.decodeIfPresent(Date.self, forKey: .lastEventAt)
        self.scanVersion = try container.decodeIfPresent(Int.self, forKey: .scanVersion) ?? 0
        self.lastScannedByteOffset = try container.decodeIfPresent(Int64.self, forKey: .lastScannedByteOffset)
            ?? self.sourceFileSize
        self.runningTokenTotals = try container.decodeIfPresent(
            SessionRunningTokenTotals.self,
            forKey: .runningTokenTotals)
        self.seenTokenCountFingerprints = try container.decodeIfPresent(
            [String].self,
            forKey: .seenTokenCountFingerprints) ?? []
        self.incrementalMigrationProgress = try container.decodeIfPresent(
            SessionIncrementalMigrationProgress.self,
            forKey: .incrementalMigrationProgress)
        self.dailyBuckets = try container.decode([DailyTokenStats].self, forKey: .dailyBuckets)
        self.hourlyBuckets = try container.decodeIfPresent([HourlyTokenStats].self, forKey: .hourlyBuckets) ?? []
        self.fiveMinuteBuckets = try container.decodeIfPresent([FiveMinuteTokenStats].self, forKey: .fiveMinuteBuckets)
            ?? []
        self.outboundMessageDailyBuckets = try container.decodeIfPresent(
            [DailyOutboundMessageStats].self,
            forKey: .outboundMessageDailyBuckets) ?? []
    }
}

public struct TokenRefreshResult: Sendable, Equatable {
    public let sessions: [String: SessionUsageSnapshot]
    public let days: [DailyTokenStats]
    public let hours: [HourlyTokenStats]
    public let fiveMinuteBuckets: [FiveMinuteTokenStats]
    public let outboundMessageDays: [DailyOutboundMessageStats]
    public let refreshedAt: Date
    public let scannedFileCount: Int
    public let reusedSessionCount: Int
    public let tailScannedSessionCount: Int
    public let errors: [String]

    public init(
        sessions: [String: SessionUsageSnapshot],
        days: [DailyTokenStats],
        hours: [HourlyTokenStats] = [],
        fiveMinuteBuckets: [FiveMinuteTokenStats] = [],
        outboundMessageDays: [DailyOutboundMessageStats] = [],
        refreshedAt: Date,
        scannedFileCount: Int,
        reusedSessionCount: Int,
        tailScannedSessionCount: Int = 0,
        errors: [String])
    {
        self.sessions = sessions
        self.days = days.sorted { $0.date < $1.date }
        self.hours = hours.sorted { $0.hourStart < $1.hourStart }
        self.fiveMinuteBuckets = fiveMinuteBuckets.sorted { $0.bucketStart < $1.bucketStart }
        self.outboundMessageDays = outboundMessageDays.sorted { $0.date < $1.date }
        self.refreshedAt = refreshedAt
        self.scannedFileCount = scannedFileCount
        self.reusedSessionCount = reusedSessionCount
        self.tailScannedSessionCount = tailScannedSessionCount
        self.errors = errors
    }
}

public struct TokenHistoryDocument: Codable, Sendable, Equatable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var sessions: [String: SessionUsageSnapshot]
    public var days: [DailyTokenStats]
    public var hours: [HourlyTokenStats]
    public var fiveMinuteBuckets: [FiveMinuteTokenStats]
    public var outboundMessageDays: [DailyOutboundMessageStats]
    public var lastRefreshAt: Date?

    public init(
        schemaVersion: Int = TokenHistoryDocument.currentSchemaVersion,
        sessions: [String: SessionUsageSnapshot] = [:],
        days: [DailyTokenStats] = [],
        hours: [HourlyTokenStats] = [],
        fiveMinuteBuckets: [FiveMinuteTokenStats] = [],
        outboundMessageDays: [DailyOutboundMessageStats] = [],
        lastRefreshAt: Date? = nil)
    {
        self.schemaVersion = schemaVersion
        self.sessions = sessions
        self.days = days.sorted { $0.date < $1.date }
        self.hours = hours.sorted { $0.hourStart < $1.hourStart }
        self.fiveMinuteBuckets = fiveMinuteBuckets.sorted { $0.bucketStart < $1.bucketStart }
        self.outboundMessageDays = outboundMessageDays.sorted { $0.date < $1.date }
        self.lastRefreshAt = lastRefreshAt
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case sessions
        case days
        case hours
        case fiveMinuteBuckets
        case outboundMessageDays
        case lastRefreshAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        self.sessions = try container.decodeIfPresent([String: SessionUsageSnapshot].self, forKey: .sessions) ?? [:]
        self.days = try container.decodeIfPresent([DailyTokenStats].self, forKey: .days) ?? []
        self.hours = try container.decodeIfPresent([HourlyTokenStats].self, forKey: .hours) ?? []
        self.fiveMinuteBuckets = try container.decodeIfPresent(
            [FiveMinuteTokenStats].self,
            forKey: .fiveMinuteBuckets) ?? []
        self.outboundMessageDays = try container.decodeIfPresent(
            [DailyOutboundMessageStats].self,
            forKey: .outboundMessageDays) ?? []
        self.lastRefreshAt = try container.decodeIfPresent(Date.self, forKey: .lastRefreshAt)
    }

    public static let empty = TokenHistoryDocument()
}
