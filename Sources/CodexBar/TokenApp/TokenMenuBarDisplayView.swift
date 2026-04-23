import AppKit
import SwiftUI

struct MenuBarQuotaMetrics: Equatable, Hashable {
    let shortLabel: String
    let summaryLabel: String
    let percentText: String
    let compactPercentText: String
    let fraction: Double?
}

struct MenuBarDisplayMetrics: Equatable, Hashable {
    let inputText: String
    let outputText: String
    let primaryQuota: MenuBarQuotaMetrics
    let secondaryQuota: MenuBarQuotaMetrics?
    let quotaIsStale: Bool

    init(
        inputText: String,
        outputText: String,
        quotaPercentText: String,
        quotaFraction: Double?,
        quotaIsStale: Bool,
        primaryQuotaShortLabel: String = "H",
        primaryQuotaSummaryLabel: String = "5h",
        secondaryQuota: MenuBarQuotaMetrics? = nil)
    {
        self.inputText = inputText
        self.outputText = outputText
        self.primaryQuota = MenuBarQuotaMetrics(
            shortLabel: primaryQuotaShortLabel,
            summaryLabel: primaryQuotaSummaryLabel,
            percentText: quotaPercentText,
            compactPercentText: Self.compactPercentText(from: quotaPercentText),
            fraction: quotaFraction)
        self.secondaryQuota = secondaryQuota
        self.quotaIsStale = quotaIsStale
    }

    init(
        inputText: String,
        outputText: String,
        primaryQuota: MenuBarQuotaMetrics,
        secondaryQuota: MenuBarQuotaMetrics?,
        quotaIsStale: Bool)
    {
        self.inputText = inputText
        self.outputText = outputText
        self.primaryQuota = primaryQuota
        self.secondaryQuota = secondaryQuota
        self.quotaIsStale = quotaIsStale
    }

    var quotaPercentText: String {
        self.primaryQuota.percentText
    }

    var quotaFraction: Double? {
        self.primaryQuota.fraction
    }

    private static func compactPercentText(from value: String) -> String {
        value.replacingOccurrences(of: "%", with: "")
    }
}

struct RenderedTokenSpeedPreview: View {
    let metrics: MenuBarTokenSpeedMetrics
    let targetHeight: CGFloat

    var body: some View {
        Text(self.metrics.displayText)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.96))
            .monospacedDigit()
            .lineLimit(1)
            .frame(height: self.targetHeight, alignment: .center)
            .fixedSize(horizontal: true, vertical: true)
    }
}

private enum MenuBarQuotaPalette {
    static let surface = Color.white.opacity(0.10)
    static let surfaceStrong = Color.white.opacity(0.16)
    static let surfaceEmphasis = Color.white.opacity(0.22)
    static let stroke = Color.white.opacity(0.58)
    static let strokeSoft = Color.white.opacity(0.34)
    static let progressShadow = Color.white.opacity(0.14)
    static let text = Color.white.opacity(0.96)
    static let textMuted = Color.white.opacity(0.86)
    static let symbol = Color.white.opacity(0.92)

    static let progressGradient = LinearGradient(
        colors: [Color.white.opacity(0.56), Color.white.opacity(0.28)],
        startPoint: .leading,
        endPoint: .trailing)
}

private enum MenuBarCodexIconLoader {
    private static let resourceBundle: Bundle? = {
        if let bundleURL = Bundle.main.url(forResource: "CodexBar_CodexBar", withExtension: "bundle"),
           let bundle = Bundle(url: bundleURL)
        {
            return bundle
        }
        return Bundle.main
    }()

    static func image() -> NSImage? {
        guard let bundle = self.resourceBundle,
              let url = bundle.url(forResource: "ProviderIcon-codex", withExtension: "svg"),
              let image = NSImage(contentsOf: url)
        else {
            return nil
        }

        image.isTemplate = true
        return image
    }
}

private struct MenuBarQuotaSizing {
    let shellHeight: CGFloat
    let verticalPadding: CGFloat
    let horizontalPadding: CGFloat
    let labelSpacing: CGFloat
    let badgeFontSize: CGFloat
    let percentFontSize: CGFloat
    let badgeHorizontalPadding: CGFloat
    let badgeVerticalPadding: CGFloat
    let cornerRadius: CGFloat
    let meterGap: CGFloat
    let meterHeight: CGFloat
    let percentMinWidth: CGFloat
    let iconSize: CGFloat
    let iconStrokeWidth: CGFloat

    static func make() -> MenuBarQuotaSizing {
        MenuBarQuotaSizing(
            shellHeight: 13,
            verticalPadding: 1.4,
            horizontalPadding: 5,
            labelSpacing: 3.5,
            badgeFontSize: 6.6,
            percentFontSize: 10.9,
            badgeHorizontalPadding: 3.2,
            badgeVerticalPadding: 1.0,
            cornerRadius: 6.5,
            meterGap: 2,
            meterHeight: 1.8,
            percentMinWidth: 28,
            iconSize: 10.5,
            iconStrokeWidth: 1.15)
    }
}

@MainActor
struct MenuBarDisplayView: View {
    static let baseTargetHeight: CGFloat = 19

    let mode: MenuBarDisplayMode
    let metrics: MenuBarDisplayMetrics
    let quotaStyle: MenuBarQuotaStyle

    private let inputColor = Color(red: 0.23, green: 0.78, blue: 0.45)
    private let outputColor = Color(red: 0.24, green: 0.55, blue: 0.98)

    private var contentHeight: CGFloat {
        Self.baseTargetHeight
    }

    var body: some View {
        Group {
            switch self.mode {
            case .todayIO:
                VStack(alignment: .leading, spacing: 0) {
                    MenuBarDotStatRow(
                        color: self.inputColor,
                        value: self.metrics.inputText)
                    MenuBarDotStatRow(
                        color: self.outputColor,
                        value: self.metrics.outputText)
                }
            case .quota5h:
                MenuBarQuotaStyleView(
                    style: self.quotaStyle,
                    percentText: self.metrics.primaryQuota.percentText,
                    fraction: self.metrics.primaryQuota.fraction,
                    isStale: self.metrics.quotaIsStale)
            case .quotaDualCompact:
                MenuBarDualQuotaCompactView(
                    primaryQuota: self.metrics.primaryQuota,
                    secondaryQuota: self.metrics.secondaryQuota,
                    isStale: self.metrics.quotaIsStale)
            case .quotaDualKnockout:
                MenuBarDualQuotaKnockoutView(
                    primaryQuota: self.metrics.primaryQuota,
                    secondaryQuota: self.metrics.secondaryQuota,
                    isStale: self.metrics.quotaIsStale)
            }
        }
        .frame(height: self.contentHeight, alignment: .center)
        .fixedSize(horizontal: true, vertical: true)
    }
}

private struct MenuBarDotStatRow: View {
    let color: Color
    let value: String

    var body: some View {
        HStack(spacing: 3.5) {
            Circle()
                .fill(self.color)
                .frame(width: 4, height: 4)

            Text(self.value)
                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.96))
                .monospacedDigit()
                .lineLimit(1)
        }
        .frame(height: 8, alignment: .center)
    }
}

private struct MenuBarDualQuotaCompactView: View {
    let primaryQuota: MenuBarQuotaMetrics
    let secondaryQuota: MenuBarQuotaMetrics?
    let isStale: Bool

    private var labelFont: Font {
        .system(size: 7.7, weight: .semibold, design: .rounded)
    }

    private var valueFont: Font {
        .system(size: 10.5, weight: .bold, design: .rounded)
    }

    private var shellOpacity: Double {
        self.isStale ? 0.76 : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            self.row(
                quota: self.primaryQuota,
                labelColor: MenuBarQuotaPalette.textMuted,
                valueColor: MenuBarQuotaPalette.text)

            if let secondaryQuota {
                self.row(
                    quota: secondaryQuota,
                    labelColor: MenuBarQuotaPalette.textMuted.opacity(0.82),
                    valueColor: MenuBarQuotaPalette.text.opacity(0.84))
            }
        }
        .padding(.vertical, 0.2)
        .opacity(self.shellOpacity)
        .fixedSize(horizontal: true, vertical: true)
    }

    private func row(quota: MenuBarQuotaMetrics, labelColor: Color, valueColor: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 1.4) {
            Text(quota.shortLabel)
                .font(self.labelFont)
                .foregroundStyle(labelColor)
                .kerning(0.05)
                .frame(width: 8, alignment: .leading)

            Text(quota.compactPercentText)
                .font(self.valueFont)
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(minWidth: 18, alignment: .leading)
        }
        .frame(height: 8.2, alignment: .center)
    }
}

private struct MenuBarDualQuotaKnockoutView: View {
    let primaryQuota: MenuBarQuotaMetrics
    let secondaryQuota: MenuBarQuotaMetrics?
    let isStale: Bool

    private struct Sizing {
        let rowSpacing: CGFloat
        let labelWidth: CGFloat
        let valueWidth: CGFloat
        let columnGap: CGFloat
        let leadingInset: CGFloat
        let trailingInset: CGFloat
        let verticalPadding: CGFloat
        let labelFontSize: CGFloat
        let valueFontSize: CGFloat
        let rowHeight: CGFloat

        var contentWidth: CGFloat {
            self.labelWidth + self.columnGap + self.valueWidth
        }

        static func make() -> Sizing {
            Sizing(
                rowSpacing: 0,
                labelWidth: 8,
                valueWidth: 19,
                columnGap: 1.4,
                leadingInset: 5.6,
                trailingInset: 4.8,
                verticalPadding: 0.9,
                labelFontSize: 7.7,
                valueFontSize: 10.5,
                rowHeight: 8.2)
        }
    }

    private var sizing: Sizing {
        .make()
    }

    private var labelFont: Font {
        .system(size: self.sizing.labelFontSize, weight: .semibold, design: .rounded)
    }

    private var valueFont: Font {
        .system(size: self.sizing.valueFontSize, weight: .bold, design: .rounded)
    }

    private var shellOpacity: Double {
        self.isStale ? 0.76 : 1
    }

    var body: some View {
        self.knockoutRows
            .padding(.leading, self.sizing.leadingInset)
            .padding(.trailing, self.sizing.trailingInset)
            .padding(.vertical, self.sizing.verticalPadding)
            .hidden()
            .background {
                Capsule()
                    .fill(Color.white)
            }
            .overlay {
                self.knockoutRows
                    .padding(.leading, self.sizing.leadingInset)
                    .padding(.trailing, self.sizing.trailingInset)
                    .padding(.vertical, self.sizing.verticalPadding)
                    .foregroundStyle(Color.black)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .drawingGroup(opaque: false, colorMode: .linear)
            .opacity(self.shellOpacity)
            .fixedSize(horizontal: true, vertical: true)
    }

    private var knockoutRows: some View {
        VStack(alignment: .leading, spacing: self.sizing.rowSpacing) {
            self.row(quota: self.primaryQuota)

            if let secondaryQuota {
                self.row(quota: secondaryQuota)
            }
        }
        .frame(width: self.sizing.contentWidth, alignment: .leading)
    }

    private func row(quota: MenuBarQuotaMetrics) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: self.sizing.columnGap) {
            Text(quota.shortLabel)
                .font(self.labelFont)
                .kerning(0.05)
                .frame(width: self.sizing.labelWidth, alignment: .leading)

            Text(quota.compactPercentText)
                .font(self.valueFont)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(width: self.sizing.valueWidth, alignment: .trailing)
        }
        .frame(width: self.sizing.contentWidth, height: self.sizing.rowHeight, alignment: .leading)
    }
}

private struct MenuBarQuotaStyleView: View {
    let style: MenuBarQuotaStyle
    let percentText: String
    let fraction: Double?
    let isStale: Bool

    private var sizing: MenuBarQuotaSizing {
        .make()
    }

    private var clampedFraction: CGFloat {
        CGFloat(min(max(self.fraction ?? 0, 0), 1))
    }

    private var shellOpacity: Double {
        self.isStale ? 0.76 : 1
    }

    private var shadowRadius: CGFloat {
        3
    }

    private var symbolScale: Image.Scale {
        .small
    }

    var body: some View {
        Group {
            switch self.style {
            case .capsule:
                self.capsuleBody
            case .split:
                self.splitBody
            case .meter:
                self.meterBody
            case .outline:
                self.outlineBody
            case .codexMinimal:
                self.codexMinimalBody
            }
        }
        .opacity(self.shellOpacity)
        .fixedSize(horizontal: true, vertical: true)
    }

    private var capsuleBody: some View {
        ZStack {
            self.capsuleTrack(strokeOpacity: 0.54, fillOpacity: 0.12)
            self.capsuleProgress(fillOpacity: 1, strokeOpacity: 0.0)

            HStack(alignment: .firstTextBaseline, spacing: self.sizing.labelSpacing) {
                self.leadingLabel

                Text(self.percentText)
                    .font(.system(size: self.sizing.percentFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(MenuBarQuotaPalette.text)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .padding(.horizontal, self.sizing.horizontalPadding)
            .padding(.vertical, self.sizing.verticalPadding)
        }
        .frame(height: self.sizing.shellHeight)
        .compositingGroup()
        .drawingGroup(opaque: false, colorMode: .linear)
    }

    private var splitBody: some View {
        HStack(spacing: self.sizing.labelSpacing) {
            self.leadingLabel
                .padding(.horizontal, self.sizing.badgeHorizontalPadding)
                .padding(.vertical, self.sizing.badgeVerticalPadding)
                .background(Capsule().fill(MenuBarQuotaPalette.surfaceEmphasis))

            Text(self.percentText)
                .font(.system(size: self.sizing.percentFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(MenuBarQuotaPalette.text)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(minWidth: self.sizing.percentMinWidth, alignment: .leading)
        }
        .padding(.leading, self.sizing.badgeVerticalPadding)
        .padding(.trailing, self.sizing.horizontalPadding)
        .padding(.vertical, self.sizing.verticalPadding)
        .background(
            Capsule()
                .fill(MenuBarQuotaPalette.surface)
                .overlay(
                    Capsule()
                        .stroke(MenuBarQuotaPalette.strokeSoft, lineWidth: 0.75)))
        .frame(height: self.sizing.shellHeight)
    }

    private var meterBody: some View {
        VStack(alignment: .leading, spacing: self.sizing.meterGap) {
            Text(self.percentText)
                .font(.system(size: self.sizing.percentFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(MenuBarQuotaPalette.text)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            GeometryReader { proxy in
                let width = proxy.size.width * self.clampedFraction

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MenuBarQuotaPalette.surfaceStrong)

                    if width > 0 {
                        Capsule()
                            .fill(MenuBarQuotaPalette.progressGradient)
                            .frame(width: max(width, self.sizing.meterHeight * 2), alignment: .leading)
                    }
                }
                .overlay(
                    Capsule()
                        .stroke(MenuBarQuotaPalette.strokeSoft, lineWidth: 0.65))
            }
            .frame(height: self.sizing.meterHeight)
        }
        .padding(.horizontal, 3)
        .padding(.vertical, self.sizing.verticalPadding)
        .background(
            RoundedRectangle(cornerRadius: self.sizing.cornerRadius, style: .continuous)
                .fill(MenuBarQuotaPalette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: self.sizing.cornerRadius, style: .continuous)
                        .stroke(MenuBarQuotaPalette.strokeSoft, lineWidth: 0.72)))
        .frame(height: self.sizing.shellHeight)
    }

    private var outlineBody: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.clear)

            GeometryReader { proxy in
                let minimum = self.sizing.shellHeight * 0.82
                let width = max(proxy.size.width * self.clampedFraction, minimum)

                if self.clampedFraction > 0 {
                    Capsule()
                        .fill(MenuBarQuotaPalette.progressGradient.opacity(0.9))
                        .frame(width: width, alignment: .leading)
                        .padding(1.2)
                }
            }
            .clipShape(Capsule())

            HStack(alignment: .firstTextBaseline, spacing: self.sizing.labelSpacing) {
                self.leadingLabel

                Text(self.percentText)
                    .font(.system(size: self.sizing.percentFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(MenuBarQuotaPalette.text)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .padding(.horizontal, self.sizing.horizontalPadding)
            .padding(.vertical, self.sizing.verticalPadding)
        }
        .overlay(
            Capsule()
                .stroke(MenuBarQuotaPalette.stroke, lineWidth: 0.78))
        .frame(height: self.sizing.shellHeight)
    }

    private var codexMinimalBody: some View {
        HStack(alignment: .center, spacing: 4.5) {
            if let codexIcon = MenuBarCodexIconLoader.image() {
                Image(nsImage: codexIcon)
                    .renderingMode(.template)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: self.sizing.iconSize, height: self.sizing.iconSize)
                    .foregroundStyle(MenuBarQuotaPalette.symbol)
            }

            Text(self.percentText)
                .font(.system(size: self.sizing.percentFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(MenuBarQuotaPalette.text)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 0.5)
        .frame(height: self.sizing.shellHeight)
    }

    private var leadingLabel: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2.5) {
            Image(systemName: "timer")
                .symbolRenderingMode(.monochrome)
                .imageScale(self.symbolScale)
                .font(.system(size: self.sizing.badgeFontSize + 0.6, weight: .semibold))
                .foregroundStyle(MenuBarQuotaPalette.symbol)

            Text("H")
                .font(.system(size: self.sizing.badgeFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(MenuBarQuotaPalette.textMuted)
                .kerning(0.1)
        }
    }

    private func capsuleTrack(strokeOpacity: Double, fillOpacity: Double) -> some View {
        Capsule()
            .fill(MenuBarQuotaPalette.surface.opacity(fillOpacity))
            .overlay(
                Capsule()
                    .stroke(MenuBarQuotaPalette.stroke.opacity(strokeOpacity), lineWidth: 0.78))
    }

    private func capsuleProgress(fillOpacity: Double, strokeOpacity: Double) -> some View {
        GeometryReader { proxy in
            let progressWidth = proxy.size.width * self.clampedFraction

            if progressWidth > 0 {
                Capsule()
                    .fill(MenuBarQuotaPalette.progressGradient.opacity(fillOpacity))
                    .frame(width: progressWidth, alignment: .leading)
                    .shadow(
                        color: MenuBarQuotaPalette.progressShadow,
                        radius: self.shadowRadius,
                        x: 0,
                        y: 0)
                    .overlay(alignment: .leading) {
                        if strokeOpacity > 0 {
                            Capsule()
                                .stroke(MenuBarQuotaPalette.stroke.opacity(strokeOpacity), lineWidth: 0.5)
                        }
                    }
            }
        }
        .clipShape(Capsule())
    }
}

@MainActor
struct RenderedMenuBarPreview: View {
    let mode: MenuBarDisplayMode
    let metrics: MenuBarDisplayMetrics
    let quotaStyle: MenuBarQuotaStyle
    let fallbackText: String
    var targetHeight: CGFloat = MenuBarDisplayRenderer.menuBarTargetHeight

    private var fallbackFontSize: CGFloat {
        let scale = self.targetHeight / MenuBarDisplayRenderer.menuBarTargetHeight
        return max(12, 12 * scale)
    }

    var body: some View {
        Group {
            if let rendered = MenuBarDisplayRenderer.render(
                mode: self.mode,
                metrics: self.metrics,
                quotaStyle: self.quotaStyle,
                targetHeight: self.targetHeight)
            {
                Image(nsImage: rendered.image)
                    .renderingMode(.original)
                    .interpolation(.high)
                    .resizable()
                    .frame(width: rendered.displaySize.width, height: rendered.displaySize.height)
            } else {
                Text(self.fallbackText)
                    .font(.system(size: self.fallbackFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(MenuBarQuotaPalette.text)
                    .monospacedDigit()
            }
        }
        .fixedSize(horizontal: true, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.fallbackText)
    }
}

@MainActor
struct MenuBarPreviewPlate<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        self.content()
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.76))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 0.8)))
    }
}

@MainActor
enum MenuBarDisplayRenderer {
    static let menuBarTargetHeight: CGFloat = MenuBarDisplayView.baseTargetHeight
    static let cacheLimit = 64

    struct RenderedLabel {
        let image: NSImage
        let displaySize: CGSize
    }

    private struct RenderCacheKey: Hashable {
        let mode: MenuBarDisplayMode
        let metrics: MenuBarDisplayMetrics
        let quotaStyle: MenuBarQuotaStyle
        let targetHeightKey: Int
        let rendererScaleKey: Int
    }

    private final class RenderCacheStore {
        private let limit: Int
        private var orderedKeys: [RenderCacheKey] = []
        private var labelsByKey: [RenderCacheKey: RenderedLabel] = [:]

        init(limit: Int) {
            self.limit = limit
        }

        func label(for key: RenderCacheKey) -> RenderedLabel? {
            self.labelsByKey[key]
        }

        func store(_ label: RenderedLabel, for key: RenderCacheKey) {
            if self.labelsByKey[key] == nil {
                self.orderedKeys.append(key)
            }
            self.labelsByKey[key] = label

            while self.orderedKeys.count > self.limit {
                let removedKey = self.orderedKeys.removeFirst()
                self.labelsByKey.removeValue(forKey: removedKey)
            }
        }

        func clear() {
            self.orderedKeys.removeAll(keepingCapacity: false)
            self.labelsByKey.removeAll(keepingCapacity: false)
        }

        var count: Int {
            self.labelsByKey.count
        }
    }

    private static let renderCacheStore = RenderCacheStore(limit: Self.cacheLimit)

    static func render(
        mode: MenuBarDisplayMode,
        metrics: MenuBarDisplayMetrics,
        quotaStyle: MenuBarQuotaStyle,
        targetHeight: CGFloat = Self.menuBarTargetHeight)
        -> RenderedLabel?
    {
        let displayScale = max(targetHeight / Self.menuBarTargetHeight, 1)
        let backingScaleFactor = NSScreen.main?.backingScaleFactor ?? 2
        let rendererScale = backingScaleFactor * displayScale
        let cacheKey = RenderCacheKey(
            mode: mode,
            metrics: metrics,
            quotaStyle: quotaStyle,
            targetHeightKey: Self.dimensionKey(for: targetHeight),
            rendererScaleKey: Self.dimensionKey(for: rendererScale))

        if let cached = self.renderCacheStore.label(for: cacheKey) {
            return cached
        }

        let renderedLabel = autoreleasepool { () -> RenderedLabel? in
            let content = MenuBarDisplayView(
                mode: mode,
                metrics: metrics,
                quotaStyle: quotaStyle)
                .compositingGroup()

            let renderer = ImageRenderer(content: content)
            renderer.scale = rendererScale
            guard let image = renderer.nsImage else { return nil }
            image.isTemplate = false

            let naturalHeight = max(image.size.height, 1)
            let scale = targetHeight / naturalHeight
            return RenderedLabel(
                image: image,
                displaySize: CGSize(width: image.size.width * scale, height: targetHeight))
        }

        guard let renderedLabel else { return nil }
        self.renderCacheStore.store(renderedLabel, for: cacheKey)
        return renderedLabel
    }

    static func clearCacheForTesting() {
        self.renderCacheStore.clear()
    }

    static func cacheCountForTesting() -> Int {
        self.renderCacheStore.count
    }

    private static func dimensionKey(for value: CGFloat) -> Int {
        Int((value * 100).rounded())
    }
}
