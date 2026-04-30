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

    var totalXPText: String {
        "\(profile?.progress.totalXP ?? 0) XP"
    }

    var mapProgressText: String {
        "Map step \(profile?.progress.mapPosition ?? 0)"
    }

    var firstSessionCTA: String? {
        guard let onboarding = profile?.onboarding else {
            return "Log the first healthy choice"
        }
        if !onboarding.hasCompletedFirstFoodLog {
            return "Log the first healthy choice"
        }
        if !onboarding.hasCompletedFirstQuest {
            return "Finish the first quest"
        }
        if !onboarding.hasOpenedFirstReward {
            return "Open the first reward"
        }
        return nil
    }

    var hasUnlockedRewards: Bool {
        !(profile?.unlockedRewardIDs.isEmpty ?? true)
    }

    func load() {
        do {
            if let loadedProfile = try profileRepository.loadProfile() {
                profile = loadedProfile
            } else {
                let starterProfile = ChildProfile.starter(
                    quests: try gameConfigRepository.starterQuests()
                )
                try profileRepository.saveProfile(starterProfile)
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

    private func handle(_ event: AppEvent) {
        switch event {
        case let .profileUpdated(profile):
            self.profile = profile
        case let .firstSessionProgressUpdated(onboarding):
            profile?.onboarding = onboarding
        case .foodLogged, .questCompleted, .rewardsUnlocked, .itemEquipped:
            load()
        }
    }
}
