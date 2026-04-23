import Foundation
import Logging

public struct TokenSpeedSample: Codable, Sendable, Equatable, Identifiable {
    public let timestamp: Date
    public let tokens: Int

    public var id: Date {
        self.timestamp
    }

    public init(timestamp: Date, tokens: Int) {
        self.timestamp = Self.secondStart(for: timestamp)
        self.tokens = tokens
    }

    public static func secondStart(for date: Date) -> Date {
        Date(timeIntervalSince1970: floor(date.timeIntervalSince1970))
    }
}

public struct TokenSpeedHistoryEntry: Sendable, Equatable, Identifiable {
    public let timestamp: Date
    public let tokens: Int

    public var id: Date {
        self.timestamp
    }

    public init(timestamp: Date, tokens: Int) {
        self.timestamp = TokenSpeedSample.secondStart(for: timestamp)
        self.tokens = tokens
    }

    public init(sample: TokenSpeedSample) {
        self.init(timestamp: sample.timestamp, tokens: sample.tokens)
    }
}

private struct TokenSpeedHistoryDocument: Codable, Sendable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var samples: [TokenSpeedSample]

    init(schemaVersion: Int = Self.currentSchemaVersion, samples: [TokenSpeedSample] = []) {
        self.schemaVersion = schemaVersion
        self.samples = samples.sorted { $0.timestamp < $1.timestamp }
    }
}

public struct TokenSpeedHistoryStore: Sendable {
    public let fileURL: URL
    private let logger = Logger(label: "CodexBarCore.TokenSpeedHistoryStore")

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static func defaultFileURL(applicationSupportDirectoryName: String) -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return appSupport
            .appendingPathComponent(applicationSupportDirectoryName, isDirectory: true)
            .appendingPathComponent("token_speed_history.json", isDirectory: false)
    }

    public func load() throws -> [TokenSpeedSample] {
        try self.load(limitToLatest: nil)
    }

    public func load(limitToLatest count: Int?) throws -> [TokenSpeedSample] {
        guard FileManager.default.fileExists(atPath: self.fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: self.fileURL)
        let decoder = JSONDecoder()
        let document = try decoder.decode(TokenSpeedHistoryDocument.self, from: data)
        guard document.schemaVersion == TokenSpeedHistoryDocument.currentSchemaVersion else {
            self.logger.warning(
                "Ignoring token speed history with unsupported schema version \(document.schemaVersion)")
            return []
        }

        return Self.normalizedSamples(document.samples, keepingLatest: count)
    }

    public func save(samples: [TokenSpeedSample], keepingLatest count: Int? = nil) throws {
        try self.write(samples: Self.normalizedSamples(samples, keepingLatest: count))
    }

    @discardableResult
    public func upsert(sample: TokenSpeedSample) throws -> [TokenSpeedSample] {
        var samples = try self.load()
        if let index = samples.firstIndex(where: { $0.timestamp == sample.timestamp }) {
            samples[index] = sample
        } else {
            samples.append(sample)
            samples.sort { $0.timestamp < $1.timestamp }
        }
        let normalizedSamples = Self.normalizedSamples(samples, keepingLatest: nil)
        try self.write(samples: normalizedSamples)
        return normalizedSamples
    }

    private func write(samples: [TokenSpeedSample]) throws {
        let directoryURL = self.fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directoryURL.path)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(TokenSpeedHistoryDocument(samples: samples))
        try data.write(to: self.fileURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: self.fileURL.path)
    }

    private static func normalizedSamples(_ samples: [TokenSpeedSample], keepingLatest count: Int?) -> [TokenSpeedSample] {
        var samplesByTimestamp: [Date: TokenSpeedSample] = [:]
        for sample in samples {
            samplesByTimestamp[TokenSpeedSample.secondStart(for: sample.timestamp)] = sample
        }

        let normalizedSamples = samplesByTimestamp.values.sorted { $0.timestamp < $1.timestamp }
        guard let count, normalizedSamples.count > count else {
            return normalizedSamples
        }
        return Array(normalizedSamples.suffix(count))
    }
}

public protocol CodexLiveTokenRateMonitoring: Sendable {
    func sample() async -> TokenSpeedSample
    func reset() async
}

private struct CodexLiveTokenTotals: Equatable, Sendable {
    let input: Int
    let cachedInput: Int
    let output: Int
    let reasoningOutput: Int
}

private struct ParsedTokenEvent {
    let timestamp: Date?
    let totalTotals: CodexLiveTokenTotals?
    let lastTotals: CodexLiveTokenTotals?
}

public actor CodexLiveTokenRateMonitor: CodexLiveTokenRateMonitoring {
    private struct FileState: Sendable {
        var offset: UInt64
        var pendingFragment = Data()
        var previousTotals: CodexLiveTokenTotals?
    }

    private let sessionRootURL: URL
    private let fileManager: FileManager
    private let now: @Sendable () -> Date
    private let seedTailByteCount: UInt64
    private var fileStates: [String: FileState] = [:]
    private var hasPrimed = false

    public init(
        sessionRootURL: URL,
        fileManager: FileManager = .default,
        now: @escaping @Sendable () -> Date = Date.init,
        seedTailByteCount: UInt64 = 131_072)
    {
        self.sessionRootURL = sessionRootURL
        self.fileManager = fileManager
        self.now = now
        self.seedTailByteCount = seedTailByteCount
    }

    public func reset() async {
        self.fileStates.removeAll()
        self.hasPrimed = false
    }

    public func sample() async -> TokenSpeedSample {
        let sampleTimestamp = TokenSpeedSample.secondStart(for: self.now())
        let fileURLs = self.sessionFiles()

        if !self.hasPrimed {
            for fileURL in fileURLs {
                self.fileStates[fileURL.path] = self.seedState(for: fileURL)
            }
            self.hasPrimed = true
            return TokenSpeedSample(timestamp: sampleTimestamp, tokens: 0)
        }

        let knownPaths = Set(fileURLs.map(\.path))
        self.fileStates = self.fileStates.filter { knownPaths.contains($0.key) }

        let cutoff = sampleTimestamp.addingTimeInterval(-1)
        var totalDelta = 0

        for fileURL in fileURLs {
            let path = fileURL.path
            var state = self.fileStates[path]
                ?? FileState(offset: 0, pendingFragment: Data(), previousTotals: nil)
            totalDelta += self.sample(fileURL: fileURL, state: &state, cutoff: cutoff)
            self.fileStates[path] = state
        }

        return TokenSpeedSample(timestamp: sampleTimestamp, tokens: totalDelta)
    }

    private func sessionFiles() -> [URL] {
        guard self.fileManager.fileExists(atPath: self.sessionRootURL.path) else {
            return []
        }

        let enumerator = self.fileManager.enumerator(
            at: self.sessionRootURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles])

        var files: [URL] = []
        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.pathExtension.lowercased() == "jsonl" else { continue }
            files.append(fileURL)
        }
        return files.sorted { $0.path < $1.path }
    }

    private func seedState(for fileURL: URL) -> FileState {
        let fileSize = self.fileSize(for: fileURL)
        guard fileSize > 0 else {
            return FileState(offset: 0, pendingFragment: Data(), previousTotals: nil)
        }

        let readOffset = fileSize > self.seedTailByteCount ? (fileSize - self.seedTailByteCount) : 0
        guard let data = self.readData(from: fileURL, offset: readOffset, length: nil) else {
            return FileState(offset: fileSize, pendingFragment: Data(), previousTotals: nil)
        }

        let seededData: Data = if readOffset > 0, let firstLineBreak = data.firstIndex(of: 0x0A) {
            data.suffix(from: data.index(after: firstLineBreak))
        } else {
            data
        }

        var previousTotals: CodexLiveTokenTotals?
        self.enumerateLines(in: seededData) { line in
            guard let event = self.parseTokenEvent(from: line) else { return }
            if let totals = event.totalTotals {
                previousTotals = totals
            }
        }

        return FileState(offset: fileSize, pendingFragment: Data(), previousTotals: previousTotals)
    }

    private func sample(fileURL: URL, state: inout FileState, cutoff: Date) -> Int {
        let fileSize = self.fileSize(for: fileURL)
        if fileSize < state.offset {
            state = FileState(offset: 0, pendingFragment: Data(), previousTotals: nil)
        }

        guard fileSize > state.offset else { return 0 }
        guard var appendedData = self.readData(
            from: fileURL,
            offset: state.offset,
            length: Int(fileSize - state.offset))
        else {
            state.offset = fileSize
            state.pendingFragment = Data()
            return 0
        }

        if !state.pendingFragment.isEmpty {
            var combined = state.pendingFragment
            combined.append(appendedData)
            appendedData = combined
            state.pendingFragment = Data()
        }

        let endsWithNewline = appendedData.last == 0x0A
        let lines = self.splitLines(from: appendedData)
        if !endsWithNewline, let trailingFragment = lines.last {
            state.pendingFragment = trailingFragment
        }

        let completeLines = endsWithNewline ? lines : lines.dropLast()
        var delta = 0

        for line in completeLines where !line.isEmpty {
            guard let event = self.parseTokenEvent(from: line) else { continue }

            if let totals = event.totalTotals {
                let previousTotals = state.previousTotals
                let inputDelta = max(0, totals.input - (previousTotals?.input ?? 0))
                let cachedInputDelta = max(0, totals.cachedInput - (previousTotals?.cachedInput ?? 0))
                let outputDelta = max(0, totals.output - (previousTotals?.output ?? 0))
                let reasoningOutputDelta = max(0, totals.reasoningOutput - (previousTotals?.reasoningOutput ?? 0))
                state.previousTotals = totals

                guard inputDelta > 0 || cachedInputDelta > 0 || outputDelta > 0 || reasoningOutputDelta > 0 else {
                    continue
                }

                if let timestamp = event.timestamp, timestamp < cutoff {
                    continue
                }

                delta += inputDelta + cachedInputDelta + outputDelta + reasoningOutputDelta
                continue
            }

            guard let lastUsage = event.lastTotals else { continue }
            if let timestamp = event.timestamp, timestamp < cutoff {
                continue
            }

            delta += max(0, lastUsage.input)
                + max(0, lastUsage.cachedInput)
                + max(0, lastUsage.output)
                + max(0, lastUsage.reasoningOutput)
        }

        state.offset = fileSize
        return delta
    }

    private func fileSize(for fileURL: URL) -> UInt64 {
        let attributes = try? self.fileManager.attributesOfItem(atPath: fileURL.path)
        return (attributes?[.size] as? NSNumber)?.uint64Value ?? 0
    }

    private func readData(from fileURL: URL, offset: UInt64, length: Int?) -> Data? {
        guard let handle = try? FileHandle(forReadingFrom: fileURL) else {
            return nil
        }
        defer { try? handle.close() }

        do {
            try handle.seek(toOffset: offset)
            if let length {
                return try handle.read(upToCount: length) ?? Data()
            }
            return try handle.readToEnd() ?? Data()
        } catch {
            return nil
        }
    }

    private func splitLines(from data: Data) -> [Data] {
        var lines: [Data] = []
        var lineStartIndex = data.startIndex

        for index in data.indices where data[index] == 0x0A {
            lines.append(data.subdata(in: lineStartIndex..<index))
            lineStartIndex = data.index(after: index)
        }

        if lineStartIndex <= data.endIndex {
            lines.append(data.subdata(in: lineStartIndex..<data.endIndex))
        }

        return lines
    }

    private func enumerateLines(in data: Data, _ block: (Data) -> Void) {
        for line in data.split(separator: 0x0A, omittingEmptySubsequences: true) {
            block(Data(line))
        }
    }

    private func parseTokenEvent(from line: Data) -> ParsedTokenEvent? {
        guard let object = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any],
              (object["type"] as? String) == "event_msg",
              let payload = object["payload"] as? [String: Any],
              (payload["type"] as? String) == "token_count"
        else {
            return nil
        }

        let timestamp = Self.parseTimestamp(object["timestamp"])
        let info = payload["info"] as? [String: Any]
        let totalTotals = Self.makeTotals(from: info?["total_token_usage"] as? [String: Any])
        let lastTotals = Self.makeTotals(from: info?["last_token_usage"] as? [String: Any])

        return ParsedTokenEvent(
            timestamp: timestamp,
            totalTotals: totalTotals,
            lastTotals: lastTotals)
    }

    private static func makeTotals(from info: [String: Any]?) -> CodexLiveTokenTotals? {
        guard let info else { return nil }
        let input = self.integerValue(info["input_tokens"])
        let cachedInput = self.integerValue(info["cached_input_tokens"])
        let output = self.integerValue(info["output_tokens"])
        let reasoningOutput = self.integerValue(info["reasoning_output_tokens"])

        guard input > 0 || cachedInput > 0 || output > 0 || reasoningOutput > 0 else {
            return nil
        }

        return CodexLiveTokenTotals(
            input: input,
            cachedInput: cachedInput,
            output: output,
            reasoningOutput: reasoningOutput)
    }

    private static func integerValue(_ value: Any?) -> Int {
        switch value {
        case let number as NSNumber:
            return number.intValue
        case let string as String:
            if let intValue = Int(string) {
                return intValue
            }
            if let doubleValue = Double(string) {
                return Int(doubleValue)
            }
            return 0
        default:
            return 0
        }
    }

    private static func parseTimestamp(_ value: Any?) -> Date? {
        guard let string = value as? String else { return nil }
        let fractionalDateFormatter = ISO8601DateFormatter()
        fractionalDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalDateFormatter.date(from: string) {
            return date
        }
        let standardDateFormatter = ISO8601DateFormatter()
        standardDateFormatter.formatOptions = [.withInternetDateTime]
        return standardDateFormatter.date(from: string)
    }
}
