import Foundation
@testable import HealthyHeroes

final class InMemoryProfileRepository: GameStateRepository {
    var profile: ChildProfile?
    private(set) var savedProfiles: [ChildProfile] = []
    private(set) var entries: [FoodLogEntry] = []
    var commitError: Error?

    init(profile: ChildProfile? = nil) {
        self.profile = profile
    }

    func loadProfile() async throws -> ChildProfile? {
        profile
    }

    func saveProfile(_ profile: ChildProfile) async throws {
        self.profile = profile
        savedProfiles.append(profile)
    }

    func fetchEntries() async throws -> [FoodLogEntry] {
        entries
    }

    func addEntry(_ entry: FoodLogEntry) async throws {
        entries.append(entry)
    }

    func commitFoodLog(_ entry: FoodLogEntry, updatedProfile: ChildProfile) async throws {
        if let commitError { throw commitError }
        entries.append(entry)
        profile = updatedProfile
        savedProfiles.append(updatedProfile)
    }

    func commitRewardOpened(_ rewardID: RewardID, updatedProfile: ChildProfile) async throws {
        if let commitError { throw commitError }
        profile = updatedProfile
        savedProfiles.append(updatedProfile)
    }
}

struct StaticRewardCatalogRepository: RewardCatalogRepository {
    var rewards: [Reward]

    func reward(id: RewardID) throws -> Reward? {
        rewards.first { $0.id == id }
    }

    func allRewards() throws -> [Reward] {
        rewards
    }
}

struct StaticGameConfigRepository: GameConfigRepository {
    var progress = ProgressConfig(smallFoodLogXP: 5, completedQuestXP: 25)
    var quests: [Quest]
    var map = MapConfig(xpPerStep: 10, maxPosition: 20)

    func progressConfig() throws -> ProgressConfig {
        progress
    }

    func starterQuests() throws -> [Quest] {
        quests
    }

    func mapConfig() throws -> MapConfig {
        map
    }
}

func makeQuest(
    id: QuestID = "quest",
    target: Int = 1,
    currentProgress: Int = 0,
    rewardID: RewardID? = "wardrobe_leaf_cape",
    status: QuestStatus = .active,
    trigger: QuestTrigger = .logAnyHealthyFood
) -> Quest {
    Quest(
        id: id,
        type: .daily,
        title: "Test quest",
        target: target,
        currentProgress: currentProgress,
        rewardID: rewardID,
        status: status,
        trigger: trigger
    )
}

func makeProfile(
    quests: [Quest] = [makeQuest()],
    selectedClass: CharacterClass = .knight
) -> ChildProfile {
    ChildProfile(
        id: "child",
        character: CharacterState(
            appearance: CharacterAppearance(),
            selectedClass: selectedClass,
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
