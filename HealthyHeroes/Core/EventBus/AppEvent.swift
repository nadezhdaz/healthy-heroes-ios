import Foundation

enum AppEvent {
    case appOpened
    case playTapped
    case characterCreated
    case classSelected(CharacterClass)
    case profileUpdated(ChildProfile)
    case foodLogged(FoodLogEntry)
    case firstFoodLogged
    case questCompleted([QuestID])
    case rewardsUnlocked([RewardID])
    case rewardOpened(RewardID)
    case rewardEquipped(RewardID)
    case itemEquipped(WardrobeItemID)
    case firstSessionProgressUpdated(OnboardingState)
}
