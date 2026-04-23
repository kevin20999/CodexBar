import CodexBarCore
import Foundation

public enum TokenDailyBoardDisplayMode: String, CaseIterable, Codable {
    case conversationOnly
    case conversationAndToday
    case fullBoard
}

package enum TokenDailyBoardConversationOnlyAnimationPreset: String, CaseIterable, Codable {
    case cinematic
    case aggressive
    case gentle
}

package struct TokenDailyBoardConversationOnlyDebugTuning: Equatable {
    package var contentOffset: CGSize
    package var windowWidth: CGFloat
    package var windowGlassOpacity: CGFloat
    package var windowGlassBlur: CGFloat
    package var enablesPreNarrativeWindowPulse: Bool
    package var enablesAvatarReplacementAnimation: Bool
    package var animationPreset: TokenDailyBoardConversationOnlyAnimationPreset
    package var pulseDurationScale: CGFloat
    package var avatarIntensityScale: CGFloat
    package var bodyTypewriterSpeedScale: CGFloat
    package var metadataTypewriterSpeedScale: CGFloat
    package var avatarSize: CGFloat
    package var bodyFontSize: CGFloat
    package var textColumnOffset: CGSize
    package var textColumnWidth: CGFloat
    package var bodyLineSpacing: CGFloat
    package var metadataFontSize: CGFloat
    package var metadataOpacity: CGFloat
    package var avatarEffectPreset: TokenDailyBoardConversationOnlyAvatarEffectPreset
    package var backgroundEffectPreset: TokenDailyBoardConversationOnlyBackgroundEffectPreset
    package var textEffectPreset: TokenDailyBoardConversationOnlyTextEffectPreset

    package init(
        contentOffset: CGSize,
        windowWidth: CGFloat,
        windowGlassOpacity: CGFloat,
        windowGlassBlur: CGFloat,
        enablesPreNarrativeWindowPulse: Bool,
        enablesAvatarReplacementAnimation: Bool,
        animationPreset: TokenDailyBoardConversationOnlyAnimationPreset,
        pulseDurationScale: CGFloat,
        avatarIntensityScale: CGFloat,
        bodyTypewriterSpeedScale: CGFloat,
        metadataTypewriterSpeedScale: CGFloat,
        avatarSize: CGFloat,
        bodyFontSize: CGFloat,
        textColumnOffset: CGSize,
        textColumnWidth: CGFloat,
        bodyLineSpacing: CGFloat,
        metadataFontSize: CGFloat,
        metadataOpacity: CGFloat,
        avatarEffectPreset: TokenDailyBoardConversationOnlyAvatarEffectPreset = .avatar01,
        backgroundEffectPreset: TokenDailyBoardConversationOnlyBackgroundEffectPreset = .background01,
        textEffectPreset: TokenDailyBoardConversationOnlyTextEffectPreset = .text01)
    {
        self.contentOffset = contentOffset
        self.windowWidth = windowWidth
        self.windowGlassOpacity = windowGlassOpacity
        self.windowGlassBlur = windowGlassBlur
        self.enablesPreNarrativeWindowPulse = enablesPreNarrativeWindowPulse
        self.enablesAvatarReplacementAnimation = enablesAvatarReplacementAnimation
        self.animationPreset = animationPreset
        self.pulseDurationScale = pulseDurationScale
        self.avatarIntensityScale = avatarIntensityScale
        self.bodyTypewriterSpeedScale = bodyTypewriterSpeedScale
        self.metadataTypewriterSpeedScale = metadataTypewriterSpeedScale
        self.avatarSize = avatarSize
        self.bodyFontSize = bodyFontSize
        self.textColumnOffset = textColumnOffset
        self.textColumnWidth = textColumnWidth
        self.bodyLineSpacing = bodyLineSpacing
        self.metadataFontSize = metadataFontSize
        self.metadataOpacity = metadataOpacity
        self.avatarEffectPreset = avatarEffectPreset
        self.backgroundEffectPreset = backgroundEffectPreset
        self.textEffectPreset = textEffectPreset
    }
}

package struct TokenDailyBoardConversationOnlyWindowAppearance: Equatable {
    package var resolvedWindowWidth: CGFloat
    package var resolvedGlassOpacity: CGFloat
    package var resolvedGlassBlur: CGFloat
    package var blurOverlayOpacity: CGFloat
}

package enum TokenDailyBoardConversationOnlyDebugRules {
    package static let buttonSymbol = "arrow.up.and.down.and.arrow.left.and.right"

    package static let overallOffsetRange: ClosedRange<Double> = -120...120
    package static let overallOffsetStep: Double = 1
    package static let windowWidthRange: ClosedRange<Double> = 300...960
    package static let windowWidthStep: Double = 1
    package static let windowGlassOpacityRange: ClosedRange<Double> = 0.25...1.0
    package static let windowGlassOpacityStep: Double = 0.05
    package static let windowGlassBlurRange: ClosedRange<Double> = 0...24
    package static let windowGlassBlurStep: Double = 1
    package static let pulseDurationScaleRange: ClosedRange<Double> = 0.70...1.40
    package static let pulseDurationScaleStep: Double = 0.05
    package static let avatarIntensityScaleRange: ClosedRange<Double> = 0.60...1.50
    package static let avatarIntensityScaleStep: Double = 0.05
    package static let bodyTypewriterSpeedScaleRange: ClosedRange<Double> = 0.70...1.50
    package static let bodyTypewriterSpeedScaleStep: Double = 0.05
    package static let metadataTypewriterSpeedScaleRange: ClosedRange<Double> = 0.70...1.50
    package static let metadataTypewriterSpeedScaleStep: Double = 0.05
    package static let avatarSizeRange: ClosedRange<Double> = 40...92
    package static let avatarSizeStep: Double = 1
    package static let bodyFontSizeRange: ClosedRange<Double> = 16...32
    package static let bodyFontSizeStep: Double = 0.5
    package static let textColumnOffsetXRange: ClosedRange<Double> = -80...80
    package static let textColumnOffsetYRange: ClosedRange<Double> = -40...40
    package static let textColumnOffsetStep: Double = 1
    package static let textColumnWidthRange: ClosedRange<Double> = 120...515
    package static let textColumnWidthStep: Double = 1
    package static let bodyLineSpacingRange: ClosedRange<Double> = 0...12
    package static let bodyLineSpacingStep: Double = 0.5
    package static let metadataFontSizeRange: ClosedRange<Double> = 10...18
    package static let metadataFontSizeStep: Double = 0.5
    package static let metadataOpacityRange: ClosedRange<Double> = 0.2...1.0
    package static let metadataOpacityStep: Double = 0.05

    package static let defaultTuning = TokenDailyBoardConversationOnlyDebugTuning(
        contentOffset: CGSize(width: -101, height: -7),
        windowWidth: 92
            + TokenDailyBoardNarrativeLayout.conversationOnlyAvatarToContentSpacing
            + 284
            + (TokenDailyBoardConversationOnlyLayoutRules.compactWindowEdgeInset * 2),
        windowGlassOpacity: 0.95,
        windowGlassBlur: 0,
        enablesPreNarrativeWindowPulse: false,
        enablesAvatarReplacementAnimation: true,
        animationPreset: .cinematic,
        pulseDurationScale: 1,
        avatarIntensityScale: 1,
        bodyTypewriterSpeedScale: 1,
        metadataTypewriterSpeedScale: 1,
        avatarSize: 92,
        bodyFontSize: 16,
        textColumnOffset: CGSize(width: 3, height: 16),
        textColumnWidth: 284,
        bodyLineSpacing: 12,
        metadataFontSize: 10.5,
        metadataOpacity: 0.65,
        avatarEffectPreset: .avatar01,
        backgroundEffectPreset: .background01,
        textEffectPreset: .text01)
    package static let defaultOffset = defaultTuning.contentOffset
    package static let defaultOffsetX = Double(defaultTuning.contentOffset.width)
    package static let defaultOffsetY = Double(defaultTuning.contentOffset.height)

    package static func shouldShowPositionDebugger(for displayMode: TokenDailyBoardDisplayMode) -> Bool {
        displayMode == .conversationOnly
    }

    package static func resolvedTuning(
        _ tuning: TokenDailyBoardConversationOnlyDebugTuning,
        for displayMode: TokenDailyBoardDisplayMode)
        -> TokenDailyBoardConversationOnlyDebugTuning
    {
        self.shouldShowPositionDebugger(for: displayMode) ? self.clamp(tuning) : self.defaultTuning
    }

    package static func resolvedOffset(_ offset: CGSize, for displayMode: TokenDailyBoardDisplayMode) -> CGSize {
        self.shouldShowPositionDebugger(for: displayMode) ? offset : .zero
    }

    package static func maximumTextColumnWidth(for avatarSize: CGFloat) -> CGFloat {
        let shellMaximum = TokenDailyBoardConversationOnlyLayoutRules.contentWidth
            - avatarSize
            - TokenDailyBoardNarrativeLayout.conversationOnlyAvatarToContentSpacing
        let clampedShellMaximum = max(shellMaximum, CGFloat(self.textColumnWidthRange.lowerBound))
        return min(clampedShellMaximum, CGFloat(self.textColumnWidthRange.upperBound))
    }

    package static func resolvedTextColumnWidth(_ value: CGFloat, avatarSize: CGFloat) -> CGFloat {
        let clampedValue = self.clamp(value, to: self.textColumnWidthRange)
        return min(clampedValue, self.maximumTextColumnWidth(for: avatarSize))
    }

    package static func resolvedWindowWidth(
        _ value: CGFloat,
        visibleFrameWidth: CGFloat)
        -> CGFloat
    {
        min(self.clamp(value, to: self.windowWidthRange), visibleFrameWidth)
    }

    package static func resolvedWindowAppearance(
        _ tuning: TokenDailyBoardConversationOnlyDebugTuning,
        for displayMode: TokenDailyBoardDisplayMode)
        -> TokenDailyBoardConversationOnlyWindowAppearance
    {
        let resolvedTuning = self.resolvedTuning(tuning, for: displayMode)
        let naturalWidth = TokenDailyBoardConversationOnlyLayoutRules.compactWindowSize(for: resolvedTuning).width
        let blur = resolvedTuning.windowGlassBlur
        let blurProgress = self.windowGlassBlurRange.upperBound > 0
            ? min(max(Double(blur) / self.windowGlassBlurRange.upperBound, 0), 1)
            : 0
        return TokenDailyBoardConversationOnlyWindowAppearance(
            resolvedWindowWidth: naturalWidth,
            resolvedGlassOpacity: resolvedTuning.windowGlassOpacity,
            resolvedGlassBlur: blur,
            blurOverlayOpacity: CGFloat(blurProgress * 0.55))
    }

    package static func clamp(_ tuning: TokenDailyBoardConversationOnlyDebugTuning)
        -> TokenDailyBoardConversationOnlyDebugTuning
    {
        let avatarSize = self.clamp(tuning.avatarSize, to: self.avatarSizeRange)
        return TokenDailyBoardConversationOnlyDebugTuning(
            contentOffset: CGSize(
                width: self.clamp(tuning.contentOffset.width, to: self.overallOffsetRange),
                height: self.clamp(tuning.contentOffset.height, to: self.overallOffsetRange)),
            windowWidth: self.clamp(tuning.windowWidth, to: self.windowWidthRange),
            windowGlassOpacity: self.clamp(tuning.windowGlassOpacity, to: self.windowGlassOpacityRange),
            windowGlassBlur: self.clamp(tuning.windowGlassBlur, to: self.windowGlassBlurRange),
            enablesPreNarrativeWindowPulse: tuning.enablesPreNarrativeWindowPulse,
            enablesAvatarReplacementAnimation: tuning.enablesAvatarReplacementAnimation,
            animationPreset: tuning.animationPreset,
            pulseDurationScale: self.clamp(tuning.pulseDurationScale, to: self.pulseDurationScaleRange),
            avatarIntensityScale: self.clamp(tuning.avatarIntensityScale, to: self.avatarIntensityScaleRange),
            bodyTypewriterSpeedScale: self.clamp(
                tuning.bodyTypewriterSpeedScale,
                to: self.bodyTypewriterSpeedScaleRange),
            metadataTypewriterSpeedScale: self.clamp(
                tuning.metadataTypewriterSpeedScale,
                to: self.metadataTypewriterSpeedScaleRange),
            avatarSize: avatarSize,
            bodyFontSize: self.clamp(tuning.bodyFontSize, to: self.bodyFontSizeRange),
            textColumnOffset: CGSize(
                width: self.clamp(tuning.textColumnOffset.width, to: self.textColumnOffsetXRange),
                height: self.clamp(tuning.textColumnOffset.height, to: self.textColumnOffsetYRange)),
            textColumnWidth: self.resolvedTextColumnWidth(tuning.textColumnWidth, avatarSize: avatarSize),
            bodyLineSpacing: self.clamp(tuning.bodyLineSpacing, to: self.bodyLineSpacingRange),
            metadataFontSize: self.clamp(tuning.metadataFontSize, to: self.metadataFontSizeRange),
            metadataOpacity: self.clamp(tuning.metadataOpacity, to: self.metadataOpacityRange),
            avatarEffectPreset: tuning.avatarEffectPreset,
            backgroundEffectPreset: tuning.backgroundEffectPreset,
            textEffectPreset: tuning.textEffectPreset)
    }

    package static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }

    package static func clamp(_ value: CGFloat, to range: ClosedRange<Double>) -> CGFloat {
        CGFloat(self.clamp(Double(value), to: range))
    }
}

@MainActor
public final class CodexDailySettingsStore {
    private enum Keys {
        static let refreshFrequency = "refreshFrequency"
        static let legacyRefreshIntervalSeconds = "refreshIntervalSeconds"
        static let sessionRootPath = "sessionRootPath"
        static let didImportLegacyCache = "didImportLegacyCache"
        static let narrativeBodyFontScale = "narrativeBodyFontScale"
        static let boardDisplayMode = "boardDisplayMode"
        static let conversationOnlyPinned = "conversationOnlyPinned"
        static let titlebarControlsCollapsed = "titlebarControlsCollapsed"
        static let windowOriginX = "windowOriginX"
        static let windowOriginY = "windowOriginY"
        static let conversationOnlyDebugPanelOriginX = "conversationOnlyDebugPanelOriginX"
        static let conversationOnlyDebugPanelOriginY = "conversationOnlyDebugPanelOriginY"
        static let conversationOnlyContentOffsetX = "conversationOnlyContentOffsetX"
        static let conversationOnlyContentOffsetY = "conversationOnlyContentOffsetY"
        static let conversationOnlyWindowWidth = "conversationOnlyWindowWidth"
        static let conversationOnlyWindowGlassOpacity = "conversationOnlyWindowGlassOpacity"
        static let conversationOnlyWindowGlassBlur = "conversationOnlyWindowGlassBlur"
        static let conversationOnlyPreNarrativeWindowPulse = "conversationOnlyPreNarrativeWindowPulse"
        static let conversationOnlyAvatarReplacementAnimation = "conversationOnlyAvatarReplacementAnimation"
        static let conversationOnlyAnimationPreset = "conversationOnlyAnimationPreset"
        static let conversationOnlyPulseDurationScale = "conversationOnlyPulseDurationScale"
        static let conversationOnlyAvatarIntensityScale = "conversationOnlyAvatarIntensityScale"
        static let conversationOnlyBodyTypewriterSpeedScale = "conversationOnlyBodyTypewriterSpeedScale"
        static let conversationOnlyMetadataTypewriterSpeedScale = "conversationOnlyMetadataTypewriterSpeedScale"
        static let conversationOnlyAvatarSize = "conversationOnlyAvatarSize"
        static let conversationOnlyBodyFontSize = "conversationOnlyBodyFontSize"
        static let conversationOnlyTextColumnOffsetX = "conversationOnlyTextColumnOffsetX"
        static let conversationOnlyTextColumnOffsetY = "conversationOnlyTextColumnOffsetY"
        static let conversationOnlyTextColumnWidth = "conversationOnlyTextColumnWidth"
        static let conversationOnlyBodyLineSpacing = "conversationOnlyBodyLineSpacing"
        static let conversationOnlyMetadataFontSize = "conversationOnlyMetadataFontSize"
        static let conversationOnlyMetadataOpacity = "conversationOnlyMetadataOpacity"
        static let conversationOnlyAvatarEffectPreset = "conversationOnlyAvatarEffectPreset"
        static let conversationOnlyBackgroundEffectPreset = "conversationOnlyBackgroundEffectPreset"
        static let conversationOnlyTextEffectPreset = "conversationOnlyTextEffectPreset"
    }

    private static let narrativeBodyFontScaleRange: ClosedRange<Double> = 0.7...1.3

    private let defaults: UserDefaults
    private var storedNarrativeBodyFontScale: Double
    private var storedBoardDisplayMode: TokenDailyBoardDisplayMode
    private var storedConversationOnlyPinned: Bool
    private var storedTitlebarControlsCollapsed: Bool
    private var storedWindowOrigin: CGPoint?
    private var storedDebugPanelOrigin: CGPoint?
    private var storedConversationOnlyDebugTuning: TokenDailyBoardConversationOnlyDebugTuning

    public var refreshFrequency: TokenRefreshFrequency {
        didSet {
            self.defaults.set(self.refreshFrequency.rawValue, forKey: Keys.refreshFrequency)
        }
    }

    public var sessionRootPath: String {
        didSet {
            self.defaults.set(self.sessionRootPath, forKey: Keys.sessionRootPath)
        }
    }

    public var didImportLegacyCache: Bool {
        didSet {
            self.defaults.set(self.didImportLegacyCache, forKey: Keys.didImportLegacyCache)
        }
    }

    public var narrativeBodyFontScale: Double {
        get {
            self.storedNarrativeBodyFontScale
        }
        set {
            self.storedNarrativeBodyFontScale = Self.clampNarrativeBodyFontScale(newValue)
            self.defaults.set(self.storedNarrativeBodyFontScale, forKey: Keys.narrativeBodyFontScale)
        }
    }

    public var boardDisplayMode: TokenDailyBoardDisplayMode {
        get {
            self.storedBoardDisplayMode
        }
        set {
            self.storedBoardDisplayMode = newValue
            self.defaults.set(newValue.rawValue, forKey: Keys.boardDisplayMode)
        }
    }

    package var isConversationOnlyPinned: Bool {
        get {
            self.storedConversationOnlyPinned
        }
        set {
            self.storedConversationOnlyPinned = newValue
            self.defaults.set(newValue, forKey: Keys.conversationOnlyPinned)
        }
    }

    package var titlebarControlsCollapsed: Bool {
        get {
            self.storedTitlebarControlsCollapsed
        }
        set {
            self.storedTitlebarControlsCollapsed = newValue
            self.defaults.set(newValue, forKey: Keys.titlebarControlsCollapsed)
        }
    }

    package var windowOrigin: CGPoint? {
        get {
            self.storedWindowOrigin
        }
        set {
            self.storedWindowOrigin = newValue.map { CGPoint(x: $0.x.rounded(), y: $0.y.rounded()) }
            if let storedWindowOrigin {
                self.defaults.set(storedWindowOrigin.x, forKey: Keys.windowOriginX)
                self.defaults.set(storedWindowOrigin.y, forKey: Keys.windowOriginY)
            } else {
                self.defaults.removeObject(forKey: Keys.windowOriginX)
                self.defaults.removeObject(forKey: Keys.windowOriginY)
            }
        }
    }

    package var debugPanelOrigin: CGPoint? {
        get {
            self.storedDebugPanelOrigin
        }
        set {
            self.storedDebugPanelOrigin = newValue.map { CGPoint(x: $0.x.rounded(), y: $0.y.rounded()) }
            if let storedDebugPanelOrigin {
                self.defaults.set(storedDebugPanelOrigin.x, forKey: Keys.conversationOnlyDebugPanelOriginX)
                self.defaults.set(storedDebugPanelOrigin.y, forKey: Keys.conversationOnlyDebugPanelOriginY)
            } else {
                self.defaults.removeObject(forKey: Keys.conversationOnlyDebugPanelOriginX)
                self.defaults.removeObject(forKey: Keys.conversationOnlyDebugPanelOriginY)
            }
        }
    }

    package var conversationOnlyDebugTuning: TokenDailyBoardConversationOnlyDebugTuning {
        get {
            self.storedConversationOnlyDebugTuning
        }
        set {
            self.storedConversationOnlyDebugTuning = TokenDailyBoardConversationOnlyDebugRules.clamp(newValue)
            self.persistConversationOnlyDebugTuning(self.storedConversationOnlyDebugTuning)
        }
    }

    public init(userDefaults: UserDefaults? = nil) {
        self.defaults = userDefaults
            ?? UserDefaults(suiteName: CodexDailyAppIdentity.defaultsSuiteName)
            ?? .standard
        self.refreshFrequency = Self.loadRefreshFrequency(defaults: self.defaults)
        self.sessionRootPath = self.defaults.string(forKey: Keys.sessionRootPath)
            ?? NSString(string: "~/.codex/sessions").expandingTildeInPath
        self.didImportLegacyCache = self.defaults.bool(forKey: Keys.didImportLegacyCache)
        self.storedNarrativeBodyFontScale = Self.loadNarrativeBodyFontScale(defaults: self.defaults)
        self.storedBoardDisplayMode = Self.loadBoardDisplayMode(defaults: self.defaults)
        self.storedConversationOnlyPinned = Self.loadConversationOnlyPinned(defaults: self.defaults)
        self.storedTitlebarControlsCollapsed = Self.loadTitlebarControlsCollapsed(defaults: self.defaults)
        self.storedWindowOrigin = Self.loadWindowOrigin(defaults: self.defaults)
        self.storedDebugPanelOrigin = Self.loadDebugPanelOrigin(defaults: self.defaults)
        self.storedConversationOnlyDebugTuning = Self.loadConversationOnlyDebugTuning(defaults: self.defaults)
    }

    public var sessionRootURL: URL {
        URL(fileURLWithPath: NSString(string: self.sessionRootPath).expandingTildeInPath, isDirectory: true)
    }

    public var narrativeUserCatalogFileURL: URL {
        CodexDailyAppIdentity.narrativeUserCatalogFileURL
    }

    private static func loadRefreshFrequency(defaults: UserDefaults) -> TokenRefreshFrequency {
        if let rawValue = defaults.string(forKey: Keys.refreshFrequency),
           let frequency = TokenRefreshFrequency(rawValue: rawValue)
        {
            return frequency
        }

        if let legacyInterval = defaults.object(forKey: Keys.legacyRefreshIntervalSeconds) as? TimeInterval {
            switch legacyInterval {
            case ...5:
                return .fiveSeconds
            case ...10:
                return .tenSeconds
            case ...15:
                return .fifteenSeconds
            default:
                return .tenSeconds
            }
        }

        return .tenSeconds
    }

    private static func loadNarrativeBodyFontScale(defaults: UserDefaults) -> Double {
        guard defaults.object(forKey: Keys.narrativeBodyFontScale) != nil else { return 1.0 }
        return self.clampNarrativeBodyFontScale(defaults.double(forKey: Keys.narrativeBodyFontScale))
    }

    private static func loadBoardDisplayMode(defaults: UserDefaults) -> TokenDailyBoardDisplayMode {
        guard let rawValue = defaults.string(forKey: Keys.boardDisplayMode),
              let mode = TokenDailyBoardDisplayMode(rawValue: rawValue)
        else {
            return .fullBoard
        }
        return mode
    }

    private static func loadConversationOnlyPinned(defaults: UserDefaults) -> Bool {
        guard defaults.object(forKey: Keys.conversationOnlyPinned) != nil else {
            return false
        }
        return defaults.bool(forKey: Keys.conversationOnlyPinned)
    }

    private static func loadTitlebarControlsCollapsed(defaults: UserDefaults) -> Bool {
        guard defaults.object(forKey: Keys.titlebarControlsCollapsed) != nil else {
            return true
        }
        return defaults.bool(forKey: Keys.titlebarControlsCollapsed)
    }

    private static func loadWindowOrigin(defaults: UserDefaults) -> CGPoint? {
        guard defaults.object(forKey: Keys.windowOriginX) != nil,
              defaults.object(forKey: Keys.windowOriginY) != nil
        else {
            return nil
        }
        return CGPoint(
            x: defaults.double(forKey: Keys.windowOriginX),
            y: defaults.double(forKey: Keys.windowOriginY))
    }

    private static func loadDebugPanelOrigin(defaults: UserDefaults) -> CGPoint? {
        guard defaults.object(forKey: Keys.conversationOnlyDebugPanelOriginX) != nil,
              defaults.object(forKey: Keys.conversationOnlyDebugPanelOriginY) != nil
        else {
            return nil
        }
        return CGPoint(
            x: defaults.double(forKey: Keys.conversationOnlyDebugPanelOriginX),
            y: defaults.double(forKey: Keys.conversationOnlyDebugPanelOriginY))
    }

    private static func loadConversationOnlyDebugTuning(defaults: UserDefaults)
        -> TokenDailyBoardConversationOnlyDebugTuning
    {
        let defaultsTuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        return TokenDailyBoardConversationOnlyDebugRules.clamp(
            TokenDailyBoardConversationOnlyDebugTuning(
                contentOffset: CGSize(
                    width: self.loadConversationOnlyTuningValue(
                        defaults: defaults,
                        key: Keys.conversationOnlyContentOffsetX,
                        defaultValue: defaultsTuning.contentOffset.width,
                        range: TokenDailyBoardConversationOnlyDebugRules.overallOffsetRange),
                    height: self.loadConversationOnlyTuningValue(
                        defaults: defaults,
                        key: Keys.conversationOnlyContentOffsetY,
                        defaultValue: defaultsTuning.contentOffset.height,
                        range: TokenDailyBoardConversationOnlyDebugRules.overallOffsetRange)),
                windowWidth: self.loadConversationOnlyTuningValue(
                    defaults: defaults,
                    key: Keys.conversationOnlyWindowWidth,
                    defaultValue: defaultsTuning.windowWidth,
                    range: TokenDailyBoardConversationOnlyDebugRules.windowWidthRange),
                windowGlassOpacity: self.loadConversationOnlyTuningValue(
                    defaults: defaults,
                    key: Keys.conversationOnlyWindowGlassOpacity,
                    defaultValue: defaultsTuning.windowGlassOpacity,
                    range: TokenDailyBoardConversationOnlyDebugRules.windowGlassOpacityRange),
                windowGlassBlur: self.loadConversationOnlyTuningValue(
                    defaults: defaults,
                    key: Keys.conversationOnlyWindowGlassBlur,
                    defaultValue: defaultsTuning.windowGlassBlur,
                    range: TokenDailyBoardConversationOnlyDebugRules.windowGlassBlurRange),
                enablesPreNarrativeWindowPulse: defaults.object(
                    forKey: Keys.conversationOnlyPreNarrativeWindowPulse) != nil
                    ? defaults.bool(forKey: Keys.conversationOnlyPreNarrativeWindowPulse)
                    : defaultsTuning.enablesPreNarrativeWindowPulse,
                enablesAvatarReplacementAnimation: defaults.object(
                    forKey: Keys.conversationOnlyAvatarReplacementAnimation) != nil
                    ? defaults.bool(forKey: Keys.conversationOnlyAvatarReplacementAnimation)
                    : defaultsTuning.enablesAvatarReplacementAnimation,
                animationPreset: TokenDailyBoardConversationOnlyAnimationPreset(
                    rawValue: defaults.string(forKey: Keys.conversationOnlyAnimationPreset) ?? "")
                    ?? defaultsTuning.animationPreset,
                pulseDurationScale: self.loadConversationOnlyTuningValue(
                    defaults: defaults,
                    key: Keys.conversationOnlyPulseDurationScale,
                    defaultValue: defaultsTuning.pulseDurationScale,
                    range: TokenDailyBoardConversationOnlyDebugRules.pulseDurationScaleRange),
                avatarIntensityScale: self.loadConversationOnlyTuningValue(
                    defaults: defaults,
                    key: Keys.conversationOnlyAvatarIntensityScale,
                    defaultValue: defaultsTuning.avatarIntensityScale,
                    range: TokenDailyBoardConversationOnlyDebugRules.avatarIntensityScaleRange),
                bodyTypewriterSpeedScale: self.loadConversationOnlyTuningValue(
                    defaults: defaults,
                    key: Keys.conversationOnlyBodyTypewriterSpeedScale,
                    defaultValue: defaultsTuning.bodyTypewriterSpeedScale,
                    range: TokenDailyBoardConversationOnlyDebugRules.bodyTypewriterSpeedScaleRange),
                metadataTypewriterSpeedScale: self.loadConversationOnlyTuningValue(
                    defaults: defaults,
                    key: Keys.conversationOnlyMetadataTypewriterSpeedScale,
                    defaultValue: defaultsTuning.metadataTypewriterSpeedScale,
                    range: TokenDailyBoardConversationOnlyDebugRules.metadataTypewriterSpeedScaleRange),
                avatarSize: self.loadConversationOnlyTuningValue(
                    defaults: defaults,
                    key: Keys.conversationOnlyAvatarSize,
                    defaultValue: defaultsTuning.avatarSize,
                    range: TokenDailyBoardConversationOnlyDebugRules.avatarSizeRange),
                bodyFontSize: self.loadConversationOnlyTuningValue(
                    defaults: defaults,
                    key: Keys.conversationOnlyBodyFontSize,
                    defaultValue: defaultsTuning.bodyFontSize,
                    range: TokenDailyBoardConversationOnlyDebugRules.bodyFontSizeRange),
                textColumnOffset: CGSize(
                    width: self.loadConversationOnlyTuningValue(
                        defaults: defaults,
                        key: Keys.conversationOnlyTextColumnOffsetX,
                        defaultValue: defaultsTuning.textColumnOffset.width,
                        range: TokenDailyBoardConversationOnlyDebugRules.textColumnOffsetXRange),
                    height: self.loadConversationOnlyTuningValue(
                        defaults: defaults,
                        key: Keys.conversationOnlyTextColumnOffsetY,
                        defaultValue: defaultsTuning.textColumnOffset.height,
                        range: TokenDailyBoardConversationOnlyDebugRules.textColumnOffsetYRange)),
                textColumnWidth: self.loadConversationOnlyTuningValue(
                    defaults: defaults,
                    key: Keys.conversationOnlyTextColumnWidth,
                    defaultValue: defaultsTuning.textColumnWidth,
                    range: TokenDailyBoardConversationOnlyDebugRules.textColumnWidthRange),
                bodyLineSpacing: self.loadConversationOnlyTuningValue(
                    defaults: defaults,
                    key: Keys.conversationOnlyBodyLineSpacing,
                    defaultValue: defaultsTuning.bodyLineSpacing,
                    range: TokenDailyBoardConversationOnlyDebugRules.bodyLineSpacingRange),
                metadataFontSize: self.loadConversationOnlyTuningValue(
                    defaults: defaults,
                    key: Keys.conversationOnlyMetadataFontSize,
                    defaultValue: defaultsTuning.metadataFontSize,
                    range: TokenDailyBoardConversationOnlyDebugRules.metadataFontSizeRange),
                metadataOpacity: self.loadConversationOnlyTuningValue(
                    defaults: defaults,
                    key: Keys.conversationOnlyMetadataOpacity,
                    defaultValue: defaultsTuning.metadataOpacity,
                    range: TokenDailyBoardConversationOnlyDebugRules.metadataOpacityRange),
                avatarEffectPreset: TokenDailyBoardConversationOnlyAvatarEffectPreset(
                    rawValue: defaults.string(forKey: Keys.conversationOnlyAvatarEffectPreset) ?? "")
                    ?? defaultsTuning.avatarEffectPreset,
                backgroundEffectPreset: TokenDailyBoardConversationOnlyBackgroundEffectPreset(
                    rawValue: defaults.string(forKey: Keys.conversationOnlyBackgroundEffectPreset) ?? "")
                    ?? defaultsTuning.backgroundEffectPreset,
                textEffectPreset: TokenDailyBoardConversationOnlyTextEffectPreset(
                    rawValue: defaults.string(forKey: Keys.conversationOnlyTextEffectPreset) ?? "")
                    ?? defaultsTuning.textEffectPreset))
    }

    private func persistConversationOnlyDebugTuning(_ tuning: TokenDailyBoardConversationOnlyDebugTuning) {
        self.defaults.set(Double(tuning.contentOffset.width), forKey: Keys.conversationOnlyContentOffsetX)
        self.defaults.set(Double(tuning.contentOffset.height), forKey: Keys.conversationOnlyContentOffsetY)
        self.defaults.set(Double(tuning.windowWidth), forKey: Keys.conversationOnlyWindowWidth)
        self.defaults.set(Double(tuning.windowGlassOpacity), forKey: Keys.conversationOnlyWindowGlassOpacity)
        self.defaults.set(Double(tuning.windowGlassBlur), forKey: Keys.conversationOnlyWindowGlassBlur)
        self.defaults.set(tuning.enablesPreNarrativeWindowPulse, forKey: Keys.conversationOnlyPreNarrativeWindowPulse)
        self.defaults.set(
            tuning.enablesAvatarReplacementAnimation,
            forKey: Keys.conversationOnlyAvatarReplacementAnimation)
        self.defaults.set(tuning.animationPreset.rawValue, forKey: Keys.conversationOnlyAnimationPreset)
        self.defaults.set(Double(tuning.pulseDurationScale), forKey: Keys.conversationOnlyPulseDurationScale)
        self.defaults.set(Double(tuning.avatarIntensityScale), forKey: Keys.conversationOnlyAvatarIntensityScale)
        self.defaults.set(
            Double(tuning.bodyTypewriterSpeedScale),
            forKey: Keys.conversationOnlyBodyTypewriterSpeedScale)
        self.defaults.set(
            Double(tuning.metadataTypewriterSpeedScale),
            forKey: Keys.conversationOnlyMetadataTypewriterSpeedScale)
        self.defaults.set(Double(tuning.avatarSize), forKey: Keys.conversationOnlyAvatarSize)
        self.defaults.set(Double(tuning.bodyFontSize), forKey: Keys.conversationOnlyBodyFontSize)
        self.defaults.set(Double(tuning.textColumnOffset.width), forKey: Keys.conversationOnlyTextColumnOffsetX)
        self.defaults.set(Double(tuning.textColumnOffset.height), forKey: Keys.conversationOnlyTextColumnOffsetY)
        self.defaults.set(Double(tuning.textColumnWidth), forKey: Keys.conversationOnlyTextColumnWidth)
        self.defaults.set(Double(tuning.bodyLineSpacing), forKey: Keys.conversationOnlyBodyLineSpacing)
        self.defaults.set(Double(tuning.metadataFontSize), forKey: Keys.conversationOnlyMetadataFontSize)
        self.defaults.set(Double(tuning.metadataOpacity), forKey: Keys.conversationOnlyMetadataOpacity)
        self.defaults.set(tuning.avatarEffectPreset.rawValue, forKey: Keys.conversationOnlyAvatarEffectPreset)
        self.defaults.set(
            tuning.backgroundEffectPreset.rawValue,
            forKey: Keys.conversationOnlyBackgroundEffectPreset)
        self.defaults.set(tuning.textEffectPreset.rawValue, forKey: Keys.conversationOnlyTextEffectPreset)
    }

    private static func loadConversationOnlyTuningValue(
        defaults: UserDefaults,
        key: String,
        defaultValue: CGFloat,
        range: ClosedRange<Double>)
        -> CGFloat
    {
        guard defaults.object(forKey: key) != nil else { return defaultValue }
        return TokenDailyBoardConversationOnlyDebugRules.clamp(
            CGFloat(defaults.double(forKey: key)),
            to: range)
    }

    private static func clampNarrativeBodyFontScale(_ value: Double) -> Double {
        min(max(value, self.narrativeBodyFontScaleRange.lowerBound), self.narrativeBodyFontScaleRange.upperBound)
    }
}
