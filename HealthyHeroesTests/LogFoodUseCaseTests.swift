import XCTest
@testable import HealthyHeroes

final class LogFoodUseCaseTests: XCTestCase {
    func testLogFoodSavesEntryUpdatesProfileCompletesQuestAndUnlocksReward() async throws {
        let quest = makeQuest(id: "first", target: 1, rewardID: "wardrobe_leaf_cape")
        let profileRepository = InMemoryProfileRepository(profile: makeProfile(quests: [quest]))
        let configRepository = StaticGameConfigRepository(
            progress: ProgressConfig(smallFoodLogXP: 5, completedQuestXP: 25),
            quests: [quest],
            map: MapConfig(xpPerStep: 10, maxPosition: 20)
        )
        let useCase = LogFoodUseCaseImpl(
            gameStateRepository: profileRepository,
            gameConfigRepository: configRepository,
            progressEngine: ProgressEngine(),
            questEngine: QuestEngine(),
            rewardEngine: RewardEngine(),
            mapEngine: MapEngine(),
            idProvider: { "entry-1" },
            dateProvider: { Date(timeIntervalSince1970: 100) }
        )

        let result = try await useCase.log(category: .fruit, customTitle: nil)

        XCTAssertEqual(profileRepository.entries.map(\.id), ["entry-1"])
        XCTAssertEqual(profileRepository.entries.first?.category, .fruit)
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

    func testLogFoodCreatesStarterProfileWhenMissing() async throws {
        let quest = makeQuest(id: "starter", target: 2, rewardID: nil)
        let profileRepository = InMemoryProfileRepository()
        let configRepository = StaticGameConfigRepository(quests: [quest])
        let useCase = LogFoodUseCaseImpl(
            gameStateRepository: profileRepository,
            gameConfigRepository: configRepository,
            progressEngine: ProgressEngine(),
            questEngine: QuestEngine(),
            rewardEngine: RewardEngine(),
            mapEngine: MapEngine(),
            idProvider: { "entry-1" },
            dateProvider: { Date(timeIntervalSince1970: 100) }
        )

        let result = try await useCase.log(category: .water, customTitle: nil)

        XCTAssertEqual(result.updatedProfile.quests.first?.id, "starter")
        XCTAssertEqual(result.updatedProfile.progress.totalXP, 5)
        XCTAssertEqual(profileRepository.profile?.id, result.updatedProfile.id)
    }

    func testLogFoodLeavesProfileAndJournalUntouchedWhenCommitFails() async throws {
        let originalProfile = makeProfile()
        let profileRepository = InMemoryProfileRepository(profile: originalProfile)
        profileRepository.commitError = TestError.commitFailed
        let useCase = LogFoodUseCaseImpl(
            gameStateRepository: profileRepository,
            gameConfigRepository: StaticGameConfigRepository(quests: originalProfile.quests),
            progressEngine: ProgressEngine(),
            questEngine: QuestEngine(),
            rewardEngine: RewardEngine(),
            mapEngine: MapEngine(),
            idProvider: { "entry-1" },
            dateProvider: { Date(timeIntervalSince1970: 100) }
        )

        do {
            _ = try await useCase.log(category: .fruit, customTitle: nil)
            XCTFail("Expected the atomic commit to fail")
        } catch {
            XCTAssertEqual(error as? TestError, .commitFailed)
        }
        XCTAssertEqual(profileRepository.profile, originalProfile)
        XCTAssertTrue(profileRepository.entries.isEmpty)
        XCTAssertTrue(profileRepository.savedProfiles.isEmpty)
    }

    func testRewardOpeningMarksFirstRewardOpenedWithoutDuplicatingInventory() async throws {
        var profile = makeProfile()
        profile.unlockedRewardIDs = ["wardrobe_leaf_cape"]
        profile.wardrobe.unlockedItemIDs = ["wardrobe_leaf_cape"]
        profile.onboarding.hasCompletedFirstFoodLog = true
        profile.onboarding.hasCompletedFirstQuest = true
        let profileRepository = InMemoryProfileRepository(profile: profile)
        let useCase = MarkRewardOpenedUseCaseImpl(gameStateRepository: profileRepository)

        let updatedProfile = try await useCase.markOpened(rewardID: "wardrobe_leaf_cape")

        XCTAssertTrue(updatedProfile.onboarding.hasOpenedFirstReward)
        XCTAssertFalse(updatedProfile.onboarding.isFirstSessionCompleted)
        XCTAssertEqual(updatedProfile.unlockedRewardIDs, ["wardrobe_leaf_cape"])
        XCTAssertEqual(updatedProfile.wardrobe.unlockedItemIDs, ["wardrobe_leaf_cape"])
        XCTAssertEqual(profileRepository.savedProfiles.last, updatedProfile)
    }

    func testEquippingUnlockedFirstRewardCompletesFirstSessionAndPersists() async throws {
        var profile = makeProfile()
        profile.wardrobe.unlockedItemIDs = ["wardrobe_leaf_cape"]
        profile.onboarding.hasCompletedFirstFoodLog = true
        profile.onboarding.hasCompletedFirstQuest = true
        profile.onboarding.hasOpenedFirstReward = true
        let profileRepository = InMemoryProfileRepository(profile: profile)
        let useCase = EquipItemUseCaseImpl(profileRepository: profileRepository)

        let updatedProfile = try await useCase.equip(itemID: "wardrobe_leaf_cape")

        XCTAssertEqual(updatedProfile.character.equippedItemIDs, ["wardrobe_leaf_cape"])
        XCTAssertEqual(updatedProfile.wardrobe.equippedItemIDs, ["wardrobe_leaf_cape"])
        XCTAssertTrue(updatedProfile.onboarding.hasEquippedFirstItem)
        XCTAssertTrue(updatedProfile.onboarding.isFirstSessionCompleted)
        let persistedProfile = try await profileRepository.loadProfile()
        XCTAssertEqual(persistedProfile, updatedProfile)
    }

    func testEquippingLockedItemThrows() async throws {
        let profileRepository = InMemoryProfileRepository(profile: makeProfile())
        let useCase = EquipItemUseCaseImpl(profileRepository: profileRepository)

        do {
            _ = try await useCase.equip(itemID: "wardrobe_leaf_cape")
            XCTFail("Expected a locked item error")
        } catch {
            XCTAssertEqual(error as? UseCaseError, .itemLocked)
        }
    }

    func testCustomFoodRequiresAndPersistsTrimmedTitle() async throws {
        let profileRepository = InMemoryProfileRepository(profile: makeProfile())
        let useCase = LogFoodUseCaseImpl(
            gameStateRepository: profileRepository,
            gameConfigRepository: StaticGameConfigRepository(quests: [makeQuest()]),
            progressEngine: ProgressEngine(),
            questEngine: QuestEngine(),
            rewardEngine: RewardEngine(),
            mapEngine: MapEngine(),
            idProvider: { "custom-entry" },
            dateProvider: { Date(timeIntervalSince1970: 100) }
        )

        let result = try await useCase.log(category: .custom, customTitle: "  Greek yogurt  ")

        XCTAssertEqual(result.foodLogEntry.customTitle, "Greek yogurt")
        XCTAssertEqual(profileRepository.entries.first?.customTitle, "Greek yogurt")

        do {
            _ = try await useCase.log(category: .custom, customTitle: "   ")
            XCTFail("Expected an empty custom title to be rejected")
        } catch {
            XCTAssertEqual(error as? UseCaseError, .customFoodTitleRequired)
        }
        XCTAssertEqual(profileRepository.entries.count, 1)
    }
}

private enum TestError: Error {
    case commitFailed
}
