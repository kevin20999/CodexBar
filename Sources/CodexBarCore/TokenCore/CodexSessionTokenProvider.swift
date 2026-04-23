import Foundation
import Logging

public struct TokenStatisticsMigrationStatus: Sendable, Equatable {
    public let isPending: Bool
    public let pendingFileCount: Int

    public init(isPending: Bool, pendingFileCount: Int) {
        self.isPending = isPending
        self.pendingFileCount = pendingFileCount
    }
}

public struct CodexSessionTokenProvider: Sendable {
    private static let currentScanVersion = 11
    private static let duplicateInstructionWindow: TimeInterval = 1.0
    private static let persistedTokenCountFingerprintLimit = 16

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

    public func statisticsMigrationStatus() -> TokenStatisticsMigrationStatus {
        let cachedDocument = (try? self.historyStore.load()) ?? .empty
        let pendingFiles = self.migrationCandidateFiles(cachedDocument: cachedDocument)
        return TokenStatisticsMigrationStatus(
            isPending: !pendingFiles.isEmpty,
            pendingFileCount: pendingFiles.count)
    }

    public func refreshMigrationBatch(maxRuntime: Duration) throws -> TokenRefreshResult {
        let cachedDocument = (try? self.historyStore.load()) ?? .empty
        let pendingFiles = self.migrationCandidateFiles(cachedDocument: cachedDocument)
        guard !pendingFiles.isEmpty else {
            return try self.scan(preserveMissingHistory: true, files: [])
        }

        let deadline = ContinuousClock().now + maxRuntime
        return try self.scan(
            preserveMissingHistory: true,
            files: pendingFiles,
            stopAfterProcessingDeadline: deadline)
    }

    private func scan(
        preserveMissingHistory: Bool,
        files requestedFiles: [URL]? = nil,
        stopAfterProcessingDeadline: ContinuousClock.Instant? = nil)
        throws -> TokenRefreshResult
    {
        let cachedDocument = preserveMissingHistory ? ((try? self.historyStore.load()) ?? .empty) : .empty
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
        var tailScannedSessionCount = 0
        let files = requestedFiles ?? self.sessionFiles()
        let clock = ContinuousClock()
        var processedFileCount = 0

        for fileURL in files {
            processedFileCount += 1
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

            if let cachedSessionID = sessionIDBySourceFile[fileURL.path],
               let cachedSnapshot = cachedSessions[cachedSessionID]
            {
                if let stopAfterProcessingDeadline,
                   self.needsIncrementalMetadataMigration(cachedSnapshot, metadata: metadata)
                {
                    do {
                        let parsedFile = try self.migrateCachedSnapshotMetadataChunk(
                            at: fileURL,
                            metadata: metadata,
                            cachedSnapshot: cachedSnapshot,
                            deadline: stopAfterProcessingDeadline)
                        errors.append(contentsOf: parsedFile.warnings)

                        if let parsedSnapshot = parsedFile.snapshot,
                           seenSessionIDs.insert(parsedSnapshot.sessionID).inserted
                        {
                            currentSessions[parsedSnapshot.sessionID] = parsedSnapshot
                            sourceFileBySessionID[parsedSnapshot.sessionID] = parsedSnapshot.sourceFile
                            if let fileIdentity = metadata.fileIdentity ?? parsedSnapshot.sourceFileIdentity {
                                seenFileIdentities.insert(fileIdentity)
                            }
                        }

                        if clock.now >= stopAfterProcessingDeadline {
                            break
                        }

                        continue
                    } catch {
                        let message =
                            "Failed migration batch for \(fileURL.lastPathComponent): \(error.localizedDescription)"
                        self.logger.error("\(message)")
                        errors.append(message)
                    }
                }

                do {
                    if let parsedFile = try self.parseSessionFileIncrementallyIfPossible(
                        at: fileURL,
                        metadata: metadata,
                        cachedSnapshot: cachedSnapshot)
                    {
                        errors.append(contentsOf: parsedFile.warnings)

                        guard let parsedSnapshot = parsedFile.snapshot else {
                            continue
                        }

                        guard seenSessionIDs.insert(parsedSnapshot.sessionID).inserted else {
                            continue
                        }

                        tailScannedSessionCount += 1
                        currentSessions[parsedSnapshot.sessionID] = parsedSnapshot
                        sourceFileBySessionID[parsedSnapshot.sessionID] = parsedSnapshot.sourceFile
                        if let fileIdentity = metadata.fileIdentity ?? parsedSnapshot.sourceFileIdentity {
                            seenFileIdentities.insert(fileIdentity)
                        }
                        continue
                    }
                } catch {
                    let message = "Failed incremental parse for \(fileURL.lastPathComponent): \(error.localizedDescription)"
                    self.logger.error("\(message)")
                    errors.append(message)
                }
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

            if let stopAfterProcessingDeadline,
               clock.now >= stopAfterProcessingDeadline
            {
                break
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
            scannedFileCount: processedFileCount,
            reusedSessionCount: reusedSessionCount,
            tailScannedSessionCount: tailScannedSessionCount,
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

    private func migrationCandidateFiles(cachedDocument: TokenHistoryDocument) -> [URL] {
        let cachedSessions = cachedDocument.sessions
        let sessionIDBySourceFile = Dictionary(
            uniqueKeysWithValues: cachedSessions.values.map { ($0.sourceFile, $0.sessionID) })
        var candidates: [MigrationCandidate] = []

        for fileURL in self.sessionFiles() {
            let metadata = (try? self.metadata(for: fileURL)) ?? SourceFileMetadata(
                fileSize: nil,
                modificationDate: nil,
                sourceFile: fileURL.path,
                fileIdentity: nil)
            let isForkedReplay = ((try? self.initialSessionMetadata(at: fileURL))?.forkedFromSessionID) != nil

            let priority: Int
            if let cachedSessionID = sessionIDBySourceFile[fileURL.path],
               let cachedSnapshot = cachedSessions[cachedSessionID]
            {
                if self.needsIncrementalMetadataMigration(cachedSnapshot, metadata: metadata) {
                    priority = 1
                } else if cachedSnapshot.scanVersion != Self.currentScanVersion {
                    priority = 2
                } else {
                    continue
                }
            } else {
                priority = 0
            }

            candidates.append(MigrationCandidate(
                fileURL: fileURL,
                priority: priority,
                isForkedReplay: isForkedReplay,
                modificationDate: metadata.modificationDate ?? .distantPast))
        }

        candidates.sort { (lhs: MigrationCandidate, rhs: MigrationCandidate) in
            if lhs.priority != rhs.priority {
                return lhs.priority < rhs.priority
            }
            if lhs.isForkedReplay != rhs.isForkedReplay {
                return rhs.isForkedReplay
            }
            if lhs.modificationDate != rhs.modificationDate {
                return lhs.modificationDate > rhs.modificationDate
            }
            return lhs.fileURL.path < rhs.fileURL.path
        }

        return candidates.map(\.fileURL)
    }

    private func needsIncrementalMetadataMigration(
        _ snapshot: SessionUsageSnapshot,
        metadata: SourceFileMetadata)
        -> Bool
    {
        if snapshot.incrementalMigrationProgress != nil {
            return true
        }
        if snapshot.lastScannedByteOffset == nil {
            return true
        }
        if snapshot.runningTokenTotals == nil {
            return true
        }
        if snapshot.sourceFileIdentity == nil, metadata.fileIdentity != nil {
            return true
        }
        return false
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
        guard snapshot.incrementalMigrationProgress == nil else { return false }
        guard snapshot.sourceFile == metadata.sourceFile else { return false }
        guard snapshot.sourceFileSize == metadata.fileSize else { return false }
        guard snapshot.scanVersion == Self.currentScanVersion else { return false }
        if snapshot.sourceFileIdentity != metadata.fileIdentity,
           snapshot.sourceFileIdentity != nil || metadata.fileIdentity != nil
        {
            return false
        }

        switch (snapshot.sourceFileModificationTime, metadata.modificationDate) {
        case (nil, nil):
            return true
        case let (lhs?, rhs?):
            return abs(lhs.timeIntervalSince1970 - rhs.timeIntervalSince1970) < 0.001
        default:
            return false
        }
    }

    private func parseSessionFileIncrementallyIfPossible(
        at fileURL: URL,
        metadata: SourceFileMetadata,
        cachedSnapshot: SessionUsageSnapshot)
        throws -> ParsedSessionFile?
    {
        guard cachedSnapshot.incrementalMigrationProgress == nil else { return nil }
        guard cachedSnapshot.sourceFile == metadata.sourceFile else { return nil }
        guard cachedSnapshot.scanVersion == Self.currentScanVersion else { return nil }
        guard let previousFileSize = cachedSnapshot.sourceFileSize,
              let currentFileSize = metadata.fileSize,
              currentFileSize > previousFileSize
        else {
            return nil
        }
        guard let lastScannedByteOffset = cachedSnapshot.lastScannedByteOffset,
              lastScannedByteOffset >= 0,
              lastScannedByteOffset <= currentFileSize
        else {
            return nil
        }
        guard cachedSnapshot.runningTokenTotals != nil else { return nil }
        if cachedSnapshot.sourceFileIdentity != metadata.fileIdentity,
           cachedSnapshot.sourceFileIdentity != nil || metadata.fileIdentity != nil
        {
            return nil
        }

        if let initialMetadata = try self.initialSessionMetadata(at: fileURL) {
            guard initialMetadata.forkedFromSessionID == nil else { return nil }
            guard initialMetadata.sessionID == cachedSnapshot.sessionID else { return nil }
            guard initialMetadata.sessionOriginKind == cachedSnapshot.sessionOriginKind else { return nil }
        }

        var state = ParsedSessionState(snapshot: cachedSnapshot)
        let progress = try self.forEachNonEmptyLine(at: fileURL, startOffset: lastScannedByteOffset) { line, _ in
            self.processParsedLine(line, into: &state)
            return true
        }

        return self.makeParsedSessionFile(
            fileURL: fileURL,
            metadata: metadata,
            sessionID: cachedSnapshot.sessionID,
            sessionOriginKind: cachedSnapshot.sessionOriginKind,
            state: state,
            warnings: [],
            sourceFileIdentity: metadata.fileIdentity ?? cachedSnapshot.sourceFileIdentity,
            lastScannedByteOffset: progress.nextByteOffset)
    }

    private func migrateCachedSnapshotMetadataChunk(
        at fileURL: URL,
        metadata: SourceFileMetadata,
        cachedSnapshot: SessionUsageSnapshot,
        deadline: ContinuousClock.Instant)
        throws -> ParsedSessionFile
    {
        let progress = self.resumableMigrationProgress(for: cachedSnapshot, metadata: metadata)
        var state = ParsedSessionState(progress: progress)
        let clock = ContinuousClock()
        let lineProgress = try self.forEachNonEmptyLine(
            at: fileURL,
            startOffset: progress.lastScannedByteOffset)
        { line, _ in
            self.processParsedLine(line, into: &state)
            return clock.now < deadline
        }

        if lineProgress.reachedEOF {
            return self.makeParsedSessionFile(
                fileURL: fileURL,
                metadata: metadata,
                sessionID: cachedSnapshot.sessionID,
                sessionOriginKind: cachedSnapshot.sessionOriginKind,
                state: state,
                warnings: [],
                sourceFileIdentity: metadata.fileIdentity ?? progress.sourceFileIdentity,
                lastScannedByteOffset: lineProgress.nextByteOffset)
        }

        let nextProgress = SessionIncrementalMigrationProgress(
            lastScannedByteOffset: lineProgress.nextByteOffset,
            sourceFileIdentity: metadata.fileIdentity ?? progress.sourceFileIdentity,
            observedFileSize: metadata.fileSize,
            observedModificationTime: metadata.modificationDate,
            scanVersion: Self.currentScanVersion,
            runningTokenTotals: state.runningTokenTotals,
            seenTokenCountFingerprints: state.recentTokenCountFingerprints,
            lastEventAt: state.lastEventAt,
            dailyBuckets: Array(state.dayBuckets.values),
            hourlyBuckets: Array(state.hourBuckets.values),
            fiveMinuteBuckets: Array(state.fiveMinuteBuckets.values),
            instructionCandidates: state.instructionCandidates.map(\.persistedValue))
        return ParsedSessionFile(
            snapshot: SessionUsageSnapshot(
                sessionID: cachedSnapshot.sessionID,
                sessionOriginKind: cachedSnapshot.sessionOriginKind,
                sourceFile: cachedSnapshot.sourceFile,
                sourceFileIdentity: cachedSnapshot.sourceFileIdentity,
                sourceFileSize: cachedSnapshot.sourceFileSize,
                sourceFileModificationTime: cachedSnapshot.sourceFileModificationTime,
                lastEventAt: cachedSnapshot.lastEventAt,
                scanVersion: cachedSnapshot.scanVersion,
                lastScannedByteOffset: cachedSnapshot.lastScannedByteOffset,
                runningTokenTotals: cachedSnapshot.runningTokenTotals,
                seenTokenCountFingerprints: cachedSnapshot.seenTokenCountFingerprints,
                incrementalMigrationProgress: nextProgress,
                dailyBuckets: cachedSnapshot.dailyBuckets,
                hourlyBuckets: cachedSnapshot.hourlyBuckets,
                fiveMinuteBuckets: cachedSnapshot.fiveMinuteBuckets,
                outboundMessageDailyBuckets: cachedSnapshot.outboundMessageDailyBuckets),
            warnings: [])
    }

    private func resumableMigrationProgress(
        for snapshot: SessionUsageSnapshot,
        metadata: SourceFileMetadata)
        -> SessionIncrementalMigrationProgress
    {
        if let progress = snapshot.incrementalMigrationProgress,
           self.canResumeMigrationProgress(progress, metadata: metadata)
        {
            return progress
        }

        return SessionIncrementalMigrationProgress(
            lastScannedByteOffset: 0,
            sourceFileIdentity: metadata.fileIdentity,
            observedFileSize: metadata.fileSize,
            observedModificationTime: metadata.modificationDate,
            scanVersion: Self.currentScanVersion)
    }

    private func canResumeMigrationProgress(
        _ progress: SessionIncrementalMigrationProgress,
        metadata: SourceFileMetadata)
        -> Bool
    {
        guard progress.scanVersion == Self.currentScanVersion else { return false }
        guard progress.lastScannedByteOffset >= 0 else { return false }
        if let currentSize = metadata.fileSize,
           progress.lastScannedByteOffset > currentSize
        {
            return false
        }
        if progress.sourceFileIdentity != metadata.fileIdentity,
           progress.sourceFileIdentity != nil || metadata.fileIdentity != nil
        {
            return false
        }
        return true
    }

    private func parseSessionFile(
        at fileURL: URL,
        metadata: SourceFileMetadata,
        sourceFileBySessionID: [String: String])
        throws -> ParsedSessionFile
    {
        var sessionID = fileURL.path
        var sessionOriginKind = SessionOriginKind.regular
        var state = ParsedSessionState()
        var pendingLines: [String] = []
        var resolvedSessionMetadata = false
        let progress: LineIterationResult

        do {
            progress = try self.forEachNonEmptyLine(at: fileURL) { line, index in
                if !resolvedSessionMetadata {
                    pendingLines.append(line)

                    if let metadata = self.sessionMetadata(from: line, lineIndex: index) {
                        sessionID = metadata.sessionID
                        sessionOriginKind = metadata.sessionOriginKind
                        if metadata.forkedFromSessionID != nil {
                            throw ForkedSessionReplayDetected(metadata: metadata)
                        }
                        resolvedSessionMetadata = true
                        for pendingLine in pendingLines {
                            self.processParsedLine(pendingLine, into: &state)
                        }
                        pendingLines.removeAll(keepingCapacity: true)
                        return true
                    }

                    if self.parseJSONObject(from: line) != nil {
                        resolvedSessionMetadata = true
                        for pendingLine in pendingLines {
                            self.processParsedLine(pendingLine, into: &state)
                        }
                        pendingLines.removeAll(keepingCapacity: true)
                    }
                    return true
                }

                self.processParsedLine(line, into: &state)
                return true
            }
        } catch let forked as ForkedSessionReplayDetected {
            return try self.parseForkedSessionFile(
                at: fileURL,
                metadata: metadata,
                initialMetadata: forked.metadata,
                sourceFileBySessionID: sourceFileBySessionID)
        }

        if !pendingLines.isEmpty {
            for pendingLine in pendingLines {
                self.processParsedLine(pendingLine, into: &state)
            }
        }

        return self.makeParsedSessionFile(
            fileURL: fileURL,
            metadata: metadata,
            sessionID: sessionID,
            sessionOriginKind: sessionOriginKind,
            state: state,
            warnings: [],
            sourceFileIdentity: metadata.fileIdentity,
            lastScannedByteOffset: progress.nextByteOffset)
    }

    private func parseForkedSessionFile(
        at fileURL: URL,
        metadata: SourceFileMetadata,
        initialMetadata: InitialSessionMetadata,
        sourceFileBySessionID: [String: String])
        throws -> ParsedSessionFile
    {
        let sessionID = initialMetadata.sessionID
        let sessionOriginKind = initialMetadata.sessionOriginKind
        guard let forkedFromSessionID = initialMetadata.forkedFromSessionID,
              let parentSourceFile = sourceFileBySessionID[forkedFromSessionID],
              FileManager.default.fileExists(atPath: parentSourceFile)
        else {
            let message = "Skipping forked session \(sessionID) from \(fileURL.lastPathComponent): parent session is unavailable"
            self.logger.warning("\(message)")
            return ParsedSessionFile(snapshot: nil, warnings: [message])
        }

        let childLines = try self.loadNonEmptyLines(at: fileURL)
        let childReplayLines = Array(childLines.dropFirst(initialMetadata.lineIndex + 1))
        let parentLines = try self.loadNonEmptyLines(at: URL(fileURLWithPath: parentSourceFile))
        let replayPrefixLength = self.sharedReplayPrefixLength(
            childReplayLines: childReplayLines,
            parentLines: parentLines)

        guard replayPrefixLength > 0 else {
            let message = "Skipping forked session \(sessionID) from \(fileURL.lastPathComponent): failed to resolve replay prefix against parent session \(forkedFromSessionID)"
            self.logger.warning("\(message)")
            return ParsedSessionFile(snapshot: nil, warnings: [message])
        }

        return self.parseProcessedLines(
            Array(childReplayLines.dropFirst(replayPrefixLength)),
            fileURL: fileURL,
            metadata: metadata,
            sessionID: sessionID,
            sessionOriginKind: sessionOriginKind,
            warnings: [])
    }

    private func parseProcessedLines(
        _ lines: [String],
        fileURL: URL,
        metadata: SourceFileMetadata,
        sessionID: String,
        sessionOriginKind: SessionOriginKind,
        warnings: [String])
        -> ParsedSessionFile
    {
        var state = ParsedSessionState()
        for line in lines {
            self.processParsedLine(line, into: &state)
        }
        return self.makeParsedSessionFile(
            fileURL: fileURL,
            metadata: metadata,
            sessionID: sessionID,
            sessionOriginKind: sessionOriginKind,
            state: state,
            warnings: warnings,
            sourceFileIdentity: metadata.fileIdentity,
            lastScannedByteOffset: metadata.fileSize)
    }

    private func makeParsedSessionFile(
        fileURL: URL,
        metadata: SourceFileMetadata,
        sessionID: String,
        sessionOriginKind: SessionOriginKind,
        state: ParsedSessionState,
        warnings: [String],
        sourceFileIdentity: String?,
        lastScannedByteOffset: Int64?)
        -> ParsedSessionFile
    {
        var outboundMessageDayBuckets = state.outboundMessageDayBuckets
        if sessionOriginKind != .subagentThreadSpawn {
            for outboundEvent in self.canonicalOutboundEvents(from: state.instructionCandidates) {
                let dayKey = DailyTokenStats.dayKey(for: outboundEvent.timestamp, calendar: self.calendar)
                var bucket = outboundMessageDayBuckets[dayKey] ?? DailyOutboundMessageStats.empty(for: dayKey)
                bucket.add(outboundEvent)
                outboundMessageDayBuckets[dayKey] = bucket
            }
        }

        guard !state.dayBuckets.isEmpty || !outboundMessageDayBuckets.isEmpty else {
            return ParsedSessionFile(snapshot: nil, warnings: warnings)
        }

        let snapshot = SessionUsageSnapshot(
            sessionID: sessionID,
            sessionOriginKind: sessionOriginKind,
            sourceFile: fileURL.path,
            sourceFileIdentity: sourceFileIdentity,
            sourceFileSize: metadata.fileSize,
            sourceFileModificationTime: metadata.modificationDate,
            lastEventAt: state.lastEventAt,
            scanVersion: Self.currentScanVersion,
            lastScannedByteOffset: lastScannedByteOffset,
            runningTokenTotals: state.runningTokenTotals ?? .zero,
            seenTokenCountFingerprints: state.recentTokenCountFingerprints,
            dailyBuckets: state.dayBuckets.values.sorted { $0.date < $1.date },
            hourlyBuckets: state.hourBuckets.values.sorted { $0.hourStart < $1.hourStart },
            fiveMinuteBuckets: state.fiveMinuteBuckets.values.sorted { $0.bucketStart < $1.bucketStart },
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

    private func sessionMetadata(from line: String, lineIndex: Int) -> InitialSessionMetadata? {
        guard let object = self.parseJSONObject(from: line),
              (object["type"] as? String) == "session_meta",
              let payload = object["payload"] as? [String: Any],
              let sessionID = payload["id"] as? String,
              !sessionID.isEmpty
        else {
            return nil
        }

        let forkedFromSessionID = (payload["forked_from_id"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return InitialSessionMetadata(
            sessionID: sessionID,
            forkedFromSessionID: forkedFromSessionID?.isEmpty == false ? forkedFromSessionID : nil,
            sessionOriginKind: self.sessionOriginKind(from: payload["source"]),
            lineIndex: lineIndex)
    }

    private func initialSessionMetadata(at fileURL: URL) throws -> InitialSessionMetadata? {
        var metadata: InitialSessionMetadata?
        _ = try self.forEachNonEmptyLine(at: fileURL) { line, index in
            if let resolvedMetadata = self.sessionMetadata(from: line, lineIndex: index) {
                metadata = resolvedMetadata
                return false
            }
            return self.parseJSONObject(from: line) == nil
        }
        return metadata
    }

    private func loadNonEmptyLines(at fileURL: URL) throws -> [String] {
        var lines: [String] = []
        _ = try self.forEachNonEmptyLine(at: fileURL) { line, _ in
            lines.append(line)
            return true
        }
        return lines
    }

    private func forEachNonEmptyLine(
        at fileURL: URL,
        startOffset: Int64 = 0,
        body: (String, Int) throws -> Bool)
        throws -> LineIterationResult
    {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer {
            try? handle.close()
        }

        let sanitizedStartOffset = max(0, startOffset)
        var skipInitialPartialLine = false
        if sanitizedStartOffset > 0 {
            try handle.seek(toOffset: UInt64(sanitizedStartOffset - 1))
            let previousByte = handle.readData(ofLength: 1).first
            skipInitialPartialLine = previousByte != 0x0A
        }
        try handle.seek(toOffset: UInt64(sanitizedStartOffset))

        var buffer = Data()
        var lineIndex = 0
        var bufferBaseOffset = sanitizedStartOffset
        var nextByteOffset = sanitizedStartOffset

        func processLineData(_ lineData: Data) throws -> Bool {
            guard !lineData.isEmpty else { return true }
            var normalizedLineData = lineData
            if normalizedLineData.last == 0x0D {
                normalizedLineData.removeLast()
            }
            guard !normalizedLineData.isEmpty else { return true }
            let line = String(decoding: normalizedLineData, as: UTF8.self)
            defer {
                lineIndex += 1
            }
            return try body(line, lineIndex)
        }

        while true {
            let chunk = handle.readData(ofLength: 64 * 1024)
            if chunk.isEmpty {
                break
            }

            buffer.append(chunk)
            while let newlineIndex = buffer.firstIndex(of: 0x0A) {
                let lineData = buffer.prefix(upTo: newlineIndex)
                let consumedCount = Int64(newlineIndex + 1)
                buffer.removeSubrange(...newlineIndex)
                nextByteOffset = bufferBaseOffset + consumedCount
                bufferBaseOffset = nextByteOffset

                if skipInitialPartialLine {
                    skipInitialPartialLine = false
                    lineIndex += 1
                    continue
                }

                if try !processLineData(Data(lineData)) {
                    return LineIterationResult(nextByteOffset: nextByteOffset, reachedEOF: false)
                }
            }
        }

        if !buffer.isEmpty {
            if skipInitialPartialLine {
                return LineIterationResult(nextByteOffset: sanitizedStartOffset, reachedEOF: true)
            }
            nextByteOffset = bufferBaseOffset + Int64(buffer.count)
            if try !processLineData(buffer) {
                return LineIterationResult(nextByteOffset: nextByteOffset, reachedEOF: false)
            }
        }

        return LineIterationResult(nextByteOffset: nextByteOffset, reachedEOF: true)
    }

    private func processParsedLine(_ line: String, into state: inout ParsedSessionState) {
        guard let payload = self.parseJSONObject(from: line) else { return }

        if let tokenCountFingerprint = self.parseTokenCountFingerprint(from: payload) {
            guard state.recordTokenCountFingerprint(tokenCountFingerprint, maxPersistedCount: Self.persistedTokenCountFingerprintLimit) else {
                return
            }
        }

        if let event = self.parseTokenEvent(from: payload, runningTokenTotals: &state.runningTokenTotals) {
            let dayKey = DailyTokenStats.dayKey(for: event.timestamp, calendar: self.calendar)
            var dayBucket = state.dayBuckets[dayKey] ?? DailyTokenStats.empty(for: dayKey)
            dayBucket.add(event)
            state.dayBuckets[dayKey] = dayBucket

            let hourStart = HourlyTokenStats.hourStart(for: event.timestamp, calendar: self.calendar)
            var hourBucket = state.hourBuckets[hourStart] ?? HourlyTokenStats.empty(for: hourStart)
            hourBucket.add(event)
            state.hourBuckets[hourStart] = hourBucket

            let bucketStart = FiveMinuteTokenStats.bucketStart(for: event.timestamp, calendar: self.calendar)
            var fiveMinuteBucket = state.fiveMinuteBuckets[bucketStart] ?? FiveMinuteTokenStats.empty(for: bucketStart)
            fiveMinuteBucket.add(event)
            state.fiveMinuteBuckets[bucketStart] = fiveMinuteBucket

            if state.lastEventAt == nil || event.timestamp > state.lastEventAt ?? .distantPast {
                state.lastEventAt = event.timestamp
            }
        }

        if let instructionCandidate = self.parseHumanInstructionCandidate(from: payload) {
            state.instructionCandidates.append(instructionCandidate)
            if state.lastEventAt == nil || instructionCandidate.event.timestamp > state.lastEventAt ?? .distantPast {
                state.lastEventAt = instructionCandidate.event.timestamp
            }
        }
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
        runningTokenTotals: inout SessionRunningTokenTotals?)
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
            let currentTotals = SessionRunningTokenTotals(
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

private struct MigrationCandidate {
    let fileURL: URL
    let priority: Int
    let isForkedReplay: Bool
    let modificationDate: Date
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

private struct LineIterationResult {
    let nextByteOffset: Int64
    let reachedEOF: Bool
}

private struct ParsedSessionState {
    var dayBuckets: [String: DailyTokenStats]
    var hourBuckets: [Date: HourlyTokenStats]
    var fiveMinuteBuckets: [Date: FiveMinuteTokenStats]
    var outboundMessageDayBuckets: [String: DailyOutboundMessageStats]
    var instructionCandidates: [HumanInstructionCandidate]
    var seenTokenCountFingerprints: Set<String>
    var recentTokenCountFingerprints: [String]
    var runningTokenTotals: SessionRunningTokenTotals?
    var lastEventAt: Date?

    init() {
        self.dayBuckets = [:]
        self.hourBuckets = [:]
        self.fiveMinuteBuckets = [:]
        self.outboundMessageDayBuckets = [:]
        self.instructionCandidates = []
        self.seenTokenCountFingerprints = []
        self.recentTokenCountFingerprints = []
        self.runningTokenTotals = nil
        self.lastEventAt = nil
    }

    init(snapshot: SessionUsageSnapshot) {
        self.dayBuckets = Dictionary(uniqueKeysWithValues: snapshot.dailyBuckets.map { ($0.date, $0) })
        self.hourBuckets = Dictionary(uniqueKeysWithValues: snapshot.hourlyBuckets.map { ($0.hourStart, $0) })
        self.fiveMinuteBuckets = Dictionary(
            uniqueKeysWithValues: snapshot.fiveMinuteBuckets.map { ($0.bucketStart, $0) })
        self.outboundMessageDayBuckets = Dictionary(
            uniqueKeysWithValues: snapshot.outboundMessageDailyBuckets.map { ($0.date, $0) })
        self.instructionCandidates = []
        self.recentTokenCountFingerprints = snapshot.seenTokenCountFingerprints
        self.seenTokenCountFingerprints = Set(snapshot.seenTokenCountFingerprints)
        self.runningTokenTotals = snapshot.runningTokenTotals
        self.lastEventAt = snapshot.lastEventAt
    }

    init(progress: SessionIncrementalMigrationProgress) {
        self.dayBuckets = Dictionary(uniqueKeysWithValues: progress.dailyBuckets.map { ($0.date, $0) })
        self.hourBuckets = Dictionary(uniqueKeysWithValues: progress.hourlyBuckets.map { ($0.hourStart, $0) })
        self.fiveMinuteBuckets = Dictionary(
            uniqueKeysWithValues: progress.fiveMinuteBuckets.map { ($0.bucketStart, $0) })
        self.outboundMessageDayBuckets = [:]
        self.instructionCandidates = progress.instructionCandidates.map(HumanInstructionCandidate.init(persistedValue:))
        self.recentTokenCountFingerprints = progress.seenTokenCountFingerprints
        self.seenTokenCountFingerprints = Set(progress.seenTokenCountFingerprints)
        self.runningTokenTotals = progress.runningTokenTotals
        self.lastEventAt = progress.lastEventAt
    }

    mutating func recordTokenCountFingerprint(_ fingerprint: String, maxPersistedCount: Int) -> Bool {
        guard self.seenTokenCountFingerprints.insert(fingerprint).inserted else {
            return false
        }
        self.recentTokenCountFingerprints.append(fingerprint)
        if self.recentTokenCountFingerprints.count > maxPersistedCount {
            self.recentTokenCountFingerprints.removeFirst(self.recentTokenCountFingerprints.count - maxPersistedCount)
        }
        return true
    }
}

private struct InitialSessionMetadata {
    let sessionID: String
    let forkedFromSessionID: String?
    let sessionOriginKind: SessionOriginKind
    let lineIndex: Int
}

private struct ForkedSessionReplayDetected: Error {
    let metadata: InitialSessionMetadata
}

private struct ParsedHumanInstructionContent {
    let sentCharacters: Int
    let signature: String
    let hasMeaningfulContent: Bool
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

    init(source: Source, signature: String, event: OutboundMessageUsageEvent) {
        self.source = source
        self.signature = signature
        self.event = event
    }

    init(persistedValue: SessionInstructionCandidate) {
        self.source = Source(persistedValue: persistedValue.source)
        self.signature = persistedValue.signature
        self.event = persistedValue.event
    }

    var persistedValue: SessionInstructionCandidate {
        SessionInstructionCandidate(
            source: self.source.persistedValue,
            signature: self.signature,
            event: self.event)
    }
}

private extension HumanInstructionCandidate.Source {
    init(persistedValue: SessionInstructionCandidateSource) {
        switch persistedValue {
        case .responseItem:
            self = .responseItem
        case .eventMessage:
            self = .eventMessage
        }
    }

    var persistedValue: SessionInstructionCandidateSource {
        switch self {
        case .responseItem:
            .responseItem
        case .eventMessage:
            .eventMessage
        }
    }
}
