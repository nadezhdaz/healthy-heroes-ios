import Foundation

enum AppEvent {
    case profileUpdated(ChildProfile)
    case foodLogged(FoodLogEntry)
    case questCompleted([QuestID])
    case rewardsUnlocked([RewardID])
    case itemEquipped(WardrobeItemID)
    case firstSessionProgressUpdated(OnboardingState)
}
