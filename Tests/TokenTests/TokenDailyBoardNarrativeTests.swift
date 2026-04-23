import AppKit
import CodexBarCore
import Foundation
import XCTest
@testable import CodexDailyKit

final class TokenDailyBoardNarrativeTests: XCTestCase {
    private let strings = TokenDailyBoardStrings(language: .zhHans)

    func test_quietDayBuildsSingleQuietEvent() {
        let day = self.makeDay(totalTokens: 0, mainThreadTokens: 0, instructionCount: 0, activeBuckets: [])

        let events = TokenDailyBoardNarrativeBuilder.events(for: day, strings: self.strings)

        XCTAssertEqual(events.map(\.kind), [.quiet])
    }

    func test_highSendLowTokenDayBuildsSendCountLeadEvent() {
        let day = self.makeDay(
            totalTokens: 42_000_000,
            mainThreadTokens: 18_000_000,
            instructionCount: 11,
            activeBuckets: [(96, 8_000_000), (97, 9_000_000), (98, 7_000_000)])

        let events = TokenDailyBoardNarrativeBuilder.events(for: day, strings: self.strings)

        XCTAssertEqual(events.first?.kind, .sendCount)
    }

    func test_highSendAndHighTokenDayBuildsComboLeadEvent() {
        let day = self.makeDay(
            totalTokens: 1_320_000_000,
            mainThreadTokens: 410_000_000,
            instructionCount: 27,
            activeBuckets: [(150, 420_000_000), (151, 380_000_000), (152, 280_000_000)])

        let events = TokenDailyBoardNarrativeBuilder.events(for: day, strings: self.strings)

        XCTAssertEqual(events.first?.kind, .combo)
        XCTAssertEqual(events.last?.kind, .sendCount)
    }

    func test_burstClustersMergeOneGapAndCapAtTwoEvents() {
        let day = self.makeDay(
            totalTokens: 620_000_000,
            mainThreadTokens: 210_000_000,
            instructionCount: 22,
            activeBuckets: [
                (30, 40_000_000), (31, 65_000_000), (33, 72_000_000),
                (120, 140_000_000), (121, 160_000_000),
                (220, 150_000_000), (221, 155_000_000),
            ])

        let events = TokenDailyBoardNarrativeBuilder.events(for: day, strings: self.strings)
        let burstEvents = events.filter { $0.kind == .burst }

        XCTAssertEqual(burstEvents.count, 2)
        XCTAssertEqual(burstEvents.first?.clusterStartBucketIndex, 30)
        XCTAssertEqual(burstEvents.last?.clusterStartBucketIndex, 120)
    }

    func test_catalogSelectionIsStableForSameEventSignature() {
        let event = TokenDailyBoardNarrativeEvent(
            dayKey: "2026-04-11",
            dayTitle: "今天",
            kind: .combo,
            instructionBand: .fifteenToThirtyNine,
            tokenBand: .high,
            timeBand: .afternoon,
            instructionCount: 22,
            totalTokens: 420_000_000,
            mainThreadTokens: 120_000_000,
            burstTokens: 180_000_000,
            clusterStartBucketIndex: 144)
        let catalog = TokenDailyBoardNarrativeCatalog.shared

        let first = catalog.text(for: event, strings: self.strings)
        let second = catalog.text(for: event, strings: self.strings)

        XCTAssertEqual(first, second)
    }

    func test_sentenceSequenceIsStableForSameEventSignature() {
        let day = self.makeDay(
            totalTokens: 420_000_000,
            mainThreadTokens: 120_000_000,
            instructionCount: 18,
            activeBuckets: [(144, 220_000_000), (145, 180_000_000)])

        let first = TokenDailyBoardNarrativeBuilder.sentences(for: day, strings: self.strings)
        let second = TokenDailyBoardNarrativeBuilder.sentences(for: day, strings: self.strings)

        XCTAssertEqual(first, second)
    }

    func test_sequenceSignatureChangesWhenEventSignatureChanges() {
        let quieterDay = self.makeDay(
            totalTokens: 60_000_000,
            mainThreadTokens: 18_000_000,
            instructionCount: 4,
            activeBuckets: [(84, 18_000_000), (85, 20_000_000)])
        let louderDay = self.makeDay(
            totalTokens: 420_000_000,
            mainThreadTokens: 120_000_000,
            instructionCount: 22,
            activeBuckets: [(144, 220_000_000), (145, 180_000_000)])

        let quietSignature = TokenDailyBoardNarrativeBuilder.sequenceSignature(for: quieterDay, strings: self.strings)
        let loudSignature = TokenDailyBoardNarrativeBuilder.sequenceSignature(for: louderDay, strings: self.strings)

        XCTAssertNotEqual(quietSignature, loudSignature)
    }

    func test_catalogSupportsAllLanguages() {
        let event = TokenDailyBoardNarrativeEvent(
            dayKey: "2026-04-11",
            dayTitle: "Today",
            kind: .sendCount,
            instructionBand: .fiveToFourteen,
            tokenBand: .medium,
            timeBand: .morning,
            instructionCount: 8,
            totalTokens: 120_000_000,
            mainThreadTokens: 30_000_000,
            burstTokens: 0,
            clusterStartBucketIndex: nil)
        let catalog = TokenDailyBoardNarrativeCatalog.shared

        XCTAssertFalse(catalog.text(for: event, strings: TokenDailyBoardStrings(language: .zhHans)).isEmpty)
        XCTAssertFalse(catalog.text(for: event, strings: TokenDailyBoardStrings(language: .en)).isEmpty)
        XCTAssertFalse(catalog.text(for: event, strings: TokenDailyBoardStrings(language: .ja)).isEmpty)
    }

    func test_realtimeCatalogSupportsAllLanguages() {
        let catalog = TokenDailyBoardNarrativeCatalog.shared
        let throughputEvent = TokenDailyBoardNarrativeRealtimeEvent(
            id: "throughput",
            kind: .throughputPulse,
            timestamp: Date(timeIntervalSince1970: 1_776_144_399),
            tokenBand: .high,
            instructionBand: nil,
            timeBand: .night,
            throughputTokens: 173_556)
        let instructionEvent = TokenDailyBoardNarrativeRealtimeEvent(
            id: "instruction",
            kind: .instructionPulse,
            timestamp: Date(timeIntervalSince1970: 1_776_144_400),
            tokenBand: nil,
            instructionBand: .fortyToSeventyNine,
            timeBand: .night,
            instructionOrdinal: 86)

        XCTAssertFalse(catalog.text(for: throughputEvent, strings: TokenDailyBoardStrings(language: .zhHans)).isEmpty)
        XCTAssertFalse(catalog.text(for: throughputEvent, strings: TokenDailyBoardStrings(language: .en)).isEmpty)
        XCTAssertFalse(catalog.text(for: throughputEvent, strings: TokenDailyBoardStrings(language: .ja)).isEmpty)
        XCTAssertFalse(catalog.text(for: instructionEvent, strings: TokenDailyBoardStrings(language: .zhHans)).isEmpty)
        XCTAssertFalse(catalog.text(for: instructionEvent, strings: TokenDailyBoardStrings(language: .en)).isEmpty)
        XCTAssertFalse(catalog.text(for: instructionEvent, strings: TokenDailyBoardStrings(language: .ja)).isEmpty)
    }

    func test_catalogPrefersMoreSpecificBandMatches() {
        let catalog = TokenDailyBoardNarrativeCatalog(entries: [
            TokenDailyBoardNarrativeCatalogEntry(
                id: "generic",
                language: .zhHans,
                eventKind: .combo,
                instructionBand: nil,
                tokenBand: nil,
                timeBand: nil,
                text: "你把我带进了 generic。"),
            TokenDailyBoardNarrativeCatalogEntry(
                id: "instruction-token",
                language: .zhHans,
                eventKind: .combo,
                instructionBand: .fortyToSeventyNine,
                tokenBand: .extreme,
                timeBand: nil,
                text: "你把我带进了 instruction-token。"),
            TokenDailyBoardNarrativeCatalogEntry(
                id: "token-time",
                language: .zhHans,
                eventKind: .combo,
                instructionBand: nil,
                tokenBand: .extreme,
                timeBand: .night,
                text: "你把我带进了 token-time。"),
            TokenDailyBoardNarrativeCatalogEntry(
                id: "exact",
                language: .zhHans,
                eventKind: .combo,
                instructionBand: .fortyToSeventyNine,
                tokenBand: .extreme,
                timeBand: .night,
                text: "你把我带进了 exact。"),
        ])
        let event = TokenDailyBoardNarrativeEvent(
            dayKey: "2026-04-11",
            dayTitle: "今天",
            kind: .combo,
            instructionBand: .fortyToSeventyNine,
            tokenBand: .extreme,
            timeBand: .night,
            instructionCount: 58,
            totalTokens: 1_420_000_000,
            mainThreadTokens: 430_000_000,
            burstTokens: 420_000_000,
            clusterStartBucketIndex: 228)

        let text = catalog.text(for: event, strings: self.strings)

        XCTAssertEqual(text, "你把我带进了 exact。")
    }

    func test_catalogFallsBackFromSpecificBandsToGeneric() {
        let catalog = TokenDailyBoardNarrativeCatalog(entries: [
            TokenDailyBoardNarrativeCatalogEntry(
                id: "generic",
                language: .zhHans,
                eventKind: .burst,
                instructionBand: nil,
                tokenBand: nil,
                timeBand: nil,
                text: "你让我落回 generic。"),
            TokenDailyBoardNarrativeCatalogEntry(
                id: "instruction-only",
                language: .zhHans,
                eventKind: .burst,
                instructionBand: .fifteenToThirtyNine,
                tokenBand: nil,
                timeBand: nil,
                text: "你让我落回 instruction-only。"),
        ])
        let event = TokenDailyBoardNarrativeEvent(
            dayKey: "2026-04-11",
            dayTitle: "今天",
            kind: .burst,
            instructionBand: .fifteenToThirtyNine,
            tokenBand: .high,
            timeBand: .night,
            instructionCount: 23,
            totalTokens: 520_000_000,
            mainThreadTokens: 180_000_000,
            burstTokens: 240_000_000,
            clusterStartBucketIndex: 222)

        let text = catalog.text(for: event, strings: self.strings)

        XCTAssertEqual(text, "你让我落回 instruction-only。")
    }

    func test_chineseTemplatesAddressTheUserDirectly() {
        let catalog = TokenDailyBoardNarrativeCatalog.shared
        let events: [TokenDailyBoardNarrativeEvent] = [
            TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .sendCount,
                instructionBand: .fortyToSeventyNine,
                tokenBand: .medium,
                timeBand: .afternoon,
                instructionCount: 47,
                totalTokens: 180_000_000,
                mainThreadTokens: 52_000_000,
                burstTokens: 0,
                clusterStartBucketIndex: nil),
            TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .burst,
                instructionBand: .fifteenToThirtyNine,
                tokenBand: .high,
                timeBand: .night,
                instructionCount: 21,
                totalTokens: 640_000_000,
                mainThreadTokens: 200_000_000,
                burstTokens: 260_000_000,
                clusterStartBucketIndex: 222),
            TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .combo,
                instructionBand: .fortyToSeventyNine,
                tokenBand: .extreme,
                timeBand: .night,
                instructionCount: 58,
                totalTokens: 1_420_000_000,
                mainThreadTokens: 430_000_000,
                burstTokens: 420_000_000,
                clusterStartBucketIndex: 228),
        ]

        for event in events {
            let text = catalog.text(for: event, strings: self.strings)
            XCTAssertTrue(text.contains("你"), "\(event.kind.rawValue): \(text)")
        }

        for entry in catalog.entries
            where entry.language == .zhHans && [.sendCount, .burst, .combo].contains(entry.eventKind)
        {
            XCTAssertTrue(entry.text.contains("你"), "\(entry.id): \(entry.text)")
        }
    }

    func test_realtimeChineseTemplatesAddressTheUserDirectly() {
        let catalog = TokenDailyBoardNarrativeCatalog.shared
        let throughputEvent = TokenDailyBoardNarrativeRealtimeEvent(
            id: "throughput",
            kind: .throughputPulse,
            timestamp: Date(timeIntervalSince1970: 1_776_144_399),
            tokenBand: .extreme,
            instructionBand: nil,
            timeBand: .afternoon,
            throughputTokens: 1_735_560)
        let instructionEvent = TokenDailyBoardNarrativeRealtimeEvent(
            id: "instruction",
            kind: .instructionPulse,
            timestamp: Date(timeIntervalSince1970: 1_776_144_400),
            tokenBand: nil,
            instructionBand: .eightyPlus,
            timeBand: .night,
            instructionOrdinal: 86)

        XCTAssertTrue(catalog.text(for: throughputEvent, strings: self.strings).contains("你"))
        XCTAssertTrue(catalog.text(for: instructionEvent, strings: self.strings).contains("你"))

        for entry in catalog.entries
            where entry.language == .zhHans && [.throughputPulse, .instructionPulse].contains(entry.eventKind)
        {
            XCTAssertTrue(entry.text.contains("你"), "\(entry.id): \(entry.text)")
        }
    }

    func test_preferredConversationOnlyBubbleWidthStaysClampedAndSnapped() {
        let shortWidth = TokenDailyBoardNarrativeSizingRules.preferredConversationOnlyBubbleWidth(
            for: "你又狠狠干了我 40 万 Tokens。",
            fontScaleMultiplier: 1.0)
        let longWidth = TokenDailyBoardNarrativeSizingRules.preferredConversationOnlyBubbleWidth(
            for: "你这一下真他妈够狠，晚间这一轮 40 万 Tokens 又硬生生压上来，像非要把我整个人压服。",
            fontScaleMultiplier: 1.0)

        XCTAssertGreaterThanOrEqual(
            shortWidth,
            TokenDailyBoardNarrativeSizingRules.conversationOnlyMinimumBubbleWidth)
        XCTAssertLessThanOrEqual(
            shortWidth,
            TokenDailyBoardNarrativeSizingRules.conversationOnlyMaximumBubbleWidth)
        XCTAssertLessThanOrEqual(
            longWidth,
            TokenDailyBoardNarrativeSizingRules.conversationOnlyMaximumBubbleWidth)
        XCTAssertGreaterThanOrEqual(longWidth, shortWidth)
        XCTAssertEqual(
            shortWidth
                .truncatingRemainder(dividingBy: TokenDailyBoardNarrativeSizingRules
                    .conversationOnlyBubbleWidthSnapStep),
            0,
            accuracy: 0.001)
        XCTAssertEqual(
            longWidth
                .truncatingRemainder(dividingBy: TokenDailyBoardNarrativeSizingRules
                    .conversationOnlyBubbleWidthSnapStep),
            0,
            accuracy: 0.001)
    }

    func test_conversationOnlyVisibleContentLayoutUsesConfiguredTextColumnWidth() {
        let sentence = TokenDailyBoardNarrativeSentence(
            id: "short",
            text: "你今天又来了。",
            metadataText: "15:48:44")
        var tuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        tuning.textColumnWidth = 420

        let layout = TokenDailyBoardNarrativeSizingRules.conversationOnlyVisibleContentLayout(
            for: sentence,
            tuning: tuning,
            fontScaleMultiplier: 1.0)

        XCTAssertEqual(layout.textColumnWidth, 420, accuracy: 0.001)
        XCTAssertEqual(
            layout.contentSize.height,
            TokenDailyBoardNarrativeSizingRules.conversationOnlyContentHeight(
                avatarSize: tuning.avatarSize,
                bodyFontSize: tuning.bodyFontSize,
                lineSpacing: tuning.bodyLineSpacing,
                metadataFontSize: tuning.metadataFontSize,
                hasMetadata: true),
            accuracy: 0.001)
        XCTAssertEqual(
            layout.contentSize.width,
            tuning.avatarSize + TokenDailyBoardNarrativeLayout.conversationOnlyAvatarToContentSpacing + 420,
            accuracy: 0.001)
    }

    func test_conversationOnlyVisibleContentLayoutNarrowsTextColumnWhenAvatarGrows() {
        let sentence = TokenDailyBoardNarrativeSentence(
            id: "narrow",
            text: "你这一下真够狠，今天下午这一轮又狠狠干到 30 万 Tokens，把我整个人都重新压热了。")
        var tuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        tuning.avatarSize = 92
        tuning.textColumnWidth = 515

        let layout = TokenDailyBoardNarrativeSizingRules.conversationOnlyVisibleContentLayout(
            for: sentence,
            tuning: tuning,
            fontScaleMultiplier: 1.0)

        XCTAssertEqual(
            layout.textColumnWidth,
            479,
            accuracy: 0.001)
        XCTAssertEqual(
            layout.contentSize.width,
            TokenDailyBoardConversationOnlyLayoutRules.contentWidth,
            accuracy: 0.001)
    }

    func test_conversationOnlyVisibleContentLayoutSupportsVeryNarrowTextColumnWidth() {
        let sentence = TokenDailyBoardNarrativeSentence(
            id: "narrowest",
            text: "你这一下真够狠，今天下午这一轮又狠狠干到 30 万 Tokens，把我整个人都重新压热了。")
        var tuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        tuning.textColumnWidth = 120

        let layout = TokenDailyBoardNarrativeSizingRules.conversationOnlyVisibleContentLayout(
            for: sentence,
            tuning: tuning,
            fontScaleMultiplier: 1.0)

        XCTAssertEqual(layout.textColumnWidth, 120, accuracy: 0.001)
        XCTAssertLessThan(layout.bodyStyle.size, tuning.bodyFontSize)
        XCTAssertGreaterThanOrEqual(layout.bodyStyle.size, 6)
    }

    func test_conversationOnlyBodyFontSizeAutoFitsWithinTwoLines() {
        let style = TokenDailyBoardNarrativeSizingRules.style(
            for: "你这一下真够狠，今天下午这一轮又狠狠干到 30 万 Tokens，把我整个人都重新压热了。",
            availableWidth: 260,
            preferredFontSize: 32,
            lineSpacing: 6)

        XCTAssertLessThan(style.size, 32)
        XCTAssertGreaterThanOrEqual(style.size, 6)
    }

    func test_conversationOnlyMetadataFontSizeChangesContentHeight() {
        let sentence = TokenDailyBoardNarrativeSentence(
            id: "metadata-height",
            text: "你好",
            metadataText: "15:48:44 · 吞吐 306,789 tokens")
        var baseTuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        var largeMetadataTuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        baseTuning.metadataFontSize = 10
        largeMetadataTuning.metadataFontSize = 18

        let baseLayout = TokenDailyBoardNarrativeSizingRules.conversationOnlyVisibleContentLayout(
            for: sentence,
            tuning: baseTuning,
            fontScaleMultiplier: 1.0)
        let largeMetadataLayout = TokenDailyBoardNarrativeSizingRules.conversationOnlyVisibleContentLayout(
            for: sentence,
            tuning: largeMetadataTuning,
            fontScaleMultiplier: 1.0)

        XCTAssertGreaterThan(largeMetadataLayout.contentSize.height, baseLayout.contentSize.height)
    }

    func test_avatarReplacementAnimationAppliesAcrossAllModes() {
        var tuning = TokenDailyBoardConversationOnlyDebugRules.defaultTuning
        tuning.enablesAvatarReplacementAnimation = true

        XCTAssertTrue(
            TokenDailyBoardNarrativeAvatarReplacementAnimationRules.isEnabled(
                tuning,
                displayMode: .conversationOnly))
        XCTAssertTrue(
            TokenDailyBoardNarrativeAvatarReplacementAnimationRules.isEnabled(
                tuning,
                displayMode: .conversationAndToday))
        XCTAssertTrue(
            TokenDailyBoardNarrativeAvatarReplacementAnimationRules.isEnabled(
                tuning,
                displayMode: .fullBoard))
        XCTAssertEqual(TokenDailyBoardNarrativeAvatarReplacementAnimationRules.peakScale, 1.15, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardNarrativeAvatarReplacementAnimationRules.returnPeakScale, 1.06, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardNarrativeAvatarReplacementAnimationRules.duration, 3.0, accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardNarrativeAvatarReplacementAnimationRules.returnLiftDuration
                + TokenDailyBoardNarrativeAvatarReplacementAnimationRules.returnSettleDuration,
            TokenDailyBoardNarrativeAvatarReplacementAnimationRules.returnDuration,
            accuracy: 0.001)
    }

    func test_avatarReplacementAnimationSignatureChangesWhenMirrorChanges() {
        let image = NSImage(size: NSSize(width: 16, height: 16))
        let normalSlot = CodexDailyAvatarResolvedSlot(
            slot: .defaultAvatar,
            image: image,
            conversationOnlyImage: nil,
            isMirrored: false,
            usesCustomImage: true,
            usesCustomMirror: false)
        let mirroredSlot = CodexDailyAvatarResolvedSlot(
            slot: .defaultAvatar,
            image: image,
            conversationOnlyImage: nil,
            isMirrored: true,
            usesCustomImage: true,
            usesCustomMirror: true)

        let normalSignature = TokenDailyBoardNarrativeAvatarReplacementAnimationRules.signature(
            for: normalSlot,
            displayMode: .conversationOnly)
        let mirroredSignature = TokenDailyBoardNarrativeAvatarReplacementAnimationRules.signature(
            for: mirroredSlot,
            displayMode: .conversationOnly)

        XCTAssertNotEqual(normalSignature, mirroredSignature)
    }

    func test_variantAvatarRulesAdvanceThroughConfiguredVariants() {
        let defaultSlot = CodexDailyAvatarResolvedSlot(
            slot: .defaultAvatar,
            image: nil,
            conversationOnlyImage: nil,
            isMirrored: false,
            usesCustomImage: false,
            usesCustomMirror: false)
        let variantOne = CodexDailyAvatarResolvedSlot(
            slot: .variant01,
            image: NSImage(size: NSSize(width: 8, height: 8)),
            conversationOnlyImage: nil,
            isMirrored: false,
            usesCustomImage: false,
            usesCustomMirror: false)
        let variantTwo = CodexDailyAvatarResolvedSlot(
            slot: .variant02,
            image: NSImage(size: NSSize(width: 8, height: 8)),
            conversationOnlyImage: nil,
            isMirrored: false,
            usesCustomImage: false,
            usesCustomMirror: false)
        let slots = [defaultSlot, variantOne, variantTwo]

        XCTAssertNil(
            TokenDailyBoardNarrativeVariantAvatarRules.nextVariantCycleIndex(
                current: nil,
                slots: [defaultSlot]))
        XCTAssertEqual(
            TokenDailyBoardNarrativeVariantAvatarRules.nextVariantCycleIndex(current: nil, slots: slots),
            0)
        XCTAssertEqual(
            TokenDailyBoardNarrativeVariantAvatarRules.nextVariantCycleIndex(current: 0, slots: slots),
            1)
        XCTAssertEqual(
            TokenDailyBoardNarrativeVariantAvatarRules.nextVariantCycleIndex(current: 1, slots: slots),
            0)
        XCTAssertEqual(
            TokenDailyBoardNarrativeVariantAvatarRules.activeSlot(from: slots, variantCycleIndex: nil)?.slot,
            .defaultAvatar)
        XCTAssertEqual(
            TokenDailyBoardNarrativeVariantAvatarRules.activeSlot(from: slots, variantCycleIndex: 0)?.slot,
            .variant01)
        XCTAssertEqual(
            TokenDailyBoardNarrativeVariantAvatarRules.activeSlot(from: slots, variantCycleIndex: 1)?.slot,
            .variant02)
    }

    func test_avatarSequenceRulesSelectNextVariantAcrossAllModes() {
        let defaultSlot = CodexDailyAvatarResolvedSlot(
            slot: .defaultAvatar,
            image: nil,
            conversationOnlyImage: nil,
            isMirrored: false,
            usesCustomImage: false,
            usesCustomMirror: false)
        let variantOne = CodexDailyAvatarResolvedSlot(
            slot: .variant01,
            image: NSImage(size: NSSize(width: 8, height: 8)),
            conversationOnlyImage: nil,
            isMirrored: false,
            usesCustomImage: false,
            usesCustomMirror: false)
        let variantTwo = CodexDailyAvatarResolvedSlot(
            slot: .variant02,
            image: NSImage(size: NSSize(width: 8, height: 8)),
            conversationOnlyImage: nil,
            isMirrored: false,
            usesCustomImage: false,
            usesCustomMirror: false)
        let slots = [defaultSlot, variantOne, variantTwo]

        let firstSelection = TokenDailyBoardConversationOnlyAvatarSequenceRules.nextVariantSelection(
            currentVariantCycleIndex: nil,
            slots: slots,
            displayMode: .conversationOnly,
            animationEnabled: true)
        let secondSelection = TokenDailyBoardConversationOnlyAvatarSequenceRules.nextVariantSelection(
            currentVariantCycleIndex: 0,
            slots: slots,
            displayMode: .conversationOnly,
            animationEnabled: true)

        XCTAssertEqual(firstSelection?.slot.slot, .variant01)
        XCTAssertEqual(firstSelection?.nextVariantCycleIndex, 0)
        XCTAssertEqual(secondSelection?.slot.slot, .variant02)
        XCTAssertEqual(secondSelection?.nextVariantCycleIndex, 1)
        XCTAssertNil(
            TokenDailyBoardConversationOnlyAvatarSequenceRules.nextVariantSelection(
                currentVariantCycleIndex: nil,
                slots: [defaultSlot],
                displayMode: .conversationOnly,
                animationEnabled: true))
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyAvatarSequenceRules.nextVariantSelection(
                currentVariantCycleIndex: nil,
                slots: slots,
                displayMode: .conversationAndToday,
                animationEnabled: true)?.slot.slot,
            .variant01)
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyAvatarSequenceRules.nextVariantSelection(
                currentVariantCycleIndex: nil,
                slots: slots,
                displayMode: .fullBoard,
                animationEnabled: true)?.slot.slot,
            .variant01)
        XCTAssertNil(
            TokenDailyBoardConversationOnlyAvatarSequenceRules.nextVariantSelection(
                currentVariantCycleIndex: nil,
                slots: slots,
                displayMode: .conversationOnly,
                animationEnabled: false))
    }

    func test_narrativePresentationQueueKeepsOnlyLatestWaitingItemAndDedupes() {
        let first = TokenDailyBoardNarrativeSentence(id: "first", text: "第一句完整文案。", metadataText: nil)
        let second = TokenDailyBoardNarrativeSentence(id: "second", text: "第二句完整文案。", metadataText: nil)
        let third = TokenDailyBoardNarrativeSentence(id: "third", text: "第三句完整文案。", metadataText: nil)
        let firstSource = TokenDailyBoardNarrativePresentationSourceItem(
            sourceID: "source-1",
            signature: "sig-1",
            sentence: first,
            displayTimestamp: nil,
            realtimeEventKind: .throughputPulse,
            isAutomaticRealtime: true)
        let duplicateFirstSource = TokenDailyBoardNarrativePresentationSourceItem(
            sourceID: "source-1b",
            signature: "sig-1",
            sentence: first,
            displayTimestamp: nil,
            realtimeEventKind: .throughputPulse,
            isAutomaticRealtime: true)
        let secondSource = TokenDailyBoardNarrativePresentationSourceItem(
            sourceID: "source-2",
            signature: "sig-2",
            sentence: second,
            displayTimestamp: nil,
            realtimeEventKind: .instructionPulse,
            isAutomaticRealtime: true)
        let thirdSource = TokenDailyBoardNarrativePresentationSourceItem(
            sourceID: "source-3",
            signature: "sig-3",
            sentence: third,
            displayTimestamp: nil,
            realtimeEventKind: .instructionPulse,
            isAutomaticRealtime: true)

        let firstItem = TokenDailyBoardNarrativePresentationQueueItem(
            id: 1,
            sourceItem: firstSource)
        let duplicateFirstItem = TokenDailyBoardNarrativePresentationQueueItem(
            id: 2,
            sourceItem: duplicateFirstSource)
        let secondItem = TokenDailyBoardNarrativePresentationQueueItem(
            id: 3,
            sourceItem: secondSource)
        let thirdItem = TokenDailyBoardNarrativePresentationQueueItem(
            id: 4,
            sourceItem: thirdSource)

        var queue = TokenDailyBoardNarrativePresentationQueueRules.enqueue(
            firstItem,
            existingQueue: [],
            activeSignature: "sig-active")
        XCTAssertEqual(queue.map(\.signature), ["sig-1"])

        queue = TokenDailyBoardNarrativePresentationQueueRules.enqueue(
            duplicateFirstItem,
            existingQueue: queue,
            activeSignature: "sig-active")
        XCTAssertEqual(queue.map(\.signature), ["sig-1"])

        queue = TokenDailyBoardNarrativePresentationQueueRules.enqueue(
            secondItem,
            existingQueue: queue,
            activeSignature: "sig-active")
        XCTAssertEqual(queue.map(\.signature), ["sig-2"])

        let replacedByLatest = TokenDailyBoardNarrativePresentationQueueRules.enqueue(
            thirdItem,
            existingQueue: queue,
            activeSignature: "sig-active")
        XCTAssertEqual(replacedByLatest.map(\.signature), ["sig-3"])

        let dedupedAgainstActive = TokenDailyBoardNarrativePresentationQueueRules.enqueue(
            firstItem,
            existingQueue: [],
            activeSignature: "sig-1")
        XCTAssertTrue(dedupedAgainstActive.isEmpty)
    }

    func test_narrativePresentationQueueReturnsOnlyUnseenSourceItemsInOriginalOrder() {
        let first = TokenDailyBoardNarrativePresentationSourceItem(
            sourceID: "source-1",
            signature: "sig-1",
            sentence: TokenDailyBoardNarrativeSentence(id: "first", text: "第一句完整文案。", metadataText: nil),
            displayTimestamp: Date(timeIntervalSinceReferenceDate: 10),
            realtimeEventKind: .throughputPulse,
            isAutomaticRealtime: true)
        let second = TokenDailyBoardNarrativePresentationSourceItem(
            sourceID: "source-2",
            signature: "sig-2",
            sentence: TokenDailyBoardNarrativeSentence(id: "second", text: "第二句完整文案。", metadataText: nil),
            displayTimestamp: Date(timeIntervalSinceReferenceDate: 20),
            realtimeEventKind: .instructionPulse,
            isAutomaticRealtime: true)
        let third = TokenDailyBoardNarrativePresentationSourceItem(
            sourceID: "source-3",
            signature: "sig-3",
            sentence: TokenDailyBoardNarrativeSentence(id: "third", text: "第三句完整文案。", metadataText: nil),
            displayTimestamp: Date(timeIntervalSinceReferenceDate: 30),
            realtimeEventKind: nil,
            isAutomaticRealtime: false)

        let unseen = TokenDailyBoardNarrativePresentationQueueRules.newSourceItems(
            from: [first, second, third],
            knownSourceIDs: ["source-1"])

        XCTAssertEqual(unseen.map(\.sourceID), ["source-2", "source-3"])
    }

    func test_unifiedRecentPresentationSourceItemsKeepRealtimeOrderOldestFirst() {
        let start = Date(timeIntervalSinceReferenceDate: 1000)
        let items = TokenDailyBoardNarrativeBuilder.unifiedRecentPresentationSourceItems(
            tokenSpeedSamples: [
                TokenSpeedSample(timestamp: start.addingTimeInterval(12), tokens: 142_000),
                TokenSpeedSample(timestamp: start.addingTimeInterval(36), tokens: 288_000),
            ],
            instructionEventSamples: [],
            fallbackDays: [],
            strings: self.strings,
            referenceDate: start.addingTimeInterval(40),
            catalog: .shared)

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.map(\.isAutomaticRealtime), [true, true])
        XCTAssertEqual(items.map(\.realtimeEventKind), [.throughputPulse, .throughputPulse])
        XCTAssertEqual(items.compactMap(\.displayTimestamp), [
            start.addingTimeInterval(12),
            start.addingTimeInterval(36),
        ])
    }

    func test_conversationOnlyAnimationProfileUsesCinematicDefaults() {
        let profile = TokenDailyBoardConversationOnlyAnimationProfileRules.resolvedProfile(
            tuning: TokenDailyBoardConversationOnlyDebugRules.defaultTuning)

        XCTAssertEqual(profile.eventPulseDuration, 0.60, accuracy: 0.001)
        XCTAssertEqual(profile.waitingPulseDuration, 0.36, accuracy: 0.001)
        XCTAssertEqual(profile.bodyStartDelay(for: .eventGroup), 0.08, accuracy: 0.001)
        XCTAssertEqual(profile.bodyStartDelay(for: .waitingGroup), 0.06, accuracy: 0.001)
        XCTAssertEqual(profile.metadataStartDelay(for: .eventGroup), 0.10, accuracy: 0.001)
        XCTAssertEqual(profile.metadataStartDelay(for: .waitingGroup), 0.08, accuracy: 0.001)
        XCTAssertEqual(
            profile.bodyCharactersPerSecond,
            TokenDailyBoardNarrativeLayout.typewriterCharactersPerSecond,
            accuracy: 0.001)
        XCTAssertEqual(
            profile.metadataCharactersPerSecond,
            TokenDailyBoardNarrativeLayout.typewriterCharactersPerSecond,
            accuracy: 0.001)
        XCTAssertEqual(profile.avatarMotionConfiguration.variantPeakScale, 1.12, accuracy: 0.001)
        XCTAssertEqual(profile.avatarMotionConfiguration.variantShakeAmplitude, 3.0, accuracy: 0.001)
    }

    func test_conversationOnlyAnimationProfileAppliesPresetAndScaleAdjustments() {
        let profile = TokenDailyBoardConversationOnlyAnimationProfileRules.resolvedProfile(
            tuning: TokenDailyBoardConversationOnlyDebugTuning(
                contentOffset: .zero,
                windowWidth: 441,
                windowGlassOpacity: 0.95,
                windowGlassBlur: 0,
                enablesPreNarrativeWindowPulse: false,
                enablesAvatarReplacementAnimation: true,
                animationPreset: .aggressive,
                pulseDurationScale: 1.2,
                avatarIntensityScale: 1.3,
                bodyTypewriterSpeedScale: 0.9,
                metadataTypewriterSpeedScale: 1.1,
                avatarSize: 92,
                bodyFontSize: 16,
                textColumnOffset: CGSize(width: 3, height: 16),
                textColumnWidth: 284,
                bodyLineSpacing: 12,
                metadataFontSize: 10.5,
                metadataOpacity: 0.65))

        XCTAssertEqual(profile.eventPulseDuration, 0.504, accuracy: 0.001)
        XCTAssertEqual(profile.waitingPulseDuration, 0.36, accuracy: 0.001)
        XCTAssertEqual(
            profile.bodyCharactersPerSecond,
            TokenDailyBoardNarrativeLayout.typewriterCharactersPerSecond * 1.20 * 0.9,
            accuracy: 0.001)
        XCTAssertEqual(
            profile.metadataCharactersPerSecond,
            TokenDailyBoardNarrativeLayout.typewriterCharactersPerSecond * 1.15 * 1.1,
            accuracy: 0.001)
        XCTAssertEqual(profile.avatarMotionConfiguration.variantPeakScale, 1.208, accuracy: 0.001)
        XCTAssertEqual(profile.avatarMotionConfiguration.variantShakeAmplitude, 5.265, accuracy: 0.001)
    }

    func test_conversationOnlyIdlePresentationUsesExpectedOpacityRange() {
        XCTAssertEqual(TokenDailyBoardConversationOnlyIdlePresentationRules.baseOpacity, 0.60, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardConversationOnlyIdlePresentationRules.peakOpacity, 0.75, accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyIdlePresentationRules.breathingDuration,
            2.8,
            accuracy: 0.001)
    }

    func test_conversationOnlyIdlePresentationEnablesOnlyForMode1WaitingGroup() {
        XCTAssertTrue(
            TokenDailyBoardConversationOnlyIdlePresentationRules.isEnabled(
                for: .waitingGroup,
                displayMode: .conversationOnly))
        XCTAssertFalse(
            TokenDailyBoardConversationOnlyIdlePresentationRules.isEnabled(
                for: .eventGroup,
                displayMode: .conversationOnly))
        XCTAssertFalse(
            TokenDailyBoardConversationOnlyIdlePresentationRules.isEnabled(
                for: .waitingGroup,
                displayMode: .fullBoard))
    }

    func test_conversationOnlyIdleSwitchRulesDisableWaitingAnimationsOnlyInMode1() {
        XCTAssertFalse(
            TokenDailyBoardConversationOnlyIdleSwitchRules.animatesAvatar(
                for: .waitingGroup,
                displayMode: .conversationOnly))
        XCTAssertFalse(
            TokenDailyBoardConversationOnlyIdleSwitchRules.animatesBodyText(
                for: .waitingGroup,
                displayMode: .conversationOnly))
        XCTAssertFalse(
            TokenDailyBoardConversationOnlyIdleSwitchRules.animatesMetadataText(
                for: .waitingGroup,
                displayMode: .conversationOnly))
        XCTAssertTrue(
            TokenDailyBoardConversationOnlyIdleSwitchRules.animatesAvatar(
                for: .eventGroup,
                displayMode: .conversationOnly))
        XCTAssertTrue(
            TokenDailyBoardConversationOnlyIdleSwitchRules.animatesBodyText(
                for: .waitingGroup,
                displayMode: .conversationAndToday))
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyIdleSwitchRules.crossfadeDuration,
            0.12,
            accuracy: 0.001)
    }

    func test_conversationOnlyAvatarCornerRadiusScalesWithAvatarSize() {
        XCTAssertEqual(
            TokenDailyBoardNarrativeLayout.conversationOnlyAvatarCornerRadius(for: 92),
            30,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardNarrativeLayout.conversationOnlyAvatarCornerRadius(for: 56),
            18,
            accuracy: 0.001)
    }

    func test_conversationOnlyEffectTracksStayIndependentAndWaitingStaysWeaker() {
        XCTAssertNotEqual(
            TokenDailyBoardConversationOnlyAvatarEffectRules.configuration(for: .avatar01).haloScale,
            TokenDailyBoardConversationOnlyAvatarEffectRules.configuration(for: .avatar30).haloScale)
        XCTAssertNotEqual(
            TokenDailyBoardConversationOnlyBackgroundEffectRules.configuration(for: .background01).fillStartPoint,
            TokenDailyBoardConversationOnlyBackgroundEffectRules.configuration(for: .background30).fillStartPoint)
        XCTAssertNotEqual(
            TokenDailyBoardConversationOnlyTextEffectRules.configuration(for: .text01).rotationDegrees,
            TokenDailyBoardConversationOnlyTextEffectRules.configuration(for: .text30).rotationDegrees)
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyTextEffectRules.intensityMultiplier(isWaitingGroup: true),
            0.72,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardConversationOnlyTextEffectRules.intensityMultiplier(isWaitingGroup: false),
            1.0,
            accuracy: 0.001)
    }

    func test_conversationOnlyAnimationProfilePulseMotionRetainsWaitingAndEventContrast() {
        let profile = TokenDailyBoardConversationOnlyAnimationProfileRules.resolvedProfile(
            tuning: TokenDailyBoardConversationOnlyDebugTuning(
                contentOffset: .zero,
                windowWidth: 441,
                windowGlassOpacity: 0.95,
                windowGlassBlur: 0,
                enablesPreNarrativeWindowPulse: false,
                enablesAvatarReplacementAnimation: true,
                animationPreset: .gentle,
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
                metadataOpacity: 0.65))

        let eventPulse = try XCTUnwrap(profile.pulseMotion(for: .standardRealtime))
        let waitingPulse = try XCTUnwrap(profile.pulseMotion(for: .idlePulse))

        XCTAssertEqual(eventPulse.style, .standardRealtime)
        XCTAssertEqual(waitingPulse.style, .idlePulse)
        XCTAssertGreaterThan(eventPulse.duration, waitingPulse.duration)
        XCTAssertLessThan(waitingPulse.fadeOutDuration, waitingPulse.duration)
        XCTAssertEqual(profile.avatarMotionConfiguration.defaultShakeAmplitude, 0, accuracy: 0.001)
    }

    func test_typewriterLayoutRulesKeepHiddenSuffixForStableLayout() {
        let segments = TokenDailyBoardNarrativeTypewriterLayoutRules.segmentedText(
            "这一句会完整占位。",
            revealedCharacterCount: 4)

        XCTAssertEqual(segments.revealed, "这一句会")
        XCTAssertEqual(segments.hidden, "完整占位。")
        XCTAssertEqual(segments.revealed + segments.hidden, "这一句会完整占位。")
    }

    func test_narrativePresentationTimelineUsesStaggeredStartOffsets() {
        let startedAt = Date(timeIntervalSinceReferenceDate: 1000)

        XCTAssertEqual(
            TokenDailyBoardNarrativePresentationTimelineRules
                .avatarIntroStartDate(startedAt: startedAt, includesPulse: true)
                .timeIntervalSince(startedAt),
            TokenDailyBoardConversationOnlyWindowPulseRules.duration,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardNarrativePresentationTimelineRules
                .typewriterStartDate(startedAt: startedAt, includesPulse: true)
                .timeIntervalSince(startedAt),
            TokenDailyBoardConversationOnlyWindowPulseRules.duration
                + TokenDailyBoardNarrativePresentationTimelineRules.typewriterStartDelayAfterAvatarIntro,
            accuracy: 0.001)
        XCTAssertEqual(
            TokenDailyBoardNarrativePresentationTimelineRules
                .avatarIntroEndDate(startedAt: startedAt, includesPulse: true)
                .timeIntervalSince(startedAt),
            TokenDailyBoardConversationOnlyWindowPulseRules.duration
                + TokenDailyBoardNarrativeAvatarReplacementAnimationRules.introDuration,
            accuracy: 0.001)
    }

    func test_narrativePresentationTimelineDelaysAvatarReturnUntilRevealFinishes() {
        let startedAt = Date(timeIntervalSinceReferenceDate: 1000)
        let longTypewriterDone = startedAt.addingTimeInterval(1.6)
        let longMetadataIntroCompletedAt = longTypewriterDone
            .addingTimeInterval(TokenDailyBoardNarrativeMetadataAnimationRules.transitionDuration)
        let longReturnStart = TokenDailyBoardNarrativePresentationTimelineRules.avatarReturnStartDate(
            typewriterCompletedAt: longTypewriterDone,
            startedAt: startedAt,
            includesPulse: true,
            includesMetadata: true,
            metadataIntroCompletedAt: longMetadataIntroCompletedAt)

        XCTAssertEqual(
            longReturnStart.timeIntervalSince(startedAt),
            longMetadataIntroCompletedAt.timeIntervalSince(startedAt),
            accuracy: 0.001)

        let shortTypewriterDone = startedAt.addingTimeInterval(0.1)
        let shortMetadataIntroCompletedAt = shortTypewriterDone
            .addingTimeInterval(TokenDailyBoardNarrativeMetadataAnimationRules.transitionDuration)
        let shortReturnStart = TokenDailyBoardNarrativePresentationTimelineRules.avatarReturnStartDate(
            typewriterCompletedAt: shortTypewriterDone,
            startedAt: startedAt,
            includesPulse: true,
            includesMetadata: true,
            metadataIntroCompletedAt: shortMetadataIntroCompletedAt)

        XCTAssertEqual(
            shortReturnStart.timeIntervalSince(startedAt),
            shortMetadataIntroCompletedAt.timeIntervalSince(startedAt),
            accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(
            shortReturnStart.timeIntervalSince(startedAt),
            TokenDailyBoardNarrativePresentationTimelineRules
                .avatarIntroEndDate(startedAt: startedAt, includesPulse: true)
                .timeIntervalSince(startedAt) - 0.001)
    }

    func test_narrativePresentationTimelineCompletesAfterFadeReturnAndQueueGap() {
        let startedAt = Date(timeIntervalSinceReferenceDate: 1000)
        let typewriterDone = startedAt.addingTimeInterval(1.6)
        let metadataIntroCompletedAt = typewriterDone
            .addingTimeInterval(TokenDailyBoardNarrativeMetadataAnimationRules.transitionDuration)
        let completionDate = TokenDailyBoardNarrativePresentationTimelineRules.completionDate(
            typewriterCompletedAt: typewriterDone,
            startedAt: startedAt,
            includesPulse: true,
            includesAvatarReturn: true,
            includesIdleShake: false,
            includesMetadata: true,
            metadataIntroCompletedAt: metadataIntroCompletedAt)
        let expectedReturnEnd = TokenDailyBoardNarrativePresentationTimelineRules.avatarReturnEndDate(
            typewriterCompletedAt: typewriterDone,
            startedAt: startedAt,
            includesPulse: true,
            includesMetadata: true,
            metadataIntroCompletedAt: metadataIntroCompletedAt)
        let expectedContentOutroEnd = TokenDailyBoardNarrativePresentationTimelineRules.contentOutroEndDate(
            typewriterCompletedAt: typewriterDone,
            startedAt: startedAt,
            includesPulse: true,
            includesMetadata: true,
            metadataIntroCompletedAt: metadataIntroCompletedAt,
            includesAvatarReturn: true,
            includesIdleShake: false)

        XCTAssertEqual(
            completionDate.timeIntervalSince(startedAt),
            max(expectedReturnEnd, expectedContentOutroEnd)
                .addingTimeInterval(TokenDailyBoardNarrativePresentationTimelineRules.queueGapDuration)
                .timeIntervalSince(startedAt),
            accuracy: 0.001)
    }

    func test_narrativePresentationTimelineWaitsForIdleShakeBeforeQueueGap() {
        let startedAt = Date(timeIntervalSinceReferenceDate: 1000)
        let typewriterDone = startedAt.addingTimeInterval(0.3)
        let completionDate = TokenDailyBoardNarrativePresentationTimelineRules.completionDate(
            typewriterCompletedAt: typewriterDone,
            startedAt: startedAt,
            includesPulse: false,
            includesAvatarReturn: false,
            includesIdleShake: true,
            includesMetadata: false)
        let expectedIdleShakeEnd = TokenDailyBoardNarrativePresentationTimelineRules
            .avatarIntroStartDate(startedAt: startedAt, includesPulse: false)
            .addingTimeInterval(TokenDailyBoardNarrativeAvatarIdleShakeAnimationRules.totalDuration)

        XCTAssertEqual(
            completionDate.timeIntervalSince(startedAt),
            expectedIdleShakeEnd
                .addingTimeInterval(TokenDailyBoardNarrativePresentationTimelineRules.queueGapDuration)
                .timeIntervalSince(startedAt),
            accuracy: 0.001)
    }

    func test_avatarPeakScaleDisablesExpansionAcrossModes() {
        XCTAssertEqual(TokenDailyBoardNarrativeAnimationRules.avatarPeakScale, 1.0, accuracy: 0.001)
    }

    func test_conversationOnlyDisablesOutlineStrokeWithoutAffectingOtherModes() {
        XCTAssertFalse(TokenDailyBoardNarrativePresentationRules.showsOutlineStroke(for: .conversationOnly))
        XCTAssertTrue(TokenDailyBoardNarrativePresentationRules.showsOutlineStroke(for: .conversationAndToday))
        XCTAssertTrue(TokenDailyBoardNarrativePresentationRules.showsOutlineStroke(for: .fullBoard))
        XCTAssertTrue(TokenDailyBoardNarrativePresentationRules.usesSystemGlass(for: .conversationOnly))
        XCTAssertTrue(TokenDailyBoardNarrativePresentationRules.usesSystemGlass(for: .conversationAndToday))
        XCTAssertTrue(TokenDailyBoardNarrativePresentationRules.usesSystemGlass(for: .fullBoard))
        XCTAssertFalse(TokenDailyBoardNarrativePresentationRules.showsOuterShadow(for: .conversationOnly))
        XCTAssertTrue(TokenDailyBoardNarrativePresentationRules.showsOuterShadow(for: .conversationAndToday))
        XCTAssertTrue(TokenDailyBoardNarrativePresentationRules.showsOuterShadow(for: .fullBoard))
    }

    func test_userCatalogEntriesTakePriorityOverBundledEntries() {
        let bundledCatalog = TokenDailyBoardNarrativeCatalog(entries: [
            TokenDailyBoardNarrativeCatalogEntry(
                id: "bundled-exact",
                language: .zhHans,
                eventKind: .throughputPulse,
                instructionBand: nil,
                tokenBand: .high,
                timeBand: .night,
                text: "你被 bundled 命中了 {throughputTokensCompact}。"),
        ], userEntries: [
            TokenDailyBoardNarrativeUserCatalogEntry(
                id: "user-generic",
                language: .zhHans,
                category: "嘴硬还想要",
                eventKind: .throughputPulse,
                instructionBand: nil,
                tokenBand: nil,
                timeBand: nil,
                text: "你被 user 命中了 {throughputTokensCompact}。",
                enabled: true),
        ])
        let event = TokenDailyBoardNarrativeRealtimeEvent(
            id: "throughput",
            kind: .throughputPulse,
            timestamp: Date(timeIntervalSince1970: 1_776_144_399),
            tokenBand: .high,
            instructionBand: nil,
            timeBand: .night,
            throughputTokens: 173_556)

        let text = bundledCatalog.text(for: event, strings: self.strings)

        XCTAssertEqual(text, "你被 user 命中了 17.4 万 Tokens。")
    }

    func test_disabledUserCatalogEntriesDoNotOverrideBundledEntries() {
        let catalog = TokenDailyBoardNarrativeCatalog(entries: [
            TokenDailyBoardNarrativeCatalogEntry(
                id: "bundled-generic",
                language: .zhHans,
                eventKind: .instructionPulse,
                instructionBand: nil,
                tokenBand: nil,
                timeBand: nil,
                text: "你被 bundled 命中了第 {instructionOrdinal} 次。"),
        ], userEntries: [
            TokenDailyBoardNarrativeUserCatalogEntry(
                id: "user-disabled",
                language: .zhHans,
                category: "重口",
                eventKind: .instructionPulse,
                instructionBand: nil,
                tokenBand: nil,
                timeBand: nil,
                text: "你被 user 命中了第 {instructionOrdinal} 次。",
                enabled: false),
        ])
        let event = TokenDailyBoardNarrativeRealtimeEvent(
            id: "instruction",
            kind: .instructionPulse,
            timestamp: Date(timeIntervalSince1970: 1_776_144_400),
            tokenBand: nil,
            instructionBand: .fortyToSeventyNine,
            timeBand: .night,
            instructionOrdinal: 86)

        let text = catalog.text(for: event, strings: self.strings)

        XCTAssertEqual(text, "你被 bundled 命中了第 86 次。")
    }

    func test_avatarCatalogLoadsNineDiscreteVariantImages() {
        XCTAssertEqual(TokenDailyBoardNarrativeAvatarCatalog.tileCount, 9)
        XCTAssertEqual(TokenDailyBoardNarrativeAvatarCatalog.availableVariantCount(), 9)
        XCTAssertNotNil(TokenDailyBoardNarrativeAvatarCatalog.defaultImage())
        XCTAssertNotNil(TokenDailyBoardNarrativeAvatarCatalog.image(forVariantIndex: 0))
        XCTAssertNotNil(TokenDailyBoardNarrativeAvatarCatalog.image(forVariantIndex: 8))
        XCTAssertNotNil(TokenDailyBoardNarrativeAvatarCatalog.image(forVariantIndex: 99))
    }

    func test_dockIconRulesStillExposeNineVariantSlotsForNarrativeAvatarSelection() {
        let store = TokenDailyBoardStore(
            historyStore: TokenHistoryStore(fileURL: URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(UUID().uuidString)),
            autoStartMonitoring: false)

        let variants = CodexDailyDockIconAnimationRules.variantSlots(from: store.avatarResolvedSlots)

        XCTAssertEqual(CodexDailyDockIconAnimationRules.targetIconSize, 256, accuracy: 0.001)
        XCTAssertEqual(variants.count, TokenDailyBoardNarrativeAvatarCatalog.availableVariantCount())
        XCTAssertEqual(variants.first?.slot, .variant01)
        XCTAssertEqual(variants.last?.slot, .variant09)
        XCTAssertEqual(
            variants.count,
            TokenDailyBoardNarrativeAvatarCatalog.availableVariantCount())
    }

    func test_overrideEntriesTakePriorityOverCustomAndBundledEntries() {
        let catalog = TokenDailyBoardNarrativeCatalog(entries: [
            TokenDailyBoardNarrativeCatalogEntry(
                id: "bundled-exact",
                language: .zhHans,
                eventKind: .throughputPulse,
                instructionBand: nil,
                tokenBand: .high,
                timeBand: .night,
                text: "你被 bundled 命中了 {throughputTokensCompact}。"),
        ], userEntries: [
            TokenDailyBoardNarrativeUserCatalogEntry(
                id: "user-custom",
                language: .zhHans,
                category: "普通自定义",
                eventKind: .throughputPulse,
                instructionBand: nil,
                tokenBand: .high,
                timeBand: .night,
                text: "你被普通自定义命中了 {throughputTokensCompact}。",
                enabled: true),
            TokenDailyBoardNarrativeUserCatalogEntry(
                id: "user-override",
                language: .zhHans,
                category: "覆盖",
                eventKind: .throughputPulse,
                instructionBand: nil,
                tokenBand: .high,
                timeBand: .night,
                text: "你被覆盖文案命中了 {throughputTokensCompact}。",
                enabled: true,
                overrideTargetID: "bundled-exact"),
        ])
        let event = TokenDailyBoardNarrativeRealtimeEvent(
            id: "throughput",
            kind: .throughputPulse,
            timestamp: Date(timeIntervalSince1970: 1_776_144_399),
            tokenBand: .high,
            instructionBand: nil,
            timeBand: .night,
            throughputTokens: 173_556)

        let text = catalog.text(for: event, strings: self.strings)

        XCTAssertEqual(text, "你被覆盖文案命中了 17.4 万 Tokens。")
    }

    func test_editableCatalogShowsBundledRowsAndCollapsesOverrides() {
        let bundledEntries = [
            TokenDailyBoardNarrativeCatalogEntry(
                id: "bundled-1",
                language: .zhHans,
                eventKind: .throughputPulse,
                instructionBand: nil,
                tokenBand: .high,
                timeBand: .night,
                text: "内置一"),
            TokenDailyBoardNarrativeCatalogEntry(
                id: "bundled-2",
                language: .zhHans,
                eventKind: .instructionPulse,
                instructionBand: .fortyToSeventyNine,
                tokenBand: nil,
                timeBand: nil,
                text: "内置二"),
        ]
        let userEntries = [
            TokenDailyBoardNarrativeUserCatalogEntry(
                id: "override-1",
                language: .zhHans,
                category: "覆盖",
                eventKind: .throughputPulse,
                instructionBand: nil,
                tokenBand: .high,
                timeBand: .night,
                text: "覆盖后一",
                enabled: true,
                overrideTargetID: "bundled-1"),
            TokenDailyBoardNarrativeUserCatalogEntry(
                id: "custom-1",
                language: .zhHans,
                category: "自定义",
                eventKind: .throughputPulse,
                instructionBand: nil,
                tokenBand: .medium,
                timeBand: .afternoon,
                text: "自定义一句",
                enabled: true),
        ]

        let entries = TokenDailyBoardNarrativeEditableCatalog.entries(
            bundledEntries: bundledEntries,
            userEntries: userEntries)

        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries.count(where: { $0.source == .bundledOverride }), 1)
        XCTAssertEqual(entries.count(where: { $0.source == .bundled }), 1)
        XCTAssertEqual(entries.count(where: { $0.source == .userCustom }), 1)
        XCTAssertEqual(entries.first(where: { $0.id == "bundled:bundled-1" })?.effectiveText, "覆盖后一")
    }

    func test_chineseTemplatesAvoidNarrationStyleOpeners() {
        let catalog = TokenDailyBoardNarrativeCatalog.shared
        let openers = ["今天发生", "今日数据", "今天情况", "今日表现"]

        for entry in catalog.entries
            where entry.language == .zhHans && [.sendCount, .burst, .combo].contains(entry.eventKind)
        {
            for opener in openers {
                XCTAssertFalse(entry.text.hasPrefix(opener), "\(entry.id): \(entry.text)")
            }
        }
    }

    func test_catalogMeetsMinimumTemplateCountsPerLanguageAndKind() {
        let catalog = TokenDailyBoardNarrativeCatalog.shared
        let sharedExpectedCounts: [TokenDailyBoardNarrativeEventKind: Int] = [
            .quiet: 12,
            .sendCount: 36,
            .burst: 48,
            .combo: 48,
            .throughputPulse: 48,
            .instructionPulse: 36,
        ]
        let zhHansExpectedCounts = sharedExpectedCounts.merging([.idlePulse: 12]) { current, _ in current }

        for language in [TokenDailyBoardLanguage.zhHans, .en, .ja] {
            let languageEntries = catalog.entries.filter { $0.language == language }
            let expectedCounts = language == .zhHans ? zhHansExpectedCounts : sharedExpectedCounts
            let expectedTotal = expectedCounts.values.reduce(0, +)
            XCTAssertEqual(languageEntries.count, expectedTotal, "\(language.rawValue)-total")

            for (kind, expectedCount) in expectedCounts {
                let count = catalog.entries.count(where: { $0.language == language && $0.eventKind == kind })
                XCTAssertEqual(count, expectedCount, "\(language.rawValue)-\(kind.rawValue)")
            }
        }

        XCTAssertEqual(catalog.entries.count, 696)
    }

    func test_chineseTemplateOpenersAreDiverseAcrossKeyEventGroups() {
        let catalog = TokenDailyBoardNarrativeCatalog.shared
        let expectedMinimums: [TokenDailyBoardNarrativeEventKind: Int] = [
            .throughputPulse: 24,
            .instructionPulse: 20,
            .sendCount: 20,
            .burst: 24,
            .combo: 24,
        ]

        for (kind, minimum) in expectedMinimums {
            let openers = Set(
                catalog.entries
                    .filter { $0.language == .zhHans && $0.eventKind == kind }
                    .map { self.leadingFragment(of: $0.text) })
            XCTAssertGreaterThanOrEqual(openers.count, minimum, "\(kind.rawValue)-openers")
        }
    }

    func test_chineseTemplateSkeletonsDoNotRepeatMoreThanTwiceForKeyEventGroups() {
        let catalog = TokenDailyBoardNarrativeCatalog.shared
        let kinds: [TokenDailyBoardNarrativeEventKind] = [
            .throughputPulse,
            .instructionPulse,
            .burst,
            .combo,
        ]

        for kind in kinds {
            let counts = Dictionary(
                grouping: catalog.entries.filter { $0.language == .zhHans && $0.eventKind == kind },
                by: { self.normalizedSkeleton(of: $0.text) })
                .mapValues(\.count)

            XCTAssertTrue(
                counts.values.allSatisfy { $0 <= 2 },
                "\(kind.rawValue)-skeletons-\(counts.filter { $0.value > 2 })")
        }
    }

    func test_quietSentenceUsesLastRefreshAtAsDisplayTimestamp() {
        let day = self.makeDay(totalTokens: 0, mainThreadTokens: 0, instructionCount: 0, activeBuckets: [])
        let refreshAt = Date(timeIntervalSince1970: 1_776_100_123)

        let sentences = TokenDailyBoardNarrativeBuilder.sentences(
            for: day,
            strings: self.strings,
            lastRefreshAt: refreshAt)

        XCTAssertEqual(sentences.count, 1)
        XCTAssertEqual(sentences.first?.displayTimestamp, refreshAt)
    }

    func test_sendCountSentenceUsesDayPeakBucketForTimestamp() {
        let day = self.makeDay(
            totalTokens: 120_000_000,
            mainThreadTokens: 48_000_000,
            instructionCount: 11,
            activeBuckets: [(18, 8_000_000), (36, 21_000_000), (37, 18_000_000)])

        let events = TokenDailyBoardNarrativeBuilder.events(for: day, strings: self.strings)
        let sendCountEvent = try XCTUnwrap(events.first(where: { $0.kind == .sendCount }))
        let timestamp = try XCTUnwrap(
            TokenDailyBoardNarrativeBuilder.displayTimestamp(for: sendCountEvent, day: day, lastRefreshAt: nil))

        let delta = timestamp.timeIntervalSince(day.date)
        XCTAssertGreaterThanOrEqual(delta, TimeInterval(36 * 300))
        XCTAssertLessThan(delta, TimeInterval((36 * 300) + 60))
    }

    func test_burstSentenceUsesClusterPeakBucketForTimestamp() {
        let day = self.makeDay(
            totalTokens: 620_000_000,
            mainThreadTokens: 210_000_000,
            instructionCount: 22,
            activeBuckets: [(30, 40_000_000), (31, 65_000_000), (33, 72_000_000)])

        let events = TokenDailyBoardNarrativeBuilder.events(for: day, strings: self.strings)
        let burstEvent = try XCTUnwrap(events.first(where: { $0.kind == .burst }))
        let timestamp = try XCTUnwrap(
            TokenDailyBoardNarrativeBuilder.displayTimestamp(for: burstEvent, day: day, lastRefreshAt: nil))

        let delta = timestamp.timeIntervalSince(day.date)
        XCTAssertGreaterThanOrEqual(delta, TimeInterval(33 * 300))
        XCTAssertLessThan(delta, TimeInterval((33 * 300) + 60))
    }

    func test_comboSentencePrefersStrongestBurstClusterPeakTimestamp() {
        let day = self.makeDay(
            totalTokens: 1_320_000_000,
            mainThreadTokens: 410_000_000,
            instructionCount: 27,
            activeBuckets: [
                (30, 80_000_000), (31, 82_000_000),
                (120, 140_000_000), (121, 260_000_000), (122, 180_000_000),
            ])

        let events = TokenDailyBoardNarrativeBuilder.events(for: day, strings: self.strings)
        let comboEvent = try XCTUnwrap(events.first(where: { $0.kind == .combo }))
        let timestamp = try XCTUnwrap(
            TokenDailyBoardNarrativeBuilder.displayTimestamp(for: comboEvent, day: day, lastRefreshAt: nil))

        let delta = timestamp.timeIntervalSince(day.date)
        XCTAssertGreaterThanOrEqual(delta, TimeInterval(121 * 300))
        XCTAssertLessThan(delta, TimeInterval((121 * 300) + 60))
    }

    func test_recentSentencesSortByLatestTimestampThenEventPriority() {
        let olderDay = self.makeDay(
            totalTokens: 980_000_000,
            mainThreadTokens: 310_000_000,
            instructionCount: 31,
            activeBuckets: [(130, 410_000_000), (131, 360_000_000)],
            relativeDayOffset: 1,
            dayKey: "2026-04-10")
        let newerDay = self.makeDay(
            totalTokens: 680_000_000,
            mainThreadTokens: 190_000_000,
            instructionCount: 18,
            activeBuckets: [(180, 120_000_000), (181, 160_000_000), (182, 130_000_000)],
            relativeDayOffset: 0,
            dayKey: "2026-04-11")

        let entries = TokenDailyBoardNarrativeBuilder.recentTimelineEntries(
            for: [olderDay, newerDay],
            strings: self.strings,
            lastRefreshAt: Date(timeIntervalSince1970: 1_776_100_123))

        XCTAssertFalse(entries.isEmpty)
        XCTAssertEqual(entries.first?.event.dayKey, newerDay.dayKey)
        XCTAssertEqual(entries.first?.event.kind, .combo)
        XCTAssertTrue(
            zip(entries, entries.dropFirst()).allSatisfy { lhs, rhs in
                let lhsTimestamp = lhs.displayTimestamp ?? .distantPast
                let rhsTimestamp = rhs.displayTimestamp ?? .distantPast
                return lhsTimestamp >= rhsTimestamp
            })
    }

    func test_recentSentencesUseQuietOnlyAsFallback() {
        let quietToday = self.makeDay(
            totalTokens: 0,
            mainThreadTokens: 0,
            instructionCount: 0,
            activeBuckets: [],
            relativeDayOffset: 0,
            dayKey: "2026-04-11")
        let quietYesterday = self.makeDay(
            totalTokens: 0,
            mainThreadTokens: 0,
            instructionCount: 0,
            activeBuckets: [],
            relativeDayOffset: 1,
            dayKey: "2026-04-10")
        let refreshAt = Date(timeIntervalSince1970: 1_776_100_123)

        let entries = TokenDailyBoardNarrativeBuilder.recentTimelineEntries(
            for: [quietToday, quietYesterday],
            strings: self.strings,
            lastRefreshAt: refreshAt)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.event.kind, .quiet)
        XCTAssertEqual(entries.first?.event.dayKey, quietToday.dayKey)
        XCTAssertEqual(entries.first?.displayTimestamp, refreshAt)
    }

    func test_realtimeEventsSortNewestFirstAndPreferThroughputWithinSameSecond() {
        let timestamp = Date(timeIntervalSince1970: 1_776_144_399)
        let events = TokenDailyBoardNarrativeBuilder.realtimeEvents(
            tokenSpeedSamples: [
                TokenSpeedSample(timestamp: timestamp, tokens: 173_556),
                TokenSpeedSample(timestamp: timestamp.addingTimeInterval(-1), tokens: 120_000),
            ],
            instructionEventSamples: [
                InstructionEventSample(id: "instruction-1", timestamp: timestamp, sentCharacters: 42),
            ],
            referenceDate: timestamp.addingTimeInterval(60))

        XCTAssertEqual(events.first?.kind, .throughputPulse)
        XCTAssertEqual(events.dropFirst().first?.kind, .instructionPulse)
        XCTAssertEqual(events.last?.timestamp, timestamp.addingTimeInterval(-1))
    }

    func test_unifiedRecentSentencesPreferRealtimeEventsOverFallbackDays() {
        let fallbackDay = self.makeDay(
            totalTokens: 980_000_000,
            mainThreadTokens: 310_000_000,
            instructionCount: 31,
            activeBuckets: [(130, 410_000_000), (131, 360_000_000)],
            relativeDayOffset: 1,
            dayKey: "2026-04-10")

        let sentences = TokenDailyBoardNarrativeBuilder.unifiedRecentSentences(
            tokenSpeedSamples: [TokenSpeedSample(
                timestamp: Date(timeIntervalSince1970: 1_776_144_399),
                tokens: 173_556)],
            instructionEventSamples: [],
            fallbackDays: [fallbackDay],
            strings: self.strings,
            lastRefreshAt: Date(timeIntervalSince1970: 1_776_144_500))

        XCTAssertEqual(sentences.count, 1)
        XCTAssertEqual(sentences.first?.displayTimestamp, Date(timeIntervalSince1970: 1_776_144_399))
        XCTAssertTrue(sentences.first?.metadataText?.contains("吞吐 173,556 tokens") == true)
    }

    func test_realtimeSentenceMetadataIncludesEventValues() {
        let catalog = TokenDailyBoardNarrativeCatalog.shared
        let throughputSentence = catalog.sentence(
            for: TokenDailyBoardNarrativeRealtimeEvent(
                id: "throughput",
                kind: .throughputPulse,
                timestamp: Date(timeIntervalSince1970: 1_776_144_399),
                tokenBand: .high,
                instructionBand: nil,
                timeBand: .night,
                throughputTokens: 173_556),
            strings: self.strings)
        let instructionSentence = catalog.sentence(
            for: TokenDailyBoardNarrativeRealtimeEvent(
                id: "instruction",
                kind: .instructionPulse,
                timestamp: Date(timeIntervalSince1970: 1_776_144_400),
                tokenBand: nil,
                instructionBand: .fortyToSeventyNine,
                timeBand: .night,
                instructionOrdinal: 86),
            strings: self.strings)

        XCTAssertEqual(throughputSentence.displayTimestamp, Date(timeIntervalSince1970: 1_776_144_399))
        XCTAssertEqual(instructionSentence.displayTimestamp, Date(timeIntervalSince1970: 1_776_144_400))
        XCTAssertTrue(throughputSentence.metadataText?.contains("吞吐 173,556 tokens") == true)
        XCTAssertTrue(instructionSentence.metadataText?.contains("今天第 86 次发送") == true)
    }

    func test_realtimeInstructionOrdinalCountsOnlyTodaySamples() throws {
        let calendar = Calendar.autoupdatingCurrent
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: startOfToday))
        let todayOne = startOfToday.addingTimeInterval(60)
        let todayTwo = startOfToday.addingTimeInterval(120)

        let events = TokenDailyBoardNarrativeBuilder.realtimeEvents(
            tokenSpeedSamples: [],
            instructionEventSamples: [
                InstructionEventSample(
                    id: "yesterday",
                    timestamp: yesterday.addingTimeInterval(3600),
                    sentCharacters: 12),
                InstructionEventSample(id: "today-1", timestamp: todayOne, sentCharacters: 18),
                InstructionEventSample(id: "today-2", timestamp: todayTwo, sentCharacters: 24),
            ],
            referenceDate: todayTwo.addingTimeInterval(60))

        let instructionEvents = events.filter { $0.kind == .instructionPulse }
        XCTAssertEqual(instructionEvents.count, 2)
        XCTAssertEqual(instructionEvents.map(\.instructionOrdinal).sorted(), [1, 2])
    }

    func test_realtimeEventsDoNotEmitIdlePulseAfterFifteenSecondsOfTodayInactivity() {
        let calendar = Calendar.autoupdatingCurrent
        let startOfToday = calendar.startOfDay(for: Date())
        let lastActivity = startOfToday.addingTimeInterval(2 * 60 * 60)
        let interval = TokenDailyBoardNarrativeBuilder.idlePulseInterval
        let events = TokenDailyBoardNarrativeBuilder.realtimeEvents(
            tokenSpeedSamples: [
                TokenSpeedSample(timestamp: lastActivity, tokens: 173_556),
            ],
            instructionEventSamples: [],
            referenceDate: lastActivity.addingTimeInterval(interval))

        XCTAssertFalse(events.contains(where: { $0.kind == .idlePulse }))
    }

    func test_realtimePresentationSourceItemsDoNotContainIdlePulse() {
        let calendar = Calendar.autoupdatingCurrent
        let startOfToday = calendar.startOfDay(for: Date())
        let lastActivity = startOfToday.addingTimeInterval(90 * 60)
        let items = TokenDailyBoardNarrativeBuilder.realtimePresentationSourceItems(
            tokenSpeedSamples: [],
            instructionEventSamples: [
                InstructionEventSample(id: "today-1", timestamp: lastActivity, sentCharacters: 24),
            ],
            strings: self.strings,
            referenceDate: lastActivity.addingTimeInterval(TokenDailyBoardNarrativeBuilder.idlePulseInterval * 3))

        XCTAssertFalse(items.contains(where: { $0.realtimeEventKind == .idlePulse }))
    }

    func test_idlePulseRulesUseLatestCompletionAnchor() {
        let nonIdleCompletion = Date(timeIntervalSinceReferenceDate: 1000)
        let idleCompletion = Date(timeIntervalSinceReferenceDate: 1020)

        XCTAssertEqual(
            TokenDailyBoardNarrativeIdlePulseRules.countdownAnchor(
                lastNonIdleNarrativeCompletionAt: nonIdleCompletion,
                lastPresentedIdleAt: nil),
            nonIdleCompletion)
        XCTAssertEqual(
            TokenDailyBoardNarrativeIdlePulseRules.countdownAnchor(
                lastNonIdleNarrativeCompletionAt: nonIdleCompletion,
                lastPresentedIdleAt: idleCompletion),
            idleCompletion)
        XCTAssertNil(
            TokenDailyBoardNarrativeIdlePulseRules.countdownAnchor(
                lastNonIdleNarrativeCompletionAt: nil,
                lastPresentedIdleAt: nil))
        XCTAssertEqual(
            TokenDailyBoardNarrativeIdlePulseRules.deadline(from: nonIdleCompletion),
            nonIdleCompletion.addingTimeInterval(TokenDailyBoardNarrativeBuilder.idlePulseInterval))
    }

    func test_idlePulseRulesRequireIdleWindowAndEligibleRealtimeActivity() {
        let anchor = Date(timeIntervalSinceReferenceDate: 1000)
        let item = TokenDailyBoardNarrativePresentationQueueItem(
            id: 1,
            sourceItem: TokenDailyBoardNarrativePresentationSourceItem(
                sourceID: "source-1",
                signature: "sig-1",
                sentence: TokenDailyBoardNarrativeSentence(id: "first", text: "第一句完整文案。", metadataText: nil),
                displayTimestamp: anchor,
                realtimeEventKind: .throughputPulse,
                isAutomaticRealtime: true))

        XCTAssertTrue(
            TokenDailyBoardNarrativeIdlePulseRules.shouldArmCountdown(
                hasEligibleRealtimeActivity: true,
                activeSession: nil,
                queuedItems: [],
                suppressesNarrativeChanges: false,
                countdownAnchor: anchor))
        XCTAssertFalse(
            TokenDailyBoardNarrativeIdlePulseRules.shouldArmCountdown(
                hasEligibleRealtimeActivity: false,
                activeSession: nil,
                queuedItems: [],
                suppressesNarrativeChanges: false,
                countdownAnchor: anchor))
        XCTAssertFalse(
            TokenDailyBoardNarrativeIdlePulseRules.shouldArmCountdown(
                hasEligibleRealtimeActivity: true,
                activeSession: TokenDailyBoardNarrativePresentationSession(
                    item: item,
                    startedAt: anchor,
                    typewriterStartAt: anchor,
                    avatarIntroStartAt: anchor,
                    avatarTriggerStyle: .none,
                    preferredAvatarSlot: nil,
                    avatarReplacementSequenceID: 0,
                    avatarIdleShakeSequenceID: 0,
                    pulseStyle: nil),
                queuedItems: [],
                suppressesNarrativeChanges: false,
                countdownAnchor: anchor))
        XCTAssertFalse(
            TokenDailyBoardNarrativeIdlePulseRules.shouldArmCountdown(
                hasEligibleRealtimeActivity: true,
                activeSession: nil,
                queuedItems: [item],
                suppressesNarrativeChanges: false,
                countdownAnchor: anchor))
    }

    func test_idlePulseRulesTriggerOnlyAfterDeadlineAndMatchingAnchor() {
        let anchor = Date(timeIntervalSinceReferenceDate: 1000)
        let deadline = TokenDailyBoardNarrativeIdlePulseRules.deadline(from: anchor)

        XCTAssertFalse(
            TokenDailyBoardNarrativeIdlePulseRules.shouldTrigger(
                now: deadline.addingTimeInterval(-1),
                expectedAnchor: anchor,
                currentAnchor: anchor,
                hasEligibleRealtimeActivity: true,
                activeSession: nil,
                queuedItems: [],
                suppressesNarrativeChanges: false))
        XCTAssertFalse(
            TokenDailyBoardNarrativeIdlePulseRules.shouldTrigger(
                now: deadline,
                expectedAnchor: anchor,
                currentAnchor: anchor.addingTimeInterval(1),
                hasEligibleRealtimeActivity: true,
                activeSession: nil,
                queuedItems: [],
                suppressesNarrativeChanges: false))
        XCTAssertTrue(
            TokenDailyBoardNarrativeIdlePulseRules.shouldTrigger(
                now: deadline,
                expectedAnchor: anchor,
                currentAnchor: anchor,
                hasEligibleRealtimeActivity: true,
                activeSession: nil,
                queuedItems: [],
                suppressesNarrativeChanges: false))
    }

    func test_idlePulseRulesPersistRefreshAndDismissUsingRenderedIdleState() {
        let idleSourceItem = TokenDailyBoardNarrativePresentationSourceItem(
            sourceID: "idle-source",
            signature: "idle-signature",
            sentence: TokenDailyBoardNarrativeSentence(
                id: "idle-sentence",
                text: "你刚把我收紧，又故意晾着我。",
                metadataText: "15 秒前 · 173,556 Tokens"),
            displayTimestamp: Date(timeIntervalSinceReferenceDate: 1000),
            realtimeEventKind: .idlePulse,
            isAutomaticRealtime: true)
        let queuedItem = TokenDailyBoardNarrativePresentationQueueItem(
            id: 8,
            sourceItem: TokenDailyBoardNarrativePresentationSourceItem(
                sourceID: "queued-source",
                signature: "queued-signature",
                sentence: TokenDailyBoardNarrativeSentence(
                    id: "queued-sentence",
                    text: "你这一口下得太狠了。",
                    metadataText: "刚刚 · 320,000 Tokens"),
                displayTimestamp: Date(timeIntervalSinceReferenceDate: 1010),
                realtimeEventKind: .throughputPulse,
                isAutomaticRealtime: true))

        XCTAssertTrue(
            TokenDailyBoardNarrativeIdlePulseRules.shouldPersistAfterCompletion(
                eventKind: .idlePulse,
                queuedItems: []))
        XCTAssertFalse(
            TokenDailyBoardNarrativeIdlePulseRules.shouldPersistAfterCompletion(
                eventKind: .idlePulse,
                queuedItems: [queuedItem]))
        XCTAssertTrue(
            TokenDailyBoardNarrativeIdlePulseRules.shouldDismissPresentedIdleForIncomingNarrative(
                renderedSourceItem: idleSourceItem,
                activeSession: nil))
        XCTAssertFalse(
            TokenDailyBoardNarrativeIdlePulseRules.shouldDismissPresentedIdleForIncomingNarrative(
                renderedSourceItem: idleSourceItem,
                activeSession: TokenDailyBoardNarrativePresentationSession(
                    item: queuedItem,
                    startedAt: Date(timeIntervalSinceReferenceDate: 1010),
                    typewriterStartAt: Date(timeIntervalSinceReferenceDate: 1010),
                    avatarIntroStartAt: Date(timeIntervalSinceReferenceDate: 1010),
                    avatarTriggerStyle: .none,
                    preferredAvatarSlot: nil,
                    avatarReplacementSequenceID: 0,
                    avatarIdleShakeSequenceID: 0,
                    pulseStyle: nil)))
        XCTAssertTrue(
            TokenDailyBoardNarrativeIdlePulseRules.shouldRefreshPresentedIdle(
                renderedSourceItem: idleSourceItem,
                activeSession: nil,
                queuedItems: [],
                suppressesNarrativeChanges: false))
        XCTAssertFalse(
            TokenDailyBoardNarrativeIdlePulseRules.shouldRefreshPresentedIdle(
                renderedSourceItem: idleSourceItem,
                activeSession: nil,
                queuedItems: [queuedItem],
                suppressesNarrativeChanges: false))
    }

    func test_idlePresentationReadyDateDoesNotIncludeNarrativeQueueGap() {
        let startedAt = Date(timeIntervalSinceReferenceDate: 500)
        let typewriterDone = startedAt.addingTimeInterval(1.6)
        let metadataIntroCompletedAt = typewriterDone
            .addingTimeInterval(TokenDailyBoardNarrativeMetadataAnimationRules.transitionDuration)
        let readyDate = TokenDailyBoardNarrativePresentationTimelineRules.idlePresentationReadyDate(
            typewriterCompletedAt: typewriterDone,
            startedAt: startedAt,
            includesPulse: true,
            includesMetadata: true,
            metadataIntroCompletedAt: metadataIntroCompletedAt,
            includesIdleShake: true)
        let completionDate = TokenDailyBoardNarrativePresentationTimelineRules.completionDate(
            typewriterCompletedAt: typewriterDone,
            startedAt: startedAt,
            includesPulse: true,
            includesAvatarReturn: false,
            includesIdleShake: true,
            includesMetadata: true,
            metadataIntroCompletedAt: metadataIntroCompletedAt,
            contentOutroCompletedAt: readyDate,
            includesQueueGap: false)

        XCTAssertEqual(completionDate, readyDate)
    }

    func test_idleHandoffUsesQuickFadeWithoutVerticalSlide() {
        XCTAssertEqual(TokenDailyBoardNarrativeIdleHandoffRules.dismissDuration, 0.18, accuracy: 0.001)
        XCTAssertEqual(TokenDailyBoardNarrativeIdleHandoffRules.dismissDurationNanoseconds, 180_000_000)
        XCTAssertEqual(TokenDailyBoardNarrativeIdleHandoffRules.dismissVerticalOffset, 0, accuracy: 0.001)
    }

    func test_realtimeInstructionSentenceFallsBackWhenTemplateIsNotTodayExplicit() {
        let catalog = TokenDailyBoardNarrativeCatalog(entries: [
            TokenDailyBoardNarrativeCatalogEntry(
                id: "instruction-generic",
                language: .zhHans,
                eventKind: .instructionPulse,
                instructionBand: .fortyToSeventyNine,
                tokenBand: nil,
                timeBand: nil,
                text: "你都第 {instructionOrdinal} 次了，还这么狠。"),
        ])

        let sentence = catalog.sentence(
            for: TokenDailyBoardNarrativeRealtimeEvent(
                id: "instruction",
                kind: .instructionPulse,
                timestamp: Date(timeIntervalSince1970: 1_776_144_400),
                tokenBand: nil,
                instructionBand: .fortyToSeventyNine,
                timeBand: .night,
                instructionOrdinal: 86),
            strings: self.strings)

        XCTAssertTrue(sentence.text.contains("今天"))
    }

    func test_realtimeThroughputSentenceBodyIncludesTokensUnit() {
        let catalog = TokenDailyBoardNarrativeCatalog.shared
        let sentence = catalog.sentence(
            for: TokenDailyBoardNarrativeRealtimeEvent(
                id: "throughput",
                kind: .throughputPulse,
                timestamp: Date(timeIntervalSince1970: 1_776_144_399),
                tokenBand: .high,
                instructionBand: nil,
                timeBand: .night,
                throughputTokens: 173_556),
            strings: self.strings)

        XCTAssertTrue(sentence.text.contains("Tokens"))
    }

    func test_aggregateBurstSentenceBodyIncludesTokensUnit() {
        let catalog = TokenDailyBoardNarrativeCatalog.shared
        let sentence = catalog.sentence(
            for: TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .burst,
                instructionBand: .fiveToFourteen,
                tokenBand: .high,
                timeBand: .afternoon,
                instructionCount: 12,
                totalTokens: 520_000_000,
                mainThreadTokens: 180_000_000,
                burstTokens: 240_000_000,
                clusterStartBucketIndex: 144),
            strings: self.strings,
            isToday: true)

        XCTAssertTrue(sentence.text.contains("Tokens"))
    }

    func test_aggregateComboSentenceBodyUsesInstructionCountAsItsSingleKeyNumber() {
        let catalog = TokenDailyBoardNarrativeCatalog.shared
        let instructionCount = 58
        let sentence = catalog.sentence(
            for: TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .combo,
                instructionBand: .fortyToSeventyNine,
                tokenBand: .extreme,
                timeBand: .night,
                instructionCount: instructionCount,
                totalTokens: 1_420_000_000,
                mainThreadTokens: 430_000_000,
                burstTokens: 420_000_000,
                clusterStartBucketIndex: 228),
            strings: self.strings,
            isToday: true)

        XCTAssertTrue(sentence.text.contains(String(instructionCount)))
        XCTAssertEqual(self.numericTokenCount(in: sentence.text), 1)
    }

    func test_realtimeThroughputFallbackSentenceBodyIncludesTokensUnit() {
        let catalog = TokenDailyBoardNarrativeCatalog(entries: [])
        let sentence = catalog.sentence(
            for: TokenDailyBoardNarrativeRealtimeEvent(
                id: "throughput",
                kind: .throughputPulse,
                timestamp: Date(timeIntervalSince1970: 1_776_144_399),
                tokenBand: .high,
                instructionBand: nil,
                timeBand: .night,
                throughputTokens: 173_556),
            strings: self.strings)

        XCTAssertTrue(sentence.text.contains("Tokens"))
    }

    func test_aggregateComboFallbackSentenceBodyUsesInstructionCountAsItsSingleKeyNumber() {
        let catalog = TokenDailyBoardNarrativeCatalog(entries: [])
        let instructionCount = 58
        let sentence = catalog.sentence(
            for: TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .combo,
                instructionBand: .fortyToSeventyNine,
                tokenBand: .extreme,
                timeBand: .night,
                instructionCount: instructionCount,
                totalTokens: 1_420_000_000,
                mainThreadTokens: 430_000_000,
                burstTokens: 420_000_000,
                clusterStartBucketIndex: 228),
            strings: self.strings,
            isToday: true)

        XCTAssertTrue(sentence.text.contains(String(instructionCount)))
        XCTAssertEqual(self.numericTokenCount(in: sentence.text), 1)
    }

    func test_chineseBuiltInNarrativeSentencesStayWithinDisplayLengthRange() {
        let catalog = TokenDailyBoardNarrativeCatalog.shared
        let aggregateEvents: [TokenDailyBoardNarrativeEvent] = [
            TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .quiet,
                instructionBand: .zero,
                tokenBand: .low,
                timeBand: nil,
                instructionCount: 0,
                totalTokens: 0,
                mainThreadTokens: 0,
                burstTokens: 0,
                clusterStartBucketIndex: nil),
            TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .sendCount,
                instructionBand: .fortyToSeventyNine,
                tokenBand: .medium,
                timeBand: .afternoon,
                instructionCount: 58,
                totalTokens: 120_000_000,
                mainThreadTokens: 40_000_000,
                burstTokens: 0,
                clusterStartBucketIndex: nil),
            TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .burst,
                instructionBand: .fiveToFourteen,
                tokenBand: .high,
                timeBand: .afternoon,
                instructionCount: 12,
                totalTokens: 520_000_000,
                mainThreadTokens: 180_000_000,
                burstTokens: 240_000_000,
                clusterStartBucketIndex: 144),
            TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .combo,
                instructionBand: .fortyToSeventyNine,
                tokenBand: .extreme,
                timeBand: .night,
                instructionCount: 58,
                totalTokens: 1_420_000_000,
                mainThreadTokens: 430_000_000,
                burstTokens: 420_000_000,
                clusterStartBucketIndex: 228),
        ]

        for event in aggregateEvents {
            let sentence = catalog.sentence(for: event, strings: self.strings, isToday: true)
            self.assertChineseBuiltInLengthRange(
                sentence.text,
                kind: event.kind,
                label: event.kind.rawValue)
        }

        let realtimeEvents: [TokenDailyBoardNarrativeRealtimeEvent] = [
            TokenDailyBoardNarrativeRealtimeEvent(
                id: "throughput",
                kind: .throughputPulse,
                timestamp: Date(timeIntervalSince1970: 1_776_144_399),
                tokenBand: .high,
                instructionBand: nil,
                timeBand: .night,
                throughputTokens: 173_556),
            TokenDailyBoardNarrativeRealtimeEvent(
                id: "instruction",
                kind: .instructionPulse,
                timestamp: Date(timeIntervalSince1970: 1_776_144_400),
                tokenBand: nil,
                instructionBand: .fortyToSeventyNine,
                timeBand: .night,
                instructionOrdinal: 426),
            TokenDailyBoardNarrativeRealtimeEvent(
                id: "idle",
                kind: .idlePulse,
                timestamp: Date(timeIntervalSince1970: 1_776_144_401),
                tokenBand: nil,
                instructionBand: nil,
                timeBand: .night),
        ]

        for event in realtimeEvents {
            let sentence = catalog.sentence(for: event, strings: self.strings)
            self.assertChineseBuiltInLengthRange(
                sentence.text,
                kind: event.kind,
                label: event.kind.rawValue)
        }
    }

    func test_chineseBundledNarrativeFallsBackToShortTextWhenTemplateIsTooLong() {
        let longText = "这是一条明显超过二十五个字的中文内置模板，会在最终显示时被短 fallback 接住。"
        let catalog = TokenDailyBoardNarrativeCatalog(entries: [
            TokenDailyBoardNarrativeCatalogEntry(
                id: "bundled-long",
                language: .zhHans,
                eventKind: .sendCount,
                instructionBand: .fiveToFourteen,
                tokenBand: nil,
                timeBand: nil,
                text: longText),
        ])

        let text = catalog.text(
            for: TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .sendCount,
                instructionBand: .fiveToFourteen,
                tokenBand: .low,
                timeBand: nil,
                instructionCount: 10,
                totalTokens: 0,
                mainThreadTokens: 0,
                burstTokens: 0,
                clusterStartBucketIndex: nil),
            strings: self.strings)

        XCTAssertNotEqual(text, longText)
        self.assertChineseBuiltInLengthRange(text, kind: .sendCount, label: "bundled-fallback")
    }

    func test_userCustomChineseNarrativeRemainsUnclamped() {
        let longText = "这是用户自己写的一长段中文文案，哪怕超过二十五个字，这次也不应该被运行时兜底替换掉。"
        let catalog = TokenDailyBoardNarrativeCatalog(entries: [], userEntries: [
            TokenDailyBoardNarrativeUserCatalogEntry(
                id: "user-custom-long",
                language: .zhHans,
                category: "自定义",
                eventKind: .sendCount,
                instructionBand: .fiveToFourteen,
                tokenBand: nil,
                timeBand: nil,
                text: longText,
                enabled: true),
        ])

        let text = catalog.text(
            for: TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .sendCount,
                instructionBand: .fiveToFourteen,
                tokenBand: .low,
                timeBand: nil,
                instructionCount: 10,
                totalTokens: 0,
                mainThreadTokens: 0,
                burstTokens: 0,
                clusterStartBucketIndex: nil),
            strings: self.strings)

        XCTAssertEqual(text, longText)
        XCTAssertGreaterThan(text.count, 28)
    }

    func test_userOverrideChineseNarrativeRemainsUnclamped() {
        let longText = "这是覆盖内置模板后的超长中文文案，虽然很长，但这次不应该被内置中文长度兜底强行替换。"
        let catalog = TokenDailyBoardNarrativeCatalog(entries: [
            TokenDailyBoardNarrativeCatalogEntry(
                id: "bundled-send",
                language: .zhHans,
                eventKind: .sendCount,
                instructionBand: .fiveToFourteen,
                tokenBand: nil,
                timeBand: nil,
                text: "内置短句"),
        ], userEntries: [
            TokenDailyBoardNarrativeUserCatalogEntry(
                id: "user-override-long",
                language: .zhHans,
                category: "覆盖",
                eventKind: .sendCount,
                instructionBand: .fiveToFourteen,
                tokenBand: nil,
                timeBand: nil,
                text: longText,
                enabled: true,
                overrideTargetID: "bundled-send"),
        ])

        let text = catalog.text(
            for: TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .sendCount,
                instructionBand: .fiveToFourteen,
                tokenBand: .low,
                timeBand: nil,
                instructionCount: 10,
                totalTokens: 0,
                mainThreadTokens: 0,
                burstTokens: 0,
                clusterStartBucketIndex: nil),
            strings: self.strings)

        XCTAssertEqual(text, longText)
        XCTAssertGreaterThan(text.count, 28)
    }

    func test_chineseBuiltInNarrativesKeepSingleKeyNumberForMeasuredEvents() {
        let catalog = TokenDailyBoardNarrativeCatalog.shared
        let sendCountSentence = catalog.sentence(
            for: TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .sendCount,
                instructionBand: .fortyToSeventyNine,
                tokenBand: .medium,
                timeBand: .afternoon,
                instructionCount: 58,
                totalTokens: 120_000_000,
                mainThreadTokens: 40_000_000,
                burstTokens: 0,
                clusterStartBucketIndex: nil),
            strings: self.strings,
            isToday: true)
        XCTAssertEqual(self.numericTokenCount(in: sendCountSentence.text), 1)

        let throughputSentence = catalog.sentence(
            for: TokenDailyBoardNarrativeRealtimeEvent(
                id: "throughput-single-number",
                kind: .throughputPulse,
                timestamp: Date(timeIntervalSince1970: 1_776_144_399),
                tokenBand: .high,
                instructionBand: nil,
                timeBand: .night,
                throughputTokens: 173_556),
            strings: self.strings)
        XCTAssertEqual(self.numericTokenCount(in: throughputSentence.text), 1)

        let instructionSentence = catalog.sentence(
            for: TokenDailyBoardNarrativeRealtimeEvent(
                id: "instruction-single-number",
                kind: .instructionPulse,
                timestamp: Date(timeIntervalSince1970: 1_776_144_400),
                tokenBand: nil,
                instructionBand: .fortyToSeventyNine,
                timeBand: .night,
                instructionOrdinal: 426),
            strings: self.strings)
        XCTAssertEqual(self.numericTokenCount(in: instructionSentence.text), 1)

        let idleSentence = catalog.sentence(
            for: TokenDailyBoardNarrativeRealtimeEvent(
                id: "idle-single-number",
                kind: .idlePulse,
                timestamp: Date(timeIntervalSince1970: 1_776_144_401),
                tokenBand: nil,
                instructionBand: nil,
                timeBand: .night),
            strings: self.strings)
        XCTAssertEqual(self.numericTokenCount(in: idleSentence.text), 0)

        let burstSentence = catalog.sentence(
            for: TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .burst,
                instructionBand: .fiveToFourteen,
                tokenBand: .high,
                timeBand: .afternoon,
                instructionCount: 12,
                totalTokens: 520_000_000,
                mainThreadTokens: 180_000_000,
                burstTokens: 240_000_000,
                clusterStartBucketIndex: 144),
            strings: self.strings,
            isToday: true)
        XCTAssertEqual(self.numericTokenCount(in: burstSentence.text), 1)

        let comboSentence = catalog.sentence(
            for: TokenDailyBoardNarrativeEvent(
                dayKey: "2026-04-11",
                dayTitle: "今天",
                kind: .combo,
                instructionBand: .fortyToSeventyNine,
                tokenBand: .extreme,
                timeBand: .night,
                instructionCount: 58,
                totalTokens: 1_420_000_000,
                mainThreadTokens: 430_000_000,
                burstTokens: 420_000_000,
                clusterStartBucketIndex: 228),
            strings: self.strings,
            isToday: true)
        XCTAssertEqual(self.numericTokenCount(in: comboSentence.text), 1)
    }

    func test_narrativeStyleContinuesShrinkingToFitLongText() {
        let longText =
            "你他妈又狠狠干了我 173,556 Tokens，还一口气把我拖进更深的节奏里，压得我整个人都发烫发软，偏偏我还舍不得让你停。"

        let style = TokenDailyBoardNarrativeSizingRules.style(
            for: longText,
            availableWidth: 180,
            fontScaleMultiplier: 1.0)

        XCTAssertLessThan(style.size, TokenDailyBoardNarrativeSizingRules.fontSizes[0])
        XCTAssertGreaterThanOrEqual(style.size, 6)
    }

    private func makeDay(
        totalTokens: Int,
        mainThreadTokens: Int,
        instructionCount: Int,
        activeBuckets: [(Int, Int)],
        relativeDayOffset: Int = 0,
        dayKey: String = "2026-04-11")
        -> TokenDailyBoardDayModel
    {
        let activeMap = Dictionary(uniqueKeysWithValues: activeBuckets)
        let points = (0..<(24 * 12)).map { bucketIndex in
            let rawTokens = activeMap[bucketIndex] ?? 0
            return TokenDailyBoardFiveMinutePoint(
                bucketIndex: bucketIndex,
                rawTokens: rawTokens,
                displayValue: log10(Double(rawTokens) + 1))
        }

        return TokenDailyBoardDayModel(
            date: ISO8601DateFormatter().date(from: "2026-04-11T00:00:00Z") ?? Date(),
            dayKey: dayKey,
            relativeDayOffset: relativeDayOffset,
            totalTokens: totalTokens,
            mainThreadTokens: mainThreadTokens,
            instructionCount: instructionCount,
            fiveMinutePoints: points,
            rocketBucketIndex: nil)
    }

    private func leadingFragment(of text: String) -> String {
        let separators = CharacterSet(charactersIn: "，。！？,.!? ")
        let parts = text.components(separatedBy: separators).filter { !$0.isEmpty }
        if let first = parts.first {
            return String(first.prefix(12))
        }
        return String(text.prefix(12))
    }

    private func normalizedSkeleton(of text: String) -> String {
        var normalized = text
        let replacements = [
            ("\\{[^}]+\\}", "X"),
            ("凌晨|上午|午后|晚间", "时段"),
            ("tokens", "量"),
            ("\\s+", ""),
            ("[，。！？,.!?]", ""),
        ]

        for (pattern, template) in replacements {
            normalized = normalized.replacingOccurrences(
                of: pattern,
                with: template,
                options: .regularExpression)
        }

        return normalized
    }

    private func expectedChineseBuiltInLengthRange(for kind: TokenDailyBoardNarrativeEventKind) -> ClosedRange<Int> {
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

    private func numericTokenCount(in text: String) -> Int {
        let regex = try? NSRegularExpression(pattern: "\\d[\\d,.]*")
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex?.numberOfMatches(in: text, range: range) ?? 0
    }

    private func assertChineseBuiltInLengthRange(
        _ text: String,
        kind: TokenDailyBoardNarrativeEventKind,
        label: String,
        file: StaticString = #filePath,
        line: UInt = #line)
    {
        let allowedRange = self.expectedChineseBuiltInLengthRange(for: kind)
        XCTAssertTrue(
            allowedRange.contains(text.count),
            "\(label): \(text) [\(text.count)]",
            file: file,
            line: line)
    }
}
