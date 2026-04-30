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
    func create(appearance: CharacterAppearance) throws -> ChildProfile
}

protocol SelectStarterClassUseCase {
    func select(_ characterClass: CharacterClass) throws -> ChildProfile
}

protocol LogFoodUseCase {
    func log(category: FoodCategory, customTitle: String?) throws -> LogFoodResult
}

protocol EquipItemUseCase {
    func equip(itemID: WardrobeItemID) throws -> ChildProfile
}

protocol OpenMysteryPackUseCase {
    func open(rewardID: RewardID) throws -> Reward?
}

struct CreateCharacterUseCaseImpl: CreateCharacterUseCase {
    let profileRepository: any ProfileRepository
    let gameConfigRepository: any GameConfigRepository

    func create(appearance: CharacterAppearance) throws -> ChildProfile {
        var profile = try profileRepository.loadProfile()
            ?? ChildProfile.starter(quests: gameConfigRepository.starterQuests())
        profile.character.appearance = appearance
        profile.onboarding.hasCreatedCharacter = true
        try profileRepository.saveProfile(profile)
        return profile
    }
}

struct SelectStarterClassUseCaseImpl: SelectStarterClassUseCase {
    let profileRepository: any ProfileRepository
    let gameConfigRepository: any GameConfigRepository

    func select(_ characterClass: CharacterClass) throws -> ChildProfile {
        var profile = try profileRepository.loadProfile()
            ?? ChildProfile.starter(quests: gameConfigRepository.starterQuests())
        profile.character.selectedClass = characterClass
        profile.onboarding.hasSelectedClass = true
        try profileRepository.saveProfile(profile)
        return profile
    }
}

struct LogFoodUseCaseImpl: LogFoodUseCase {
    let profileRepository: any ProfileRepository
    let foodLogRepository: any FoodLogRepository
    let gameConfigRepository: any GameConfigRepository
    let progressEngine: ProgressEngine
    let questEngine: QuestEngine
    let rewardEngine: RewardEngine
    let mapEngine: MapEngine
    var idProvider: () -> String = { UUID().uuidString }
    var dateProvider: () -> Date = Date.init

    func log(category: FoodCategory, customTitle: String?) throws -> LogFoodResult {
        let progressConfig = try gameConfigRepository.progressConfig()
        let mapConfig = try gameConfigRepository.mapConfig()
        var profile = try profileRepository.loadProfile()
            ?? ChildProfile.starter(quests: gameConfigRepository.starterQuests())
        let previousMapPosition = profile.progress.mapPosition

        let entry = FoodLogEntry(
            id: idProvider(),
            category: category,
            customTitle: category == .custom ? customTitle : nil,
            createdAt: dateProvider()
        )
        try foodLogRepository.addEntry(entry)

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

        var rewardUpdate = rewardEngine.unlockRewards(
            for: questUpdate.completedQuestIDs,
            in: profile
        )
        profile = rewardUpdate.profile
        profile.onboarding.hasCompletedFirstFoodLog = true
        if !questUpdate.completedQuestIDs.isEmpty {
            profile.onboarding.hasCompletedFirstQuest = true
        }
        if !rewardUpdate.unlockedRewardIDs.isEmpty {
            profile.onboarding.hasOpenedFirstReward = true
        }
        profile.onboarding.isFirstSessionCompleted = profile.onboarding.hasCompletedFirstFoodLog
            && profile.onboarding.hasCompletedFirstQuest
            && profile.onboarding.hasOpenedFirstReward

        try profileRepository.saveProfile(profile)

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

    func equip(itemID: WardrobeItemID) throws -> ChildProfile {
        guard var profile = try profileRepository.loadProfile() else {
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
        try profileRepository.saveProfile(profile)
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
}
