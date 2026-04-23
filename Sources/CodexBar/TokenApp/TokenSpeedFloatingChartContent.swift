import AppKit
import SwiftUI

struct TokenSpeedFloatingWidgetPalette {
    let textColor: NSColor
    let mutedTextColor: NSColor
    let guideLineColor: NSColor
    let baselineColor: NSColor
    let spikeColor: NSColor

    var text: Color {
        Color(nsColor: self.textColor)
    }

    var mutedText: Color {
        Color(nsColor: self.mutedTextColor)
    }

    var guideLine: Color {
        Color(nsColor: self.guideLineColor)
    }

    var baseline: Color {
        Color(nsColor: self.baselineColor)
    }

    var spike: Color {
        Color(nsColor: self.spikeColor)
    }
}

enum TokenSpeedFloatingWidgetTheme {
    private static var theme: MenuVisualThemeTokens {
        MenuVisualThemeProvider.tokens
    }

    static var usesPixelChrome: Bool {
        self.theme.chromeStyle == .pixel
    }

    static var surfaceTint: Color {
        if self.usesPixelChrome {
            return Color(nsColor: self.theme.analyticsTint).opacity(0.10)
        }
        return Color(nsColor: NSColor(
            srgbRed: 12 / 255,
            green: 14 / 255,
            blue: 18 / 255,
            alpha: 0.06))
    }

    static var stroke: Color {
        if self.usesPixelChrome {
            return Color(nsColor: self.theme.glassStroke)
        }
        return Color.white.opacity(0.12)
    }

    static var shadow: Color {
        if self.usesPixelChrome {
            return Color(nsColor: self.theme.panelShadow).opacity(0.78)
        }
        return Color.black.opacity(0.04)
    }

    static func palette(for colorScheme: ColorScheme) -> TokenSpeedFloatingWidgetPalette {
        if self.usesPixelChrome {
            return TokenSpeedFloatingWidgetPalette(
                textColor: self.theme.primaryText,
                mutedTextColor: self.theme.secondaryText,
                guideLineColor: self.theme.chartGrid,
                baselineColor: self.theme.chartAxis,
                spikeColor: self.theme.analyticsTint)
        }

        switch colorScheme {
        case .light:
            return TokenSpeedFloatingWidgetPalette(
                textColor: NSColor(srgbRed: 31 / 255, green: 35 / 255, blue: 42 / 255, alpha: 0.96),
                mutedTextColor: NSColor(srgbRed: 52 / 255, green: 57 / 255, blue: 66 / 255, alpha: 0.76),
                guideLineColor: NSColor(srgbRed: 31 / 255, green: 35 / 255, blue: 42 / 255, alpha: 0.14),
                baselineColor: NSColor(srgbRed: 31 / 255, green: 35 / 255, blue: 42 / 255, alpha: 0.78),
                spikeColor: NSColor(srgbRed: 31 / 255, green: 35 / 255, blue: 42 / 255, alpha: 0.78))
        case .dark:
            return TokenSpeedFloatingWidgetPalette(
                textColor: NSColor.white.withAlphaComponent(0.98),
                mutedTextColor: NSColor.white.withAlphaComponent(0.74),
                guideLineColor: NSColor.white.withAlphaComponent(0.11),
                baselineColor: NSColor.white.withAlphaComponent(0.96),
                spikeColor: NSColor.white.withAlphaComponent(0.96))
        @unknown default:
            return TokenSpeedFloatingWidgetPalette(
                textColor: NSColor.white.withAlphaComponent(0.98),
                mutedTextColor: NSColor.white.withAlphaComponent(0.74),
                guideLineColor: NSColor.white.withAlphaComponent(0.11),
                baselineColor: NSColor.white.withAlphaComponent(0.96),
                spikeColor: NSColor.white.withAlphaComponent(0.96))
        }
    }
}

private struct TokenSpeedFloatingWidgetBackground: View {
    let cornerRadius: CGFloat

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
    }

    var body: some View {
        Group {
            if TokenSpeedFloatingWidgetTheme.usesPixelChrome {
                TokenPixelSurfaceBackground(
                    cornerRadius: TokenMenuTheme.chromeCornerRadius(default: self.cornerRadius, pixel: min(self.cornerRadius, 12)),
                    tint: Color(nsColor: MenuVisualThemeProvider.tokens.analyticsTint),
                    style: .card)
            } else {
                self.shape
                    .fill(.clear)
                    .modifier(TokenSpeedFloatingWidgetGlassModifier(shape: self.shape))
                    .overlay {
                        self.shape.fill(TokenSpeedFloatingWidgetTheme.surfaceTint)
                    }
                    .overlay {
                        self.shape
                            .stroke(TokenSpeedFloatingWidgetTheme.stroke, lineWidth: 0.8)
                    }
                    .shadow(color: TokenSpeedFloatingWidgetTheme.shadow, radius: 2.4, x: 0, y: 1)
            }
        }
    }
}

private struct TokenSpeedFloatingWidgetGlassModifier<ShapeType: InsettableShape>: ViewModifier {
    let shape: ShapeType

    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.glassEffect(.regular, in: self.shape)
        } else {
            content.background(.ultraThinMaterial, in: self.shape)
        }
    }
}

enum TokenSpeedFloatingChartLayout {
    static let size = CGSize(width: 192, height: 192)
    static let cornerRadius: CGFloat = 42
    static let contentPadding: CGFloat = 16
    static let chartHeight: CGFloat = 110
    static let chartBottomSpacing: CGFloat = 8
    static let metricTopSpacing: CGFloat = 0
}

enum TokenSpeedFloatingChartPlacement {
    static let screenInset: CGFloat = 8
    static let horizontalGap: CGFloat = 12

    static func defaultFrame(
        anchorFrame: CGRect,
        panelSize: CGSize,
        visibleFrame: CGRect)
        -> CGRect
    {
        let proposedOrigin = CGPoint(
            x: anchorFrame.maxX + self.horizontalGap,
            y: anchorFrame.maxY - panelSize.height)
        return self.clampedFrame(
            origin: proposedOrigin,
            panelSize: panelSize,
            visibleFrame: visibleFrame)
    }

    static func clampedFrame(
        origin: CGPoint,
        panelSize: CGSize,
        visibleFrame: CGRect)
        -> CGRect
    {
        let minX = visibleFrame.minX + self.screenInset
        let maxX = visibleFrame.maxX - panelSize.width - self.screenInset
        let minY = visibleFrame.minY + self.screenInset
        let maxY = visibleFrame.maxY - panelSize.height - self.screenInset

        let x = min(max(origin.x, minX), maxX)
        let y = min(max(origin.y, minY), maxY)

        return CGRect(
            x: x.rounded(.toNearestOrAwayFromZero),
            y: y.rounded(.toNearestOrAwayFromZero),
            width: panelSize.width.rounded(.up),
            height: panelSize.height.rounded(.up))
    }
}

@MainActor
final class TokenSpeedFloatingChartStateStore {
    private enum Keys {
        static let originX = "tokenSpeedFloatingChartOriginX"
        static let originY = "tokenSpeedFloatingChartOriginY"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadOrigin() -> CGPoint? {
        guard self.defaults.object(forKey: Keys.originX) != nil,
              self.defaults.object(forKey: Keys.originY) != nil
        else {
            return nil
        }

        return CGPoint(
            x: self.defaults.double(forKey: Keys.originX),
            y: self.defaults.double(forKey: Keys.originY))
    }

    func saveOrigin(_ origin: CGPoint) {
        self.defaults.set(origin.x, forKey: Keys.originX)
        self.defaults.set(origin.y, forKey: Keys.originY)
    }
}

struct TokenSpeedFloatingValueParts: Equatable {
    let magnitude: String
    let suffix: String?
}

enum TokenSpeedFloatingValueFormatter {
    static func tokenParts(for value: Int, strings: AppStrings) -> TokenSpeedFloatingValueParts {
        switch strings.language {
        case .zhHans:
            if value >= 10_000_000 {
                return self.yiParts(value: value, unit: "亿", locale: strings.locale)
            }
        case .ja:
            if value >= 10_000_000 {
                return self.yiParts(value: value, unit: "億", locale: strings.locale)
            }
        case .en, .system:
            break
        }

        return self.parts(from: strings.compactTokenText(value))
    }

    static func instructionParts(for value: Int, strings: AppStrings) -> TokenSpeedFloatingValueParts {
        let formatter = NumberFormatter()
        formatter.locale = strings.locale
        formatter.numberStyle = .decimal
        let text = formatter.string(from: NSNumber(value: value)) ?? String(value)
        let suffix: String? = switch strings.language {
        case .zhHans: "次"
        case .ja: "回"
        case .en, .system: nil
        }
        return TokenSpeedFloatingValueParts(magnitude: text, suffix: suffix)
    }

    static func parts(from text: String) -> TokenSpeedFloatingValueParts {
        let characters = Array(text)
        let allowedCharacters = CharacterSet(charactersIn: "0123456789.,")
        var magnitudeCharacters: [Character] = []
        var suffixCharacters: [Character] = []
        var isReadingMagnitude = true

        for character in characters {
            let scalar = String(character).unicodeScalars.first
            let isMagnitudeCharacter = scalar.map { allowedCharacters.contains($0) } ?? false

            if isReadingMagnitude, isMagnitudeCharacter {
                magnitudeCharacters.append(character)
            } else {
                isReadingMagnitude = false
                suffixCharacters.append(character)
            }
        }

        let magnitude = String(magnitudeCharacters).trimmingCharacters(in: .whitespacesAndNewlines)
        let suffix = String(suffixCharacters).trimmingCharacters(in: .whitespacesAndNewlines)

        if magnitude.isEmpty {
            return TokenSpeedFloatingValueParts(magnitude: text, suffix: nil)
        }

        return TokenSpeedFloatingValueParts(
            magnitude: magnitude,
            suffix: suffix.isEmpty ? nil : suffix)
    }

    private static func yiParts(value: Int, unit: String, locale: Locale) -> TokenSpeedFloatingValueParts {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1

        let scaledValue = Double(value) / 100_000_000
        let magnitude = formatter.string(from: NSNumber(value: scaledValue)) ?? String(format: "%.1f", scaledValue)
        return TokenSpeedFloatingValueParts(magnitude: magnitude, suffix: unit)
    }
}

enum TokenSpeedFloatingRocketPlacement {
    static let baseAngle = -45.0

    static func xPosition(
        for indexedPoints: [(offset: Int, point: TokenSpeedDisplayPoint)],
        horizontalInset: CGFloat,
        usableWidth: CGFloat,
        fallbackX: CGFloat)
        -> CGFloat
    {
        guard let lastBurstPoint = indexedPoints.last(where: { $0.point.rawTokens > 0 }) else {
            return fallbackX
        }

        let denominator = max(indexedPoints.count - 1, 1)
        let progress = CGFloat(lastBurstPoint.offset) / CGFloat(denominator)
        return horizontalInset + (usableWidth * progress)
    }
}

private struct TokenSpeedFloatingSpikeChart: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var rocketMotion = TokenSpeedRocketBurstMotion.zero

    let model: TokenSpeedPanelModel

    private var indexedPoints: [(offset: Int, point: TokenSpeedDisplayPoint)] {
        self.model.points.enumerated().map { (offset: $0.offset, point: $0.element) }
    }

    private var palette: TokenSpeedFloatingWidgetPalette {
        TokenSpeedFloatingWidgetTheme.palette(for: self.colorScheme)
    }

    var body: some View {
        GeometryReader { geo in
            let baselineY = geo.size.height - 6
            let topInset: CGFloat = 14
            let horizontalInset: CGFloat = 8
            let usableHeight = max(baselineY - topInset, 1)
            let usableWidth = max(geo.size.width - (horizontalInset * 2), 1)
            let fallbackRocketX = geo.size.width - 18
            let rocketX = TokenSpeedFloatingRocketPlacement.xPosition(
                for: self.indexedPoints,
                horizontalInset: horizontalInset,
                usableWidth: usableWidth,
                fallbackX: fallbackRocketX)

            ZStack(alignment: .topLeading) {
                Path { path in
                    path.move(to: CGPoint(x: horizontalInset, y: baselineY))
                    path.addLine(to: CGPoint(x: geo.size.width - horizontalInset, y: baselineY))
                }
                .stroke(
                    self.palette.baseline,
                    style: StrokeStyle(lineWidth: 1.9, lineCap: .round, lineJoin: .round))

                ForEach(self.indexedPoints, id: \.offset) { indexedPoint in
                    if indexedPoint.point.rawTokens > 0 {
                        let progress = self.progress(for: indexedPoint.offset)
                        let x = horizontalInset + (usableWidth * progress)
                        let spikeHeight = self.spikeHeight(
                            for: indexedPoint.point,
                            usableHeight: usableHeight)

                        Path { path in
                            path.move(to: CGPoint(x: x, y: baselineY))
                            path.addLine(to: CGPoint(x: x, y: baselineY - spikeHeight))
                        }
                        .stroke(
                            self.palette.spike,
                            style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
                    }
                }

                self.rocket(
                    verticalOffset: self.rocketVerticalOffset(
                        baselineY: baselineY,
                        usableHeight: usableHeight))
                    .position(
                        x: rocketX,
                        y: baselineY)
                    .allowsHitTesting(false)
            }
        }
        .task(id: self.rocketBurstTrigger) {
            await self.runRocketBurstAnimation()
        }
    }

    private func progress(for index: Int) -> CGFloat {
        let denominator = max(self.model.points.count - 1, 1)
        return CGFloat(index) / CGFloat(denominator)
    }

    private func spikeHeight(
        for point: TokenSpeedDisplayPoint,
        usableHeight: CGFloat)
        -> CGFloat
    {
        guard self.model.scaleTopValue > 0 else { return 12 }
        let normalized = CGFloat(point.displayValue / self.model.scaleTopValue)
        return max(12, usableHeight * normalized)
    }

    private func rocketVerticalOffset(baselineY: CGFloat, usableHeight: CGFloat) -> CGFloat {
        guard self.model.scaleTopValue > 0 else { return -12 }
        let normalized = CGFloat(self.model.rocketHeadPoint.rocketValue / self.model.scaleTopValue)
        let trackY = baselineY - (usableHeight * normalized)
        return max(14, trackY - 8) - baselineY
    }

    private var rocketBurstTrigger: TokenSpeedRocketBurstTrigger? {
        TokenSpeedRocketBurstTrigger(
            launchTimestamp: self.model.rocketLaunchTimestamp,
            launchStrength: self.model.rocketLaunchStrength)
    }

    private func rocket(verticalOffset: CGFloat) -> some View {
        Text("🚀")
            .font(.system(size: 19))
            .offset(y: verticalOffset + self.rocketMotion.yOffset)
            .rotationEffect(.degrees(TokenSpeedFloatingRocketPlacement.baseAngle + self.rocketMotion.rotation))
            .scaleEffect(self.rocketMotion.scale)
    }

    @MainActor
    private func runRocketBurstAnimation() async {
        guard self.rocketBurstTrigger != nil else {
            self.rocketMotion = .zero
            return
        }

        let launchStrength = TokenSpeedRocketBurstAnimator.clampedStrength(self.model.rocketLaunchStrength)
        self.rocketMotion = .zero

        withAnimation(TokenSpeedRocketBurstAnimator.ignitionAnimation) {
            self.rocketMotion = TokenSpeedRocketBurstAnimator.launchMotion(
                strength: launchStrength,
                allowsHorizontalDrift: false)
        }

        do {
            try await Task.sleep(for: TokenSpeedRocketBurstAnimator.ignitionDuration)
        } catch {
            return
        }

        guard !Task.isCancelled else { return }

        withAnimation(TokenSpeedRocketBurstAnimator.settleAnimation) {
            self.rocketMotion = TokenSpeedRocketBurstAnimator.settleMotion(
                strength: launchStrength,
                allowsHorizontalDrift: false)
        }

        do {
            try await Task.sleep(for: TokenSpeedRocketBurstAnimator.settleDuration)
        } catch {
            return
        }

        guard !Task.isCancelled else { return }

        withAnimation(TokenSpeedRocketBurstAnimator.returnAnimation) {
            self.rocketMotion = .zero
        }
    }
}

private struct TokenSpeedFloatingMetricGroup: View {
    @Environment(\.colorScheme) private var colorScheme

    let label: String
    let value: TokenSpeedFloatingValueParts
    let magnitudeFontSize: CGFloat
    let suffixFontSize: CGFloat
    let minimumScaleFactor: CGFloat

    var body: some View {
        let palette = TokenSpeedFloatingWidgetTheme.palette(for: self.colorScheme)

        VStack(alignment: .leading, spacing: 3) {
            Text(self.label)
                .font(TokenMenuTheme.labelFont(size: 10, weight: .semibold))
                .foregroundStyle(palette.mutedText)
                .lineLimit(1)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(self.value.magnitude)
                    .font(TokenMenuTheme.metricFont(size: self.magnitudeFontSize, weight: .semibold))
                    .foregroundStyle(palette.text)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(self.minimumScaleFactor)

                if let suffix = self.value.suffix {
                    Text(suffix)
                        .font(TokenMenuTheme.labelFont(size: self.suffixFontSize, weight: .semibold))
                        .foregroundStyle(palette.text)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@MainActor
struct TokenSpeedFloatingChartContent: View {
    @Bindable var store: UsageStore
    @Bindable var settings: SettingsStore

    private var shape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: TokenMenuTheme.chromeCornerRadius(
                default: TokenSpeedFloatingChartLayout.cornerRadius,
                pixel: 12),
            style: .continuous)
    }

    private var chartModel: TokenSpeedPanelModel {
        TokenSpeedPanelModelBuilder.makeModel(samples: self.store.recentTokenSpeedSamples)
    }

    private var todayTokenParts: TokenSpeedFloatingValueParts {
        TokenSpeedFloatingValueFormatter.tokenParts(
            for: self.store.today.totalTokens,
            strings: self.settings.strings)
    }

    private var todayInstructionParts: TokenSpeedFloatingValueParts {
        TokenSpeedFloatingValueFormatter.instructionParts(
            for: self.store.todayOutboundMessages.instructionCount,
            strings: self.settings.strings)
    }

    var body: some View {
        let theme = self.settings.menuVisualTheme
        VStack(alignment: .leading, spacing: 0) {
            TokenSpeedFloatingSpikeChart(model: self.chartModel)
                .frame(height: TokenSpeedFloatingChartLayout.chartHeight)

            Spacer(minLength: TokenSpeedFloatingChartLayout.chartBottomSpacing)

            HStack(alignment: .top, spacing: 18) {
                TokenSpeedFloatingMetricGroup(
                    label: self.settings.strings.tokenSpeedFloatingTodayTokensLabel,
                    value: self.todayTokenParts,
                    magnitudeFontSize: 34,
                    suffixFontSize: 14,
                    minimumScaleFactor: 0.62)
                    .layoutPriority(1)

                TokenSpeedFloatingMetricGroup(
                    label: self.settings.strings.tokenSpeedFloatingTodayInstructionsLabel,
                    value: self.todayInstructionParts,
                    magnitudeFontSize: 34,
                    suffixFontSize: 14,
                    minimumScaleFactor: 0.62)
                    .frame(width: 72, alignment: .leading)
            }
            .padding(.top, TokenSpeedFloatingChartLayout.metricTopSpacing)
        }
        .padding(TokenSpeedFloatingChartLayout.contentPadding)
        .frame(
            width: TokenSpeedFloatingChartLayout.size.width,
            height: TokenSpeedFloatingChartLayout.size.height,
            alignment: .topLeading)
        .background(
            TokenSpeedFloatingWidgetBackground(cornerRadius: TokenSpeedFloatingChartLayout.cornerRadius))
        .clipShape(self.shape)
        .id(theme)
    }
}
