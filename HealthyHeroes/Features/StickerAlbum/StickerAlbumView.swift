import Combine
import SwiftUI

struct StickerAlbumView: View {
    @State private var stickerIDs: [StickerID] = []
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let eventBus: AppEventBus

    var body: some View {
        LandscapeGameScreen(title: "Sticker Album", fallbackColor: Color.yellow.opacity(0.12)) { _ in
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
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
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
            load()
        }
        .onAppear {
            cancellable = eventBus.events.sink { event in
                if case .profileUpdated = event {
                    load()
                }
            }
        }
    }

    private func load() {
        stickerIDs = (try? profileRepository.loadProfile()?.stickers.unlockedStickerIDs) ?? []
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
            .frame(width: 58, height: 58)

            Text(stickerID)
                .font(.headline)
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 126)
        .padding(12)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
