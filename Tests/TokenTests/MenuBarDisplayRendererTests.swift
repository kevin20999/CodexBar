import SwiftUI
import XCTest
@testable import CodexBar

@MainActor
final class MenuBarDisplayRendererTests: XCTestCase {
    func test_quotaRendererSupportsAllQuotaStylesAtSettingsPreviewHeight() {
        let metrics = MenuBarDisplayMetrics(
            inputText: "12.3k",
            outputText: "987",
            quotaPercentText: "56%",
            quotaFraction: 0.56,
            quotaIsStale: false)

        for style in MenuBarQuotaStyle.allCases {
            let rendered = MenuBarDisplayRenderer.render(
                mode: .quota5h,
                metrics: metrics,
                quotaStyle: style,
                targetHeight: 28)

            XCTAssertNotNil(rendered, "Expected settings preview renderer output for \(style.rawValue)")
            XCTAssertEqual(
                Double(rendered?.displaySize.height ?? 0),
                28,
                accuracy: 0.001,
                "Display height should match settings preview target")
        }
    }

    func test_dualRenderersSupportSettingsPreviewHeight() {
        let metrics = MenuBarDisplayMetrics(
            inputText: "12.3k",
            outputText: "987",
            primaryQuota: MenuBarQuotaMetrics(
                shortLabel: "H",
                summaryLabel: "5 hours",
                percentText: "56%",
                compactPercentText: "56",
                fraction: 0.56),
            secondaryQuota: MenuBarQuotaMetrics(
                shortLabel: "W",
                summaryLabel: "1 week",
                percentText: "88%",
                compactPercentText: "88",
                fraction: 0.88),
            quotaIsStale: false)

        for mode in [MenuBarDisplayMode.quotaDualCompact, .quotaDualKnockout] {
            let rendered = MenuBarDisplayRenderer.render(
                mode: mode,
                metrics: metrics,
                quotaStyle: .capsule,
                targetHeight: 28)

            XCTAssertNotNil(rendered, "Expected settings preview renderer output for \(mode.rawValue)")
            XCTAssertEqual(
                Double(rendered?.displaySize.height ?? 0),
                28,
                accuracy: 0.001,
                "Display height should match settings preview target")
        }
    }

    func test_quotaRendererSupportsAllQuotaStylesAcrossStates() {
        let fractions: [Double?] = [nil, 0.21, 0.56, 1.0]
        let staleStates = [false, true]

        for style in MenuBarQuotaStyle.allCases {
            for fraction in fractions {
                for isStale in staleStates {
                    let metrics = MenuBarDisplayMetrics(
                        inputText: "12.3k",
                        outputText: "987",
                        quotaPercentText: Self.percentText(for: fraction),
                        quotaFraction: fraction,
                        quotaIsStale: isStale)

                    let rendered = MenuBarDisplayRenderer.render(
                        mode: .quota5h,
                        metrics: metrics,
                        quotaStyle: style,
                        targetHeight: 19)

                    XCTAssertNotNil(rendered, Self.failureMessage(style: style, fraction: fraction, isStale: isStale))
                    XCTAssertGreaterThan(rendered?.image.size.width ?? 0, 0, "Image width should be positive")
                    XCTAssertGreaterThan(
                        rendered?.image.size.height ?? 0,
                        0,
                        "Image height should be positive")
                    XCTAssertGreaterThan(
                        rendered?.displaySize.width ?? 0,
                        0,
                        "Display width should be positive")
                    XCTAssertEqual(
                        Double(rendered?.displaySize.height ?? 0),
                        19,
                        accuracy: 0.001,
                        "Display height should match target")
                }
            }
        }
    }

    func test_dualCompactRendererSupportsPrimaryAndOptionalSecondaryStates() {
        let fractions: [Double?] = [nil, 0.21, 0.56, 1.0]
        let staleStates = [false, true]

        for primaryFraction in fractions {
            for secondaryFraction in fractions {
                for includesSecondary in [false, true] {
                    for isStale in staleStates {
                        let metrics = MenuBarDisplayMetrics(
                            inputText: "12.3k",
                            outputText: "987",
                            primaryQuota: MenuBarQuotaMetrics(
                                shortLabel: "H",
                                summaryLabel: "5 hours",
                                percentText: Self.percentText(for: primaryFraction),
                                compactPercentText: Self.compactPercentText(for: primaryFraction),
                                fraction: primaryFraction),
                            secondaryQuota: includesSecondary
                                ? MenuBarQuotaMetrics(
                                    shortLabel: "W",
                                    summaryLabel: "1 week",
                                    percentText: Self.percentText(for: secondaryFraction),
                                    compactPercentText: Self.compactPercentText(for: secondaryFraction),
                                    fraction: secondaryFraction)
                                : nil,
                            quotaIsStale: isStale)

                        let rendered = MenuBarDisplayRenderer.render(
                            mode: .quotaDualCompact,
                            metrics: metrics,
                            quotaStyle: .capsule,
                            targetHeight: 19)

                        XCTAssertNotNil(rendered, "Expected dual compact renderer output")
                        XCTAssertGreaterThan(rendered?.image.size.width ?? 0, 0, "Image width should be positive")
                        XCTAssertGreaterThan(rendered?.displaySize.width ?? 0, 0, "Display width should be positive")
                        XCTAssertEqual(
                            Double(rendered?.displaySize.height ?? 0),
                            19,
                            accuracy: 0.001,
                            "Display height should match target")
                    }
                }
            }
        }
    }

    func test_dualKnockoutRendererSupportsPrimaryAndOptionalSecondaryStates() {
        let fractions: [Double?] = [nil, 0.21, 0.56, 1.0]
        let staleStates = [false, true]

        for primaryFraction in fractions {
            for secondaryFraction in fractions {
                for includesSecondary in [false, true] {
                    for isStale in staleStates {
                        let metrics = MenuBarDisplayMetrics(
                            inputText: "12.3k",
                            outputText: "987",
                            primaryQuota: MenuBarQuotaMetrics(
                                shortLabel: "H",
                                summaryLabel: "5 hours",
                                percentText: Self.percentText(for: primaryFraction),
                                compactPercentText: Self.compactPercentText(for: primaryFraction),
                                fraction: primaryFraction),
                            secondaryQuota: includesSecondary
                                ? MenuBarQuotaMetrics(
                                    shortLabel: "W",
                                    summaryLabel: "1 week",
                                    percentText: Self.percentText(for: secondaryFraction),
                                    compactPercentText: Self.compactPercentText(for: secondaryFraction),
                                    fraction: secondaryFraction)
                                : nil,
                            quotaIsStale: isStale)

                        let rendered = MenuBarDisplayRenderer.render(
                            mode: .quotaDualKnockout,
                            metrics: metrics,
                            quotaStyle: .capsule,
                            targetHeight: 19)

                        XCTAssertNotNil(rendered, "Expected dual knockout renderer output")
                        XCTAssertGreaterThan(rendered?.image.size.width ?? 0, 0, "Image width should be positive")
                        XCTAssertGreaterThan(rendered?.displaySize.width ?? 0, 0, "Display width should be positive")
                        XCTAssertEqual(
                            Double(rendered?.displaySize.height ?? 0),
                            19,
                            accuracy: 0.001,
                            "Display height should match target")
                    }
                }
            }
        }
    }

    func test_dualKnockoutRendererIncludesOpaqueShellAndTransparentCutouts() throws {
        let metrics = MenuBarDisplayMetrics(
            inputText: "12.3k",
            outputText: "987",
            primaryQuota: MenuBarQuotaMetrics(
                shortLabel: "H",
                summaryLabel: "5 hours",
                percentText: "56%",
                compactPercentText: "56",
                fraction: 0.56),
            secondaryQuota: MenuBarQuotaMetrics(
                shortLabel: "W",
                summaryLabel: "1 week",
                percentText: "88%",
                compactPercentText: "88",
                fraction: 0.88),
            quotaIsStale: false)

        let rendered = try XCTUnwrap(MenuBarDisplayRenderer.render(
            mode: .quotaDualKnockout,
            metrics: metrics,
            quotaStyle: .capsule,
            targetHeight: 19))
        let rep = try Self.bitmapRep(from: rendered.image)

        let xRange = (rep.pixelsWide / 4)..<(rep.pixelsWide * 3 / 4)
        let yRange = (rep.pixelsHigh / 4)..<(rep.pixelsHigh * 3 / 4)

        var foundOpaqueWhite = false
        var foundTransparentHole = false

        for x in xRange {
            for y in yRange {
                guard let color = (rep.colorAt(x: x, y: y) ?? .clear).usingColorSpace(.deviceRGB) else {
                    continue
                }

                if color.alphaComponent > 0.95,
                   color.redComponent > 0.95,
                   color.greenComponent > 0.95,
                   color.blueComponent > 0.95
                {
                    foundOpaqueWhite = true
                }

                if color.alphaComponent < 0.05 {
                    foundTransparentHole = true
                }
            }
        }

        XCTAssertTrue(foundOpaqueWhite, "Expected an opaque white shell pixel inside the rendered label")
        XCTAssertTrue(foundTransparentHole, "Expected a transparent knockout pixel inside the rendered label")
    }

    func test_dualKnockoutRendererBalancesHorizontalInsets() throws {
        let metrics = MenuBarDisplayMetrics(
            inputText: "12.3k",
            outputText: "987",
            primaryQuota: MenuBarQuotaMetrics(
                shortLabel: "H",
                summaryLabel: "5 hours",
                percentText: "56%",
                compactPercentText: "56",
                fraction: 0.56),
            secondaryQuota: MenuBarQuotaMetrics(
                shortLabel: "W",
                summaryLabel: "1 week",
                percentText: "88%",
                compactPercentText: "88",
                fraction: 0.88),
            quotaIsStale: false)

        let rendered = try XCTUnwrap(MenuBarDisplayRenderer.render(
            mode: .quotaDualKnockout,
            metrics: metrics,
            quotaStyle: .capsule,
            targetHeight: 19))
        let rep = try Self.bitmapRep(from: rendered.image)
        let margins = try XCTUnwrap(Self.knockoutHorizontalMargins(in: rep))

        XCTAssertLessThanOrEqual(
            abs(margins.left - margins.right),
            1,
            "Expected nearly symmetrical horizontal margins inside the white shell")
        XCTAssertGreaterThanOrEqual(
            margins.right,
            margins.left,
            "Expected the right margin to be at least as large as the left margin")
    }

    func test_settingsPreviewPlateKeepsDualKnockoutHolesNeutral() throws {
        let metrics = MenuBarDisplayMetrics(
            inputText: "12.3k",
            outputText: "987",
            primaryQuota: MenuBarQuotaMetrics(
                shortLabel: "H",
                summaryLabel: "5 hours",
                percentText: "56%",
                compactPercentText: "56",
                fraction: 0.56),
            secondaryQuota: MenuBarQuotaMetrics(
                shortLabel: "W",
                summaryLabel: "1 week",
                percentText: "88%",
                compactPercentText: "88",
                fraction: 0.88),
            quotaIsStale: false)

        let image = try XCTUnwrap(Self.image(
            from: MenuBarPreviewPlate {
                RenderedMenuBarPreview(
                    mode: .quotaDualKnockout,
                    metrics: metrics,
                    quotaStyle: .capsule,
                    fallbackText: "H 56%, W 88%",
                    targetHeight: 28)
            }))
        let rep = try Self.bitmapRep(from: image)
        let shellBounds = try XCTUnwrap(Self.opaqueWhiteBounds(in: rep))

        var foundDarkHole = false
        for x in shellBounds.minX...shellBounds.maxX {
            for y in shellBounds.minY...shellBounds.maxY {
                guard let color = (rep.colorAt(x: x, y: y) ?? .clear).usingColorSpace(.deviceRGB) else {
                    continue
                }

                if color.alphaComponent > 0.6,
                   color.redComponent < 0.15,
                   color.greenComponent < 0.15,
                   color.blueComponent < 0.15
                {
                    foundDarkHole = true
                    break
                }
            }

            if foundDarkHole {
                break
            }
        }

        XCTAssertTrue(foundDarkHole, "Expected neutral dark knockout holes inside the white shell")
    }

    private static func percentText(for fraction: Double?) -> String {
        guard let fraction else { return "--" }
        return "\(Int((fraction * 100).rounded()))%"
    }

    private static func compactPercentText(for fraction: Double?) -> String {
        guard let fraction else { return "--" }
        return "\(Int((fraction * 100).rounded()))"
    }

    private static func bitmapRep(from image: NSImage) throws -> NSBitmapImageRep {
        if let rep = image.representations.compactMap({ $0 as? NSBitmapImageRep }).first(where: {
            $0.pixelsWide > 0 && $0.pixelsHigh > 0
        }) {
            return rep
        }

        let data = try XCTUnwrap(image.tiffRepresentation)
        return try XCTUnwrap(NSBitmapImageRep(data: data))
    }

    private static func image(from view: some View) -> NSImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2
        return renderer.nsImage
    }

    private static func knockoutHorizontalMargins(in rep: NSBitmapImageRep) -> (left: Int, right: Int)? {
        var shellMinX: Int?
        var shellMaxX: Int?
        var holeMinX: Int?
        var holeMaxX: Int?

        for y in 0..<rep.pixelsHigh {
            var rowShellMin: Int?
            var rowShellMax: Int?

            for x in 0..<rep.pixelsWide {
                guard let color = (rep.colorAt(x: x, y: y) ?? .clear).usingColorSpace(.deviceRGB) else {
                    continue
                }

                let isShellPixel = color.alphaComponent > 0.95 &&
                    color.redComponent > 0.95 &&
                    color.greenComponent > 0.95 &&
                    color.blueComponent > 0.95
                guard isShellPixel else { continue }

                rowShellMin = min(rowShellMin ?? x, x)
                rowShellMax = max(rowShellMax ?? x, x)
            }

            guard let rowShellMin, let rowShellMax else { continue }

            var rowHoleMin: Int?
            var rowHoleMax: Int?
            for x in rowShellMin...rowShellMax {
                let alpha = (rep.colorAt(x: x, y: y) ?? .clear).alphaComponent
                guard alpha < 0.05 else { continue }

                rowHoleMin = min(rowHoleMin ?? x, x)
                rowHoleMax = max(rowHoleMax ?? x, x)
            }

            guard let rowHoleMin, let rowHoleMax else { continue }
            shellMinX = min(shellMinX ?? rowShellMin, rowShellMin)
            shellMaxX = max(shellMaxX ?? rowShellMax, rowShellMax)
            holeMinX = min(holeMinX ?? rowHoleMin, rowHoleMin)
            holeMaxX = max(holeMaxX ?? rowHoleMax, rowHoleMax)
        }

        guard let shellMinX, let shellMaxX, let holeMinX, let holeMaxX else { return nil }
        return (left: holeMinX - shellMinX, right: shellMaxX - holeMaxX)
    }

    private static func opaqueWhiteBounds(in rep: NSBitmapImageRep) -> (minX: Int, maxX: Int, minY: Int, maxY: Int)? {
        var minX: Int?
        var maxX: Int?
        var minY: Int?
        var maxY: Int?

        for x in 0..<rep.pixelsWide {
            for y in 0..<rep.pixelsHigh {
                guard let color = (rep.colorAt(x: x, y: y) ?? .clear).usingColorSpace(.deviceRGB) else {
                    continue
                }

                let isOpaqueWhite = color.alphaComponent > 0.95 &&
                    color.redComponent > 0.95 &&
                    color.greenComponent > 0.95 &&
                    color.blueComponent > 0.95
                guard isOpaqueWhite else { continue }

                minX = min(minX ?? x, x)
                maxX = max(maxX ?? x, x)
                minY = min(minY ?? y, y)
                maxY = max(maxY ?? y, y)
            }
        }

        guard let minX, let maxX, let minY, let maxY else { return nil }
        return (minX: minX, maxX: maxX, minY: minY, maxY: maxY)
    }

    private static func failureMessage(style: MenuBarQuotaStyle, fraction: Double?, isStale: Bool) -> String {
        let fractionDescription = String(describing: fraction)
        return "Expected renderer output for style \(style.rawValue), fraction \(fractionDescription), stale \(isStale)"
    }
}
