import Foundation

struct ProgressEngine {
    func smallProgressAward(config: ProgressConfig) -> Int {
        config.smallFoodLogXP
    }

    func bigProgressAward(completedQuestCount: Int, config: ProgressConfig) -> Int {
        completedQuestCount * config.completedQuestXP
    }

    func addingXP(_ xp: Int, to progress: ProgressState) -> ProgressState {
        ProgressState(totalXP: progress.totalXP + xp, mapPosition: progress.mapPosition)
    }
}

struct QuestUpdateResult: Equatable {
    var quests: [Quest]
    var completedQuestIDs: [QuestID]
}

struct QuestEngine {
    func updateQuests(afterLogging category: FoodCategory, quests: [Quest]) -> QuestUpdateResult {
        var completedQuestIDs: [QuestID] = []

        let updatedQuests = quests.map { quest in
            guard quest.status == .active, quest.trigger.matches(category) else {
                return quest
            }

            var updatedQuest = quest
            updatedQuest.currentProgress = min(quest.currentProgress + 1, quest.target)

            if updatedQuest.currentProgress >= updatedQuest.target {
                updatedQuest.status = .completed
                completedQuestIDs.append(updatedQuest.id)
            }

            return updatedQuest
        }

        return QuestUpdateResult(quests: updatedQuests, completedQuestIDs: completedQuestIDs)
    }
}

struct RewardUnlockResult: Equatable {
    var profile: ChildProfile
    var unlockedRewardIDs: [RewardID]
}

struct RewardEngine {
    func unlockRewards(for completedQuestIDs: [QuestID], in profile: ChildProfile) -> RewardUnlockResult {
        var profile = profile
        let completedQuestSet = Set(completedQuestIDs)
        let existingRewardIDs = Set(profile.unlockedRewardIDs)

        let newRewardIDs = profile.quests
            .filter { completedQuestSet.contains($0.id) }
            .compactMap(\.rewardID)
            .filter { !existingRewardIDs.contains($0) }

        guard !newRewardIDs.isEmpty else {
            return RewardUnlockResult(profile: profile, unlockedRewardIDs: [])
        }

        profile.unlockedRewardIDs.append(contentsOf: newRewardIDs)
        profile.wardrobe.unlockedItemIDs.append(
            contentsOf: newRewardIDs.filter { $0.hasPrefix("wardrobe_") }
        )
        profile.stickers.unlockedStickerIDs.append(
            contentsOf: newRewardIDs.filter { $0.hasPrefix("sticker_") }
        )
        profile.quests = profile.quests.map { quest in
            guard completedQuestSet.contains(quest.id), quest.status == .completed else {
                return quest
            }

            var rewardedQuest = quest
            rewardedQuest.status = .rewarded
            return rewardedQuest
        }

        return RewardUnlockResult(profile: profile, unlockedRewardIDs: newRewardIDs)
    }
}

struct MapEngine {
    func updatedMapPosition(totalXP: Int, config: MapConfig) -> Int {
        guard config.xpPerStep > 0 else { return 0 }
        return min(totalXP / config.xpPerStep, config.maxPosition)
    }
}
