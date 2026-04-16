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
    private struct AccentPalette {
        let start: Color
        let end: Color
        let valueGradient: LinearGradient
        let progressGradient: LinearGradient
        let chartGradient: LinearGradient
        let glow: Color
    }

    static let primaryText = dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.94),
        light: NSColor(srgbRed: 0.16, green: 0.19, blue: 0.26, alpha: 0.95))
    static let cardTop = dynamicColor(
        dark: NSColor(srgbRed: 0.16, green: 0.16, blue: 0.23, alpha: 1),
        light: NSColor(srgbRed: 0.995, green: 0.989, blue: 0.978, alpha: 1))
    static let cardBottom = dynamicColor(
        dark: NSColor(srgbRed: 0.12, green: 0.12, blue: 0.17, alpha: 1),
        light: NSColor(srgbRed: 0.976, green: 0.978, blue: 0.986, alpha: 1))
    static let insetTop = dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.07),
        light: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.88))
    static let insetBottom = dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.025),
        light: NSColor(srgbRed: 1, green: 0.996, blue: 0.992, alpha: 0.60))
    static let stroke = dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.09),
        light: NSColor(srgbRed: 0.36, green: 0.41, blue: 0.50, alpha: 0.14))
    static let highlight = dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.14),
        light: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.82))
    static let secondaryText = dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.62),
        light: NSColor(srgbRed: 0.23, green: 0.27, blue: 0.35, alpha: 0.62))
    static let tertiaryText = dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.46),
        light: NSColor(srgbRed: 0.36, green: 0.39, blue: 0.47, alpha: 0.54))
    static let track = dynamicColor(
        dark: NSColor(srgbRed: 0.23, green: 0.23, blue: 0.29, alpha: 0.84),
        light: NSColor(srgbRed: 0.86, green: 0.87, blue: 0.89, alpha: 0.92))
    static let trackStroke = dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.05),
        light: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.72))
    static let plotFill = dynamicColor(
        dark: NSColor(srgbRed: 0.22, green: 0.23, blue: 0.29, alpha: 0.74),
        light: NSColor(srgbRed: 0.94, green: 0.95, blue: 0.97, alpha: 0.88))
    static let plotStroke = dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.06),
        light: NSColor(srgbRed: 0.13, green: 0.17, blue: 0.24, alpha: 0.08))
    static let chartGrid = dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.10),
        light: NSColor(srgbRed: 0.10, green: 0.14, blue: 0.20, alpha: 0.10))
    static let chartAxis = dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.56),
        light: NSColor(srgbRed: 0.12, green: 0.15, blue: 0.21, alpha: 0.56))
    static let selectionBand = dynamicColor(
        dark: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.06),
        light: NSColor(srgbRed: 0.11, green: 0.14, blue: 0.20, alpha: 0.06))
    static let innerShadow = dynamicColor(
        dark: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.24),
        light: NSColor(srgbRed: 0.24, green: 0.28, blue: 0.36, alpha: 0.10))
    static let outerShadow = dynamicColor(
        dark: NSColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.34),
        light: NSColor(srgbRed: 0.33, green: 0.35, blue: 0.40, alpha: 0.12))

    static func progressGradient(for role: TokenMetricAccentRole) -> LinearGradient {
        self.palette(for: role).progressGradient
    }

    static func chartGradient(for role: TokenMetricAccentRole) -> LinearGradient {
        self.palette(for: role).chartGradient
    }

    static func valueGradient(for role: TokenMetricAccentRole) -> LinearGradient {
        self.palette(for: role).valueGradient
    }

    static func valueColor(for role: TokenMetricAccentRole) -> Color {
        self.palette(for: role).end
    }

    static func glowColor(for role: TokenMetricAccentRole) -> Color {
        self.palette(for: role).glow
    }

    static let hoverGlow = TokenHoverGlowStyle(
        shadowOpacity: 0.30,
        shadowRadius: 7,
        haloFillOpacity: 0.16,
        haloShadowOpacity: 0.34,
        haloShadowRadius: 10)

    private static func palette(for role: TokenMetricAccentRole) -> AccentPalette {
        switch role {
        case .input:
            let start = self.dynamicColor(
                dark: NSColor(srgbRed: 77 / 255, green: 168 / 255, blue: 1, alpha: 0.98),
                light: NSColor(srgbRed: 59 / 255, green: 138 / 255, blue: 245 / 255, alpha: 0.92))
            let end = self.dynamicColor(
                dark: NSColor(srgbRed: 123 / 255, green: 217 / 255, blue: 1, alpha: 0.96),
                light: NSColor(srgbRed: 111 / 255, green: 193 / 255, blue: 1, alpha: 0.88))
            let glow = self.dynamicColor(
                dark: NSColor(srgbRed: 103 / 255, green: 198 / 255, blue: 1, alpha: 0.86),
                light: NSColor(srgbRed: 83 / 255, green: 171 / 255, blue: 247 / 255, alpha: 0.58))
            return AccentPalette(
                start: start,
                end: end,
                valueGradient: LinearGradient(
                    colors: [start, end],
                    startPoint: .leading,
                    endPoint: .trailing),
                progressGradient: LinearGradient(
                    colors: [start, end],
                    startPoint: .leading,
                    endPoint: .trailing),
                chartGradient: LinearGradient(
                    colors: [start.opacity(0.98), end.opacity(0.90)],
                    startPoint: .leading,
                    endPoint: .trailing),
                glow: glow)
        case .output:
            let start = self.dynamicColor(
                dark: NSColor(srgbRed: 76 / 255, green: 1, blue: 150 / 255, alpha: 0.97),
                light: NSColor(srgbRed: 56 / 255, green: 196 / 255, blue: 92 / 255, alpha: 0.92))
            let end = self.dynamicColor(
                dark: NSColor(srgbRed: 50 / 255, green: 216 / 255, blue: 156 / 255, alpha: 0.94),
                light: NSColor(srgbRed: 112 / 255, green: 224 / 255, blue: 130 / 255, alpha: 0.84))
            let glow = self.dynamicColor(
                dark: NSColor(srgbRed: 87 / 255, green: 237 / 255, blue: 171 / 255, alpha: 0.82),
                light: NSColor(srgbRed: 94 / 255, green: 210 / 255, blue: 114 / 255, alpha: 0.52))
            return AccentPalette(
                start: start,
                end: end,
                valueGradient: LinearGradient(
                    colors: [start, end],
                    startPoint: .leading,
                    endPoint: .trailing),
                progressGradient: LinearGradient(
                    colors: [start, end],
                    startPoint: .leading,
                    endPoint: .trailing),
                chartGradient: LinearGradient(
                    colors: [start.opacity(0.98), end.opacity(0.88)],
                    startPoint: .leading,
                    endPoint: .trailing),
                glow: glow)
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

    static let paletteLight = RibbonPalette(
        cardAccent: TokenRecentHistoryTheme.cardAccent,
        areaFill: Color(nsColor: NSColor(srgbRed: 189 / 255, green: 226 / 255, blue: 255 / 255, alpha: 0.76)),
        glowStart: Color(nsColor: NSColor(srgbRed: 154 / 255, green: 211 / 255, blue: 255 / 255, alpha: 0.12)),
        glowMid: Color(nsColor: NSColor(srgbRed: 112 / 255, green: 193 / 255, blue: 255 / 255, alpha: 0.28)),
        glowEnd: Color(nsColor: NSColor(srgbRed: 72 / 255, green: 161 / 255, blue: 244 / 255, alpha: 0.14)),
        outlineStart: Color(nsColor: NSColor(srgbRed: 61 / 255, green: 136 / 255, blue: 235 / 255, alpha: 0.98)),
        outlineMid: Color(nsColor: NSColor(srgbRed: 87 / 255, green: 171 / 255, blue: 248 / 255, alpha: 0.96)),
        outlineEnd: Color(nsColor: NSColor(srgbRed: 124 / 255, green: 201 / 255, blue: 255 / 255, alpha: 0.94)),
        outlineSheen: Color(nsColor: NSColor(srgbRed: 247 / 255, green: 251 / 255, blue: 255 / 255, alpha: 0.92)),
        peakPoint: Color(nsColor: NSColor(srgbRed: 245 / 255, green: 250 / 255, blue: 255 / 255, alpha: 0.98)),
        peakGlow: Color(nsColor: NSColor(srgbRed: 91 / 255, green: 176 / 255, blue: 248 / 255, alpha: 0.36)),
        latestCore: Color(nsColor: NSColor(srgbRed: 252 / 255, green: 254 / 255, blue: 255 / 255, alpha: 0.98)),
        latestRing: Color(nsColor: NSColor(srgbRed: 181 / 255, green: 226 / 255, blue: 255 / 255, alpha: 0.96)),
        latestGlow: Color(nsColor: NSColor(srgbRed: 86 / 255, green: 173 / 255, blue: 245 / 255, alpha: 0.28)),
        peakLabelDark: PeakLabelSurface(
            top: Color(nsColor: NSColor(srgbRed: 51 / 255, green: 60 / 255, blue: 74 / 255, alpha: 0.96)),
            bottom: Color(nsColor: NSColor(srgbRed: 32 / 255, green: 40 / 255, blue: 54 / 255, alpha: 0.97)),
            stroke: Color(nsColor: NSColor(srgbRed: 129 / 255, green: 193 / 255, blue: 248 / 255, alpha: 0.26)),
            text: TokenFloatingCardTheme.primaryText),
        peakLabelLight: PeakLabelSurface(
            top: Color(nsColor: NSColor(srgbRed: 246 / 255, green: 249 / 255, blue: 253 / 255, alpha: 0.98)),
            bottom: Color(nsColor: NSColor(srgbRed: 232 / 255, green: 239 / 255, blue: 248 / 255, alpha: 0.98)),
            stroke: Color(nsColor: NSColor(srgbRed: 164 / 255, green: 204 / 255, blue: 242 / 255, alpha: 0.84)),
            text: TokenFloatingCardTheme.primaryText),
        axis: TokenFloatingCardTheme.chartAxis.opacity(0.76),
        boundaryAxis: Color(nsColor: NSColor(srgbRed: 69 / 255, green: 144 / 255, blue: 232 / 255, alpha: 0.92)),
        compressedAxis: Color(nsColor: NSColor(srgbRed: 78 / 255, green: 159 / 255, blue: 241 / 255, alpha: 0.86)),
        grid: TokenFloatingCardTheme.chartGrid)

    static let paletteDark = RibbonPalette(
        cardAccent: TokenRecentHistoryTheme.cardAccent,
        areaFill: Color(nsColor: NSColor(srgbRed: 90 / 255, green: 183 / 255, blue: 255 / 255, alpha: 0.24)),
        glowStart: Color(nsColor: NSColor(srgbRed: 89 / 255, green: 192 / 255, blue: 255 / 255, alpha: 0.20)),
        glowMid: Color(nsColor: NSColor(srgbRed: 64 / 255, green: 175 / 255, blue: 255 / 255, alpha: 0.38)),
        glowEnd: Color(nsColor: NSColor(srgbRed: 131 / 255, green: 226 / 255, blue: 255 / 255, alpha: 0.22)),
        outlineStart: Color(nsColor: NSColor(srgbRed: 86 / 255, green: 195 / 255, blue: 255 / 255, alpha: 0.98)),
        outlineMid: Color(nsColor: NSColor(srgbRed: 118 / 255, green: 223 / 255, blue: 255 / 255, alpha: 0.96)),
        outlineEnd: Color(nsColor: NSColor(srgbRed: 172 / 255, green: 242 / 255, blue: 255 / 255, alpha: 0.94)),
        outlineSheen: Color(nsColor: NSColor(srgbRed: 243 / 255, green: 251 / 255, blue: 255 / 255, alpha: 0.80)),
        peakPoint: Color(nsColor: NSColor(srgbRed: 246 / 255, green: 252 / 255, blue: 255 / 255, alpha: 0.98)),
        peakGlow: Color(nsColor: NSColor(srgbRed: 95 / 255, green: 195 / 255, blue: 255 / 255, alpha: 0.42)),
        latestCore: Color(nsColor: NSColor(srgbRed: 245 / 255, green: 252 / 255, blue: 255 / 255, alpha: 0.99)),
        latestRing: Color(nsColor: NSColor(srgbRed: 116 / 255, green: 218 / 255, blue: 255 / 255, alpha: 0.96)),
        latestGlow: Color(nsColor: NSColor(srgbRed: 83 / 255, green: 191 / 255, blue: 255 / 255, alpha: 0.32)),
        peakLabelDark: PeakLabelSurface(
            top: Color(nsColor: NSColor(srgbRed: 32 / 255, green: 48 / 255, blue: 68 / 255, alpha: 0.96)),
            bottom: Color(nsColor: NSColor(srgbRed: 18 / 255, green: 29 / 255, blue: 44 / 255, alpha: 0.97)),
            stroke: Color(nsColor: NSColor(srgbRed: 102 / 255, green: 200 / 255, blue: 255 / 255, alpha: 0.40)),
            text: TokenFloatingCardTheme.primaryText),
        peakLabelLight: PeakLabelSurface(
            top: Color(nsColor: NSColor(srgbRed: 244 / 255, green: 248 / 255, blue: 253 / 255, alpha: 0.98)),
            bottom: Color(nsColor: NSColor(srgbRed: 228 / 255, green: 236 / 255, blue: 246 / 255, alpha: 0.98)),
            stroke: Color(nsColor: NSColor(srgbRed: 155 / 255, green: 200 / 255, blue: 244 / 255, alpha: 0.82)),
            text: TokenFloatingCardTheme.primaryText),
        axis: TokenFloatingCardTheme.chartAxis.opacity(0.60),
        boundaryAxis: Color(nsColor: NSColor(srgbRed: 127 / 255, green: 214 / 255, blue: 255 / 255, alpha: 0.95)),
        compressedAxis: Color(nsColor: NSColor(srgbRed: 95 / 255, green: 195 / 255, blue: 255 / 255, alpha: 0.88)),
        grid: TokenFloatingCardTheme.chartGrid.opacity(0.86))

    static func palette(for isDarkMode: Bool) -> RibbonPalette {
        isDarkMode ? self.paletteDark : self.paletteLight
    }

    static var cardAccent: Color {
        TokenRecentHistoryTheme.dynamicColor(
            dark: NSColor(srgbRed: 96 / 255, green: 182 / 255, blue: 246 / 255, alpha: 0.76),
            light: NSColor(srgbRed: 93 / 255, green: 166 / 255, blue: 241 / 255, alpha: 0.84))
    }

    static var accent: Color {
        self.cardAccent
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

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
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
            1.0
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

struct TokenFloatingInsetBackground: View {
    let cornerRadius: CGFloat
    let tint: Color

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
    }

    var body: some View {
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
                    .offset(x: 0, y: 1.0)
                    .mask(self.shape)
            }
            .shadow(color: self.tint.opacity(0.10), radius: 10, x: 0, y: 4)
    }
}
