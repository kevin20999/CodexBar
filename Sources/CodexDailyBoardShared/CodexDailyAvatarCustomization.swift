import AppKit
import Foundation

public enum CodexDailyAvatarSlot: String, CaseIterable, Codable, Hashable, Identifiable {
    case defaultAvatar = "default"
    case variant01
    case variant02
    case variant03
    case variant04
    case variant05
    case variant06
    case variant07
    case variant08
    case variant09

    public var id: String {
        self.rawValue
    }

    var assetFileName: String {
        "\(self.rawValue).png"
    }

    var bundleImageName: NSImage.Name {
        switch self {
        case .defaultAvatar:
            NSImage.Name("DailyBoardCodexAvatar")
        case .variant01:
            NSImage.Name("DailyBoardCodexAvatarVariant01")
        case .variant02:
            NSImage.Name("DailyBoardCodexAvatarVariant02")
        case .variant03:
            NSImage.Name("DailyBoardCodexAvatarVariant03")
        case .variant04:
            NSImage.Name("DailyBoardCodexAvatarVariant04")
        case .variant05:
            NSImage.Name("DailyBoardCodexAvatarVariant05")
        case .variant06:
            NSImage.Name("DailyBoardCodexAvatarVariant06")
        case .variant07:
            NSImage.Name("DailyBoardCodexAvatarVariant07")
        case .variant08:
            NSImage.Name("DailyBoardCodexAvatarVariant08")
        case .variant09:
            NSImage.Name("DailyBoardCodexAvatarVariant09")
        }
    }

    public var variantIndex: Int? {
        switch self {
        case .defaultAvatar:
            nil
        case .variant01:
            0
        case .variant02:
            1
        case .variant03:
            2
        case .variant04:
            3
        case .variant05:
            4
        case .variant06:
            5
        case .variant07:
            6
        case .variant08:
            7
        case .variant09:
            8
        }
    }
}

struct CodexDailyAvatarCustomization: Codable, Equatable, Identifiable {
    let slot: CodexDailyAvatarSlot
    var imageFileName: String?
    var isMirrored: Bool

    var id: String {
        self.slot.id
    }
}

public struct CodexDailyAvatarResolvedSlot: Identifiable {
    public let slot: CodexDailyAvatarSlot
    public let image: NSImage?
    public let conversationOnlyImage: NSImage?
    public let isMirrored: Bool
    public let usesCustomImage: Bool
    public let usesCustomMirror: Bool

    public var id: String {
        self.slot.id
    }

    public var canRestoreDefault: Bool {
        self.usesCustomImage || self.usesCustomMirror
    }

    public func preferredImage(for displayMode: TokenDailyBoardDisplayMode) -> NSImage? {
        switch displayMode {
        case .conversationOnly:
            self.conversationOnlyImage ?? self.image
        case .conversationAndToday, .fullBoard:
            self.image
        }
    }
}

enum CodexDailyAvatarCustomizationError: LocalizedError {
    case failedToLoadImage
    case failedToEncodeImage

    var errorDescription: String? {
        switch self {
        case .failedToLoadImage:
            "无法读取所选图片。"
        case .failedToEncodeImage:
            "无法保存所选图片。"
        }
    }
}

final class CodexDailyAvatarCustomizationStore {
    private static let conversationOnlyThumbnailMaximumDimension: CGFloat = 128

    private let fileURL: URL
    private let assetsDirectoryURL: URL

    init(
        fileURL: URL = CodexDailyAppIdentity.avatarCustomizationFileURL,
        assetsDirectoryURL: URL = CodexDailyAppIdentity.avatarAssetsDirectoryURL)
    {
        self.fileURL = fileURL
        self.assetsDirectoryURL = assetsDirectoryURL
    }

    func load() throws -> [CodexDailyAvatarCustomization] {
        guard FileManager.default.fileExists(atPath: self.fileURL.path) else { return [] }
        let data = try Data(contentsOf: self.fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode([CodexDailyAvatarCustomization].self, from: data)
            .sorted { $0.slot.rawValue < $1.slot.rawValue }
    }

    func save(_ customizations: [CodexDailyAvatarCustomization]) throws {
        try self.ensureDirectories()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(customizations.sorted { $0.slot.rawValue < $1.slot.rawValue })
        try data.write(to: self.fileURL, options: .atomic)
    }

    func resolvedSlots(from customizations: [CodexDailyAvatarCustomization]) -> [CodexDailyAvatarResolvedSlot] {
        let customizationBySlot = Dictionary(uniqueKeysWithValues: customizations.map { ($0.slot, $0) })

        return CodexDailyAvatarSlot.allCases.map { slot in
            let customization = customizationBySlot[slot]
            let image = self.resolvedImage(for: slot, customization: customization)
            let conversationOnlyImage = image.flatMap {
                self.resizedImage($0, maximumDimension: Self.conversationOnlyThumbnailMaximumDimension)
            }
            let defaultMirror = TokenDailyBoardNarrativePresentationRules.avatarIsMirrored
            let effectiveMirror = customization?.isMirrored ?? defaultMirror
            let usesCustomMirror = customization.map { $0.isMirrored != defaultMirror } ?? false
            return CodexDailyAvatarResolvedSlot(
                slot: slot,
                image: image,
                conversationOnlyImage: conversationOnlyImage,
                isMirrored: effectiveMirror,
                usesCustomImage: customization?.imageFileName != nil,
                usesCustomMirror: usesCustomMirror)
        }
    }

    func replaceImage(
        at sourceURL: URL,
        for slot: CodexDailyAvatarSlot,
        existing customizations: [CodexDailyAvatarCustomization])
        throws -> [CodexDailyAvatarCustomization]
    {
        try self.ensureDirectories()
        let image = try self.loadImage(from: sourceURL)
        let destinationURL = self.assetsDirectoryURL.appendingPathComponent(slot.assetFileName, isDirectory: false)
        let data = try self.pngData(from: image)
        try data.write(to: destinationURL, options: .atomic)

        var customization = customizations.first(where: { $0.slot == slot })
            ?? CodexDailyAvatarCustomization(
                slot: slot,
                imageFileName: nil,
                isMirrored: TokenDailyBoardNarrativePresentationRules.avatarIsMirrored)
        customization.imageFileName = slot.assetFileName
        return self.replacing(customization, in: customizations)
    }

    func setMirrored(
        _ isMirrored: Bool,
        for slot: CodexDailyAvatarSlot,
        existing customizations: [CodexDailyAvatarCustomization])
        throws -> [CodexDailyAvatarCustomization]
    {
        let defaultMirror = TokenDailyBoardNarrativePresentationRules.avatarIsMirrored
        var customization = customizations.first(where: { $0.slot == slot })
            ?? CodexDailyAvatarCustomization(
                slot: slot,
                imageFileName: nil,
                isMirrored: defaultMirror)
        customization.isMirrored = isMirrored

        if customization.imageFileName == nil, customization.isMirrored == defaultMirror {
            return customizations.filter { $0.slot != slot }
        }

        return self.replacing(customization, in: customizations)
    }

    func restoreDefault(
        for slot: CodexDailyAvatarSlot,
        existing customizations: [CodexDailyAvatarCustomization])
        throws -> [CodexDailyAvatarCustomization]
    {
        let destinationURL = self.assetsDirectoryURL.appendingPathComponent(slot.assetFileName, isDirectory: false)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        return customizations.filter { $0.slot != slot }
    }

    private func replacing(
        _ customization: CodexDailyAvatarCustomization,
        in customizations: [CodexDailyAvatarCustomization])
        -> [CodexDailyAvatarCustomization]
    {
        var updated = customizations.filter { $0.slot != customization.slot }
        updated.append(customization)
        return updated.sorted { $0.slot.rawValue < $1.slot.rawValue }
    }

    private func resolvedImage(
        for slot: CodexDailyAvatarSlot,
        customization: CodexDailyAvatarCustomization?)
        -> NSImage?
    {
        if let fileName = customization?.imageFileName {
            let customURL = self.assetsDirectoryURL.appendingPathComponent(fileName, isDirectory: false)
            if let image = NSImage(contentsOf: customURL) {
                return image
            }
        }

        return Bundle.module.image(forResource: slot.bundleImageName)
    }

    private func ensureDirectories() throws {
        try FileManager.default.createDirectory(
            at: self.assetsDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil)
        let customizationDirectoryURL = self.fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: customizationDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil)
    }

    private func loadImage(from sourceURL: URL) throws -> NSImage {
        guard let image = NSImage(contentsOf: sourceURL) else {
            throw CodexDailyAvatarCustomizationError.failedToLoadImage
        }
        return image
    }

    private func pngData(from image: NSImage) throws -> Data {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            throw CodexDailyAvatarCustomizationError.failedToEncodeImage
        }
        return pngData
    }

    private func resizedImage(_ image: NSImage, maximumDimension: CGFloat) -> NSImage? {
        guard maximumDimension > 0 else { return image }
        let originalSize = image.size
        guard originalSize.width > 0, originalSize.height > 0 else { return image }

        let longestEdge = max(originalSize.width, originalSize.height)
        guard longestEdge > maximumDimension else { return image }

        let scale = maximumDimension / longestEdge
        let targetSize = NSSize(
            width: max((originalSize.width * scale).rounded(), 1),
            height: max((originalSize.height * scale).rounded(), 1))
        let resized = NSImage(size: targetSize)

        resized.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1)
        resized.unlockFocus()

        return resized
    }
}
