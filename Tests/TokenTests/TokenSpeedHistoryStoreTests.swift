import Foundation
import XCTest
@testable import CodexBar

final class TokenSpeedHistoryStoreTests: XCTestCase {
    func test_upsertPersistsAndOverwritesSamplesBySecond() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("token_speed_history.json", isDirectory: false)
        let store = TokenSpeedHistoryStore(fileURL: fileURL)
        let timestamp = Date(timeIntervalSince1970: 1_800_000_000)

        _ = try store.upsert(sample: TokenSpeedSample(timestamp: timestamp, tokens: 12))
        _ = try store.upsert(sample: TokenSpeedSample(timestamp: timestamp, tokens: 48))

        let loaded = try store.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first, TokenSpeedSample(timestamp: timestamp, tokens: 48))
    }

    func test_upsertKeepsSamplesSortedAscending() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("token_speed_history.json", isDirectory: false)
        let store = TokenSpeedHistoryStore(fileURL: fileURL)

        _ = try store.upsert(sample: TokenSpeedSample(
            timestamp: Date(timeIntervalSince1970: 1_800_000_010),
            tokens: 10))
        _ = try store.upsert(sample: TokenSpeedSample(
            timestamp: Date(timeIntervalSince1970: 1_800_000_000),
            tokens: 30))

        let loaded = try store.load()
        XCTAssertEqual(loaded.map(\.tokens), [30, 10])
    }

    func test_saveKeepsOnlyLatestHundredSamples() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("token_speed_history.json", isDirectory: false)
        let store = TokenSpeedHistoryStore(fileURL: fileURL)
        let baseTimestamp = Date(timeIntervalSince1970: 1_800_000_000)
        let samples = (0..<150).map { offset in
            TokenSpeedSample(
                timestamp: baseTimestamp.addingTimeInterval(Double(offset)),
                tokens: offset + 1)
        }

        try store.save(samples: samples, keepingLatest: 100)

        let loaded = try store.load()
        XCTAssertEqual(loaded.count, 100)
        XCTAssertEqual(loaded.first?.tokens, 51)
        XCTAssertEqual(loaded.last?.tokens, 150)
    }

    func test_loadLatestHundredDeduplicatesSameSecond() throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("token_speed_history.json", isDirectory: false)
        let store = TokenSpeedHistoryStore(fileURL: fileURL)
        let baseTimestamp = Date(timeIntervalSince1970: 1_800_000_000)
        let duplicateTimestamp = baseTimestamp.addingTimeInterval(149)
        let samples = (0..<150).map { offset in
            TokenSpeedSample(
                timestamp: baseTimestamp.addingTimeInterval(Double(offset)),
                tokens: offset + 1)
        } + [
            TokenSpeedSample(timestamp: duplicateTimestamp, tokens: 999),
        ]

        try store.save(samples: samples, keepingLatest: 100)

        let loaded = try store.load(limitToLatest: 100)
        XCTAssertEqual(loaded.count, 100)
        XCTAssertEqual(loaded.last, TokenSpeedSample(timestamp: duplicateTimestamp, tokens: 999))
        XCTAssertEqual(loaded.filter { $0.timestamp == duplicateTimestamp }.count, 1)
    }
}
