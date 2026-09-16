import Combine
import Foundation

@MainActor
final class MainViewModel: ObservableObject {
    @Published private(set) var profile: ChildProfile?
    @Published private(set) var errorMessage: String?

    private let profileRepository: any ProfileRepository
    private let gameConfigRepository: any GameConfigRepository
    private let eventBus: AppEventBus
    private let router: AppRouter
    private var cancellables: Set<AnyCancellable> = []

    init(
        profileRepository: any ProfileRepository,
        gameConfigRepository: any GameConfigRepository,
        eventBus: AppEventBus,
        router: AppRouter
    ) {
        self.profileRepository = profileRepository
        self.gameConfigRepository = gameConfigRepository
        self.eventBus = eventBus
        self.router = router

        eventBus.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handle(event)
            }
            .store(in: &cancellables)
    }

    var heroTitle: String {
        profile?.character.selectedClass?.title ?? "Healthy Hero"
    }

    var selectedClass: CharacterClass? {
        profile?.character.selectedClass
    }

    var appearance: CharacterAppearance {
        profile?.character.appearance ?? CharacterAppearance()
    }

    var equippedItemIDs: [WardrobeItemID] {
        profile?.character.equippedItemIDs ?? []
    }

    var totalXPText: String {
        "\(profile?.progress.totalXP ?? 0) XP"
    }

    var mapProgressText: String {
        "Map step \(profile?.progress.mapPosition ?? 0)"
    }

    var progressValue: Double {
        min(Double(profile?.progress.totalXP ?? 0) / 100.0, 1.0)
    }

    var firstSessionCTA: String? {
        guard let onboarding = profile?.onboarding else {
            return "Feed your hero to make them stronger"
        }
        if !onboarding.hasCompletedFirstFoodLog {
            return "Feed your hero to make them stronger"
        }
        if !onboarding.hasCompletedFirstQuest {
            return "Finish the first quest"
        }
        return nil
    }

    var hasUnlockedRewards: Bool {
        !(profile?.unlockedRewardIDs.isEmpty ?? true)
    }

    func load() async {
        do {
            if let loadedProfile = try await profileRepository.loadProfile() {
                profile = loadedProfile
            } else {
                let starterProfile = ChildProfile.starter(
                    quests: try gameConfigRepository.starterQuests()
                )
                try await profileRepository.saveProfile(starterProfile)
                profile = starterProfile
            }
            errorMessage = nil
        } catch {
            errorMessage = "Could not load the hero profile."
        }
    }

    func openFoodLog() {
        router.show(.foodLog)
    }

    func goBack() {
        router.pop()
    }

    func openQuests() {
        router.show(.quests)
    }

    func openMap() {
        router.show(.map)
    }

    func openRewards() {
        router.show(.rewards)
    }

    func openWardrobe() {
        router.show(.wardrobe)
    }

    func openStickerAlbum() {
        router.show(.stickerAlbum)
    }

    func openMiniGames() {
        router.show(.miniGames)
    }

    func openSettings() {
        router.show(.settings)
    }

    func followFirstSessionCTA() {
        guard let onboarding = profile?.onboarding else {
            openFoodLog()
            return
        }

        if !onboarding.hasCompletedFirstFoodLog || !onboarding.hasCompletedFirstQuest {
            openFoodLog()
        }
    }

    private func handle(_ event: AppEvent) {
        switch event {
        case .appOpened, .playTapped, .characterCreated, .classSelected, .firstFoodLogged,
             .rewardOpened, .rewardEquipped:
            break
        case let .profileUpdated(profile):
            self.profile = profile
        case let .firstSessionProgressUpdated(onboarding):
            profile?.onboarding = onboarding
        case .foodLogged, .questCompleted, .rewardsUnlocked, .itemEquipped:
            break
        }
    }
}
