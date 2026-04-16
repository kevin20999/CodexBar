import CodexBarCore
import XCTest
@testable import CodexBar

@MainActor
final class CodexQuotaOverviewModelTests: XCTestCase {
    func test_modelBuildsNativeCodexQuotaPresentations() throws {
        let strings = AppStrings(language: .zhHans)
        let now = try self.fixedDate(year: 2026, month: 4, day: 9, hour: 12, minute: 0)
        let snapshot = CodexQuotaSnapshot(
            primary: RateWindow(
                usedPercent: 44,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: "00:04"),
            secondary: RateWindow(
                usedPercent: 33,
                windowMinutes: 7 * 24 * 60,
                resetsAt: nil,
                resetDescription: "Reset time: Apr 15, 2026"),
            updatedAt: Date(timeIntervalSince1970: 1_744_200_000),
            accountEmail: "kevin2.0.163@gmail.com",
            accountPlan: "Pro")

        let model = CodexQuotaOverviewModel(snapshot: snapshot, strings: strings, now: now)

        XCTAssertTrue(model.hasQuotaData)
        XCTAssertEqual(model.quotaItems.count, 2)
        XCTAssertEqual(model.quotaItems[0].title, "5 小时")
        XCTAssertEqual(model.quotaItems[0].remainingPercent, 56, accuracy: 0.01)
        XCTAssertEqual(model.quotaItems[0].resetText, "00:04")
        XCTAssertEqual(model.quotaItems[1].title, "1 周")
        XCTAssertEqual(model.accountEmail, "kevin2.0.163@gmail.com")
        XCTAssertEqual(model.accountHeaderText, "kevin2.0.1…")
        XCTAssertEqual(model.accountPlan, "Pro")
        XCTAssertNotNil(model.updatedDescription)
    }

    func test_modelReturnsEmptyStateWithoutSnapshot() {
        let model = CodexQuotaOverviewModel(
            snapshot: nil,
            strings: AppStrings(language: .en))

        XCTAssertFalse(model.hasQuotaData)
        XCTAssertTrue(model.quotaItems.isEmpty)
        XCTAssertNil(model.accountEmail)
        XCTAssertNil(model.accountHeaderText)
        XCTAssertNil(model.accountPlan)
        XCTAssertNil(model.updatedDescription)
    }

    private func fixedDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) throws -> Date {
        var components = DateComponents()
        components.calendar = Calendar.current
        components.timeZone = TimeZone.current
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return try XCTUnwrap(Calendar.current.date(from: components))
    }
}
