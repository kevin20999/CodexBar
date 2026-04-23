import SwiftUI

enum TokenMenuTheme {
    private static var theme: MenuVisualThemeTokens {
        MenuVisualThemeProvider.tokens
    }

    static var chromeStyle: MenuVisualChromeStyle { self.theme.chromeStyle }
    static var usesPixelChrome: Bool { self.chromeStyle == .pixel }

    static var primaryText: Color { Color(nsColor: self.theme.primaryText) }
    static var secondaryText: Color { Color(nsColor: self.theme.secondaryText) }
    static var tertiaryText: Color { Color(nsColor: self.theme.tertiaryText) }
    static var footerButtonText: Color { TokenFloatingCardTheme.tertiaryText }
    static var footerButtonHoverText: Color { TokenFloatingCardTheme.secondaryText }
    static var footerButtonHoverFill: Color { Color(nsColor: self.theme.analyticsTint).opacity(0.10) }
    static var footerButtonPressedFill: Color { Color(nsColor: self.theme.analyticsTint).opacity(0.16) }
    static var footerButtonHoverStroke: Color { Color(nsColor: self.theme.glassStroke).opacity(0.38) }
    static var footerButtonPressedStroke: Color { Color(nsColor: self.theme.glassStroke).opacity(0.52) }
    static var footerButtonGlow: Color { Color(nsColor: self.theme.analyticsTint).opacity(0.18) }
    static var warningText: Color { Color(nsColor: self.theme.warningText) }

    static var primaryQuotaTint: Color { Color(nsColor: self.theme.primaryQuotaTint) }
    static var secondaryQuotaTint: Color { Color(nsColor: self.theme.secondaryQuotaTint) }
    static var reviewTint: Color { Color(nsColor: self.theme.reviewTint) }
    static var creditsTint: Color { Color(nsColor: self.theme.creditsTint) }
    static var analyticsTint: Color { Color(nsColor: self.theme.analyticsTint) }
    static var recentHistoryTint: Color { Color(nsColor: self.theme.recentHistoryTint) }
    static var quotaCardTint: Color { Color(nsColor: self.theme.primaryQuotaTint.lightened(0.30)) }

    static var inputTint: Color { TokenFloatingCardTheme.valueColor(for: .input) }
    static var outputTint: Color { TokenFloatingCardTheme.valueColor(for: .output) }

    static var heroNumber: Color { TokenFloatingCardTheme.primaryText }
    static var compactNumber: Color { TokenFloatingCardTheme.primaryText }
    static var metricHighlight: Color { Color(nsColor: self.theme.primaryText).opacity(0.88) }
    static var chartGrid: Color { Color(nsColor: self.theme.chartGrid) }
    static var chartAxis: Color { Color(nsColor: self.theme.chartAxis) }

    static var glassStroke: Color { Color(nsColor: self.theme.glassStroke) }
    static var glassHighlight: Color { Color(nsColor: self.theme.glassHighlight) }
    static var innerStroke: Color { Color(nsColor: self.theme.glassStroke).opacity(0.55) }
    static var progressTrack: Color { TokenFloatingCardTheme.track }
    static var progressTrackStroke: Color { TokenFloatingCardTheme.trackStroke }
    static var badgeBackground: Color { Color(nsColor: self.theme.panelBase.lightened(0.08)).opacity(0.82) }
    static var innerPanel: Color { Color(nsColor: self.theme.panelBase.lightened(0.03)).opacity(0.14) }
    static var tertiaryFill: Color { Color(nsColor: self.theme.panelBase).opacity(0.16) }
    static var quotaDivider: Color { Color(nsColor: self.theme.glassStroke).opacity(0.58) }
    static var quotaDividerHighlight: Color { Color(nsColor: self.theme.glassHighlight).opacity(0.72) }

    static var panelBase: Color { Color(nsColor: self.theme.panelBase) }
    static var panelGlowTop: Color { Color(nsColor: self.theme.panelGlowTop) }
    static var panelGlowTrailing: Color { Color(nsColor: self.theme.panelGlowTrailing) }
    static var panelShadow: Color { Color(nsColor: self.theme.panelShadow) }
    static var panelGlassTint: Color { Color(nsColor: self.theme.panelGlassTint) }
    static var panelLiquidStroke: Color { Color(nsColor: self.theme.glassStroke) }
    static var panelLiquidShadow: Color { Color(nsColor: self.theme.panelShadow) }

    static var pixelShadow: Color { Color(nsColor: self.theme.panelShadow) }

    static func labelFont(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        if self.usesPixelChrome {
            return .system(size: size, weight: weight == .regular ? .medium : weight, design: .monospaced)
        }
        return .system(size: size, weight: weight)
    }

    static func metricFont(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        if self.usesPixelChrome {
            return .system(size: size, weight: weight, design: .monospaced)
        }
        return .system(size: size, weight: weight)
    }

    static func nsLabelFont(size: CGFloat, weight: NSFont.Weight = .semibold) -> NSFont {
        if self.usesPixelChrome {
            return NSFont.monospacedSystemFont(ofSize: size, weight: weight)
        }
        return NSFont.systemFont(ofSize: size, weight: weight)
    }

    static func chromeCornerRadius(default defaultRadius: CGFloat, pixel pixelRadius: CGFloat) -> CGFloat {
        self.usesPixelChrome ? pixelRadius : defaultRadius
    }

    static var tooltipLightSurfaceTop: Color { Color(nsColor: self.theme.tooltipSurfaceTop) }
    static var tooltipLightSurfaceBottom: Color { Color(nsColor: self.theme.tooltipSurfaceBottom) }
    static var tooltipLightStroke: Color { Color(nsColor: self.theme.tooltipStroke) }
    static var tooltipLightInnerHighlight: Color { Color(nsColor: self.theme.tooltipInnerHighlight) }
    static var tooltipLightShadow: Color { Color(nsColor: self.theme.tooltipShadow) }
    static var tooltipLightGlow: Color { Color(nsColor: self.theme.tooltipGlow) }
    static var tooltipLightPrimaryText: Color { Color(nsColor: self.theme.tooltipPrimaryText) }
    static var tooltipLightSecondaryText: Color { Color(nsColor: self.theme.tooltipSecondaryText) }
    static var tooltipLightTertiaryText: Color { Color(nsColor: self.theme.tooltipTertiaryText) }

    static func panelBackdrop() -> some View {
        Group {
            if #available(macOS 26, *) {
                Color.clear
            } else {
                ZStack {
                    self.panelBase
                    LinearGradient(
                        colors: [
                            self.panelGlowTop,
                            Color.clear,
                            self.panelGlowTrailing,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                    RadialGradient(
                        colors: [
                            self.glassHighlight.opacity(0.16),
                            Color.clear,
                        ],
                        center: .topLeading,
                        startRadius: 8,
                        endRadius: 280)
                }
            }
        }
    }

    static func progressGradient(for tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                tint.opacity(0.74),
                tint,
                Color.white.opacity(0.82),
            ],
            startPoint: .leading,
            endPoint: .trailing)
    }

    static func quotaValueGradient(for accent: QuotaProgressPresentation.Accent) -> LinearGradient {
        switch accent {
        case .primary:
            self.tintGradient(from: self.primaryQuotaTint)
        case .secondary:
            self.tintGradient(from: self.secondaryQuotaTint)
        case .review:
            self.tintGradient(from: self.reviewTint)
        }
    }

    static func tooltipPrimaryText(for colorScheme: ColorScheme, usesFloatingStyle: Bool) -> Color {
        self.tooltipLightPrimaryText
    }

    static func tooltipSecondaryText(for colorScheme: ColorScheme, usesFloatingStyle: Bool) -> Color {
        self.tooltipLightSecondaryText
    }

    static func tooltipTertiaryText(for colorScheme: ColorScheme, usesFloatingStyle: Bool) -> Color {
        self.tooltipLightTertiaryText
    }

    static func tooltipValueGradient(for role: TokenMetricAccentRole, colorScheme: ColorScheme) -> LinearGradient {
        TokenFloatingCardTheme.valueGradient(for: role)
    }

    private static func tintGradient(from tint: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                tint.opacity(0.92),
                tint,
                Color.white.opacity(0.28),
            ],
            startPoint: .leading,
            endPoint: .trailing)
    }
}

private enum TokenGlassSurfaceStyle {
    case panel
    case card
    case inset

    var baseFillOpacity: Double {
        switch self {
        case .panel:
            0.28
        case .card:
            0.34
        case .inset:
            0.22
        }
    }

    var glassTintOpacity: Double {
        switch self {
        case .panel:
            0.18
        case .card:
            0.12
        case .inset:
            0.08
        }
    }

    var highlightOpacity: Double {
        switch self {
        case .panel:
            0.95
        case .card:
            1
        case .inset:
            0.78
        }
    }

    var middleGlowOpacity: Double {
        switch self {
        case .panel:
            0.12
        case .card:
            0.08
        case .inset:
            0.06
        }
    }

    var radialOpacity: Double {
        switch self {
        case .panel:
            0.22
        case .card:
            0.20
        case .inset:
            0.12
        }
    }

    var radialEndRadius: CGFloat {
        switch self {
        case .panel:
            360
        case .card:
            220
        case .inset:
            160
        }
    }

    var strokeOpacity: Double {
        switch self {
        case .panel:
            1.05
        case .card:
            1
        case .inset:
            0.72
        }
    }

    var highlightStrokeOpacity: Double {
        switch self {
        case .panel:
            0.52
        case .card:
            0.45
        case .inset:
            0.30
        }
    }

    var tintShadowOpacity: Double {
        switch self {
        case .panel:
            0.18
        case .card:
            0.14
        case .inset:
            0.10
        }
    }

    var tintShadowRadius: CGFloat {
        switch self {
        case .panel:
            26
        case .card:
            18
        case .inset:
            12
        }
    }

    var tintShadowYOffset: CGFloat {
        switch self {
        case .panel:
            14
        case .card:
            10
        case .inset:
            6
        }
    }

    var panelShadowRadius: CGFloat {
        switch self {
        case .panel:
            16
        case .card:
            10
        case .inset:
            6
        }
    }

    var panelShadowYOffset: CGFloat {
        switch self {
        case .panel:
            7
        case .card:
            4
        case .inset:
            2
        }
    }
}

enum TokenPixelSurfaceStyle {
    case panel
    case card
    case inset
    case tooltip

    var strokeWidth: CGFloat {
        switch self {
        case .panel:
            2.2
        case .card, .tooltip:
            1.8
        case .inset:
            1.4
        }
    }

    var shadowOffset: CGFloat {
        switch self {
        case .panel:
            8
        case .card:
            6
        case .inset:
            3
        case .tooltip:
            4
        }
    }

    var tintOpacity: Double {
        switch self {
        case .panel:
            0.16
        case .card:
            0.10
        case .inset:
            0.08
        case .tooltip:
            0.12
        }
    }

    var highlightOpacity: Double {
        switch self {
        case .panel:
            0.62
        case .card:
            0.54
        case .inset:
            0.34
        case .tooltip:
            0.48
        }
    }
}

struct TokenPixelSurfaceBackground: View {
    let cornerRadius: CGFloat
    let tint: Color
    let style: TokenPixelSurfaceStyle

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
    }

    var body: some View {
        self.shape
            .fill(
                LinearGradient(
                    colors: [
                        TokenMenuTheme.panelBase,
                        Color(nsColor: MenuVisualThemeProvider.tokens.panelBase.darkened(0.03)),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing))
            .overlay {
                self.shape
                    .fill(
                        LinearGradient(
                            colors: [
                                TokenMenuTheme.glassHighlight.opacity(self.style.highlightOpacity),
                                Color.white.opacity(0.04),
                                Color.clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
            }
            .overlay(alignment: .topLeading) {
                RoundedRectangle(
                    cornerRadius: max(self.cornerRadius - 2, 4),
                    style: .continuous)
                    .stroke(Color.white.opacity(0.38), lineWidth: 1)
                    .padding(3)
                    .mask(
                        LinearGradient(
                            colors: [Color.white, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
            }
            .overlay {
                self.shape
                    .fill(
                        RadialGradient(
                            colors: [
                                self.tint.opacity(self.style.tintOpacity),
                                Color.clear,
                            ],
                            center: .topLeading,
                            startRadius: 6,
                            endRadius: 180))
            }
            .overlay {
                self.shape
                    .stroke(TokenMenuTheme.glassStroke, lineWidth: self.style.strokeWidth)
            }
            .shadow(
                color: TokenMenuTheme.pixelShadow.opacity(0.85),
                radius: 0,
                x: self.style.shadowOffset,
                y: self.style.shadowOffset)
    }
}

private struct TokenGlassSurfaceBackground: View {
    let cornerRadius: CGFloat
    let tint: Color
    let style: TokenGlassSurfaceStyle

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
    }

    var body: some View {
        ZStack {
            self.shape
                .fill(.ultraThinMaterial)

            self.shape
                .fill(
                    LinearGradient(
                        colors: [
                            TokenMenuTheme.panelBase.opacity(self.style.baseFillOpacity),
                            TokenMenuTheme.panelBase.opacity(self.style.baseFillOpacity * 0.72),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))

            self.shape
                .fill(
                    LinearGradient(
                        colors: [
                            TokenMenuTheme.glassHighlight.opacity(self.style.highlightOpacity),
                            Color.white.opacity(self.style.middleGlowOpacity),
                            Color.clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))
                .blendMode(.screen)

            self.shape
                .fill(
                    RadialGradient(
                        colors: [
                            self.tint.opacity(self.style.radialOpacity),
                            Color.clear,
                        ],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: self.style.radialEndRadius))
                .opacity(0.85)
        }
        .overlay(
            self.shape
                .stroke(TokenMenuTheme.glassStroke.opacity(self.style.strokeOpacity), lineWidth: 0.9))
        .overlay(
            self.shape
                .stroke(TokenMenuTheme.glassHighlight.opacity(self.style.highlightStrokeOpacity), lineWidth: 0.5)
                .blur(radius: 1.2))
        .shadow(
            color: self.tint.opacity(self.style.tintShadowOpacity),
            radius: self.style.tintShadowRadius,
            x: 0,
            y: self.style.tintShadowYOffset)
        .shadow(
            color: TokenMenuTheme.panelShadow,
            radius: self.style.panelShadowRadius,
            x: 0,
            y: self.style.panelShadowYOffset)
    }
}

struct TokenGlassPanelBackground: View {
    let cornerRadius: CGFloat
    let tint: Color

    private var resolvedCornerRadius: CGFloat {
        TokenMenuTheme.chromeCornerRadius(default: self.cornerRadius, pixel: min(self.cornerRadius, 14))
    }

    var body: some View {
        Group {
            if TokenMenuTheme.usesPixelChrome {
                TokenPixelSurfaceBackground(
                    cornerRadius: self.resolvedCornerRadius,
                    tint: self.tint,
                    style: .panel)
            } else if #available(macOS 26, *) {
                RoundedRectangle(cornerRadius: self.resolvedCornerRadius, style: .continuous)
                    .fill(.clear)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: self.resolvedCornerRadius, style: .continuous))
            } else {
                TokenGlassSurfaceBackground(
                    cornerRadius: self.resolvedCornerRadius,
                    tint: self.tint,
                    style: .panel)
            }
        }
    }
}

struct TokenGlassCardBackground: View {
    let cornerRadius: CGFloat
    let tint: Color

    private var resolvedCornerRadius: CGFloat {
        TokenMenuTheme.chromeCornerRadius(default: self.cornerRadius, pixel: min(self.cornerRadius, 12))
    }

    var body: some View {
        if TokenMenuTheme.usesPixelChrome {
            TokenPixelSurfaceBackground(
                cornerRadius: self.resolvedCornerRadius,
                tint: self.tint,
                style: .card)
        } else {
            TokenGlassSurfaceBackground(
                cornerRadius: self.resolvedCornerRadius,
                tint: self.tint,
                style: .card)
        }
    }
}

struct TokenGlassInsetBackground: View {
    let cornerRadius: CGFloat
    let tint: Color

    private var resolvedCornerRadius: CGFloat {
        TokenMenuTheme.chromeCornerRadius(default: self.cornerRadius, pixel: min(self.cornerRadius, 10))
    }

    var body: some View {
        if TokenMenuTheme.usesPixelChrome {
            TokenPixelSurfaceBackground(
                cornerRadius: self.resolvedCornerRadius,
                tint: self.tint,
                style: .inset)
        } else {
            TokenGlassSurfaceBackground(
                cornerRadius: self.resolvedCornerRadius,
                tint: self.tint,
                style: .inset)
        }
    }
}

struct TokenChartTooltipBackground: View {
    let cornerRadius: CGFloat
    let tint: Color

    private var resolvedCornerRadius: CGFloat {
        TokenMenuTheme.chromeCornerRadius(default: self.cornerRadius, pixel: min(self.cornerRadius, 8))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: self.resolvedCornerRadius, style: .continuous)
    }

    var body: some View {
        Group {
            if TokenMenuTheme.usesPixelChrome {
                TokenPixelSurfaceBackground(
                    cornerRadius: self.resolvedCornerRadius,
                    tint: self.tint,
                    style: .tooltip)
            } else {
                ZStack {
                    self.shape
                        .fill(TokenMenuTheme.tooltipLightSurfaceTop)

                    self.shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    TokenMenuTheme.tooltipLightSurfaceTop,
                                    TokenMenuTheme.tooltipLightSurfaceBottom,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))

                    self.shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    TokenMenuTheme.tooltipLightInnerHighlight,
                                    Color.white.opacity(0.18),
                                    Color.clear,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                        .blendMode(.screen)

                    self.shape
                        .fill(
                            RadialGradient(
                                colors: [
                                    TokenMenuTheme.tooltipLightGlow,
                                    Color.clear,
                                ],
                                center: .topLeading,
                                startRadius: 6,
                                endRadius: 130))
                        .opacity(0.58)
                }
                .overlay(
                    self.shape
                        .stroke(TokenMenuTheme.tooltipLightStroke, lineWidth: 0.95))
                .overlay(
                    self.shape
                        .stroke(TokenMenuTheme.tooltipLightInnerHighlight.opacity(0.84), lineWidth: 0.6)
                        .blur(radius: 1))
                .shadow(
                    color: TokenMenuTheme.tooltipLightGlow.opacity(0.54),
                    radius: 10,
                    x: 0,
                    y: 3)
                .shadow(
                    color: TokenMenuTheme.tooltipLightShadow,
                    radius: 20,
                    x: 0,
                    y: 10)
            }
        }
    }
}

struct TokenProgressBar: View {
    let fraction: Double
    let tint: Color
    var accentRole: TokenMetricAccentRole?
    var height: CGFloat = 10

    private var clampedFraction: Double {
        min(max(self.fraction, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let minimumVisibleWidth = max(self.height * 1.6, 10)
            let fillWidth = self.clampedFraction == 0 ? 0 : max(width * self.clampedFraction, minimumVisibleWidth)
            let strokeWidth = self.height <= 7 ? 0.65 : 0.8
            let cornerRadius = TokenMenuTheme.usesPixelChrome
                ? min(max(self.height * 0.28, 3), 5)
                : self.height / 2

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(TokenMenuTheme.progressTrack)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(TokenMenuTheme.progressTrackStroke, lineWidth: strokeWidth))

                if fillWidth > 0 {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(self.fillGradient)
                        .frame(width: min(fillWidth, width))
                        .overlay(alignment: .top) {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.28),
                                            Color.clear,
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom))
                                .frame(height: max(self.height * 0.42, 2.5))
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                        }
                        .shadow(
                            color: self.glowColor.opacity(self.height <= 7 ? 0.22 : 0.28),
                            radius: self.height <= 7 ? 5 : 8,
                            x: 0,
                            y: 0)
                }
            }
        }
        .frame(height: self.height)
    }

    private var fillGradient: LinearGradient {
        guard let accentRole else {
            return TokenMenuTheme.progressGradient(for: self.tint)
        }
        return TokenFloatingCardTheme.progressGradient(for: accentRole)
    }

    private var glowColor: Color {
        guard let accentRole else { return self.tint }
        return TokenFloatingCardTheme.glowColor(for: accentRole)
    }
}
