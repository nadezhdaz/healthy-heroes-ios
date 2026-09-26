import SwiftUI

struct MainView: View {
    @StateObject private var viewModel: MainViewModel

    private let backgroundAssetID: String
    private let backgroundArtworkAspectRatio: CGFloat

    init(
        viewModel: MainViewModel,
        backgroundAssetID: String = "main_forest_background",
        backgroundArtworkAspectRatio: CGFloat = 4.0 / 3.0
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.backgroundAssetID = backgroundAssetID
        self.backgroundArtworkAspectRatio = backgroundArtworkAspectRatio
    }

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width < proxy.size.height {
                PhoneMainHub(viewModel: viewModel)
            } else {
            VStack(spacing: 0) {
            GeometryReader { sceneProxy in
            let artworkSize = fittedArtworkSize(in: sceneProxy.size)
            ZStack {
                MainHubBackdrop(
                    assetID: backgroundAssetID,
                    artworkSize: artworkSize
                )

                MainHubScene(
                    size: artworkSize,
                    progressValue: viewModel.progressValue,
                    selectedClass: viewModel.selectedClass,
                    appearance: viewModel.appearance,
                    equippedItemIDs: viewModel.equippedItemIDs,
                    highlightsFoodLog: viewModel.profile?.onboarding.hasCompletedFirstFoodLog == false,
                    goBack: viewModel.goBack,
                    openRewards: viewModel.openRewards,
                    openSettings: viewModel.openSettings,
                    openMap: viewModel.openMap,
                    openQuests: viewModel.openQuests,
                    openFoodDiary: viewModel.openFoodLog,
                    openMiniGames: viewModel.openMiniGames,
                    openWardrobe: viewModel.openWardrobe
                )
                .frame(width: artworkSize.width, height: artworkSize.height)
            }
            .frame(width: sceneProxy.size.width, height: sceneProxy.size.height)
            }
                HStack {
                    Button("Sticker Album", systemImage: "star.square.fill", action: viewModel.openStickerAlbum)
                        .buttonStyle(.borderedProminent)
                        .tint(GameDesign.green)
                    MainGuidance(viewModel: viewModel)
                }.padding(.horizontal).padding(.vertical, 8)
            }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.load()
        }
        .overlay {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func fittedArtworkSize(in containerSize: CGSize) -> CGSize {
        guard containerSize.width > 0, containerSize.height > 0 else {
            return .zero
        }

        let containerAspectRatio = containerSize.width / containerSize.height
        if containerAspectRatio > backgroundArtworkAspectRatio {
            return CGSize(
                width: containerSize.height * backgroundArtworkAspectRatio,
                height: containerSize.height
            )
        }

        return CGSize(
            width: containerSize.width,
            height: containerSize.width / backgroundArtworkAspectRatio
        )
    }
}

private struct MainHubBackdrop: View {
    let assetID: String
    let artworkSize: CGSize

    var body: some View {
        ZStack {
            DesignImageView(assetID: assetID, contentMode: .fill) {
                Color(red: 0.45, green: 0.83, blue: 0.33)
            }
            .scaleEffect(1.12)
            .blur(radius: 24)
            .overlay(Color.green.opacity(0.08))

            DesignImageView(assetID: assetID, contentMode: .fit) {
                Color(red: 0.45, green: 0.83, blue: 0.33)
            }
            .frame(width: artworkSize.width, height: artworkSize.height)
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct MainHubScene: View {
    private enum Reference {
        static let size = CGSize(width: 2_048, height: 1_536)

        static let topButtonSize: CGFloat = 185
        static let menuButtonSize: CGFloat = 352
        static let progressSize = CGSize(width: 934, height: 560)
        static let heroSize = CGSize(width: 1_065, height: 1_120)

        static let backPosition = CGPoint(x: 148, y: 145)
        static let rewardsPosition = CGPoint(x: 400, y: 145)
        static let settingsPosition = CGPoint(x: 1_900, y: 145)
        static let progressPosition = CGPoint(x: 1_024, y: 342)
        static let heroPosition = CGPoint(x: 1_024, y: 952)
        static let mapPosition = CGPoint(x: 292, y: 630)
        static let questsPosition = CGPoint(x: 292, y: 1_105)
        static let foodDiaryPosition = CGPoint(x: 1_756, y: 630)
        static let miniGamesPosition = CGPoint(x: 1_756, y: 1_105)
        static let wardrobePosition = CGPoint(x: 1_430, y: 1_345)
    }

    let size: CGSize
    let progressValue: Double
    let selectedClass: CharacterClass?
    let appearance: CharacterAppearance
    let equippedItemIDs: [WardrobeItemID]
    let highlightsFoodLog: Bool
    let goBack: () -> Void
    let openRewards: () -> Void
    let openSettings: () -> Void
    let openMap: () -> Void
    let openQuests: () -> Void
    let openFoodDiary: () -> Void
    let openMiniGames: () -> Void
    let openWardrobe: () -> Void

    var body: some View {
        ZStack {
            MainProgressMeter(progress: progressValue)
                .frame(
                    width: scaled(Reference.progressSize.width),
                    height: scaled(Reference.progressSize.height)
                )
                .position(scaled(Reference.progressPosition))

            MainHeroArtwork(
                selectedClass: selectedClass,
                appearance: appearance,
                equippedItemIDs: equippedItemIDs
            )
            .frame(
                width: scaled(Reference.heroSize.width),
                height: scaled(Reference.heroSize.height)
            )
            .position(scaled(Reference.heroPosition))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Your hero")

            mainMenuButton(
                assetID: "menu_map",
                accessibilityLabel: "Map",
                action: openMap,
                position: Reference.mapPosition,
                referenceSize: Reference.menuButtonSize
            )

            mainMenuButton(
                assetID: "menu_quests",
                accessibilityLabel: "Quests",
                action: openQuests,
                position: Reference.questsPosition,
                referenceSize: Reference.menuButtonSize
            )

            mainMenuButton(
                assetID: "menu_food",
                accessibilityLabel: "Food diary",
                action: openFoodDiary,
                position: Reference.foodDiaryPosition,
                referenceSize: Reference.menuButtonSize
            )

            mainMenuButton(
                assetID: "menu_mini_games",
                accessibilityLabel: "Mini games",
                action: openMiniGames,
                position: Reference.miniGamesPosition,
                referenceSize: Reference.menuButtonSize
            )

            mainMenuButton(
                assetID: "back_button",
                accessibilityLabel: "Back",
                action: goBack,
                position: Reference.backPosition,
                referenceSize: Reference.topButtonSize
            )

            mainMenuButton(
                assetID: "menu_rewards",
                accessibilityLabel: "Rewards",
                action: openRewards,
                position: Reference.rewardsPosition,
                referenceSize: Reference.topButtonSize
            )

            mainMenuButton(
                assetID: "settings_button",
                accessibilityLabel: "Settings",
                action: openSettings,
                position: Reference.settingsPosition,
                referenceSize: Reference.topButtonSize
            )

            mainMenuButton(
                assetID: "menu_wardrobe",
                accessibilityLabel: "Customize hero",
                action: openWardrobe,
                position: Reference.wardrobePosition,
                referenceSize: Reference.topButtonSize
            )
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    private func mainMenuButton(
        assetID: String,
        accessibilityLabel: String,
        action: @escaping () -> Void,
        position: CGPoint,
        referenceSize: CGFloat
    ) -> some View {
        Button(action: action) {
            DesignImageView(assetID: assetID, contentMode: .fit) {
                RoundedRectangle(cornerRadius: scaled(28), style: .continuous)
                    .fill(GameDesign.cream.opacity(0.92))
            }
            .frame(width: scaled(referenceSize), height: scaled(referenceSize))
            .frame(minWidth: 44, minHeight: 44)
            .overlay {
                if assetID == "menu_food", highlightsFoodLog {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.yellow, lineWidth: 3)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(MainMenuButtonStyle())
        .position(scaled(position))
        .accessibilityLabel(accessibilityLabel)
    }

    private func scaled(_ referenceValue: CGFloat) -> CGFloat {
        referenceValue * scale
    }

    private func scaled(_ referencePoint: CGPoint) -> CGPoint {
        CGPoint(
            x: scaled(referencePoint.x),
            y: scaled(referencePoint.y)
        )
    }

    private var scale: CGFloat {
        min(
            size.width / Reference.size.width,
            size.height / Reference.size.height
        )
    }
}

private struct MainHeroArtwork: View {
    let selectedClass: CharacterClass?
    let appearance: CharacterAppearance
    let equippedItemIDs: [WardrobeItemID]

    var body: some View {
        HeroArtwork(
            appearance: appearance,
            equippedItemIDs: equippedItemIDs,
            selectedClass: selectedClass
        )
    }
}

private struct MainProgressMeter: View {
    let progress: Double

    private var clampedProgress: CGFloat {
        CGFloat(min(max(progress, 0), 1))
    }

    private var percentage: Int {
        Int((min(max(progress, 0), 1) * 100).rounded())
    }

    var body: some View {
        GeometryReader { proxy in
            let innerSize = CGSize(
                width: proxy.size.width * 884 / 934,
                height: proxy.size.height * 378 / 560
            )
            let innerCenter = CGPoint(
                x: proxy.size.width / 2,
                y: proxy.size.height * 350 / 560
            )

            ZStack(alignment: .top) {
                DesignImageView(assetID: "main_progress_status", contentMode: .fit) {
                    Color.clear
                }

                DesignImageView(assetID: "main_progress_empty", contentMode: .fit) {
                    Color.clear
                }
                .frame(width: innerSize.width, height: innerSize.height)
                .position(innerCenter)

                DesignImageView(assetID: "main_progress_full", contentMode: .fit) {
                    Color.clear
                }
                .frame(width: innerSize.width, height: innerSize.height)
                .mask(alignment: .leading) {
                    Rectangle()
                        .frame(width: innerSize.width * clampedProgress)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .position(innerCenter)

                Text("\(percentage)%")
                    .font(GameDesign.font(proxy.size.width * 0.096, weight: .black))
                    .foregroundStyle(GameDesign.green)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: proxy.size.width * 0.34)
                    .position(
                        x: proxy.size.width / 2,
                        y: proxy.size.height * 92 / 560
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hero progress")
        .accessibilityValue("\(percentage) percent")
        .allowsHitTesting(false)
    }
}

private struct MainMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct MainHubComingSoonView: View {
    let title: String
    let systemImage: String

    var body: some View {
        LandscapeGameScreen(
            title: title,
            backgroundAssetID: "main_forest_background",
            backgroundContentMode: .fit,
            fallbackColor: Color.green.opacity(0.12)
        ) { _ in
            GamePanel {
                GameEmptyStateView(
                    title: "Coming soon",
                    systemImage: systemImage,
                    message: "This part of Healthy Heroes is being prepared."
                )
            }
            .frame(maxWidth: 460, maxHeight: 220)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct PhoneMainHub: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    menuButton("menu_rewards", "Rewards", action: viewModel.openRewards).frame(width: 48)
                    menuButton("menu_wardrobe", "Wardrobe", action: viewModel.openWardrobe).frame(width: 48)
                    Spacer()
                    menuButton("menu_stickers", "Sticker Album", action: viewModel.openStickerAlbum).frame(width: 48)
                    menuButton("settings_button", "Settings", action: viewModel.openSettings).frame(width: 48)
                }
                .frame(height: 48)
                .padding(.top, UIDevice.current.userInterfaceIdiom == .pad ? 40 : 0)

                ZStack(alignment: .top) {
                    PhoneProgressMeter(progress: viewModel.progressValue)
                        .frame(width: min(proxy.size.width * 0.70, 300), height: min(proxy.size.height * 0.23, 170))
                        .zIndex(1)
                    HeroArtwork(
                        appearance: viewModel.appearance,
                        equippedItemIDs: viewModel.equippedItemIDs,
                        selectedClass: viewModel.selectedClass
                    )
                    .padding(.top, min(proxy.size.height * 0.17, 120))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Your hero")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(-1)

                MainGuidance(viewModel: viewModel)

                HStack(spacing: 6) {
                    menuButton("Phone_Food diary tab", "Food diary", action: viewModel.openFoodLog)
                        .overlay {
                            if viewModel.profile?.onboarding.hasCompletedFirstFoodLog == false {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(.yellow, lineWidth: 3)
                                    .allowsHitTesting(false)
                            }
                        }
                    menuButton("Phone_Quests tab", "Quests", action: viewModel.openQuests)
                    menuButton("Phone_Map tab", "Map", action: viewModel.openMap)
                    menuButton("Phone_Mini games tab", "Mini games", action: viewModel.openMiniGames)
                }
                .frame(height: max(54, min(90, (proxy.size.width - 18) / 4)))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                DesignImageView(assetID: "Phone_Forest-background", contentMode: .fill) { GameDesign.green }
                    .ignoresSafeArea()
            }
        }
    }

    private func menuButton(_ assetID: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            DesignImageView(assetID: assetID, contentMode: .fit) {
                Text(label).font(.caption).padding(4).background(GameDesign.cream)
            }
            .frame(minWidth: 44, maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(MainMenuButtonStyle())
        .accessibilityLabel(label)
    }
}

private struct PhoneProgressMeter: View {
    let progress: Double
    private var value: Double { min(max(progress, 0), 1) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                DesignImageView(assetID: "Phone_Empty Status bar", contentMode: .fit) { Color.clear }
                DesignImageView(assetID: "Phone_Full Status bar", contentMode: .fit) { Color.clear }
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: proxy.size.width * value)
                    }
                Text("\(Int((value * 100).rounded()))%")
                    .font(GameDesign.font(max(18, proxy.size.width * 0.09), weight: .black))
                    .foregroundStyle(GameDesign.green)
                    .padding(.top, 3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hero progress")
        .accessibilityValue("\(Int((value * 100).rounded())) percent")
        .allowsHitTesting(false)
    }
}

private struct MainGuidance: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        if let message = viewModel.firstSessionCTA {
            Button(action: viewModel.followFirstSessionCTA) {
                Label(message, systemImage: "sparkles")
                    .font(.callout.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(GameDesign.green)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(GameDesign.cream, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }
}
