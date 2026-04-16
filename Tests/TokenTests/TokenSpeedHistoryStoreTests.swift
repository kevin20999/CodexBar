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
}
