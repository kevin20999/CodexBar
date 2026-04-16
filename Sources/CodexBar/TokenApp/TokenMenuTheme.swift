import SwiftUI

enum TokenMenuTheme {
    static let primaryText = Color.primary
    static let secondaryText = Color(nsColor: NSColor(
        srgbRed: 111 / 255,
        green: 116 / 255,
        blue: 129 / 255,
        alpha: 1))
    static let tertiaryText = Color(nsColor: NSColor(
        srgbRed: 145 / 255,
        green: 150 / 255,
        blue: 163 / 255,
        alpha: 1))
    static let footerButtonText = TokenFloatingCardTheme.tertiaryText
    static let footerButtonHoverText = TokenFloatingCardTheme.secondaryText
    static let footerButtonHoverFill = TokenMenuTheme.dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.08),
        light: NSColor(srgbRed: 0.978, green: 0.982, blue: 0.992, alpha: 0.60))
    static let footerButtonPressedFill = TokenMenuTheme.dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.12),
        light: NSColor(srgbRed: 0.986, green: 0.990, blue: 0.997, alpha: 0.74))
    static let footerButtonHoverStroke = TokenMenuTheme.dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.10),
        light: NSColor(srgbRed: 0.29, green: 0.34, blue: 0.42, alpha: 0.12))
    static let footerButtonPressedStroke = TokenMenuTheme.dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.16),
        light: NSColor(srgbRed: 0.25, green: 0.30, blue: 0.38, alpha: 0.18))
    static let footerButtonGlow = TokenMenuTheme.dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.05),
        light: NSColor(srgbRed: 0.71, green: 0.78, blue: 0.92, alpha: 0.14))
    static let warningText = Color(nsColor: .systemOrange)

    static let primaryQuotaTint = Color(nsColor: NSColor(
        srgbRed: 1.0,
        green: 122 / 255,
        blue: 47 / 255,
        alpha: 1))
    static let secondaryQuotaTint = Color(nsColor: NSColor(
        srgbRed: 1.0,
        green: 164 / 255,
        blue: 84 / 255,
        alpha: 1))
    static let reviewTint = Color(red: 0.99, green: 0.67, blue: 0.30)
    static let creditsTint = Color(red: 0.37, green: 0.87, blue: 0.84)
    static let analyticsTint = Color(red: 0.50, green: 0.60, blue: 1.0)
    static let recentHistoryTint = TokenRecentHistoryTheme.cardAccent
    static let quotaCardTint = Color(nsColor: NSColor(
        srgbRed: 1.0,
        green: 196 / 255,
        blue: 156 / 255,
        alpha: 1))

    static let inputTint = TokenFloatingCardTheme.valueColor(for: .input)
    static let outputTint = TokenFloatingCardTheme.valueColor(for: .output)

    static let heroNumber = TokenFloatingCardTheme.primaryText
    static let compactNumber = TokenFloatingCardTheme.primaryText
    static let metricHighlight = Color.primary.opacity(0.88)
    static let chartGrid = Color(nsColor: NSColor(
        srgbRed: 176 / 255,
        green: 184 / 255,
        blue: 201 / 255,
        alpha: 1)).opacity(0.30)
    static let chartAxis = TokenMenuTheme.secondaryText.opacity(0.82)

    static let glassStroke = Color.white.opacity(0.22)
    static let glassHighlight = Color.white.opacity(0.34)
    static let innerStroke = Color.white.opacity(0.14)
    static let progressTrack = Color(nsColor: NSColor(
        srgbRed: 216 / 255,
        green: 219 / 255,
        blue: 225 / 255,
        alpha: 1)).opacity(0.94)
    static let progressTrackStroke = Color.white.opacity(0.48)
    static let badgeBackground = Color.white.opacity(0.62)
    static let innerPanel = Color.white.opacity(0.09)
    static let tertiaryFill = Color.white.opacity(0.18)
    static let quotaDivider = Color(nsColor: NSColor(
        srgbRed: 219 / 255,
        green: 223 / 255,
        blue: 232 / 255,
        alpha: 1)).opacity(0.92)
    static let quotaDividerHighlight = Color.white.opacity(0.56)

    static let panelBase = Color(nsColor: NSColor(
        srgbRed: 244 / 255,
        green: 246 / 255,
        blue: 250 / 255,
        alpha: 1))
    static let panelGlowTop = Color(red: 1.0, green: 0.74, blue: 0.55).opacity(0.26)
    static let panelGlowTrailing = Color(red: 0.56, green: 0.72, blue: 1.0).opacity(0.20)
    static let panelShadow = Color.black.opacity(0.08)
    static let panelGlassTint = Color(red: 1.0, green: 0.66, blue: 0.42)
    static let panelLiquidStroke = Color.white.opacity(0.24)
    static let panelLiquidShadow = Color.black.opacity(0.10)
    static let tooltipLightSurfaceTop = Color(nsColor: NSColor(
        srgbRed: 244 / 255,
        green: 247 / 255,
        blue: 252 / 255,
        alpha: 0.96))
    static let tooltipLightSurfaceBottom = Color(nsColor: NSColor(
        srgbRed: 229 / 255,
        green: 236 / 255,
        blue: 247 / 255,
        alpha: 0.94))
    static let tooltipLightStroke = Color(nsColor: NSColor(
        srgbRed: 185 / 255,
        green: 198 / 255,
        blue: 221 / 255,
        alpha: 0.92))
    static let tooltipLightInnerHighlight = Color.white.opacity(0.72)
    static let tooltipLightShadow = Color(nsColor: NSColor(
        srgbRed: 62 / 255,
        green: 84 / 255,
        blue: 118 / 255,
        alpha: 0.18))
    static let tooltipLightGlow = Color(nsColor: NSColor(
        srgbRed: 127 / 255,
        green: 164 / 255,
        blue: 221 / 255,
        alpha: 0.22))
    static let tooltipLightPrimaryText = Color(nsColor: NSColor(
        srgbRed: 33 / 255,
        green: 40 / 255,
        blue: 54 / 255,
        alpha: 0.98))
    static let tooltipLightSecondaryText = Color(nsColor: NSColor(
        srgbRed: 79 / 255,
        green: 92 / 255,
        blue: 114 / 255,
        alpha: 0.94))
    static let tooltipLightTertiaryText = Color(nsColor: NSColor(
        srgbRed: 106 / 255,
        green: 116 / 255,
        blue: 135 / 255,
        alpha: 0.88))

    static func panelBackdrop() -> some View {
        Group {
            if #available(macOS 26, *) {
                Color.clear
            } else {
                let base = TokenMenuTheme.panelBase
                let glowTop = TokenMenuTheme.panelGlowTop
                let glowTrailing = TokenMenuTheme.panelGlowTrailing
                ZStack {
                    base
                    LinearGradient(
                        colors: [
                            glowTop,
                            Color.clear,
                            glowTrailing,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.15),
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
                tint.opacity(0.72),
                tint,
                Color.white.opacity(0.86),
            ],
            startPoint: .leading,
            endPoint: .trailing)
    }

    static func quotaValueGradient(for accent: QuotaProgressPresentation.Accent) -> LinearGradient {
        switch accent {
        case .primary:
            LinearGradient(
                colors: [
                    Color(nsColor: NSColor(srgbRed: 1.0, green: 99 / 255, blue: 32 / 255, alpha: 1)),
                    Color(nsColor: NSColor(srgbRed: 1.0, green: 145 / 255, blue: 63 / 255, alpha: 1)),
                ],
                startPoint: .leading,
                endPoint: .trailing)
        case .secondary:
            LinearGradient(
                colors: [
                    Color(nsColor: NSColor(srgbRed: 1.0, green: 112 / 255, blue: 43 / 255, alpha: 1)),
                    Color(nsColor: NSColor(srgbRed: 1.0, green: 169 / 255, blue: 84 / 255, alpha: 1)),
                ],
                startPoint: .leading,
                endPoint: .trailing)
        case .review:
            LinearGradient(
                colors: [
                    self.reviewTint,
                    self.reviewTint.opacity(0.82),
                ],
                startPoint: .leading,
                endPoint: .trailing)
        }
    }

    static func tooltipPrimaryText(for colorScheme: ColorScheme, usesFloatingStyle: Bool) -> Color {
        if colorScheme == .light {
            self.tooltipLightPrimaryText
        } else if usesFloatingStyle {
            TokenFloatingCardTheme.primaryText
        } else {
            self.primaryText
        }
    }

    static func tooltipSecondaryText(for colorScheme: ColorScheme, usesFloatingStyle: Bool) -> Color {
        if colorScheme == .light {
            self.tooltipLightSecondaryText
        } else if usesFloatingStyle {
            TokenFloatingCardTheme.secondaryText
        } else {
            self.secondaryText
        }
    }

    static func tooltipTertiaryText(for colorScheme: ColorScheme, usesFloatingStyle: Bool) -> Color {
        if colorScheme == .light {
            self.tooltipLightTertiaryText
        } else if usesFloatingStyle {
            TokenFloatingCardTheme.tertiaryText
        } else {
            self.tertiaryText
        }
    }

    static func tooltipValueGradient(for role: TokenMetricAccentRole, colorScheme: ColorScheme) -> LinearGradient {
        guard colorScheme == .light else {
            return TokenFloatingCardTheme.valueGradient(for: role)
        }

        switch role {
        case .input:
            return LinearGradient(
                colors: [
                    Color(nsColor: NSColor(srgbRed: 42 / 255, green: 114 / 255, blue: 232 / 255, alpha: 1)),
                    Color(nsColor: NSColor(srgbRed: 101 / 255, green: 168 / 255, blue: 250 / 255, alpha: 1)),
                ],
                startPoint: .leading,
                endPoint: .trailing)
        case .output:
            return LinearGradient(
                colors: [
                    Color(nsColor: NSColor(srgbRed: 47 / 255, green: 160 / 255, blue: 79 / 255, alpha: 1)),
                    Color(nsColor: NSColor(srgbRed: 97 / 255, green: 196 / 255, blue: 116 / 255, alpha: 1)),
                ],
                startPoint: .leading,
                endPoint: .trailing)
        }
    }

    private static func dynamicColor(dark: NSColor, light: NSColor) -> Color {
        Color(
            nsColor: NSColor(name: nil) { appearance in
                switch appearance.bestMatch(from: [.darkAqua, .aqua, .vibrantDark, .vibrantLight]) {
                case .aqua, .vibrantLight:
                    light
                default:
                    dark
                }
            })
    }
}

private enum TokenGlassSurfaceStyle {
    case panel
    case card
    case inset

    var baseFillOpacity: Double {
        switch self {
        case .panel:
            0.26
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
            1.0
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
            1.0
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

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
    }

    var body: some View {
        Group {
            if #available(macOS 26, *) {
                self.shape
                    .fill(.clear)
                    .glassEffect(.regular, in: self.shape)
            } else {
                TokenGlassSurfaceBackground(
                    cornerRadius: self.cornerRadius,
                    tint: self.tint,
                    style: .panel)
            }
        }
    }
}

struct TokenGlassCardBackground: View {
    let cornerRadius: CGFloat
    let tint: Color

    var body: some View {
        TokenGlassSurfaceBackground(
            cornerRadius: self.cornerRadius,
            tint: self.tint,
            style: .card)
    }
}

struct TokenGlassInsetBackground: View {
    let cornerRadius: CGFloat
    let tint: Color

    var body: some View {
        TokenGlassSurfaceBackground(
            cornerRadius: self.cornerRadius,
            tint: self.tint,
            style: .inset)
    }
}

struct TokenChartTooltipBackground: View {
    let cornerRadius: CGFloat
    let tint: Color
    @Environment(\.colorScheme) private var colorScheme

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
    }

    private var readabilityGradient: LinearGradient {
        if self.colorScheme == .light {
            LinearGradient(
                colors: [
                    TokenMenuTheme.tooltipLightSurfaceTop,
                    TokenMenuTheme.tooltipLightSurfaceBottom,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
        } else {
            LinearGradient(
                colors: [
                    TokenFloatingCardTheme.cardTop.opacity(0.60),
                    TokenFloatingCardTheme.cardBottom.opacity(0.50),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
        }
    }

    private var readabilityOpacity: Double {
        if self.colorScheme == .light {
            0.96
        } else if #available(macOS 26, *) {
            0.34
        } else {
            0.62
        }
    }

    private var tintOpacity: Double {
        self.colorScheme == .light ? 0.08 : 0.20
    }

    private var glossGradient: LinearGradient {
        if self.colorScheme == .light {
            LinearGradient(
                colors: [
                    TokenMenuTheme.tooltipLightInnerHighlight,
                    Color.white.opacity(0.22),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
        } else {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.20),
                    Color.white.opacity(0.05),
                    Color.clear,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing)
        }
    }

    private var glowGradient: RadialGradient {
        if self.colorScheme == .light {
            RadialGradient(
                colors: [
                    TokenMenuTheme.tooltipLightGlow,
                    Color.clear,
                ],
                center: .topLeading,
                startRadius: 6,
                endRadius: 130)
        } else {
            RadialGradient(
                colors: [
                    self.tint.opacity(0.16),
                    Color.clear,
                ],
                center: .topLeading,
                startRadius: 6,
                endRadius: 130)
        }
    }

    var body: some View {
        ZStack {
            if self.colorScheme == .light {
                self.shape
                    .fill(TokenMenuTheme.tooltipLightSurfaceTop)
            } else {
                self.shape
                    .fill(.regularMaterial)
            }

            self.shape
                .fill(self.readabilityGradient)
                .opacity(self.readabilityOpacity)

            self.shape
                .fill(self.glossGradient)
                .blendMode(.screen)

            self.shape
                .fill(self.glowGradient)
                .opacity(self.colorScheme == .light ? 0.56 : 0.78)
        }
        .overlay(
            self.shape
                .stroke(
                    self.colorScheme == .light
                        ? TokenMenuTheme.tooltipLightStroke
                        : TokenMenuTheme.glassStroke.opacity(0.90),
                    lineWidth: self.colorScheme == .light ? 0.95 : 0.85))
        .overlay(
            self.shape
                .stroke(
                    self.colorScheme == .light
                        ? TokenMenuTheme.tooltipLightInnerHighlight.opacity(0.84)
                        : Color.white.opacity(0.14),
                    lineWidth: self.colorScheme == .light ? 0.6 : 0.45)
                .blur(radius: 1.0))
        .shadow(
            color: self.colorScheme == .light
                ? TokenMenuTheme.tooltipLightGlow.opacity(0.54)
                : self.tint.opacity(0.16),
            radius: self.colorScheme == .light ? 10 : 12,
            x: 0,
            y: self.colorScheme == .light ? 3 : 4)
        .shadow(
            color: self.colorScheme == .light
                ? TokenMenuTheme.tooltipLightShadow
                : TokenFloatingCardTheme.outerShadow.opacity(0.45),
            radius: self.colorScheme == .light ? 20 : 16,
            x: 0,
            y: self.colorScheme == .light ? 10 : 6)
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

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(TokenMenuTheme.progressTrack)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(TokenMenuTheme.progressTrackStroke, lineWidth: strokeWidth))

                if fillWidth > 0 {
                    Capsule(style: .continuous)
                        .fill(self.fillGradient)
                        .frame(width: min(fillWidth, width))
                        .overlay(alignment: .top) {
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.28),
                                            Color.clear,
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom))
                                .frame(height: max(self.height * 0.42, 2.5))
                                .clipShape(Capsule(style: .continuous))
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
