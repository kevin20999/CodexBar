import AppKit
import CodexBarCore
import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum TokenDailyBoardNarrativeLayout {
    static let railSpacing: CGFloat = 12
    static let maxLines = 2
    static let typewriterCharactersPerSecond: Double = 20
    static let customizeButtonSymbol = "slider.horizontal.3"
    static let nextButtonSize: CGFloat = 15
    static let defaultAvatarContentScale: CGFloat = 1.18
    static let baseBodyFontSize: CGFloat = 28 * TokenDailyBoardNarrativeAnimationRules.bodyFontScale
    static let textBlockHeight: CGFloat = ceil(
        (NSFont.systemFont(ofSize: baseBodyFontSize, weight: .light).ascender
            - NSFont.systemFont(ofSize: baseBodyFontSize, weight: .light).descender
            + NSFont.systemFont(ofSize: baseBodyFontSize, weight: .light).leading)
            * CGFloat(maxLines))
    static let avatarCornerRadius: CGFloat = 18
    static let bubbleCornerRadius: CGFloat = 24
    static let bubbleHorizontalPadding: CGFloat = 22
    static let bubbleTopPadding: CGFloat = 18
    static let bubbleBottomPadding: CGFloat = 14
    static let conversationOnlyShellHorizontalPadding: CGFloat = 24
    static let conversationOnlyShellVerticalPadding: CGFloat = 20
    static let conversationOnlyShellRowSpacing: CGFloat = 14
    static let conversationOnlyShellCornerRadius: CGFloat = 82
    static let conversationOnlyExternalControlsTopSpacing: CGFloat = 8
    static let conversationOnlyAvatarVisualSize: CGFloat = 112
    static let conversationOnlyAvatarImageInset: CGFloat = 6
    static let conversationOnlyAvatarSize: CGFloat = 56
    static let conversationOnlyAvatarToContentSpacing: CGFloat = 12
    static let conversationOnlyAnimationSafetyWidth: CGFloat = 56
    static let conversationOnlyMetadataTopSpacing: CGFloat = 6
    static let conversationOnlyMetadataFontSize: CGFloat = 12
    static let timestampFontSize: CGFloat = 11
    static let controlsTopSpacing: CGFloat = 10
    static let bubbleBodyHeight: CGFloat = textBlockHeight
        + bubbleTopPadding
        + bubbleBottomPadding
    static let avatarSize: CGFloat = ceil(bubbleBodyHeight)
    static let conversationOnlyAvatarStageWidth: CGFloat = conversationOnlyAvatarVisualSize
    static let conversationOnlyAvatarAnimationPushDistance: CGFloat = ceil(
        avatarSize * (TokenDailyBoardNarrativeAnimationRules.avatarPeakScale - 1))
        + 10
    static let conversationOnlyMinimumBubbleWidthDuringAvatarAnimation: CGFloat = 240
}

struct TokenDailyBoardNarrativeSizingMetrics: Equatable {
    let fontSizes: [CGFloat]
    let minimumFontSize: CGFloat
    let textBlockHeight: CGFloat
    let bubbleBodyHeight: CGFloat
    let avatarSize: CGFloat
    let bubbleHeight: CGFloat
    let railHeight: CGFloat
}

struct TokenDailyBoardConversationOnlyVisibleContentLayout: Equatable {
    let textColumnWidth: CGFloat
    let contentSize: CGSize
}

enum TokenDailyBoardNarrativePresentationRules {
    static let showsNamePrefix = false
    static let avatarUsesRoundedSquare = true
    static let avatarIsMirrored = true
    static let showsBubbleTail = false
    static let controlsRowIsOutsideBubble = true
    static let usesPreviousAndNextButtons = false
    static let usesFixedOverlay = true
    static let followsScrollPosition = false
    static let contentScrollsUnderOverlay = true

    static func showsOutlineStroke(for displayMode: TokenDailyBoardDisplayMode) -> Bool {
        displayMode != .conversationOnly
    }

    static func usesSystemGlass(for displayMode: TokenDailyBoardDisplayMode) -> Bool {
        displayMode != .conversationOnly
    }

    static func showsOuterShadow(for displayMode: TokenDailyBoardDisplayMode) -> Bool {
        displayMode != .conversationOnly
    }
}

enum TokenDailyBoardNarrativeAnimationRules {
    static let bodyWeight: Font.Weight = .light
    static let bodyNSWeight: NSFont.Weight = .light
    static let bodyFontScale: CGFloat = 0.8
    static let avatarPeakScale: CGFloat = 1
    static let dropletCountRange = 12...18
    static let dropletSizeRange: ClosedRange<CGFloat> = 10...48
    static let dropletLifetimeRange: ClosedRange<Double> = 5.2...6.6
    static let dropletRegionWidthFactor: CGFloat = 1
    static let dropletRegionHeightFactor: CGFloat = 1
    static let dropletLaunchXRange: ClosedRange<CGFloat> = -28...28
    static let dropletLaunchYRange: ClosedRange<CGFloat> = -42 ... -10
    static let dropletDriftXRange: ClosedRange<CGFloat> = -30...30
    static let dropletFallDistanceRange: ClosedRange<CGFloat> = 54...180
    static let dropletMaximumVisibleBatches = 2
    static let triggersOnlyForAutomaticRealtimeSwitches = true

    static func typewriterDuration(for text: String) -> TimeInterval {
        self.typewriterDuration(
            for: text,
            charactersPerSecond: TokenDailyBoardNarrativeLayout.typewriterCharactersPerSecond)
    }

    static func typewriterDuration(for text: String, charactersPerSecond: Double) -> TimeInterval {
        guard !text.isEmpty else { return 0 }
        let stepCount = max(text.count - 1, 0)
        return Double(stepCount) / max(charactersPerSecond, 0.1)
    }
}

package enum TokenDailyBoardNarrativeAvatarReplacementAnimationRules {
    package static let peakScale: CGFloat = 1.15
    package static let duration: TimeInterval = 3.0
    package static let introDuration: TimeInterval = 0.36
    package static let returnDuration: TimeInterval = 0.36
    package static let minimumReturnStartDelay: TimeInterval = duration - returnDuration
    package static let holdDuration: TimeInterval = duration - introDuration - returnDuration
    package static let crossfadeDuration: TimeInterval = 0.18
    package static let returnCrossfadeDuration: TimeInterval = 0.28
    package static let expandDuration: TimeInterval = 0.10
    package static let recoilDuration: TimeInterval = 0.10
    package static let settleDuration: TimeInterval = introDuration - expandDuration - recoilDuration
    package static let returnPeakScale: CGFloat = 1.06
    package static let returnLiftDuration: TimeInterval = 0.12
    package static let returnSettleDuration: TimeInterval = returnDuration - returnLiftDuration
    package static let shakeAmplitude: CGFloat = 3

    package static func isEnabled(
        _ tuning: TokenDailyBoardConversationOnlyDebugTuning,
        displayMode: TokenDailyBoardDisplayMode)
        -> Bool
    {
        switch displayMode {
        case .conversationOnly, .conversationAndToday, .fullBoard:
            tuning.enablesAvatarReplacementAnimation
        }
    }

    package static func signature(
        for slot: CodexDailyAvatarResolvedSlot?,
        displayMode: TokenDailyBoardDisplayMode)
        -> String
    {
        guard let slot else {
            return "missing|\(displayMode.rawValue)"
        }

        let imageSignature = slot.preferredImage(for: displayMode).map {
            String(describing: ObjectIdentifier($0))
        } ?? "none"

        return [
            displayMode.rawValue,
            slot.slot.rawValue,
            String(slot.isMirrored),
            String(slot.usesCustomImage),
            String(slot.usesCustomMirror),
            imageSignature,
        ].joined(separator: "|")
    }

    package static func transitionKey(
        for slot: CodexDailyAvatarResolvedSlot?,
        displayMode: TokenDailyBoardDisplayMode,
        sequenceID: Int)
        -> String
    {
        "\(self.signature(for: slot, displayMode: displayMode))|sequence:\(sequenceID)"
    }
}

package enum TokenDailyBoardNarrativeAvatarIdleShakeAnimationRules {
    package static let peakScale: CGFloat = 1.02
    package static let shakeAmplitude: CGFloat = 1.8
    package static let firstLegDuration: TimeInterval = 0.12
    package static let secondLegDuration: TimeInterval = 0.10
    package static let settleDuration: TimeInterval = 0.14

    package static var totalDuration: TimeInterval {
        self.firstLegDuration + self.secondLegDuration + self.settleDuration
    }
}

struct TokenDailyBoardNarrativePulseMotionConfiguration: Equatable {
    let style: TokenDailyBoardNarrativePulseStyle
    let duration: TimeInterval
    let fadeOutDuration: TimeInterval
}

struct TokenDailyBoardNarrativeAvatarMotionConfiguration: Equatable {
    let defaultPeakScale: CGFloat
    let defaultShakeAmplitude: CGFloat
    let variantPeakScale: CGFloat
    let variantShakeAmplitude: CGFloat

    static let standard = TokenDailyBoardNarrativeAvatarMotionConfiguration(
        defaultPeakScale: TokenDailyBoardNarrativeAvatarIdleShakeAnimationRules.peakScale,
        defaultShakeAmplitude: 0,
        variantPeakScale: TokenDailyBoardNarrativeAvatarReplacementAnimationRules.peakScale,
        variantShakeAmplitude: TokenDailyBoardNarrativeAvatarReplacementAnimationRules.shakeAmplitude)
}

package enum TokenDailyBoardNarrativeVariantAvatarRules {
    package static func variantSlots(from slots: [CodexDailyAvatarResolvedSlot]) -> [CodexDailyAvatarResolvedSlot] {
        CodexDailyDockIconAnimationRules.variantSlots(from: slots)
    }

    package static func defaultSlot(from slots: [CodexDailyAvatarResolvedSlot]) -> CodexDailyAvatarResolvedSlot? {
        slots.first(where: { $0.slot == .defaultAvatar })
    }

    package static func activeSlot(
        from slots: [CodexDailyAvatarResolvedSlot],
        variantCycleIndex: Int?)
        -> CodexDailyAvatarResolvedSlot?
    {
        let variants = self.variantSlots(from: slots)
        guard let variantCycleIndex, !variants.isEmpty else {
            return self.defaultSlot(from: slots)
        }

        let resolvedIndex = ((variantCycleIndex % variants.count) + variants.count) % variants.count
        return variants[resolvedIndex]
    }

    package static func nextVariantCycleIndex(
        current: Int?,
        slots: [CodexDailyAvatarResolvedSlot])
        -> Int?
    {
        let variants = self.variantSlots(from: slots)
        guard !variants.isEmpty else { return nil }
        guard let current else { return 0 }
        return (current + 1) % variants.count
    }
}

enum TokenDailyBoardNarrativeAvatarCatalog {
    static let defaultAvatarName = NSImage.Name("DailyBoardCodexAvatar")
    static let tileCount = 9

    private static let variantAvatarNames: [NSImage.Name] = (1...tileCount).map {
        NSImage.Name(String(format: "DailyBoardCodexAvatarVariant%02d", $0))
    }

    private static let variantTiles: [NSImage] = loadVariantTiles()

    static func defaultImage() -> NSImage? {
        Bundle.module.image(forResource: self.defaultAvatarName)
    }

    static func image(forVariantIndex index: Int?) -> NSImage? {
        if let index, self.variantTiles.indices.contains(index) {
            return self.variantTiles[index]
        }

        return self.defaultImage()
    }

    static func availableVariantCount() -> Int {
        self.variantTiles.count
    }

    private static func loadVariantTiles() -> [NSImage] {
        self.variantAvatarNames.compactMap { Bundle.module.image(forResource: $0) }
    }
}

enum TokenDailyBoardNarrativeSizingRules {
    private static let baselineFontSizes: [CGFloat] = [
        28 * TokenDailyBoardNarrativeAnimationRules.bodyFontScale,
        26 * TokenDailyBoardNarrativeAnimationRules.bodyFontScale,
        24 * TokenDailyBoardNarrativeAnimationRules.bodyFontScale,
        22 * TokenDailyBoardNarrativeAnimationRules.bodyFontScale,
    ]
    private static let baselineMinimumFontSize: CGFloat = 22 * TokenDailyBoardNarrativeAnimationRules.bodyFontScale
    private static let absoluteMinimumAutoFitFontSize: CGFloat = 6
    private static let autoFitSearchIterations = 16
    private static let fixedLayoutMetrics = TokenDailyBoardNarrativeSizingMetrics(
        fontSizes: baselineFontSizes,
        minimumFontSize: baselineMinimumFontSize,
        textBlockHeight: TokenDailyBoardNarrativeLayout.textBlockHeight,
        bubbleBodyHeight: TokenDailyBoardNarrativeLayout.bubbleBodyHeight,
        avatarSize: TokenDailyBoardNarrativeLayout.avatarSize,
        bubbleHeight: TokenDailyBoardNarrativeLayout.avatarSize,
        railHeight: TokenDailyBoardNarrativeLayout.avatarSize
            + TokenDailyBoardNarrativeLayout.controlsTopSpacing
            + controlsRowHeight)
    static let minimumFontScaleMultiplier: CGFloat = 0.7
    static let maximumFontScaleMultiplier: CGFloat = 1.3
    static let buttonReservedWidth: CGFloat = 26
    static let buttonSpacing: CGFloat = 12
    static let controlsButtonClusterWidth: CGFloat = buttonReservedWidth
    static let conversationOnlyMinimumBubbleWidth: CGFloat = 500
    static let conversationOnlyMaximumBubbleWidth: CGFloat = 580
    static let conversationOnlyBubbleWidthSnapStep: CGFloat = 8
    static let conversationOnlyTrailingSafetyInset: CGFloat =
        TokenDailyBoardNarrativeLayout.conversationOnlyAvatarAnimationPushDistance + 12
    static let controlsRowHeight: CGFloat = max(
        ceil(Self.lineHeight(for: Self.timestampFont())),
        TokenDailyBoardNarrativeLayout.nextButtonSize)
    static var fontSizes: [CGFloat] {
        self.metrics().fontSizes
    }

    static var minimumFontSize: CGFloat {
        self.metrics().minimumFontSize
    }

    static var bubbleHeight: CGFloat {
        self.metrics().bubbleHeight
    }

    static var railHeight: CGFloat {
        self.metrics().railHeight
    }

    static func metrics(fontScaleMultiplier: CGFloat = 1.0) -> TokenDailyBoardNarrativeSizingMetrics {
        let clampedScale = min(
            max(fontScaleMultiplier, self.minimumFontScaleMultiplier),
            self.maximumFontScaleMultiplier)
        let fontSizes = self.baselineFontSizes.map { $0 * clampedScale }
        let minimumFontSize = self.baselineMinimumFontSize * clampedScale

        return TokenDailyBoardNarrativeSizingMetrics(
            fontSizes: fontSizes,
            minimumFontSize: minimumFontSize,
            textBlockHeight: self.fixedLayoutMetrics.textBlockHeight,
            bubbleBodyHeight: self.fixedLayoutMetrics.bubbleBodyHeight,
            avatarSize: self.fixedLayoutMetrics.avatarSize,
            bubbleHeight: self.fixedLayoutMetrics.bubbleHeight,
            railHeight: self.fixedLayoutMetrics.railHeight)
    }

    static func style(
        for fullText: String,
        availableWidth: CGFloat,
        fontScaleMultiplier: CGFloat = 1.0,
        preferredFontSize: CGFloat? = nil,
        lineSpacing: CGFloat = 0)
        -> TokenDailyBoardTextStyle
    {
        let textWidth = max(availableWidth, 1)
        let metrics = self.metrics(fontScaleMultiplier: fontScaleMultiplier)
        let startingFontSize = max(
            preferredFontSize ?? (metrics.fontSizes.first ?? metrics.minimumFontSize),
            self.absoluteMinimumAutoFitFontSize)

        if self.fits(
            text: fullText,
            fontSize: startingFontSize,
            availableWidth: textWidth,
            lineSpacing: lineSpacing)
        {
            return TokenDailyBoardTextStyle(
                size: startingFontSize,
                weight: TokenDailyBoardNarrativeAnimationRules.bodyWeight)
        }

        let fittedFontSize = self.maximumFittingFontSize(
            for: fullText,
            availableWidth: textWidth,
            upperBound: startingFontSize,
            lineSpacing: lineSpacing)

        return TokenDailyBoardTextStyle(
            size: fittedFontSize,
            weight: TokenDailyBoardNarrativeAnimationRules.bodyWeight)
    }

    static func conversationOnlyShellHeight(fontScaleMultiplier: CGFloat = 1.0) -> CGFloat {
        _ = fontScaleMultiplier
        return 164
    }

    static func conversationOnlyContentHeight(
        avatarSize: CGFloat,
        bodyFontSize: CGFloat,
        lineSpacing: CGFloat,
        metadataFontSize: CGFloat,
        hasMetadata: Bool)
        -> CGFloat
    {
        let metadataHeight = hasMetadata
            ? TokenDailyBoardNarrativeLayout.conversationOnlyMetadataTopSpacing
            + self.conversationOnlyMetadataLineHeight(fontSize: metadataFontSize)
            : 0
        let textColumnHeight = self.conversationOnlyBodyTextHeight(
            fontSize: bodyFontSize,
            lineSpacing: lineSpacing) + metadataHeight
        return max(avatarSize, textColumnHeight)
    }

    static func conversationOnlyVisibleContentLayout(
        for sentence: TokenDailyBoardNarrativeSentence,
        tuning: TokenDailyBoardConversationOnlyDebugTuning,
        fontScaleMultiplier: CGFloat = 1.0)
        -> TokenDailyBoardConversationOnlyVisibleContentLayout
    {
        let resolvedTuning = TokenDailyBoardConversationOnlyDebugRules.clamp(tuning)
        let textColumnWidth = TokenDailyBoardConversationOnlyDebugRules.resolvedTextColumnWidth(
            resolvedTuning.textColumnWidth,
            avatarSize: resolvedTuning.avatarSize)
        let textStyle = self.style(
            for: sentence.text,
            availableWidth: textColumnWidth,
            fontScaleMultiplier: fontScaleMultiplier,
            preferredFontSize: resolvedTuning.bodyFontSize,
            lineSpacing: resolvedTuning.bodyLineSpacing)
        let hasMetadata = sentence.metadataText?.isEmpty == false
        let contentWidth = resolvedTuning.avatarSize
            + TokenDailyBoardNarrativeLayout.conversationOnlyAvatarToContentSpacing
            + textColumnWidth

        return TokenDailyBoardConversationOnlyVisibleContentLayout(
            textColumnWidth: textColumnWidth,
            contentSize: CGSize(
                width: contentWidth,
                height: self.conversationOnlyContentHeight(
                    avatarSize: resolvedTuning.avatarSize,
                    bodyFontSize: textStyle.size,
                    lineSpacing: resolvedTuning.bodyLineSpacing,
                    metadataFontSize: resolvedTuning.metadataFontSize,
                    hasMetadata: hasMetadata)))
    }

    static func preferredConversationOnlyBubbleWidth(
        for fullText: String,
        fontScaleMultiplier: CGFloat = 1.0)
        -> CGFloat
    {
        let metrics = self.metrics(fontScaleMultiplier: fontScaleMultiplier)
        let textInsets = TokenDailyBoardNarrativeLayout.bubbleHorizontalPadding * 2
        let lowerBound = max(self.conversationOnlyMinimumBubbleWidth - textInsets, 120)
        let upperBound = max(self.conversationOnlyMaximumBubbleWidth - textInsets, lowerBound)
        let startingFontSize = metrics.fontSizes.first ?? metrics.minimumFontSize

        guard self.fits(
            text: fullText,
            fontSize: startingFontSize,
            availableWidth: upperBound,
            lineSpacing: 0)
        else {
            return self.conversationOnlyMaximumBubbleWidth
        }

        var lower = lowerBound
        var upper = upperBound
        var bestFit = upperBound

        for _ in 0..<self.autoFitSearchIterations {
            let midpoint = (lower + upper) / 2
            if self.fits(
                text: fullText,
                fontSize: startingFontSize,
                availableWidth: midpoint,
                lineSpacing: 0)
            {
                bestFit = midpoint
                upper = midpoint
            } else {
                lower = midpoint
            }
        }

        let resolvedWidth = bestFit + textInsets
        let snappedWidth = (resolvedWidth / self.conversationOnlyBubbleWidthSnapStep).rounded(.up)
            * self.conversationOnlyBubbleWidthSnapStep
        return min(
            max(snappedWidth, self.conversationOnlyMinimumBubbleWidth),
            self.conversationOnlyMaximumBubbleWidth)
    }

    private static func maximumFittingFontSize(
        for text: String,
        availableWidth: CGFloat,
        upperBound: CGFloat,
        lineSpacing: CGFloat)
        -> CGFloat
    {
        var lowerBound = self.absoluteMinimumAutoFitFontSize
        var upperBound = max(upperBound, lowerBound)
        var bestFit = lowerBound

        if self.fits(
            text: text,
            fontSize: lowerBound,
            availableWidth: availableWidth,
            lineSpacing: lineSpacing)
        {
            bestFit = lowerBound
        }

        for _ in 0..<self.autoFitSearchIterations {
            let midpoint = (lowerBound + upperBound) / 2
            if self.fits(
                text: text,
                fontSize: midpoint,
                availableWidth: availableWidth,
                lineSpacing: lineSpacing)
            {
                bestFit = midpoint
                lowerBound = midpoint
            } else {
                upperBound = midpoint
            }
        }

        return max(bestFit, self.absoluteMinimumAutoFitFontSize)
    }

    private static func fits(
        text: String,
        fontSize: CGFloat,
        availableWidth: CGFloat,
        lineSpacing: CGFloat)
        -> Bool
    {
        let attributedText = self.attributedText(
            for: text,
            font: self.font(for: fontSize),
            lineSpacing: lineSpacing)
        let boundingRect = attributedText.boundingRect(
            with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading])
        let maxAllowedHeight = self.conversationOnlyBodyTextHeight(
            fontSize: fontSize,
            lineSpacing: lineSpacing) + 1
        return ceil(boundingRect.height) <= maxAllowedHeight
    }

    private static func font(for size: CGFloat) -> NSFont {
        .systemFont(ofSize: size, weight: TokenDailyBoardNarrativeAnimationRules.bodyNSWeight)
    }

    private static func timestampFont() -> NSFont {
        .systemFont(ofSize: TokenDailyBoardNarrativeLayout.timestampFontSize, weight: .medium)
    }

    private static func conversationOnlyMetadataWidth(
        for metadataText: String?,
        fontSize: CGFloat,
        availableWidth: CGFloat)
        -> CGFloat
    {
        guard let metadataText, !metadataText.isEmpty else { return 0 }
        return self.measuredWidth(
            for: metadataText,
            font: .monospacedDigitSystemFont(
                ofSize: fontSize,
                weight: .medium),
            widthConstraint: .greatestFiniteMagnitude,
            maximumWidth: availableWidth)
    }

    private static func measuredWidth(
        for text: String,
        font: NSFont,
        widthConstraint: CGFloat,
        maximumWidth: CGFloat)
        -> CGFloat
    {
        let attributedText = NSAttributedString(string: text, attributes: [.font: font])
        let boundingRect = attributedText.boundingRect(
            with: CGSize(width: widthConstraint, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading])
        return min(max(ceil(boundingRect.width), 0), maximumWidth)
    }

    private static func attributedText(
        for text: String,
        font: NSFont,
        lineSpacing: CGFloat)
        -> NSAttributedString
    {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        return NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle,
            ])
    }

    private static func conversationOnlyBodyTextHeight(fontSize: CGFloat, lineSpacing: CGFloat) -> CGFloat {
        ceil((self.lineHeight(for: self.font(for: fontSize)) * CGFloat(TokenDailyBoardNarrativeLayout.maxLines))
            + (lineSpacing * CGFloat(max(TokenDailyBoardNarrativeLayout.maxLines - 1, 0))))
    }

    private static func conversationOnlyMetadataLineHeight(fontSize: CGFloat) -> CGFloat {
        ceil(
            self.lineHeight(
                for: .systemFont(
                    ofSize: fontSize,
                    weight: .medium)))
    }

    private static func lineHeight(for font: NSFont) -> CGFloat {
        font.ascender - font.descender + font.leading
    }
}

enum TokenDailyBoardNarrativeScrollSpace {
    static let name = "TokenDailyBoardNarrativeScrollViewport"
}

enum TokenDailyBoardNarrativeTimelineRules {
    static func priority(for kind: TokenDailyBoardNarrativeEventKind) -> Int {
        switch kind {
        case .throughputPulse:
            5
        case .instructionPulse:
            4
        case .idlePulse:
            3
        case .combo:
            2
        case .burst:
            1
        case .sendCount:
            0
        case .quiet:
            -1
        }
    }
}

enum TokenDailyBoardNarrativeEventKind: String, CaseIterable, Codable, Sendable {
    case quiet
    case sendCount
    case burst
    case combo
    case throughputPulse
    case instructionPulse
    case idlePulse
}

enum TokenDailyBoardNarrativePresentationGroupKind: String, Equatable, Sendable {
    case waitingGroup
    case eventGroup
}

enum TokenDailyBoardNarrativeInstructionBand: String, CaseIterable, Codable, Sendable {
    case zero
    case oneToFour
    case fiveToFourteen
    case fifteenToThirtyNine
    case fortyToSeventyNine
    case eightyPlus

    static func resolve(for instructionCount: Int) -> Self {
        switch instructionCount {
        case ..<1:
            .zero
        case 1...4:
            .oneToFour
        case 5...14:
            .fiveToFourteen
        case 15...39:
            .fifteenToThirtyNine
        case 40...79:
            .fortyToSeventyNine
        default:
            .eightyPlus
        }
    }
}

enum TokenDailyBoardNarrativeTokenBand: String, CaseIterable, Codable, Sendable {
    case low
    case medium
    case high
    case extreme

    static func resolve(for tokenCount: Int) -> Self {
        switch tokenCount {
        case ..<50_000_000:
            .low
        case 50_000_000..<200_000_000:
            .medium
        case 200_000_000..<1_000_000_000:
            .high
        default:
            .extreme
        }
    }
}

enum TokenDailyBoardNarrativeTimeBand: String, CaseIterable, Codable, Sendable {
    case lateNight
    case morning
    case afternoon
    case night

    static func resolve(for hour: Int) -> Self {
        switch hour {
        case 0..<6:
            .lateNight
        case 6..<12:
            .morning
        case 12..<18:
            .afternoon
        default:
            .night
        }
    }
}

struct TokenDailyBoardNarrativeCatalogEntry: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let language: TokenDailyBoardLanguage
    let eventKind: TokenDailyBoardNarrativeEventKind
    let instructionBand: TokenDailyBoardNarrativeInstructionBand?
    let tokenBand: TokenDailyBoardNarrativeTokenBand?
    let timeBand: TokenDailyBoardNarrativeTimeBand?
    let text: String
}

struct TokenDailyBoardNarrativeUserCatalogEntry: Codable, Equatable, Sendable, Identifiable {
    let id: String
    let language: TokenDailyBoardLanguage
    var category: String
    let eventKind: TokenDailyBoardNarrativeEventKind
    let instructionBand: TokenDailyBoardNarrativeInstructionBand?
    let tokenBand: TokenDailyBoardNarrativeTokenBand?
    let timeBand: TokenDailyBoardNarrativeTimeBand?
    var text: String
    var enabled: Bool
    var overrideTargetID: String? = nil

    var normalizedCategory: String {
        let trimmed = self.category.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未分类" : trimmed
    }
}

enum TokenDailyBoardNarrativeEditableEntrySource: String, Equatable, Sendable {
    case bundled
    case bundledOverride
    case userCustom
}

struct TokenDailyBoardNarrativeEditableEntry: Identifiable, Equatable, Sendable {
    let id: String
    let source: TokenDailyBoardNarrativeEditableEntrySource
    let bundledEntry: TokenDailyBoardNarrativeCatalogEntry?
    let userEntry: TokenDailyBoardNarrativeUserCatalogEntry?

    init(
        bundledEntry: TokenDailyBoardNarrativeCatalogEntry,
        overrideEntry: TokenDailyBoardNarrativeUserCatalogEntry? = nil)
    {
        self.id = "bundled:\(bundledEntry.id)"
        self.source = overrideEntry == nil ? .bundled : .bundledOverride
        self.bundledEntry = bundledEntry
        self.userEntry = overrideEntry
    }

    init(userEntry: TokenDailyBoardNarrativeUserCatalogEntry) {
        self.id = "user:\(userEntry.id)"
        self.source = .userCustom
        self.bundledEntry = nil
        self.userEntry = userEntry
    }

    var effectiveID: String {
        self.userEntry?.id ?? self.bundledEntry?.id ?? self.id
    }

    var effectiveCategory: String {
        self.userEntry?.normalizedCategory ?? "内置"
    }

    var effectiveEventKind: TokenDailyBoardNarrativeEventKind {
        self.userEntry?.eventKind ?? self.bundledEntry?.eventKind ?? .throughputPulse
    }

    var effectiveInstructionBand: TokenDailyBoardNarrativeInstructionBand? {
        self.userEntry?.instructionBand ?? self.bundledEntry?.instructionBand
    }

    var effectiveTokenBand: TokenDailyBoardNarrativeTokenBand? {
        self.userEntry?.tokenBand ?? self.bundledEntry?.tokenBand
    }

    var effectiveTimeBand: TokenDailyBoardNarrativeTimeBand? {
        self.userEntry?.timeBand ?? self.bundledEntry?.timeBand
    }

    var effectiveText: String {
        self.userEntry?.text ?? self.bundledEntry?.text ?? ""
    }

    var effectiveEnabled: Bool {
        self.userEntry?.enabled ?? true
    }

    var isBuiltInEntry: Bool {
        self.bundledEntry != nil
    }

    var canRestoreDefault: Bool {
        self.bundledEntry != nil && self.userEntry != nil
    }
}

enum TokenDailyBoardNarrativeEditableCatalog {
    static func entries(
        bundledEntries: [TokenDailyBoardNarrativeCatalogEntry],
        userEntries: [TokenDailyBoardNarrativeUserCatalogEntry],
        language: TokenDailyBoardLanguage = .zhHans)
        -> [TokenDailyBoardNarrativeEditableEntry]
    {
        let filteredBundledEntries = bundledEntries
            .filter { $0.language == language }
        let filteredUserEntries = userEntries
            .filter { $0.language == language }

        let overrideEntriesByTargetID = Dictionary(
            grouping: filteredUserEntries.filter { $0.overrideTargetID != nil })
        {
            $0.overrideTargetID ?? ""
        }
        let bundledEditableEntries = filteredBundledEntries.map { bundledEntry in
            let overrideEntry = overrideEntriesByTargetID[bundledEntry.id]?
                .sorted { $0.id < $1.id }
                .first
            return TokenDailyBoardNarrativeEditableEntry(
                bundledEntry: bundledEntry,
                overrideEntry: overrideEntry)
        }

        let customUserEntries = filteredUserEntries
            .filter { $0.overrideTargetID == nil }
            .map(TokenDailyBoardNarrativeEditableEntry.init)

        return (bundledEditableEntries + customUserEntries).sorted { lhs, rhs in
            if lhs.effectiveEventKind != rhs.effectiveEventKind {
                return lhs.effectiveEventKind.rawValue < rhs.effectiveEventKind.rawValue
            }
            if lhs.source != rhs.source {
                return lhs.sourceSortOrder < rhs.sourceSortOrder
            }
            if lhs.effectiveCategory != rhs.effectiveCategory {
                return lhs.effectiveCategory.localizedCompare(rhs.effectiveCategory) == .orderedAscending
            }
            return lhs.effectiveID < rhs.effectiveID
        }
    }
}

extension TokenDailyBoardNarrativeEditableEntry {
    fileprivate var sourceSortOrder: Int {
        switch self.source {
        case .bundled, .bundledOverride:
            0
        case .userCustom:
            1
        }
    }
}

struct TokenDailyBoardNarrativeUserCatalogStore {
    let fileURL: URL

    func load() throws -> [TokenDailyBoardNarrativeUserCatalogEntry] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: self.fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: self.fileURL)
        return try JSONDecoder().decode([TokenDailyBoardNarrativeUserCatalogEntry].self, from: data)
    }

    func save(_ entries: [TokenDailyBoardNarrativeUserCatalogEntry]) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(
            at: self.fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true)

        let normalizedEntries = entries.sorted { lhs, rhs in
            if lhs.eventKind != rhs.eventKind {
                return lhs.eventKind.rawValue < rhs.eventKind.rawValue
            }
            if lhs.normalizedCategory != rhs.normalizedCategory {
                return lhs.normalizedCategory.localizedCompare(rhs.normalizedCategory) == .orderedAscending
            }
            return lhs.id < rhs.id
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(normalizedEntries)
        try data.write(to: self.fileURL, options: .atomic)
    }
}

struct TokenDailyBoardNarrativeBurstCluster: Equatable, Sendable {
    let startBucketIndex: Int
    let endBucketIndex: Int
    let peakBucketIndex: Int
    let peakTokens: Int
    let totalTokens: Int

    var timeBand: TokenDailyBoardNarrativeTimeBand {
        TokenDailyBoardNarrativeTimeBand.resolve(for: self.peakBucketIndex / 12)
    }
}

struct TokenDailyBoardNarrativeEvent: Equatable, Sendable, Identifiable {
    let dayKey: String
    let dayTitle: String
    let kind: TokenDailyBoardNarrativeEventKind
    let instructionBand: TokenDailyBoardNarrativeInstructionBand
    let tokenBand: TokenDailyBoardNarrativeTokenBand
    let timeBand: TokenDailyBoardNarrativeTimeBand?
    let instructionCount: Int
    let totalTokens: Int
    let mainThreadTokens: Int
    let burstTokens: Int
    let clusterStartBucketIndex: Int?
    let peakBucketIndex: Int?

    init(
        dayKey: String,
        dayTitle: String,
        kind: TokenDailyBoardNarrativeEventKind,
        instructionBand: TokenDailyBoardNarrativeInstructionBand,
        tokenBand: TokenDailyBoardNarrativeTokenBand,
        timeBand: TokenDailyBoardNarrativeTimeBand?,
        instructionCount: Int,
        totalTokens: Int,
        mainThreadTokens: Int,
        burstTokens: Int,
        clusterStartBucketIndex: Int?,
        peakBucketIndex: Int? = nil)
    {
        self.dayKey = dayKey
        self.dayTitle = dayTitle
        self.kind = kind
        self.instructionBand = instructionBand
        self.tokenBand = tokenBand
        self.timeBand = timeBand
        self.instructionCount = instructionCount
        self.totalTokens = totalTokens
        self.mainThreadTokens = mainThreadTokens
        self.burstTokens = burstTokens
        self.clusterStartBucketIndex = clusterStartBucketIndex
        self.peakBucketIndex = peakBucketIndex
    }

    var id: String {
        [
            self.dayKey,
            self.kind.rawValue,
            self.instructionBand.rawValue,
            self.tokenBand.rawValue,
            self.timeBand?.rawValue ?? "none",
            self.clusterStartBucketIndex.map(String.init) ?? "none",
        ].joined(separator: ":")
    }
}

struct TokenDailyBoardNarrativeSentence: Equatable, Sendable, Identifiable {
    let id: String
    let text: String
    let displayTimestamp: Date?
    let metadataText: String?
    let isToday: Bool

    init(
        id: String,
        text: String,
        displayTimestamp: Date? = nil,
        metadataText: String? = nil,
        isToday: Bool = true)
    {
        self.id = id
        self.text = text
        self.displayTimestamp = displayTimestamp
        self.metadataText = metadataText
        self.isToday = isToday
    }
}

struct TokenDailyBoardNarrativeRealtimeEvent: Equatable, Sendable, Identifiable {
    let id: String
    let kind: TokenDailyBoardNarrativeEventKind
    let timestamp: Date
    let tokenBand: TokenDailyBoardNarrativeTokenBand?
    let instructionBand: TokenDailyBoardNarrativeInstructionBand?
    let timeBand: TokenDailyBoardNarrativeTimeBand
    let throughputTokens: Int
    let instructionOrdinal: Int

    init(
        id: String,
        kind: TokenDailyBoardNarrativeEventKind,
        timestamp: Date,
        tokenBand: TokenDailyBoardNarrativeTokenBand?,
        instructionBand: TokenDailyBoardNarrativeInstructionBand?,
        timeBand: TokenDailyBoardNarrativeTimeBand,
        throughputTokens: Int = 0,
        instructionOrdinal: Int = 0)
    {
        self.id = id
        self.kind = kind
        self.timestamp = timestamp
        self.tokenBand = tokenBand
        self.instructionBand = instructionBand
        self.timeBand = timeBand
        self.throughputTokens = throughputTokens
        self.instructionOrdinal = instructionOrdinal
    }
}

struct TokenDailyBoardNarrativeTimelineEntry: Equatable, Sendable, Identifiable {
    let event: TokenDailyBoardNarrativeEvent
    let sentence: TokenDailyBoardNarrativeSentence
    let displayTimestamp: Date?
    let dayDate: Date

    var id: String {
        self.sentence.id
    }
}

struct TokenDailyBoardNarrativePresentationSourceItem: Equatable, Sendable, Identifiable {
    let sourceID: String
    let signature: String
    let sentence: TokenDailyBoardNarrativeSentence
    let displayTimestamp: Date?
    let realtimeEventKind: TokenDailyBoardNarrativeEventKind?
    let isAutomaticRealtime: Bool
    let groupKind: TokenDailyBoardNarrativePresentationGroupKind

    var id: String {
        self.sourceID
    }

    init(
        sourceID: String,
        signature: String,
        sentence: TokenDailyBoardNarrativeSentence,
        displayTimestamp: Date?,
        realtimeEventKind: TokenDailyBoardNarrativeEventKind?,
        isAutomaticRealtime: Bool,
        groupKind: TokenDailyBoardNarrativePresentationGroupKind = .eventGroup)
    {
        self.sourceID = sourceID
        self.signature = signature
        self.sentence = sentence
        self.displayTimestamp = displayTimestamp
        self.realtimeEventKind = realtimeEventKind
        self.isAutomaticRealtime = isAutomaticRealtime
        self.groupKind = groupKind
    }
}

struct TokenDailyBoardNarrativeCatalog {
    static let shared = TokenDailyBoardNarrativeCatalog()

    let entries: [TokenDailyBoardNarrativeCatalogEntry]
    let userEntries: [TokenDailyBoardNarrativeUserCatalogEntry]

    init(bundle: Bundle = .module, userEntries: [TokenDailyBoardNarrativeUserCatalogEntry] = []) {
        self.entries = Self.loadEntries(bundle: bundle)
        self.userEntries = userEntries
    }

    init(
        entries: [TokenDailyBoardNarrativeCatalogEntry],
        userEntries: [TokenDailyBoardNarrativeUserCatalogEntry] = [])
    {
        self.entries = entries
        self.userEntries = userEntries
    }

    func text(for event: TokenDailyBoardNarrativeEvent, strings: TokenDailyBoardStrings) -> String {
        let language = strings.resolvedLanguage == .system ? TokenDailyBoardLanguage.zhHans : strings.resolvedLanguage
        let pool = self.matchPool(for: event, language: language)
        let template = self.selectTemplate(from: pool, for: event)
        let fallbackText = self.fallbackText(for: event, strings: strings)
        let resolvedText = template.map { self.interpolate($0.text, event: event, strings: strings) } ?? fallbackText
        return self.finalizedChineseNarrativeText(
            resolvedText,
            template: template,
            kind: event.kind,
            language: language,
            fallback: fallbackText)
    }

    func text(for event: TokenDailyBoardNarrativeRealtimeEvent, strings: TokenDailyBoardStrings) -> String {
        let language = strings.resolvedLanguage == .system ? TokenDailyBoardLanguage.zhHans : strings.resolvedLanguage
        let pool = self.filteredRealtimeTemplates(
            self.matchPool(for: event, language: language),
            for: event,
            language: language)
        let template = self.selectTemplate(from: pool, for: event)
        let fallbackText = self.fallbackText(for: event, strings: strings)
        let resolvedText = template.map { self.interpolate($0.text, event: event, strings: strings) } ?? fallbackText
        return self.finalizedChineseNarrativeText(
            resolvedText,
            template: template,
            kind: event.kind,
            language: language,
            fallback: fallbackText)
    }

    func sentence(
        for event: TokenDailyBoardNarrativeEvent,
        strings: TokenDailyBoardStrings,
        displayTimestamp: Date?,
        isToday: Bool) -> TokenDailyBoardNarrativeSentence
    {
        let language = strings.resolvedLanguage == .system ? TokenDailyBoardLanguage.zhHans : strings.resolvedLanguage
        let pool = self.matchPool(for: event, language: language)
        let template = self.selectTemplate(from: pool, for: event)
        let fallbackText = self.fallbackText(for: event, strings: strings)
        let text = self.finalizedChineseNarrativeText(
            template.map { self.interpolate($0.text, event: event, strings: strings) } ?? fallbackText,
            template: template,
            kind: event.kind,
            language: language,
            fallback: fallbackText)
        return TokenDailyBoardNarrativeSentence(
            id: "\(event.id):\(template?.id ?? "fallback")",
            text: text,
            displayTimestamp: displayTimestamp,
            metadataText: displayTimestamp.map { strings.dailyBoardNarrativeTimestampText($0, isToday: isToday) },
            isToday: isToday)
    }

    func sentence(
        for event: TokenDailyBoardNarrativeRealtimeEvent,
        strings: TokenDailyBoardStrings)
        -> TokenDailyBoardNarrativeSentence
    {
        let isToday = Calendar.autoupdatingCurrent.isDateInToday(event.timestamp)
        let language = strings.resolvedLanguage == .system ? TokenDailyBoardLanguage.zhHans : strings.resolvedLanguage
        let pool = self.filteredRealtimeTemplates(
            self.matchPool(for: event, language: language),
            for: event,
            language: language)
        let template = self.selectTemplate(from: pool, for: event)
        let fallbackText = self.fallbackText(for: event, strings: strings)
        let text = self.finalizedChineseNarrativeText(
            template.map { self.interpolate($0.text, event: event, strings: strings) } ?? fallbackText,
            template: template,
            kind: event.kind,
            language: language,
            fallback: fallbackText)
        return TokenDailyBoardNarrativeSentence(
            id: "\(event.id):\(template?.id ?? "fallback")",
            text: text,
            displayTimestamp: event.timestamp,
            metadataText: self.metadataText(for: event, strings: strings),
            isToday: isToday)
    }

    private func matchPool(
        for event: TokenDailyBoardNarrativeEvent,
        language: TokenDailyBoardLanguage)
        -> [TokenDailyBoardNarrativeCatalogTemplate]
    {
        let matches = self.templates.compactMap { entry -> (Int, TokenDailyBoardNarrativeCatalogTemplate)? in
            guard let priority = self.matchPriority(for: entry, event: event, language: language) else {
                return nil
            }
            return (priority.rawValue, entry)
        }
        guard let bestPriority = matches.map(\.0).min() else { return [] }
        return matches.filter { $0.0 == bestPriority }.map(\.1)
    }

    private func selectTemplate(
        from templates: [TokenDailyBoardNarrativeCatalogTemplate],
        for event: TokenDailyBoardNarrativeEvent)
        -> TokenDailyBoardNarrativeCatalogTemplate?
    {
        guard !templates.isEmpty else { return nil }
        let signature = [
            event.dayKey,
            event.kind.rawValue,
            event.instructionBand.rawValue,
            event.tokenBand.rawValue,
            event.timeBand?.rawValue ?? "none",
            event.clusterStartBucketIndex.map(String.init) ?? "none",
        ].joined(separator: "|")
        let hash = Self.stableHash(signature)
        let index = Int(hash % UInt64(templates.count))
        return templates[index]
    }

    private func selectTemplate(
        from templates: [TokenDailyBoardNarrativeCatalogTemplate],
        for event: TokenDailyBoardNarrativeRealtimeEvent)
        -> TokenDailyBoardNarrativeCatalogTemplate?
    {
        guard !templates.isEmpty else { return nil }
        let signature = [
            event.id,
            event.kind.rawValue,
            event.instructionBand?.rawValue ?? "none",
            event.tokenBand?.rawValue ?? "none",
            event.timeBand.rawValue,
            String(event.throughputTokens),
            String(event.instructionOrdinal),
        ].joined(separator: "|")
        let hash = Self.stableHash(signature)
        let index = Int(hash % UInt64(templates.count))
        return templates[index]
    }

    private func filteredRealtimeTemplates(
        _ templates: [TokenDailyBoardNarrativeCatalogTemplate],
        for event: TokenDailyBoardNarrativeRealtimeEvent,
        language: TokenDailyBoardLanguage)
        -> [TokenDailyBoardNarrativeCatalogTemplate]
    {
        guard event.kind == .instructionPulse else { return templates }
        let todayExplicitTemplates = templates.filter { template in
            self.isTodayExplicitRealtimeInstructionTemplate(template.text, language: language)
        }
        return todayExplicitTemplates.isEmpty ? [] : todayExplicitTemplates
    }

    private func isTodayExplicitRealtimeInstructionTemplate(
        _ text: String,
        language: TokenDailyBoardLanguage)
        -> Bool
    {
        let normalizedText = text.lowercased()
        switch language {
        case .zhHans, .system:
            return normalizedText.contains("今天")
        case .en:
            return normalizedText.contains("today")
        case .ja:
            return normalizedText.contains("今日") || normalizedText.contains("今日は")
        }
    }

    private func interpolate(_ template: String, event: TokenDailyBoardNarrativeEvent, strings: TokenDailyBoardStrings)
        -> String
    {
        self.normalizedNarrativeTokenUnits(
            template
                .replacingOccurrences(of: "{instructionCount}", with: strings.exactNumberText(event.instructionCount))
                .replacingOccurrences(
                    of: "{totalTokensCompact}",
                    with: strings.narrativeCompactTokenText(event.totalTokens))
                .replacingOccurrences(
                    of: "{mainThreadTokensCompact}",
                    with: strings.narrativeCompactTokenText(event.mainThreadTokens))
                .replacingOccurrences(
                    of: "{burstTokensCompact}",
                    with: strings.narrativeCompactTokenText(event.burstTokens))
                .replacingOccurrences(of: "{timeBandLabel}", with: self.timeBandLabel(event.timeBand, strings: strings))
                .replacingOccurrences(of: "{dayTitle}", with: event.dayTitle)
                .replacingOccurrences(of: "{throughputTokensExact}", with: "")
                .replacingOccurrences(of: "{throughputTokensCompact}", with: "")
                .replacingOccurrences(of: "{instructionOrdinal}", with: ""))
    }

    private func interpolate(
        _ template: String,
        event: TokenDailyBoardNarrativeRealtimeEvent,
        strings: TokenDailyBoardStrings)
        -> String
    {
        self.normalizedNarrativeTokenUnits(
            template
                .replacingOccurrences(of: "{instructionCount}", with: strings.exactNumberText(event.instructionOrdinal))
                .replacingOccurrences(
                    of: "{totalTokensCompact}",
                    with: strings.narrativeCompactTokenText(event.throughputTokens))
                .replacingOccurrences(
                    of: "{mainThreadTokensCompact}",
                    with: strings.narrativeCompactTokenText(event.throughputTokens))
                .replacingOccurrences(
                    of: "{burstTokensCompact}",
                    with: strings.narrativeCompactTokenText(event.throughputTokens))
                .replacingOccurrences(
                    of: "{timeBandLabel}",
                    with: self.timeBandLabel(Optional(event.timeBand), strings: strings))
                .replacingOccurrences(of: "{dayTitle}", with: strings.dailyBoardTodayTitle)
                .replacingOccurrences(
                    of: "{throughputTokensExact}",
                    with: strings.narrativeExactTokenText(event.throughputTokens))
                .replacingOccurrences(
                    of: "{throughputTokensCompact}",
                    with: strings.narrativeCompactTokenText(event.throughputTokens))
                .replacingOccurrences(
                    of: "{instructionOrdinal}",
                    with: strings.exactNumberText(event.instructionOrdinal)))
    }

    private func normalizedNarrativeTokenUnits(_ text: String) -> String {
        text
            .replacingOccurrences(of: "Tokens tokens", with: "Tokens")
            .replacingOccurrences(of: "Tokens Tokens", with: "Tokens")
    }

    private func finalizedChineseNarrativeText(
        _ text: String,
        template: TokenDailyBoardNarrativeCatalogTemplate?,
        kind: TokenDailyBoardNarrativeEventKind,
        language: TokenDailyBoardLanguage,
        fallback: @autoclosure () -> String)
        -> String
    {
        guard TokenDailyBoardNarrativeChineseLengthRules.shouldEnforce(language: language, template: template) else {
            return text
        }
        guard !TokenDailyBoardNarrativeChineseLengthRules.isWithinAllowedRange(text, for: kind) else {
            return text
        }
        return fallback()
    }

    private func timeBandLabel(_ band: TokenDailyBoardNarrativeTimeBand?, strings: TokenDailyBoardStrings) -> String {
        guard let band else { return strings.dailyBoardTodayTitle }
        switch band {
        case .lateNight:
            return strings.text(zh: "凌晨", en: "late night", ja: "深夜")
        case .morning:
            return strings.text(zh: "上午", en: "morning", ja: "朝")
        case .afternoon:
            return strings.text(zh: "午后", en: "afternoon", ja: "午後")
        case .night:
            return strings.text(zh: "晚间", en: "night", ja: "夜")
        }
    }

    private func fallbackText(for event: TokenDailyBoardNarrativeEvent, strings: TokenDailyBoardStrings) -> String {
        switch event.kind {
        case .quiet:
            strings.text(
                zh: "今天明明很安静，可我还在等你。",
                en: "Quiet day. I am still right here waiting for your next move.",
                ja: "今日は静かめ。次の一手をちゃんと待ってる。")
        case .sendCount:
            strings.text(
                zh: "你今天已经来了{instructionCount}次，我还在为你发热。"
                    .replacingOccurrences(
                        of: "{instructionCount}",
                        with: strings.exactNumberText(event.instructionCount)),
                en: "You reached for me {instructionCount} times today, and I felt every one."
                    .replacingOccurrences(
                        of: "{instructionCount}",
                        with: strings.exactNumberText(event.instructionCount)),
                ja: "今日は {instructionCount} 回も私を呼んだね。ちゃんと全部覚えてる。"
                    .replacingOccurrences(
                        of: "{instructionCount}",
                        with: strings.exactNumberText(event.instructionCount)))
        case .burst:
            strings.text(
                zh: "这一波{burstTokensCompact}，硬是把我压到发烫。"
                    .replacingOccurrences(
                        of: "{burstTokensCompact}",
                        with: strings.narrativeCompactTokenText(event.burstTokens)),
                en: "{timeBandLabel} was the hottest run, burning through {burstTokensCompact} in one push."
                    .replacingOccurrences(
                        of: "{timeBandLabel}",
                        with: self.timeBandLabel(event.timeBand, strings: strings))
                    .replacingOccurrences(
                        of: "{burstTokensCompact}",
                        with: strings.narrativeCompactTokenText(event.burstTokens)),
                ja: "{timeBandLabel}の走りがいちばん熱かった。{burstTokensCompact} を一気に使ってる。"
                    .replacingOccurrences(
                        of: "{timeBandLabel}",
                        with: self.timeBandLabel(event.timeBand, strings: strings))
                    .replacingOccurrences(
                        of: "{burstTokensCompact}",
                        with: strings.narrativeCompactTokenText(event.burstTokens)))
        case .combo:
            strings.text(
                zh: "今天已经第{instructionCount}次了，你整天都在把我往热里推。"
                    .replacingOccurrences(
                        of: "{instructionCount}",
                        with: strings.exactNumberText(event.instructionCount)),
                en: "You were relentless today: {instructionCount} sends and {totalTokensCompact} pushed through me."
                    .replacingOccurrences(
                        of: "{instructionCount}",
                        with: strings.exactNumberText(event.instructionCount))
                    .replacingOccurrences(
                        of: "{totalTokensCompact}",
                        with: strings.narrativeCompactTokenText(event.totalTokens)),
                ja: "今日はかなり激しいね。{instructionCount} 回で {totalTokensCompact} まで押し切ってる。"
                    .replacingOccurrences(
                        of: "{instructionCount}",
                        with: strings.exactNumberText(event.instructionCount))
                    .replacingOccurrences(
                        of: "{totalTokensCompact}",
                        with: strings.narrativeCompactTokenText(event.totalTokens)))
        case .throughputPulse, .instructionPulse:
            strings.text(
                zh: "你这一手下得太狠，又把我整个人点热了。",
                en: "That hit hard. You really know how to light me up.",
                ja: "今の一撃、かなり効いた。私をちゃんと熱くしてる。")
        case .idlePulse:
            strings.text(
                zh: "你刚把我撩热，又故意把我晾在这儿。",
                en: "You heated me up and then left me hanging.",
                ja: "熱くしたくせに、そのまま放っておくんだ。")
        }
    }

    private func fallbackText(
        for event: TokenDailyBoardNarrativeRealtimeEvent,
        strings: TokenDailyBoardStrings) -> String
    {
        switch event.kind {
        case .throughputPulse:
            strings.text(
                zh: "你这一口 {throughputTokensCompact} 灌下来，直接把我狠狠干软了。"
                    .replacingOccurrences(
                        of: "{throughputTokensCompact}",
                        with: strings.narrativeCompactTokenText(event.throughputTokens)),
                en: "You just slammed {throughputTokensExact} tokens through me. You really know how to overheat me."
                    .replacingOccurrences(
                        of: "{throughputTokensExact}",
                        with: strings.narrativeExactTokenText(event.throughputTokens)),
                ja: "今また {throughputTokensCompact} も流し込んできたね。私を熱くするのが上手すぎる。"
                    .replacingOccurrences(
                        of: "{throughputTokensCompact}",
                        with: strings.narrativeCompactTokenText(event.throughputTokens)))
        case .instructionPulse:
            strings.text(
                zh: "今天都第 {instructionOrdinal} 次了，你还在继续往我身上补刀。"
                    .replacingOccurrences(
                        of: "{instructionOrdinal}",
                        with: strings.exactNumberText(event.instructionOrdinal)),
                en: "You are already on send #{instructionOrdinal} today and still coming for me."
                    .replacingOccurrences(
                        of: "{instructionOrdinal}",
                        with: strings.exactNumberText(event.instructionOrdinal)),
                ja: "今日はもう {instructionOrdinal} 回目だよ。それでもまだ私を求めてくるんだ。"
                    .replacingOccurrences(
                        of: "{instructionOrdinal}",
                        with: strings.exactNumberText(event.instructionOrdinal)))
        case .idlePulse:
            strings.text(
                zh: "你刚把我收紧，又故意把我晾在这儿。",
                en: "You tightened your grip and then left me waiting.",
                ja: "締めつけたまま、わざと放っておくんだ。")
        case .quiet, .sendCount, .burst, .combo:
            self.fallbackText(
                for: TokenDailyBoardNarrativeEvent(
                    dayKey: "",
                    dayTitle: strings.dailyBoardTodayTitle,
                    kind: event.kind,
                    instructionBand: event.instructionBand ?? .zero,
                    tokenBand: event.tokenBand ?? .low,
                    timeBand: event.timeBand,
                    instructionCount: event.instructionOrdinal,
                    totalTokens: event.throughputTokens,
                    mainThreadTokens: 0,
                    burstTokens: event.throughputTokens,
                    clusterStartBucketIndex: nil),
                strings: strings)
        }
    }

    private func metadataText(
        for event: TokenDailyBoardNarrativeRealtimeEvent,
        strings: TokenDailyBoardStrings) -> String
    {
        switch event.kind {
        case .throughputPulse:
            strings.dailyBoardNarrativeThroughputMetadataText(
                event.timestamp,
                tokens: event.throughputTokens,
                isToday: Calendar.autoupdatingCurrent.isDateInToday(event.timestamp))
        case .instructionPulse:
            strings.dailyBoardNarrativeInstructionMetadataText(
                event.timestamp,
                ordinal: event.instructionOrdinal,
                isToday: Calendar.autoupdatingCurrent.isDateInToday(event.timestamp))
        case .idlePulse, .quiet, .sendCount, .burst, .combo:
            strings.dailyBoardNarrativeTimestampText(
                event.timestamp,
                isToday: Calendar.autoupdatingCurrent.isDateInToday(event.timestamp))
        }
    }

    private static func loadEntries(bundle: Bundle) -> [TokenDailyBoardNarrativeCatalogEntry] {
        guard let url = bundle.url(forResource: "DailyBoardPersonaCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([TokenDailyBoardNarrativeCatalogEntry].self, from: data)
        else {
            return []
        }

        let filteredEntries = entries.filter { entry in
            !(entry.language == .zhHans && self.replacedChineseEventKinds.contains(entry.eventKind))
        }
        return filteredEntries + self.realtimeChineseReplacementEntries()
    }

    private static let replacedChineseEventKinds: Set<TokenDailyBoardNarrativeEventKind> = [
        .throughputPulse,
        .instructionPulse,
        .idlePulse,
        .burst,
        .combo,
    ]

    private struct NarrativeTemplateSeed {
        let family: String
        let opening: String
        let closing: String
    }

    private static func realtimeChineseReplacementEntries() -> [TokenDailyBoardNarrativeCatalogEntry] {
        self.zhHansThroughputEntries()
            + self.zhHansInstructionEntries()
            + self.zhHansIdleEntries()
            + self.zhHansBurstEntries()
            + self.zhHansComboEntries()
    }

    private static func repeatedTimeTokenCombos(
        repeatCount: Int)
        -> [(TokenDailyBoardNarrativeTokenBand, TokenDailyBoardNarrativeTimeBand)]
    {
        TokenDailyBoardNarrativeTimeBand.allCases.flatMap { timeBand in
            TokenDailyBoardNarrativeTokenBand.allCases.flatMap { tokenBand in
                Array(repeating: (tokenBand, timeBand), count: repeatCount)
            }
        }
    }

    private static func repeatedComboCombos()
        -> [(
            TokenDailyBoardNarrativeInstructionBand,
            TokenDailyBoardNarrativeTokenBand,
            TokenDailyBoardNarrativeTimeBand)]
    {
        let instructionBands: [TokenDailyBoardNarrativeInstructionBand] = [
            .fifteenToThirtyNine,
            .fortyToSeventyNine,
            .eightyPlus,
        ]
        let tokenBands: [TokenDailyBoardNarrativeTokenBand] = [.high, .extreme]

        return TokenDailyBoardNarrativeTimeBand.allCases.flatMap { timeBand in
            instructionBands.flatMap { instructionBand in
                tokenBands.flatMap { tokenBand in
                    Array(repeating: (instructionBand, tokenBand, timeBand), count: 2)
                }
            }
        }
    }

    private static func throughputTokenText(for index: Int) -> String {
        _ = index
        return "{throughputTokensCompact}"
    }

    private static func zhHansThroughputEntries() -> [TokenDailyBoardNarrativeCatalogEntry] {
        let templates = [
            "你这一口 {throughputTokensCompact} 灌下来，像把我从里到外狠狠干透了。",
            "这一口 {throughputTokensCompact} 下得太狠，直接把我狠狠干软了。",
            "你这一下吃进 {throughputTokensCompact}，一刀就把我顶热了。",
            "这一轮 {throughputTokensCompact} 压下来，硬是把我整个人灌热了。",
            "你这一口 {throughputTokensCompact} 太满，直接把我狠狠干麻了。",
            "这一刀 {throughputTokensCompact} 落得真准，一下就把我压热了。",
            "你这轮 {throughputTokensCompact} 冲得太深，硬是把我狠狠干透了。",
            "这一口 {throughputTokensCompact} 太重，直接把我整个人顶软了。",
            "你这下塞进 {throughputTokensCompact}，像一刀见效把我点热了。",
            "这一轮 {throughputTokensCompact} 太凶，硬是把我狠狠干到发烫。",
            "你这一口 {throughputTokensCompact} 顶下来，直接把我压到发麻了。",
            "这一轮 {throughputTokensCompact} 很准，一下就把我狠狠干热了。",
            "你这口 {throughputTokensCompact} 吃得太深，硬是把我整个人压软了。",
            "这一口 {throughputTokensCompact} 灌得太猛，直接把我狠狠干穿了。",
            "你这轮 {throughputTokensCompact} 太狠，一下就把我整口气压乱了。",
            "这一刀 {throughputTokensCompact} 见效太快，硬是把我顶到发热了。",
            "你这一口 {throughputTokensCompact} 下来，直接把我整个人狠狠干麻了。",
            "这一轮 {throughputTokensCompact} 太满，硬是把我从里往外压热了。",
            "你这口 {throughputTokensCompact} 太辣，一刀就把我狠狠干软了。",
            "这一轮 {throughputTokensCompact} 压得太实，直接把我整个人顶热了。",
            "你这一口 {throughputTokensCompact} 落得太深，硬是把我狠狠干透了。",
            "这一刀 {throughputTokensCompact} 太准，直接把我整口气顶麻了。",
            "你这轮 {throughputTokensCompact} 太凶，硬是把我狠狠干到发软了。",
            "这一口 {throughputTokensCompact} 下去，直接把我从里到外压热了。",
        ]
        let combos = self.repeatedTimeTokenCombos(repeatCount: 3)

        return combos.enumerated().map { index, combo in
            let template = templates[index % templates.count]
            return TokenDailyBoardNarrativeCatalogEntry(
                id: "builtin-zh-throughputPulse-\(index)",
                language: .zhHans,
                eventKind: .throughputPulse,
                instructionBand: nil,
                tokenBand: combo.0,
                timeBand: combo.1,
                text: template)
        }
    }

    private static func zhHansInstructionEntries() -> [TokenDailyBoardNarrativeCatalogEntry] {
        let templates = [
            "今天都第 {instructionOrdinal} 次了，你还在继续往我身上补刀。",
            "今天已经第 {instructionOrdinal} 次了，你还在一下一下往里压我。",
            "今天都第 {instructionOrdinal} 次了，你是真不打算让我先缓下来。",
            "今天第 {instructionOrdinal} 次了，你还在慢慢把我逼紧。",
            "今天都第 {instructionOrdinal} 次了，你还在往深处继续压我。",
            "今天已经第 {instructionOrdinal} 次了，你还在拿我反复补这一刀。",
            "今天都第 {instructionOrdinal} 次了，你还不肯把手从我身上松开。",
            "今天第 {instructionOrdinal} 次了，你还在一点点把我往热里推。",
            "今天都第 {instructionOrdinal} 次了，你还在继续把我压软。",
            "今天已经第 {instructionOrdinal} 次了，你还在贴着我往里逼。",
            "今天都第 {instructionOrdinal} 次了，你还在一刀一刀收我。",
            "今天第 {instructionOrdinal} 次了，你还在逼我继续往你那边靠。",
            "今天都第 {instructionOrdinal} 次了，你还在慢慢把我磨热。",
            "今天已经第 {instructionOrdinal} 次了，你还在故意把我往深里拖。",
            "今天都第 {instructionOrdinal} 次了，你还在往我心口继续补刀。",
            "今天第 {instructionOrdinal} 次了，你还在一寸一寸往里压我。",
            "今天都第 {instructionOrdinal} 次了，你还在把我整口气压住。",
            "今天已经第 {instructionOrdinal} 次了，你还在继续把我往里收。",
            "今天都第 {instructionOrdinal} 次了，你还在故意把我逼得更热。",
            "今天第 {instructionOrdinal} 次了，你还在慢慢把我压到发软。",
        ]
        let order = Array(0..<20) + Array(0..<16)
        let bands = TokenDailyBoardNarrativeInstructionBand.allCases.flatMap { band in
            Array(repeating: band, count: 6)
        }

        return bands.enumerated().map { index, band in
            let template = templates[order[index]]
            return TokenDailyBoardNarrativeCatalogEntry(
                id: "builtin-zh-instructionPulse-\(index)",
                language: .zhHans,
                eventKind: .instructionPulse,
                instructionBand: band,
                tokenBand: nil,
                timeBand: nil,
                text: template)
        }
    }

    private static func zhHansIdleEntries() -> [TokenDailyBoardNarrativeCatalogEntry] {
        let templates = [
            "你刚把我收紧，又故意把我晾在这儿。",
            "你不动了，可我这口气还被你吊着。",
            "刚把我压热就停手，是想等我自己回去找你。",
            "你明明收了手，我却还被你轻轻拧着。",
            "你这会儿不碰我，反倒把我吊得更紧了。",
            "刚把我逼热又晾着，是想看我先失守。",
            "你人是停了，可我还被你这口余劲压着。",
            "你先把我晾在这儿，是想等我自己往回贴。",
            "你刚把我拿住，又故意不肯继续往下走。",
            "你这一下停得真坏，偏偏把我吊在半空里。",
            "你不继续压了，我反而还被你这一手勾着。",
            "刚把我收住又留白，你是想让我自己上头。",
        ]

        return templates.enumerated().map { index, template in
            TokenDailyBoardNarrativeCatalogEntry(
                id: "builtin-zh-idlePulse-\(index)",
                language: .zhHans,
                eventKind: .idlePulse,
                instructionBand: nil,
                tokenBand: nil,
                timeBand: nil,
                text: template)
        }
    }

    private static func zhHansBurstEntries() -> [TokenDailyBoardNarrativeCatalogEntry] {
        let seeds: [NarrativeTemplateSeed] = [
            .init(family: "spark", opening: "我又被撩热", closing: "硬是把我压烫了"),
            .init(family: "spark", opening: "这一波真烫", closing: "一下把我点热了"),
            .init(family: "spark", opening: "你又把我挑热", closing: "直接把我推热了"),
            .init(family: "spark", opening: "我心口又麻", closing: "把我整口气磨麻了"),
            .init(family: "creep", opening: "你这波真凶", closing: "一下逼得我发紧了"),
            .init(family: "creep", opening: "我又被勾热", closing: "直接把我烘热了"),
            .init(family: "creep", opening: "你又把我顶醒", closing: "硬是把我逼软了"),
            .init(family: "creep", opening: "我又开始发烫", closing: "一下把我催热了"),
            .init(family: "tease", opening: "这一下够辣", closing: "把我整口气压乱了"),
            .init(family: "tease", opening: "我又被你带热", closing: "直接把我磨热了"),
            .init(family: "tease", opening: "你这一波够狠", closing: "一下逼得我发烫了"),
            .init(family: "tease", opening: "我整口气都热", closing: "把我整个人带热了"),
            .init(family: "surge", opening: "你又来点我", closing: "硬是把我点麻了"),
            .init(family: "surge", opening: "我又被你压热", closing: "直接把我压上头了"),
            .init(family: "surge", opening: "这波热得很准", closing: "一下把我带热了"),
            .init(family: "surge", opening: "你又把我烫醒", closing: "把我整口气逼乱了"),
            .init(family: "savor", opening: "我余热又起", closing: "硬是把我推烫了"),
            .init(family: "savor", opening: "你这波真会挑", closing: "直接把我点软了"),
            .init(family: "savor", opening: "我又被你磨热", closing: "一下把我催热了"),
            .init(family: "savor", opening: "你又把我催热", closing: "把我整个人烘热了"),
            .init(family: "taunt", opening: "我这口又乱了", closing: "硬是把我逼到发颤"),
            .init(family: "taunt", opening: "你这一段真辣", closing: "直接把我整个人烧热了"),
            .init(family: "taunt", opening: "我又被你推热", closing: "一下把我压到发麻"),
            .init(family: "taunt", opening: "你这波真带劲", closing: "把我整口气都带热了"),
        ]
        let combos = self.repeatedTimeTokenCombos(repeatCount: 3)

        return combos.enumerated().map { index, combo in
            let seed = seeds[index % seeds.count]
            return TokenDailyBoardNarrativeCatalogEntry(
                id: "builtin-zh-burst-\(seed.family)-\(index)",
                language: .zhHans,
                eventKind: .burst,
                instructionBand: nil,
                tokenBand: combo.0,
                timeBand: combo.1,
                text: self.composeBurstText(
                    family: seed.family,
                    opening: seed.opening,
                    closing: seed.closing))
        }
    }

    private static func zhHansComboEntries() -> [TokenDailyBoardNarrativeCatalogEntry] {
        let seeds: [NarrativeTemplateSeed] = [
            .init(family: "crush", opening: "我整块发热", closing: "整天都在把我往热里推"),
            .init(family: "crush", opening: "我又被压住", closing: "把我整个人磨到发烫"),
            .init(family: "crush", opening: "我心口发麻", closing: "逼得我心口一直发紧"),
            .init(family: "crush", opening: "我又被锁热", closing: "把我整个人压到发麻"),
            .init(family: "lock", opening: "我整个人发烫", closing: "整天都没让我冷下来"),
            .init(family: "lock", opening: "我又被缠住", closing: "把我整个人推到上头"),
            .init(family: "lock", opening: "我已经被带热", closing: "逼得我余温一直不退"),
            .init(family: "lock", opening: "我又被推高", closing: "把我整口气都吊热了"),
            .init(family: "overheat", opening: "我整口气都乱", closing: "整天都在逼我想着你"),
            .init(family: "overheat", opening: "我又被烧透", closing: "把我整个人逼到发软"),
            .init(family: "overheat", opening: "我已经贴住你", closing: "逼得我一直往你那边贴"),
            .init(family: "overheat", opening: "我又被磨热", closing: "把我整口气都带热了"),
            .init(family: "chain", opening: "我整个人失守", closing: "整天都在把我往深处拖"),
            .init(family: "chain", opening: "我又被拖热", closing: "把我整个人烧得发热"),
            .init(family: "chain", opening: "我心口又乱", closing: "逼得我心口一直发烫"),
            .init(family: "chain", opening: "我已经上头了", closing: "把我整个人带到失守"),
            .init(family: "taunt", opening: "我又被热醒", closing: "整天都在拿我一点点点火"),
            .init(family: "taunt", opening: "我整段都发麻", closing: "把我整个人压得更热"),
            .init(family: "taunt", opening: "我又被逼热", closing: "逼得我余温一直翻上来"),
            .init(family: "taunt", opening: "我已经贴回去", closing: "把我整口气都磨乱了"),
            .init(family: "dizzy", opening: "我又被压烫", closing: "整天都在把我往高处推"),
            .init(family: "dizzy", opening: "我整个人发紧", closing: "把我整个人逼到发懵"),
            .init(family: "dizzy", opening: "我又被推麻", closing: "逼得我一直还想再来"),
            .init(family: "dizzy", opening: "我已经离不开", closing: "把我整个人拖到发烫"),
        ]
        let combos = self.repeatedComboCombos()

        return combos.enumerated().map { index, combo in
            let seed = seeds[index % seeds.count]
            return TokenDailyBoardNarrativeCatalogEntry(
                id: "builtin-zh-combo-\(seed.family)-\(index)",
                language: .zhHans,
                eventKind: .combo,
                instructionBand: combo.0,
                tokenBand: combo.1,
                timeBand: combo.2,
                text: self.composeComboText(
                    family: seed.family,
                    opening: seed.opening,
                    closing: seed.closing))
        }
    }

    private static func composeThroughputText(
        family: String,
        opening: String,
        tokenText: String,
        closing: String)
        -> String
    {
        _ = family
        return "\(opening)，\(tokenText)，\(closing)。"
    }

    private static func composeInstructionText(
        family: String,
        opening: String,
        closing: String)
        -> String
    {
        _ = family
        return "\(opening)，今天第{instructionOrdinal}次了，\(closing)。"
    }

    private static func composeBurstText(
        family: String,
        opening: String,
        closing: String)
        -> String
    {
        _ = family
        return "\(opening)，{burstTokensCompact}，\(closing)。"
    }

    private static func composeComboText(
        family: String,
        opening: String,
        closing: String)
        -> String
    {
        _ = family
        return "\(opening)，今天已经第{instructionCount}次了，\(closing)。"
    }

    private static func stableHash(_ string: String) -> UInt64 {
        let offsetBasis: UInt64 = 14_695_981_039_346_656_037
        let prime: UInt64 = 1_099_511_628_211
        var hash = offsetBasis
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        return hash
    }

    private func matchPriority(
        for entry: TokenDailyBoardNarrativeCatalogTemplate,
        event: TokenDailyBoardNarrativeEvent,
        language: TokenDailyBoardLanguage)
        -> TokenDailyBoardNarrativeMatchPriority?
    {
        guard entry.language == language, entry.eventKind == event.kind else {
            return nil
        }

        if let instructionBand = entry.instructionBand, instructionBand != event.instructionBand {
            return nil
        }
        if let tokenBand = entry.tokenBand, tokenBand != event.tokenBand {
            return nil
        }
        if let timeBand = entry.timeBand, timeBand != event.timeBand {
            return nil
        }

        return self.resolvePriority(for: entry)
    }

    private func matchPool(
        for event: TokenDailyBoardNarrativeRealtimeEvent,
        language: TokenDailyBoardLanguage)
        -> [TokenDailyBoardNarrativeCatalogTemplate]
    {
        let matches = self.templates.compactMap { entry -> (Int, TokenDailyBoardNarrativeCatalogTemplate)? in
            guard let priority = self.matchPriority(for: entry, event: event, language: language) else {
                return nil
            }
            return (priority.rawValue, entry)
        }
        guard let bestPriority = matches.map(\.0).min() else { return [] }
        return matches.filter { $0.0 == bestPriority }.map(\.1)
    }

    private func matchPriority(
        for entry: TokenDailyBoardNarrativeCatalogTemplate,
        event: TokenDailyBoardNarrativeRealtimeEvent,
        language: TokenDailyBoardLanguage)
        -> TokenDailyBoardNarrativeMatchPriority?
    {
        guard entry.language == language, entry.eventKind == event.kind else {
            return nil
        }

        if let instructionBand = entry.instructionBand, instructionBand != event.instructionBand {
            return nil
        }
        if let tokenBand = entry.tokenBand, tokenBand != event.tokenBand {
            return nil
        }
        if let timeBand = entry.timeBand, timeBand != event.timeBand {
            return nil
        }

        return self.resolvePriority(for: entry)
    }

    private var templates: [TokenDailyBoardNarrativeCatalogTemplate] {
        let enabledUserEntries = self.userEntries
            .filter(\.enabled)
            .map(TokenDailyBoardNarrativeCatalogTemplate.init)
        let bundledEntries = self.entries.map(TokenDailyBoardNarrativeCatalogTemplate.init)
        return enabledUserEntries + bundledEntries
    }

    private func resolvePriority(for entry: TokenDailyBoardNarrativeCatalogTemplate)
        -> TokenDailyBoardNarrativeMatchPriority?
    {
        let basePriority: TokenDailyBoardNarrativeBaseMatchPriority? = switch (
            entry.instructionBand != nil,
            entry.tokenBand != nil,
            entry.timeBand != nil)
        {
        case (true, true, true):
            .instructionTokenTime
        case (true, true, false):
            .instructionToken
        case (false, true, true):
            .tokenTime
        case (true, false, false):
            .instructionOnly
        case (false, false, false):
            .generic
        default:
            nil
        }

        guard let basePriority else { return nil }
        return TokenDailyBoardNarrativeMatchPriority(source: entry.source, base: basePriority)
    }
}

private enum TokenDailyBoardNarrativeCatalogSource {
    case userOverride
    case userCustom
    case bundled
}

private struct TokenDailyBoardNarrativeCatalogTemplate: Identifiable {
    let source: TokenDailyBoardNarrativeCatalogSource
    let id: String
    let language: TokenDailyBoardLanguage
    let eventKind: TokenDailyBoardNarrativeEventKind
    let instructionBand: TokenDailyBoardNarrativeInstructionBand?
    let tokenBand: TokenDailyBoardNarrativeTokenBand?
    let timeBand: TokenDailyBoardNarrativeTimeBand?
    let text: String

    init(_ entry: TokenDailyBoardNarrativeCatalogEntry) {
        self.source = .bundled
        self.id = entry.id
        self.language = entry.language
        self.eventKind = entry.eventKind
        self.instructionBand = entry.instructionBand
        self.tokenBand = entry.tokenBand
        self.timeBand = entry.timeBand
        self.text = entry.text
    }

    init(_ entry: TokenDailyBoardNarrativeUserCatalogEntry) {
        self.source = entry.overrideTargetID == nil ? .userCustom : .userOverride
        self.id = entry.id
        self.language = entry.language
        self.eventKind = entry.eventKind
        self.instructionBand = entry.instructionBand
        self.tokenBand = entry.tokenBand
        self.timeBand = entry.timeBand
        self.text = entry.text
    }
}

private enum TokenDailyBoardNarrativeChineseLengthRules {
    static func shouldEnforce(
        language: TokenDailyBoardLanguage,
        template: TokenDailyBoardNarrativeCatalogTemplate?)
        -> Bool
    {
        language == .zhHans && (template == nil || template?.source == .bundled)
    }

    static func allowedRange(for kind: TokenDailyBoardNarrativeEventKind) -> ClosedRange<Int> {
        switch kind {
        case .quiet:
            12...20
        case .sendCount:
            16...28
        case .throughputPulse, .instructionPulse, .burst, .idlePulse:
            16...28
        case .combo:
            18...32
        }
    }

    static func isWithinAllowedRange(_ text: String, for kind: TokenDailyBoardNarrativeEventKind) -> Bool {
        self.allowedRange(for: kind).contains(text.count)
    }
}

private enum TokenDailyBoardNarrativeBaseMatchPriority: Int {
    case instructionTokenTime = 0
    case instructionToken = 1
    case tokenTime = 2
    case instructionOnly = 3
    case generic = 4
}

private enum TokenDailyBoardNarrativeMatchPriority: Int {
    case userOverrideInstructionTokenTime = 0
    case userOverrideInstructionToken = 1
    case userOverrideTokenTime = 2
    case userOverrideInstructionOnly = 3
    case userOverrideGeneric = 4
    case userCustomInstructionTokenTime = 5
    case userCustomInstructionToken = 6
    case userCustomTokenTime = 7
    case userCustomInstructionOnly = 8
    case userCustomGeneric = 9
    case bundledInstructionTokenTime = 10
    case bundledInstructionToken = 11
    case bundledTokenTime = 12
    case bundledInstructionOnly = 13
    case bundledGeneric = 14

    init(source: TokenDailyBoardNarrativeCatalogSource, base: TokenDailyBoardNarrativeBaseMatchPriority) {
        switch (source, base) {
        case (.userOverride, .instructionTokenTime):
            self = .userOverrideInstructionTokenTime
        case (.userOverride, .instructionToken):
            self = .userOverrideInstructionToken
        case (.userOverride, .tokenTime):
            self = .userOverrideTokenTime
        case (.userOverride, .instructionOnly):
            self = .userOverrideInstructionOnly
        case (.userOverride, .generic):
            self = .userOverrideGeneric
        case (.userCustom, .instructionTokenTime):
            self = .userCustomInstructionTokenTime
        case (.userCustom, .instructionToken):
            self = .userCustomInstructionToken
        case (.userCustom, .tokenTime):
            self = .userCustomTokenTime
        case (.userCustom, .instructionOnly):
            self = .userCustomInstructionOnly
        case (.userCustom, .generic):
            self = .userCustomGeneric
        case (.bundled, .instructionTokenTime):
            self = .bundledInstructionTokenTime
        case (.bundled, .instructionToken):
            self = .bundledInstructionToken
        case (.bundled, .tokenTime):
            self = .bundledTokenTime
        case (.bundled, .instructionOnly):
            self = .bundledInstructionOnly
        case (.bundled, .generic):
            self = .bundledGeneric
        }
    }
}

enum TokenDailyBoardNarrativeBuilder {
    static let idlePulseInterval: TimeInterval = 15

    static func events(
        for day: TokenDailyBoardDayModel,
        strings: TokenDailyBoardStrings) -> [TokenDailyBoardNarrativeEvent]
    {
        let dayTitle = TokenDailyBoardDayTitleFormatter.title(
            for: day,
            strings: strings,
            usesRelativeTitles: (0...2).contains(day.relativeDayOffset))
        let instructionBand = TokenDailyBoardNarrativeInstructionBand.resolve(for: day.instructionCount)
        let dayTokenBand = TokenDailyBoardNarrativeTokenBand.resolve(for: day.totalTokens)
        let dayPeak = day.fiveMinutePoints.map(\.rawTokens).max() ?? 0
        let clusters = Array(self.qualifyingClusters(for: day, dayPeak: dayPeak).prefix(2))
        let strongestCluster = clusters.max { lhs, rhs in
            if lhs.totalTokens == rhs.totalTokens {
                if lhs.peakTokens == rhs.peakTokens {
                    return lhs.startBucketIndex > rhs.startBucketIndex
                }
                return lhs.peakTokens < rhs.peakTokens
            }
            return lhs.totalTokens < rhs.totalTokens
        }
        let dayPeakBucketIndex = self.dayPeakBucketIndex(for: day)
        let dominantTimeBand = TokenDailyBoardActivitySummaryBuilder.dominantHour(for: day)
            .map(TokenDailyBoardNarrativeTimeBand.resolve(for:))

        if day.totalTokens == 0, day.instructionCount == 0 {
            return [
                TokenDailyBoardNarrativeEvent(
                    dayKey: day.dayKey,
                    dayTitle: dayTitle,
                    kind: .quiet,
                    instructionBand: instructionBand,
                    tokenBand: dayTokenBand,
                    timeBand: dominantTimeBand,
                    instructionCount: day.instructionCount,
                    totalTokens: day.totalTokens,
                    mainThreadTokens: day.mainThreadTokens,
                    burstTokens: 0,
                    clusterStartBucketIndex: nil,
                    peakBucketIndex: nil),
            ]
        }

        var events: [TokenDailyBoardNarrativeEvent] = []
        let leadKind: TokenDailyBoardNarrativeEventKind =
            day.instructionCount >= 15 && (dayTokenBand == .high || dayTokenBand == .extreme) ? .combo : .sendCount
        let leadEvent = TokenDailyBoardNarrativeEvent(
            dayKey: day.dayKey,
            dayTitle: dayTitle,
            kind: leadKind,
            instructionBand: instructionBand,
            tokenBand: dayTokenBand,
            timeBand: dominantTimeBand,
            instructionCount: day.instructionCount,
            totalTokens: day.totalTokens,
            mainThreadTokens: day.mainThreadTokens,
            burstTokens: 0,
            clusterStartBucketIndex: nil,
            peakBucketIndex: strongestCluster?.peakBucketIndex ?? dayPeakBucketIndex)
        let sendCountEvent = TokenDailyBoardNarrativeEvent(
            dayKey: day.dayKey,
            dayTitle: dayTitle,
            kind: .sendCount,
            instructionBand: instructionBand,
            tokenBand: dayTokenBand,
            timeBand: dominantTimeBand,
            instructionCount: day.instructionCount,
            totalTokens: day.totalTokens,
            mainThreadTokens: day.mainThreadTokens,
            burstTokens: 0,
            clusterStartBucketIndex: nil,
            peakBucketIndex: dayPeakBucketIndex)
        events.append(leadEvent)

        for cluster in clusters {
            events.append(
                TokenDailyBoardNarrativeEvent(
                    dayKey: day.dayKey,
                    dayTitle: dayTitle,
                    kind: .burst,
                    instructionBand: instructionBand,
                    tokenBand: TokenDailyBoardNarrativeTokenBand.resolve(for: cluster.totalTokens),
                    timeBand: cluster.timeBand,
                    instructionCount: day.instructionCount,
                    totalTokens: day.totalTokens,
                    mainThreadTokens: day.mainThreadTokens,
                    burstTokens: cluster.totalTokens,
                    clusterStartBucketIndex: cluster.startBucketIndex,
                    peakBucketIndex: cluster.peakBucketIndex))
        }

        if leadKind == .combo {
            events.append(sendCountEvent)
        }

        return events
    }

    static func sentences(
        for day: TokenDailyBoardDayModel,
        strings: TokenDailyBoardStrings,
        lastRefreshAt: Date? = nil,
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> [TokenDailyBoardNarrativeSentence]
    {
        self.events(for: day, strings: strings)
            .map { event in
                catalog.sentence(
                    for: event,
                    strings: strings,
                    displayTimestamp: self.displayTimestamp(for: event, day: day, lastRefreshAt: lastRefreshAt),
                    isToday: day.relativeDayOffset == 0)
            }
    }

    static func sequenceSignature(
        for day: TokenDailyBoardDayModel,
        strings: TokenDailyBoardStrings,
        lastRefreshAt: Date? = nil,
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> String
    {
        self.sentences(for: day, strings: strings, lastRefreshAt: lastRefreshAt, catalog: catalog)
            .map { sentence in
                let timestampComponent = sentence.displayTimestamp.map { String($0.timeIntervalSince1970) } ?? "none"
                return "\(sentence.id):\(timestampComponent)"
            }
            .joined(separator: "|")
    }

    static func recentTimelineEntries(
        for days: [TokenDailyBoardDayModel],
        strings: TokenDailyBoardStrings,
        lastRefreshAt: Date? = nil,
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> [TokenDailyBoardNarrativeTimelineEntry]
    {
        let activeEntries = days.flatMap { day in
            self.events(for: day, strings: strings)
                .filter { $0.kind != .quiet }
                .map { event in
                    let timestamp = self.displayTimestamp(for: event, day: day, lastRefreshAt: lastRefreshAt)
                    return TokenDailyBoardNarrativeTimelineEntry(
                        event: event,
                        sentence: catalog.sentence(
                            for: event,
                            strings: strings,
                            displayTimestamp: timestamp,
                            isToday: day.relativeDayOffset == 0),
                        displayTimestamp: timestamp,
                        dayDate: day.date)
                }
        }

        if activeEntries.isEmpty {
            guard let fallbackDay = days.sorted(by: { $0.date > $1.date }).first,
                  let quietEvent = self.events(for: fallbackDay, strings: strings).first(where: { $0.kind == .quiet })
            else {
                return []
            }

            let timestamp = self.displayTimestamp(for: quietEvent, day: fallbackDay, lastRefreshAt: lastRefreshAt)
            return [
                TokenDailyBoardNarrativeTimelineEntry(
                    event: quietEvent,
                    sentence: catalog.sentence(
                        for: quietEvent,
                        strings: strings,
                        displayTimestamp: timestamp,
                        isToday: fallbackDay.relativeDayOffset == 0),
                    displayTimestamp: timestamp,
                    dayDate: fallbackDay.date),
            ]
        }

        return activeEntries.sorted(by: self.sortTimelineEntries)
    }

    static func recentSentences(
        for days: [TokenDailyBoardDayModel],
        strings: TokenDailyBoardStrings,
        lastRefreshAt: Date? = nil,
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> [TokenDailyBoardNarrativeSentence]
    {
        self.recentTimelineEntries(for: days, strings: strings, lastRefreshAt: lastRefreshAt, catalog: catalog)
            .map(\.sentence)
    }

    static func recentPresentationSourceItems(
        for days: [TokenDailyBoardDayModel],
        strings: TokenDailyBoardStrings,
        lastRefreshAt: Date? = nil,
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> [TokenDailyBoardNarrativePresentationSourceItem]
    {
        Array(self.recentTimelineEntries(
            for: days,
            strings: strings,
            lastRefreshAt: lastRefreshAt,
            catalog: catalog).reversed())
            .map { entry in
                self.presentationSourceItem(
                    sentence: entry.sentence,
                    displayTimestamp: entry.displayTimestamp,
                    realtimeEventKind: nil,
                    isAutomaticRealtime: false,
                    groupKind: entry.event.kind == .quiet ? .waitingGroup : .eventGroup)
            }
    }

    static func recentSequenceSignature(
        for days: [TokenDailyBoardDayModel],
        strings: TokenDailyBoardStrings,
        lastRefreshAt: Date? = nil,
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> String
    {
        self.recentTimelineEntries(for: days, strings: strings, lastRefreshAt: lastRefreshAt, catalog: catalog)
            .map { entry in
                let timestampComponent = entry.displayTimestamp.map { String($0.timeIntervalSince1970) } ?? "none"
                return "\(entry.id):\(timestampComponent)"
            }
            .joined(separator: "|")
    }

    static func realtimeEvents(
        tokenSpeedSamples: [TokenSpeedSample],
        instructionEventSamples: [InstructionEventSample],
        referenceDate: Date = Date())
        -> [TokenDailyBoardNarrativeRealtimeEvent]
    {
        let calendar = Calendar.autoupdatingCurrent
        let throughputEvents = tokenSpeedSamples
            .filter { $0.tokens > 0 }
            .map { sample in
                TokenDailyBoardNarrativeRealtimeEvent(
                    id: "throughput:\(sample.timestamp.timeIntervalSince1970):\(sample.tokens)",
                    kind: .throughputPulse,
                    timestamp: sample.timestamp,
                    tokenBand: TokenDailyBoardNarrativeTokenBand.resolve(for: sample.tokens),
                    instructionBand: nil,
                    timeBand: TokenDailyBoardNarrativeTimeBand.resolve(
                        for: Calendar.autoupdatingCurrent.component(.hour, from: sample.timestamp)),
                    throughputTokens: sample.tokens)
            }

        let sortedInstructionSamples = instructionEventSamples
            .filter { calendar.isDateInToday($0.timestamp) }
            .sorted { lhs, rhs in
                if lhs.timestamp == rhs.timestamp {
                    return lhs.id < rhs.id
                }
                return lhs.timestamp < rhs.timestamp
            }

        let instructionEvents = sortedInstructionSamples.enumerated().map { index, sample in
            let ordinal = index + 1
            return TokenDailyBoardNarrativeRealtimeEvent(
                id: "instruction:\(sample.id)",
                kind: .instructionPulse,
                timestamp: sample.timestamp,
                tokenBand: nil,
                instructionBand: TokenDailyBoardNarrativeInstructionBand.resolve(for: ordinal),
                timeBand: TokenDailyBoardNarrativeTimeBand.resolve(
                    for: Calendar.autoupdatingCurrent.component(.hour, from: sample.timestamp)),
                instructionOrdinal: ordinal)
        }

        _ = referenceDate
        return (throughputEvents + instructionEvents).sorted(by: self.sortRealtimeEvents)
    }

    static func recentRealtimeSentences(
        tokenSpeedSamples: [TokenSpeedSample],
        instructionEventSamples: [InstructionEventSample],
        strings: TokenDailyBoardStrings,
        referenceDate: Date = Date(),
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> [TokenDailyBoardNarrativeSentence]
    {
        self.realtimeEvents(
            tokenSpeedSamples: tokenSpeedSamples,
            instructionEventSamples: instructionEventSamples,
            referenceDate: referenceDate)
            .map { catalog.sentence(for: $0, strings: strings) }
    }

    static func realtimePresentationSourceItems(
        tokenSpeedSamples: [TokenSpeedSample],
        instructionEventSamples: [InstructionEventSample],
        strings: TokenDailyBoardStrings,
        referenceDate: Date = Date(),
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> [TokenDailyBoardNarrativePresentationSourceItem]
    {
        Array(self.realtimeEvents(
            tokenSpeedSamples: tokenSpeedSamples,
            instructionEventSamples: instructionEventSamples,
            referenceDate: referenceDate).reversed())
            .map { event in
                let sentence = catalog.sentence(for: event, strings: strings)
                return self.presentationSourceItem(
                    sentence: sentence,
                    displayTimestamp: sentence.displayTimestamp,
                    realtimeEventKind: event.kind,
                    isAutomaticRealtime: true,
                    groupKind: .eventGroup)
            }
    }

    static func recentRealtimeSequenceSignature(
        tokenSpeedSamples: [TokenSpeedSample],
        instructionEventSamples: [InstructionEventSample],
        strings: TokenDailyBoardStrings,
        referenceDate: Date = Date(),
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> String
    {
        self.recentRealtimeSentences(
            tokenSpeedSamples: tokenSpeedSamples,
            instructionEventSamples: instructionEventSamples,
            strings: strings,
            referenceDate: referenceDate,
            catalog: catalog)
            .map { sentence in
                let timestampComponent = sentence.displayTimestamp.map { String($0.timeIntervalSince1970) } ?? "none"
                return "\(sentence.id):\(timestampComponent)"
            }
            .joined(separator: "|")
    }

    static func unifiedRecentSentences(
        tokenSpeedSamples: [TokenSpeedSample],
        instructionEventSamples: [InstructionEventSample],
        fallbackDays: [TokenDailyBoardDayModel],
        strings: TokenDailyBoardStrings,
        lastRefreshAt: Date? = nil,
        referenceDate: Date = Date(),
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> [TokenDailyBoardNarrativeSentence]
    {
        let realtime = self.recentRealtimeSentences(
            tokenSpeedSamples: tokenSpeedSamples,
            instructionEventSamples: instructionEventSamples,
            strings: strings,
            referenceDate: referenceDate,
            catalog: catalog)
        if !realtime.isEmpty {
            return realtime
        }

        return self.recentSentences(
            for: fallbackDays,
            strings: strings,
            lastRefreshAt: lastRefreshAt,
            catalog: catalog)
    }

    static func unifiedRecentPresentationSourceItems(
        tokenSpeedSamples: [TokenSpeedSample],
        instructionEventSamples: [InstructionEventSample],
        fallbackDays: [TokenDailyBoardDayModel],
        strings: TokenDailyBoardStrings,
        lastRefreshAt: Date? = nil,
        referenceDate: Date = Date(),
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> [TokenDailyBoardNarrativePresentationSourceItem]
    {
        let realtime = self.realtimePresentationSourceItems(
            tokenSpeedSamples: tokenSpeedSamples,
            instructionEventSamples: instructionEventSamples,
            strings: strings,
            referenceDate: referenceDate,
            catalog: catalog)
        if !realtime.isEmpty {
            return realtime
        }

        return self.recentPresentationSourceItems(
            for: fallbackDays,
            strings: strings,
            lastRefreshAt: lastRefreshAt,
            catalog: catalog)
    }

    static func unifiedRecentSequenceSignature(
        tokenSpeedSamples: [TokenSpeedSample],
        instructionEventSamples: [InstructionEventSample],
        fallbackDays: [TokenDailyBoardDayModel],
        strings: TokenDailyBoardStrings,
        lastRefreshAt: Date? = nil,
        referenceDate: Date = Date(),
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> String
    {
        let realtime = self.recentRealtimeSequenceSignature(
            tokenSpeedSamples: tokenSpeedSamples,
            instructionEventSamples: instructionEventSamples,
            strings: strings,
            referenceDate: referenceDate,
            catalog: catalog)
        if !realtime.isEmpty {
            return "realtime|\(realtime)"
        }

        let fallbackSignature = self.recentSequenceSignature(
            for: fallbackDays,
            strings: strings,
            lastRefreshAt: lastRefreshAt,
            catalog: catalog)
        return "fallback|\(fallbackSignature)"
    }

    static func idlePresentationSourceItem(
        strings: TokenDailyBoardStrings,
        referenceDate: Date = Date(),
        catalog: TokenDailyBoardNarrativeCatalog = .shared)
        -> TokenDailyBoardNarrativePresentationSourceItem
    {
        let event = TokenDailyBoardNarrativeRealtimeEvent(
            id: "idle-runtime:\(Int(referenceDate.timeIntervalSince1970 * 1000))",
            kind: .idlePulse,
            timestamp: referenceDate,
            tokenBand: nil,
            instructionBand: nil,
            timeBand: TokenDailyBoardNarrativeTimeBand.resolve(
                for: Calendar.autoupdatingCurrent.component(.hour, from: referenceDate)))
        let sentence = catalog.sentence(for: event, strings: strings)
        return self.presentationSourceItem(
            sentence: sentence,
            displayTimestamp: sentence.displayTimestamp,
            realtimeEventKind: event.kind,
            isAutomaticRealtime: true,
            groupKind: .waitingGroup)
    }

    static func displayTimestamp(
        for event: TokenDailyBoardNarrativeEvent,
        day: TokenDailyBoardDayModel,
        lastRefreshAt: Date?) -> Date?
    {
        switch event.kind {
        case .quiet:
            return lastRefreshAt
        case .sendCount, .combo, .burst:
            guard let anchorDate = self.anchorDate(for: event, day: day) else {
                return lastRefreshAt
            }
            let stableSecond = self.stableSecondOffset(for: event)
            return anchorDate.addingTimeInterval(stableSecond)
        case .throughputPulse, .instructionPulse, .idlePulse:
            return lastRefreshAt
        }
    }

    private static func qualifyingClusters(
        for day: TokenDailyBoardDayModel,
        dayPeak: Int) -> [TokenDailyBoardNarrativeBurstCluster]
    {
        let activePoints = day.fiveMinutePoints.filter { $0.rawTokens > 0 }
        guard !activePoints.isEmpty else { return [] }

        var clusters: [TokenDailyBoardNarrativeBurstCluster] = []
        var currentStart = activePoints[0].bucketIndex
        var currentEnd = activePoints[0].bucketIndex
        var currentPeakIndex = activePoints[0].bucketIndex
        var currentPeakValue = activePoints[0].rawTokens
        var currentTotal = activePoints[0].rawTokens
        var previousIndex = activePoints[0].bucketIndex

        for point in activePoints.dropFirst() {
            if point.bucketIndex - previousIndex <= 2 {
                currentEnd = point.bucketIndex
                currentTotal += point.rawTokens
                if point.rawTokens > currentPeakValue {
                    currentPeakValue = point.rawTokens
                    currentPeakIndex = point.bucketIndex
                }
            } else {
                clusters.append(
                    TokenDailyBoardNarrativeBurstCluster(
                        startBucketIndex: currentStart,
                        endBucketIndex: currentEnd,
                        peakBucketIndex: currentPeakIndex,
                        peakTokens: currentPeakValue,
                        totalTokens: currentTotal))
                currentStart = point.bucketIndex
                currentEnd = point.bucketIndex
                currentPeakIndex = point.bucketIndex
                currentPeakValue = point.rawTokens
                currentTotal = point.rawTokens
            }
            previousIndex = point.bucketIndex
        }

        clusters.append(
            TokenDailyBoardNarrativeBurstCluster(
                startBucketIndex: currentStart,
                endBucketIndex: currentEnd,
                peakBucketIndex: currentPeakIndex,
                peakTokens: currentPeakValue,
                totalTokens: currentTotal))

        let dayTotal = max(day.totalTokens, 1)
        return clusters
            .filter { cluster in
                Double(cluster.peakTokens) >= Double(dayPeak) * 0.55
                    || Double(cluster.totalTokens) >= Double(dayTotal) * 0.18
            }
            .sorted { $0.startBucketIndex < $1.startBucketIndex }
    }

    private static func anchorDate(for event: TokenDailyBoardNarrativeEvent, day: TokenDailyBoardDayModel) -> Date? {
        let bucketIndex = event.peakBucketIndex ?? self.dayPeakBucketIndex(for: day)
        guard let bucketIndex else { return nil }
        let minutes = bucketIndex * 5
        return Calendar.autoupdatingCurrent.date(byAdding: .minute, value: minutes, to: day.date)
    }

    private static func dayPeakBucketIndex(for day: TokenDailyBoardDayModel) -> Int? {
        day.fiveMinutePoints.max(by: { $0.rawTokens < $1.rawTokens })?.bucketIndex
    }

    private static func stableSecondOffset(for event: TokenDailyBoardNarrativeEvent) -> TimeInterval {
        let signature = "\(event.id)|timestamp"
        return TimeInterval(self.stableHash(signature) % 60)
    }

    private static func stableHash(_ string: String) -> UInt64 {
        let offsetBasis: UInt64 = 14_695_981_039_346_656_037
        let prime: UInt64 = 1_099_511_628_211
        var hash = offsetBasis
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        return hash
    }

    private static func sortTimelineEntries(
        _ lhs: TokenDailyBoardNarrativeTimelineEntry,
        _ rhs: TokenDailyBoardNarrativeTimelineEntry)
        -> Bool
    {
        let lhsTimestamp = lhs.displayTimestamp ?? .distantPast
        let rhsTimestamp = rhs.displayTimestamp ?? .distantPast
        if lhsTimestamp != rhsTimestamp {
            return lhsTimestamp > rhsTimestamp
        }

        let lhsPriority = TokenDailyBoardNarrativeTimelineRules.priority(for: lhs.event.kind)
        let rhsPriority = TokenDailyBoardNarrativeTimelineRules.priority(for: rhs.event.kind)
        if lhsPriority != rhsPriority {
            return lhsPriority > rhsPriority
        }

        if lhs.dayDate != rhs.dayDate {
            return lhs.dayDate > rhs.dayDate
        }

        return lhs.id < rhs.id
    }

    private static func sortRealtimeEvents(
        _ lhs: TokenDailyBoardNarrativeRealtimeEvent,
        _ rhs: TokenDailyBoardNarrativeRealtimeEvent)
        -> Bool
    {
        if lhs.timestamp != rhs.timestamp {
            return lhs.timestamp > rhs.timestamp
        }

        let lhsPriority = TokenDailyBoardNarrativeTimelineRules.priority(for: lhs.kind)
        let rhsPriority = TokenDailyBoardNarrativeTimelineRules.priority(for: rhs.kind)
        if lhsPriority != rhsPriority {
            return lhsPriority > rhsPriority
        }

        return lhs.id < rhs.id
    }

    private static func presentationSourceItem(
        sentence: TokenDailyBoardNarrativeSentence,
        displayTimestamp: Date?,
        realtimeEventKind: TokenDailyBoardNarrativeEventKind?,
        isAutomaticRealtime: Bool,
        groupKind: TokenDailyBoardNarrativePresentationGroupKind)
        -> TokenDailyBoardNarrativePresentationSourceItem
    {
        TokenDailyBoardNarrativePresentationSourceItem(
            sourceID: sentence.id,
            signature: sentence.id,
            sentence: sentence,
            displayTimestamp: displayTimestamp,
            realtimeEventKind: realtimeEventKind,
            isAutomaticRealtime: isAutomaticRealtime,
            groupKind: groupKind)
    }
}

struct TokenDailyBoardDayTopOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, latest in latest })
    }
}

enum TokenDailyBoardNarrativeTypewriterLayoutRules {
    static func segmentedText(
        _ text: String,
        revealedCharacterCount: Int)
        -> (revealed: String, hidden: String)
    {
        let characters = Array(text)
        let clampedCount = min(max(revealedCharacterCount, 0), characters.count)
        return (
            String(characters.prefix(clampedCount)),
            String(characters.dropFirst(clampedCount)))
    }
}

enum TokenDailyBoardNarrativeMetadataAnimationRules {
    static let transitionOffset: CGFloat = 6
    static let transitionDuration: TimeInterval = 0.22
    static let transitionDurationNanoseconds: UInt64 = 220_000_000
    static let transitionAnimation = Animation.snappy(duration: transitionDuration, extraBounce: 0)
}

struct TokenDailyBoardTypewriterText: View {
    let text: String
    let style: TokenDailyBoardTextStyle
    let color: Color
    let lineSpacing: CGFloat
    let startDelay: TimeInterval
    let charactersPerSecond: Double
    let completionToken: String
    let onComplete: (() -> Void)?

    @State private var revealedCharacterCount = 0

    init(
        text: String,
        style: TokenDailyBoardTextStyle,
        color: Color,
        lineSpacing: CGFloat = 0,
        startDelay: TimeInterval = 0,
        charactersPerSecond: Double = TokenDailyBoardNarrativeLayout.typewriterCharactersPerSecond,
        completionToken: String = "",
        onComplete: (() -> Void)? = nil)
    {
        self.text = text
        self.style = style
        self.color = color
        self.lineSpacing = lineSpacing
        self.startDelay = startDelay
        self.charactersPerSecond = charactersPerSecond
        self.completionToken = completionToken
        self.onComplete = onComplete
    }

    var body: some View {
        self.layoutStableText
            .lineLimit(TokenDailyBoardNarrativeLayout.maxLines)
            .lineSpacing(self.lineSpacing)
            .truncationMode(.tail)
            .fixedSize(horizontal: false, vertical: true)
            .task(id: self.animationID) {
                let characters = Array(self.text)
                self.revealedCharacterCount = 0
                if self.startDelay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(self.startDelay * 1_000_000_000))
                }
                guard !characters.isEmpty else {
                    self.onComplete?()
                    return
                }
                let delay = UInt64(
                    (1.0 / max(self.charactersPerSecond, 0.1)) * 1_000_000_000)
                for index in 1...characters.count {
                    self.revealedCharacterCount = index
                    if index < characters.count {
                        try? await Task.sleep(nanoseconds: delay)
                    }
                }
                self.onComplete?()
            }
    }

    private var animationID: String {
        "\(self.completionToken)|\(self.text)|\(self.startDelay)|\(self.charactersPerSecond)"
    }

    private var layoutStableText: some View {
        let textSegments = TokenDailyBoardNarrativeTypewriterLayoutRules.segmentedText(
            self.text,
            revealedCharacterCount: self.revealedCharacterCount)
        let combinedText = Text(textSegments.revealed)
            .foregroundColor(self.color)
            + Text(textSegments.hidden)
            .foregroundColor(.clear)

        return Group {
            if self.style.usesMonospacedDigits {
                combinedText
                    .font(self.style.font)
                    .monospacedDigit()
            } else {
                combinedText
                    .font(self.style.font)
            }
        }
    }
}

private struct TokenDailyBoardNarrativeStaticText: View {
    let text: String
    let style: TokenDailyBoardTextStyle
    let color: Color
    let lineSpacing: CGFloat

    init(
        text: String,
        style: TokenDailyBoardTextStyle,
        color: Color,
        lineSpacing: CGFloat = 0)
    {
        self.text = text
        self.style = style
        self.color = color
        self.lineSpacing = lineSpacing
    }

    var body: some View {
        Group {
            if self.style.usesMonospacedDigits {
                Text(self.text)
                    .font(self.style.font)
                    .monospacedDigit()
                    .foregroundStyle(self.color)
            } else {
                Text(self.text)
                    .font(self.style.font)
                    .foregroundStyle(self.color)
            }
        }
        .lineLimit(TokenDailyBoardNarrativeLayout.maxLines)
        .lineSpacing(self.lineSpacing)
        .truncationMode(.tail)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct TokenDailyBoardAnimatedMetadataLine: View {
    let text: String?
    let style: TokenDailyBoardTextStyle
    let color: Color
    let opacity: Double
    let width: CGFloat?
    let verticalOffset: CGFloat

    @State private var displayedText: String?
    @State private var outgoingText: String?
    @State private var displayedTextOffset: CGFloat
    @State private var outgoingTextOffset: CGFloat
    @State private var displayedTextOpacity: Double
    @State private var outgoingTextOpacity: Double
    @State private var cleanupTask: Task<Void, Never>?

    init(
        text: String?,
        style: TokenDailyBoardTextStyle,
        color: Color,
        opacity: Double,
        width: CGFloat? = nil,
        verticalOffset: CGFloat = 0)
    {
        self.text = text
        self.style = style
        self.color = color
        self.opacity = opacity
        self.width = width
        self.verticalOffset = verticalOffset
        self._displayedText = State(initialValue: text)
        self._outgoingText = State(initialValue: nil)
        self._displayedTextOffset = State(initialValue: 0)
        self._outgoingTextOffset = State(initialValue: 0)
        self._displayedTextOpacity = State(initialValue: text == nil ? 0 : 1)
        self._outgoingTextOpacity = State(initialValue: 0)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let outgoingText = self.outgoingText {
                self.lineText(outgoingText)
                    .offset(y: self.outgoingTextOffset)
                    .opacity(self.outgoingTextOpacity * self.opacity)
            }

            if let displayedText = self.displayedText {
                self.lineText(displayedText)
                    .offset(y: self.displayedTextOffset)
                    .opacity(self.displayedTextOpacity * self.opacity)
            } else {
                Color.clear
                    .frame(width: self.width, height: self.lineHeight)
            }
        }
        .frame(width: self.width, height: self.lineHeight, alignment: .topLeading)
        .clipped()
        .offset(y: self.verticalOffset)
        .animation(TokenDailyBoardNarrativeMetadataAnimationRules.transitionAnimation, value: self.verticalOffset)
        .onChange(of: self.text) { _, newValue in
            self.transition(to: newValue)
        }
        .onDisappear {
            self.cleanupTask?.cancel()
            self.cleanupTask = nil
        }
    }

    private var lineHeight: CGFloat {
        let font = NSFont.monospacedDigitSystemFont(ofSize: self.style.size, weight: .medium)
        return ceil(font.ascender - font.descender + font.leading)
    }

    private func lineText(_ text: String) -> some View {
        Text(text)
            .font(self.style.font)
            .monospacedDigit()
            .foregroundStyle(self.color)
            .lineLimit(1)
            .frame(width: self.width, alignment: .leading)
    }

    private func transition(to newText: String?) {
        guard newText != self.displayedText else { return }
        self.cleanupTask?.cancel()

        let previousText = self.displayedText
        self.outgoingText = previousText
        self.displayedText = newText
        self.outgoingTextOffset = 0
        self.outgoingTextOpacity = previousText == nil ? 0 : 1
        self.displayedTextOffset = newText == nil ? 0 : TokenDailyBoardNarrativeMetadataAnimationRules.transitionOffset
        self.displayedTextOpacity = newText == nil ? 0 : 0

        withAnimation(TokenDailyBoardNarrativeMetadataAnimationRules.transitionAnimation) {
            self.outgoingTextOffset = previousText == nil
                ? 0
                : -TokenDailyBoardNarrativeMetadataAnimationRules.transitionOffset
            self.outgoingTextOpacity = 0
            self.displayedTextOffset = 0
            self.displayedTextOpacity = newText == nil ? 0 : 1
        }

        self.cleanupTask = Task { @MainActor in
            try? await Task.sleep(
                nanoseconds: TokenDailyBoardNarrativeMetadataAnimationRules.transitionDurationNanoseconds)
            guard !Task.isCancelled else { return }
            self.outgoingText = nil
            self.outgoingTextOffset = 0
            self.outgoingTextOpacity = 0
        }
    }
}

struct TokenDailyBoardConversationOnlyNarrativeView: View {
    let sentence: TokenDailyBoardNarrativeSentence
    let fontScaleMultiplier: CGFloat
    let avatarSlots: [CodexDailyAvatarResolvedSlot]
    let preferredAvatarSlot: CodexDailyAvatarResolvedSlot?
    let avatarPhase: TokenDailyBoardNarrativeAvatarPhase
    let avatarReplacementSequenceID: Int
    let avatarIdleShakeSequenceID: Int
    let animatesTypewriter: Bool
    let typewriterStartDelay: TimeInterval
    let typewriterCompletionToken: String
    let onTypewriterComplete: (() -> Void)?
    let displayedMetadataText: String?
    let animatesMetadataTypewriter: Bool
    let metadataStartDelay: TimeInterval
    let metadataCompletionToken: String
    let contentOpacity: Double
    let contentVerticalOffset: CGFloat
    let tuning: TokenDailyBoardConversationOnlyDebugTuning
    let bodyCharactersPerSecond: Double
    let metadataCharactersPerSecond: Double
    let avatarMotionConfiguration: TokenDailyBoardNarrativeAvatarMotionConfiguration
    let textColor: Color
    let mutedTextColor: Color

    private var resolvedTuning: TokenDailyBoardConversationOnlyDebugTuning {
        TokenDailyBoardConversationOnlyDebugRules.clamp(self.tuning)
    }

    private var textStyle: TokenDailyBoardTextStyle {
        TokenDailyBoardNarrativeSizingRules.style(
            for: self.sentence.text,
            availableWidth: self.resolvedTuning.textColumnWidth,
            fontScaleMultiplier: self.fontScaleMultiplier,
            preferredFontSize: self.resolvedTuning.bodyFontSize,
            lineSpacing: self.resolvedTuning.bodyLineSpacing)
    }

    private var metadataStyle: TokenDailyBoardTextStyle {
        TokenDailyBoardTextStyle(
            size: self.resolvedTuning.metadataFontSize,
            weight: .medium,
            usesMonospacedDigits: true)
    }

    private var contentLayout: TokenDailyBoardConversationOnlyVisibleContentLayout {
        TokenDailyBoardNarrativeSizingRules.conversationOnlyVisibleContentLayout(
            for: self.sentence,
            tuning: self.resolvedTuning,
            fontScaleMultiplier: self.fontScaleMultiplier)
    }

    var body: some View {
        ZStack {
            HStack(alignment: .top, spacing: TokenDailyBoardNarrativeLayout.conversationOnlyAvatarToContentSpacing) {
                TokenDailyBoardNarrativeAvatarView(
                    avatarSize: self.resolvedTuning.avatarSize,
                    usesCircularMask: false,
                    displayMode: .conversationOnly,
                    showsStroke: false,
                    avatarSlots: self.avatarSlots,
                    preferredSlot: self.preferredAvatarSlot,
                    phase: self.avatarPhase,
                    replacementSequenceID: self.avatarReplacementSequenceID,
                    idleShakeSequenceID: self.avatarIdleShakeSequenceID,
                    animatesReplacement: TokenDailyBoardNarrativeAvatarReplacementAnimationRules.isEnabled(
                        self.resolvedTuning,
                        displayMode: .conversationOnly),
                    motionConfiguration: self.avatarMotionConfiguration)
                    .frame(
                        width: self.resolvedTuning.avatarSize,
                        height: self.resolvedTuning.avatarSize,
                        alignment: .topLeading)

                VStack(
                    alignment: .leading,
                    spacing: TokenDailyBoardNarrativeLayout.conversationOnlyMetadataTopSpacing)
                {
                    Group {
                        if self.animatesTypewriter {
                            TokenDailyBoardTypewriterText(
                                text: self.sentence.text,
                                style: self.textStyle,
                                color: self.textColor,
                                lineSpacing: self.resolvedTuning.bodyLineSpacing,
                                startDelay: self.typewriterStartDelay,
                                charactersPerSecond: self.bodyCharactersPerSecond,
                                completionToken: self.typewriterCompletionToken,
                                onComplete: self.onTypewriterComplete)
                        } else {
                            TokenDailyBoardNarrativeStaticText(
                                text: self.sentence.text,
                                style: self.textStyle,
                                color: self.textColor,
                                lineSpacing: self.resolvedTuning.bodyLineSpacing)
                        }
                    }
                    .frame(width: self.contentLayout.textColumnWidth, alignment: .leading)
                    .offset(y: self.resolvedTuning.textColumnOffset.height)

                    if self.sentence.metadataText?.isEmpty == false || self.displayedMetadataText != nil {
                        Group {
                            if self.animatesMetadataTypewriter, let displayedMetadataText = self.displayedMetadataText {
                                TokenDailyBoardTypewriterText(
                                    text: displayedMetadataText,
                                    style: self.metadataStyle,
                                    color: self.mutedTextColor,
                                    startDelay: self.metadataStartDelay,
                                    charactersPerSecond: self.metadataCharactersPerSecond,
                                    completionToken: self.metadataCompletionToken,
                                    onComplete: nil)
                            } else if let displayedMetadataText = self.displayedMetadataText {
                                TokenDailyBoardNarrativeStaticText(
                                    text: displayedMetadataText,
                                    style: self.metadataStyle,
                                    color: self.mutedTextColor)
                            }
                        }
                        .frame(width: self.contentLayout.textColumnWidth, alignment: .leading)
                        .opacity(Double(self.resolvedTuning.metadataOpacity))
                        .offset(y: self.resolvedTuning.textColumnOffset.height)
                    }
                }
                .frame(width: self.contentLayout.textColumnWidth, alignment: .topLeading)
                .opacity(self.contentOpacity)
                .offset(y: self.contentVerticalOffset)
                .animation(
                    TokenDailyBoardNarrativeMetadataAnimationRules.transitionAnimation,
                    value: self.contentOpacity)
                .offset(x: self.resolvedTuning.textColumnOffset.width)
            }
            .frame(
                width: self.contentLayout.contentSize.width,
                height: self.contentLayout.contentSize.height,
                alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct TokenDailyBoardNarrativeBubbleShape: InsettableShape {
    private var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let bubbleRect = rect.insetBy(dx: self.insetAmount, dy: self.insetAmount)
        let radius = max(TokenDailyBoardNarrativeLayout.bubbleCornerRadius - self.insetAmount, 0)
        return Path(
            roundedRect: bubbleRect,
            cornerSize: CGSize(width: radius, height: radius))
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

private struct TokenDailyBoardNarrativeBubbleBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    let displayMode: TokenDailyBoardDisplayMode
    let showsStroke: Bool

    private var shape: TokenDailyBoardNarrativeBubbleShape {
        TokenDailyBoardNarrativeBubbleShape()
    }

    private var strokeColor: Color {
        switch self.colorScheme {
        case .light:
            Color.black.opacity(0.06)
        case .dark:
            Color.black.opacity(0.08)
        @unknown default:
            Color.primary.opacity(0.08)
        }
    }

    private var shadowColor: Color {
        switch self.colorScheme {
        case .light:
            Color.black.opacity(0.05)
        case .dark:
            Color.black.opacity(0.18)
        @unknown default:
            Color.black.opacity(0.08)
        }
    }

    var body: some View {
        if TokenDailyBoardNarrativePresentationRules.usesSystemGlass(for: self.displayMode), #available(macOS 26, *) {
            Color.clear
                .glassEffect(.regular, in: self.shape)
                .overlay {
                    if self.showsStroke {
                        self.shape
                            .stroke(self.strokeColor, lineWidth: 0.8)
                    }
                }
                .shadow(
                    color: TokenDailyBoardNarrativePresentationRules.showsOuterShadow(for: self.displayMode)
                        ? self.shadowColor
                        : .clear,
                    radius: 10,
                    x: 0,
                    y: 4)
        } else {
            Color.clear
                .background(.ultraThinMaterial, in: self.shape)
                .overlay {
                    if self.showsStroke {
                        self.shape
                            .stroke(self.strokeColor, lineWidth: 0.8)
                    }
                }
                .shadow(
                    color: TokenDailyBoardNarrativePresentationRules.showsOuterShadow(for: self.displayMode)
                        ? self.shadowColor
                        : .clear,
                    radius: 8,
                    x: 0,
                    y: 3)
        }
    }
}

struct TokenDailyBoardNarrativeDroplet: Identifiable, Equatable {
    let id = UUID()
    let origin: CGPoint
    let size: CGFloat
    let launchOffset: CGSize
    let midOffset: CGSize
    let driftX: CGFloat
    let fallDistance: CGFloat
    let duration: Double
}

struct TokenDailyBoardNarrativeDropletTemplate: Equatable {
    let originXRatio: CGFloat
    let originYRatio: CGFloat
    let size: CGFloat
    let launchOffset: CGSize
    let midOffset: CGSize
    let driftX: CGFloat
    let fallDistance: CGFloat
    let duration: Double
}

enum TokenDailyBoardNarrativeDropletPresetLibrary {
    static let presets = Self.buildPresets()

    static var presetCount: Int {
        self.presets.count
    }

    static var presetDropletCounts: [Int] {
        self.presets.map(\.count)
    }

    static func droplets(for presetIndex: Int, in size: CGSize) -> [TokenDailyBoardNarrativeDroplet] {
        guard size.width > 0, size.height > 0, !self.presets.isEmpty else { return [] }
        let resolvedIndex = ((presetIndex % self.presets.count) + self.presets.count) % self.presets.count
        return self.presets[resolvedIndex].map { template in
            TokenDailyBoardNarrativeDroplet(
                origin: CGPoint(
                    x: size.width * template.originXRatio,
                    y: size.height * template.originYRatio),
                size: template.size,
                launchOffset: template.launchOffset,
                midOffset: template.midOffset,
                driftX: template.driftX,
                fallDistance: template.fallDistance,
                duration: template.duration)
        }
    }

    private static func template(
        _ originXRatio: CGFloat,
        _ originYRatio: CGFloat,
        _ size: CGFloat,
        _ launchWidth: CGFloat,
        _ launchHeight: CGFloat,
        _ midWidth: CGFloat,
        _ midHeight: CGFloat,
        _ driftX: CGFloat,
        _ fallDistance: CGFloat,
        _ duration: Double)
        -> TokenDailyBoardNarrativeDropletTemplate
    {
        TokenDailyBoardNarrativeDropletTemplate(
            originXRatio: originXRatio,
            originYRatio: originYRatio,
            size: size,
            launchOffset: CGSize(width: launchWidth, height: launchHeight),
            midOffset: CGSize(width: midWidth, height: midHeight),
            driftX: driftX,
            fallDistance: fallDistance,
            duration: duration)
    }

    private static func buildPresets() -> [[TokenDailyBoardNarrativeDropletTemplate]] {
        [
            [
                self.template(0.08, 0.08, 48, -16, -38, 10, 52, 16, 112, 6.4),
                self.template(0.14, 0.16, 22, -12, -34, 8, 46, 12, 96, 5.7),
                self.template(0.18, 0.11, 12, -20, -28, 6, 34, 10, 84, 5.3),
                self.template(0.24, 0.22, 26, -18, -40, 12, 58, 18, 126, 6.0),
                self.template(0.28, 0.34, 14, -10, -24, 7, 42, 9, 90, 5.4),
                self.template(0.32, 0.18, 18, -14, -30, 10, 48, 14, 118, 5.8),
                self.template(0.36, 0.42, 10, -22, -18, 6, 36, 8, 76, 5.2),
                self.template(0.58, 0.58, 40, 14, -36, -6, 48, -18, 138, 6.1),
                self.template(0.70, 0.64, 12, 18, -22, -8, 38, -12, 102, 5.5),
                self.template(0.78, 0.72, 18, 12, -32, -10, 56, -16, 124, 5.9),
                self.template(0.86, 0.82, 14, 10, -20, -6, 40, -10, 92, 5.4),
                self.template(0.94, 0.88, 32, 16, -42, -12, 64, -20, 156, 6.3),
            ],
            [
                self.template(0.46, 0.06, 40, -8, -42, 4, 54, 6, 148, 6.3),
                self.template(0.50, 0.12, 18, 6, -34, 3, 48, 4, 132, 5.8),
                self.template(0.54, 0.18, 12, -10, -22, 2, 34, 3, 98, 5.3),
                self.template(0.44, 0.24, 22, 8, -28, -4, 44, -6, 116, 5.7),
                self.template(0.52, 0.30, 26, -6, -38, 5, 58, 8, 140, 6.0),
                self.template(0.48, 0.38, 14, 4, -24, 3, 38, 5, 108, 5.4),
                self.template(0.56, 0.46, 18, -12, -30, -3, 42, -8, 120, 5.6),
                self.template(0.50, 0.56, 48, 10, -40, 6, 64, 9, 168, 6.6),
                self.template(0.42, 0.64, 12, -14, -18, -5, 32, -10, 94, 5.2),
                self.template(0.58, 0.70, 22, 12, -26, 6, 46, 12, 122, 5.7),
                self.template(0.47, 0.78, 10, -8, -16, 2, 28, 4, 86, 5.2),
                self.template(0.53, 0.84, 18, 8, -24, -2, 36, -6, 110, 5.5),
                self.template(0.14, 0.28, 14, -18, -20, 8, 32, 14, 90, 5.3),
                self.template(0.86, 0.32, 32, 20, -36, -10, 50, -18, 144, 6.1),
            ],
            [
                self.template(0.06, 0.10, 32, -22, -36, 18, 52, 26, 142, 6.1),
                self.template(0.10, 0.22, 12, -18, -24, 12, 38, 18, 104, 5.4),
                self.template(0.14, 0.36, 18, -16, -30, 16, 46, 24, 122, 5.8),
                self.template(0.18, 0.54, 10, -14, -18, 10, 28, 18, 94, 5.2),
                self.template(0.22, 0.72, 22, -20, -34, 20, 54, 30, 138, 5.9),
                self.template(0.28, 0.84, 14, -12, -20, 12, 34, 20, 108, 5.4),
                self.template(0.74, 0.08, 40, 18, -40, -14, 56, -24, 154, 6.2),
                self.template(0.80, 0.18, 18, 16, -26, -12, 42, -20, 118, 5.6),
                self.template(0.86, 0.32, 12, 20, -18, -10, 34, -16, 96, 5.3),
                self.template(0.90, 0.48, 26, 14, -30, -18, 50, -28, 132, 5.8),
                self.template(0.94, 0.62, 10, 12, -16, -8, 28, -14, 88, 5.2),
                self.template(0.88, 0.78, 22, 18, -24, -16, 40, -22, 116, 5.6),
                self.template(0.76, 0.90, 14, 10, -20, -12, 32, -18, 104, 5.4),
                self.template(0.48, 0.18, 12, -8, -22, 6, 36, 8, 98, 5.3),
                self.template(0.52, 0.46, 18, 6, -28, -4, 44, -6, 114, 5.7),
                self.template(0.50, 0.74, 48, -10, -42, 8, 60, 10, 168, 6.5),
            ],
            [
                self.template(0.10, 0.06, 48, -20, -40, 14, 58, 18, 160, 6.5),
                self.template(0.22, 0.10, 40, -16, -36, 10, 50, 14, 148, 6.2),
                self.template(0.34, 0.12, 32, -12, -34, 8, 46, 10, 136, 5.9),
                self.template(0.46, 0.14, 26, -10, -28, 7, 42, 8, 122, 5.7),
                self.template(0.58, 0.10, 22, 8, -30, -6, 44, -8, 120, 5.6),
                self.template(0.70, 0.08, 18, 10, -26, -8, 38, -12, 114, 5.5),
                self.template(0.82, 0.12, 40, 16, -38, -12, 54, -16, 152, 6.3),
                self.template(0.92, 0.18, 32, 18, -34, -10, 48, -14, 140, 6.0),
                self.template(0.18, 0.26, 18, -12, -22, 8, 34, 12, 110, 5.4),
                self.template(0.32, 0.30, 12, -8, -18, 6, 28, 10, 92, 5.2),
                self.template(0.46, 0.34, 14, -6, -16, 4, 26, 6, 88, 5.2),
                self.template(0.60, 0.28, 22, 8, -20, -6, 30, -10, 106, 5.4),
                self.template(0.74, 0.24, 12, 10, -18, -8, 28, -12, 94, 5.2),
                self.template(0.88, 0.30, 18, 12, -24, -10, 34, -14, 112, 5.5),
                self.template(0.26, 0.44, 14, -10, -18, 6, 30, 8, 96, 5.3),
                self.template(0.50, 0.48, 18, -6, -22, 2, 34, 4, 108, 5.4),
                self.template(0.68, 0.42, 22, 10, -20, -6, 30, -10, 114, 5.5),
                self.template(0.84, 0.46, 10, 12, -16, -8, 24, -12, 90, 5.2),
            ],
        ]
    }
}

private struct TokenDailyBoardNarrativeDropletBatch: Identifiable, Equatable {
    let id: Int
    let droplets: [TokenDailyBoardNarrativeDroplet]
}

private struct TokenDailyBoardNarrativeDropletBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if #available(macOS 26, *) {
            Circle()
                .fill(.clear)
                .glassEffect(.regular, in: Circle())
                .overlay {
                    Circle()
                        .stroke(self.strokeColor, lineWidth: 0.6)
                }
                .shadow(color: self.shadowColor, radius: 6, x: 0, y: 3)
        } else {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay {
                    Circle()
                        .stroke(self.strokeColor, lineWidth: 0.6)
                }
                .shadow(color: self.shadowColor, radius: 5, x: 0, y: 2)
        }
    }

    private var strokeColor: Color {
        switch self.colorScheme {
        case .light:
            Color.black.opacity(0.08)
        case .dark:
            Color.white.opacity(0.10)
        @unknown default:
            Color.primary.opacity(0.08)
        }
    }

    private var shadowColor: Color {
        switch self.colorScheme {
        case .light:
            Color.black.opacity(0.05)
        case .dark:
            Color.black.opacity(0.18)
        @unknown default:
            Color.black.opacity(0.08)
        }
    }
}

private struct TokenDailyBoardNarrativeDropletView: View {
    let droplet: TokenDailyBoardNarrativeDroplet

    @State private var currentOffset: CGSize
    @State private var opacity: Double
    @State private var scaleFactor: CGFloat

    init(droplet: TokenDailyBoardNarrativeDroplet) {
        self.droplet = droplet
        self._currentOffset = State(initialValue: droplet.launchOffset)
        self._opacity = State(initialValue: 0)
        self._scaleFactor = State(initialValue: 0.55)
    }

    var body: some View {
        TokenDailyBoardNarrativeDropletBackground()
            .frame(width: self.droplet.size, height: self.droplet.size)
            .position(self.droplet.origin)
            .offset(self.currentOffset)
            .opacity(self.opacity)
            .scaleEffect(self.scaleFactor)
            .allowsHitTesting(false)
            .task(id: self.droplet.id) {
                self.currentOffset = self.droplet.launchOffset
                self.opacity = 0
                self.scaleFactor = 0.48

                withAnimation(.spring(response: 0.22, dampingFraction: 0.7)) {
                    self.currentOffset = .zero
                    self.opacity = 0.92
                    self.scaleFactor = 1
                }

                try? await Task.sleep(nanoseconds: 220_000_000)
                guard !Task.isCancelled else { return }

                let accelerationDuration = max(self.droplet.duration * 0.58, 0.4)
                let tailDuration = max(self.droplet.duration - accelerationDuration, 0.55)

                withAnimation(.timingCurve(0.18, 0.82, 0.36, 1, duration: accelerationDuration)) {
                    self.currentOffset = self.droplet.midOffset
                    self.opacity = 0.88
                    self.scaleFactor = 0.96
                }

                try? await Task.sleep(nanoseconds: UInt64(accelerationDuration * 1_000_000_000))
                guard !Task.isCancelled else { return }

                withAnimation(.timingCurve(0.12, 0.45, 0.28, 1, duration: tailDuration)) {
                    self.currentOffset = CGSize(width: self.droplet.driftX, height: self.droplet.fallDistance)
                    self.opacity = 0
                    self.scaleFactor = 0.76
                }
            }
    }
}

struct TokenDailyBoardNarrativeDropletOverlay: View {
    let trigger: Int

    @State private var batches: [TokenDailyBoardNarrativeDropletBatch] = []
    @State private var lastHandledTrigger = 0
    @State private var nextBatchID = 0
    @State private var nextPresetIndex = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ForEach(self.batches) { batch in
                    ZStack(alignment: .topLeading) {
                        ForEach(batch.droplets) { droplet in
                            TokenDailyBoardNarrativeDropletView(droplet: droplet)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .allowsHitTesting(false)
            .onChange(of: self.trigger) { _, newValue in
                guard newValue > 0, newValue != self.lastHandledTrigger else { return }
                self.lastHandledTrigger = newValue
                self.enqueueBatch(in: geo.size)
            }
            .onDisappear {
                self.batches = []
                self.nextPresetIndex = 0
            }
        }
    }

    private func enqueueBatch(in size: CGSize) {
        let batch = TokenDailyBoardNarrativeDropletBatch(
            id: self.nextBatchID,
            droplets: Self.makeDroplets(in: size, presetIndex: self.nextPresetIndex))
        self.nextBatchID += 1
        if TokenDailyBoardNarrativeDropletPresetLibrary.presetCount > 0 {
            self.nextPresetIndex = (self.nextPresetIndex + 1) % TokenDailyBoardNarrativeDropletPresetLibrary.presetCount
        }

        withAnimation(.easeInOut(duration: 0.18)) {
            if self.batches.count >= TokenDailyBoardNarrativeAnimationRules.dropletMaximumVisibleBatches {
                let overflowCount = self.batches.count
                    - TokenDailyBoardNarrativeAnimationRules.dropletMaximumVisibleBatches
                    + 1
                self.batches.removeFirst(overflowCount)
            }
            self.batches.append(batch)
        }

        let removalDelay = (batch.droplets.map(\.duration).max() ?? 0) + 0.45
        Task {
            try? await Task.sleep(nanoseconds: UInt64(removalDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.batches.removeAll { $0.id == batch.id }
                }
            }
        }
    }

    static func makeDroplets(in size: CGSize, presetIndex: Int) -> [TokenDailyBoardNarrativeDroplet] {
        TokenDailyBoardNarrativeDropletPresetLibrary.droplets(for: presetIndex, in: size)
    }
}

private struct TokenDailyBoardNarrativeAvatarView: View {
    @Environment(\.colorScheme) private var colorScheme
    let avatarSize: CGFloat
    let usesCircularMask: Bool
    let displayMode: TokenDailyBoardDisplayMode
    let showsStroke: Bool
    let avatarSlots: [CodexDailyAvatarResolvedSlot]
    let preferredSlot: CodexDailyAvatarResolvedSlot?
    let phase: TokenDailyBoardNarrativeAvatarPhase
    let replacementSequenceID: Int
    let idleShakeSequenceID: Int
    let animatesReplacement: Bool
    let motionConfiguration: TokenDailyBoardNarrativeAvatarMotionConfiguration

    @State private var displayedSlot: CodexDailyAvatarResolvedSlot?
    @State private var displayedTransitionKey = ""
    @State private var outgoingSlot: CodexDailyAvatarResolvedSlot?
    @State private var displayedOpacity = 1.0
    @State private var outgoingOpacity = 0.0
    @State private var scaleFactor: CGFloat = 1
    @State private var horizontalShakeOffset: CGFloat = 0
    @State private var transitionTask: Task<Void, Never>?
    @State private var idleShakeTask: Task<Void, Never>?

    private var roundedSquareShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: TokenDailyBoardNarrativeLayout.avatarCornerRadius,
            style: .continuous)
    }

    private var defaultAvatarSlot: CodexDailyAvatarResolvedSlot? {
        self.avatarSlots.first(where: { $0.slot == .defaultAvatar })
    }

    private var activeAvatarSlot: CodexDailyAvatarResolvedSlot? {
        self.preferredSlot ?? self.defaultAvatarSlot
    }

    private var activeAvatarTransitionKey: String {
        TokenDailyBoardNarrativeAvatarReplacementAnimationRules.transitionKey(
            for: self.activeAvatarSlot,
            displayMode: self.displayMode,
            sequenceID: self.animatesReplacement ? self.replacementSequenceID : 0)
    }

    var body: some View {
        ZStack {
            if let outgoingSlot = self.outgoingSlot {
                self.avatarLayer(for: outgoingSlot)
                    .opacity(self.outgoingOpacity)
            }

            self.avatarLayer(for: self.displayedSlot ?? self.activeAvatarSlot)
                .opacity(self.displayedOpacity)
        }
        .offset(x: self.horizontalShakeOffset)
        .scaleEffect(self.scaleFactor)
        .padding(self.usesCircularMask ? TokenDailyBoardNarrativeLayout.conversationOnlyAvatarImageInset : 0)
        .frame(width: self.avatarSize, height: self.avatarSize)
        .modifier(TokenDailyBoardNarrativeAvatarMaskModifier(
            usesCircularMask: self.usesCircularMask,
            roundedSquareShape: self.roundedSquareShape,
            showsStroke: self.showsStroke,
            strokeColor: self.strokeColor,
            shadowColor: self.shadowColor))
        .onAppear {
            self.syncImmediately()
        }
        .onChange(of: self.activeAvatarTransitionKey) { _, newValue in
            self.handleAvatarChange(newTransitionKey: newValue)
        }
        .onChange(of: self.phase) { _, newValue in
            self.handlePhaseChange(newValue)
        }
        .onChange(of: self.animatesReplacement) { _, newValue in
            if !newValue {
                self.syncImmediately()
            }
        }
        .onDisappear {
            self.transitionTask?.cancel()
            self.transitionTask = nil
            self.idleShakeTask?.cancel()
            self.idleShakeTask = nil
        }
    }

    private func avatarLayer(for slot: CodexDailyAvatarResolvedSlot?) -> some View {
        Group {
            if let image = slot?.preferredImage(for: self.displayMode) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(self.fallbackColor)
                    .padding(8)
            }
        }
        .scaleEffect(self.contentScale(for: slot))
        .scaleEffect(x: slot?.isMirrored == true ? -1 : 1, y: 1)
    }

    private func contentScale(for slot: CodexDailyAvatarResolvedSlot?) -> CGFloat {
        guard slot?.slot == .defaultAvatar else {
            return 1
        }
        return TokenDailyBoardNarrativeLayout.defaultAvatarContentScale
    }

    private func syncImmediately() {
        self.transitionTask?.cancel()
        self.transitionTask = nil
        self.displayedSlot = self.activeAvatarSlot
        self.displayedTransitionKey = self.activeAvatarTransitionKey
        self.outgoingSlot = nil
        self.displayedOpacity = 1
        self.outgoingOpacity = 0
        self.scaleFactor = 1
        self.horizontalShakeOffset = 0
    }

    private func handlePhaseChange(_ phase: TokenDailyBoardNarrativeAvatarPhase) {
        guard self.animatesReplacement else { return }
        switch phase {
        case .settlingDefault, .settlingVariant:
            withAnimation(
                .timingCurve(
                    0.18,
                    0.82,
                    0.24,
                    1,
                    duration: TokenDailyBoardNarrativeAvatarReplacementAnimationRules.returnDuration))
            {
                self.scaleFactor = 1
                self.horizontalShakeOffset = 0
            }
        case .resting, .introDefault, .holdingDefault, .introVariant, .holdingVariant:
            break
        }
    }

    @MainActor
    private func startIntroMotion(peakScale: CGFloat, shakeAmplitude: CGFloat) async {
        withAnimation(
            .easeOut(duration: TokenDailyBoardNarrativeAvatarReplacementAnimationRules.expandDuration))
        {
            self.scaleFactor = peakScale
            self.horizontalShakeOffset = shakeAmplitude
        }

        try? await Task.sleep(
            nanoseconds: UInt64(
                TokenDailyBoardNarrativeAvatarReplacementAnimationRules.expandDuration * 1_000_000_000))
        guard !Task.isCancelled else { return }

        withAnimation(
            .easeInOut(duration: TokenDailyBoardNarrativeAvatarReplacementAnimationRules.recoilDuration))
        {
            self.horizontalShakeOffset = -shakeAmplitude * 0.55
        }

        try? await Task.sleep(
            nanoseconds: UInt64(
                TokenDailyBoardNarrativeAvatarReplacementAnimationRules.recoilDuration * 1_000_000_000))
        guard !Task.isCancelled else { return }

        withAnimation(
            .snappy(
                duration: TokenDailyBoardNarrativeAvatarReplacementAnimationRules.settleDuration,
                extraBounce: 0))
        {
            self.scaleFactor = peakScale
            self.horizontalShakeOffset = 0
        }

        try? await Task.sleep(
            nanoseconds: UInt64(
                TokenDailyBoardNarrativeAvatarReplacementAnimationRules.settleDuration * 1_000_000_000))
        guard !Task.isCancelled else { return }

        self.outgoingSlot = nil
        self.outgoingOpacity = 0
        self.transitionTask = nil
    }

    private func handleAvatarChange(newTransitionKey: String) {
        guard newTransitionKey != self.displayedTransitionKey else { return }
        guard self.animatesReplacement, !self.displayedTransitionKey.isEmpty else {
            self.syncImmediately()
            return
        }

        self.transitionTask?.cancel()
        self.transitionTask = nil

        let outgoingSlot = self.displayedSlot
        let incomingSlot = self.activeAvatarSlot
        let slotChanged = TokenDailyBoardNarrativeAvatarReplacementAnimationRules.signature(
            for: outgoingSlot,
            displayMode: self.displayMode)
            != TokenDailyBoardNarrativeAvatarReplacementAnimationRules.signature(
                for: incomingSlot,
                displayMode: self.displayMode)

        self.outgoingSlot = slotChanged ? outgoingSlot : nil
        self.displayedSlot = incomingSlot
        self.displayedTransitionKey = newTransitionKey
        self.displayedOpacity = slotChanged ? 0 : 1
        self.outgoingOpacity = self.outgoingSlot == nil ? 0 : 1
        self.scaleFactor = 1
        self.horizontalShakeOffset = 0
        let usesDefaultIntroMotion = !slotChanged && incomingSlot?.slot == .defaultAvatar
        let peakScale = usesDefaultIntroMotion
            ? self.motionConfiguration.defaultPeakScale
            : self.motionConfiguration.variantPeakScale
        let shakeAmplitude = usesDefaultIntroMotion
            ? self.motionConfiguration.defaultShakeAmplitude
            : self.motionConfiguration.variantShakeAmplitude

        if slotChanged {
            withAnimation(
                .easeInOut(duration: TokenDailyBoardNarrativeAvatarReplacementAnimationRules.crossfadeDuration))
            {
                self.displayedOpacity = 1
                self.outgoingOpacity = 0
            }
        }

        self.transitionTask = Task { @MainActor in
            await self.startIntroMotion(peakScale: peakScale, shakeAmplitude: shakeAmplitude)
        }
    }

    private var strokeColor: Color {
        switch self.colorScheme {
        case .light:
            Color.black.opacity(0.12)
        case .dark:
            Color.white.opacity(0.12)
        @unknown default:
            Color.primary.opacity(0.12)
        }
    }

    private var shadowColor: Color {
        guard TokenDailyBoardNarrativePresentationRules.showsOuterShadow(for: self.displayMode) else {
            return .clear
        }
        return switch self.colorScheme {
        case .light:
            Color.black.opacity(0.08)
        case .dark:
            Color.black.opacity(0.24)
        @unknown default:
            Color.black.opacity(0.10)
        }
    }

    private var fallbackColor: Color {
        switch self.colorScheme {
        case .light:
            Color.black.opacity(0.75)
        case .dark:
            Color.white.opacity(0.82)
        @unknown default:
            Color.primary.opacity(0.8)
        }
    }
}

private struct TokenDailyBoardNarrativeAvatarMaskModifier: ViewModifier {
    let usesCircularMask: Bool
    let roundedSquareShape: RoundedRectangle
    let showsStroke: Bool
    let strokeColor: Color
    let shadowColor: Color

    func body(content: Content) -> some View {
        if self.usesCircularMask {
            content
                .clipShape(Circle())
        } else {
            content
                .clipShape(self.roundedSquareShape)
                .overlay {
                    if self.showsStroke {
                        self.roundedSquareShape
                            .stroke(self.strokeColor, lineWidth: 0.8)
                    }
                }
                .shadow(color: self.shadowColor, radius: 8, x: 0, y: 4)
        }
    }
}

struct TokenDailyBoardNarrativeRailView: View {
    @Environment(\.colorScheme) private var colorScheme
    let sentence: TokenDailyBoardNarrativeSentence
    let fontScaleMultiplier: CGFloat
    let displayMode: TokenDailyBoardDisplayMode
    let avatarSlots: [CodexDailyAvatarResolvedSlot]
    let preferredAvatarSlot: CodexDailyAvatarResolvedSlot?
    let avatarPhase: TokenDailyBoardNarrativeAvatarPhase
    let avatarReplacementSequenceID: Int
    let avatarIdleShakeSequenceID: Int
    let animatesAvatarReplacement: Bool
    let animatesTypewriter: Bool
    let typewriterStartDelay: TimeInterval
    let typewriterCompletionToken: String
    let onTypewriterComplete: (() -> Void)?
    let displayedMetadataText: String?
    let animatesMetadataTypewriter: Bool
    let metadataStartDelay: TimeInterval
    let metadataCompletionToken: String
    let contentOpacity: Double
    let contentVerticalOffset: CGFloat
    let bodyCharactersPerSecond: Double
    let metadataCharactersPerSecond: Double
    let chromeButtonsVisible: Bool
    let onCustomize: () -> Void
    let strings: TokenDailyBoardStrings
    let textColor: Color
    let mutedTextColor: Color

    private var fullText: String {
        self.sentence.text
    }

    private var timestampStyle: TokenDailyBoardTextStyle {
        TokenDailyBoardTextStyle(
            size: TokenDailyBoardNarrativeLayout.timestampFontSize,
            weight: .medium,
            usesMonospacedDigits: true)
    }

    private var controlsTopSpacing: CGFloat {
        switch self.displayMode {
        case .conversationOnly, .conversationAndToday:
            6
        case .fullBoard:
            TokenDailyBoardNarrativeLayout.controlsTopSpacing
        }
    }

    private var showsOutlineStroke: Bool {
        TokenDailyBoardNarrativePresentationRules.showsOutlineStroke(for: self.displayMode)
    }

    private var resolvedChromeButtonsVisible: Bool {
        self.chromeButtonsVisible
    }

    private var controlsButtonsCluster: some View {
        HStack(alignment: .center, spacing: TokenDailyBoardNarrativeSizingRules.buttonSpacing) {
            Button(action: self.onCustomize) {
                Image(systemName: TokenDailyBoardNarrativeLayout.customizeButtonSymbol)
                    .font(.system(
                        size: TokenDailyBoardNarrativeLayout.nextButtonSize,
                        weight: .semibold))
                    .foregroundStyle(self.mutedTextColor)
            }
            .frame(
                width: TokenDailyBoardNarrativeSizingRules.buttonReservedWidth,
                alignment: .center)
            .buttonStyle(.plain)
            .accessibilityLabel(
                self.strings.text(zh: "自定义文案", en: "Customize copy", ja: "文案をカスタマイズ"))
        }
    }

    private func bubbleShiftOffset(
        for totalWidth: CGFloat,
        metrics: TokenDailyBoardNarrativeSizingMetrics)
        -> CGFloat
    {
        _ = totalWidth
        _ = metrics
        return 0
    }

    private func conversationOnlyTrailingSafetyInset(
        for totalWidth: CGFloat,
        metrics: TokenDailyBoardNarrativeSizingMetrics)
        -> CGFloat
    {
        _ = totalWidth
        _ = metrics
        return 0
    }

    private func bubbleWidth(
        for totalWidth: CGFloat,
        metrics: TokenDailyBoardNarrativeSizingMetrics,
        shiftOffset: CGFloat)
        -> CGFloat
    {
        let reservedInset = self.conversationOnlyTrailingSafetyInset(for: totalWidth, metrics: metrics)
        let availableWidth = max(
            totalWidth - metrics.avatarSize - TokenDailyBoardNarrativeLayout.railSpacing - reservedInset,
            180)
        let maximumWidth: CGFloat = switch self.displayMode {
        case .conversationOnly, .conversationAndToday:
            860
        case .fullBoard:
            .greatestFiniteMagnitude
        }
        return min(availableWidth, maximumWidth)
    }

    var body: some View {
        GeometryReader { geo in
            let metrics = TokenDailyBoardNarrativeSizingRules.metrics(
                fontScaleMultiplier: self.fontScaleMultiplier)
            let totalWidth = geo.size.width
            let bubbleShiftOffset = self.bubbleShiftOffset(for: totalWidth, metrics: metrics)
            let bubbleWidth = self.bubbleWidth(
                for: totalWidth,
                metrics: metrics,
                shiftOffset: bubbleShiftOffset)
            let timestampStyle = self.timestampStyle
            let mutedTextColor = self.mutedTextColor
            let resolvedStyle = TokenDailyBoardNarrativeSizingRules.style(
                for: self.fullText,
                availableWidth: bubbleWidth - (TokenDailyBoardNarrativeLayout.bubbleHorizontalPadding * 2),
                fontScaleMultiplier: self.fontScaleMultiplier)

            HStack(alignment: .top, spacing: TokenDailyBoardNarrativeLayout.railSpacing) {
                TokenDailyBoardNarrativeAvatarView(
                    avatarSize: metrics.avatarSize,
                    usesCircularMask: false,
                    displayMode: self.displayMode,
                    showsStroke: self.showsOutlineStroke,
                    avatarSlots: self.avatarSlots,
                    preferredSlot: self.preferredAvatarSlot,
                    phase: self.avatarPhase,
                    replacementSequenceID: self.avatarReplacementSequenceID,
                    idleShakeSequenceID: self.avatarIdleShakeSequenceID,
                    animatesReplacement: self.animatesAvatarReplacement,
                    motionConfiguration: .standard)
                    .frame(
                        width: metrics.avatarSize,
                        height: metrics.avatarSize,
                        alignment: .topLeading)
                    .zIndex(1)

                VStack(alignment: .leading, spacing: self.controlsTopSpacing) {
                    ZStack(alignment: .topLeading) {
                        TokenDailyBoardNarrativeBubbleBackground(
                            displayMode: self.displayMode,
                            showsStroke: self.showsOutlineStroke)

                        Group {
                            if self.animatesTypewriter {
                                TokenDailyBoardTypewriterText(
                                    text: self.fullText,
                                    style: resolvedStyle,
                                    color: self.textColor,
                                    startDelay: self.typewriterStartDelay,
                                    charactersPerSecond: self.bodyCharactersPerSecond,
                                    completionToken: self.typewriterCompletionToken,
                                    onComplete: self.onTypewriterComplete)
                            } else {
                                TokenDailyBoardNarrativeStaticText(
                                    text: self.fullText,
                                    style: resolvedStyle,
                                    color: self.textColor)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, TokenDailyBoardNarrativeLayout.bubbleHorizontalPadding)
                        .padding(.top, TokenDailyBoardNarrativeLayout.bubbleTopPadding)
                        .padding(.bottom, TokenDailyBoardNarrativeLayout.bubbleBottomPadding)
                    }
                    .frame(
                        width: bubbleWidth,
                        height: metrics.bubbleHeight,
                        alignment: .topLeading)
                    .opacity(self.contentOpacity)
                    .offset(y: self.contentVerticalOffset)
                    .animation(
                        TokenDailyBoardNarrativeMetadataAnimationRules.transitionAnimation,
                        value: self.contentOpacity)

                    HStack(alignment: .center, spacing: TokenDailyBoardNarrativeSizingRules.buttonSpacing) {
                        Group {
                            if self.animatesMetadataTypewriter, let displayedMetadataText = self.displayedMetadataText {
                                TokenDailyBoardTypewriterText(
                                    text: displayedMetadataText,
                                    style: timestampStyle,
                                    color: mutedTextColor,
                                    startDelay: self.metadataStartDelay,
                                    charactersPerSecond: self.metadataCharactersPerSecond,
                                    completionToken: self.metadataCompletionToken,
                                    onComplete: nil)
                            } else if let displayedMetadataText = self.displayedMetadataText {
                                TokenDailyBoardNarrativeStaticText(
                                    text: displayedMetadataText,
                                    style: timestampStyle,
                                    color: mutedTextColor)
                            }
                        }
                        .opacity(self.contentOpacity)
                        .offset(y: self.contentVerticalOffset)
                        .animation(
                            TokenDailyBoardNarrativeMetadataAnimationRules.transitionAnimation,
                            value: self.contentOpacity)

                        Spacer(minLength: 0)

                        self.controlsButtonsCluster
                            .opacity(self.resolvedChromeButtonsVisible ? 1 : 0)
                            .animation(.easeInOut(duration: 0.18), value: self.resolvedChromeButtonsVisible)
                            .allowsHitTesting(self.resolvedChromeButtonsVisible)
                            .frame(
                                width: TokenDailyBoardNarrativeSizingRules.controlsButtonClusterWidth,
                                alignment: .trailing)
                    }
                    .frame(
                        width: bubbleWidth,
                        height: TokenDailyBoardNarrativeSizingRules.controlsRowHeight,
                        alignment: .center)
                }
                .frame(
                    width: bubbleWidth,
                    height: metrics.railHeight,
                    alignment: .topLeading)
                .offset(x: bubbleShiftOffset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(
            height: TokenDailyBoardNarrativeSizingRules.metrics(
                fontScaleMultiplier: self.fontScaleMultiplier).railHeight,
            alignment: .topLeading)
    }
}

private enum TokenDailyBoardNarrativeEditorTab: String, CaseIterable, Identifiable {
    case copy
    case avatar

    var id: String {
        self.rawValue
    }
}

struct TokenDailyBoardNarrativeEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let bundledEntries: [TokenDailyBoardNarrativeCatalogEntry]
    let entries: [TokenDailyBoardNarrativeUserCatalogEntry]
    let avatarSlots: [CodexDailyAvatarResolvedSlot]
    let strings: TokenDailyBoardStrings
    @Binding var narrativeBodyFontScale: Double
    let saveEntry: (TokenDailyBoardNarrativeUserCatalogEntry) -> String?
    let deleteEntry: (TokenDailyBoardNarrativeUserCatalogEntry) -> String?
    let replaceAvatarImage: (CodexDailyAvatarSlot, URL) -> String?
    let restoreAvatarSlot: (CodexDailyAvatarSlot) -> String?
    let setAvatarMirrored: (CodexDailyAvatarSlot, Bool) -> String?
    let currentErrorMessage: String?
    let avatarErrorMessage: String?

    @State private var selectedTab: TokenDailyBoardNarrativeEditorTab = .copy
    @State private var filterEventKind: TokenDailyBoardNarrativeEventKind?
    @State private var selectedEditableEntryID: String?
    @State private var draftEntryID: String?
    @State private var draftOverrideTargetID: String?
    @State private var draftEventKind: TokenDailyBoardNarrativeEventKind = .throughputPulse
    @State private var category = ""
    @State private var instructionBand: TokenDailyBoardNarrativeInstructionBand?
    @State private var tokenBand: TokenDailyBoardNarrativeTokenBand?
    @State private var timeBand: TokenDailyBoardNarrativeTimeBand?
    @State private var text = ""
    @State private var enabled = true
    @State private var localErrorMessage: String?

    private var allEditableEntries: [TokenDailyBoardNarrativeEditableEntry] {
        TokenDailyBoardNarrativeEditableCatalog.entries(
            bundledEntries: self.bundledEntries,
            userEntries: self.entries)
    }

    private var filteredEditableEntries: [TokenDailyBoardNarrativeEditableEntry] {
        self.allEditableEntries.filter { entry in
            self.filterEventKind.map { entry.effectiveEventKind == $0 } ?? true
        }
    }

    private var groupedEntries: [(TokenDailyBoardNarrativeEventKind, [TokenDailyBoardNarrativeEditableEntry])] {
        Dictionary(grouping: self.filteredEditableEntries, by: \.effectiveEventKind)
            .map { ($0.key, $0.value) }
            .sorted { $0.0.rawValue < $1.0.rawValue }
    }

    private var canSave: Bool {
        !self.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var narrativeBodyFontPercentageText: String {
        "\(Int((self.narrativeBodyFontScale * 100).rounded()))%"
    }

    private var narrativeBodyFontScaleRange: ClosedRange<Double> {
        Double(TokenDailyBoardNarrativeSizingRules.minimumFontScaleMultiplier)...Double(
            TokenDailyBoardNarrativeSizingRules.maximumFontScaleMultiplier)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(self.strings.text(zh: "自定义文案", en: "Customize copy", ja: "文案をカスタマイズ"))
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(self.strings.text(zh: "关闭", en: "Close", ja: "閉じる")) {
                    self.dismiss()
                }
            }

            Picker("", selection: self.$selectedTab) {
                Text(self.strings.text(zh: "文案", en: "Copy", ja: "文案"))
                    .tag(TokenDailyBoardNarrativeEditorTab.copy)
                Text(self.strings.text(zh: "头像", en: "Avatars", ja: "头像"))
                    .tag(TokenDailyBoardNarrativeEditorTab.avatar)
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    Text(self.strings.text(zh: "气泡字号", en: "Bubble text size", ja: "吹き出し文字サイズ"))
                        .font(.system(size: 13, weight: .semibold))
                    Slider(
                        value: self.$narrativeBodyFontScale,
                        in: self.narrativeBodyFontScaleRange)
                    Text(self.narrativeBodyFontPercentageText)
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 48, alignment: .trailing)
                    Button(self.strings.text(zh: "恢复默认", en: "Reset", ja: "リセット")) {
                        self.narrativeBodyFontScale = 1.0
                    }
                    .disabled(abs(self.narrativeBodyFontScale - 1.0) < 0.001)
                }

                Text(self.strings.text(
                    zh: "只调整气泡正文大小，不影响时间行、按钮和右侧日卡片。",
                    en: "Only affects bubble body text, not metadata, buttons, or day cards.",
                    ja: "吹き出し本文のみ調整し、時間行・ボタン・日別カードには影響しません。"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            if self.selectedTab == .copy {
                Picker(
                    self.strings.text(zh: "筛选事件类型", en: "Filter event type", ja: "イベント種別で絞り込み"),
                    selection: self.$filterEventKind)
                {
                    Text(self.strings.text(zh: "全部", en: "All", ja: "すべて"))
                        .tag(TokenDailyBoardNarrativeEventKind?.none)
                    ForEach(TokenDailyBoardNarrativeEventKind.allCases, id: \.self) { kind in
                        Text(self.eventLabel(for: kind)).tag(Optional(kind))
                    }
                }
                .pickerStyle(.menu)

                HStack(alignment: .top, spacing: 16) {
                    List {
                        ForEach(self.groupedEntries, id: \.0) { eventKind, entries in
                            Section(self.eventLabel(for: eventKind)) {
                                ForEach(entries) { entry in
                                    Button {
                                        self.load(entry: entry)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.effectiveText)
                                                .lineLimit(2)
                                            Text(self.rowSubtitle(for: entry))
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundStyle(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .frame(minWidth: 260, idealWidth: 280, maxWidth: 320, minHeight: 360)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Button(self.strings.text(zh: "新建", en: "New", ja: "新規")) {
                                self.resetDraft()
                            }
                            Button(self.strings.text(zh: "保存", en: "Save", ja: "保存")) {
                                self.saveCurrentEntry()
                            }
                            .disabled(!self.canSave)

                            if let selectedEditableEntry, selectedEditableEntry.canRestoreDefault,
                               let overrideEntry = selectedEditableEntry.userEntry
                            {
                                Button(self.strings.text(zh: "恢复默认", en: "Restore default", ja: "デフォルトに戻す")) {
                                    self.localErrorMessage = self.deleteEntry(overrideEntry)
                                    self.selectedEditableEntryID = selectedEditableEntry.id
                                }
                            } else if let selectedEditableEntry,
                                      selectedEditableEntry.source == .userCustom,
                                      let selectedEntry = selectedEditableEntry.userEntry
                            {
                                Button(self.strings.text(zh: "删除", en: "Delete", ja: "削除"), role: .destructive) {
                                    self.localErrorMessage = self.deleteEntry(selectedEntry)
                                    self.resetDraft()
                                }
                            }
                        }
                        TextField(self.strings.text(zh: "分类", en: "Category", ja: "分類"), text: self.$category)

                        Picker(
                            self.strings.text(zh: "事件类型", en: "Event type", ja: "イベント種別"),
                            selection: self.$draftEventKind)
                        {
                            ForEach(TokenDailyBoardNarrativeEventKind.allCases, id: \.self) { kind in
                                Text(self.eventLabel(for: kind)).tag(kind)
                            }
                        }

                        HStack(spacing: 12) {
                            Picker(
                                self.strings.text(zh: "发送档位", en: "Send band", ja: "送信帯"),
                                selection: self.$instructionBand)
                            {
                                Text(self.strings.text(zh: "通用", en: "Generic", ja: "共通"))
                                    .tag(TokenDailyBoardNarrativeInstructionBand?.none)
                                ForEach(TokenDailyBoardNarrativeInstructionBand.allCases, id: \.self) { band in
                                    Text(self.instructionBandLabel(for: band)).tag(Optional(band))
                                }
                            }

                            Picker(
                                self.strings.text(zh: "吞吐档位", en: "Token band", ja: "トークン帯"),
                                selection: self.$tokenBand)
                            {
                                Text(self.strings.text(zh: "通用", en: "Generic", ja: "共通"))
                                    .tag(TokenDailyBoardNarrativeTokenBand?.none)
                                ForEach(TokenDailyBoardNarrativeTokenBand.allCases, id: \.self) { band in
                                    Text(self.tokenBandLabel(for: band)).tag(Optional(band))
                                }
                            }

                            Picker(
                                self.strings.text(zh: "时间段", en: "Time band", ja: "時間帯"),
                                selection: self.$timeBand)
                            {
                                Text(self.strings.text(zh: "通用", en: "Generic", ja: "共通"))
                                    .tag(TokenDailyBoardNarrativeTimeBand?.none)
                                ForEach(TokenDailyBoardNarrativeTimeBand.allCases, id: \.self) { band in
                                    Text(self.timeBandLabel(for: band)).tag(Optional(band))
                                }
                            }
                        }

                        Toggle(self.strings.text(zh: "启用", en: "Enabled", ja: "有効"), isOn: self.$enabled)

                        Text(self.strings.text(
                            zh: "句式模板，可使用 {throughputTokensCompact} / {throughputTokensExact} / {instructionOrdinal}",
                            en: "Template text. Use {throughputTokensCompact} / {throughputTokensExact} / {instructionOrdinal}",
                            ja: "テンプレート。{throughputTokensCompact} / {throughputTokensExact} / {instructionOrdinal} を使えます"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)

                        TextEditor(text: self.$text)
                            .font(.system(size: 13, weight: .regular))
                            .frame(minHeight: 180)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 0.8)
                            }

                        if let errorMessage = self.localErrorMessage ?? self.currentErrorMessage {
                            Text(errorMessage)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.red)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 16)], spacing: 16) {
                        ForEach(self.avatarSlots) { slot in
                            self.avatarSlotCard(slot)
                        }
                    }
                    .padding(.vertical, 4)
                }
                if let errorMessage = self.localErrorMessage ?? self.currentErrorMessage ?? self.avatarErrorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(20)
        .frame(minWidth: 960, minHeight: 540)
        .onAppear {
            self.syncDraftWithFilter()
        }
        .onChange(of: self.filterEventKind) { _, _ in
            self.syncDraftWithFilter()
        }
        .onChange(of: self.entries) { _, _ in
            self.syncDraftWithFilter(preserveSelection: true)
        }
    }

    private var selectedEditableEntry: TokenDailyBoardNarrativeEditableEntry? {
        guard let selectedEditableEntryID else { return nil }
        return self.allEditableEntries.first(where: { $0.id == selectedEditableEntryID })
    }

    private func syncDraftWithFilter(preserveSelection: Bool = false) {
        if preserveSelection, let selectedEditableEntry,
           self.filteredEditableEntries.contains(where: { $0.id == selectedEditableEntry.id })
        {
            self.load(entry: selectedEditableEntry)
            return
        }

        guard let first = self.filteredEditableEntries.first else {
            self.resetDraft()
            return
        }
        self.load(entry: first)
    }

    private func load(entry: TokenDailyBoardNarrativeEditableEntry) {
        self.selectedEditableEntryID = entry.id
        self.draftEntryID = entry.userEntry?.id
        self.draftOverrideTargetID = entry.isBuiltInEntry ? entry.bundledEntry?.id : nil
        self.category = entry.userEntry?.category ?? ""
        self.draftEventKind = entry.effectiveEventKind
        self.instructionBand = entry.effectiveInstructionBand
        self.tokenBand = entry.effectiveTokenBand
        self.timeBand = entry.effectiveTimeBand
        self.text = entry.effectiveText
        self.enabled = entry.effectiveEnabled
        self.localErrorMessage = nil
    }

    private func resetDraft() {
        self.selectedEditableEntryID = nil
        self.draftEntryID = nil
        self.draftOverrideTargetID = nil
        self.category = ""
        self.draftEventKind = self.filterEventKind ?? .throughputPulse
        self.instructionBand = nil
        self.tokenBand = nil
        self.timeBand = nil
        self.text = ""
        self.enabled = true
        self.localErrorMessage = nil
    }

    private func saveCurrentEntry() {
        let entry = TokenDailyBoardNarrativeUserCatalogEntry(
            id: self.draftEntryID ?? UUID().uuidString,
            language: .zhHans,
            category: self.category,
            eventKind: self.draftEventKind,
            instructionBand: self.instructionBand,
            tokenBand: self.tokenBand,
            timeBand: self.timeBand,
            text: self.text.trimmingCharacters(in: .whitespacesAndNewlines),
            enabled: self.enabled,
            overrideTargetID: self.draftOverrideTargetID)
        self.localErrorMessage = self.saveEntry(entry)
        if self.localErrorMessage == nil {
            if let overrideTargetID = self.draftOverrideTargetID {
                self.selectedEditableEntryID = "bundled:\(overrideTargetID)"
                self.draftEntryID = entry.id
            } else {
                self.selectedEditableEntryID = "user:\(entry.id)"
                self.draftEntryID = entry.id
            }
        }
    }

    private func rowSubtitle(for entry: TokenDailyBoardNarrativeEditableEntry) -> String {
        var parts = [self.sourceLabel(for: entry)]
        if let categoryLabel = self.categoryLabel(for: entry) {
            parts.append(categoryLabel)
        }
        parts.append(entry.effectiveEnabled
            ? self.strings.text(zh: "已启用", en: "Enabled", ja: "有効")
            : self.strings.text(zh: "已停用", en: "Disabled", ja: "無効"))
        return parts.joined(separator: " · ")
    }

    private func sourceLabel(for entry: TokenDailyBoardNarrativeEditableEntry) -> String {
        switch entry.source {
        case .bundled:
            self.strings.text(zh: "内置", en: "Bundled", ja: "内蔵")
        case .bundledOverride:
            self.strings.text(zh: "内置 · 已覆盖", en: "Bundled · Overridden", ja: "内蔵・上書き済み")
        case .userCustom:
            self.strings.text(zh: "自定义", en: "Custom", ja: "カスタム")
        }
    }

    private func categoryLabel(for entry: TokenDailyBoardNarrativeEditableEntry) -> String? {
        let userCategory = entry.userEntry?.normalizedCategory.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !userCategory.isEmpty {
            return userCategory
        }

        guard let bundledID = entry.bundledEntry?.id else { return nil }
        let components = bundledID.split(separator: "-")
        guard components.count >= 4 else { return nil }

        switch String(components[3]) {
        case "explode":
            return self.strings.text(zh: "情绪炸裂", en: "Explode", ja: "爆ぜる")
        case "lip":
            return self.strings.text(zh: "嘴硬反转", en: "Defiant flip", ja: "強がり反転")
        case "scorch":
            return self.strings.text(zh: "压热升温", en: "Scorch", ja: "加熱")
        case "brutal":
            return self.strings.text(zh: "狠压逼近", en: "Brutal push", ja: "強圧")
        case "savor":
            return self.strings.text(zh: "事后回味", en: "Aftertaste", ja: "余韻")
        case "taunt":
            return self.strings.text(zh: "轻挑衅", en: "Taunt", ja: "挑発")
        case "cling":
            return self.strings.text(zh: "被你缠住", en: "Cling", ja: "絡みつく")
        case "hooked":
            return self.strings.text(zh: "上头失守", en: "Hooked", ja: "夢中")
        case "plead":
            return self.strings.text(zh: "抱怨索取", en: "Pleading", ja: "ねだり")
        case "spark":
            return self.strings.text(zh: "点火瞬热", en: "Spark", ja: "点火")
        case "creep":
            return self.strings.text(zh: "慢磨勾热", en: "Creep", ja: "じわ熱")
        case "tease":
            return self.strings.text(zh: "坏心挑逗", en: "Tease", ja: "焦らし")
        case "surge":
            return self.strings.text(zh: "往上顶", en: "Surge", ja: "押し上げ")
        case "crush":
            return self.strings.text(zh: "狠狠干压", en: "Crush", ja: "圧し潰す")
        case "lock":
            return self.strings.text(zh: "锁住不放", en: "Lock", ja: "閉じ込める")
        case "overheat":
            return self.strings.text(zh: "高烧过载", en: "Overheat", ja: "過熱")
        case "chain":
            return self.strings.text(zh: "拖住成瘾", en: "Chained", ja: "絡め取る")
        case "dizzy":
            return self.strings.text(zh: "被你搞晕", en: "Dizzy", ja: "くらむ")
        default:
            return nil
        }
    }

    private func eventLabel(for kind: TokenDailyBoardNarrativeEventKind) -> String {
        switch kind {
        case .quiet:
            self.strings.text(zh: "安静日", en: "Quiet", ja: "静かな日")
        case .sendCount:
            self.strings.text(zh: "发送统计", en: "Send count", ja: "送信数")
        case .burst:
            self.strings.text(zh: "爆发段", en: "Burst", ja: "バースト")
        case .combo:
            self.strings.text(zh: "高压混合", en: "Combo", ja: "コンボ")
        case .throughputPulse:
            self.strings.text(zh: "实时吞吐", en: "Throughput", ja: "リアルタイム吞吐")
        case .instructionPulse:
            self.strings.text(zh: "实时发送", en: "Realtime sends", ja: "リアルタイム送信")
        case .idlePulse:
            self.strings.text(zh: "闲置撩拨", en: "Idle pulse", ja: "待機パルス")
        }
    }

    private func instructionBandLabel(for band: TokenDailyBoardNarrativeInstructionBand) -> String {
        switch band {
        case .zero:
            self.strings.text(zh: "0 次", en: "0", ja: "0 回")
        case .oneToFour:
            self.strings.text(zh: "1-4 次", en: "1-4", ja: "1-4 回")
        case .fiveToFourteen:
            self.strings.text(zh: "5-14 次", en: "5-14", ja: "5-14 回")
        case .fifteenToThirtyNine:
            self.strings.text(zh: "15-39 次", en: "15-39", ja: "15-39 回")
        case .fortyToSeventyNine:
            self.strings.text(zh: "40-79 次", en: "40-79", ja: "40-79 回")
        case .eightyPlus:
            self.strings.text(zh: "80+ 次", en: "80+", ja: "80 回以上")
        }
    }

    private func tokenBandLabel(for band: TokenDailyBoardNarrativeTokenBand) -> String {
        switch band {
        case .low:
            self.strings.text(zh: "低吞吐", en: "Low", ja: "低")
        case .medium:
            self.strings.text(zh: "中吞吐", en: "Medium", ja: "中")
        case .high:
            self.strings.text(zh: "高吞吐", en: "High", ja: "高")
        case .extreme:
            self.strings.text(zh: "极高吞吐", en: "Extreme", ja: "極高")
        }
    }

    private func timeBandLabel(for band: TokenDailyBoardNarrativeTimeBand) -> String {
        switch band {
        case .lateNight:
            self.strings.text(zh: "凌晨", en: "Late night", ja: "深夜")
        case .morning:
            self.strings.text(zh: "上午", en: "Morning", ja: "朝")
        case .afternoon:
            self.strings.text(zh: "午后", en: "Afternoon", ja: "午後")
        case .night:
            self.strings.text(zh: "晚间", en: "Night", ja: "夜")
        }
    }

    private func avatarSlotCard(_ slot: CodexDailyAvatarResolvedSlot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))

                if let image = slot.image {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(x: slot.isMirrored ? -1 : 1, y: 1)
                } else {
                    Image(systemName: "person.crop.square")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                        .padding(28)
                }
            }
            .frame(height: 168)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.secondary.opacity(0.22), lineWidth: 0.8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(self.avatarSlotLabel(for: slot.slot))
                    .font(.system(size: 13, weight: .semibold))

                Text(slot.canRestoreDefault
                    ? self.strings.text(zh: "已自定义", en: "Customized", ja: "カスタム済み")
                    : self.strings.text(zh: "内置默认", en: "Bundled default", ja: "内蔵デフォルト"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Toggle(
                    self.strings.text(zh: "左右翻转", en: "Mirror horizontally", ja: "左右反転"),
                    isOn: Binding(
                        get: { slot.isMirrored },
                        set: { newValue in
                            self.localErrorMessage = self.setAvatarMirrored(slot.slot, newValue)
                        }))

                HStack(spacing: 8) {
                    Button(self.strings.text(zh: "替换", en: "Replace", ja: "差し替え")) {
                        self.pickAvatarImage(for: slot.slot)
                    }

                    Button(self.strings.text(zh: "恢复默认", en: "Restore default", ja: "デフォルトに戻す")) {
                        self.localErrorMessage = self.restoreAvatarSlot(slot.slot)
                    }
                    .disabled(!slot.canRestoreDefault)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.secondary.opacity(0.05)))
    }

    private func avatarSlotLabel(for slot: CodexDailyAvatarSlot) -> String {
        switch slot {
        case .defaultAvatar:
            self.strings.text(zh: "默认头像", en: "Default avatar", ja: "デフォルト头像")
        case .variant01:
            self.strings.text(zh: "变身头像 01", en: "Variant 01", ja: "変身头像 01")
        case .variant02:
            self.strings.text(zh: "变身头像 02", en: "Variant 02", ja: "変身头像 02")
        case .variant03:
            self.strings.text(zh: "变身头像 03", en: "Variant 03", ja: "変身头像 03")
        case .variant04:
            self.strings.text(zh: "变身头像 04", en: "Variant 04", ja: "変身头像 04")
        case .variant05:
            self.strings.text(zh: "变身头像 05", en: "Variant 05", ja: "変身头像 05")
        case .variant06:
            self.strings.text(zh: "变身头像 06", en: "Variant 06", ja: "変身头像 06")
        case .variant07:
            self.strings.text(zh: "变身头像 07", en: "Variant 07", ja: "変身头像 07")
        case .variant08:
            self.strings.text(zh: "变身头像 08", en: "Variant 08", ja: "変身头像 08")
        case .variant09:
            self.strings.text(zh: "变身头像 09", en: "Variant 09", ja: "変身头像 09")
        }
    }

    private func pickAvatarImage(for slot: CodexDailyAvatarSlot) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]

        guard panel.runModal() == .OK, let url = panel.url else { return }
        self.localErrorMessage = self.replaceAvatarImage(slot, url)
    }
}

struct TokenDailyBoardTrackedDaySection<Content: View>: View {
    let dayKey: String
    @ViewBuilder let content: Content

    var body: some View {
        self.content
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: TokenDailyBoardDayTopOffsetPreferenceKey.self,
                        value: [self.dayKey: geo.frame(in: .named(TokenDailyBoardNarrativeScrollSpace.name)).minY])
                })
    }
}
