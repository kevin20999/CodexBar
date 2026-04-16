import CodexBarCore
import XCTest
@testable import CodexBar

@MainActor
final class DashboardOverviewModelTests: XCTestCase {
    func test_modelBuildsSparkAndCodeReviewPresentations() throws {
        let strings = AppStrings(language: .zhHans)
        let now = try self.fixedDate(year: 2026, month: 3, day: 22, hour: 12, minute: 0)
        let snapshot = OpenAIDashboardSnapshot(
            signedInEmail: "person@example.com",
            codeReviewRemainingPercent: 61,
            creditEvents: [],
            dailyBreakdown: [],
            usageBreakdown: [],
            creditsPurchaseURL: nil,
            primaryLimit: RateWindow(
                usedPercent: 44,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: "00:04"),
            secondaryLimit: RateWindow(
                usedPercent: 33,
                windowMinutes: 14 * 24 * 60,
                resetsAt: nil,
                resetDescription: "Reset time: Mar 18, 2026"),
            sparkPrimaryLimit: RateWindow(
                usedPercent: 22,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: "00:30"),
            sparkSecondaryLimit: RateWindow(
                usedPercent: 18,
                windowMinutes: 14 * 24 * 60,
                resetsAt: nil,
                resetDescription: "Reset time: Mar 18, 2026"),
            creditsRemaining: 19,
            accountPlan: "Plus",
            updatedAt: Date(timeIntervalSince1970: 1_741_740_000))

        let model = DashboardOverviewModel(snapshot: snapshot, strings: strings, isStale: true, now: now)

        XCTAssertTrue(model.sparkHasQuotaData)
        XCTAssertTrue(model.showsSparkQuotaCard)
        XCTAssertEqual(model.sparkQuotaItems.count, 2)
        XCTAssertEqual(model.sparkQuotaItems[0].title, "5 小时")
        XCTAssertEqual(model.sparkQuotaItems[0].remainingPercent, 78, accuracy: 0.01)
        XCTAssertEqual(model.sparkQuotaItems[0].progressFraction, 0.78, accuracy: 0.001)
        XCTAssertEqual(model.sparkQuotaItems[0].resetText, "00:30")
        XCTAssertEqual(model.sparkQuotaItems[0].accent, .primary)
        XCTAssertTrue(model.sparkQuotaItems[0].isStale)

        XCTAssertEqual(model.sparkQuotaItems[1].title, "2 周")
        XCTAssertEqual(model.sparkQuotaItems[1].resetText, "3月18日")
        XCTAssertEqual(model.sparkQuotaItems[1].accent, .secondary)

        let codeReview = try XCTUnwrap(model.codeReview)
        XCTAssertEqual(codeReview.title, strings.codeReviewTitle)
        XCTAssertEqual(codeReview.remainingPercent, 61, accuracy: 0.01)
        XCTAssertEqual(codeReview.progressFraction, 0.61, accuracy: 0.001)
        XCTAssertEqual(codeReview.accent, .review)
        XCTAssertEqual(model.credits?.title, strings.quotaCreditsLabel)
        XCTAssertEqual(model.credits?.valueText, "19")
        XCTAssertEqual(model.accountEmail, "person@example.com")
        XCTAssertEqual(model.accountHeaderText, "person")
        XCTAssertEqual(model.accountPlan, "Plus")
        XCTAssertTrue(model.showsAccountHeader)
    }

    func test_modelKeepsOnlyEmailWhenPlanMissing() {
        let model = DashboardOverviewModel(
            snapshot: OpenAIDashboardSnapshot(
                signedInEmail: "person@example.com",
                codeReviewRemainingPercent: nil,
                creditEvents: [],
                dailyBreakdown: [],
                usageBreakdown: [],
                creditsPurchaseURL: nil,
                primaryLimit: nil,
                secondaryLimit: nil,
                creditsRemaining: nil,
                accountPlan: "   ",
                updatedAt: Date(timeIntervalSince1970: 1_741_740_000)),
            strings: AppStrings(language: .en),
            isStale: false)

        XCTAssertEqual(model.accountEmail, "person@example.com")
        XCTAssertEqual(model.accountHeaderText, "person")
        XCTAssertNil(model.accountPlan)
        XCTAssertTrue(model.showsAccountHeader)
    }

    func test_modelShortensLongAccountHeaderText() {
        let model = DashboardOverviewModel(
            snapshot: OpenAIDashboardSnapshot(
                signedInEmail: "kevin2.0.163@gmail.com",
                codeReviewRemainingPercent: nil,
                creditEvents: [],
                dailyBreakdown: [],
                usageBreakdown: [],
                creditsPurchaseURL: nil,
                primaryLimit: nil,
                secondaryLimit: nil,
                creditsRemaining: nil,
                accountPlan: "Plus",
                updatedAt: Date(timeIntervalSince1970: 1_741_740_000)),
            strings: AppStrings(language: .zhHans),
            isStale: false)

        XCTAssertEqual(model.accountEmail, "kevin2.0.163@gmail.com")
        XCTAssertEqual(model.accountHeaderText, "kevin2.0.1…")
    }

    func test_modelHidesAccountHeaderWithoutEmailOrPlan() {
        let model = DashboardOverviewModel(
            snapshot: OpenAIDashboardSnapshot(
                signedInEmail: "  ",
                codeReviewRemainingPercent: nil,
                creditEvents: [],
                dailyBreakdown: [],
                usageBreakdown: [],
                creditsPurchaseURL: nil,
                primaryLimit: nil,
                secondaryLimit: nil,
                creditsRemaining: nil,
                accountPlan: nil,
                updatedAt: Date(timeIntervalSince1970: 1_741_740_000)),
            strings: AppStrings(language: .en),
            isStale: false)

        XCTAssertNil(model.accountEmail)
        XCTAssertNil(model.accountHeaderText)
        XCTAssertNil(model.accountPlan)
        XCTAssertFalse(model.showsAccountHeader)
        XCTAssertNotNil(model.updatedDescription)
    }

    func test_modelReturnsEmptyStateWithoutSnapshot() {
        let model = DashboardOverviewModel(
            snapshot: nil,
            strings: AppStrings(language: .en),
            isStale: false)

        XCTAssertTrue(model.sparkQuotaItems.isEmpty)
        XCTAssertNil(model.codeReview)
        XCTAssertNil(model.credits)
        XCTAssertNil(model.accountEmail)
        XCTAssertNil(model.accountHeaderText)
        XCTAssertNil(model.accountPlan)
        XCTAssertFalse(model.showsAccountHeader)
        XCTAssertNil(model.updatedDescription)
        XCTAssertTrue(model.usageBreakdown.isEmpty)
        XCTAssertTrue(model.creditsHistory.isEmpty)
        XCTAssertFalse(model.showsSparkQuotaCard)
    }

    func test_modelShowsSparkQuotaCardWhenSparkDataExistsWithoutProPlan() {
        let strings = AppStrings(language: .en)
        let now = Date(timeIntervalSince1970: 1_742_644_800)
        let sparkPrimary = RateWindow(
            usedPercent: 22,
            windowMinutes: 5 * 60,
            resetsAt: nil,
            resetDescription: "Reset time: 00:30")
        let sparkSecondary = RateWindow(
            usedPercent: 18,
            windowMinutes: 7 * 24 * 60,
            resetsAt: nil,
            resetDescription: "Reset time: Mar 20, 2026")

        let model = DashboardOverviewModel(
            snapshot: OpenAIDashboardSnapshot(
                signedInEmail: "person@example.com",
                codeReviewRemainingPercent: nil,
                creditEvents: [],
                dailyBreakdown: [],
                usageBreakdown: [],
                creditsPurchaseURL: nil,
                primaryLimit: nil,
                secondaryLimit: nil,
                sparkPrimaryLimit: sparkPrimary,
                sparkSecondaryLimit: sparkSecondary,
                creditsRemaining: nil,
                accountPlan: "Plus",
                updatedAt: Date(timeIntervalSince1970: 1_741_740_000)),
            strings: strings,
            isStale: false,
            now: now)

        XCTAssertTrue(model.showsSparkQuotaCard)
        XCTAssertTrue(model.sparkHasQuotaData)
        XCTAssertEqual(model.sparkQuotaItems.count, 2)
        XCTAssertEqual(model.sparkQuotaItems[0].remainingPercent, 78, accuracy: 0.01)
        XCTAssertEqual(model.sparkQuotaItems[1].remainingPercent, 82, accuracy: 0.01)
        XCTAssertEqual(model.sparkQuotaItems[0].resetText, strings.quotaDetailText(for: sparkPrimary, now: now))
        XCTAssertEqual(model.sparkQuotaItems[1].resetText, strings.quotaDetailText(for: sparkSecondary, now: now))
    }

    func test_modelUsesCompactDateTimeForSparkWeeklyQuotaReset() throws {
        let strings = AppStrings(language: .zhHans)
        let now = try self.fixedDate(year: 2026, month: 3, day: 22, hour: 12, minute: 0)
        let resetDate = try self.fixedDate(year: 2026, month: 3, day: 26, hour: 11, minute: 11)
        let snapshot = OpenAIDashboardSnapshot(
            signedInEmail: "person@example.com",
            codeReviewRemainingPercent: nil,
            creditEvents: [],
            dailyBreakdown: [],
            usageBreakdown: [],
            creditsPurchaseURL: nil,
            primaryLimit: nil,
            secondaryLimit: nil,
            sparkPrimaryLimit: RateWindow(
                usedPercent: 22,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: "00:30"),
            sparkSecondaryLimit: RateWindow(
                usedPercent: 18,
                windowMinutes: 7 * 24 * 60,
                resetsAt: resetDate,
                resetDescription: nil),
            creditsRemaining: nil,
            accountPlan: "Plus",
            updatedAt: Date(timeIntervalSince1970: 1_741_740_000))

        let model = DashboardOverviewModel(snapshot: snapshot, strings: strings, isStale: false, now: now)

        XCTAssertEqual(model.sparkQuotaItems.count, 2)
        XCTAssertEqual(model.sparkQuotaItems[1].resetText, "3.26 11:11 · 剩 4 天 · 日均 20%")
    }

    func test_modelHidesSparkQuotaCardWithoutSparkData() {
        let model = DashboardOverviewModel(
            snapshot: OpenAIDashboardSnapshot(
                signedInEmail: "person@example.com",
                codeReviewRemainingPercent: nil,
                creditEvents: [],
                dailyBreakdown: [],
                usageBreakdown: [],
                creditsPurchaseURL: nil,
                primaryLimit: nil,
                secondaryLimit: nil,
                creditsRemaining: nil,
                accountPlan: "Pro",
                updatedAt: Date(timeIntervalSince1970: 1_741_740_000)),
            strings: AppStrings(language: .en),
            isStale: false)

        XCTAssertFalse(model.showsSparkQuotaCard)
        XCTAssertFalse(model.sparkHasQuotaData)
        XCTAssertTrue(model.sparkQuotaItems.isEmpty)
    }

    func test_modelPrefersExplicitSparkWindowsOverDashboardSnapshot() {
        let strings = AppStrings(language: .en)
        let explicitPrimary = RateWindow(
            usedPercent: 8,
            windowMinutes: 5 * 60,
            resetsAt: nil,
            resetDescription: "Reset time: 02:00")
        let explicitSecondary = RateWindow(
            usedPercent: 12,
            windowMinutes: 7 * 24 * 60,
            resetsAt: nil,
            resetDescription: "Reset time: Apr 17")
        let snapshot = OpenAIDashboardSnapshot(
            signedInEmail: "person@example.com",
            codeReviewRemainingPercent: nil,
            creditEvents: [],
            dailyBreakdown: [],
            usageBreakdown: [],
            creditsPurchaseURL: nil,
            primaryLimit: nil,
            secondaryLimit: nil,
            sparkPrimaryLimit: RateWindow(
                usedPercent: 33,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: "Reset time: 00:30"),
            sparkSecondaryLimit: nil,
            creditsRemaining: nil,
            accountPlan: "Plus",
            updatedAt: Date(timeIntervalSince1970: 1_741_740_000))

        let model = DashboardOverviewModel(
            snapshot: snapshot,
            sparkPrimaryLimit: explicitPrimary,
            sparkSecondaryLimit: explicitSecondary,
            strings: strings,
            isStale: false,
            sparkIsStale: false)

        XCTAssertEqual(model.sparkQuotaItems.count, 2)
        XCTAssertEqual(model.sparkQuotaItems[0].remainingPercent, 92, accuracy: 0.01)
        XCTAssertEqual(model.sparkQuotaItems[0].resetText, "Reset time: 02:00")
        XCTAssertEqual(model.sparkQuotaItems[1].remainingPercent, 88, accuracy: 0.01)
        XCTAssertEqual(model.sparkQuotaItems[1].resetText, "Reset time: Apr 17")
    }

    func test_modelBuildsSparkPresentationWithoutDashboardSnapshot() {
        let strings = AppStrings(language: .zhHans)
        let model = DashboardOverviewModel(
            snapshot: nil,
            sparkPrimaryLimit: RateWindow(
                usedPercent: 9,
                windowMinutes: 5 * 60,
                resetsAt: nil,
                resetDescription: "02:00"),
            strings: strings,
            isStale: false,
            sparkIsStale: true)

        XCTAssertTrue(model.sparkHasQuotaData)
        XCTAssertTrue(model.showsSparkQuotaCard)
        XCTAssertEqual(model.sparkQuotaItems.count, 1)
        XCTAssertEqual(model.sparkQuotaItems[0].remainingPercent, 91, accuracy: 0.01)
        XCTAssertTrue(model.sparkQuotaItems[0].isStale)
        XCTAssertNil(model.accountEmail)
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
