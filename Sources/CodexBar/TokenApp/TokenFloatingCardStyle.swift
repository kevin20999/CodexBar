import SwiftUI

enum TokenMetricAccentRole {
    case input
    case output
}

struct TokenHoverGlowStyle {
    let shadowOpacity: Double
    let shadowRadius: CGFloat
    let haloFillOpacity: Double
    let haloShadowOpacity: Double
    let haloShadowRadius: CGFloat
}

enum TokenFloatingCardTheme {
    private static var theme: MenuVisualThemeTokens {
        MenuVisualThemeProvider.tokens
    }

    static var chromeStyle: MenuVisualChromeStyle { self.theme.chromeStyle }
    static var usesPixelChrome: Bool { self.chromeStyle == .pixel }

    static var primaryText: Color { Color(nsColor: self.theme.floatingPrimaryText) }
    static var cardTop: Color { Color(nsColor: self.theme.floatingCardTop) }
    static var cardBottom: Color { Color(nsColor: self.theme.floatingCardBottom) }
    static var insetTop: Color { Color(nsColor: self.theme.floatingInsetTop) }
    static var insetBottom: Color { Color(nsColor: self.theme.floatingInsetBottom) }
    static var stroke: Color { Color(nsColor: self.theme.floatingStroke) }
    static var highlight: Color { Color(nsColor: self.theme.floatingHighlight) }
    static var secondaryText: Color { Color(nsColor: self.theme.floatingSecondaryText) }
    static var tertiaryText: Color { Color(nsColor: self.theme.floatingTertiaryText) }
    static var track: Color { Color(nsColor: self.theme.floatingTrack) }
    static var trackStroke: Color { Color(nsColor: self.theme.floatingTrackStroke) }
    static var plotFill: Color { Color(nsColor: self.theme.floatingPlotFill) }
    static var plotStroke: Color { Color(nsColor: self.theme.floatingPlotStroke) }
    static var chartGrid: Color { Color(nsColor: self.theme.floatingChartGrid) }
    static var chartAxis: Color { Color(nsColor: self.theme.floatingChartAxis) }
    static var selectionBand: Color { Color(nsColor: self.theme.floatingSelectionBand) }
    static var innerShadow: Color { Color(nsColor: self.theme.floatingInnerShadow) }
    static var outerShadow: Color { Color(nsColor: self.theme.floatingOuterShadow) }

    static func progressGradient(for role: TokenMetricAccentRole) -> LinearGradient {
        self.gradient(for: role)
    }

    static func chartGradient(for role: TokenMetricAccentRole) -> LinearGradient {
        self.gradient(for: role, endOpacity: 0.90)
    }

    static func valueGradient(for role: TokenMetricAccentRole) -> LinearGradient {
        self.gradient(for: role)
    }

    static func valueColor(for role: TokenMetricAccentRole) -> Color {
        let palette = self.palette(for: role)
        return Color(nsColor: palette.end)
    }

    static func glowColor(for role: TokenMetricAccentRole) -> Color {
        let palette = self.palette(for: role)
        return Color(nsColor: palette.glow)
    }

    static let hoverGlow = TokenHoverGlowStyle(
        shadowOpacity: 0.30,
        shadowRadius: 7,
        haloFillOpacity: 0.16,
        haloShadowOpacity: 0.34,
        haloShadowRadius: 10)

    private static func palette(for role: TokenMetricAccentRole) -> MenuVisualAccentPalette {
        switch role {
        case .input:
            self.theme.inputAccent
        case .output:
            self.theme.outputAccent
        }
    }

    private static func gradient(for role: TokenMetricAccentRole, endOpacity: Double = 1) -> LinearGradient {
        let palette = self.palette(for: role)
        return LinearGradient(
            colors: [
                Color(nsColor: palette.start),
                Color(nsColor: palette.end).opacity(endOpacity),
            ],
            startPoint: .leading,
            endPoint: .trailing)
    }
}

enum TokenRecentHistoryTheme {
    struct PeakLabelSurface {
        let top: Color
        let bottom: Color
        let stroke: Color
        let text: Color
    }

    struct RibbonPalette {
        let cardAccent: Color
        let areaFill: Color
        let glowStart: Color
        let glowMid: Color
        let glowEnd: Color
        let outlineStart: Color
        let outlineMid: Color
        let outlineEnd: Color
        let outlineSheen: Color
        let peakPoint: Color
        let peakGlow: Color
        let latestCore: Color
        let latestRing: Color
        let latestGlow: Color
        let peakLabelDark: PeakLabelSurface
        let peakLabelLight: PeakLabelSurface
        let axis: Color
        let boundaryAxis: Color
        let compressedAxis: Color
        let grid: Color
    }

    static func palette(for isDarkMode: Bool) -> RibbonPalette {
        let theme = MenuVisualThemeProvider.tokens
        let accent = theme.recentHistoryTint
        let accentColor = Color(nsColor: accent)
        let boundary = Color(nsColor: accent.lightened(isDarkMode ? 0.18 : 0.06))
        let compressed = Color(nsColor: accent.lightened(isDarkMode ? 0.10 : 0.02))
        let darkLabel = PeakLabelSurface(
            top: Color(nsColor: accent.darkened(0.56).mixed(with: .black, fraction: 0.24)),
            bottom: Color(nsColor: accent.darkened(0.72)),
            stroke: Color(nsColor: accent.lightened(0.10)).opacity(0.40),
            text: TokenFloatingCardTheme.primaryText)
        let lightLabel = PeakLabelSurface(
            top: Color(nsColor: accent.lightened(0.42)),
            bottom: Color(nsColor: accent.lightened(0.28)),
            stroke: Color(nsColor: accent.lightened(0.10)).opacity(0.82),
            text: TokenFloatingCardTheme.primaryText)

        return RibbonPalette(
            cardAccent: accentColor,
            areaFill: accentColor.opacity(isDarkMode ? 0.24 : 0.76),
            glowStart: accentColor.opacity(isDarkMode ? 0.20 : 0.12),
            glowMid: accentColor.opacity(isDarkMode ? 0.38 : 0.28),
            glowEnd: accentColor.opacity(isDarkMode ? 0.22 : 0.14),
            outlineStart: Color(nsColor: accent.darkened(isDarkMode ? 0.06 : 0.10)),
            outlineMid: accentColor,
            outlineEnd: Color(nsColor: accent.lightened(isDarkMode ? 0.24 : 0.18)),
            outlineSheen: Color.white.opacity(isDarkMode ? 0.80 : 0.92),
            peakPoint: Color.white.opacity(0.98),
            peakGlow: accentColor.opacity(isDarkMode ? 0.42 : 0.36),
            latestCore: Color.white.opacity(0.99),
            latestRing: Color(nsColor: accent.lightened(0.10)).opacity(0.96),
            latestGlow: accentColor.opacity(isDarkMode ? 0.32 : 0.28),
            peakLabelDark: darkLabel,
            peakLabelLight: lightLabel,
            axis: TokenFloatingCardTheme.chartAxis.opacity(isDarkMode ? 0.60 : 0.76),
            boundaryAxis: boundary,
            compressedAxis: compressed,
            grid: TokenFloatingCardTheme.chartGrid.opacity(isDarkMode ? 0.86 : 1))
    }

    static var cardAccent: Color {
        Color(nsColor: MenuVisualThemeProvider.tokens.recentHistoryTint)
    }

    static var accent: Color {
        self.cardAccent
    }
}

struct TokenTopRoundedBarShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let radius = min(self.radius, rect.width / 2, rect.height)
        guard radius > 0 else { return Path(rect) }

        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct TokenFloatingCardBackground: View {
    enum Emphasis {
        case regular
        case subtle
    }

    let cornerRadius: CGFloat
    let tint: Color
    let emphasis: Emphasis

    init(cornerRadius: CGFloat, tint: Color, emphasis: Emphasis = .regular) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.emphasis = emphasis
    }

    private var resolvedCornerRadius: CGFloat {
        TokenMenuTheme.chromeCornerRadius(default: self.cornerRadius, pixel: min(self.cornerRadius, 12))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: self.resolvedCornerRadius, style: .continuous)
    }

    private var radialOpacity: Double {
        switch self.emphasis {
        case .regular:
            0.20
        case .subtle:
            0.07
        }
    }

    private var highlightOpacity: Double {
        switch self.emphasis {
        case .regular:
            1
        case .subtle:
            0.38
        }
    }

    private var innerShadowOpacity: Double {
        switch self.emphasis {
        case .regular:
            1
        case .subtle:
            0.32
        }
    }

    private var innerShadowBlurRadius: CGFloat {
        switch self.emphasis {
        case .regular:
            2.8
        case .subtle:
            1
        }
    }

    private var innerShadowYOffset: CGFloat {
        switch self.emphasis {
        case .regular:
            1.4
        case .subtle:
            0.5
        }
    }

    private var tintShadowOpacity: Double {
        switch self.emphasis {
        case .regular:
            0.18
        case .subtle:
            0.05
        }
    }

    private var tintShadowRadius: CGFloat {
        switch self.emphasis {
        case .regular:
            18
        case .subtle:
            7
        }
    }

    private var tintShadowYOffset: CGFloat {
        switch self.emphasis {
        case .regular:
            8
        case .subtle:
            3
        }
    }

    private var outerShadowRadius: CGFloat {
        switch self.emphasis {
        case .regular:
            24
        case .subtle:
            10
        }
    }

    private var outerShadowYOffset: CGFloat {
        switch self.emphasis {
        case .regular:
            12
        case .subtle:
            4
        }
    }

    var body: some View {
        Group {
            if TokenFloatingCardTheme.usesPixelChrome {
                TokenPixelSurfaceBackground(
                    cornerRadius: self.resolvedCornerRadius,
                    tint: self.tint,
                    style: .card)
            } else {
                self.shape
                    .fill(
                        LinearGradient(
                            colors: [TokenFloatingCardTheme.cardTop, TokenFloatingCardTheme.cardBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                    .overlay {
                        self.shape
                            .fill(
                                RadialGradient(
                                    colors: [self.tint.opacity(self.radialOpacity), Color.clear],
                                    center: .topLeading,
                                    startRadius: 8,
                                    endRadius: 260))
                            .blendMode(.screen)
                    }
                    .overlay {
                        self.shape
                            .fill(
                                LinearGradient(
                                    colors: [TokenFloatingCardTheme.highlight, Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
                            .blendMode(.screen)
                            .opacity(self.highlightOpacity)
                    }
                    .overlay {
                        self.shape
                            .stroke(TokenFloatingCardTheme.stroke, lineWidth: 0.9)
                    }
                    .overlay {
                        self.shape
                            .stroke(TokenFloatingCardTheme.innerShadow.opacity(self.innerShadowOpacity), lineWidth: 1.2)
                            .blur(radius: self.innerShadowBlurRadius)
                            .offset(x: 0, y: self.innerShadowYOffset)
                            .mask(self.shape)
                    }
                    .shadow(
                        color: self.tint.opacity(self.tintShadowOpacity),
                        radius: self.tintShadowRadius,
                        x: 0,
                        y: self.tintShadowYOffset)
                    .shadow(
                        color: TokenFloatingCardTheme.outerShadow,
                        radius: self.outerShadowRadius,
                        x: 0,
                        y: self.outerShadowYOffset)
            }
        }
    }
}

struct TokenFloatingInsetBackground: View {
    let cornerRadius: CGFloat
    let tint: Color

    private var resolvedCornerRadius: CGFloat {
        TokenMenuTheme.chromeCornerRadius(default: self.cornerRadius, pixel: min(self.cornerRadius, 10))
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: self.resolvedCornerRadius, style: .continuous)
    }

    var body: some View {
        Group {
            if TokenFloatingCardTheme.usesPixelChrome {
                TokenPixelSurfaceBackground(
                    cornerRadius: self.resolvedCornerRadius,
                    tint: self.tint,
                    style: .inset)
            } else {
                self.shape
                    .fill(
                        LinearGradient(
                            colors: [TokenFloatingCardTheme.insetTop, TokenFloatingCardTheme.insetBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                    .overlay {
                        self.shape
                            .fill(
                                RadialGradient(
                                    colors: [self.tint.opacity(0.10), Color.clear],
                                    center: .topLeading,
                                    startRadius: 6,
                                    endRadius: 180))
                            .blendMode(.screen)
                    }
                    .overlay {
                        self.shape
                            .stroke(TokenFloatingCardTheme.stroke.opacity(0.9), lineWidth: 0.8)
                    }
                    .overlay {
                        self.shape
                            .stroke(TokenFloatingCardTheme.innerShadow.opacity(0.72), lineWidth: 1.1)
                            .blur(radius: 1.8)
                            .offset(x: 0, y: 1)
                            .mask(self.shape)
                    }
                    .shadow(color: self.tint.opacity(0.10), radius: 10, x: 0, y: 4)
            }
        }
    }
}
