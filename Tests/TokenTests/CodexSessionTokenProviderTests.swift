import CodexBarCore
import Foundation
import XCTest

final class CodexSessionTokenProviderTests: XCTestCase {
    func test_refreshAggregatesTokenCountEvents() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/03/11", isDirectory: true)
            .appendingPathComponent("rollout.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try fixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.scannedFileCount, 1)
        XCTAssertEqual(result.reusedSessionCount, 0)
        XCTAssertEqual(result.sessions["session-123"]?.dailyBuckets.first?.inputTokens, 23)
        XCTAssertEqual(result.sessions["session-123"]?.dailyBuckets.first?.outputTokens, 7)
        XCTAssertEqual(result.sessions["session-123"]?.dailyBuckets.first?.cachedInputTokens, 12)
        XCTAssertEqual(result.sessions["session-123"]?.hourlyBuckets.count, 2)
        XCTAssertEqual(result.sessions["session-123"]?.hourlyBuckets.last?.totalTokens, 17)
        XCTAssertEqual(result.sessions["session-123"]?.fiveMinuteBuckets.count, 2)
        XCTAssertEqual(result.sessions["session-123"]?.outboundMessageDailyBuckets.first?.sentCharacters, 15)
        XCTAssertEqual(result.sessions["session-123"]?.outboundMessageDailyBuckets.first?.sentMessages, 2)
        XCTAssertEqual(result.hours.count, 2)
        XCTAssertEqual(result.fiveMinuteBuckets.count, 2)
        XCTAssertEqual(result.days.first?.totalTokens, 30)
        XCTAssertEqual(result.outboundMessageDays.first?.sentCharacters, 15)
        XCTAssertEqual(result.outboundMessageDays.first?.sentMessages, 2)
    }

    func test_refreshKeepsCachedHistoryUntilRebuild() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/03/11", isDirectory: true)
            .appendingPathComponent("rollout.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try fixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let historyStore = TokenHistoryStore(fileURL: sandbox.statsFile)
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: historyStore)

        let initial = try provider.refresh()
        _ = try historyStore.merge(refreshResult: initial)
        try FileManager.default.removeItem(at: sessionFile)

        let preserved = try provider.refresh()
        XCTAssertEqual(preserved.days.first?.totalTokens, 30)

        let rebuilt = try provider.rebuild()
        XCTAssertTrue(rebuilt.days.isEmpty)
    }

    func test_refreshReusesUnchangedSessionSnapshot() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/03/11", isDirectory: true)
            .appendingPathComponent("rollout.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try fixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let historyStore = TokenHistoryStore(fileURL: sandbox.statsFile)
        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: historyStore)

        let first = try provider.refresh()
        _ = try historyStore.merge(refreshResult: first)

        let second = try provider.refresh()
        XCTAssertEqual(second.reusedSessionCount, 1)
        XCTAssertEqual(second.days.first?.totalTokens, 30)
    }

    func test_refreshCountsOnlyPostForkUsageForForkedSessionReplay() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let parentFile = sessionRoot
            .appendingPathComponent("2026/03/14", isDirectory: true)
            .appendingPathComponent("parent.jsonl", isDirectory: false)
        let childFile = sessionRoot
            .appendingPathComponent("2026/03/15", isDirectory: true)
            .appendingPathComponent("child.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: parentFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: childFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try forkParentFixtureJSONL.write(to: parentFile, atomically: true, encoding: .utf8)
        try forkChildFixtureJSONL.write(to: childFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.scannedFileCount, 2)
        XCTAssertEqual(result.sessions.count, 2)
        XCTAssertEqual(result.sessions["session-parent"]?.dailyBuckets.first?.totalTokens, 12)
        XCTAssertEqual(result.sessions["session-child"]?.dailyBuckets.first?.totalTokens, 6)
        XCTAssertEqual(result.days.reduce(0) { $0 + $1.totalTokens }, 18)
        XCTAssertEqual(result.sessions["session-parent"]?.outboundMessageDailyBuckets.first?.sentMessages, 1)
        XCTAssertEqual(result.sessions["session-child"]?.outboundMessageDailyBuckets.first?.sentMessages, 1)
        XCTAssertEqual(result.outboundMessageDays.reduce(0) { $0 + $1.sentMessages }, 2)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func test_refreshExcludesSubagentThreadSpawnOutboundMessagesButKeepsTokenUsage() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("subagent-thread-spawn.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try subagentThreadSpawnFixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        let snapshot = try XCTUnwrap(result.sessions["session-subagent"])
        XCTAssertEqual(snapshot.sessionOriginKind, .subagentThreadSpawn)
        XCTAssertEqual(snapshot.dailyBuckets.first?.totalTokens, 13)
        XCTAssertEqual(snapshot.hourlyBuckets.first?.totalTokens, 13)
        XCTAssertEqual(snapshot.fiveMinuteBuckets.first?.totalTokens, 13)
        XCTAssertEqual(snapshot.outboundMessageDailyBuckets, [])
        XCTAssertEqual(result.days.first?.totalTokens, 13)
        XCTAssertEqual(result.hours.first?.totalTokens, 13)
        XCTAssertEqual(result.fiveMinuteBuckets.first?.totalTokens, 13)
        XCTAssertTrue(result.outboundMessageDays.isEmpty)
    }

    func test_refreshAggregatesSubagentThreadSpawnSessionsIntoGlobalTokenSeries() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let regularFile = sessionRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("regular.jsonl", isDirectory: false)
        let subagentFile = sessionRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("subagent-thread-spawn.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: regularFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try regularAggregateFixtureJSONL.write(to: regularFile, atomically: true, encoding: .utf8)
        try subagentThreadSpawnFixtureJSONL.write(to: subagentFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.sessions["session-regular"]?.dailyBuckets.first?.totalTokens, 8)
        XCTAssertEqual(result.sessions["session-subagent"]?.dailyBuckets.first?.totalTokens, 13)
        XCTAssertEqual(result.days.count, 1)
        XCTAssertEqual(result.days.first?.totalTokens, 21)
        XCTAssertEqual(result.hours.map(\.totalTokens), [21])
        XCTAssertEqual(result.fiveMinuteBuckets.map(\.totalTokens), [21])
        XCTAssertEqual(result.outboundMessageDays.first?.sentMessages, 1)
    }

    func test_refreshDeduplicatesRepeatedTokenCountEventsWithinSingleSession() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("duplicate-token-counts.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try duplicateTokenCountFixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.days.count, 1)
        XCTAssertEqual(result.days.first?.totalTokens, 13)
        XCTAssertEqual(result.hours.first?.totalTokens, 13)
        XCTAssertEqual(result.fiveMinuteBuckets.first?.totalTokens, 13)
        XCTAssertEqual(result.sessions["session-duplicate"]?.dailyBuckets.first?.totalTokens, 13)
    }

    func test_refreshUsesTotalTokenUsageDeltaWhenCumulativeUsageIncreases() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("total-usage-delta.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try totalUsageDeltaFixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        let snapshot = try XCTUnwrap(result.sessions["session-total-usage-delta"])
        XCTAssertEqual(snapshot.dailyBuckets.first?.inputTokens, 13)
        XCTAssertEqual(snapshot.dailyBuckets.first?.outputTokens, 5)
        XCTAssertEqual(snapshot.dailyBuckets.first?.cachedInputTokens, 6)
        XCTAssertEqual(snapshot.dailyBuckets.first?.reasoningOutputTokens, 2)
        XCTAssertEqual(snapshot.dailyBuckets.first?.totalTokens, 18)
        XCTAssertEqual(result.days.first?.totalTokens, 18)
        XCTAssertEqual(result.hours.first?.totalTokens, 18)
        XCTAssertEqual(result.fiveMinuteBuckets.first?.totalTokens, 18)
    }

    func test_refreshSkipsZeroDeltaTotalTokenUsageEventsWithinSingleSession() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("total-usage-zero-delta.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try totalUsageZeroDeltaFixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.days.first?.totalTokens, 13)
        XCTAssertEqual(result.hours.first?.totalTokens, 13)
        XCTAssertEqual(result.fiveMinuteBuckets.first?.totalTokens, 13)
        XCTAssertEqual(result.sessions["session-total-usage-zero"]?.dailyBuckets.first?.totalTokens, 13)
    }

    func test_refreshCountsAdjacentMatchingLastTokenUsageWithinSingleSessionWhenTotalUsageIsMissing() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("adjacent-same-last-usage.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try adjacentSameLastUsageFixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.days.first?.totalTokens, 26)
        XCTAssertEqual(result.hours.first?.totalTokens, 26)
        XCTAssertEqual(result.fiveMinuteBuckets.first?.totalTokens, 26)
        XCTAssertEqual(result.sessions["session-adjacent-same"]?.dailyBuckets.first?.totalTokens, 26)
    }

    func test_refreshCountsAdjacentTripleMatchingLastTokenUsageWithinSingleSessionWhenTotalUsageIsMissing() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("adjacent-triple-same-last-usage.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try adjacentTripleSameLastUsageFixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.days.first?.totalTokens, 39)
        XCTAssertEqual(result.hours.first?.totalTokens, 39)
        XCTAssertEqual(result.fiveMinuteBuckets.first?.totalTokens, 39)
        XCTAssertEqual(result.sessions["session-adjacent-triple"]?.dailyBuckets.first?.totalTokens, 39)
    }

    func test_refreshCountsNonAdjacentMatchingLastTokenUsageWithinSingleSession() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("non-adjacent-same-last-usage.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try nonAdjacentSameLastUsageFixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.days.first?.totalTokens, 34)
        XCTAssertEqual(result.hours.first?.totalTokens, 34)
        XCTAssertEqual(result.fiveMinuteBuckets.first?.totalTokens, 34)
        XCTAssertEqual(result.sessions["session-non-adjacent"]?.dailyBuckets.first?.totalTokens, 34)
    }

    func test_refreshKeepsMatchingTokenCountEventsAcrossDifferentSessions() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let firstSessionFile = sessionRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("session-a.jsonl", isDirectory: false)
        let secondSessionFile = sessionRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("session-b.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: firstSessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try matchingSessionAFixtureJSONL.write(to: firstSessionFile, atomically: true, encoding: .utf8)
        try matchingSessionBFixtureJSONL.write(to: secondSessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.sessions.count, 2)
        XCTAssertEqual(result.days.count, 1)
        XCTAssertEqual(result.days.first?.totalTokens, 26)
        XCTAssertEqual(result.hours.first?.totalTokens, 26)
        XCTAssertEqual(result.fiveMinuteBuckets.first?.totalTokens, 26)
    }

    func test_refreshDeduplicatesRepeatedTokenCountsInsideForkedChildPostReplay() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let parentFile = sessionRoot
            .appendingPathComponent("2026/03/14", isDirectory: true)
            .appendingPathComponent("parent.jsonl", isDirectory: false)
        let childFile = sessionRoot
            .appendingPathComponent("2026/03/15", isDirectory: true)
            .appendingPathComponent("child-duplicate.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: parentFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: childFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try forkParentFixtureJSONL.write(to: parentFile, atomically: true, encoding: .utf8)
        try forkChildDuplicateTokenFixtureJSONL.write(to: childFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.sessions["session-parent"]?.dailyBuckets.first?.totalTokens, 12)
        XCTAssertEqual(result.sessions["session-child"]?.dailyBuckets.first?.totalTokens, 6)
        XCTAssertEqual(result.days.reduce(0) { $0 + $1.totalTokens }, 18)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func test_refreshCountsAdjacentMatchingLastTokenUsageInsideForkedChildPostReplayWhenTotalUsageIsMissing() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let parentFile = sessionRoot
            .appendingPathComponent("2026/03/14", isDirectory: true)
            .appendingPathComponent("parent.jsonl", isDirectory: false)
        let childFile = sessionRoot
            .appendingPathComponent("2026/03/15", isDirectory: true)
            .appendingPathComponent("child-adjacent-duplicate.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: parentFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: childFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try forkParentFixtureJSONL.write(to: parentFile, atomically: true, encoding: .utf8)
        try forkChildAdjacentDuplicateTokenFixtureJSONL.write(to: childFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.sessions["session-parent"]?.dailyBuckets.first?.totalTokens, 12)
        XCTAssertEqual(result.sessions["session-child"]?.dailyBuckets.first?.totalTokens, 12)
        XCTAssertEqual(result.days.reduce(0) { $0 + $1.totalTokens }, 24)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func test_refreshSkipsForkedSessionWhenParentSourceFileIsUnavailable() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let childFile = sessionRoot
            .appendingPathComponent("2026/03/15", isDirectory: true)
            .appendingPathComponent("child.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: childFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try missingParentForkFixtureJSONL.write(to: childFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.scannedFileCount, 1)
        XCTAssertTrue(result.sessions.isEmpty)
        XCTAssertTrue(result.days.isEmpty)
        XCTAssertTrue(result.outboundMessageDays.isEmpty)
        XCTAssertEqual(result.errors.count, 1)
        XCTAssertTrue(result.errors.first?.contains("Skipping forked session session-child") == true)
    }

    func test_refreshSplitsHourlyBucketsAcrossHourAndDayBoundaries() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/03/11", isDirectory: true)
            .appendingPathComponent("boundary.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try boundaryFixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.days.count, 2)
        XCTAssertEqual(result.hours.count, 3)
        XCTAssertEqual(result.fiveMinuteBuckets.count, 3)
        XCTAssertEqual(result.hours.map(\.totalTokens), [7, 11, 13])
        XCTAssertEqual(result.fiveMinuteBuckets.map(\.totalTokens), [7, 11, 13])
        XCTAssertEqual(result.hours.first?.hourStart, Self.date("2026-03-11T23:00:00.000Z"))
        XCTAssertEqual(result.hours.last?.hourStart, Self.date("2026-03-12T01:00:00.000Z"))
        XCTAssertEqual(result.fiveMinuteBuckets.first?.bucketStart, Self.date("2026-03-11T23:55:00.000Z"))
        XCTAssertEqual(result.fiveMinuteBuckets.last?.bucketStart, Self.date("2026-03-12T01:20:00.000Z"))
    }

    func test_refreshMergesTokenCountEventsWithinSameFiveMinuteBucket() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/03/11", isDirectory: true)
            .appendingPathComponent("same-minute.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try sameMinuteFixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.hours.count, 1)
        XCTAssertEqual(result.fiveMinuteBuckets.count, 1)
        XCTAssertEqual(result.fiveMinuteBuckets.first?.bucketStart, Self.date("2026-03-11T10:00:00.000Z"))
        XCTAssertEqual(result.fiveMinuteBuckets.first?.totalTokens, 18)
    }

    func test_refreshRescansLegacyCachedSessionWithoutHourlyBuckets() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/03/11", isDirectory: true)
            .appendingPathComponent("rollout.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try fixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)
        let sessionFileSize = try XCTUnwrap(
            try (FileManager.default.attributesOfItem(atPath: sessionFile.path)[.size] as? NSNumber)?.int64Value)

        let payload = """
        {
          "schemaVersion" : 1,
          "sessions" : {
            "session-123" : {
              "dailyBuckets" : [
                {
                  "cachedInputTokens" : 12,
                  "date" : "2026-03-11",
                  "inputTokens" : 23,
                  "outputTokens" : 7,
                  "reasoningOutputTokens" : 3,
                  "totalTokens" : 30
                }
              ],
              "lastEventAt" : null,
              "sessionID" : "session-123",
              "sourceFile" : "\(sessionFile.path)",
              "sourceFileModificationTime" : null,
              "sourceFileSize" : \(sessionFileSize)
            }
          },
          "days" : [
            {
              "cachedInputTokens" : 12,
              "date" : "2026-03-11",
              "inputTokens" : 23,
              "outputTokens" : 7,
              "reasoningOutputTokens" : 3,
              "totalTokens" : 30
            }
          ],
          "lastRefreshAt" : null
        }
        """
        try payload.write(to: sandbox.statsFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.reusedSessionCount, 0)
        XCTAssertEqual(result.sessions["session-123"]?.hourlyBuckets.count, 2)
        XCTAssertEqual(result.sessions["session-123"]?.fiveMinuteBuckets.count, 2)
        XCTAssertEqual(result.sessions["session-123"]?.scanVersion, 11)
        XCTAssertEqual(result.sessions["session-123"]?.outboundMessageDailyBuckets.first?.sentMessages, 2)
    }

    func test_sessionUsageSnapshotDecodesLegacyCacheWithoutOriginKind() throws {
        let payload = """
        {
          "sessionID" : "legacy-session",
          "sourceFile" : "/tmp/legacy.jsonl",
          "sourceFileSize" : 42,
          "sourceFileModificationTime" : null,
          "lastEventAt" : null,
          "scanVersion" : 7,
          "dailyBuckets" : [],
          "hourlyBuckets" : [],
          "fiveMinuteBuckets" : [],
          "outboundMessageDailyBuckets" : []
        }
        """

        let snapshot = try JSONDecoder().decode(SessionUsageSnapshot.self, from: Data(payload.utf8))
        XCTAssertEqual(snapshot.sessionOriginKind, .regular)
    }

    func test_refreshBuildsCanonicalHumanInstructionsFromResponseItems() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/03/13", isDirectory: true)
            .appendingPathComponent("response-items.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try responseItemFixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        let outbound = try XCTUnwrap(result.outboundMessageDays.first)
        XCTAssertEqual(outbound.sentMessages, 2)
        XCTAssertEqual(outbound.sentCharacters, "确认方案，执行".count)
        XCTAssertEqual(result.sessions["session-response"]?.outboundMessageDailyBuckets.first?.sentMessages, 2)
    }

    func test_refreshCountsOutboundMessagesWithoutTokenEvents() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/03/12", isDirectory: true)
            .appendingPathComponent("messages-only.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try outboundOnlyFixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertTrue(result.days.isEmpty)
        XCTAssertTrue(result.hours.isEmpty)
        XCTAssertTrue(result.fiveMinuteBuckets.isEmpty)
        XCTAssertEqual(result.outboundMessageDays.first?.sentCharacters, 5)
        XCTAssertEqual(result.outboundMessageDays.first?.sentMessages, 2)
        XCTAssertEqual(result.sessions["session-outbound"]?.outboundMessageDailyBuckets.first?.sentCharacters, 5)
        XCTAssertEqual(result.sessions["session-outbound"]?.hourlyBuckets, [])
        XCTAssertEqual(result.sessions["session-outbound"]?.fiveMinuteBuckets, [])
    }

    func test_refreshCountsAdjacentMatchingLastTokenUsageForSubagentSessionWhenTotalUsageIsMissing() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let sessionFile = sessionRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("subagent-adjacent-same-last-usage.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: sessionFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try subagentAdjacentSameLastUsageFixtureJSONL.write(to: sessionFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        let snapshot = try XCTUnwrap(result.sessions["session-subagent-adjacent"])
        XCTAssertEqual(snapshot.sessionOriginKind, .subagentThreadSpawn)
        XCTAssertEqual(snapshot.dailyBuckets.first?.totalTokens, 26)
        XCTAssertEqual(snapshot.hourlyBuckets.first?.totalTokens, 26)
        XCTAssertEqual(snapshot.fiveMinuteBuckets.first?.totalTokens, 26)
        XCTAssertEqual(result.days.first?.totalTokens, 26)
        XCTAssertEqual(result.hours.first?.totalTokens, 26)
        XCTAssertEqual(result.fiveMinuteBuckets.first?.totalTokens, 26)
    }

    func test_refreshPrefersLiveSessionOverArchivedDuplicateSession() throws {
        let sandbox = try TestSandbox()
        let sessionRoot = sandbox.root.appendingPathComponent("sessions", isDirectory: true)
        let archivedRoot = sandbox.root.appendingPathComponent("archived_sessions", isDirectory: true)
        let liveFile = sessionRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("shared-session.jsonl", isDirectory: false)
        let archivedFile = archivedRoot
            .appendingPathComponent("2026/04/09", isDirectory: true)
            .appendingPathComponent("shared-session.jsonl", isDirectory: false)
        try FileManager.default.createDirectory(
            at: liveFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try FileManager.default.createDirectory(
            at: archivedFile.deletingLastPathComponent(),
            withIntermediateDirectories: true)
        try regularAggregateFixtureJSONL.write(to: liveFile, atomically: true, encoding: .utf8)
        try archivedDuplicateFixtureJSONL.write(to: archivedFile, atomically: true, encoding: .utf8)

        let provider = CodexSessionTokenProvider(
            sessionRootURL: sessionRoot,
            calendar: Self.utcCalendar,
            historyStore: TokenHistoryStore(fileURL: sandbox.statsFile))

        let result = try provider.refresh()

        XCTAssertEqual(result.scannedFileCount, 2)
        XCTAssertEqual(result.sessions.count, 1)
        XCTAssertEqual(result.sessions["session-regular"]?.sourceFile, liveFile.path)
        XCTAssertEqual(result.days.first?.totalTokens, 8)
        XCTAssertEqual(result.hours.first?.totalTokens, 8)
        XCTAssertEqual(result.fiveMinuteBuckets.first?.totalTokens, 8)
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone(abbreviation: "GMT") ?? .current
        return calendar
    }()

    private static func date(_ timestamp: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp) ?? Date.distantPast
    }
}

private struct TestSandbox {
    let root: URL
    let statsFile: URL

    init() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        self.root = root
        self.statsFile = root.appendingPathComponent("token_stats.json", isDirectory: false)
    }
}

private let fixtureJSONL = [
    #"{"timestamp":"2026-03-11T10:00:00.000Z","type":"session_meta","payload":{"id":"session-123"}}"#,
    userMessageLine(timestamp: "2026-03-11T10:00:00.500Z", message: "hello world"),
    tokenCountLine(.init(
        timestamp: "2026-03-11T10:00:01.000Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13)),
    userMessageLine(timestamp: "2026-03-11T11:00:30.000Z", message: "test"),
    tokenCountLine(.init(
        timestamp: "2026-03-11T11:10:01.000Z",
        input: 13,
        output: 4,
        cachedInput: 7,
        reasoningOutput: 2,
        total: 17)),
].joined(separator: "\n")

private let outboundOnlyFixtureJSONL = [
    #"{"timestamp":"2026-03-12T08:00:00.000Z","type":"session_meta","payload":{"id":"session-outbound"}}"#,
    userMessageLine(
        timestamp: "2026-03-12T08:01:00.000Z",
        message: "",
        textElementsJSON: #"[{"text":"abc"},{"text":"de"}]"#),
    userMessageLine(
        timestamp: "2026-03-12T08:02:00.000Z",
        message: "",
        imagesJSON: #"[{"name":"diagram.png"}]"#),
].joined(separator: "\n")

private let regularAggregateFixtureJSONL = [
    #"{"timestamp":"2026-04-09T12:24:50.000Z","type":"session_meta","payload":{"id":"session-regular"}}"#,
    userMessageLine(timestamp: "2026-04-09T12:24:50.200Z", message: "main thread"),
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:50.900Z",
        input: 5,
        output: 3,
        cachedInput: 0,
        reasoningOutput: 0,
        total: 8)),
].joined(separator: "\n")

private let subagentThreadSpawnFixtureJSONL = [
    sessionMetaLine(
        timestamp: "2026-04-09T12:24:51.000Z",
        id: "session-subagent",
        sourceJSON: #"{"subagent":{"thread_spawn":{"parent_thread_id":"session-parent","depth":1}}}"#),
    responseUserTextLine(timestamp: "2026-04-09T12:24:51.100Z", text: "delegate this"),
    userMessageLine(timestamp: "2026-04-09T12:24:51.200Z", message: "delegate this"),
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:51.829Z",
        input: 10,
        output: 3,
        cachedInput: 0,
        reasoningOutput: 0,
        total: 13)),
].joined(separator: "\n")

private let boundaryFixtureJSONL = [
    #"{"timestamp":"2026-03-11T23:00:00.000Z","type":"session_meta","payload":{"id":"session-boundary"}}"#,
    tokenCountLine(.init(
        timestamp: "2026-03-11T23:58:00.000Z",
        input: 4,
        output: 3,
        cachedInput: 0,
        reasoningOutput: 0,
        total: 7)),
    tokenCountLine(.init(
        timestamp: "2026-03-12T00:05:00.000Z",
        input: 6,
        output: 5,
        cachedInput: 0,
        reasoningOutput: 0,
        total: 11)),
    tokenCountLine(.init(
        timestamp: "2026-03-12T01:20:00.000Z",
        input: 8,
        output: 5,
        cachedInput: 0,
        reasoningOutput: 0,
        total: 13)),
].joined(separator: "\n")

private let sameMinuteFixtureJSONL = [
    #"{"timestamp":"2026-03-11T10:00:00.000Z","type":"session_meta","payload":{"id":"session-minute"}}"#,
    tokenCountLine(.init(
        timestamp: "2026-03-11T10:00:01.000Z",
        input: 4,
        output: 2,
        cachedInput: 0,
        reasoningOutput: 0,
        total: 6)),
    tokenCountLine(.init(
        timestamp: "2026-03-11T10:00:40.000Z",
        input: 8,
        output: 4,
        cachedInput: 0,
        reasoningOutput: 0,
        total: 12)),
].joined(separator: "\n")

private let duplicateTokenCountFixtureJSONL = [
    #"{"timestamp":"2026-04-09T12:24:51.000Z","type":"session_meta","payload":{"id":"session-duplicate"}}"#,
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:51.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13,
        totalUsage: 1_183_579,
        modelContextWindow: 258_400,
        limitID: "codex_bengalfox")),
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:51.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13,
        totalUsage: 1_183_579,
        modelContextWindow: 258_400,
        limitID: "codex")),
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:51.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13,
        totalUsage: 1_183_579,
        modelContextWindow: 258_400,
        limitID: "codex_bengalfox")),
].joined(separator: "\n")

private let adjacentSameLastUsageFixtureJSONL = [
    #"{"timestamp":"2026-04-09T12:24:51.000Z","type":"session_meta","payload":{"id":"session-adjacent-same"}}"#,
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:51.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13)),
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:52.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13)),
].joined(separator: "\n")

private let adjacentTripleSameLastUsageFixtureJSONL = [
    #"{"timestamp":"2026-04-09T12:24:51.000Z","type":"session_meta","payload":{"id":"session-adjacent-triple"}}"#,
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:51.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13)),
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:52.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13)),
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:53.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13)),
].joined(separator: "\n")

private let totalUsageDeltaFixtureJSONL = [
    #"{"timestamp":"2026-04-09T12:24:51.000Z","type":"session_meta","payload":{"id":"session-total-usage-delta"}}"#,
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:51.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13,
        totalUsage: 13,
        totalUsageInput: 10,
        totalUsageOutput: 3,
        totalUsageCachedInput: 5,
        totalUsageReasoningOutput: 1)),
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:52.829Z",
        input: 3,
        output: 2,
        cachedInput: 1,
        reasoningOutput: 1,
        total: 5,
        totalUsage: 18,
        totalUsageInput: 13,
        totalUsageOutput: 5,
        totalUsageCachedInput: 6,
        totalUsageReasoningOutput: 2)),
].joined(separator: "\n")

private let totalUsageZeroDeltaFixtureJSONL = [
    #"{"timestamp":"2026-04-09T12:24:51.000Z","type":"session_meta","payload":{"id":"session-total-usage-zero"}}"#,
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:51.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13,
        totalUsage: 13,
        totalUsageInput: 10,
        totalUsageOutput: 3,
        totalUsageCachedInput: 5,
        totalUsageReasoningOutput: 1)),
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:52.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13,
        totalUsage: 13,
        totalUsageInput: 10,
        totalUsageOutput: 3,
        totalUsageCachedInput: 5,
        totalUsageReasoningOutput: 1)),
].joined(separator: "\n")

private let nonAdjacentSameLastUsageFixtureJSONL = [
    #"{"timestamp":"2026-04-09T12:24:51.000Z","type":"session_meta","payload":{"id":"session-non-adjacent"}}"#,
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:51.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13)),
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:52.829Z",
        input: 6,
        output: 2,
        cachedInput: 1,
        reasoningOutput: 0,
        total: 8)),
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:53.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13)),
].joined(separator: "\n")

private let matchingSessionAFixtureJSONL = [
    #"{"timestamp":"2026-04-09T12:24:51.000Z","type":"session_meta","payload":{"id":"session-a"}}"#,
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:51.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13,
        totalUsage: 1_183_579,
        modelContextWindow: 258_400,
        limitID: "codex")),
].joined(separator: "\n")

private let matchingSessionBFixtureJSONL = [
    #"{"timestamp":"2026-04-09T12:24:52.000Z","type":"session_meta","payload":{"id":"session-b"}}"#,
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:51.829Z",
        input: 10,
        output: 3,
        cachedInput: 5,
        reasoningOutput: 1,
        total: 13,
        totalUsage: 1_183_579,
        modelContextWindow: 258_400,
        limitID: "codex_bengalfox")),
].joined(separator: "\n")

private let responseItemFixtureJSONL = [
    #"{"timestamp":"2026-03-13T09:00:00.000Z","type":"session_meta","payload":{"id":"session-response"}}"#,
    responseUserTextLine(
        timestamp: "2026-03-13T09:00:00.100Z",
        text: """
        # AGENTS.md instructions for /Users/kevin/codexbardiy
        """),
    responseUserTextLine(
        timestamp: "2026-03-13T09:00:00.200Z",
        text: """
        <environment_context>
          <cwd>/Users/kevin/codexbardiy</cwd>
        </environment_context>
        """),
    responseUserTextLine(
        timestamp: "2026-03-13T09:00:00.300Z",
        text: """
        <turn_aborted>
        The user interrupted the previous turn on purpose.
        </turn_aborted>
        """),
    responseUserTextLine(timestamp: "2026-03-13T09:00:01.000Z", text: "确认方案，执行\n"),
    userMessageLine(timestamp: "2026-03-13T09:00:01.200Z", message: "确认方案，执行"),
    responseUserImageOnlyLine(timestamp: "2026-03-13T09:00:02.000Z"),
].joined(separator: "\n")

private let forkParentFixtureLines = [
    sessionMetaLine(timestamp: "2026-03-14T10:00:00.000Z", id: "session-parent"),
    userMessageLine(timestamp: "2026-03-14T10:00:00.500Z", message: "parent request"),
    tokenCountLine(.init(
        timestamp: "2026-03-14T10:00:01.000Z",
        input: 9,
        output: 3,
        cachedInput: 0,
        reasoningOutput: 0,
        total: 12)),
]

private let forkParentFixtureJSONL = forkParentFixtureLines.joined(separator: "\n")

private let forkChildFixtureJSONL = (
    [
        sessionMetaLine(
            timestamp: "2026-03-15T10:00:00.000Z",
            id: "session-child",
            forkedFromID: "session-parent"),
    ] + forkParentFixtureLines + [
        userMessageLine(timestamp: "2026-03-15T10:05:00.500Z", message: "child request"),
        tokenCountLine(.init(
            timestamp: "2026-03-15T10:05:01.000Z",
            input: 4,
            output: 2,
            cachedInput: 0,
            reasoningOutput: 0,
            total: 6)),
    ]).joined(separator: "\n")

private let forkChildDuplicateTokenFixtureJSONL = (
    [
        sessionMetaLine(
            timestamp: "2026-03-15T10:00:00.000Z",
            id: "session-child",
            forkedFromID: "session-parent"),
    ] + forkParentFixtureLines + [
        userMessageLine(timestamp: "2026-03-15T10:05:00.500Z", message: "child request"),
        tokenCountLine(.init(
            timestamp: "2026-03-15T10:05:01.000Z",
            input: 4,
            output: 2,
            cachedInput: 0,
            reasoningOutput: 0,
            total: 6,
            totalUsage: 18,
            modelContextWindow: 258_400,
            limitID: "codex_bengalfox")),
        tokenCountLine(.init(
            timestamp: "2026-03-15T10:05:01.000Z",
            input: 4,
            output: 2,
            cachedInput: 0,
            reasoningOutput: 0,
            total: 6,
            totalUsage: 18,
            modelContextWindow: 258_400,
            limitID: "codex")),
    ]).joined(separator: "\n")

private let forkChildAdjacentDuplicateTokenFixtureJSONL = (
    [
        sessionMetaLine(
            timestamp: "2026-03-15T10:00:00.000Z",
            id: "session-child",
            forkedFromID: "session-parent"),
    ] + forkParentFixtureLines + [
        userMessageLine(timestamp: "2026-03-15T10:05:00.500Z", message: "child request"),
        tokenCountLine(.init(
            timestamp: "2026-03-15T10:05:01.000Z",
            input: 4,
            output: 2,
            cachedInput: 0,
            reasoningOutput: 0,
            total: 6)),
        tokenCountLine(.init(
            timestamp: "2026-03-15T10:05:02.000Z",
            input: 4,
            output: 2,
            cachedInput: 0,
            reasoningOutput: 0,
            total: 6)),
    ]).joined(separator: "\n")

private let missingParentForkFixtureJSONL = [
    sessionMetaLine(
        timestamp: "2026-03-15T10:00:00.000Z",
        id: "session-child",
        forkedFromID: "missing-parent"),
    sessionMetaLine(timestamp: "2026-03-14T10:00:00.000Z", id: "missing-parent"),
    userMessageLine(timestamp: "2026-03-15T10:05:00.500Z", message: "child request"),
    tokenCountLine(.init(
        timestamp: "2026-03-15T10:05:01.000Z",
        input: 4,
        output: 2,
        cachedInput: 0,
        reasoningOutput: 0,
        total: 6)),
].joined(separator: "\n")

private let subagentAdjacentSameLastUsageFixtureJSONL = [
    sessionMetaLine(
        timestamp: "2026-04-09T12:24:51.000Z",
        id: "session-subagent-adjacent",
        sourceJSON: #"{"subagent":{"thread_spawn":{"parent_thread_id":"session-parent","depth":1}}}"#),
    responseUserTextLine(timestamp: "2026-04-09T12:24:51.100Z", text: "delegate this"),
    userMessageLine(timestamp: "2026-04-09T12:24:51.200Z", message: "delegate this"),
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:51.829Z",
        input: 10,
        output: 3,
        cachedInput: 0,
        reasoningOutput: 0,
        total: 13)),
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:52.829Z",
        input: 10,
        output: 3,
        cachedInput: 0,
        reasoningOutput: 0,
        total: 13)),
].joined(separator: "\n")

private let archivedDuplicateFixtureJSONL = [
    #"{"timestamp":"2026-04-09T12:24:52.000Z","type":"session_meta","payload":{"id":"session-regular"}}"#,
    tokenCountLine(.init(
        timestamp: "2026-04-09T12:24:52.829Z",
        input: 20,
        output: 1,
        cachedInput: 0,
        reasoningOutput: 0,
        total: 21)),
].joined(separator: "\n")

private func sessionMetaLine(
    timestamp: String,
    id: String,
    forkedFromID: String? = nil,
    sourceJSON: String? = nil)
    -> String
{
    let forkedField = if let forkedFromID {
        ",\"forked_from_id\":\(jsonString(forkedFromID))"
    } else {
        ""
    }
    let sourceField = if let sourceJSON {
        ",\"source\":\(sourceJSON)"
    } else {
        ""
    }

    return "{"
        + "\"timestamp\":\"\(timestamp)\","
        + "\"type\":\"session_meta\","
        + "\"payload\":{"
        + "\"id\":\(jsonString(id))"
        + forkedField
        + sourceField
        + "}}"
}

private func tokenCountLine(_ fixture: TokenCountFixture) -> String {
    let usageFields = [
        "\"input_tokens\":\(fixture.input)",
        "\"output_tokens\":\(fixture.output)",
        "\"cached_input_tokens\":\(fixture.cachedInput)",
        "\"reasoning_output_tokens\":\(fixture.reasoningOutput)",
        "\"total_tokens\":\(fixture.total)",
    ].joined(separator: ",")

    let totalUsageField = if fixture.totalUsage != nil
        || fixture.totalUsageInput != nil
        || fixture.totalUsageOutput != nil
        || fixture.totalUsageCachedInput != nil
        || fixture.totalUsageReasoningOutput != nil
    {
        let totalUsageFields = [
            "\"input_tokens\":\(fixture.totalUsageInput ?? fixture.input)",
            "\"output_tokens\":\(fixture.totalUsageOutput ?? fixture.output)",
            "\"cached_input_tokens\":\(fixture.totalUsageCachedInput ?? fixture.cachedInput)",
            "\"reasoning_output_tokens\":\(fixture.totalUsageReasoningOutput ?? fixture.reasoningOutput)",
            "\"total_tokens\":\(fixture.totalUsage ?? ((fixture.totalUsageInput ?? fixture.input) + (fixture.totalUsageOutput ?? fixture.output)))",
        ].joined(separator: ",")
        ",\"total_token_usage\":{\(totalUsageFields)}"
    } else {
        ""
    }

    let modelContextWindowField = if let modelContextWindow = fixture.modelContextWindow {
        ",\"model_context_window\":\(modelContextWindow)"
    } else {
        ""
    }

    let rateLimitsField = if let limitID = fixture.limitID {
        ",\"rate_limits\":{\"limit_id\":\(jsonString(limitID))}"
    } else {
        ""
    }

    return "{"
        + "\"timestamp\":\"\(fixture.timestamp)\","
        + "\"type\":\"event_msg\","
        + "\"payload\":{"
        + "\"type\":\"token_count\","
        + "\"info\":{"
        + "\"last_token_usage\":{"
        + usageFields
        + "}"
        + totalUsageField
        + modelContextWindowField
        + "}"
        + rateLimitsField
        + "}}"
}

private func userMessageLine(
    timestamp: String,
    message: String,
    textElementsJSON: String = "[]",
    imagesJSON: String = "[]",
    localImagesJSON: String = "[]")
    -> String
{
    "{"
        + "\"timestamp\":\"\(timestamp)\","
        + "\"type\":\"event_msg\","
        + "\"payload\":{"
        + "\"type\":\"user_message\","
        + "\"message\":\(jsonString(message)),"
        + "\"images\":\(imagesJSON),"
        + "\"local_images\":\(localImagesJSON),"
        + "\"text_elements\":\(textElementsJSON)"
        + "}}"
}

private func responseUserTextLine(timestamp: String, text: String) -> String {
    "{"
        + "\"timestamp\":\"\(timestamp)\","
        + "\"type\":\"response_item\","
        + "\"payload\":{"
        + "\"type\":\"message\","
        + "\"role\":\"user\","
        + "\"content\":[{"
        + "\"type\":\"input_text\","
        + "\"text\":\(jsonString(text))"
        + "}]"
        + "}}"
}

private func responseUserImageOnlyLine(timestamp: String) -> String {
    "{"
        + "\"timestamp\":\"\(timestamp)\","
        + "\"type\":\"response_item\","
        + "\"payload\":{"
        + "\"type\":\"message\","
        + "\"role\":\"user\","
        + "\"content\":["
        + "{\"type\":\"input_text\",\"text\":\"<image>\"},"
        + "{\"type\":\"input_image\",\"image_url\":\"data:image/png;base64,abc\"}"
        + "]"
        + "}}"
}

private func jsonString(_ value: String) -> String {
    let data = try? JSONEncoder().encode(value)
    return String(data: data ?? Data("".utf8), encoding: .utf8) ?? "\"\""
}

private struct TokenCountFixture {
    let timestamp: String
    let input: Int
    let output: Int
    let cachedInput: Int
    let reasoningOutput: Int
    let total: Int
    let totalUsage: Int? = nil
    let totalUsageInput: Int? = nil
    let totalUsageOutput: Int? = nil
    let totalUsageCachedInput: Int? = nil
    let totalUsageReasoningOutput: Int? = nil
    let modelContextWindow: Int? = nil
    let limitID: String? = nil
}
