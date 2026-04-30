import Combine
import SwiftUI

struct StickerAlbumView: View {
    @State private var stickerIDs: [StickerID] = []
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let eventBus: AppEventBus

    var body: some View {
        List(stickerIDs, id: \.self) { stickerID in
            Label(stickerID, systemImage: "star.square.fill")
        }
        .overlay {
            if stickerIDs.isEmpty {
                StickerAlbumEmptyStateView()
            }
        }
        .navigationTitle("Sticker Album")
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

private struct StickerAlbumEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.square")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No stickers yet")
                .font(.headline)
            Text("Quest rewards can add stickers to this album.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}
