import AppKit
import SwiftUI

enum MenuVisualTheme: String, CaseIterable, Codable, Sendable, Identifiable {
    case liquidGlassClassic
    case pureLiquidGlass
    case pixelGame
    case pixelArcade
    case insCream
    case handbookCollage
    case diaryPaper
    case retroCopper
    case cyberNeon
    case sakura
    case literaryFresh
    case minimalBlackWhite
    case midnightBlue
    case forestMatcha
    case citrusSunset
    case seaSaltMint
    case purpleMist
    case amberFilm
    case nordicCoolGray
    case industrialUtility
    case frenchCafe

    var id: String {
        self.rawValue
    }
}

struct MenuVisualAccentPalette: Sendable {
    let start: NSColor
    let end: NSColor
    let glow: NSColor
}

enum MenuVisualChromeStyle: Sendable {
    case glass
    case pixel
}

struct MenuVisualThemeTokens: Sendable {
    let chromeStyle: MenuVisualChromeStyle
    let primaryText: NSColor
    let secondaryText: NSColor
    let tertiaryText: NSColor
    let warningText: NSColor

    let primaryQuotaTint: NSColor
    let secondaryQuotaTint: NSColor
    let reviewTint: NSColor
    let creditsTint: NSColor
    let analyticsTint: NSColor
    let recentHistoryTint: NSColor

    let chartGrid: NSColor
    let chartAxis: NSColor

    let glassStroke: NSColor
    let glassHighlight: NSColor
    let panelShadow: NSColor
    let panelBase: NSColor
    let panelGlowTop: NSColor
    let panelGlowTrailing: NSColor
    let panelGlassTint: NSColor

    let tooltipSurfaceTop: NSColor
    let tooltipSurfaceBottom: NSColor
    let tooltipStroke: NSColor
    let tooltipInnerHighlight: NSColor
    let tooltipShadow: NSColor
    let tooltipGlow: NSColor
    let tooltipPrimaryText: NSColor
    let tooltipSecondaryText: NSColor
    let tooltipTertiaryText: NSColor

    let floatingPrimaryText: NSColor
    let floatingCardTop: NSColor
    let floatingCardBottom: NSColor
    let floatingInsetTop: NSColor
    let floatingInsetBottom: NSColor
    let floatingStroke: NSColor
    let floatingHighlight: NSColor
    let floatingSecondaryText: NSColor
    let floatingTertiaryText: NSColor
    let floatingTrack: NSColor
    let floatingTrackStroke: NSColor
    let floatingPlotFill: NSColor
    let floatingPlotStroke: NSColor
    let floatingChartGrid: NSColor
    let floatingChartAxis: NSColor
    let floatingSelectionBand: NSColor
    let floatingInnerShadow: NSColor
    let floatingOuterShadow: NSColor

    let inputAccent: MenuVisualAccentPalette
    let outputAccent: MenuVisualAccentPalette
}

enum MenuVisualThemeProvider {
    private nonisolated(unsafe) static var currentThemeStorage: MenuVisualTheme = .liquidGlassClassic

    static var currentTheme: MenuVisualTheme {
        get { self.currentThemeStorage }
        set { self.currentThemeStorage = newValue }
    }

    static var tokens: MenuVisualThemeTokens {
        self.currentTheme.tokens
    }
}

private struct MenuVisualThemeSeed {
    let chromeStyle: MenuVisualChromeStyle
    let panelBase: NSColor
    let panelGlowTop: NSColor
    let panelGlowTrailing: NSColor
    let cardTop: NSColor
    let cardBottom: NSColor
    let insetTop: NSColor
    let insetBottom: NSColor
    let textPrimary: NSColor
    let textSecondary: NSColor
    let textTertiary: NSColor
    let border: NSColor
    let highlight: NSColor
    let shadow: NSColor
    let track: NSColor
    let plotFill: NSColor
    let chartGrid: NSColor
    let chartAxis: NSColor
    let primaryQuota: NSColor
    let secondaryQuota: NSColor
    let review: NSColor
    let credits: NSColor
    let analytics: NSColor
    let warning: NSColor
    let panelTint: NSColor
    let recentHistory: NSColor
    let inputAccent: MenuVisualAccentPalette
    let outputAccent: MenuVisualAccentPalette
    let tooltipTop: NSColor
    let tooltipBottom: NSColor
}

private extension MenuVisualTheme {
    var tokens: MenuVisualThemeTokens {
        MenuVisualThemePaletteBuilder.tokens(for: self)
    }
}

private enum MenuVisualThemePaletteBuilder {
    static func tokens(for theme: MenuVisualTheme) -> MenuVisualThemeTokens {
        let seed = self.seed(for: theme)

        return MenuVisualThemeTokens(
            chromeStyle: seed.chromeStyle,
            primaryText: seed.textPrimary,
            secondaryText: seed.textSecondary,
            tertiaryText: seed.textTertiary,
            warningText: seed.warning,
            primaryQuotaTint: seed.primaryQuota,
            secondaryQuotaTint: seed.secondaryQuota,
            reviewTint: seed.review,
            creditsTint: seed.credits,
            analyticsTint: seed.analytics,
            recentHistoryTint: seed.recentHistory,
            chartGrid: seed.chartGrid,
            chartAxis: seed.chartAxis,
            glassStroke: seed.border.withAlphaComponent(0.92),
            glassHighlight: seed.highlight,
            panelShadow: seed.shadow.withAlphaComponent(0.18),
            panelBase: seed.panelBase,
            panelGlowTop: seed.panelGlowTop,
            panelGlowTrailing: seed.panelGlowTrailing,
            panelGlassTint: seed.panelTint,
            tooltipSurfaceTop: seed.tooltipTop,
            tooltipSurfaceBottom: seed.tooltipBottom,
            tooltipStroke: seed.border.lightened(0.08).withAlphaComponent(0.92),
            tooltipInnerHighlight: seed.highlight.withAlphaComponent(0.84),
            tooltipShadow: seed.shadow.withAlphaComponent(0.22),
            tooltipGlow: seed.analytics.withAlphaComponent(0.26),
            tooltipPrimaryText: seed.textPrimary,
            tooltipSecondaryText: seed.textSecondary,
            tooltipTertiaryText: seed.textTertiary,
            floatingPrimaryText: seed.textPrimary,
            floatingCardTop: seed.cardTop,
            floatingCardBottom: seed.cardBottom,
            floatingInsetTop: seed.insetTop,
            floatingInsetBottom: seed.insetBottom,
            floatingStroke: seed.border.withAlphaComponent(0.84),
            floatingHighlight: seed.highlight,
            floatingSecondaryText: seed.textSecondary,
            floatingTertiaryText: seed.textTertiary,
            floatingTrack: seed.track,
            floatingTrackStroke: seed.highlight.withAlphaComponent(0.76),
            floatingPlotFill: seed.plotFill,
            floatingPlotStroke: seed.border.withAlphaComponent(0.32),
            floatingChartGrid: seed.chartGrid,
            floatingChartAxis: seed.chartAxis,
            floatingSelectionBand: seed.analytics.withAlphaComponent(0.12),
            floatingInnerShadow: seed.shadow.withAlphaComponent(0.14),
            floatingOuterShadow: seed.shadow.withAlphaComponent(0.18),
            inputAccent: seed.inputAccent,
            outputAccent: seed.outputAccent)
    }

    private static func seed(for theme: MenuVisualTheme) -> MenuVisualThemeSeed {
        switch theme {
        case .liquidGlassClassic:
            self.makeSeed(
                panelBase: .hex(0xF4F6FA),
                panelGlowTop: .hex(0xFFC38A, alpha: 0.28),
                panelGlowTrailing: .hex(0x8FB7FF, alpha: 0.22),
                cardTop: .hex(0xFDFCF8),
                cardBottom: .hex(0xF6F8FD),
                textPrimary: .hex(0x2A3140),
                textSecondary: .hex(0x4D5A6F, alpha: 0.72),
                textTertiary: .hex(0x6F7A8F, alpha: 0.58),
                border: .hex(0xB8C6D8, alpha: 0.34),
                highlight: .hex(0xFFFFFF, alpha: 0.86),
                shadow: .hex(0x2E3440, alpha: 0.18),
                track: .hex(0xE2E6ED, alpha: 0.92),
                plotFill: .hex(0xEEF2F8, alpha: 0.92),
                chartGrid: .hex(0xB0B8C9, alpha: 0.24),
                chartAxis: .hex(0x6E7A92, alpha: 0.78),
                primaryQuota: .hex(0xFF7A2F),
                secondaryQuota: .hex(0xFFA454),
                review: .hex(0xFCA94B),
                credits: .hex(0x5FDED6),
                analytics: .hex(0x7E99FF),
                warning: .hex(0xF28A2E),
                panelTint: .hex(0xFFAA78, alpha: 0.82),
                recentHistory: .hex(0x62A9F1),
                inputAccent: NSColor.accent(start: 0x4A90F5, end: 0x7DC6FF, glow: 0x7BC6FF),
                outputAccent: NSColor.accent(start: 0x42C46C, end: 0x8FE38A, glow: 0x6FD587))
        case .pureLiquidGlass:
            self.makeSeed(
                panelBase: .hex(0xF8FBFF),
                panelGlowTop: .hex(0xD3F2FF, alpha: 0.26),
                panelGlowTrailing: .hex(0xE8F0FF, alpha: 0.24),
                cardTop: .hex(0xFEFFFF),
                cardBottom: .hex(0xF1F8FF),
                textPrimary: .hex(0x243143),
                textSecondary: .hex(0x50627A, alpha: 0.72),
                textTertiary: .hex(0x7A8799, alpha: 0.56),
                border: .hex(0xB6D6EA, alpha: 0.32),
                highlight: .hex(0xFFFFFF, alpha: 0.92),
                shadow: .hex(0x345067, alpha: 0.16),
                track: .hex(0xE5EEF5, alpha: 0.92),
                plotFill: .hex(0xEDF7FF, alpha: 0.92),
                chartGrid: .hex(0xB8D1E0, alpha: 0.24),
                chartAxis: .hex(0x6A8098, alpha: 0.76),
                primaryQuota: .hex(0x4FB0FF),
                secondaryQuota: .hex(0x93D4FF),
                review: .hex(0x8BCBFF),
                credits: .hex(0x73E6E6),
                analytics: .hex(0x7FA8FF),
                warning: .hex(0x7ABEFF),
                panelTint: .hex(0xC5EEFF, alpha: 0.74),
                recentHistory: .hex(0x69B4F8),
                inputAccent: NSColor.accent(start: 0x5AA9FF, end: 0xA7E4FF, glow: 0x90DFFF),
                outputAccent: NSColor.accent(start: 0x63D8D0, end: 0xB8F4E5, glow: 0x8CE8D8))
        case .pixelGame:
            self.makeSeed(
                panelBase: .hex(0x141A25),
                panelGlowTop: .hex(0x1E874B, alpha: 0.24),
                panelGlowTrailing: .hex(0x3D5AFE, alpha: 0.26),
                cardTop: .hex(0x1A2230),
                cardBottom: .hex(0x121925),
                textPrimary: .hex(0xE9F1FF),
                textSecondary: .hex(0xB8D0FF, alpha: 0.76),
                textTertiary: .hex(0x8EA6C8, alpha: 0.62),
                border: .hex(0x5E7AA5, alpha: 0.42),
                highlight: .hex(0xE8FFF1, alpha: 0.34),
                shadow: .hex(0x05070D, alpha: 0.30),
                track: .hex(0x283347, alpha: 0.92),
                plotFill: .hex(0x182230, alpha: 0.88),
                chartGrid: .hex(0x44617F, alpha: 0.26),
                chartAxis: .hex(0x9AC2EA, alpha: 0.82),
                primaryQuota: .hex(0xFFB300),
                secondaryQuota: .hex(0xFF7A00),
                review: .hex(0xFFD54F),
                credits: .hex(0x57F287),
                analytics: .hex(0x6EA8FF),
                warning: .hex(0xFFB300),
                panelTint: .hex(0x4DE39A, alpha: 0.48),
                recentHistory: .hex(0x7AC6FF),
                inputAccent: NSColor.accent(start: 0x64B5F6, end: 0x90CAF9, glow: 0x6EC6FF),
                outputAccent: NSColor.accent(start: 0x66BB6A, end: 0xA5D66D, glow: 0x7EEF95))
        case .pixelArcade:
            self.makeSeed(
                chromeStyle: .pixel,
                panelBase: .hex(0xF4E3BE),
                panelGlowTop: .hex(0xFFECC8, alpha: 0.18),
                panelGlowTrailing: .hex(0x18233A, alpha: 0.10),
                cardTop: .hex(0xFFF6E2),
                cardBottom: .hex(0xF5E2BD),
                textPrimary: .hex(0x1D2337),
                textSecondary: .hex(0x394057, alpha: 0.84),
                textTertiary: .hex(0x666C7F, alpha: 0.72),
                border: .hex(0x1A2032, alpha: 0.98),
                highlight: .hex(0xFFFBEF, alpha: 0.96),
                shadow: .hex(0x2E344C, alpha: 0.34),
                track: .hex(0xE2D0AE, alpha: 0.98),
                plotFill: .hex(0xFFF8E9, alpha: 0.98),
                chartGrid: .hex(0xD4C099, alpha: 0.42),
                chartAxis: .hex(0x2A3148, alpha: 0.92),
                primaryQuota: .hex(0xF45D36),
                secondaryQuota: .hex(0x2E83F7),
                review: .hex(0xF4B000),
                credits: .hex(0x38C172),
                analytics: .hex(0x3D7CFF),
                warning: .hex(0xE95B2B),
                panelTint: .hex(0xF9D16A, alpha: 0.44),
                recentHistory: .hex(0x4390FF),
                inputAccent: NSColor.accent(start: 0x2F82F8, end: 0x59B3FF, glow: 0x7BCBFF),
                outputAccent: NSColor.accent(start: 0x3ABF71, end: 0x6CDB93, glow: 0x8AE7AE))
        case .insCream:
            self.makeSeed(
                panelBase: .hex(0xFFF8F1),
                panelGlowTop: .hex(0xFFD7C2, alpha: 0.24),
                panelGlowTrailing: .hex(0xF8E9D6, alpha: 0.24),
                cardTop: .hex(0xFFFCF8),
                cardBottom: .hex(0xFFF4EA),
                textPrimary: .hex(0x4A403A),
                textSecondary: .hex(0x7C6D64, alpha: 0.74),
                textTertiary: .hex(0xA39389, alpha: 0.58),
                border: .hex(0xE4D0C0, alpha: 0.34),
                highlight: .hex(0xFFFFFF, alpha: 0.82),
                shadow: .hex(0x8B6F64, alpha: 0.12),
                track: .hex(0xF0E2D8, alpha: 0.94),
                plotFill: .hex(0xFFF7F1, alpha: 0.92),
                chartGrid: .hex(0xD7C5B5, alpha: 0.22),
                chartAxis: .hex(0x88796E, alpha: 0.74),
                primaryQuota: .hex(0xFF9868),
                secondaryQuota: .hex(0xFFB287),
                review: .hex(0xFFBE7C),
                credits: .hex(0x8FD7C2),
                analytics: .hex(0x8BB5FF),
                warning: .hex(0xFF9868),
                panelTint: .hex(0xFFD8C0, alpha: 0.62),
                recentHistory: .hex(0x8FB5FF),
                inputAccent: NSColor.accent(start: 0x7AB8FF, end: 0xBAD8FF, glow: 0x9AC8FF),
                outputAccent: NSColor.accent(start: 0x7BCFB0, end: 0xBEEAD7, glow: 0x9EE0C8))
        case .handbookCollage:
            self.makeSeed(
                panelBase: .hex(0xF6EBDC),
                panelGlowTop: .hex(0xF4C693, alpha: 0.20),
                panelGlowTrailing: .hex(0xC7E0D3, alpha: 0.22),
                cardTop: .hex(0xFFF8ED),
                cardBottom: .hex(0xF8EFDF),
                textPrimary: .hex(0x4C4138),
                textSecondary: .hex(0x6D645B, alpha: 0.74),
                textTertiary: .hex(0x958A80, alpha: 0.58),
                border: .hex(0xD3BFAB, alpha: 0.38),
                highlight: .hex(0xFFF6E6, alpha: 0.68),
                shadow: .hex(0x826B58, alpha: 0.16),
                track: .hex(0xE9DBC8, alpha: 0.92),
                plotFill: .hex(0xF7EEDB, alpha: 0.90),
                chartGrid: .hex(0xC4B39D, alpha: 0.22),
                chartAxis: .hex(0x796B61, alpha: 0.78),
                primaryQuota: .hex(0xD98841),
                secondaryQuota: .hex(0xE0B35E),
                review: .hex(0xD8A76A),
                credits: .hex(0x7FB998),
                analytics: .hex(0x7696D8),
                warning: .hex(0xD98841),
                panelTint: .hex(0xD7A573, alpha: 0.52),
                recentHistory: .hex(0x7DA0E0),
                inputAccent: NSColor.accent(start: 0x7EA6E6, end: 0xAFC7F0, glow: 0x8FB6EA),
                outputAccent: NSColor.accent(start: 0x78B58A, end: 0xAFD2B7, glow: 0x90C8A1))
        case .diaryPaper:
            self.makeSeed(
                panelBase: .hex(0xFAF7F0),
                panelGlowTop: .hex(0xF3D7BA, alpha: 0.20),
                panelGlowTrailing: .hex(0xD5E4F8, alpha: 0.18),
                cardTop: .hex(0xFFFDF7),
                cardBottom: .hex(0xF7F1E8),
                textPrimary: .hex(0x3E3A34),
                textSecondary: .hex(0x6D675F, alpha: 0.72),
                textTertiary: .hex(0x938A80, alpha: 0.56),
                border: .hex(0xDDD2C4, alpha: 0.34),
                highlight: .hex(0xFFFDF8, alpha: 0.74),
                shadow: .hex(0x7A7065, alpha: 0.12),
                track: .hex(0xECE4D8, alpha: 0.92),
                plotFill: .hex(0xFBF6EC, alpha: 0.90),
                chartGrid: .hex(0xCFC6B7, alpha: 0.20),
                chartAxis: .hex(0x7C7265, alpha: 0.74),
                primaryQuota: .hex(0xA77B4D),
                secondaryQuota: .hex(0xC5A37D),
                review: .hex(0xC08E61),
                credits: .hex(0x88B7A2),
                analytics: .hex(0x8AA8D8),
                warning: .hex(0xA77B4D),
                panelTint: .hex(0xE2C7A8, alpha: 0.46),
                recentHistory: .hex(0x89AADD),
                inputAccent: NSColor.accent(start: 0x8EA9D9, end: 0xBDD0EF, glow: 0x9FBBE5),
                outputAccent: NSColor.accent(start: 0x8DB8A3, end: 0xBDDCC9, glow: 0xA5CBB7))
        case .retroCopper:
            self.makeSeed(
                panelBase: .hex(0x2C211D),
                panelGlowTop: .hex(0xC97A42, alpha: 0.20),
                panelGlowTrailing: .hex(0x8A5A44, alpha: 0.18),
                cardTop: .hex(0x3A2B25),
                cardBottom: .hex(0x241A16),
                textPrimary: .hex(0xF3E6D8),
                textSecondary: .hex(0xD7BDA6, alpha: 0.76),
                textTertiary: .hex(0xA88F7B, alpha: 0.62),
                border: .hex(0x8D6550, alpha: 0.44),
                highlight: .hex(0xFFD4B2, alpha: 0.22),
                shadow: .hex(0x0C0908, alpha: 0.30),
                track: .hex(0x46322A, alpha: 0.92),
                plotFill: .hex(0x31231E, alpha: 0.90),
                chartGrid: .hex(0x6C4E40, alpha: 0.26),
                chartAxis: .hex(0xD0B59D, alpha: 0.78),
                primaryQuota: .hex(0xE38A4F),
                secondaryQuota: .hex(0xC77A44),
                review: .hex(0xD49A53),
                credits: .hex(0x6CB7A7),
                analytics: .hex(0x7DA0D8),
                warning: .hex(0xE38A4F),
                panelTint: .hex(0xC77A44, alpha: 0.52),
                recentHistory: .hex(0x7EA8E5),
                inputAccent: NSColor.accent(start: 0x79A3E2, end: 0xA7C6F2, glow: 0x87B4EC),
                outputAccent: NSColor.accent(start: 0x57AA95, end: 0x9BD1C3, glow: 0x73BFAE))
        case .cyberNeon:
            self.makeSeed(
                panelBase: .hex(0x0C0F1D),
                panelGlowTop: .hex(0x00E5FF, alpha: 0.20),
                panelGlowTrailing: .hex(0xFF2FD8, alpha: 0.16),
                cardTop: .hex(0x12172B),
                cardBottom: .hex(0x0A0F1D),
                textPrimary: .hex(0xF2FAFF),
                textSecondary: .hex(0xA8C9FF, alpha: 0.78),
                textTertiary: .hex(0x7C92C9, alpha: 0.66),
                border: .hex(0x4B5D92, alpha: 0.42),
                highlight: .hex(0xD5F7FF, alpha: 0.26),
                shadow: .hex(0x02040B, alpha: 0.32),
                track: .hex(0x1D2540, alpha: 0.92),
                plotFill: .hex(0x131A32, alpha: 0.90),
                chartGrid: .hex(0x33507A, alpha: 0.30),
                chartAxis: .hex(0xB4E1FF, alpha: 0.82),
                primaryQuota: .hex(0xFF8A00),
                secondaryQuota: .hex(0xFF4FD8),
                review: .hex(0xFFB400),
                credits: .hex(0x22F5C6),
                analytics: .hex(0x5AB0FF),
                warning: .hex(0xFF8A00),
                panelTint: .hex(0x00E5FF, alpha: 0.44),
                recentHistory: .hex(0x49B6FF),
                inputAccent: NSColor.accent(start: 0x00D6FF, end: 0x6CA8FF, glow: 0x00F0FF),
                outputAccent: NSColor.accent(start: 0x00FFB2, end: 0x7EF8D2, glow: 0x00FFC2))
        case .sakura:
            self.makeSeed(
                panelBase: .hex(0xFFF5F8),
                panelGlowTop: .hex(0xFFC5D7, alpha: 0.24),
                panelGlowTrailing: .hex(0xF6DFF8, alpha: 0.22),
                cardTop: .hex(0xFFFDFE),
                cardBottom: .hex(0xFFF0F5),
                textPrimary: .hex(0x4F3C46),
                textSecondary: .hex(0x7C6670, alpha: 0.74),
                textTertiary: .hex(0xA28792, alpha: 0.58),
                border: .hex(0xE2C8D4, alpha: 0.34),
                highlight: .hex(0xFFFFFF, alpha: 0.82),
                shadow: .hex(0x8A6677, alpha: 0.12),
                track: .hex(0xF2E2EA, alpha: 0.92),
                plotFill: .hex(0xFFF5F7, alpha: 0.90),
                chartGrid: .hex(0xDDBFCB, alpha: 0.22),
                chartAxis: .hex(0x8D7480, alpha: 0.74),
                primaryQuota: .hex(0xFF8EB0),
                secondaryQuota: .hex(0xFFB7C9),
                review: .hex(0xFFB293),
                credits: .hex(0x92DCC8),
                analytics: .hex(0xA3A2FF),
                warning: .hex(0xFF8EB0),
                panelTint: .hex(0xFFD7E4, alpha: 0.62),
                recentHistory: .hex(0xA7B3FF),
                inputAccent: NSColor.accent(start: 0x88B2FF, end: 0xD5D9FF, glow: 0xABC6FF),
                outputAccent: NSColor.accent(start: 0x88D7B8, end: 0xC8F2E3, glow: 0xA6E4CC))
        case .literaryFresh:
            self.makeSeed(
                panelBase: .hex(0xF6FBF5),
                panelGlowTop: .hex(0xC7E6C8, alpha: 0.24),
                panelGlowTrailing: .hex(0xE6F2E4, alpha: 0.20),
                cardTop: .hex(0xFEFFFC),
                cardBottom: .hex(0xF0F8EE),
                textPrimary: .hex(0x314239),
                textSecondary: .hex(0x577162, alpha: 0.74),
                textTertiary: .hex(0x7D9386, alpha: 0.58),
                border: .hex(0xC7D8CB, alpha: 0.34),
                highlight: .hex(0xFFFFFF, alpha: 0.82),
                shadow: .hex(0x53655A, alpha: 0.10),
                track: .hex(0xE1ECE0, alpha: 0.92),
                plotFill: .hex(0xF5FBF4, alpha: 0.90),
                chartGrid: .hex(0xB7CCBC, alpha: 0.22),
                chartAxis: .hex(0x6B8174, alpha: 0.74),
                primaryQuota: .hex(0x6AB06E),
                secondaryQuota: .hex(0x98C589),
                review: .hex(0xD7A763),
                credits: .hex(0x65C8B0),
                analytics: .hex(0x7EA7D5),
                warning: .hex(0x6AB06E),
                panelTint: .hex(0xB5D7B9, alpha: 0.52),
                recentHistory: .hex(0x83B3E0),
                inputAccent: NSColor.accent(start: 0x79AEE0, end: 0xB9D3EE, glow: 0x93BFE8),
                outputAccent: NSColor.accent(start: 0x63C0A2, end: 0xAEE1CF, glow: 0x82D1BB))
        case .minimalBlackWhite:
            self.makeSeed(
                panelBase: .hex(0xF2F2F2),
                panelGlowTop: .hex(0xDADADA, alpha: 0.18),
                panelGlowTrailing: .hex(0xC6C6C6, alpha: 0.16),
                cardTop: .hex(0xFFFFFF),
                cardBottom: .hex(0xECECEC),
                textPrimary: .hex(0x1F1F1F),
                textSecondary: .hex(0x505050, alpha: 0.74),
                textTertiary: .hex(0x7D7D7D, alpha: 0.58),
                border: .hex(0xBEBEBE, alpha: 0.34),
                highlight: .hex(0xFFFFFF, alpha: 0.78),
                shadow: .hex(0x141414, alpha: 0.12),
                track: .hex(0xDBDBDB, alpha: 0.92),
                plotFill: .hex(0xF1F1F1, alpha: 0.90),
                chartGrid: .hex(0xC8C8C8, alpha: 0.22),
                chartAxis: .hex(0x5A5A5A, alpha: 0.74),
                primaryQuota: .hex(0x242424),
                secondaryQuota: .hex(0x5E5E5E),
                review: .hex(0x474747),
                credits: .hex(0x727272),
                analytics: .hex(0x3B3B3B),
                warning: .hex(0x242424),
                panelTint: .hex(0xC8C8C8, alpha: 0.42),
                recentHistory: .hex(0x4B4B4B),
                inputAccent: NSColor.accent(start: 0x2E2E2E, end: 0x7A7A7A, glow: 0x4F4F4F),
                outputAccent: NSColor.accent(start: 0x5E5E5E, end: 0xA6A6A6, glow: 0x7A7A7A))
        case .midnightBlue:
            self.makeSeed(
                panelBase: .hex(0x0F1B33),
                panelGlowTop: .hex(0x204A7A, alpha: 0.20),
                panelGlowTrailing: .hex(0x19355A, alpha: 0.20),
                cardTop: .hex(0x172440),
                cardBottom: .hex(0x0E1830),
                textPrimary: .hex(0xEDF4FF),
                textSecondary: .hex(0xB6CAE5, alpha: 0.76),
                textTertiary: .hex(0x8799B5, alpha: 0.62),
                border: .hex(0x4A678F, alpha: 0.40),
                highlight: .hex(0xD7E8FF, alpha: 0.20),
                shadow: .hex(0x02060E, alpha: 0.32),
                track: .hex(0x1F2C49, alpha: 0.92),
                plotFill: .hex(0x16233C, alpha: 0.90),
                chartGrid: .hex(0x3C5E87, alpha: 0.24),
                chartAxis: .hex(0xB2CBE8, alpha: 0.80),
                primaryQuota: .hex(0x76A8FF),
                secondaryQuota: .hex(0x4D7BE8),
                review: .hex(0x9AC0FF),
                credits: .hex(0x5AD0D2),
                analytics: .hex(0x7B92FF),
                warning: .hex(0x76A8FF),
                panelTint: .hex(0x3769B0, alpha: 0.48),
                recentHistory: .hex(0x78B3FF),
                inputAccent: NSColor.accent(start: 0x4E8EFF, end: 0x84C3FF, glow: 0x6BA8FF),
                outputAccent: NSColor.accent(start: 0x44C3C9, end: 0x8DE3E5, glow: 0x67D7D9))
        case .forestMatcha:
            self.makeSeed(
                panelBase: .hex(0xEEF6EB),
                panelGlowTop: .hex(0xB5D69C, alpha: 0.24),
                panelGlowTrailing: .hex(0xD8E9C6, alpha: 0.18),
                cardTop: .hex(0xF9FDF4),
                cardBottom: .hex(0xEAF4DF),
                textPrimary: .hex(0x33432D),
                textSecondary: .hex(0x596E51, alpha: 0.74),
                textTertiary: .hex(0x809278, alpha: 0.58),
                border: .hex(0xC3D4B8, alpha: 0.34),
                highlight: .hex(0xFFFFFF, alpha: 0.78),
                shadow: .hex(0x52624A, alpha: 0.10),
                track: .hex(0xDEE8D4, alpha: 0.92),
                plotFill: .hex(0xF0F7E9, alpha: 0.90),
                chartGrid: .hex(0xB6C8A8, alpha: 0.22),
                chartAxis: .hex(0x687C61, alpha: 0.74),
                primaryQuota: .hex(0x6D9D3A),
                secondaryQuota: .hex(0x9ABE53),
                review: .hex(0xB3A04E),
                credits: .hex(0x68B98A),
                analytics: .hex(0x6F9AD1),
                warning: .hex(0x6D9D3A),
                panelTint: .hex(0xA7C26E, alpha: 0.50),
                recentHistory: .hex(0x75A6E1),
                inputAccent: NSColor.accent(start: 0x6C9BDE, end: 0xA6C4EE, glow: 0x84B0E8),
                outputAccent: NSColor.accent(start: 0x67B67D, end: 0xABD8B0, glow: 0x82CB93))
        case .citrusSunset:
            self.makeSeed(
                panelBase: .hex(0xFFF2E7),
                panelGlowTop: .hex(0xFFAE58, alpha: 0.24),
                panelGlowTrailing: .hex(0xFF7B6B, alpha: 0.20),
                cardTop: .hex(0xFFFDF8),
                cardBottom: .hex(0xFFF0E4),
                textPrimary: .hex(0x4B352E),
                textSecondary: .hex(0x7B5F55, alpha: 0.74),
                textTertiary: .hex(0xA08277, alpha: 0.58),
                border: .hex(0xE6C4AD, alpha: 0.34),
                highlight: .hex(0xFFF8F0, alpha: 0.76),
                shadow: .hex(0x8A6A58, alpha: 0.12),
                track: .hex(0xF1D9CB, alpha: 0.92),
                plotFill: .hex(0xFFF5ED, alpha: 0.90),
                chartGrid: .hex(0xD7B79F, alpha: 0.22),
                chartAxis: .hex(0x8B6C61, alpha: 0.74),
                primaryQuota: .hex(0xFF7A2F),
                secondaryQuota: .hex(0xFFA94D),
                review: .hex(0xFFB25F),
                credits: .hex(0x67D0A1),
                analytics: .hex(0x7BA5FF),
                warning: .hex(0xFF7A2F),
                panelTint: .hex(0xFFB066, alpha: 0.58),
                recentHistory: .hex(0x82B1FF),
                inputAccent: NSColor.accent(start: 0x6FA2FF, end: 0xAFCEFF, glow: 0x88B6FF),
                outputAccent: NSColor.accent(start: 0x63C890, end: 0x9DE7B9, glow: 0x7BDBA4))
        case .seaSaltMint:
            self.makeSeed(
                panelBase: .hex(0xF2FCFB),
                panelGlowTop: .hex(0x9EE7DE, alpha: 0.24),
                panelGlowTrailing: .hex(0xD8F5F2, alpha: 0.20),
                cardTop: .hex(0xFCFFFF),
                cardBottom: .hex(0xE9F8F6),
                textPrimary: .hex(0x244244),
                textSecondary: .hex(0x507174, alpha: 0.72),
                textTertiary: .hex(0x799295, alpha: 0.56),
                border: .hex(0xB6DCD8, alpha: 0.34),
                highlight: .hex(0xFFFFFF, alpha: 0.84),
                shadow: .hex(0x4A6B6F, alpha: 0.10),
                track: .hex(0xDCF0EE, alpha: 0.92),
                plotFill: .hex(0xEFFBFA, alpha: 0.90),
                chartGrid: .hex(0xB5D8D4, alpha: 0.22),
                chartAxis: .hex(0x618386, alpha: 0.74),
                primaryQuota: .hex(0x4DBEC3),
                secondaryQuota: .hex(0x7FDDE0),
                review: .hex(0x9BC8FF),
                credits: .hex(0x56DDAE),
                analytics: .hex(0x78AFFF),
                warning: .hex(0x4DBEC3),
                panelTint: .hex(0x9BE6DC, alpha: 0.52),
                recentHistory: .hex(0x7AB7FF),
                inputAccent: NSColor.accent(start: 0x78AFFF, end: 0xB4D9FF, glow: 0x8CC4FF),
                outputAccent: NSColor.accent(start: 0x55D7B7, end: 0xA8F0D9, glow: 0x76E3C7))
        case .purpleMist:
            self.makeSeed(
                panelBase: .hex(0xF8F3FF),
                panelGlowTop: .hex(0xD3C1FF, alpha: 0.24),
                panelGlowTrailing: .hex(0xEBDFFF, alpha: 0.22),
                cardTop: .hex(0xFEFCFF),
                cardBottom: .hex(0xF2EAFF),
                textPrimary: .hex(0x433C54),
                textSecondary: .hex(0x6D6585, alpha: 0.74),
                textTertiary: .hex(0x948BA9, alpha: 0.58),
                border: .hex(0xD3C7EB, alpha: 0.34),
                highlight: .hex(0xFFFFFF, alpha: 0.82),
                shadow: .hex(0x645A7A, alpha: 0.12),
                track: .hex(0xE8DFF7, alpha: 0.92),
                plotFill: .hex(0xF7F1FF, alpha: 0.90),
                chartGrid: .hex(0xCDBFE6, alpha: 0.22),
                chartAxis: .hex(0x7A718F, alpha: 0.74),
                primaryQuota: .hex(0xB28AFF),
                secondaryQuota: .hex(0xD0AEFF),
                review: .hex(0xFFB0CC),
                credits: .hex(0x7ADCB9),
                analytics: .hex(0x86A5FF),
                warning: .hex(0xB28AFF),
                panelTint: .hex(0xD7C3FF, alpha: 0.56),
                recentHistory: .hex(0x8FB2FF),
                inputAccent: NSColor.accent(start: 0x7FA0FF, end: 0xC7D3FF, glow: 0x9BB5FF),
                outputAccent: NSColor.accent(start: 0x73D1B2, end: 0xB9EED9, glow: 0x8BE0C3))
        case .amberFilm:
            self.makeSeed(
                panelBase: .hex(0x2C231A),
                panelGlowTop: .hex(0xD69134, alpha: 0.18),
                panelGlowTrailing: .hex(0x7B5835, alpha: 0.16),
                cardTop: .hex(0x372B20),
                cardBottom: .hex(0x221A13),
                textPrimary: .hex(0xF5E7D1),
                textSecondary: .hex(0xD7BF9F, alpha: 0.76),
                textTertiary: .hex(0xA99273, alpha: 0.62),
                border: .hex(0x8B6B4D, alpha: 0.42),
                highlight: .hex(0xFFD9AB, alpha: 0.18),
                shadow: .hex(0x090705, alpha: 0.32),
                track: .hex(0x473526, alpha: 0.92),
                plotFill: .hex(0x30241B, alpha: 0.90),
                chartGrid: .hex(0x6C543E, alpha: 0.26),
                chartAxis: .hex(0xD2B892, alpha: 0.80),
                primaryQuota: .hex(0xFFB04D),
                secondaryQuota: .hex(0xC98E40),
                review: .hex(0xE5B767),
                credits: .hex(0x6FB5A5),
                analytics: .hex(0x7CA6D8),
                warning: .hex(0xFFB04D),
                panelTint: .hex(0xC88E48, alpha: 0.54),
                recentHistory: .hex(0x84B2E6),
                inputAccent: NSColor.accent(start: 0x7EA8E3, end: 0xB5D0EE, glow: 0x94BEE9),
                outputAccent: NSColor.accent(start: 0x66B39D, end: 0xA8D9C7, glow: 0x82C6B4))
        case .nordicCoolGray:
            self.makeSeed(
                panelBase: .hex(0xF0F4F7),
                panelGlowTop: .hex(0xC9D5DD, alpha: 0.22),
                panelGlowTrailing: .hex(0xDEE6EE, alpha: 0.22),
                cardTop: .hex(0xFCFDFE),
                cardBottom: .hex(0xE8EEF3),
                textPrimary: .hex(0x31404B),
                textSecondary: .hex(0x60717D, alpha: 0.72),
                textTertiary: .hex(0x87949F, alpha: 0.58),
                border: .hex(0xC8D3DB, alpha: 0.34),
                highlight: .hex(0xFFFFFF, alpha: 0.84),
                shadow: .hex(0x51606B, alpha: 0.10),
                track: .hex(0xDEE5EB, alpha: 0.92),
                plotFill: .hex(0xF0F5F8, alpha: 0.90),
                chartGrid: .hex(0xC2CDD5, alpha: 0.22),
                chartAxis: .hex(0x6E7F8B, alpha: 0.74),
                primaryQuota: .hex(0x6A87A5),
                secondaryQuota: .hex(0x90A5BD),
                review: .hex(0x98B0C8),
                credits: .hex(0x79B9B0),
                analytics: .hex(0x7D97BE),
                warning: .hex(0x6A87A5),
                panelTint: .hex(0xC7D4DE, alpha: 0.50),
                recentHistory: .hex(0x86A5D2),
                inputAccent: NSColor.accent(start: 0x7C97BC, end: 0xB6C8DA, glow: 0x97AEC9),
                outputAccent: NSColor.accent(start: 0x76B5AE, end: 0xB2DDD7, glow: 0x8BCAC3))
        case .industrialUtility:
            self.makeSeed(
                panelBase: .hex(0x1A1D23),
                panelGlowTop: .hex(0xFF8A3D, alpha: 0.16),
                panelGlowTrailing: .hex(0x59626F, alpha: 0.18),
                cardTop: .hex(0x252A31),
                cardBottom: .hex(0x171A20),
                textPrimary: .hex(0xEDF1F5),
                textSecondary: .hex(0xC0C8D2, alpha: 0.76),
                textTertiary: .hex(0x8F99A5, alpha: 0.62),
                border: .hex(0x616975, alpha: 0.42),
                highlight: .hex(0xFFFFFF, alpha: 0.12),
                shadow: .hex(0x040507, alpha: 0.32),
                track: .hex(0x323840, alpha: 0.92),
                plotFill: .hex(0x242830, alpha: 0.90),
                chartGrid: .hex(0x56606C, alpha: 0.26),
                chartAxis: .hex(0xCED7E1, alpha: 0.78),
                primaryQuota: .hex(0xFF8A3D),
                secondaryQuota: .hex(0xFFB36F),
                review: .hex(0xFFC56D),
                credits: .hex(0x54C2AE),
                analytics: .hex(0x6A8DFF),
                warning: .hex(0xFF8A3D),
                panelTint: .hex(0xFF8A3D, alpha: 0.44),
                recentHistory: .hex(0x77A2FF),
                inputAccent: NSColor.accent(start: 0x6A93FF, end: 0xA9BEFF, glow: 0x88A8FF),
                outputAccent: NSColor.accent(start: 0x50C1AB, end: 0x9DE3D5, glow: 0x72D6C3))
        case .frenchCafe:
            self.makeSeed(
                panelBase: .hex(0xF7F0E8),
                panelGlowTop: .hex(0xCFA56B, alpha: 0.20),
                panelGlowTrailing: .hex(0xE6D4BD, alpha: 0.20),
                cardTop: .hex(0xFFFDF9),
                cardBottom: .hex(0xF2E7D9),
                textPrimary: .hex(0x4A3931),
                textSecondary: .hex(0x7A655A, alpha: 0.74),
                textTertiary: .hex(0xA08A7E, alpha: 0.58),
                border: .hex(0xD9C5B2, alpha: 0.34),
                highlight: .hex(0xFFFDF9, alpha: 0.80),
                shadow: .hex(0x7B665A, alpha: 0.10),
                track: .hex(0xE9DCCA, alpha: 0.92),
                plotFill: .hex(0xF8F1E6, alpha: 0.90),
                chartGrid: .hex(0xCCB9A6, alpha: 0.22),
                chartAxis: .hex(0x846F61, alpha: 0.74),
                primaryQuota: .hex(0x9E6D4D),
                secondaryQuota: .hex(0xC08D67),
                review: .hex(0xD7A36B),
                credits: .hex(0x7BB39D),
                analytics: .hex(0x7EA1D5),
                warning: .hex(0x9E6D4D),
                panelTint: .hex(0xCCA071, alpha: 0.50),
                recentHistory: .hex(0x85ABDE),
                inputAccent: NSColor.accent(start: 0x7EA3DB, end: 0xB3CBEA, glow: 0x93B7E2),
                outputAccent: NSColor.accent(start: 0x75B39C, end: 0xB3DCCF, glow: 0x8DC4B3))
        }
    }

    private static func makeSeed(
        chromeStyle: MenuVisualChromeStyle = .glass,
        panelBase: NSColor,
        panelGlowTop: NSColor,
        panelGlowTrailing: NSColor,
        cardTop: NSColor,
        cardBottom: NSColor,
        textPrimary: NSColor,
        textSecondary: NSColor,
        textTertiary: NSColor,
        border: NSColor,
        highlight: NSColor,
        shadow: NSColor,
        track: NSColor,
        plotFill: NSColor,
        chartGrid: NSColor,
        chartAxis: NSColor,
        primaryQuota: NSColor,
        secondaryQuota: NSColor,
        review: NSColor,
        credits: NSColor,
        analytics: NSColor,
        warning: NSColor,
        panelTint: NSColor,
        recentHistory: NSColor,
        inputAccent: MenuVisualAccentPalette,
        outputAccent: MenuVisualAccentPalette)
        -> MenuVisualThemeSeed
    {
        MenuVisualThemeSeed(
            chromeStyle: chromeStyle,
            panelBase: panelBase,
            panelGlowTop: panelGlowTop,
            panelGlowTrailing: panelGlowTrailing,
            cardTop: cardTop,
            cardBottom: cardBottom,
            insetTop: cardTop.lightened(0.04).withAlphaComponent(0.92),
            insetBottom: cardBottom.lightened(0.02).withAlphaComponent(0.80),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            textTertiary: textTertiary,
            border: border,
            highlight: highlight,
            shadow: shadow,
            track: track,
            plotFill: plotFill,
            chartGrid: chartGrid,
            chartAxis: chartAxis,
            primaryQuota: primaryQuota,
            secondaryQuota: secondaryQuota,
            review: review,
            credits: credits,
            analytics: analytics,
            warning: warning,
            panelTint: panelTint,
            recentHistory: recentHistory,
            inputAccent: inputAccent,
            outputAccent: outputAccent,
            tooltipTop: cardTop.lightened(0.08).withAlphaComponent(0.96),
            tooltipBottom: cardBottom.lightened(0.04).withAlphaComponent(0.94))
    }
}

extension NSColor {
    static func hex(_ hex: Int, alpha: CGFloat = 1) -> NSColor {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        return NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }

    static func accent(start: Int, end: Int, glow: Int) -> MenuVisualAccentPalette {
        MenuVisualAccentPalette(
            start: .hex(start),
            end: .hex(end),
            glow: .hex(glow))
    }

    func withAlphaComponent(_ alpha: CGFloat) -> NSColor {
        let color = self.usingColorSpace(.sRGB) ?? self
        return NSColor(
            srgbRed: color.redComponent,
            green: color.greenComponent,
            blue: color.blueComponent,
            alpha: alpha)
    }

    func mixed(with other: NSColor, fraction: CGFloat) -> NSColor {
        let lhs = self.usingColorSpace(.sRGB) ?? self
        let rhs = other.usingColorSpace(.sRGB) ?? other
        let clamped = max(0, min(1, fraction))
        let inverse = 1 - clamped
        return NSColor(
            srgbRed: (lhs.redComponent * inverse) + (rhs.redComponent * clamped),
            green: (lhs.greenComponent * inverse) + (rhs.greenComponent * clamped),
            blue: (lhs.blueComponent * inverse) + (rhs.blueComponent * clamped),
            alpha: (lhs.alphaComponent * inverse) + (rhs.alphaComponent * clamped))
    }

    func lightened(_ amount: CGFloat) -> NSColor {
        self.mixed(with: .white, fraction: max(0, min(1, amount)))
    }

    func darkened(_ amount: CGFloat) -> NSColor {
        self.mixed(with: .black, fraction: max(0, min(1, amount)))
    }
}
