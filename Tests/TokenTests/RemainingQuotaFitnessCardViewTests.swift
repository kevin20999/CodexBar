import AppKit
import Foundation
import SwiftUI
import XCTest
@testable import CodexBar

final class RemainingQuotaFitnessCardViewTests: XCTestCase {
    func test_visibleTitleKeepsHeaderVisible() {
        XCTAssertTrue(
            RemainingQuotaFitnessHeaderVisibility.shouldShowHeader(
                showsTitle: true,
                showsCachedBadge: false,
                isRefreshing: false,
                metadataText: nil))
    }

    func test_hiddenTitleWithoutBadgeRefreshOrMetadataHidesHeader() {
        XCTAssertFalse(
            RemainingQuotaFitnessHeaderVisibility.shouldShowHeader(
                showsTitle: false,
                showsCachedBadge: false,
                isRefreshing: false,
                metadataText: nil))
    }

    func test_hiddenTitleWithCachedBadgeKeepsHeaderVisible() {
        XCTAssertTrue(
            RemainingQuotaFitnessHeaderVisibility.shouldShowHeader(
                showsTitle: false,
                showsCachedBadge: true,
                isRefreshing: false,
                metadataText: nil))
    }

    func test_hiddenTitleWithMetadataKeepsHeaderVisible() {
        let metadataText = RemainingQuotaFitnessHeaderVisibility.metadataText(
            accountHeaderText: "person",
            accountPlan: "Plus",
            updatedDescription: "Updated just now")

        XCTAssertEqual(
            String(metadataText?.characters ?? AttributedString().characters),
            "person  •  Plus  •  Updated just now")
        XCTAssertTrue(
            RemainingQuotaFitnessHeaderVisibility.shouldShowHeader(
                showsTitle: false,
                showsCachedBadge: false,
                isRefreshing: false,
                metadataText: metadataText))
    }

    func test_metadataLinksAccountNameAndPlanOnly() throws {
        let url = try XCTUnwrap(URL(string: "https://chatgpt.com/codex/settings/usage"))
        let metadataText = try XCTUnwrap(RemainingQuotaFitnessHeaderVisibility.metadataText(
            accountHeaderText: "person",
            accountPlan: "Pro Plus",
            updatedDescription: "Updated just now",
            metadataLinkURL: url))

        XCTAssertEqual(String(metadataText.characters), "person  •  Pro Plus  •  Updated just now")
        XCTAssertEqual(self.link(in: metadataText, matching: "person"), url)
        XCTAssertEqual(self.link(in: metadataText, matching: "Pro Plus"), url)
        XCTAssertNil(self.link(in: metadataText, matching: "Updated just now"))
    }

    func test_metadataLinksOnlyPresentAccountSegments() throws {
        let url = try XCTUnwrap(URL(string: "https://chatgpt.com/codex/settings/usage"))
        let accountOnly = try XCTUnwrap(RemainingQuotaFitnessHeaderVisibility.metadataText(
            accountHeaderText: "person",
            accountPlan: nil,
            updatedDescription: nil,
            metadataLinkURL: url))
        let planOnly = try XCTUnwrap(RemainingQuotaFitnessHeaderVisibility.metadataText(
            accountHeaderText: nil,
            accountPlan: "Pro Plus",
            updatedDescription: nil,
            metadataLinkURL: url))

        XCTAssertEqual(self.link(in: accountOnly, matching: "person"), url)
        XCTAssertEqual(self.link(in: planOnly, matching: "Pro Plus"), url)
    }

    func test_metadataWithoutLinkURLStaysPlainText() throws {
        let metadataText = try XCTUnwrap(RemainingQuotaFitnessHeaderVisibility.metadataText(
            accountHeaderText: "person",
            accountPlan: "Pro Plus",
            updatedDescription: "Updated just now"))

        XCTAssertNil(self.link(in: metadataText, matching: "person"))
        XCTAssertNil(self.link(in: metadataText, matching: "Pro Plus"))
        XCTAssertNil(self.link(in: metadataText, matching: "Updated just now"))
    }

    func test_statusVisibilityHidesFooterWhenQuotaDataExistsWithoutError() {
        let statusMessage = RemainingQuotaFitnessStatusVisibility.statusMessage(
            errorMessage: nil,
            hasQuotaData: true,
            emptyMessage: "Unavailable")

        XCTAssertNil(statusMessage)
        XCTAssertFalse(RemainingQuotaFitnessStatusVisibility.shouldShowFooter(for: statusMessage))
    }

    func test_statusVisibilityShowsFooterWhenQuotaDataIsMissing() {
        let statusMessage = RemainingQuotaFitnessStatusVisibility.statusMessage(
            errorMessage: nil,
            hasQuotaData: false,
            emptyMessage: "Unavailable")

        XCTAssertEqual(statusMessage, "Unavailable")
        XCTAssertTrue(RemainingQuotaFitnessStatusVisibility.shouldShowFooter(for: statusMessage))
    }

    func test_statusVisibilityPrefersTrimmedErrorMessage() {
        let statusMessage = RemainingQuotaFitnessStatusVisibility.statusMessage(
            errorMessage: "  Request failed  ",
            hasQuotaData: true,
            emptyMessage: "Unavailable")

        XCTAssertEqual(statusMessage, "Request failed")
        XCTAssertTrue(RemainingQuotaFitnessStatusVisibility.shouldShowFooter(for: statusMessage))
    }

    func test_headerLayoutMetricsReserveStableSpinnerSlot() {
        XCTAssertEqual(RemainingQuotaFitnessHeaderLayoutMetrics.spinnerSlotSize(compactMode: false), 16)
        XCTAssertEqual(RemainingQuotaFitnessHeaderLayoutMetrics.spinnerSlotSize(compactMode: true), 14)
        XCTAssertEqual(RemainingQuotaFitnessHeaderLayoutMetrics.minHeight(compactMode: false), 20)
        XCTAssertEqual(RemainingQuotaFitnessHeaderLayoutMetrics.minHeight(compactMode: true), 18)
    }

    @MainActor
    func test_refreshingStateDoesNotChangeMeasuredCardHeight() {
        let idleHeight = self.measuredHeight(isRefreshing: false)
        let refreshingHeight = self.measuredHeight(isRefreshing: true)

        XCTAssertEqual(idleHeight, refreshingHeight, accuracy: 1)
    }

    private func link(in text: AttributedString, matching substring: String) -> URL? {
        for run in text.runs {
            let runText = String(text[run.range].characters)
            if runText == substring {
                return run.link
            }
        }
        return nil
    }

    @MainActor
    private func measuredHeight(isRefreshing: Bool) -> CGFloat {
        let view = RemainingQuotaFitnessCardView(
            title: "Codex Quota",
            themeVariant: .general,
            showsTitle: true,
            cachedBadgeTitle: "Cached",
            showsCachedBadge: false,
            cachedActionTitle: nil,
            onCachedAction: nil,
            isRefreshing: isRefreshing,
            accountHeaderText: "person@example.com",
            accountPlan: "Pro",
            updatedDescription: "Updated just now",
            metadataLinkURL: nil,
            quotaItems: [
                QuotaProgressPresentation(
                    title: "5h",
                    remainingPercent: 82,
                    progressFraction: 0.18,
                    resetText: "Resets 13:09",
                    accent: .primary,
                    isStale: false),
                QuotaProgressPresentation(
                    title: "7d",
                    remainingPercent: 56,
                    progressFraction: 0.44,
                    resetText: "Resets 4.17 07:23",
                    accent: .secondary,
                    isStale: false),
            ],
            hasQuotaData: true,
            emptyMessage: "Unavailable",
            errorMessage: nil,
            strings: AppStrings(languageCode: "en"),
            compactMode: false)
        let hostingView = NSHostingView(rootView: view.frame(width: 360))
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 10))
        container.addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: container.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(equalToConstant: 360),
        ])

        container.layoutSubtreeIfNeeded()
        return container.fittingSize.height
    }
}
