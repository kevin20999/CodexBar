import Foundation

package enum TokenDailyBoardConversationOnlyAvatarEffectPreset: String, CaseIterable, Codable {
    case avatar01
    case avatar02
    case avatar03
    case avatar04
    case avatar05
    case avatar06
    case avatar07
    case avatar08
    case avatar09
    case avatar10
    case avatar11
    case avatar12
    case avatar13
    case avatar14
    case avatar15
    case avatar16
    case avatar17
    case avatar18
    case avatar19
    case avatar20
    case avatar21
    case avatar22
    case avatar23
    case avatar24
    case avatar25
    case avatar26
    case avatar27
    case avatar28
    case avatar29
    case avatar30
}

package enum TokenDailyBoardConversationOnlyBackgroundEffectPreset: String, CaseIterable, Codable {
    case background01
    case background02
    case background03
    case background04
    case background05
    case background06
    case background07
    case background08
    case background09
    case background10
    case background11
    case background12
    case background13
    case background14
    case background15
    case background16
    case background17
    case background18
    case background19
    case background20
    case background21
    case background22
    case background23
    case background24
    case background25
    case background26
    case background27
    case background28
    case background29
    case background30
}

package enum TokenDailyBoardConversationOnlyTextEffectPreset: String, CaseIterable, Codable {
    case text01
    case text02
    case text03
    case text04
    case text05
    case text06
    case text07
    case text08
    case text09
    case text10
    case text11
    case text12
    case text13
    case text14
    case text15
    case text16
    case text17
    case text18
    case text19
    case text20
    case text21
    case text22
    case text23
    case text24
    case text25
    case text26
    case text27
    case text28
    case text29
    case text30
}

extension TokenDailyBoardConversationOnlyAvatarEffectPreset {
    package var debugTitle: String {
        self.rawValue.replacingOccurrences(of: "avatar", with: "")
    }

    package var ordinal: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

extension TokenDailyBoardConversationOnlyBackgroundEffectPreset {
    package var debugTitle: String {
        self.rawValue.replacingOccurrences(of: "background", with: "")
    }

    package var ordinal: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

extension TokenDailyBoardConversationOnlyTextEffectPreset {
    package var debugTitle: String {
        self.rawValue.replacingOccurrences(of: "text", with: "")
    }

    package var ordinal: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
