import Combine
import CoreText
import SwiftUI

@main
struct HealthyHeroesApp: App {
    @StateObject private var container = AppDependencyContainer.live()

    init() {
        Self.registerDesignFonts()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(container: container)
        }
    }

    private static func registerDesignFonts() {
        let fontNames = [
            "MPLUSRounded1c-Regular",
            "MPLUSRounded1c-Bold",
            "MPLUSRounded1c-Black"
        ]

        for fontName in fontNames {
            guard let url = Bundle.main.url(
                forResource: fontName,
                withExtension: "ttf"
            ) else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
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
            StartView(router: container.router, eventBus: container.eventBus)
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
                profileRepository: container.profileRepository,
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
                    router: container.router,
                    profileRepository: container.profileRepository
                )
            )
        case .map:
            MapView(
                profileRepository: container.profileRepository,
                mapConfigRepository: container.gameConfigRepository,
                eventBus: container.eventBus
            )
        case .quests:
            QuestsView(profileRepository: container.profileRepository, eventBus: container.eventBus)
        case .rewards:
            RewardsView(
                profileRepository: container.profileRepository,
                rewardCatalogRepository: container.rewardCatalogRepository,
                eventBus: container.eventBus,
                router: container.router,
                foodLogRepository: container.foodLogRepository
            )
        case .wardrobe:
            WardrobeView(
                profileRepository: container.profileRepository,
                equipItemUseCase: container.equipItemUseCase,
                eventBus: container.eventBus
            )
        case .stickerAlbum:
            StickerAlbumView(profileRepository: container.profileRepository, eventBus: container.eventBus)
        case .miniGames:
            MainHubComingSoonView(title: "MINI GAMES", systemImage: "gamecontroller.fill")
        case .settings:
            MainHubComingSoonView(title: "SETTINGS", systemImage: "gearshape.fill")
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
                ZStack {
                    GameDesign.cream
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(GameDesign.green)
                }
            case .onboarding:
                StartView(router: container.router, eventBus: container.eventBus)
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
        .task {
            await loadInitialState()
        }
        .onAppear {
            cancellable = container.eventBus.events.sink { event in
                if case let .profileUpdated(profile) = event {
                    rootState = profile.character.selectedClass == nil ? .onboarding : .main
                }
            }
        }
    }

    private func loadInitialState() async {
        do {
            let profile = try await container.profileRepository.loadProfile()
            rootState = profile?.character.selectedClass == nil ? .onboarding : .main
        } catch {
            rootState = .onboarding
        }
    }
}
