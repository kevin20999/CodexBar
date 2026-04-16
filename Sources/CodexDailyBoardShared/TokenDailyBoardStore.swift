import AppKit
import CodexBarCore
import Foundation
import Observation

struct TokenDailyBoardRealtimeNarrativeProjection: Equatable {
    static let sourceItemLimit = 8
    static let empty = TokenDailyBoardRealtimeNarrativeProjection(
        sourceItems: [],
        sequenceSignature: "",
        hasEligibleIdleRealtimeActivity: false)

    let sourceItems: [TokenDailyBoardNarrativePresentationSourceItem]
    let sequenceSignature: String
    let hasEligibleIdleRealtimeActivity: Bool

    static func make(
        tokenSpeedSamples: [TokenSpeedSample],
        instructionEventSamples: [InstructionEventSample],
        strings: TokenDailyBoardStrings = TokenDailyBoardStrings(),
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> TokenDailyBoardRealtimeNarrativeProjection
    {
        let sourceItems = Array(
            TokenDailyBoardNarrativeBuilder.realtimePresentationSourceItems(
                tokenSpeedSamples: tokenSpeedSamples,
                instructionEventSamples: instructionEventSamples,
                strings: strings,
                catalog: catalog)
                .suffix(Self.sourceItemLimit))
        let sequenceSignature = sourceItems
            .map { sourceItem in
                let timestampComponent = sourceItem.displayTimestamp.map { String($0.timeIntervalSince1970) } ?? "none"
                return "\(sourceItem.signature):\(timestampComponent)"
            }
            .joined(separator: "|")
        return TokenDailyBoardRealtimeNarrativeProjection(
            sourceItems: sourceItems,
            sequenceSignature: sequenceSignature,
            hasEligibleIdleRealtimeActivity: !sourceItems.isEmpty)
    }
}

public enum TokenDailyBoardCacheState: Equatable {
    case ready
    case missing
    case failed(message: String)
}

@MainActor
@Observable
public final class TokenDailyBoardStore {
    var days: [DailyTokenStats]
    var regularDays: [DailyTokenStats]
    var fiveMinuteBuckets: [FiveMinuteTokenStats]
    var outboundMessageDays: [DailyOutboundMessageStats]
    var realtimeTokenSpeedSamples: [TokenSpeedSample]
    var realtimeInstructionEvents: [InstructionEventSample]
    var realtimeEventSignature: String
    var realtimeNarrativeProjection: TokenDailyBoardRealtimeNarrativeProjection
    var narrativeUserEntries: [TokenDailyBoardNarrativeUserCatalogEntry]
    var narrativeUserCatalogErrorMessage: String?
    var avatarCustomizations: [CodexDailyAvatarCustomization]
    public var avatarResolvedSlots: [CodexDailyAvatarResolvedSlot]
    var avatarCustomizationErrorMessage: String?
    var narrativeBodyFontScale: CGFloat
    public var boardDisplayMode: TokenDailyBoardDisplayMode
    package var isBoardDisplayModeTransitioning: Bool
    package var isConversationOnlyPinned: Bool
    package var titlebarControlsCollapsed: Bool
    package var isConversationOnlyWindowHovered: Bool
    package var conversationOnlyDebugTuning: TokenDailyBoardConversationOnlyDebugTuning
    public var windowChromeVisible: Bool
    var lastRefreshAt: Date?
    public var cacheState: TokenDailyBoardCacheState

    @ObservationIgnored private let settings: CodexDailySettingsStore
    @ObservationIgnored private let historyStore: TokenHistoryStore
    @ObservationIgnored private let provider: CodexSessionTokenProvider
    @ObservationIgnored private let tokenRateMonitor: any CodexLiveTokenRateMonitoring
    @ObservationIgnored private let tokenSpeedHistoryStore: TokenSpeedHistoryStore
    @ObservationIgnored private let instructionEventMonitor: any CodexLiveInstructionEventMonitoring
    @ObservationIgnored private let instructionEventHistoryStore: InstructionEventHistoryStore
    @ObservationIgnored private let narrativeUserCatalogStore: TokenDailyBoardNarrativeUserCatalogStore
    @ObservationIgnored private let avatarCustomizationStore: CodexDailyAvatarCustomizationStore
    @ObservationIgnored private var monitorTask: Task<Void, Never>?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var realtimeMonitorTask: Task<Void, Never>?
    @ObservationIgnored private var lastObservedFileTimestamp: Date?

    public convenience init(
        settings: CodexDailySettingsStore = CodexDailySettingsStore(),
        historyStore: TokenHistoryStore? = nil,
        provider: CodexSessionTokenProvider? = nil,
        tokenRateMonitor: (any CodexLiveTokenRateMonitoring)? = nil,
        tokenSpeedHistoryStore: TokenSpeedHistoryStore? = nil,
        instructionEventMonitor: (any CodexLiveInstructionEventMonitoring)? = nil,
        instructionEventHistoryStore: InstructionEventHistoryStore? = nil,
        migrationSourceFileURLs: [URL]? = nil,
        autoStartMonitoring: Bool = true,
        autoStartRefresh: Bool? = nil)
    {
        self.init(
            settings: settings,
            historyStore: historyStore,
            provider: provider,
            tokenRateMonitor: tokenRateMonitor,
            tokenSpeedHistoryStore: tokenSpeedHistoryStore,
            instructionEventMonitor: instructionEventMonitor,
            instructionEventHistoryStore: instructionEventHistoryStore,
            avatarCustomizationStore: nil,
            narrativeUserCatalogStore: nil,
            migrationSourceFileURLs: migrationSourceFileURLs,
            autoStartMonitoring: autoStartMonitoring,
            autoStartRefresh: autoStartRefresh)
    }

    init(
        settings: CodexDailySettingsStore = CodexDailySettingsStore(),
        historyStore: TokenHistoryStore? = nil,
        provider: CodexSessionTokenProvider? = nil,
        tokenRateMonitor: (any CodexLiveTokenRateMonitoring)? = nil,
        tokenSpeedHistoryStore: TokenSpeedHistoryStore? = nil,
        instructionEventMonitor: (any CodexLiveInstructionEventMonitoring)? = nil,
        instructionEventHistoryStore: InstructionEventHistoryStore? = nil,
        avatarCustomizationStore: CodexDailyAvatarCustomizationStore? = nil,
        narrativeUserCatalogStore: TokenDailyBoardNarrativeUserCatalogStore? = nil,
        migrationSourceFileURLs: [URL]? = nil,
        autoStartMonitoring: Bool = true,
        autoStartRefresh: Bool? = nil)
    {
        self.settings = settings
        let resolvedHistoryStore = historyStore ?? provider?.historyStore ?? TokenHistoryStore(
            fileURL: CodexDailyAppIdentity.historyFileURL)
        self.historyStore = resolvedHistoryStore
        self.provider = provider ?? CodexSessionTokenProvider(
            sessionRootURL: settings.sessionRootURL,
            historyStore: resolvedHistoryStore)
        self.tokenRateMonitor = tokenRateMonitor
            ?? CodexLiveTokenRateMonitor(sessionRootURL: self.provider.sessionRootURL)
        self.tokenSpeedHistoryStore = tokenSpeedHistoryStore
            ?? TokenSpeedHistoryStore(fileURL: CodexDailyAppIdentity.tokenSpeedHistoryFileURL)
        self.instructionEventMonitor = instructionEventMonitor
            ?? CodexLiveInstructionEventMonitor(sessionRootURL: self.provider.sessionRootURL)
        self.instructionEventHistoryStore = instructionEventHistoryStore
            ?? InstructionEventHistoryStore(fileURL: CodexDailyAppIdentity.instructionEventHistoryFileURL)
        self.narrativeUserCatalogStore = narrativeUserCatalogStore
            ?? TokenDailyBoardNarrativeUserCatalogStore(fileURL: settings.narrativeUserCatalogFileURL)
        self.avatarCustomizationStore = avatarCustomizationStore
            ?? CodexDailyAvatarCustomizationStore(
                fileURL: CodexDailyAppIdentity.avatarCustomizationFileURL,
                assetsDirectoryURL: CodexDailyAppIdentity.avatarAssetsDirectoryURL)
        self.days = []
        self.regularDays = []
        self.fiveMinuteBuckets = []
        self.outboundMessageDays = []
        self.realtimeTokenSpeedSamples = []
        self.realtimeInstructionEvents = []
        self.realtimeEventSignature = ""
        self.realtimeNarrativeProjection = .empty
        self.narrativeUserEntries = []
        self.narrativeUserCatalogErrorMessage = nil
        self.avatarCustomizations = []
        self.avatarResolvedSlots = self.avatarCustomizationStore.resolvedSlots(from: [])
        self.avatarCustomizationErrorMessage = nil
        self.narrativeBodyFontScale = CGFloat(settings.narrativeBodyFontScale)
        self.boardDisplayMode = settings.boardDisplayMode
        self.isBoardDisplayModeTransitioning = false
        self.isConversationOnlyPinned = settings.isConversationOnlyPinned
        self.titlebarControlsCollapsed = settings.titlebarControlsCollapsed
        self.isConversationOnlyWindowHovered = true
        self.conversationOnlyDebugTuning = settings.conversationOnlyDebugTuning
        self.windowChromeVisible = true
        self.lastRefreshAt = nil
        self.cacheState = .missing

        self.migrateLegacyHistoryIfNeeded(
            candidateFileURLs: migrationSourceFileURLs
                ??
                (historyStore == nil && provider == nil ? CodexDailyAppIdentity
                    .legacyHistoryImportCandidateURLs : []))
        self.reloadFromDisk()
        self.loadRealtimeEventHistories()
        self.loadNarrativeUserCatalog()
        self.loadAvatarCustomizations()

        if autoStartMonitoring {
            self.startMonitoring()
        }

        if autoStartRefresh ?? (historyStore == nil && provider == nil) {
            self.startRefreshLoop()
            Task { [weak self] in
                await self?.refresh()
            }
        }
    }

    deinit {
        self.monitorTask?.cancel()
        self.refreshTask?.cancel()
        self.realtimeMonitorTask?.cancel()
    }

    public func startMonitoring() {
        guard self.monitorTask == nil else { return }

        self.monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                self?.reloadIfFileChanged()
            }
        }

        self.startRealtimeMonitoring()
    }

    public func stopMonitoring() {
        self.monitorTask?.cancel()
        self.monitorTask = nil
        self.refreshTask?.cancel()
        self.refreshTask = nil
        self.realtimeMonitorTask?.cancel()
        self.realtimeMonitorTask = nil
    }

    public func refresh() async {
        do {
            let outcome = try await TokenHistoryRefreshExecutor.refresh(
                provider: self.provider,
                historyStore: self.historyStore)
            self.apply(document: outcome.document)
            self.lastObservedFileTimestamp = self.fileModificationDate(for: self.historyStore.fileURL)
        } catch {
            self.reloadFromDisk()
            if case .missing = self.cacheState {
                self.cacheState = .failed(message: error.localizedDescription)
            }
        }
    }

    public func rebuildCache() async {
        do {
            let outcome = try await TokenHistoryRefreshExecutor.rebuild(
                provider: self.provider,
                historyStore: self.historyStore)
            self.apply(document: outcome.document)
            self.lastObservedFileTimestamp = self.fileModificationDate(for: self.historyStore.fileURL)
        } catch {
            self.reloadFromDisk()
            if case .missing = self.cacheState {
                self.cacheState = .failed(message: error.localizedDescription)
            }
        }
    }

    public func reloadFromDisk() {
        let fileURL = self.historyStore.fileURL
        let path = fileURL.path
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: path) else {
            self.days = []
            self.regularDays = []
            self.fiveMinuteBuckets = []
            self.outboundMessageDays = []
            self.lastRefreshAt = nil
            self.cacheState = .missing
            self.lastObservedFileTimestamp = nil
            return
        }

        do {
            let document = try self.historyStore.load()
            self.apply(document: document)
            self.lastObservedFileTimestamp = self.fileModificationDate(for: fileURL)
        } catch {
            self.days = []
            self.regularDays = []
            self.fiveMinuteBuckets = []
            self.outboundMessageDays = []
            self.lastRefreshAt = nil
            self.cacheState = .failed(message: error.localizedDescription)
            self.lastObservedFileTimestamp = self.fileModificationDate(for: fileURL)
        }
    }

    private func loadRealtimeEventHistories() {
        self.realtimeTokenSpeedSamples = (try? self.tokenSpeedHistoryStore.load()) ?? []
        self.realtimeInstructionEvents = (try? self.instructionEventHistoryStore.load()) ?? []
        self.refreshRealtimeNarrativeProjection()
    }

    private func loadNarrativeUserCatalog() {
        do {
            self.narrativeUserEntries = try self.narrativeUserCatalogStore.load()
            self.narrativeUserCatalogErrorMessage = nil
        } catch {
            self.narrativeUserEntries = []
            self.narrativeUserCatalogErrorMessage = error.localizedDescription
        }
        self.refreshRealtimeNarrativeProjection()
    }

    private func loadAvatarCustomizations() {
        do {
            self.avatarCustomizations = try self.avatarCustomizationStore.load()
            self.avatarCustomizationErrorMessage = nil
        } catch {
            self.avatarCustomizations = []
            self.avatarCustomizationErrorMessage = error.localizedDescription
        }
        self.avatarResolvedSlots = self.avatarCustomizationStore.resolvedSlots(from: self.avatarCustomizations)
    }

    @discardableResult
    func upsertNarrativeUserEntry(_ entry: TokenDailyBoardNarrativeUserCatalogEntry) -> String? {
        var updatedEntries = self.narrativeUserEntries
        if let existingIndex = updatedEntries.firstIndex(where: { $0.id == entry.id }) {
            updatedEntries[existingIndex] = entry
        } else {
            updatedEntries.append(entry)
        }

        do {
            try self.narrativeUserCatalogStore.save(updatedEntries)
            self.narrativeUserEntries = updatedEntries
            self.narrativeUserCatalogErrorMessage = nil
            self.refreshRealtimeNarrativeProjection()
            return nil
        } catch {
            self.narrativeUserCatalogErrorMessage = error.localizedDescription
            return error.localizedDescription
        }
    }

    @discardableResult
    func deleteNarrativeUserEntry(id: String) -> String? {
        let updatedEntries = self.narrativeUserEntries.filter { $0.id != id }
        do {
            try self.narrativeUserCatalogStore.save(updatedEntries)
            self.narrativeUserEntries = updatedEntries
            self.narrativeUserCatalogErrorMessage = nil
            self.refreshRealtimeNarrativeProjection()
            return nil
        } catch {
            self.narrativeUserCatalogErrorMessage = error.localizedDescription
            return error.localizedDescription
        }
    }

    @discardableResult
    func replaceAvatarImage(for slot: CodexDailyAvatarSlot, sourceURL: URL) -> String? {
        do {
            let updated = try self.avatarCustomizationStore.replaceImage(
                at: sourceURL,
                for: slot,
                existing: self.avatarCustomizations)
            try self.avatarCustomizationStore.save(updated)
            self.avatarCustomizations = updated
            self.avatarResolvedSlots = self.avatarCustomizationStore.resolvedSlots(from: updated)
            self.avatarCustomizationErrorMessage = nil
            return nil
        } catch {
            self.avatarCustomizationErrorMessage = error.localizedDescription
            return error.localizedDescription
        }
    }

    @discardableResult
    func restoreAvatarSlot(_ slot: CodexDailyAvatarSlot) -> String? {
        do {
            let updated = try self.avatarCustomizationStore.restoreDefault(
                for: slot,
                existing: self.avatarCustomizations)
            try self.avatarCustomizationStore.save(updated)
            self.avatarCustomizations = updated
            self.avatarResolvedSlots = self.avatarCustomizationStore.resolvedSlots(from: updated)
            self.avatarCustomizationErrorMessage = nil
            return nil
        } catch {
            self.avatarCustomizationErrorMessage = error.localizedDescription
            return error.localizedDescription
        }
    }

    @discardableResult
    func setAvatarMirrored(_ isMirrored: Bool, for slot: CodexDailyAvatarSlot) -> String? {
        do {
            let updated = try self.avatarCustomizationStore.setMirrored(
                isMirrored,
                for: slot,
                existing: self.avatarCustomizations)
            try self.avatarCustomizationStore.save(updated)
            self.avatarCustomizations = updated
            self.avatarResolvedSlots = self.avatarCustomizationStore.resolvedSlots(from: updated)
            self.avatarCustomizationErrorMessage = nil
            return nil
        } catch {
            self.avatarCustomizationErrorMessage = error.localizedDescription
            return error.localizedDescription
        }
    }

    func setNarrativeBodyFontScale(_ value: CGFloat) {
        let clampedValue = min(max(value, 0.7), 1.3)
        self.narrativeBodyFontScale = clampedValue
        self.settings.narrativeBodyFontScale = Double(clampedValue)
    }

    public func setBoardDisplayMode(_ mode: TokenDailyBoardDisplayMode) {
        guard self.boardDisplayMode != mode else { return }
        self.boardDisplayMode = mode
        self.isConversationOnlyWindowHovered = true
        self.settings.boardDisplayMode = mode
    }

    package func setBoardDisplayModeTransitioning(_ isTransitioning: Bool) {
        guard self.isBoardDisplayModeTransitioning != isTransitioning else { return }
        self.isBoardDisplayModeTransitioning = isTransitioning
    }

    package func setConversationOnlyPinned(_ isPinned: Bool) {
        guard self.isConversationOnlyPinned != isPinned else { return }
        self.isConversationOnlyPinned = isPinned
        self.settings.isConversationOnlyPinned = isPinned
    }

    public func setWindowChromeVisible(_ isVisible: Bool) {
        guard self.windowChromeVisible != isVisible else { return }
        self.windowChromeVisible = isVisible
    }

    package func setTitlebarControlsCollapsed(_ isCollapsed: Bool) {
        guard self.titlebarControlsCollapsed != isCollapsed else { return }
        self.titlebarControlsCollapsed = isCollapsed
        self.settings.titlebarControlsCollapsed = isCollapsed
    }

    package func setConversationOnlyWindowHovered(_ isHovered: Bool) {
        guard self.isConversationOnlyWindowHovered != isHovered else { return }
        self.isConversationOnlyWindowHovered = isHovered
    }

    package var windowOrigin: CGPoint? {
        self.settings.windowOrigin
    }

    package func setWindowOrigin(_ origin: CGPoint?) {
        self.settings.windowOrigin = origin
    }

    package var debugPanelOrigin: CGPoint? {
        self.settings.debugPanelOrigin
    }

    package func setDebugPanelOrigin(_ origin: CGPoint?) {
        self.settings.debugPanelOrigin = origin
    }

    package func setConversationOnlyDebugTuning(_ tuning: TokenDailyBoardConversationOnlyDebugTuning) {
        let resolvedTuning = TokenDailyBoardConversationOnlyDebugRules.clamp(tuning)
        guard self.conversationOnlyDebugTuning != resolvedTuning else { return }
        self.conversationOnlyDebugTuning = resolvedTuning
        self.settings.conversationOnlyDebugTuning = resolvedTuning
    }

    package func resetConversationOnlyDebugTuning() {
        self.setConversationOnlyDebugTuning(TokenDailyBoardConversationOnlyDebugRules.defaultTuning)
    }

    private func reloadIfFileChanged() {
        let fileURL = self.historyStore.fileURL
        let latestModificationDate = self.fileModificationDate(for: fileURL)

        switch (self.lastObservedFileTimestamp, latestModificationDate) {
        case (nil, nil):
            if self.cacheState != .missing {
                self.reloadFromDisk()
            }
        case let (previous?, latest?):
            if latest > previous {
                self.reloadFromDisk()
            }
        case (nil, .some), (.some, nil):
            self.reloadFromDisk()
        }
    }

    private func apply(document: TokenHistoryDocument) {
        self.days = document.days
        self.regularDays = Self.aggregateDailyBuckets(from: document.sessions.values.compactMap { snapshot in
            guard snapshot.sessionOriginKind == .regular else { return nil }
            return snapshot.dailyBuckets
        })
        self.fiveMinuteBuckets = document.fiveMinuteBuckets
        self.outboundMessageDays = document.outboundMessageDays
        self.lastRefreshAt = document.lastRefreshAt
        self.cacheState = document == .empty ? .missing : .ready
    }

    private func startRealtimeMonitoring() {
        guard self.realtimeMonitorTask == nil else { return }

        self.realtimeMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }

                let tokenSample = await self.tokenRateMonitor.sample()
                let instructionSamples = await self.instructionEventMonitor.sample()
                await self.applyRealtimeSamples(
                    tokenSample: tokenSample,
                    instructionSamples: instructionSamples)

                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
            }
        }
    }

    private func startRefreshLoop() {
        self.refreshTask?.cancel()
        guard let interval = self.settings.refreshFrequency.interval else {
            self.refreshTask = nil
            return
        }
        self.refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(interval))
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                await self?.refresh()
            }
        }
    }

    private func migrateLegacyHistoryIfNeeded(candidateFileURLs: [URL]) {
        guard !FileManager.default.fileExists(atPath: self.historyStore.fileURL.path) else { return }
        guard !candidateFileURLs.isEmpty else { return }

        for candidateURL in candidateFileURLs where candidateURL != self.historyStore.fileURL {
            guard FileManager.default.fileExists(atPath: candidateURL.path) else { continue }

            do {
                let legacyStore = TokenHistoryStore(fileURL: candidateURL)
                let document = try legacyStore.load()
                guard document != .empty else { continue }

                try self.writeImportedDocument(document)
                self.settings.didImportLegacyCache = true
                return
            } catch {
                continue
            }
        }
    }

    private func writeImportedDocument(_ document: TokenHistoryDocument) throws {
        let directoryURL = self.historyStore.fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directoryURL.path)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)
        try data.write(to: self.historyStore.fileURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: self.historyStore.fileURL.path)
    }

    private func fileModificationDate(for fileURL: URL) -> Date? {
        let path = fileURL.path
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path) else {
            return nil
        }
        return attributes[.modificationDate] as? Date
    }

    private func applyRealtimeSamples(
        tokenSample: TokenSpeedSample,
        instructionSamples: [InstructionEventSample])
        async
    {
        if tokenSample.tokens > 0 {
            if let persisted = try? self.tokenSpeedHistoryStore.upsert(sample: tokenSample) {
                self.realtimeTokenSpeedSamples = persisted
            } else {
                self.realtimeTokenSpeedSamples = Self.mergeTokenSpeedSample(
                    tokenSample,
                    into: self.realtimeTokenSpeedSamples)
            }
        }

        if !instructionSamples.isEmpty {
            if let persisted = try? self.instructionEventHistoryStore.upsert(samples: instructionSamples) {
                self.realtimeInstructionEvents = persisted
            } else {
                self.realtimeInstructionEvents = Self.mergeInstructionSamples(
                    instructionSamples,
                    into: self.realtimeInstructionEvents)
            }
        }

        if tokenSample.tokens > 0 || !instructionSamples.isEmpty {
            self.refreshRealtimeNarrativeProjection()
        }
    }

    private func refreshRealtimeNarrativeProjection() {
        let catalog = TokenDailyBoardNarrativeCatalog(userEntries: self.narrativeUserEntries)
        let projection = TokenDailyBoardRealtimeNarrativeProjection.make(
            tokenSpeedSamples: self.realtimeTokenSpeedSamples,
            instructionEventSamples: self.realtimeInstructionEvents,
            catalog: catalog)
        self.realtimeNarrativeProjection = projection
        self.realtimeEventSignature = projection.sequenceSignature
    }

    private static func aggregateDailyBuckets(from bucketCollections: [[DailyTokenStats]]) -> [DailyTokenStats] {
        var mergedByDay: [String: DailyTokenStats] = [:]

        for buckets in bucketCollections {
            for bucket in buckets {
                if var existing = mergedByDay[bucket.date] {
                    existing.merge(bucket)
                    mergedByDay[bucket.date] = existing
                } else {
                    mergedByDay[bucket.date] = bucket
                }
            }
        }

        return mergedByDay.values.sorted { $0.date < $1.date }
    }

    private static func mergeTokenSpeedSample(
        _ sample: TokenSpeedSample,
        into samples: [TokenSpeedSample]) -> [TokenSpeedSample]
    {
        var keyed = Dictionary(uniqueKeysWithValues: samples.map { ($0.timestamp, $0) })
        keyed[sample.timestamp] = sample
        return keyed.values.sorted { $0.timestamp < $1.timestamp }
    }

    private static func mergeInstructionSamples(
        _ newSamples: [InstructionEventSample],
        into samples: [InstructionEventSample])
        -> [InstructionEventSample]
    {
        var keyed = Dictionary(uniqueKeysWithValues: samples.map { ($0.id, $0) })
        for sample in newSamples {
            keyed[sample.id] = sample
        }
        return keyed.values.sorted { lhs, rhs in
            if lhs.timestamp == rhs.timestamp {
                return lhs.id < rhs.id
            }
            return lhs.timestamp < rhs.timestamp
        }
    }
}
