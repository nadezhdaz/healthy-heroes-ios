import Foundation

struct LogFoodResult: Equatable {
    let updatedProfile: ChildProfile
    let foodLogEntry: FoodLogEntry
    let completedQuestIDs: [QuestID]
    let unlockedRewardIDs: [RewardID]
    let didAdvanceOnMap: Bool
    let smallProgressAwarded: Int
    let bigProgressAwarded: Int
}

protocol CreateCharacterUseCase {
    func create(appearance: CharacterAppearance) async throws -> ChildProfile
}

protocol SelectStarterClassUseCase {
    func select(_ characterClass: CharacterClass) async throws -> ChildProfile
}

protocol LogFoodUseCase {
    func log(category: FoodCategory, customTitle: String?) async throws -> LogFoodResult
}

protocol EquipItemUseCase {
    func equip(itemID: WardrobeItemID) async throws -> ChildProfile
}

protocol MarkRewardOpenedUseCase {
    func markOpened(rewardID: RewardID) async throws -> ChildProfile
}

protocol OpenMysteryPackUseCase {
    func open(rewardID: RewardID) throws -> Reward?
}

struct CreateCharacterUseCaseImpl: CreateCharacterUseCase {
    let profileRepository: any ProfileRepository
    let gameConfigRepository: any GameConfigRepository

    func create(appearance: CharacterAppearance) async throws -> ChildProfile {
        var profile = try await profileRepository.loadProfile()
            ?? ChildProfile.starter(quests: gameConfigRepository.starterQuests())
        profile.character.appearance = appearance
        profile.onboarding.hasCreatedCharacter = true
        try await profileRepository.saveProfile(profile)
        return profile
    }
}

struct SelectStarterClassUseCaseImpl: SelectStarterClassUseCase {
    let profileRepository: any ProfileRepository
    let gameConfigRepository: any GameConfigRepository

    func select(_ characterClass: CharacterClass) async throws -> ChildProfile {
        guard characterClass.isAvailableAtStart else {
            throw UseCaseError.classLocked
        }

        var profile = try await profileRepository.loadProfile()
            ?? ChildProfile.starter(quests: gameConfigRepository.starterQuests())
        profile.character.selectedClass = characterClass
        profile.onboarding.hasSelectedClass = true
        try await profileRepository.saveProfile(profile)
        return profile
    }
}

struct LogFoodUseCaseImpl: LogFoodUseCase {
    let gameStateRepository: any GameStateRepository
    let gameConfigRepository: any GameConfigRepository
    let progressEngine: ProgressEngine
    let questEngine: QuestEngine
    let rewardEngine: RewardEngine
    let mapEngine: MapEngine
    var idProvider: () -> String = { UUID().uuidString }
    var dateProvider: () -> Date = Date.init

    func log(category: FoodCategory, customTitle: String?) async throws -> LogFoodResult {
        let normalizedCustomTitle: String?
        if category == .custom {
            let title = customTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !title.isEmpty else {
                throw UseCaseError.customFoodTitleRequired
            }
            normalizedCustomTitle = title
        } else {
            normalizedCustomTitle = nil
        }

        let progressConfig = try gameConfigRepository.progressConfig()
        let mapConfig = try gameConfigRepository.mapConfig()
        var profile = try await gameStateRepository.loadProfile()
            ?? ChildProfile.starter(quests: gameConfigRepository.starterQuests())
        let previousMapPosition = profile.progress.mapPosition

        let entry = FoodLogEntry(
            id: idProvider(),
            category: category,
            customTitle: normalizedCustomTitle,
            createdAt: dateProvider()
        )
        let smallProgress = progressEngine.smallProgressAward(config: progressConfig)
        profile.progress = progressEngine.addingXP(smallProgress, to: profile.progress)

        let questUpdate = questEngine.updateQuests(afterLogging: category, quests: profile.quests)
        profile.quests = questUpdate.quests

        let bigProgress = progressEngine.bigProgressAward(
            completedQuestCount: questUpdate.completedQuestIDs.count,
            config: progressConfig
        )
        profile.progress = progressEngine.addingXP(bigProgress, to: profile.progress)

        profile.progress.mapPosition = mapEngine.updatedMapPosition(
            totalXP: profile.progress.totalXP,
            config: mapConfig
        )

        let rewardUpdate = rewardEngine.unlockRewards(
            for: questUpdate.completedQuestIDs,
            in: profile
        )
        profile = rewardUpdate.profile
        profile.onboarding.hasCompletedFirstFoodLog = true
        if !questUpdate.completedQuestIDs.isEmpty {
            profile.onboarding.hasCompletedFirstQuest = true
        }
        profile.onboarding.isFirstSessionCompleted = profile.onboarding.hasFinishedFirstSessionLoop

        try await gameStateRepository.commitFoodLog(entry, updatedProfile: profile)

        return LogFoodResult(
            updatedProfile: profile,
            foodLogEntry: entry,
            completedQuestIDs: questUpdate.completedQuestIDs,
            unlockedRewardIDs: rewardUpdate.unlockedRewardIDs,
            didAdvanceOnMap: profile.progress.mapPosition > previousMapPosition,
            smallProgressAwarded: smallProgress,
            bigProgressAwarded: bigProgress
        )
    }
}

struct EquipItemUseCaseImpl: EquipItemUseCase {
    let profileRepository: any ProfileRepository

    func equip(itemID: WardrobeItemID) async throws -> ChildProfile {
        guard var profile = try await profileRepository.loadProfile() else {
            throw UseCaseError.missingProfile
        }
        guard profile.wardrobe.unlockedItemIDs.contains(itemID) else {
            throw UseCaseError.itemLocked
        }

        if !profile.character.equippedItemIDs.contains(itemID) {
            profile.character.equippedItemIDs.append(itemID)
        }
        if !profile.wardrobe.equippedItemIDs.contains(itemID) {
            profile.wardrobe.equippedItemIDs.append(itemID)
        }
        profile.onboarding.hasEquippedFirstItem = true
        profile.onboarding.isFirstSessionCompleted = profile.onboarding.hasFinishedFirstSessionLoop
        try await profileRepository.saveProfile(profile)
        return profile
    }
}

struct MarkRewardOpenedUseCaseImpl: MarkRewardOpenedUseCase {
    let gameStateRepository: any GameStateRepository

    func markOpened(rewardID: RewardID) async throws -> ChildProfile {
        guard var profile = try await gameStateRepository.loadProfile() else {
            throw UseCaseError.missingProfile
        }
        guard profile.unlockedRewardIDs.contains(rewardID) else {
            throw UseCaseError.rewardLocked
        }

        profile.onboarding.hasOpenedFirstReward = true
        profile.onboarding.isFirstSessionCompleted = profile.onboarding.hasFinishedFirstSessionLoop
        try await gameStateRepository.commitRewardOpened(rewardID, updatedProfile: profile)
        return profile
    }
}

struct OpenMysteryPackUseCaseImpl: OpenMysteryPackUseCase {
    let rewardCatalogRepository: any RewardCatalogRepository

    func open(rewardID: RewardID) throws -> Reward? {
        try rewardCatalogRepository.reward(id: rewardID)
    }
}

enum UseCaseError: Error, Equatable {
    case missingProfile
    case itemLocked
    case classLocked
    case rewardLocked
    case customFoodTitleRequired
}
