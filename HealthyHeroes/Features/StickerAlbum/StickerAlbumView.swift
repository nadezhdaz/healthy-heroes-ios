import Combine
import SwiftUI

struct StickerAlbumView: View {
    @State private var stickerIDs: [StickerID] = []
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let eventBus: AppEventBus

    var body: some View {
        LandscapeGameScreen(
            title: "REWARDS",
            backgroundAssetID: "rewards_background",
            fallbackColor: Color.yellow.opacity(0.12),
            titleColor: GameDesign.purple
        ) { _ in
            GamePanel(alignment: .leading) {
                if stickerIDs.isEmpty {
                    GameEmptyStateView(
                        title: "No stickers yet",
                        systemImage: "star.square",
                        message: "Quest rewards can add stickers to this album."
                    )
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ],
                            spacing: 12
                        ) {
                            ForEach(stickerIDs, id: \.self) { stickerID in
                                StickerCard(stickerID: stickerID)
                            }
                        }
                    }
                }
            }
        }
        .task {
            await load()
        }
        .onAppear {
            cancellable = eventBus.events.sink { event in
                if case .profileUpdated = event {
                    Task { @MainActor in
                        await load()
                    }
                }
            }
        }
    }

    @MainActor
    private func load() async {
        stickerIDs = (try? await profileRepository.loadProfile()?.stickers.unlockedStickerIDs) ?? []
    }
}

private struct StickerCard: View {
    let stickerID: StickerID

    var body: some View {
        VStack(spacing: 10) {
            DesignImageView(assetID: stickerID, contentMode: .fit) {
                Image(systemName: "star.square.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.yellow)
            }
            .frame(width: 48, height: 48)

            Text(displayName)
                .font(GameDesign.font(13, weight: .bold))
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .padding(9)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var displayName: String {
        switch stickerID {
        case "sticker_star", "reward_star_sticker": "Shiny Star Sticker"
        case "sticker_apple": "Apple Sticker"
        default:
            stickerID
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }
}
