import Foundation

enum CharacterCustomizationCategory: String, CaseIterable, Identifiable {
    case base
    case hair
    case brows
    case eyes
    case nose
    case mouth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .base: "Gender"
        case .hair: "Hair"
        case .brows: "Brows"
        case .eyes: "Eyes"
        case .nose: "Nose"
        case .mouth: "Mouth"
        }
    }

    var systemImage: String {
        switch self {
        case .base: "person.crop.circle"
        case .hair: "comb.fill"
        case .brows: "eyebrow"
        case .eyes: "eye.fill"
        case .nose: "nose.fill"
        case .mouth: "mouth.fill"
        }
    }
}

struct CharacterCustomizationOption: Identifiable, Equatable {
    let id: String
    let title: String
}

enum CharacterCustomizationCatalog {
    static func options(
        for category: CharacterCustomizationCategory,
        baseStyle: CharacterBaseStyle
    ) -> [CharacterCustomizationOption] {
        if category == .base {
            return CharacterBaseStyle.allCases.map { style in
                CharacterCustomizationOption(
                    id: style.rawValue,
                    title: style.title
                )
            }
        }

        return assetIDs(for: category, baseStyle: baseStyle).enumerated().map { index, assetID in
            CharacterCustomizationOption(id: assetID, title: "\(index + 1)")
        }
    }

    static func selectedOptionID(
        for category: CharacterCustomizationCategory,
        appearance: CharacterAppearance
    ) -> String {
        switch category {
        case .base: appearance.baseStyle.rawValue
        case .hair: appearance.hairStyle
        case .brows: appearance.browsStyle
        case .eyes: appearance.eyesStyle
        case .nose: appearance.noseStyle
        case .mouth: appearance.mouthStyle
        }
    }

    static func appearance(
        _ appearance: CharacterAppearance,
        selecting option: CharacterCustomizationOption,
        in category: CharacterCustomizationCategory
    ) -> CharacterAppearance {
        if category == .base,
           let baseStyle = CharacterBaseStyle(rawValue: option.id) {
            return switchingBase(appearance, to: baseStyle)
        }

        var updatedAppearance = appearance
        set(option.id, for: category, in: &updatedAppearance)
        return updatedAppearance
    }

    static func previewAppearance(
        for option: CharacterCustomizationOption,
        category: CharacterCustomizationCategory,
        currentAppearance: CharacterAppearance
    ) -> CharacterAppearance {
        appearance(currentAppearance, selecting: option, in: category)
    }

    static func assetIDs(
        for category: CharacterCustomizationCategory,
        baseStyle: CharacterBaseStyle
    ) -> [String] {
        let prefix = baseStyle == .boy ? "b_" : "g_"
        let hairPrefix = baseStyle == .boy ? "bhairstyle_" : "ghairstyle_"

        switch category {
        case .base:
            return []
        case .hair:
            return (1...4).map { "\(hairPrefix)\($0)" }
        case .brows:
            return (1...4).map { "\(prefix)brows\($0)" }
        case .eyes:
            return (1...4).map { "\(prefix)eyes\($0)" }
        case .nose:
            return (1...4).map { "\(prefix)nose\($0)" }
        case .mouth:
            return (1...4).map { "\(prefix)mouth\($0)" }
        }
    }

    private static func switchingBase(
        _ appearance: CharacterAppearance,
        to baseStyle: CharacterBaseStyle
    ) -> CharacterAppearance {
        guard appearance.baseStyle != baseStyle else { return appearance }

        var updatedAppearance = appearance
        let previousBaseStyle = appearance.baseStyle

        for category in CharacterCustomizationCategory.allCases where category != .base {
            let previousAssetIDs = assetIDs(for: category, baseStyle: previousBaseStyle)
            let selectedID = selectedOptionID(for: category, appearance: appearance)
            let selectedIndex = previousAssetIDs.firstIndex(of: selectedID) ?? 0
            let replacementIDs = assetIDs(for: category, baseStyle: baseStyle)
            set(replacementIDs[selectedIndex], for: category, in: &updatedAppearance)
        }

        updatedAppearance.baseStyle = baseStyle
        return updatedAppearance
    }

    private static func set(
        _ optionID: String,
        for category: CharacterCustomizationCategory,
        in appearance: inout CharacterAppearance
    ) {
        switch category {
        case .base:
            break
        case .hair:
            appearance.hairStyle = optionID
        case .brows:
            appearance.browsStyle = optionID
        case .eyes:
            appearance.eyesStyle = optionID
        case .nose:
            appearance.noseStyle = optionID
        case .mouth:
            appearance.mouthStyle = optionID
        }
    }
}
