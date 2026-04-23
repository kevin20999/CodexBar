import AppKit
import Observation
import SwiftUI

enum TokenMenuSpeedMeterLayout {
    static let statusItemWidth: CGFloat = 38
    static let statusItemHeight: CGFloat = 22
    static let bubbleHorizontalPadding: CGFloat = 12
    static let bubbleMinimumWidth: CGFloat = statusItemWidth - 6
}

final class TokenPassThroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}

@MainActor
@Observable
final class TokenMenuSpeedBubbleModel {
    var presentation: TokenMenuSpeedPresentationState = .idle
    var isPresented = false
}

@MainActor
@Observable
final class TokenMenuSpeedStatusItemModel {
    var presentation: TokenMenuSpeedPresentationState = .idle
}

private enum TokenMenuSpeedSurfaceStyle {
    case compact
    case bubble

    var strokeOpacity: Double {
        switch self {
        case .compact:
            0.14
        case .bubble:
            0.12
        }
    }

    var shadowOpacity: Double {
        switch self {
        case .compact:
            0.028
        case .bubble:
            0.024
        }
    }

    var shadowRadius: CGFloat {
        switch self {
        case .compact:
            1.4
        case .bubble:
            1.6
        }
    }

    var shadowYOffset: CGFloat {
        switch self {
        case .compact:
            0.6
        case .bubble:
            0.8
        }
    }
}

private enum TokenMenuSpeedSurfaceTheme {
    static let surfaceTop = Color.white
    static let surfaceBottom = Color(red: 0.995, green: 0.996, blue: 0.998)
    static let surfaceStroke = Color(red: 0.78, green: 0.80, blue: 0.85)
    static let symbol = Color(red: 0.25, green: 0.28, blue: 0.34)
    static let bubbleText = Color(red: 0.23, green: 0.26, blue: 0.31)
}

private struct TokenMenuSpeedSurfaceBackground<SurfaceShape: Shape>: View {
    let shape: SurfaceShape
    let style: TokenMenuSpeedSurfaceStyle

    private var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [
                TokenMenuSpeedSurfaceTheme.surfaceTop,
                TokenMenuSpeedSurfaceTheme.surfaceBottom,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
    }

    var body: some View {
        self.shape
            .fill(self.surfaceGradient)
            .overlay(
                self.shape
                    .stroke(
                        TokenMenuSpeedSurfaceTheme.surfaceStroke.opacity(self.style.strokeOpacity),
                        lineWidth: 0.55))
            .shadow(
                color: Color.black.opacity(self.style.shadowOpacity),
                radius: self.style.shadowRadius,
                x: 0,
                y: self.style.shadowYOffset)
    }
}

struct TokenMenuRocketMotion: Equatable {
    let yOffset: CGFloat
    let rotation: Double
    let scale: CGFloat

    static let zero = TokenMenuRocketMotion(
        yOffset: 0,
        rotation: 0,
        scale: 1)
}

enum TokenMenuSpeedStatusItemAnimation {
    static let launchRise: CGFloat = -5.2
    static let launchRotation: Double = -7
    static let launchScale: CGFloat = 1.08
    static let settleRise: CGFloat = -1.2
    static let launchUpDuration: TimeInterval = 0.12
    static let settleDuration: TimeInterval = 0.22

    static func launchMotion(strength: Double) -> TokenMenuRocketMotion {
        let normalizedStrength = CGFloat(max(0, min(1, strength)))
        return TokenMenuRocketMotion(
            yOffset: self.launchRise * normalizedStrength,
            rotation: self.launchRotation * Double(normalizedStrength),
            scale: 1 + ((self.launchScale - 1) * normalizedStrength))
    }

    static func settleMotion(strength: Double) -> TokenMenuRocketMotion {
        let normalizedStrength = CGFloat(max(0, min(1, strength)))
        return TokenMenuRocketMotion(
            yOffset: self.settleRise * normalizedStrength,
            rotation: 0,
            scale: 1)
    }
}

enum TokenMenuSpeedBubbleAnimation {
    static func capsuleYOffset(for presentation: TokenMenuSpeedPresentationState) -> CGFloat {
        switch presentation.phase {
        case .idle:
            0
        case .ignite:
            1
        case .thrust:
            2
        case .hold:
            0
        case .dismissing:
            -4
        }
    }

    static func capsuleScaleX(for presentation: TokenMenuSpeedPresentationState) -> CGFloat {
        switch presentation.phase {
        case .idle:
            0.72
        case .ignite:
            0.88
        case .thrust:
            1.02
        case .hold:
            1
        case .dismissing:
            0.84
        }
    }

    static func capsuleScaleY(for presentation: TokenMenuSpeedPresentationState) -> CGFloat {
        switch presentation.phase {
        case .idle:
            0.84
        case .ignite:
            0.92
        case .thrust:
            1.04
        case .hold:
            1
        case .dismissing:
            0.9
        }
    }

    static func capsuleOpacity(for presentation: TokenMenuSpeedPresentationState) -> Double {
        switch presentation.phase {
        case .idle:
            0
        case .ignite:
            0.82
        case .thrust, .hold:
            1
        case .dismissing:
            0
        }
    }

    static func textOpacity(for presentation: TokenMenuSpeedPresentationState) -> Double {
        switch presentation.phase {
        case .idle, .ignite:
            0
        case .thrust:
            0.92
        case .hold:
            1
        case .dismissing:
            0
        }
    }

    static func textYOffset(for presentation: TokenMenuSpeedPresentationState) -> CGFloat {
        switch presentation.phase {
        case .idle:
            4
        case .ignite:
            2
        case .thrust:
            0
        case .hold:
            0
        case .dismissing:
            -2
        }
    }

    static func animation(for presentation: TokenMenuSpeedPresentationState) -> Animation {
        switch presentation.phase {
        case .idle:
            .easeOut(duration: 0.16)
        case .ignite:
            .easeOut(duration: 0.14)
        case .thrust:
            .easeOut(duration: 0.32)
        case .hold:
            .spring(response: 0.26, dampingFraction: 0.86)
        case .dismissing:
            .easeInOut(duration: 0.42)
        }
    }

    static func panelAnimationDuration(for presentation: TokenMenuSpeedPresentationState) -> TimeInterval {
        switch presentation.phase {
        case .idle:
            0.16
        case .ignite:
            0.14
        case .thrust:
            0.32
        case .hold:
            0.18
        case .dismissing:
            0.42
        }
    }
}

enum TokenMenuSpeedBubbleLayout {
    static let compactWidth = TokenMenuSpeedMeterLayout.statusItemWidth - 6
    static let compactHeight = TokenMenuSpeedMeterLayout.statusItemHeight

    static func width(for presentation: TokenMenuSpeedPresentationState) -> CGFloat {
        let expandedWidth = self.expandedWidth(for: presentation.bubbleDisplayText)
        return switch presentation.phase {
        case .idle, .ignite:
            self.compactWidth
        case .thrust:
            self.compactWidth + ((expandedWidth - self.compactWidth) * 0.78)
        case .hold:
            expandedWidth
        case .dismissing:
            self.compactWidth + ((expandedWidth - self.compactWidth) * 0.46)
        }
    }

    static func size(for presentation: TokenMenuSpeedPresentationState) -> CGSize {
        CGSize(width: self.width(for: presentation), height: self.compactHeight)
    }

    static func overlap(for presentation: TokenMenuSpeedPresentationState) -> CGFloat {
        switch presentation.phase {
        case .idle:
            0
        case .ignite:
            12
        case .thrust:
            8
        case .hold:
            5
        case .dismissing:
            9
        }
    }

    static func expandedWidth(for bubbleDisplayText: String) -> CGFloat {
        let measurementFont = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        let measuredText = NSAttributedString(
            string: bubbleDisplayText,
            attributes: [.font: measurementFont])
        let textWidth = ceil(measuredText.size().width)
        return max(
            TokenMenuSpeedMeterLayout.bubbleMinimumWidth,
            textWidth + (TokenMenuSpeedMeterLayout.bubbleHorizontalPadding * 2))
    }
}

enum TokenMenuSpeedSymbolGlyph: Equatable {
    case coffee
    case rocket

    var systemName: String {
        switch self {
        case .coffee:
            "cup.and.saucer"
        case .rocket:
            "rocket"
        }
    }

    var fallbackEmoji: String {
        switch self {
        case .coffee:
            "☕️"
        case .rocket:
            "🚀"
        }
    }
}

enum TokenMenuSpeedStatusItemAppearance {
    static func symbolGlyph(for presentation: TokenMenuSpeedPresentationState) -> TokenMenuSpeedSymbolGlyph {
        presentation.usesRocketIcon ? .rocket : .coffee
    }

    static func fontSize(for presentation: TokenMenuSpeedPresentationState) -> CGFloat {
        presentation.usesRocketIcon ? 12.5 : 11
    }

    static func motion(for presentation: TokenMenuSpeedPresentationState) -> TokenMenuRocketMotion {
        switch presentation.phase {
        case .idle:
            .zero
        case .ignite, .thrust:
            TokenMenuSpeedStatusItemAnimation.launchMotion(strength: presentation.launchStrength)
        case .hold:
            TokenMenuSpeedStatusItemAnimation.settleMotion(strength: presentation.launchStrength)
        case .dismissing:
            TokenMenuRocketMotion(
                yOffset: -2.4,
                rotation: 0,
                scale: 0.98)
        }
    }

    static func animation(for presentation: TokenMenuSpeedPresentationState) -> Animation {
        switch presentation.phase {
        case .idle:
            .easeOut(duration: 0.16)
        case .ignite:
            .easeOut(duration: 0.14)
        case .thrust:
            .easeOut(duration: 0.32)
        case .hold:
            .easeOut(duration: 0.18)
        case .dismissing:
            .easeInOut(duration: 0.42)
        }
    }
}

private struct TokenMenuSpeedSymbol: View {
    let glyph: TokenMenuSpeedSymbolGlyph
    let fontSize: CGFloat
    let motion: TokenMenuRocketMotion

    var body: some View {
        Group {
            if NSImage(systemSymbolName: self.glyph.systemName, accessibilityDescription: nil) != nil {
                Image(systemName: self.glyph.systemName)
                    .font(.system(size: self.fontSize, weight: .semibold))
                    .symbolRenderingMode(.monochrome)
            } else {
                Text(self.glyph.fallbackEmoji)
                    .font(.system(size: self.fontSize + 1))
            }
        }
        .foregroundStyle(TokenMenuSpeedSurfaceTheme.symbol)
        .offset(y: self.motion.yOffset)
        .rotationEffect(.degrees(self.motion.rotation))
        .scaleEffect(self.motion.scale)
        .accessibilityHidden(true)
    }
}

struct TokenMenuSpeedStatusItemView: View {
    @Bindable var model: TokenMenuSpeedStatusItemModel

    private var presentation: TokenMenuSpeedPresentationState {
        self.model.presentation
    }

    private var motion: TokenMenuRocketMotion {
        TokenMenuSpeedStatusItemAppearance.motion(for: self.presentation)
    }

    var body: some View {
        self.iconSurface(motion: self.motion)
            .frame(
                width: TokenMenuSpeedMeterLayout.statusItemWidth - 6,
                height: TokenMenuSpeedMeterLayout.statusItemHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(self.presentation.speedText)
            .animation(
                TokenMenuSpeedStatusItemAppearance.animation(for: self.presentation),
                value: self.presentation.phase)
            .animation(.easeOut(duration: 0.18), value: self.presentation.burstID)
            .animation(.easeOut(duration: 0.16), value: self.presentation.displayedTokensPerSecond)
    }

    private func iconSurface(motion: TokenMenuRocketMotion) -> some View {
        ZStack {
            TokenMenuSpeedSurfaceBackground(
                shape: Capsule(style: .continuous),
                style: .compact)

            TokenMenuSpeedSymbol(
                glyph: TokenMenuSpeedStatusItemAppearance.symbolGlyph(for: self.presentation),
                fontSize: TokenMenuSpeedStatusItemAppearance.fontSize(for: self.presentation),
                motion: motion)
        }
    }
}

struct TokenMenuSpeedBubbleView: View {
    @Bindable var model: TokenMenuSpeedBubbleModel

    private var shape: Capsule {
        Capsule(style: .continuous)
    }

    private var presentation: TokenMenuSpeedPresentationState {
        self.model.presentation
    }

    var body: some View {
        self.content
            .opacity(self.model.isPresented ? TokenMenuSpeedBubbleAnimation.capsuleOpacity(for: self.presentation) : 0)
            .scaleEffect(
                x: TokenMenuSpeedBubbleAnimation.capsuleScaleX(for: self.presentation),
                y: TokenMenuSpeedBubbleAnimation.capsuleScaleY(for: self.presentation),
                anchor: .top)
            .offset(y: TokenMenuSpeedBubbleAnimation.capsuleYOffset(for: self.presentation))
            .animation(
                TokenMenuSpeedBubbleAnimation.animation(for: self.presentation),
                value: self.presentation.phase)
            .animation(.spring(response: 0.34, dampingFraction: 0.82), value: self.model.isPresented)
            .animation(.easeOut(duration: 0.16), value: self.presentation.displayedTokensPerSecond)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            TokenMenuSpeedSurfaceBackground(shape: self.shape, style: .bubble)

            HStack(alignment: .center, spacing: 0) {
                Text(self.presentation.bubbleDisplayText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(TokenMenuSpeedSurfaceTheme.bubbleText)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .opacity(TokenMenuSpeedBubbleAnimation.textOpacity(for: self.presentation))
            .offset(y: TokenMenuSpeedBubbleAnimation.textYOffset(for: self.presentation))
            .lineLimit(1)
            .padding(.horizontal, TokenMenuSpeedMeterLayout.bubbleHorizontalPadding)
            .frame(minWidth: TokenMenuSpeedMeterLayout.bubbleMinimumWidth)
        }
        .frame(width: TokenMenuSpeedBubbleLayout.width(for: self.presentation), height: TokenMenuSpeedBubbleLayout.compactHeight)
        .fixedSize(horizontal: true, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.presentation.speedText)
    }
}

struct TokenMenuSpeedMeterPreviewView: View {
    let metrics: MenuBarTokenSpeedMetrics

    @State private var bubbleModel = TokenMenuSpeedBubbleModel()
    @State private var statusItemModel = TokenMenuSpeedStatusItemModel()

    private var previewPresentation: TokenMenuSpeedPresentationState {
        guard self.metrics.tokensPerSecond > 0 else { return .idle }

        return TokenMenuSpeedPresentationState(
            displayedTokensPerSecond: self.metrics.tokensPerSecond,
            bubbleDisplayText: AppStrings(
                language: AppLanguage.resolvePreferredLanguage(Locale.preferredLanguages)
            ).compactTokenText(self.metrics.tokensPerSecond),
            launchStrength: max(self.metrics.launchStrength, 0.38),
            lastBurstDate: self.metrics.launchDate ?? Date(),
            burstID: 1,
            phase: .hold)
    }

    var body: some View {
        VStack(spacing: -6) {
            TokenMenuSpeedStatusItemView(model: self.statusItemModel)

            if self.previewPresentation.keepsBubbleMounted {
                TokenMenuSpeedBubbleView(model: self.bubbleModel)
            }
        }
        .task(id: self.metrics.tokensPerSecond) {
            self.statusItemModel.presentation = self.previewPresentation
            self.bubbleModel.presentation = self.previewPresentation
            self.bubbleModel.isPresented = self.previewPresentation.bubblePresented
        }
    }
}
