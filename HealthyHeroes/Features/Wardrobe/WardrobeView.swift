import Combine
import SwiftUI

struct WardrobeView: View {
    @State private var itemIDs: [WardrobeItemID] = []
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let eventBus: AppEventBus

    var body: some View {
        List(itemIDs, id: \.self) { itemID in
            Label(itemID, systemImage: "tshirt.fill")
        }
        .overlay {
            if itemIDs.isEmpty {
                WardrobeEmptyStateView()
            }
        }
        .navigationTitle("Wardrobe")
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
        itemIDs = (try? profileRepository.loadProfile()?.wardrobe.unlockedItemIDs) ?? []
    }
}

private struct WardrobeEmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tshirt")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Wardrobe is empty")
                .font(.headline)
            Text("Unlocked reward items will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}
