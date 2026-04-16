import Foundation
import XCTest
@testable import CodexBar

final class CodexLiveTokenRateMonitorTests: XCTestCase {
    func test_sampleUsesLastTokenUsageAsDirectDelta() async throws {
        let sandbox = try LiveTokenRateMonitorSandbox()
        let timestamp = Date(timeIntervalSince1970: 1_800_000_000)
        let fileURL = try sandbox.makeSessionFile(named: "session-a.jsonl", contents: "")
        let monitor = CodexLiveTokenRateMonitor(
            sessionRootURL: sandbox.root,
            now: { timestamp })

        await XCTAssertEqual(
            monitor.sample(),
            TokenSpeedSample(timestamp: timestamp, tokens: 0))

        try sandbox.appendLine(
            self.tokenCountLine(
                timestamp: timestamp,
                lastUsage: [
                    "input_tokens": 3,
                    "cached_input_tokens": 2,
                    "output_tokens": 1,
                    "reasoning_output_tokens": 4,
                ]),
            to: fileURL)

        await XCTAssertEqual(
            monitor.sample(),
            TokenSpeedSample(timestamp: timestamp, tokens: 10))
        await XCTAssertEqual(
            monitor.sample(),
            TokenSpeedSample(timestamp: timestamp, tokens: 0))
    }

    func test_sampleDiffsTotalTokenUsageAgainstPreviousTotals() async throws {
        let sandbox = try LiveTokenRateMonitorSandbox()
        let timestamp = Date(timeIntervalSince1970: 1_800_000_100)
        let fileURL = try sandbox.makeSessionFile(
            named: "session-b.jsonl",
            contents: self.tokenCountLine(
                timestamp: timestamp.addingTimeInterval(-2),
                totalUsage: [
                    "input_tokens": 100,
                    "cached_input_tokens": 20,
                    "output_tokens": 10,
                    "reasoning_output_tokens": 5,
                ]))
        let monitor = CodexLiveTokenRateMonitor(
            sessionRootURL: sandbox.root,
            now: { timestamp })

        await XCTAssertEqual(
            monitor.sample(),
            TokenSpeedSample(timestamp: timestamp, tokens: 0))

        try sandbox.appendLine(
            self.tokenCountLine(
                timestamp: timestamp,
                totalUsage: [
                    "input_tokens": 120,
                    "cached_input_tokens": 25,
                    "output_tokens": 16,
                    "reasoning_output_tokens": 7,
                ]),
            to: fileURL)

        await XCTAssertEqual(
            monitor.sample(),
            TokenSpeedSample(timestamp: timestamp, tokens: 33))
    }

    func test_sampleAggregatesAcrossMultipleSessionFiles() async throws {
        let sandbox = try LiveTokenRateMonitorSandbox()
        let timestamp = Date(timeIntervalSince1970: 1_800_000_200)
        let firstFile = try sandbox.makeSessionFile(named: "session-c.jsonl", contents: "")
        let secondFile = try sandbox.makeSessionFile(named: "session-d.jsonl", contents: "")
        let monitor = CodexLiveTokenRateMonitor(
            sessionRootURL: sandbox.root,
            now: { timestamp })

        await XCTAssertEqual(
            monitor.sample(),
            TokenSpeedSample(timestamp: timestamp, tokens: 0))

        try sandbox.appendLine(
            self.tokenCountLine(
                timestamp: timestamp,
                lastUsage: [
                    "input_tokens": 2,
                    "cached_input_tokens": 1,
                    "output_tokens": 1,
                ]),
            to: firstFile)
        try sandbox.appendLine(
            self.tokenCountLine(
                timestamp: timestamp,
                lastUsage: [
                    "input_tokens": 3,
                    "output_tokens": 4,
                ]),
            to: secondFile)

        await XCTAssertEqual(
            monitor.sample(),
            TokenSpeedSample(timestamp: timestamp, tokens: 11))
    }

    private func tokenCountLine(
        timestamp: Date,
        totalUsage: [String: Int]? = nil,
        lastUsage: [String: Int]? = nil) -> String
    {
        var info: [String: Any] = [:]
        if let totalUsage {
            info["total_token_usage"] = totalUsage
        }
        if let lastUsage {
            info["last_token_usage"] = lastUsage
        }

        let payload: [String: Any] = [
            "type": "token_count",
            "info": info,
        ]
        let object: [String: Any] = [
            "type": "event_msg",
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "payload": payload,
        ]

        let data = try! JSONSerialization.data(withJSONObject: object, options: [])
        return String(decoding: data, as: UTF8.self)
    }
}

private struct LiveTokenRateMonitorSandbox {
    let root: URL

    init() throws {
        self.root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: self.root, withIntermediateDirectories: true)
    }

    func makeSessionFile(named name: String, contents: String) throws -> URL {
        let directory = self.root.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent(name, isDirectory: false)
        let initialContents = contents.isEmpty ? "" : contents + "\n"
        try initialContents.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    func appendLine(_ line: String, to fileURL: URL) throws {
        let handle = try FileHandle(forWritingTo: fileURL)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: Data((line + "\n").utf8))
    }
}
