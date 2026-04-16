import Foundation
import XCTest
@testable import CodexBarCore

final class RemainingQuotaTests: XCTestCase {
    func test_dashboardCacheStoreWritesSecureFilePermissions() throws {
        OpenAIDashboardCacheStore.clear()
        OpenAIDashboardCacheStore.save(OpenAIDashboardCache(
            accountEmail: "person@example.com",
            snapshot: OpenAIDashboardSnapshot(
                signedInEmail: "person@example.com",
                codeReviewRemainingPercent: 61,
                creditEvents: [],
                dailyBreakdown: [],
                usageBreakdown: [],
                creditsPurchaseURL: nil,
                primaryLimit: RateWindow(usedPercent: 44, windowMinutes: 300, resetsAt: nil, resetDescription: nil),
                secondaryLimit: nil,
                creditsRemaining: 19,
                accountPlan: "Plus",
                updatedAt: Date())))

        let fileURL = try XCTUnwrap(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first)
            .appendingPathComponent("CodexBar", isDirectory: true)
            .appendingPathComponent("openai_dashboard.json", isDirectory: false)
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let permissions = try XCTUnwrap(attributes[.posixPermissions] as? NSNumber)
        XCTAssertEqual(permissions.intValue, 0o600)
    }

    func test_parserExtractsQuotaWindowsCreditsAndCodeReview() {
        let body = """
        5-hour limit
        56% remaining
        Resets today 00:04
        Weekly limit
        67% remaining
        Resets Mar 18
        Credits remaining 31.5
        Code review 72% remaining
        """

        let now = Date(timeIntervalSince1970: 1_741_720_000)
        let windows = OpenAIDashboardParser.parseRateLimits(bodyText: body, now: now)
        let credits = OpenAIDashboardParser.parseCreditsRemaining(bodyText: body)
        let codeReview = OpenAIDashboardParser.parseCodeReviewRemainingPercent(bodyText: body)

        XCTAssertEqual(Int(windows.primary?.remainingPercent.rounded() ?? -1), 56)
        XCTAssertEqual(windows.primary?.windowMinutes, 5 * 60)
        XCTAssertEqual(Int(windows.secondary?.remainingPercent.rounded() ?? -1), 67)
        XCTAssertEqual(windows.secondary?.windowMinutes, 7 * 24 * 60)
        XCTAssertEqual(credits, 31.5)
        XCTAssertEqual(codeReview, 72)
    }

    func test_parserExtractsLocalizedQuotaWindowsCreditsAndCodeReview() throws {
        let body = """
        5 小时
        56%
        00:04
        2 周
        67%
        3月18日
        剩余 Credits
        19
        Code review
        61% 剩余
        """

        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 12
        components.hour = 10
        components.minute = 30
        components.timeZone = TimeZone(identifier: "Asia/Shanghai")
        let now = try XCTUnwrap(calendar.date(from: components))

        let windows = OpenAIDashboardParser.parseRateLimits(bodyText: body, now: now)
        let credits = OpenAIDashboardParser.parseCreditsRemaining(bodyText: body)
        let codeReview = OpenAIDashboardParser.parseCodeReviewRemainingPercent(bodyText: body)

        XCTAssertEqual(Int(windows.primary?.remainingPercent.rounded() ?? -1), 56)
        XCTAssertEqual(windows.primary?.windowMinutes, 5 * 60)
        XCTAssertEqual(Int(windows.secondary?.remainingPercent.rounded() ?? -1), 67)
        XCTAssertEqual(windows.secondary?.windowMinutes, 7 * 24 * 60)
        XCTAssertEqual(credits, 19)
        XCTAssertEqual(codeReview, 61)

        let resetAt = try XCTUnwrap(windows.primary?.resetsAt)
        let resetComponents = calendar.dateComponents([.hour, .minute], from: resetAt)
        XCTAssertEqual(resetComponents.hour, 0)
        XCTAssertEqual(resetComponents.minute, 4)
    }

    func test_parserSeparatesGeneralAndSparkQuotaWindowsFromMixedEnglishBody() {
        let body = """
        5-hour limit
        56% remaining
        Resets today 00:04
        Weekly limit
        67% remaining
        Resets Mar 18
        GPT-5.3-Codex-Spark 5-hour limit
        98% remaining
        Resets today 14:15
        GPT-5.3-Codex-Spark Weekly limit
        100% remaining
        Resets Mar 26
        """

        let windows = OpenAIDashboardParser.parseGroupedRateLimits(bodyText: body)

        XCTAssertEqual(Int(windows.primary?.remainingPercent.rounded() ?? -1), 56)
        XCTAssertEqual(Int(windows.secondary?.remainingPercent.rounded() ?? -1), 67)
        XCTAssertEqual(Int(windows.sparkPrimary?.remainingPercent.rounded() ?? -1), 98)
        XCTAssertEqual(Int(windows.sparkSecondary?.remainingPercent.rounded() ?? -1), 100)
    }

    func test_parserSeparatesGeneralAndSparkQuotaWindowsFromLocalizedBody() {
        let body = """
        5 小时使用限额
        100% 剩余
        00:04
        每周使用限额
        82% 剩余
        2026年3月26日 6:13
        GPT-5.3-Codex-Spark 5 小时使用限额
        98% 剩余
        14:15
        GPT-5.3-Codex-Spark 每周使用限额
        100% 剩余
        2026年3月26日 6:13
        """

        let windows = OpenAIDashboardParser.parseGroupedRateLimits(bodyText: body)

        XCTAssertEqual(Int(windows.primary?.remainingPercent.rounded() ?? -1), 100)
        XCTAssertEqual(Int(windows.secondary?.remainingPercent.rounded() ?? -1), 82)
        XCTAssertEqual(Int(windows.sparkPrimary?.remainingPercent.rounded() ?? -1), 98)
        XCTAssertEqual(Int(windows.sparkSecondary?.remainingPercent.rounded() ?? -1), 100)
    }

    func test_snapshotDecodesWhenSparkFieldsAreMissing() throws {
        let json = """
        {
          "signedInEmail": "user@example.com",
          "codeReviewRemainingPercent": 42,
          "creditEvents": [],
          "dailyBreakdown": [],
          "updatedAt": "2025-12-18T00:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(OpenAIDashboardSnapshot.self, from: Data(json.utf8))

        XCTAssertNil(snapshot.sparkPrimaryLimit)
        XCTAssertNil(snapshot.sparkSecondaryLimit)
    }

    func test_codexQuotaDebugSnapshotMapsSparkRateLimitsFromAdditionalRateLimits() throws {
        let json = """
        {
          "plan_type": "pro",
          "rate_limit": {
            "primary_window": {
              "used_percent": 14,
              "reset_at": 1775840000,
              "limit_window_seconds": 18000
            },
            "secondary_window": {
              "used_percent": 12,
              "reset_at": 1775900000,
              "limit_window_seconds": 604800
            }
          },
          "additional_rate_limits": [
            {
              "limit_name": "GPT-5.3-Codex-Spark",
              "metered_feature": "codex_bengalfox",
              "rate_limit": {
                "primary_window": {
                  "used_percent": 1,
                  "reset_at": 1775844368,
                  "limit_window_seconds": 18000
                },
                "secondary_window": {
                  "used_percent": 13,
                  "reset_at": 1775838163,
                  "limit_window_seconds": 604800
                }
              }
            }
          ]
        }
        """

        let snapshot = try CodexQuotaProvider.debugSnapshot(
            fromUsageResponseData: Data(json.utf8),
            accountEmail: "person@example.com",
            accountPlan: "Pro")

        XCTAssertEqual(snapshot.primary?.usedPercent, 14, accuracy: 0.01)
        XCTAssertEqual(snapshot.secondary?.usedPercent, 12, accuracy: 0.01)
        XCTAssertEqual(snapshot.sparkPrimary?.usedPercent, 1, accuracy: 0.01)
        XCTAssertEqual(snapshot.sparkPrimary?.windowMinutes, 5 * 60)
        XCTAssertEqual(snapshot.sparkSecondary?.usedPercent, 13, accuracy: 0.01)
        XCTAssertEqual(snapshot.sparkSecondary?.windowMinutes, 7 * 24 * 60)
    }

    func test_codexQuotaDebugSnapshotIgnoresUnrelatedAdditionalRateLimits() throws {
        let json = """
        {
          "plan_type": "pro",
          "rate_limit": {
            "primary_window": {
              "used_percent": 14,
              "reset_at": 1775840000,
              "limit_window_seconds": 18000
            }
          },
          "additional_rate_limits": [
            {
              "limit_name": "Code Review",
              "metered_feature": "code_review",
              "rate_limit": {
                "primary_window": {
                  "used_percent": 44,
                  "reset_at": 1775844368,
                  "limit_window_seconds": 18000
                }
              }
            }
          ]
        }
        """

        let snapshot = try CodexQuotaProvider.debugSnapshot(fromUsageResponseData: Data(json.utf8))

        XCTAssertNil(snapshot.sparkPrimary)
        XCTAssertNil(snapshot.sparkSecondary)
    }

    func test_codexQuotaDebugSnapshotMatchesSparkByMeteredFeatureWhenLimitNameIsMissing() throws {
        let json = """
        {
          "plan_type": "pro",
          "additional_rate_limits": [
            {
              "metered_feature": "codex_bengalfox",
              "rate_limit": {
                "primary_window": {
                  "used_percent": 8,
                  "reset_at": 1775844368,
                  "limit_window_seconds": 18000
                },
                "secondary_window": {
                  "used_percent": 21,
                  "reset_at": 1775838163,
                  "limit_window_seconds": 604800
                }
              }
            }
          ]
        }
        """

        let snapshot = try CodexQuotaProvider.debugSnapshot(fromUsageResponseData: Data(json.utf8))

        XCTAssertEqual(snapshot.sparkPrimary?.usedPercent, 8, accuracy: 0.01)
        XCTAssertEqual(snapshot.sparkSecondary?.usedPercent, 21, accuracy: 0.01)
    }

    func test_authReaderParsesEmailFromJWT() throws {
        let payload = #"{"email":"person@example.com","chatgpt_plan_type":"plus"}"#
        let base64 = Data(payload.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let token = "header.\(base64).signature"

        let parsed = try XCTUnwrap(CodexAuthAccountReader.parseJWT(token))
        XCTAssertEqual(parsed["email"] as? String, "person@example.com")
        XCTAssertEqual(parsed["chatgpt_plan_type"] as? String, "plus")
    }
}
