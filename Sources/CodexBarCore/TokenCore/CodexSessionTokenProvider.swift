import Foundation
import Logging

public struct CodexSessionTokenProvider: Sendable {
    private static let currentScanVersion = 11
    private static let duplicateInstructionWindow: TimeInterval = 1.0

    public let sessionRootURL: URL
    public let calendar: Calendar
    public let historyStore: TokenHistoryStore

    private let logger = Logger(label: "CodexBar.CodexSessionTokenProvider")

    public init(
        sessionRootURL: URL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(
            ".codex/sessions",
            isDirectory: true),
        calendar: Calendar = .autoupdatingCurrent,
        historyStore: TokenHistoryStore = TokenHistoryStore())
    {
        self.sessionRootURL = sessionRootURL
        self.calendar = calendar
        self.historyStore = historyStore
    }

    public func refresh() throws -> TokenRefreshResult {
        try self.scan(preserveMissingHistory: true)
    }

    public func rebuild() throws -> TokenRefreshResult {
        try self.scan(preserveMissingHistory: false)
    }

    private func scan(preserveMissingHistory: Bool) throws -> TokenRefreshResult {
        let cachedDocument = try preserveMissingHistory ? (self.historyStore.load()) : .empty
        let cachedSessions = cachedDocument.sessions
        let sessionIDBySourceFile = Dictionary(
            uniqueKeysWithValues: cachedDocument.sessions.values.map { ($0.sourceFile, $0.sessionID) })
        var sourceFileBySessionID = Dictionary(
            uniqueKeysWithValues: cachedDocument.sessions.values.map { ($0.sessionID, $0.sourceFile) })
        var currentSessions: [String: SessionUsageSnapshot] = [:]
        var scannedSourceFiles: Set<String> = []
        var seenSessionIDs: Set<String> = []
        var seenFileIdentities: Set<String> = []

        var errors: [String] = []
        var reusedSessionCount = 0
        let files = self.sessionFiles()

        for fileURL in files {
            scannedSourceFiles.insert(fileURL.path)
            let metadata: SourceFileMetadata
            do {
                metadata = try self.metadata(for: fileURL)
            } catch {
                let message = "Failed to read metadata for \(fileURL.lastPathComponent): \(error.localizedDescription)"
                self.logger.error("\(message)")
                errors.append(message)
                continue
            }

            if let fileIdentity = metadata.fileIdentity,
               seenFileIdentities.contains(fileIdentity)
            {
                continue
            }

            if let cachedSessionID = sessionIDBySourceFile[fileURL.path],
               let cachedSnapshot = cachedSessions[cachedSessionID],
               self.matchesCachedSnapshot(cachedSnapshot, metadata: metadata)
            {
                guard seenSessionIDs.insert(cachedSnapshot.sessionID).inserted else {
                    continue
                }
                reusedSessionCount += 1
                currentSessions[cachedSnapshot.sessionID] = cachedSnapshot
                sourceFileBySessionID[cachedSnapshot.sessionID] = cachedSnapshot.sourceFile
                if let fileIdentity = metadata.fileIdentity {
                    seenFileIdentities.insert(fileIdentity)
                }
                continue
            }

            do {
                let parsedFile = try self.parseSessionFile(
                    at: fileURL,
                    metadata: metadata,
                    sourceFileBySessionID: sourceFileBySessionID)
                errors.append(contentsOf: parsedFile.warnings)

                guard let parsedSnapshot = parsedFile.snapshot else {
                    continue
                }

                guard seenSessionIDs.insert(parsedSnapshot.sessionID).inserted else {
                    continue
                }

                currentSessions[parsedSnapshot.sessionID] = parsedSnapshot
                sourceFileBySessionID[parsedSnapshot.sessionID] = parsedSnapshot.sourceFile
                if let fileIdentity = metadata.fileIdentity {
                    seenFileIdentities.insert(fileIdentity)
                }
            } catch {
                let message = "Failed to parse \(fileURL.lastPathComponent): \(error.localizedDescription)"
                self.logger.error("\(message)")
                errors.append(message)
            }
        }

        var sessions = preserveMissingHistory
            ? cachedSessions.filter { !scannedSourceFiles.contains($0.value.sourceFile) }
            : [:]
        for snapshot in currentSessions.values {
            sessions[snapshot.sessionID] = snapshot
        }

        let snapshots = Array(sessions.values)
        let days = self.aggregateDays(from: snapshots)
        let hours = self.aggregateHours(from: snapshots)
        let fiveMinuteBuckets = self.aggregateFiveMinuteBuckets(from: snapshots)
        let outboundMessageDays = self.aggregateOutboundMessageDays(from: snapshots)
        return TokenRefreshResult(
            sessions: sessions,
            days: days,
            hours: hours,
            fiveMinuteBuckets: fiveMinuteBuckets,
            outboundMessageDays: outboundMessageDays,
            refreshedAt: Date(),
            scannedFileCount: files.count,
            reusedSessionCount: reusedSessionCount,
            errors: errors)
    }

    private func sessionFiles() -> [URL] {
        var files: [URL] = []
        var seenPaths: Set<String> = []

        for root in self.sessionRoots() where FileManager.default.fileExists(atPath: root.path) {
            let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles])

            var rootFiles: [URL] = []
            while let fileURL = enumerator?.nextObject() as? URL {
                guard fileURL.pathExtension == "jsonl" else { continue }
                rootFiles.append(fileURL)
            }

            for fileURL in rootFiles.sorted(by: { $0.path < $1.path })
                where seenPaths.insert(fileURL.path).inserted
            {
                files.append(fileURL)
            }
        }

        return files
    }

    private func sessionRoots() -> [URL] {
        if let archivedRoot = Self.archivedSessionsRoot(for: self.sessionRootURL) {
            return [self.sessionRootURL, archivedRoot]
        }
        return [self.sessionRootURL]
    }

    private static func archivedSessionsRoot(for sessionRootURL: URL) -> URL? {
        guard sessionRootURL.lastPathComponent == "sessions" else { return nil }
        return sessionRootURL
            .deletingLastPathComponent()
            .appendingPathComponent("archived_sessions", isDirectory: true)
    }

    private func fileIdentityString(for fileURL: URL) -> String? {
        guard let values = try? fileURL.resourceValues(forKeys: [.fileResourceIdentifierKey]) else { return nil }
        guard let identifier = values.fileResourceIdentifier else { return nil }
        if let data = identifier as? Data {
            return data.base64EncodedString()
        }
        return String(describing: identifier)
    }

    private func metadata(for fileURL: URL) throws -> SourceFileMetadata {
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let size = (attributes[.size] as? NSNumber)?.int64Value
        let modifiedAt = attributes[.modificationDate] as? Date
        return SourceFileMetadata(
            fileSize: size,
            modificationDate: modifiedAt,
            sourceFile: fileURL.path,
            fileIdentity: self.fileIdentityString(for: fileURL))
    }

    private func matchesCachedSnapshot(_ snapshot: SessionUsageSnapshot, metadata: SourceFileMetadata) -> Bool {
        guard snapshot.sourceFile == metadata.sourceFile else { return false }
        guard snapshot.sourceFileSize == metadata.fileSize else { return false }
        guard snapshot.scanVersion == Self.currentScanVersion else { return false }

        switch (snapshot.sourceFileModificationTime, metadata.modificationDate) {
        case (nil, nil):
            return true
        case let (lhs?, rhs?):
            return abs(lhs.timeIntervalSince1970 - rhs.timeIntervalSince1970) < 0.001
        default:
            return false
        }
    }

    private func parseSessionFile(
        at fileURL: URL,
        metadata: SourceFileMetadata,
        sourceFileBySessionID: [String: String])
        throws -> ParsedSessionFile
    {
        let raw = try String(contentsOf: fileURL, encoding: .utf8)
        let lines = self.nonEmptyLines(from: raw)
        let initialMetadata = self.initialSessionMetadata(from: lines)
        let sessionID = initialMetadata?.sessionID ?? fileURL.path
        let sessionOriginKind = initialMetadata?.sessionOriginKind ?? .regular
        var warnings: [String] = []
        var dayBuckets: [String: DailyTokenStats] = [:]
        var hourBuckets: [Date: HourlyTokenStats] = [:]
        var fiveMinuteBuckets: [Date: FiveMinuteTokenStats] = [:]
        var outboundMessageDayBuckets: [String: DailyOutboundMessageStats] = [:]
        var instructionCandidates: [HumanInstructionCandidate] = []
        var seenTokenCountFingerprints: Set<String> = []
        var runningTokenTotals: RunningTokenTotals?
        var lastEventAt: Date?
        let parseLines: [String]

        if let initialMetadata,
           let forkedFromSessionID = initialMetadata.forkedFromSessionID
        {
            guard let parentSourceFile = sourceFileBySessionID[forkedFromSessionID],
                  FileManager.default.fileExists(atPath: parentSourceFile)
            else {
                let message = "Skipping forked session \(sessionID) from \(fileURL.lastPathComponent): parent session \(forkedFromSessionID) source file is unavailable"
                self.logger.warning("\(message)")
                warnings.append(message)
                return ParsedSessionFile(snapshot: nil, warnings: warnings)
            }

            let parentRaw = try String(contentsOf: URL(fileURLWithPath: parentSourceFile), encoding: .utf8)
            let childReplayLines = Array(lines.dropFirst(initialMetadata.lineIndex + 1))
            let parentLines = self.nonEmptyLines(from: parentRaw)
            let replayPrefixLength = self.sharedReplayPrefixLength(
                childReplayLines: childReplayLines,
                parentLines: parentLines)

            guard replayPrefixLength > 0 else {
                let message = "Skipping forked session \(sessionID) from \(fileURL.lastPathComponent): failed to resolve replay prefix against parent session \(forkedFromSessionID)"
                self.logger.warning("\(message)")
                warnings.append(message)
                return ParsedSessionFile(snapshot: nil, warnings: warnings)
            }

            parseLines = Array(childReplayLines.dropFirst(replayPrefixLength))
        } else {
            parseLines = lines
        }

        for line in parseLines {
            guard let payload = self.parseJSONObject(from: line) else { continue }

            if let tokenCountFingerprint = self.parseTokenCountFingerprint(from: payload) {
                guard seenTokenCountFingerprints.insert(tokenCountFingerprint).inserted else {
                    continue
                }
            }

            if let event = self.parseTokenEvent(from: payload, runningTokenTotals: &runningTokenTotals) {
                let dayKey = DailyTokenStats.dayKey(for: event.timestamp, calendar: self.calendar)
                var bucket = dayBuckets[dayKey] ?? DailyTokenStats.empty(for: dayKey)
                bucket.add(event)
                dayBuckets[dayKey] = bucket
                let hourStart = HourlyTokenStats.hourStart(for: event.timestamp, calendar: self.calendar)
                var hourBucket = hourBuckets[hourStart] ?? HourlyTokenStats.empty(for: hourStart)
                hourBucket.add(event)
                hourBuckets[hourStart] = hourBucket
                let bucketStart = FiveMinuteTokenStats.bucketStart(for: event.timestamp, calendar: self.calendar)
                var fiveMinuteBucket = fiveMinuteBuckets[bucketStart] ?? FiveMinuteTokenStats.empty(for: bucketStart)
                fiveMinuteBucket.add(event)
                fiveMinuteBuckets[bucketStart] = fiveMinuteBucket
                if lastEventAt == nil || event.timestamp > lastEventAt ?? .distantPast {
                    lastEventAt = event.timestamp
                }
            }

            if let instructionCandidate = self.parseHumanInstructionCandidate(from: payload) {
                instructionCandidates.append(instructionCandidate)
                if lastEventAt == nil || instructionCandidate.event.timestamp > lastEventAt ?? .distantPast {
                    lastEventAt = instructionCandidate.event.timestamp
                }
            }
        }

        if sessionOriginKind != .subagentThreadSpawn {
            for outboundEvent in self.canonicalOutboundEvents(from: instructionCandidates) {
                let dayKey = DailyTokenStats.dayKey(for: outboundEvent.timestamp, calendar: self.calendar)
                var bucket = outboundMessageDayBuckets[dayKey] ?? DailyOutboundMessageStats.empty(for: dayKey)
                bucket.add(outboundEvent)
                outboundMessageDayBuckets[dayKey] = bucket
            }
        }

        guard !dayBuckets.isEmpty || !outboundMessageDayBuckets.isEmpty else {
            return ParsedSessionFile(snapshot: nil, warnings: warnings)
        }

        let snapshot = SessionUsageSnapshot(
            sessionID: sessionID,
            sessionOriginKind: sessionOriginKind,
            sourceFile: fileURL.path,
            sourceFileSize: metadata.fileSize,
            sourceFileModificationTime: metadata.modificationDate,
            lastEventAt: lastEventAt,
            scanVersion: Self.currentScanVersion,
            dailyBuckets: dayBuckets.values.sorted { $0.date < $1.date },
            hourlyBuckets: hourBuckets.values.sorted { $0.hourStart < $1.hourStart },
            fiveMinuteBuckets: fiveMinuteBuckets.values.sorted { $0.bucketStart < $1.bucketStart },
            outboundMessageDailyBuckets: outboundMessageDayBuckets.values.sorted { $0.date < $1.date })
        return ParsedSessionFile(snapshot: snapshot, warnings: warnings)
    }

    private func aggregateDays(from sessions: [SessionUsageSnapshot]) -> [DailyTokenStats] {
        var days: [String: DailyTokenStats] = [:]
        for snapshot in sessions {
            for bucket in snapshot.dailyBuckets {
                var existing = days[bucket.date] ?? DailyTokenStats.empty(for: bucket.date)
                existing.merge(bucket)
                days[bucket.date] = existing
            }
        }

        return days.values.sorted { $0.date < $1.date }
    }

    private func aggregateHours(from sessions: [SessionUsageSnapshot]) -> [HourlyTokenStats] {
        var hours: [Date: HourlyTokenStats] = [:]
        for snapshot in sessions {
            for bucket in snapshot.hourlyBuckets {
                var existing = hours[bucket.hourStart] ?? HourlyTokenStats.empty(for: bucket.hourStart)
                existing.merge(bucket)
                hours[bucket.hourStart] = existing
            }
        }

        return hours.values.sorted { $0.hourStart < $1.hourStart }
    }

    private func aggregateFiveMinuteBuckets(from sessions: [SessionUsageSnapshot]) -> [FiveMinuteTokenStats] {
        var buckets: [Date: FiveMinuteTokenStats] = [:]
        for snapshot in sessions {
            for bucket in snapshot.fiveMinuteBuckets {
                var existing = buckets[bucket.bucketStart] ?? FiveMinuteTokenStats.empty(for: bucket.bucketStart)
                existing.merge(bucket)
                buckets[bucket.bucketStart] = existing
            }
        }

        return buckets.values.sorted { $0.bucketStart < $1.bucketStart }
    }

    private func aggregateOutboundMessageDays(from sessions: [SessionUsageSnapshot]) -> [DailyOutboundMessageStats] {
        var days: [String: DailyOutboundMessageStats] = [:]
        for snapshot in sessions {
            for bucket in snapshot.outboundMessageDailyBuckets {
                var existing = days[bucket.date] ?? DailyOutboundMessageStats.empty(for: bucket.date)
                existing.merge(bucket)
                days[bucket.date] = existing
            }
        }

        return days.values.sorted { $0.date < $1.date }
    }

    private func parseJSONObject(from line: String) -> [String: Any]? {
        guard let data = line.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        return object
    }

    private func initialSessionMetadata(from lines: [String]) -> InitialSessionMetadata? {
        for (index, line) in lines.enumerated() {
            guard let object = self.parseJSONObject(from: line),
                  (object["type"] as? String) == "session_meta",
                  let payload = object["payload"] as? [String: Any],
                  let sessionID = payload["id"] as? String,
                  !sessionID.isEmpty
            else {
                continue
            }

            let forkedFromSessionID = (payload["forked_from_id"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let sessionOriginKind = self.sessionOriginKind(from: payload["source"])
            return InitialSessionMetadata(
                sessionID: sessionID,
                forkedFromSessionID: forkedFromSessionID?.isEmpty == false ? forkedFromSessionID : nil,
                sessionOriginKind: sessionOriginKind,
                lineIndex: index)
        }

        return nil
    }

    private func nonEmptyLines(from raw: String) -> [String] {
        raw.split(whereSeparator: \.isNewline).map(String.init)
    }

    private func sessionOriginKind(from sourceValue: Any?) -> SessionOriginKind {
        guard let source = sourceValue as? [String: Any],
              let subagent = source["subagent"] as? [String: Any],
              subagent["thread_spawn"] as? [String: Any] != nil
        else {
            return .regular
        }
        return .subagentThreadSpawn
    }

    private func sharedReplayPrefixLength(childReplayLines: [String], parentLines: [String]) -> Int {
        let limit = min(childReplayLines.count, parentLines.count)
        var count = 0

        for index in 0..<limit {
            guard let childLine = self.normalizedReplayLine(childReplayLines[index]),
                  let parentLine = self.normalizedReplayLine(parentLines[index]),
                  childLine == parentLine
            else {
                break
            }
            count += 1
        }

        return count
    }

    private func normalizedReplayLine(_ line: String) -> String? {
        guard var object = self.parseJSONObject(from: line) else {
            return nil
        }

        object.removeValue(forKey: "timestamp")
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]),
              let string = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return string
    }

    private func parseTokenEvent(
        from object: [String: Any],
        runningTokenTotals: inout RunningTokenTotals?)
        -> TokenUsageEvent?
    {
        guard (object["type"] as? String) == "event_msg",
              let payload = object["payload"] as? [String: Any],
              (payload["type"] as? String) == "token_count",
              let info = payload["info"] as? [String: Any],
              let timestampString = object["timestamp"] as? String,
              let timestamp = Self.parseDate(timestampString)
        else {
            return nil
        }

        if let totalUsage = info["total_token_usage"] as? [String: Any] {
            let currentTotals = RunningTokenTotals(
                inputTokens: max(0, self.integerValue(totalUsage["input_tokens"])),
                outputTokens: max(0, self.integerValue(totalUsage["output_tokens"])),
                cachedInputTokens: max(
                    0,
                    self.integerValue(totalUsage["cached_input_tokens"] ?? totalUsage["cache_read_input_tokens"])),
                reasoningOutputTokens: max(0, self.integerValue(totalUsage["reasoning_output_tokens"])))
            let previousTotals = runningTokenTotals ?? .zero
            runningTokenTotals = currentTotals

            let deltaInputTokens = max(0, currentTotals.inputTokens - previousTotals.inputTokens)
            let deltaOutputTokens = max(0, currentTotals.outputTokens - previousTotals.outputTokens)
            let deltaCachedInputTokens = max(
                0,
                currentTotals.cachedInputTokens - previousTotals.cachedInputTokens)
            let deltaReasoningOutputTokens = max(
                0,
                currentTotals.reasoningOutputTokens - previousTotals.reasoningOutputTokens)

            if deltaInputTokens == 0,
               deltaOutputTokens == 0,
               deltaCachedInputTokens == 0,
               deltaReasoningOutputTokens == 0
            {
                return nil
            }

            return TokenUsageEvent(
                timestamp: timestamp,
                inputTokens: deltaInputTokens,
                outputTokens: deltaOutputTokens,
                cachedInputTokens: min(deltaCachedInputTokens, deltaInputTokens),
                reasoningOutputTokens: deltaReasoningOutputTokens,
                totalTokens: deltaInputTokens + deltaOutputTokens)
        }

        guard let lastUsage = info["last_token_usage"] as? [String: Any] else {
            return nil
        }

        let inputTokens = max(0, self.integerValue(lastUsage["input_tokens"]))
        let outputTokens = max(0, self.integerValue(lastUsage["output_tokens"]))
        let cachedInputTokens = max(
            0,
            self.integerValue(lastUsage["cached_input_tokens"] ?? lastUsage["cache_read_input_tokens"]))
        let reasoningOutputTokens = max(0, self.integerValue(lastUsage["reasoning_output_tokens"]))

        if inputTokens == 0,
           outputTokens == 0,
           cachedInputTokens == 0,
           reasoningOutputTokens == 0
        {
            return nil
        }

        return TokenUsageEvent(
            timestamp: timestamp,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cachedInputTokens: min(cachedInputTokens, inputTokens),
            reasoningOutputTokens: reasoningOutputTokens,
            totalTokens: inputTokens + outputTokens)
    }

    private func parseTokenCountFingerprint(from object: [String: Any]) -> String? {
        guard (object["type"] as? String) == "event_msg",
              let payload = object["payload"] as? [String: Any],
              (payload["type"] as? String) == "token_count",
              let info = payload["info"] as? [String: Any],
              let timestampString = object["timestamp"] as? String
        else {
            return nil
        }

        var canonicalObject: [String: Any] = ["timestamp": timestampString]

        if let lastUsage = info["last_token_usage"] {
            canonicalObject["last_token_usage"] = lastUsage
        }
        if let totalUsage = info["total_token_usage"] {
            canonicalObject["total_token_usage"] = totalUsage
        }
        if let modelContextWindow = info["model_context_window"] {
            canonicalObject["model_context_window"] = modelContextWindow
        }

        guard JSONSerialization.isValidJSONObject(canonicalObject),
              let data = try? JSONSerialization.data(withJSONObject: canonicalObject, options: [.sortedKeys]),
              let fingerprint = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return fingerprint
    }

    private func parseHumanInstructionCandidate(from object: [String: Any]) -> HumanInstructionCandidate? {
        self.parseResponseItemInstructionCandidate(from: object) ?? self
            .parseEventMessageInstructionCandidate(from: object)
    }

    private func parseResponseItemInstructionCandidate(from object: [String: Any]) -> HumanInstructionCandidate? {
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
        return HumanInstructionCandidate(
            source: .responseItem,
            signature: extracted.signature,
            event: OutboundMessageUsageEvent(
                timestamp: timestamp,
                sentCharacters: extracted.sentCharacters,
                sentMessages: 1))
    }

    private func parseEventMessageInstructionCandidate(from object: [String: Any]) -> HumanInstructionCandidate? {
        guard (object["type"] as? String) == "event_msg",
              let payload = object["payload"] as? [String: Any],
              (payload["type"] as? String) == "user_message",
              let timestampString = object["timestamp"] as? String,
              let timestamp = Self.parseDate(timestampString)
        else {
            return nil
        }

        let extracted = self.extractHumanInstructionContent(
            directMessage: payload["message"] as? String,
            textElements: payload["text_elements"],
            hasImageInput: self.containsImageEntries(payload["images"]) || self
                .containsImageEntries(payload["local_images"]))
        guard extracted.hasMeaningfulContent else { return nil }
        return HumanInstructionCandidate(
            source: .eventMessage,
            signature: extracted.signature,
            event: OutboundMessageUsageEvent(
                timestamp: timestamp,
                sentCharacters: extracted.sentCharacters,
                sentMessages: 1))
    }

    private func integerValue(_ value: Any?) -> Int {
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

    private func canonicalOutboundEvents(from candidates: [HumanInstructionCandidate]) -> [OutboundMessageUsageEvent] {
        var canonical: [HumanInstructionCandidate] = []

        for candidate in candidates {
            guard let last = canonical.last else {
                canonical.append(candidate)
                continue
            }

            let isDuplicatePair = last.signature == candidate.signature
                && last.source != candidate.source
                && abs(last.event.timestamp.timeIntervalSince(candidate.event.timestamp)) <= Self
                .duplicateInstructionWindow

            if isDuplicatePair {
                if candidate.source.priority > last.source.priority {
                    canonical[canonical.count - 1] = candidate
                }
                continue
            }

            canonical.append(candidate)
        }

        return canonical.map(\.event)
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
        text.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func containsImageEntries(_ value: Any?) -> Bool {
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

private struct SourceFileMetadata {
    let fileSize: Int64?
    let modificationDate: Date?
    let sourceFile: String
    let fileIdentity: String?
}

private struct ParsedSessionFile {
    let snapshot: SessionUsageSnapshot?
    let warnings: [String]
}

private struct InitialSessionMetadata {
    let sessionID: String
    let forkedFromSessionID: String?
    let sessionOriginKind: SessionOriginKind
    let lineIndex: Int
}

private struct ParsedHumanInstructionContent {
    let sentCharacters: Int
    let signature: String
    let hasMeaningfulContent: Bool
}

private struct RunningTokenTotals {
    let inputTokens: Int
    let outputTokens: Int
    let cachedInputTokens: Int
    let reasoningOutputTokens: Int

    static let zero = RunningTokenTotals(
        inputTokens: 0,
        outputTokens: 0,
        cachedInputTokens: 0,
        reasoningOutputTokens: 0)
}

private struct HumanInstructionCandidate {
    enum Source {
        case responseItem
        case eventMessage

        var priority: Int {
            switch self {
            case .responseItem:
                2
            case .eventMessage:
                1
            }
        }
    }

    let source: Source
    let signature: String
    let event: OutboundMessageUsageEvent
}
