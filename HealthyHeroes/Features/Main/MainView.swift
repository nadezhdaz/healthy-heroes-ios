import SwiftUI

struct MainView: View {
    @StateObject private var viewModel: MainViewModel

    init(viewModel: MainViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        LandscapeGameScreen(
            backgroundAssetID: "main_forest_background",
            fallbackColor: Color.green.opacity(0.12),
            showsBackButton: false
        ) { size in
            VStack(spacing: 12) {
                HeroSummaryCard(
                    title: viewModel.heroTitle,
                    xpText: viewModel.totalXPText,
                    mapText: viewModel.mapProgressText,
                    progressValue: viewModel.progressValue,
                    appearance: viewModel.appearance,
                    equippedItemIDs: viewModel.equippedItemIDs
                )
                .frame(height: min(142, size.height * 0.31))

                VStack(spacing: 10) {
                    if let firstSessionCTA = viewModel.firstSessionCTA {
                        FirstSessionCTA(
                            title: firstSessionCTA,
                            action: viewModel.followFirstSessionCTA
                        )
                        .frame(height: 48)
                    }

                    MainActionGrid(
                        hasUnlockedRewards: viewModel.hasUnlockedRewards,
                        openFoodLog: viewModel.openFoodLog,
                        openQuests: viewModel.openQuests,
                        openMap: viewModel.openMap,
                        openRewards: viewModel.openRewards,
                        openWardrobe: viewModel.openWardrobe,
                        openStickerAlbum: viewModel.openStickerAlbum
                    )
                }
                .frame(maxHeight: .infinity)
            }
        }
        .task {
            viewModel.load()
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
}

private struct HeroSummaryCard: View {
    let title: String
    let xpText: String
    let mapText: String
    let progressValue: Double
    let appearance: CharacterAppearance
    let equippedItemIDs: [WardrobeItemID]

    var body: some View {
        GamePanel(alignment: .leading) {
            HStack(alignment: .center, spacing: 16) {
                HeroPreview(appearance: appearance, equippedItemIDs: equippedItemIDs)
                    .frame(width: 112, height: 116)

                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(GameDesign.font(28, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text("Feed your hero to move forward.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        StatPill(text: xpText, systemImage: "sparkles")
                        StatPill(text: mapText, systemImage: "map")
                    }
                    ProgressView(value: progressValue, total: 1)
                        .tint(.green)
                }
            }
        }
    }
}

private struct StatPill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct FirstSessionCTA: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .imageScale(.large)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }
}

private struct MainActionGrid: View {
    let hasUnlockedRewards: Bool
    let openFoodLog: () -> Void
    let openQuests: () -> Void
    let openMap: () -> Void
    let openRewards: () -> Void
    let openWardrobe: () -> Void
    let openStickerAlbum: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            MainActionButton(title: "Food Log", systemImage: "plus.circle.fill", action: openFoodLog)
            MainActionButton(title: "Quests", systemImage: "checklist", action: openQuests)
            MainActionButton(title: "Map", systemImage: "map.fill", action: openMap)
            MainActionButton(
                title: hasUnlockedRewards ? "Rewards" : "Rewards",
                systemImage: "gift.fill",
                action: openRewards
            )
            MainActionButton(title: "Wardrobe", systemImage: "tshirt.fill", action: openWardrobe)
            MainActionButton(title: "Stickers", systemImage: "star.square.fill", action: openStickerAlbum)
        }
    }
}

private struct MainActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                DesignImageView(assetID: assetID(for: title), contentMode: .fit) {
                    Image(systemName: systemImage)
                        .font(.title3)
                }
                .frame(width: 58, height: 42)
                Text(title)
                    .font(GameDesign.font(13, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 92)
            .padding(.vertical, 8)
            .background(GameDesign.cream.opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: GameDesign.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.14), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func assetID(for title: String) -> String {
        switch title {
        case "Food Log": return "menu_food"
        case "Quests": return "menu_quests"
        case "Map": return "menu_map"
        case "Rewards": return "menu_rewards"
        case "Wardrobe": return "menu_wardrobe"
        case "Stickers": return "menu_stickers"
        default: return ""
        }
    }
}
