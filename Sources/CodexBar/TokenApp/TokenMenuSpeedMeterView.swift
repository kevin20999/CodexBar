import AppKit
import Observation
import SwiftUI

enum TokenMenuSpeedMeterLayout {
    static let statusItemWidth: CGFloat = 38
    static let statusItemHeight: CGFloat = 22
    static let bubbleBridgeWidth: CGFloat = 18
    static let bubbleBridgeHeight: CGFloat = 10
    static let bubbleInnerHeight: CGFloat = 32
    static let bubbleHorizontalPadding: CGFloat = 14
    static let bubbleAttachmentOverlap: CGFloat = 6
    static let bubbleMinimumWidth: CGFloat = 86
}

final class TokenPassThroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}

@MainActor
@Observable
final class TokenMenuSpeedBubbleModel {
    var metrics: MenuBarTokenSpeedMetrics = .zero
    var isPresented = false
}

@MainActor
@Observable
final class TokenMenuSpeedStatusItemModel {
    var metrics: MenuBarTokenSpeedMetrics = .zero
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

enum TokenMenuSpeedStatusItemAppearance {
    static func symbolName(for metrics: MenuBarTokenSpeedMetrics) -> String {
        metrics.usesRocketIcon ? "rocket" : "cup.and.saucer"
    }

    static func fontSize(for metrics: MenuBarTokenSpeedMetrics) -> CGFloat {
        metrics.usesRocketIcon ? 12.5 : 11
    }
}

private struct TokenMenuSpeedSymbol: View {
    let systemName: String
    let fontSize: CGFloat
    let motion: TokenMenuRocketMotion

    var body: some View {
        Image(systemName: self.systemName)
            .font(.system(size: self.fontSize, weight: .semibold))
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(TokenMenuSpeedSurfaceTheme.symbol)
            .offset(y: self.motion.yOffset)
            .rotationEffect(.degrees(self.motion.rotation))
            .scaleEffect(self.motion.scale)
            .accessibilityHidden(true)
    }
}

struct TokenMenuSpeedStatusItemView: View {
    @Bindable var model: TokenMenuSpeedStatusItemModel
    @State private var motion = TokenMenuRocketMotion.zero

    private var metrics: MenuBarTokenSpeedMetrics {
        self.model.metrics
    }

    private var animationID: String {
        let launchTime = self.metrics.launchDate?.timeIntervalSinceReferenceDate ?? -1
        return "\(self.metrics.tokensPerSecond)-\(self.metrics.launchStrength)-\(launchTime)"
    }

    var body: some View {
        self.iconSurface(motion: self.motion)
            .frame(
                width: TokenMenuSpeedMeterLayout.statusItemWidth - 6,
                height: TokenMenuSpeedMeterLayout.statusItemHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(self.metrics.speedText)
            .task(id: self.animationID) {
                await self.runAnimation()
            }
    }

    private func iconSurface(motion: TokenMenuRocketMotion) -> some View {
        ZStack {
            TokenMenuSpeedSurfaceBackground(
                shape: Capsule(style: .continuous),
                style: .compact)

            TokenMenuSpeedSymbol(
                systemName: TokenMenuSpeedStatusItemAppearance.symbolName(for: self.metrics),
                fontSize: TokenMenuSpeedStatusItemAppearance.fontSize(for: self.metrics),
                motion: motion)
        }
    }

    private func runAnimation() async {
        guard self.metrics.usesRocketIcon else {
            self.motion = .zero
            return
        }

        guard self.metrics.launchStrength > 0, self.metrics.launchDate != nil else {
            self.motion = .zero
            return
        }

        withAnimation(.easeOut(duration: TokenMenuSpeedStatusItemAnimation.launchUpDuration)) {
            self.motion = TokenMenuSpeedStatusItemAnimation.launchMotion(strength: self.metrics.launchStrength)
        }

        try? await Task.sleep(
            nanoseconds: UInt64(TokenMenuSpeedStatusItemAnimation.launchUpDuration * 1_000_000_000))
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: TokenMenuSpeedStatusItemAnimation.settleDuration)) {
            self.motion = TokenMenuSpeedStatusItemAnimation.settleMotion(strength: self.metrics.launchStrength)
        }

        try? await Task.sleep(
            nanoseconds: UInt64(TokenMenuSpeedStatusItemAnimation.settleDuration * 1_000_000_000))
        guard !Task.isCancelled else { return }

        withAnimation(.easeOut(duration: 0.16)) {
            self.motion = .zero
        }
    }
}

struct TokenMenuSpeedBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let bridgeWidth = TokenMenuSpeedMeterLayout.bubbleBridgeWidth
        let bridgeHeight = TokenMenuSpeedMeterLayout.bubbleBridgeHeight
        let bubbleRect = CGRect(
            x: 0,
            y: bridgeHeight - 4,
            width: rect.width,
            height: rect.height - bridgeHeight + 4)
        let bridgeRect = CGRect(
            x: (rect.width - bridgeWidth) / 2,
            y: 0,
            width: bridgeWidth,
            height: bridgeHeight)
        let connectorRect = CGRect(
            x: bridgeRect.minX,
            y: bridgeRect.midY,
            width: bridgeRect.width,
            height: max(bubbleRect.minY - bridgeRect.midY, 0))

        var path = Path()
        path.addRoundedRect(
            in: bubbleRect,
            cornerSize: CGSize(width: bubbleRect.height / 2, height: bubbleRect.height / 2))
        path.addRoundedRect(
            in: bridgeRect,
            cornerSize: CGSize(width: bridgeRect.width / 2, height: bridgeRect.height / 2))
        path.addRect(connectorRect)
        return path
    }
}

struct TokenMenuSpeedBubbleView: View {
    @Bindable var model: TokenMenuSpeedBubbleModel

    private var shape: TokenMenuSpeedBubbleShape {
        TokenMenuSpeedBubbleShape()
    }

    var body: some View {
        self.content
            .opacity(self.model.isPresented ? 1 : 0)
            .scaleEffect(self.model.isPresented ? 1 : 0.92, anchor: .top)
            .animation(.spring(response: 0.34, dampingFraction: 0.82), value: self.model.isPresented)
            .animation(.easeOut(duration: 0.16), value: self.model.metrics.tokensPerSecond)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var content: some View {
        let bubbleText = self.model.metrics.speedText

        ZStack {
            TokenMenuSpeedSurfaceBackground(shape: self.shape, style: .bubble)

            Text(bubbleText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(TokenMenuSpeedSurfaceTheme.bubbleText)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .padding(.top, TokenMenuSpeedMeterLayout.bubbleBridgeHeight - 1)
                .padding(.horizontal, TokenMenuSpeedMeterLayout.bubbleHorizontalPadding)
                .frame(minWidth: TokenMenuSpeedMeterLayout.bubbleMinimumWidth)
        }
        .frame(height: TokenMenuSpeedMeterLayout.bubbleBridgeHeight + TokenMenuSpeedMeterLayout.bubbleInnerHeight)
        .fixedSize(horizontal: true, vertical: true)
    }
}

struct TokenMenuSpeedMeterPreviewView: View {
    let metrics: MenuBarTokenSpeedMetrics

    @State private var bubbleModel = TokenMenuSpeedBubbleModel()
    @State private var statusItemModel = TokenMenuSpeedStatusItemModel()

    var body: some View {
        VStack(spacing: -(TokenMenuSpeedMeterLayout.bubbleAttachmentOverlap - 1)) {
            TokenMenuSpeedStatusItemView(model: self.statusItemModel)

            if self.metrics.isActive {
                TokenMenuSpeedBubbleView(model: self.bubbleModel)
            }
        }
        .task(id: self.metrics.tokensPerSecond) {
            self.statusItemModel.metrics = self.metrics
            self.bubbleModel.metrics = self.metrics
            self.bubbleModel.isPresented = self.metrics.isActive
        }
    }
}
