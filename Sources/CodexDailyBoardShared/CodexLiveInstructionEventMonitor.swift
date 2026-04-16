import CodexBarCore
import Foundation

public struct InstructionEventSample: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let timestamp: Date
    public let sentCharacters: Int
    public let sentMessages: Int

    public init(id: String, timestamp: Date, sentCharacters: Int, sentMessages: Int = 1) {
        self.id = id
        self.timestamp = timestamp
        self.sentCharacters = sentCharacters
        self.sentMessages = sentMessages
    }
}

private struct InstructionEventHistoryDocument: Codable, Sendable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var events: [InstructionEventSample]

    init(schemaVersion: Int = Self.currentSchemaVersion, events: [InstructionEventSample] = []) {
        self.schemaVersion = schemaVersion
        self.events = events.sorted { lhs, rhs in
            if lhs.timestamp == rhs.timestamp {
                return lhs.id < rhs.id
            }
            return lhs.timestamp < rhs.timestamp
        }
    }
}

public struct InstructionEventHistoryStore: Sendable {
    public let fileURL: URL

    public init(fileURL: URL = CodexDailyAppIdentity.instructionEventHistoryFileURL) {
        self.fileURL = fileURL
    }

    public func load() throws -> [InstructionEventSample] {
        guard FileManager.default.fileExists(atPath: self.fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: self.fileURL)
        let document = try JSONDecoder().decode(InstructionEventHistoryDocument.self, from: data)
        guard document.schemaVersion == InstructionEventHistoryDocument.currentSchemaVersion else {
            return []
        }
        return document.events.sorted { lhs, rhs in
            if lhs.timestamp == rhs.timestamp {
                return lhs.id < rhs.id
            }
            return lhs.timestamp < rhs.timestamp
        }
    }

    @discardableResult
    public func upsert(samples newSamples: [InstructionEventSample]) throws -> [InstructionEventSample] {
        guard !newSamples.isEmpty else {
            return try self.load()
        }

        var keyed = try Dictionary(uniqueKeysWithValues: self.load().map { ($0.id, $0) })
        for sample in newSamples {
            keyed[sample.id] = sample
        }
        let merged = keyed.values.sorted { lhs, rhs in
            if lhs.timestamp == rhs.timestamp {
                return lhs.id < rhs.id
            }
            return lhs.timestamp < rhs.timestamp
        }
        try self.write(events: merged)
        return merged
    }

    private func write(events: [InstructionEventSample]) throws {
        let directoryURL = self.fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directoryURL.path)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(InstructionEventHistoryDocument(events: events))
        try data.write(to: self.fileURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: self.fileURL.path)
    }
}

public protocol CodexLiveInstructionEventMonitoring: Sendable {
    func sample() async -> [InstructionEventSample]
    func reset() async
}

private struct CodexLiveInstructionCandidate: Sendable {
    enum Source: Int, Sendable {
        case eventMessage = 1
        case responseItem = 2
    }

    let source: Source
    let signature: String
    let event: OutboundMessageUsageEvent

    var sampleID: String {
        "\(Int(self.event.timestamp.timeIntervalSince1970 * 1000))|\(self.signature)"
    }
}

private struct ParsedHumanInstructionContent: Sendable {
    let sentCharacters: Int
    let signature: String
    let hasMeaningfulContent: Bool
}

actor CodexLiveInstructionEventMonitor: CodexLiveInstructionEventMonitoring {
    private struct FileState: Sendable {
        var offset: UInt64
        var pendingFragment = Data()
        var pendingCandidates: [CodexLiveInstructionCandidate] = []
    }

    private static let duplicateInstructionWindow: TimeInterval = 1.0

    private let sessionRootURL: URL
    private let fileManager: FileManager
    private let now: @Sendable () -> Date
    private var fileStates: [String: FileState] = [:]
    private var hasPrimed = false

    init(
        sessionRootURL: URL,
        fileManager: FileManager = .default,
        now: @escaping @Sendable () -> Date = Date.init)
    {
        self.sessionRootURL = sessionRootURL
        self.fileManager = fileManager
        self.now = now
    }

    func reset() async {
        self.fileStates.removeAll()
        self.hasPrimed = false
    }

    func sample() async -> [InstructionEventSample] {
        let sampleTimestamp = self.now()
        let fileURLs = self.sessionFiles()

        if !self.hasPrimed {
            for fileURL in fileURLs {
                self.fileStates[fileURL.path] = FileState(
                    offset: self.fileSize(for: fileURL),
                    pendingFragment: Data(),
                    pendingCandidates: [])
            }
            self.hasPrimed = true
            return []
        }

        let knownPaths = Set(fileURLs.map(\.path))
        self.fileStates = self.fileStates.filter { knownPaths.contains($0.key) }

        let cutoff = sampleTimestamp.addingTimeInterval(-Self.duplicateInstructionWindow)
        var emitted: [InstructionEventSample] = []

        for fileURL in fileURLs {
            let path = fileURL.path
            var state = self.fileStates[path] ?? FileState(offset: 0)
            emitted.append(contentsOf: self.sample(fileURL: fileURL, state: &state, cutoff: cutoff))
            self.fileStates[path] = state
        }

        return emitted.sorted { lhs, rhs in
            if lhs.timestamp == rhs.timestamp {
                return lhs.id < rhs.id
            }
            return lhs.timestamp < rhs.timestamp
        }
    }

    private func sample(fileURL: URL, state: inout FileState, cutoff: Date) -> [InstructionEventSample] {
        let fileSize = self.fileSize(for: fileURL)
        if fileSize < state.offset {
            state = FileState(offset: 0)
        }

        guard fileSize > state.offset else {
            let finalized = self.finalizeCandidates(&state.pendingCandidates, cutoff: cutoff)
            return finalized.map(self.makeSample(from:))
        }

        guard var appendedData = self.readData(
            from: fileURL,
            offset: state.offset,
            length: Int(fileSize - state.offset))
        else {
            state.offset = fileSize
            state.pendingFragment = Data()
            return []
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
        var newCandidates: [CodexLiveInstructionCandidate] = []
        for line in completeLines where !line.isEmpty {
            guard let object = (try? JSONSerialization.jsonObject(with: line)) as? [String: Any] else { continue }
            if let candidate = self.parseHumanInstructionCandidate(from: object) {
                newCandidates.append(candidate)
            }
        }

        state.pendingCandidates.append(contentsOf: newCandidates)
        let finalized = self.finalizeCandidates(&state.pendingCandidates, cutoff: cutoff)
        state.offset = fileSize
        return finalized.map(self.makeSample(from:))
    }

    private func finalizeCandidates(
        _ candidates: inout [CodexLiveInstructionCandidate],
        cutoff: Date)
        -> [CodexLiveInstructionCandidate]
    {
        guard !candidates.isEmpty else { return [] }

        let canonical = self.canonicalOutboundCandidates(from: candidates.sorted(by: { lhs, rhs in
            if lhs.event.timestamp == rhs.event.timestamp {
                return lhs.source.rawValue < rhs.source.rawValue
            }
            return lhs.event.timestamp < rhs.event.timestamp
        }))

        let finalized = canonical.filter { $0.event.timestamp <= cutoff }
        candidates = canonical.filter { $0.event.timestamp > cutoff }
        return finalized
    }

    private func canonicalOutboundCandidates(
        from candidates: [CodexLiveInstructionCandidate])
        -> [CodexLiveInstructionCandidate]
    {
        var canonical: [CodexLiveInstructionCandidate] = []

        for candidate in candidates {
            guard let last = canonical.last else {
                canonical.append(candidate)
                continue
            }

            let isDuplicatePair = last.signature == candidate.signature
                && last.source != candidate.source
                && abs(last.event.timestamp.timeIntervalSince(candidate.event.timestamp))
                <= Self.duplicateInstructionWindow

            if isDuplicatePair {
                if candidate.source.rawValue > last.source.rawValue {
                    canonical[canonical.count - 1] = candidate
                }
                continue
            }

            canonical.append(candidate)
        }

        return canonical
    }

    private func makeSample(from candidate: CodexLiveInstructionCandidate) -> InstructionEventSample {
        InstructionEventSample(
            id: candidate.sampleID,
            timestamp: candidate.event.timestamp,
            sentCharacters: candidate.event.sentCharacters,
            sentMessages: candidate.event.sentMessages)
    }

    private func sessionFiles() -> [URL] {
        var files: [URL] = []
        var seenPaths: Set<String> = []

        for root in self.sessionRoots() where self.fileManager.fileExists(atPath: root.path) {
            let enumerator = self.fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles])

            while let fileURL = enumerator?.nextObject() as? URL {
                guard fileURL.pathExtension.lowercased() == "jsonl" else { continue }
                guard seenPaths.insert(fileURL.path).inserted else { continue }
                files.append(fileURL)
            }
        }

        return files.sorted { $0.path < $1.path }
    }

    private func sessionRoots() -> [URL] {
        if let archivedRoot = Self.archivedSessionsRoot(for: self.sessionRootURL) {
            return [self.sessionRootURL, archivedRoot]
        }
        return [self.sessionRootURL]
    }

    private static func archivedSessionsRoot(for sessionRootURL: URL) -> URL? {
        guard sessionRootURL.lastPathComponent == "sessions" else { return nil }
        return sessionRootURL.deletingLastPathComponent()
            .appendingPathComponent("archived_sessions", isDirectory: true)
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

    private func parseHumanInstructionCandidate(from object: [String: Any]) -> CodexLiveInstructionCandidate? {
        self.parseResponseItemInstructionCandidate(from: object) ?? self
            .parseEventMessageInstructionCandidate(from: object)
    }

    private func parseResponseItemInstructionCandidate(from object: [String: Any]) -> CodexLiveInstructionCandidate? {
        guard (object["type"] as? String) == "response_item",
              let payload = object["payload"] as? [String: Any],
              (payload["type"] as? String) == "message",
              (payload["role"] as? String) == "user",
              let timestampString = object["timestamp"] as? String,
              let timestamp = Self.parseDate(timestampString)
        else {
            return nil
        }

        let content = payload["content"] as? [Any] ?? []
        let extracted = self.extractHumanInstructionContent(fromResponseContent: content)
        guard extracted.hasMeaningfulContent else { return nil }

        return CodexLiveInstructionCandidate(
            source: .responseItem,
            signature: extracted.signature,
            event: OutboundMessageUsageEvent(
                timestamp: timestamp,
                sentCharacters: extracted.sentCharacters,
                sentMessages: 1))
    }

    private func parseEventMessageInstructionCandidate(from object: [String: Any]) -> CodexLiveInstructionCandidate? {
        guard (object["type"] as? String) == "event_msg",
              let payload = object["payload"] as? [String: Any],
              (payload["type"] as? String) == "user_message",
              let timestampString = object["timestamp"] as? String,
              let timestamp = Self.parseDate(timestampString)
        else {
            return nil
        }

        let directMessage = payload["message"] as? String
        let textElements = payload["text_elements"]
        let images = payload["images"]
        let localImages = payload["local_images"]
        let hasImageInput = Self.containsImageEntries(images) || Self.containsImageEntries(localImages)
        let extracted = self.extractHumanInstructionContent(
            directMessage: directMessage,
            textElements: textElements,
            hasImageInput: hasImageInput)
        guard extracted.hasMeaningfulContent else { return nil }

        return CodexLiveInstructionCandidate(
            source: .eventMessage,
            signature: extracted.signature,
            event: OutboundMessageUsageEvent(
                timestamp: timestamp,
                sentCharacters: extracted.sentCharacters,
                sentMessages: 1))
    }

    private func extractHumanInstructionContent(fromResponseContent content: [Any]) -> ParsedHumanInstructionContent {
        let textSegments = content.compactMap { item -> String? in
            guard let dict = item as? [String: Any],
                  (dict["type"] as? String) == "input_text",
                  let text = dict["text"] as? String
            else {
                return nil
            }
            return self.cleanedHumanInstructionText(text)
        }

        let hasImageInput = content.contains { item in
            guard let dict = item as? [String: Any],
                  let type = dict["type"] as? String
            else {
                return false
            }
            return type == "input_image" || type == "local_image"
        }

        return self.makeParsedHumanInstructionContent(textSegments: textSegments, hasImageInput: hasImageInput)
    }

    private func extractHumanInstructionContent(
        directMessage: String?,
        textElements: Any?,
        hasImageInput: Bool)
        -> ParsedHumanInstructionContent
    {
        let cleanedDirectMessage = directMessage.flatMap(self.cleanedHumanInstructionText)
        let textSegments: [String] = if let cleanedDirectMessage, !cleanedDirectMessage.isEmpty {
            [cleanedDirectMessage]
        } else {
            self.textElementStrings(from: textElements).compactMap(self.cleanedHumanInstructionText)
        }

        return self.makeParsedHumanInstructionContent(textSegments: textSegments, hasImageInput: hasImageInput)
    }

    private func makeParsedHumanInstructionContent(
        textSegments: [String],
        hasImageInput: Bool)
        -> ParsedHumanInstructionContent
    {
        let combinedText = textSegments.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedText = self.normalizedInstructionSignatureText(combinedText)
        let hasMeaningfulContent = !normalizedText.isEmpty || hasImageInput
        let signature = "\(normalizedText)|image:\(hasImageInput ? 1 : 0)"
        return ParsedHumanInstructionContent(
            sentCharacters: combinedText.count,
            signature: signature,
            hasMeaningfulContent: hasMeaningfulContent)
    }

    private func cleanedHumanInstructionText(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !trimmed.hasPrefix("# AGENTS.md instructions") else { return nil }
        guard !trimmed.hasPrefix("<environment_context>") else { return nil }
        guard !trimmed.hasPrefix("<turn_aborted>") else { return nil }

        let lines = trimmed.components(separatedBy: .newlines)
        let filteredLines = lines.compactMap { rawLine -> String? in
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { return "" }
            guard !self.isImageWrapperLine(line) else { return nil }
            return rawLine
        }

        let cleaned = filteredLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    private func isImageWrapperLine(_ line: String) -> Bool {
        if line == "</image>" {
            return true
        }
        guard line.hasPrefix("<image") else { return false }
        return line.hasSuffix(">")
    }

    private func normalizedInstructionSignatureText(_ text: String) -> String {
        text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func containsImageEntries(_ value: Any?) -> Bool {
        switch value {
        case let values as [Any]:
            !values.isEmpty
        case let value as String:
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case let dict as [String: Any]:
            !dict.isEmpty
        default:
            false
        }
    }

    private func textElementStrings(from value: Any?) -> [String] {
        switch value {
        case let text as String:
            return [text]
        case let values as [Any]:
            return values.reduce(into: [String]()) { partialResult, entry in
                partialResult.append(contentsOf: self.textElementStrings(from: entry))
            }
        case let dict as [String: Any]:
            if let text = dict["text"] as? String {
                return [text]
            }
            if let text = dict["value"] as? String {
                return [text]
            }
            if let text = dict["content"] as? String {
                return [text]
            }
            return []
        default:
            return []
        }
    }

    private static func parseDate(_ string: String) -> Date? {
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
