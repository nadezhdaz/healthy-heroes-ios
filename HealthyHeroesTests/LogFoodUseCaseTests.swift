import XCTest
@testable import HealthyHeroes

final class LogFoodUseCaseTests: XCTestCase {
    func testLogFoodSavesEntryUpdatesProfileCompletesQuestAndUnlocksReward() throws {
        let quest = makeQuest(id: "first", target: 1, rewardID: "wardrobe_leaf_cape")
        let profileRepository = InMemoryProfileRepository(profile: makeProfile(quests: [quest]))
        let foodLogRepository = InMemoryFoodLogRepository()
        let configRepository = StaticGameConfigRepository(
            progress: ProgressConfig(smallFoodLogXP: 5, completedQuestXP: 25),
            quests: [quest],
            map: MapConfig(xpPerStep: 10, maxPosition: 20)
        )
        let useCase = LogFoodUseCaseImpl(
            profileRepository: profileRepository,
            foodLogRepository: foodLogRepository,
            gameConfigRepository: configRepository,
            progressEngine: ProgressEngine(),
            questEngine: QuestEngine(),
            rewardEngine: RewardEngine(),
            mapEngine: MapEngine(),
            idProvider: { "entry-1" },
            dateProvider: { Date(timeIntervalSince1970: 100) }
        )

        let result = try useCase.log(category: .fruit, customTitle: nil)

        XCTAssertEqual(foodLogRepository.entries.map(\.id), ["entry-1"])
        XCTAssertEqual(foodLogRepository.entries.first?.category, .fruit)
        XCTAssertEqual(result.completedQuestIDs, ["first"])
        XCTAssertEqual(result.unlockedRewardIDs, ["wardrobe_leaf_cape"])
        XCTAssertEqual(result.smallProgressAwarded, 5)
        XCTAssertEqual(result.bigProgressAwarded, 25)
        XCTAssertTrue(result.didAdvanceOnMap)
        XCTAssertEqual(result.updatedProfile.progress.totalXP, 30)
        XCTAssertEqual(result.updatedProfile.progress.mapPosition, 3)
        XCTAssertEqual(result.updatedProfile.quests.first?.status, .rewarded)
        XCTAssertEqual(result.updatedProfile.wardrobe.unlockedItemIDs, ["wardrobe_leaf_cape"])
        XCTAssertEqual(profileRepository.savedProfiles.last, result.updatedProfile)
    }

    func testLogFoodCreatesStarterProfileWhenMissing() throws {
        let quest = makeQuest(id: "starter", target: 2, rewardID: nil)
        let profileRepository = InMemoryProfileRepository()
        let foodLogRepository = InMemoryFoodLogRepository()
        let configRepository = StaticGameConfigRepository(quests: [quest])
        let useCase = LogFoodUseCaseImpl(
            profileRepository: profileRepository,
            foodLogRepository: foodLogRepository,
            gameConfigRepository: configRepository,
            progressEngine: ProgressEngine(),
            questEngine: QuestEngine(),
            rewardEngine: RewardEngine(),
            mapEngine: MapEngine(),
            idProvider: { "entry-1" },
            dateProvider: { Date(timeIntervalSince1970: 100) }
        )

        let result = try useCase.log(category: .water, customTitle: nil)

        XCTAssertEqual(result.updatedProfile.quests.first?.id, "starter")
        XCTAssertEqual(result.updatedProfile.progress.totalXP, 5)
        XCTAssertEqual(profileRepository.profile?.id, result.updatedProfile.id)
    }
}
