import SwiftUI

struct StickerAlbumView: View {
    @State private var stickerIDs: [StickerID] = []
    @State private var catalog: [StickerDefinition] = []
    @State private var errorMessage: String?

    let profileRepository: any ProfileRepository
    let eventBus: AppEventBus

    var body: some View {
        LandscapeGameScreen(title: "STICKER ALBUM", backgroundAssetID: "rewards_background") { _ in
            ScrollView {
                VStack(spacing: 16) {
                    Text("\(stickerIDs.count) of \(catalog.count) collected")
                        .font(GameDesign.font(20, weight: .bold))
                    if let errorMessage {
                        Text(errorMessage)
                        Button("Retry") { Task { await load() } }
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                        ForEach(catalog) { sticker in
                            let unlocked = stickerIDs.contains(sticker.id)
                            VStack(spacing: 12) {
                                DesignImageView(assetID: sticker.assetID, contentMode: .fit) {
                                    Image(systemName: "star.fill").resizable().scaledToFit()
                                }
                                .frame(height: 84)
                                .grayscale(unlocked ? 0 : 1)
                                .opacity(unlocked ? 1 : 0.25)
                                Text(sticker.title).font(.headline)
                                Label(unlocked ? "Collected" : "Locked", systemImage: unlocked ? "checkmark.circle.fill" : "lock.fill")
                                    .font(.caption)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, minHeight: 190)
                            .background(GameDesign.cream, in: RoundedRectangle(cornerRadius: 20))
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
        .task { await load() }
        .onReceive(eventBus.events) { event in
            if case .profileUpdated = event { Task { await load() } }
        }
    }

    @MainActor
    private func load() async {
        do {
            catalog = try BundledConfigLoader().decode([StickerDefinition].self, fileName: "stickers")
            stickerIDs = try await profileRepository.loadProfile()?.stickers.unlockedStickerIDs ?? []
            errorMessage = nil
        } catch {
            errorMessage = "Could not load your stickers. Please try again."
        }
    }
}
