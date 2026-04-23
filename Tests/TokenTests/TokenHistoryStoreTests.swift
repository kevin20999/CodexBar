import CodexBarCore
import Foundation
import XCTest

final class TokenHistoryStoreTests: XCTestCase {
    func test_mergeWritesSecureFilePermissions() throws {
        let sandbox = try HistorySandbox()
        let store = TokenHistoryStore(fileURL: sandbox.fileURL)

        let result = TokenRefreshResult(
            sessions: [:],
            days: [DailyTokenStats(
                date: "2026-03-11",
                inputTokens: 1,
                outputTokens: 2,
                cachedInputTokens: 0,
                reasoningOutputTokens: 0,
                totalTokens: 3)],
            refreshedAt: Date(),
            scannedFileCount: 1,
            reusedSessionCount: 0,
            errors: [])

        _ = try store.merge(refreshResult: result)

        let attributes = try FileManager.default.attributesOfItem(atPath: sandbox.fileURL.path)
        let permissions = (attributes[.posixPermissions] as? NSNumber)?.intValue
        XCTAssertEqual(permissions, 0o600)
    }

    func test_loadReturnsEmptyForUnsupportedSchemaVersion() throws {
        let sandbox = try HistorySandbox()
        let payload = """
        {
          "schemaVersion" : 999,
          "sessions" : {},
          "days" : [],
          "lastRefreshAt" : null
        }
        """
        try payload.write(to: sandbox.fileURL, atomically: true, encoding: .utf8)

        let store = TokenHistoryStore(fileURL: sandbox.fileURL)
        let document = try store.load()

        XCTAssertEqual(document, .empty)
    }

    func test_loadDecodesLegacyDocumentWithoutFiveMinuteBuckets() throws {
        let sandbox = try HistorySandbox()
        let payload = """
        {
          "schemaVersion" : 1,
          "sessions" : {
            "session-123" : {
              "dailyBuckets" : [
                {
                  "cachedInputTokens" : 0,
                  "date" : "2026-03-11",
                  "inputTokens" : 10,
                  "outputTokens" : 3,
                  "reasoningOutputTokens" : 0,
                  "totalTokens" : 13
                }
              ],
              "lastEventAt" : null,
              "sessionID" : "session-123",
              "sourceFile" : "/tmp/session.jsonl",
              "sourceFileModificationTime" : null,
              "sourceFileSize" : 123
            }
          },
          "days" : [],
          "lastRefreshAt" : null
        }
        """
        try payload.write(to: sandbox.fileURL, atomically: true, encoding: .utf8)

        let document = try TokenHistoryStore(fileURL: sandbox.fileURL).load()

        XCTAssertEqual(document.schemaVersion, 1)
        XCTAssertEqual(document.sessions["session-123"]?.hourlyBuckets, [])
        XCTAssertEqual(document.sessions["session-123"]?.fiveMinuteBuckets, [])
        XCTAssertEqual(document.sessions["session-123"]?.outboundMessageDailyBuckets, [])
        XCTAssertEqual(document.hours, [])
        XCTAssertEqual(document.fiveMinuteBuckets, [])
        XCTAssertEqual(document.outboundMessageDays, [])
    }

    func test_mergeRoundTripsHourlyAndFiveMinuteBuckets() throws {
        let sandbox = try HistorySandbox()
        let hourStart = Date(timeIntervalSince1970: 1_773_225_600)
        let bucketStart = Date(timeIntervalSince1970: 1_773_225_900)
        let result = TokenRefreshResult(
            sessions: [
                "session-123": SessionUsageSnapshot(
                    sessionID: "session-123",
                    sourceFile: "/tmp/session.jsonl",
                    sourceFileSize: 321,
                    sourceFileModificationTime: nil,
                    lastEventAt: hourStart,
                    dailyBuckets: [
                        DailyTokenStats(
                            date: "2026-03-11",
                            inputTokens: 12,
                            outputTokens: 8,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 20),
                    ],
                    hourlyBuckets: [
                        HourlyTokenStats(
                            hourStart: hourStart,
                            inputTokens: 12,
                            outputTokens: 8,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 20),
                    ],
                    fiveMinuteBuckets: [
                        FiveMinuteTokenStats(
                            bucketStart: bucketStart,
                            inputTokens: 12,
                            outputTokens: 8,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 20),
                    ],
                    outboundMessageDailyBuckets: [
                        DailyOutboundMessageStats(
                            date: "2026-03-11",
                            sentCharacters: 120,
                            sentMessages: 3),
                    ]),
            ],
            days: [],
            hours: [
                HourlyTokenStats(
                    hourStart: hourStart,
                    inputTokens: 12,
                    outputTokens: 8,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 20),
            ],
            fiveMinuteBuckets: [
                FiveMinuteTokenStats(
                    bucketStart: bucketStart,
                    inputTokens: 12,
                    outputTokens: 8,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 20),
            ],
            outboundMessageDays: [
                DailyOutboundMessageStats(
                    date: "2026-03-11",
                    sentCharacters: 120,
                    sentMessages: 3),
            ],
            refreshedAt: hourStart,
            scannedFileCount: 1,
            reusedSessionCount: 0,
            errors: [])

        _ = try TokenHistoryStore(fileURL: sandbox.fileURL).merge(refreshResult: result)
        let loaded = try TokenHistoryStore(fileURL: sandbox.fileURL).load()

        XCTAssertEqual(loaded.hours.count, 1)
        XCTAssertEqual(loaded.hours.first?.hourStart, hourStart)
        XCTAssertEqual(loaded.fiveMinuteBuckets.count, 1)
        XCTAssertEqual(loaded.fiveMinuteBuckets.first?.bucketStart, bucketStart)
        XCTAssertEqual(loaded.sessions["session-123"]?.hourlyBuckets.first?.totalTokens, 20)
        XCTAssertEqual(loaded.sessions["session-123"]?.fiveMinuteBuckets.first?.totalTokens, 20)
        XCTAssertEqual(loaded.sessions["session-123"]?.outboundMessageDailyBuckets.first?.sentCharacters, 120)
        XCTAssertEqual(loaded.outboundMessageDays.first?.sentMessages, 3)
    }

    func test_loadForDisplaySkipsSessionFiveMinuteBucketsAndBuildsRegularSeries() throws {
        let sandbox = try HistorySandbox()
        let hourStart = Date(timeIntervalSince1970: 1_773_225_600)
        let document = TokenHistoryDocument(
            sessions: [
                "regular": SessionUsageSnapshot(
                    sessionID: "regular",
                    sessionOriginKind: .regular,
                    sourceFile: "/tmp/regular.jsonl",
                    sourceFileSize: 111,
                    sourceFileModificationTime: nil,
                    lastEventAt: hourStart,
                    scanVersion: 11,
                    dailyBuckets: [
                        DailyTokenStats(
                            date: "2026-03-11",
                            inputTokens: 12,
                            outputTokens: 8,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 20),
                    ],
                    hourlyBuckets: [
                        HourlyTokenStats(
                            hourStart: hourStart,
                            inputTokens: 12,
                            outputTokens: 8,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 20),
                    ],
                    fiveMinuteBuckets: [
                        FiveMinuteTokenStats(
                            bucketStart: hourStart,
                            inputTokens: 12,
                            outputTokens: 8,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 20),
                    ]),
                "subagent": SessionUsageSnapshot(
                    sessionID: "subagent",
                    sessionOriginKind: .subagentThreadSpawn,
                    sourceFile: "/tmp/subagent.jsonl",
                    sourceFileSize: 222,
                    sourceFileModificationTime: nil,
                    lastEventAt: hourStart,
                    scanVersion: 11,
                    dailyBuckets: [
                        DailyTokenStats(
                            date: "2026-03-11",
                            inputTokens: 4,
                            outputTokens: 1,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 5),
                    ],
                    hourlyBuckets: [
                        HourlyTokenStats(
                            hourStart: hourStart,
                            inputTokens: 4,
                            outputTokens: 1,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 5),
                    ],
                    fiveMinuteBuckets: [
                        FiveMinuteTokenStats(
                            bucketStart: hourStart,
                            inputTokens: 4,
                            outputTokens: 1,
                            cachedInputTokens: 0,
                            reasoningOutputTokens: 0,
                            totalTokens: 5),
                    ]),
            ],
            days: [
                DailyTokenStats(
                    date: "2026-03-11",
                    inputTokens: 16,
                    outputTokens: 9,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 25),
            ],
            hours: [
                HourlyTokenStats(
                    hourStart: hourStart,
                    inputTokens: 16,
                    outputTokens: 9,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 25),
            ],
            fiveMinuteBuckets: [
                FiveMinuteTokenStats(
                    bucketStart: hourStart,
                    inputTokens: 16,
                    outputTokens: 9,
                    cachedInputTokens: 0,
                    reasoningOutputTokens: 0,
                    totalTokens: 25),
            ],
            outboundMessageDays: [
                DailyOutboundMessageStats(
                    date: "2026-03-11",
                    sentCharacters: 120,
                    sentMessages: 3),
            ],
            lastRefreshAt: hourStart)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(document).write(to: sandbox.fileURL, options: .atomic)

        let loaded = try TokenHistoryStore(fileURL: sandbox.fileURL).loadForDisplay()

        XCTAssertEqual(loaded.days.first?.totalTokens, 25)
        XCTAssertEqual(loaded.hours.first?.totalTokens, 25)
        XCTAssertEqual(loaded.regularDays.first?.totalTokens, 20)
        XCTAssertEqual(loaded.regularHours.first?.totalTokens, 20)
        XCTAssertEqual(loaded.outboundMessageDays.first?.sentMessages, 3)
        XCTAssertEqual(loaded.lastRefreshAt, hourStart)
    }
}

private struct HistorySandbox {
    let fileURL: URL

    init() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        self.fileURL = root.appendingPathComponent("token_stats.json", isDirectory: false)
    }
}
