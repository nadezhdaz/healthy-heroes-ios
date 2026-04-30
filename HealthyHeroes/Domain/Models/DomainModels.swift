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

struct CharacterAppearance: Codable, Equatable {
    var hairStyle: String
    var faceStyle: String
    var eyesStyle: String
    var noseStyle: String
    var earsStyle: String

    init(
        hairStyle: String = "hero_hair_01",
        faceStyle: String = "hero_face_01",
        eyesStyle: String = "hero_eyes_01",
        noseStyle: String = "hero_nose_01",
        earsStyle: String = "hero_ears_01"
    ) {
        self.hairStyle = hairStyle
        self.faceStyle = faceStyle
        self.eyesStyle = eyesStyle
        self.noseStyle = noseStyle
        self.earsStyle = earsStyle
    }
}

enum CharacterClass: String, Codable, CaseIterable, Identifiable {
    case guardian
    case explorer
    case sproutMage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .guardian: "Guardian"
        case .explorer: "Explorer"
        case .sproutMage: "Sprout Mage"
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
}

struct ProgressConfig: Codable, Equatable {
    var smallFoodLogXP: Int
    var completedQuestXP: Int
}

struct MapConfig: Codable, Equatable {
    var xpPerStep: Int
    var maxPosition: Int
}

struct WardrobeItemDefinition: Codable, Equatable, Identifiable {
    var id: WardrobeItemID
    var title: String
    var assetID: String
}

struct StickerDefinition: Codable, Equatable, Identifiable {
    var id: StickerID
    var title: String
    var assetID: String
}
