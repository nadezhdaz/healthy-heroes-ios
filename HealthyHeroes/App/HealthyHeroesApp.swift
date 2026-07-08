import Combine
import SwiftUI

@main
struct HealthyHeroesApp: App {
    @StateObject private var container = AppDependencyContainer.live()

    var body: some Scene {
        WindowGroup {
            AppRootView(container: container)
        }
    }
}

private struct AppRootView: View {
    @ObservedObject private var router: AppRouter
    private let container: AppDependencyContainer

    init(container: AppDependencyContainer) {
        self.container = container
        self.router = container.router
    }

    var body: some View {
        NavigationStack(path: $router.path) {
            RootFlowView(container: container)
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
        }
        .sheet(item: $router.sheet) { sheet in
            sheetView(for: sheet)
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .start:
            StartView(router: container.router)
        case .characterCreation:
            CharacterCreationView(
                router: container.router,
                createCharacterUseCase: container.createCharacterUseCase,
                eventBus: container.eventBus
            )
        case .classSelection:
            ClassSelectionView(
                router: container.router,
                selectStarterClassUseCase: container.selectStarterClassUseCase,
                eventBus: container.eventBus
            )
        case .mainHub:
            MainView(
                viewModel: MainViewModel(
                    profileRepository: container.profileRepository,
                    gameConfigRepository: container.gameConfigRepository,
                    eventBus: container.eventBus,
                    router: container.router
                )
            )
        case .foodLog:
            FoodLogView(
                viewModel: FoodLogViewModel(
                    logFoodUseCase: container.logFoodUseCase,
                    eventBus: container.eventBus,
                    router: container.router
                )
            )
        case .map:
            MapView(profileRepository: container.profileRepository, eventBus: container.eventBus)
        case .quests:
            QuestsView(profileRepository: container.profileRepository, eventBus: container.eventBus)
        case .rewards:
            RewardsView(
                profileRepository: container.profileRepository,
                rewardCatalogRepository: container.rewardCatalogRepository,
                eventBus: container.eventBus
            )
        case .wardrobe:
            WardrobeView(
                profileRepository: container.profileRepository,
                equipItemUseCase: container.equipItemUseCase,
                eventBus: container.eventBus
            )
        case .stickerAlbum:
            StickerAlbumView(profileRepository: container.profileRepository, eventBus: container.eventBus)
        case let .mysteryPack(rewardIDs):
            MysteryPackView(
                rewardIDs: rewardIDs,
                openMysteryPackUseCase: container.openMysteryPackUseCase,
                markRewardOpenedUseCase: container.markRewardOpenedUseCase,
                equipItemUseCase: container.equipItemUseCase,
                profileRepository: container.profileRepository,
                eventBus: container.eventBus,
                router: container.router
            )
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: AppSheet) -> some View {
        switch sheet {
        case let .mysteryPack(rewardIDs):
            MysteryPackView(
                rewardIDs: rewardIDs,
                openMysteryPackUseCase: container.openMysteryPackUseCase,
                markRewardOpenedUseCase: container.markRewardOpenedUseCase,
                equipItemUseCase: container.equipItemUseCase,
                profileRepository: container.profileRepository,
                eventBus: container.eventBus,
                router: container.router
            )
        case let .reward(rewardID):
            RewardRevealView(
                rewardID: rewardID,
                openMysteryPackUseCase: container.openMysteryPackUseCase,
                router: container.router
            )
        }
    }
}

private struct RootFlowView: View {
    private enum RootState {
        case loading
        case onboarding
        case main
    }

    @State private var rootState: RootState = .loading
    @State private var cancellable: AnyCancellable?

    let container: AppDependencyContainer

    var body: some View {
        Group {
            switch rootState {
            case .loading:
                ProgressView("Loading hero...")
                    .task {
                        load()
                    }
            case .onboarding:
                StartView(router: container.router)
            case .main:
                MainView(
                    viewModel: MainViewModel(
                        profileRepository: container.profileRepository,
                        gameConfigRepository: container.gameConfigRepository,
                        eventBus: container.eventBus,
                        router: container.router
                    )
                )
            }
        }
        .onAppear {
            cancellable = container.eventBus.events.sink { event in
                if case let .profileUpdated(profile) = event {
                    rootState = profile.character.selectedClass == nil ? .onboarding : .main
                }
            }
        }
    }

    private func load() {
        do {
            let profile = try container.profileRepository.loadProfile()
            rootState = profile?.character.selectedClass == nil ? .onboarding : .main
        } catch {
            rootState = .onboarding
        }
    }
}
