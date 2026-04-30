import SwiftUI

struct MainView: View {
    @StateObject private var viewModel: MainViewModel

    init(viewModel: MainViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeroSummaryCard(
                    title: viewModel.heroTitle,
                    xpText: viewModel.totalXPText,
                    mapText: viewModel.mapProgressText
                )

                if let firstSessionCTA = viewModel.firstSessionCTA {
                    FirstSessionCTA(title: firstSessionCTA, action: viewModel.openFoodLog)
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
            .padding(20)
        }
        .navigationTitle("Healthy Heroes")
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.largeTitle.bold())
            Text("Small choices move your hero forward.")
                .font(.body)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                StatPill(text: xpText, systemImage: "sparkles")
                StatPill(text: mapText, systemImage: "map")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.green.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
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
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 96)
        }
        .buttonStyle(.bordered)
    }
}
