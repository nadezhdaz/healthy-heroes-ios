import Foundation

typealias QuestID = String
typealias RewardID = String
typealias WardrobeItemID = String
typealias StickerID = String

struct ChildProfile: Codable, Equatable, Identifiable {
    var id: String
    var character: CharacterState
    var progress: ProgressState
    var quests: [Quest]
    var unlockedRewardIDs: [RewardID]
    var wardrobe: WardrobeState
    var stickers: StickerAlbumState
    var onboarding: OnboardingState
    // Optional for compatibility with existing JSON profiles.
    var openedRewardIDs: [RewardID]? = nil

    static func starter(quests: [Quest]) -> ChildProfile {
        ChildProfile(
            id: UUID().uuidString,
            character: CharacterState(
                appearance: CharacterAppearance(),
                selectedClass: nil,
                equippedItemIDs: []
            ),
            progress: ProgressState(totalXP: 0, mapPosition: 0),
            quests: quests,
            unlockedRewardIDs: [],
            wardrobe: WardrobeState(unlockedItemIDs: [], equippedItemIDs: []),
            stickers: StickerAlbumState(unlockedStickerIDs: []),
            onboarding: OnboardingState()
        )
    }
}

struct CharacterState: Codable, Equatable {
    var appearance: CharacterAppearance
    var selectedClass: CharacterClass?
    var equippedItemIDs: [WardrobeItemID]
}

enum CharacterBaseStyle: String, Codable, CaseIterable, Identifiable {
    case boy = "type_a"
    case girl = "type_b"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .boy: "Boy"
        case .girl: "Girl"
        }
    }
}

struct CharacterAppearance: Codable, Equatable {
    static let defaultFaceStyle = "hero_head_1"
    static let defaultEarsStyle = "hero_ears_01"

    var baseStyle: CharacterBaseStyle
    var hairStyle: String
    var faceStyle: String
    var browsStyle: String
    var eyesStyle: String
    var noseStyle: String
    var mouthStyle: String
    var earsStyle: String

    init(
        baseStyle: CharacterBaseStyle? = nil,
        hairStyle: String? = nil,
        faceStyle: String? = nil,
        browsStyle: String? = nil,
        eyesStyle: String? = nil,
        noseStyle: String? = nil,
        mouthStyle: String? = nil,
        earsStyle: String? = nil
    ) {
        let resolvedBaseStyle = baseStyle ?? Self.inferredBaseStyle(
            from: [hairStyle, browsStyle, eyesStyle, noseStyle, mouthStyle]
        )
        let legacyHeadStyle = hairStyle.flatMap { style in
            style.hasPrefix("hero_head_") ? style : nil
        }

        self.baseStyle = resolvedBaseStyle
        self.hairStyle = Self.normalizedFeatureStyle(
            hairStyle,
            legacyPrefix: "hero_hair_",
            currentPrefix: resolvedBaseStyle.hairAssetPrefix,
            defaultStyle: Self.defaultHairStyle(for: resolvedBaseStyle),
            replacingLegacyHead: legacyHeadStyle != nil
        )
        self.faceStyle = legacyHeadStyle
            ?? Self.normalizedFaceStyle(faceStyle)
        self.browsStyle = browsStyle
            ?? Self.defaultBrowsStyle(for: resolvedBaseStyle)
        self.eyesStyle = Self.normalizedFeatureStyle(
            eyesStyle,
            legacyPrefix: "hero_eyes_",
            currentPrefix: resolvedBaseStyle.featureAssetPrefix + "eyes",
            defaultStyle: Self.defaultEyesStyle(for: resolvedBaseStyle)
        )
        self.noseStyle = Self.normalizedFeatureStyle(
            noseStyle,
            legacyPrefix: "hero_nose_",
            currentPrefix: resolvedBaseStyle.featureAssetPrefix + "nose",
            defaultStyle: Self.defaultNoseStyle(for: resolvedBaseStyle)
        )
        self.mouthStyle = mouthStyle
            ?? Self.defaultMouthStyle(for: resolvedBaseStyle)
        self.earsStyle = earsStyle ?? Self.defaultEarsStyle
    }

    static func defaultHairStyle(for baseStyle: CharacterBaseStyle) -> String {
        "\(baseStyle.hairAssetPrefix)1"
    }

    static func defaultBrowsStyle(for baseStyle: CharacterBaseStyle) -> String {
        "\(baseStyle.featureAssetPrefix)brows1"
    }

    static func defaultEyesStyle(for baseStyle: CharacterBaseStyle) -> String {
        "\(baseStyle.featureAssetPrefix)eyes1"
    }

    static func defaultNoseStyle(for baseStyle: CharacterBaseStyle) -> String {
        "\(baseStyle.featureAssetPrefix)nose1"
    }

    static func defaultMouthStyle(for baseStyle: CharacterBaseStyle) -> String {
        "\(baseStyle.featureAssetPrefix)mouth1"
    }

    static func inferredBaseStyle(from styles: [String?]) -> CharacterBaseStyle {
        styles.compactMap { $0 }.contains { style in
            style.hasPrefix("g_") || style.hasPrefix("ghairstyle_")
        } ? .girl : .boy
    }

    private static func normalizedFaceStyle(_ style: String?) -> String {
        guard let style, style != "hero_face_01" else {
            return defaultFaceStyle
        }
        return style
    }

    private static func normalizedFeatureStyle(
        _ style: String?,
        legacyPrefix: String,
        currentPrefix: String,
        defaultStyle: String,
        replacingLegacyHead: Bool = false
    ) -> String {
        guard !replacingLegacyHead, let style else { return defaultStyle }
        guard style.hasPrefix(legacyPrefix) else { return style }

        let suffix = style.dropFirst(legacyPrefix.count)
        guard let index = Int(suffix), (1...4).contains(index) else {
            return defaultStyle
        }
        return "\(currentPrefix)\(index)"
    }

    private enum CodingKeys: String, CodingKey {
        case baseStyle
        case hairStyle
        case faceStyle
        case browsStyle
        case eyesStyle
        case noseStyle
        case mouthStyle
        case earsStyle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            baseStyle: try container.decodeIfPresent(CharacterBaseStyle.self, forKey: .baseStyle),
            hairStyle: try container.decodeIfPresent(String.self, forKey: .hairStyle),
            faceStyle: try container.decodeIfPresent(String.self, forKey: .faceStyle),
            browsStyle: try container.decodeIfPresent(String.self, forKey: .browsStyle),
            eyesStyle: try container.decodeIfPresent(String.self, forKey: .eyesStyle),
            noseStyle: try container.decodeIfPresent(String.self, forKey: .noseStyle),
            mouthStyle: try container.decodeIfPresent(String.self, forKey: .mouthStyle),
            earsStyle: try container.decodeIfPresent(String.self, forKey: .earsStyle)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(baseStyle, forKey: .baseStyle)
        try container.encode(hairStyle, forKey: .hairStyle)
        try container.encode(faceStyle, forKey: .faceStyle)
        try container.encode(browsStyle, forKey: .browsStyle)
        try container.encode(eyesStyle, forKey: .eyesStyle)
        try container.encode(noseStyle, forKey: .noseStyle)
        try container.encode(mouthStyle, forKey: .mouthStyle)
        try container.encode(earsStyle, forKey: .earsStyle)
    }
}

private extension CharacterBaseStyle {
    var featureAssetPrefix: String {
        switch self {
        case .boy: "b_"
        case .girl: "g_"
        }
    }

    var hairAssetPrefix: String {
        switch self {
        case .boy: "bhairstyle_"
        case .girl: "ghairstyle_"
        }
    }
}

enum CharacterClass: String, Codable, CaseIterable, Identifiable {
    case knight
    case princess
    case wizard
    case fairy
    case elf
    case mermaid
    case unicorn
    case dragon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .knight: "Knight"
        case .princess: "Princess"
        case .wizard: "Wizard"
        case .fairy: "Fairy"
        case .elf: "Elf"
        case .mermaid: "Mermaid"
        case .unicorn: "Unicorn"
        case .dragon: "Dragon"
        }
    }

    var isAvailableAtStart: Bool {
        switch self {
        case .knight, .princess:
            true
        case .wizard, .fairy, .elf, .mermaid, .unicorn, .dragon:
            false
        }
    }

    var isLocked: Bool {
        !isAvailableAtStart
    }

    var assetID: String {
        switch self {
        case .knight:
            "class_knight"
        case .princess:
            "class_princess"
        case .wizard:
            "class_wizard"
        case .fairy:
            "class_fairy"
        case .elf:
            "class_elf"
        case .mermaid:
            "class_mermaid"
        case .unicorn:
            "class_unicorn"
        case .dragon:
            "class_dragon"
        }
    }

    var starterClothingAssetIDs: [String] {
        switch self {
        case .knight:
            ["main_knight_shirt", "main_knight_legs", "main_knight_shoes"]
        case .princess:
            ["main_princess_shirt", "main_princess_legs", "main_princess_shoes"]
        case .wizard, .fairy, .elf, .mermaid, .unicorn, .dragon:
            []
        }
    }

    var starterAccessoryAssetIDs: [String] {
        switch self {
        case .knight:
            ["main_knight_hat", "main_knight_sword"]
        case .princess:
            ["main_princess_hat"]
        case .wizard, .fairy, .elf, .mermaid, .unicorn, .dragon:
            []
        }
    }
}

struct ProgressState: Codable, Equatable {
    var totalXP: Int
    var mapPosition: Int
}

struct FoodLogEntry: Codable, Equatable, Identifiable {
    var id: String
    var category: FoodCategory
    var customTitle: String?
    var createdAt: Date
}

enum FoodCategory: String, Codable, CaseIterable, Identifiable {
    case fruit
    case vegetable
    case water
    case healthyMeal
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fruit: "Fruit"
        case .vegetable: "Vegetable"
        case .water: "Water"
        case .healthyMeal: "Healthy Meal"
        case .custom: "Custom"
        }
    }
}

struct Quest: Codable, Equatable, Identifiable {
    var id: QuestID
    var type: QuestType
    var title: String
    var target: Int
    var currentProgress: Int
    var rewardID: RewardID?
    var status: QuestStatus
    var trigger: QuestTrigger
    var assetID: String? = nil
}

enum QuestType: String, Codable {
    case daily
    case challenge
    case milestone
}

enum QuestStatus: String, Codable {
    case active
    case completed
    case rewarded
}

enum QuestTrigger: String, Codable {
    case logAnyHealthyFood
    case logFruit
    case logVegetable
    case logWater
    case logHealthyMeal

    func matches(_ category: FoodCategory) -> Bool {
        switch self {
        case .logAnyHealthyFood:
            true
        case .logFruit:
            category == .fruit
        case .logVegetable:
            category == .vegetable
        case .logWater:
            category == .water
        case .logHealthyMeal:
            category == .healthyMeal
        }
    }
}

struct Reward: Codable, Equatable, Identifiable {
    var id: RewardID
    var type: RewardType
    var title: String
    var assetID: String
}

enum RewardType: String, Codable {
    case wardrobeItem
    case sticker
    case classUnlock
}

struct WardrobeState: Codable, Equatable {
    var unlockedItemIDs: [WardrobeItemID]
    var equippedItemIDs: [WardrobeItemID]
}

struct StickerAlbumState: Codable, Equatable {
    var unlockedStickerIDs: [StickerID]
}

struct OnboardingState: Codable, Equatable {
    var hasSeenStart: Bool
    var hasCreatedCharacter: Bool
    var hasSelectedClass: Bool
    var hasCompletedFirstFoodLog: Bool
    var hasCompletedFirstQuest: Bool
    var hasOpenedFirstReward: Bool
    var hasEquippedFirstItem: Bool
    var isFirstSessionCompleted: Bool

    init(
        hasSeenStart: Bool = false,
        hasCreatedCharacter: Bool = false,
        hasSelectedClass: Bool = false,
        hasCompletedFirstFoodLog: Bool = false,
        hasCompletedFirstQuest: Bool = false,
        hasOpenedFirstReward: Bool = false,
        hasEquippedFirstItem: Bool = false,
        isFirstSessionCompleted: Bool = false
    ) {
        self.hasSeenStart = hasSeenStart
        self.hasCreatedCharacter = hasCreatedCharacter
        self.hasSelectedClass = hasSelectedClass
        self.hasCompletedFirstFoodLog = hasCompletedFirstFoodLog
        self.hasCompletedFirstQuest = hasCompletedFirstQuest
        self.hasOpenedFirstReward = hasOpenedFirstReward
        self.hasEquippedFirstItem = hasEquippedFirstItem
        self.isFirstSessionCompleted = isFirstSessionCompleted
    }

    var hasFinishedFirstSessionLoop: Bool {
        hasCompletedFirstFoodLog
            && hasCompletedFirstQuest
            && hasOpenedFirstReward
            && hasEquippedFirstItem
    }
}

struct ProgressConfig: Codable, Equatable {
    var smallFoodLogXP: Int
    var completedQuestXP: Int
}

struct MapConfig: Codable, Equatable {
    var xpPerStep: Int
    var maxPosition: Int
    var routeAnchors: [MapAnchor]

    init(xpPerStep: Int, maxPosition: Int, routeAnchors: [MapAnchor] = MapAnchor.defaultRoute) {
        self.xpPerStep = xpPerStep
        self.maxPosition = maxPosition
        self.routeAnchors = routeAnchors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            xpPerStep: try container.decode(Int.self, forKey: .xpPerStep),
            maxPosition: try container.decode(Int.self, forKey: .maxPosition),
            routeAnchors: try container.decodeIfPresent([MapAnchor].self, forKey: .routeAnchors) ?? MapAnchor.defaultRoute
        )
    }

    private enum CodingKeys: String, CodingKey { case xpPerStep, maxPosition, routeAnchors }

    func anchor(at position: Int) -> MapAnchor {
        guard !routeAnchors.isEmpty else { return MapAnchor(x: 0.5, y: 0.5) }
        return routeAnchors[min(max(position, 0), routeAnchors.count - 1)]
    }
}

struct MapAnchor: Codable, Equatable {
    let x: Double
    let y: Double

    static let defaultRoute: [MapAnchor] = [
        // Canonical route in the five-column iPad map world; phones recompose it.
        (0.158672, 0.100207), (0.331699, 0.100207), (0.504727, 0.100207), (0.677755, 0.100207), (0.850770, 0.101161),
        (0.898664, 0.332835), (0.729128, 0.366736), (0.556100, 0.366736), (0.383073, 0.366736), (0.210045, 0.366736),
        (0.072219, 0.5), (0.210045, 0.633264), (0.383073, 0.633264), (0.556100, 0.633264), (0.729128, 0.633264),
        (0.898664, 0.667165), (0.850770, 0.898839), (0.677755, 0.899793), (0.504727, 0.899793), (0.331699, 0.899793),
        (0.158672, 0.899793)
    ].map { MapAnchor(x: $0.0, y: $0.1) }
}

enum WardrobeCategory: String, CaseIterable, Identifiable, Codable {
    case head = "Head", top = "Top", legs = "Legs", feet = "Feet", accessories = "Accessories"
    var id: String { rawValue }
}

struct WardrobeItemDefinition: Codable, Equatable, Identifiable {
    var category: WardrobeCategory? = nil
    var id: WardrobeItemID
    var title: String
    var assetID: String
}

struct StickerDefinition: Codable, Equatable, Identifiable {
    var id: StickerID
    var title: String
    var assetID: String
}
