import Combine
import SwiftUI

struct WardrobeView: View {
    @State private var itemIDs: [WardrobeItemID] = []
    @State private var equippedItemIDs: [WardrobeItemID] = []
    @State private var appearance = CharacterAppearance()
    @State private var errorMessage: String?
    @State private var cancellable: AnyCancellable?

    let profileRepository: any ProfileRepository
    let equipItemUseCase: any EquipItemUseCase
    let eventBus: AppEventBus

    var body: some View {
        LandscapeGameScreen(title: "Wardrobe", fallbackColor: Color.green.opacity(0.08)) { size in
            HStack(spacing: 18) {
                GamePanel {
                    HeroPreview(appearance: appearance, equippedItemIDs: equippedItemIDs)
                        .frame(width: min(270, size.width * 0.3), height: min(300, size.height * 0.68))
                }
                .frame(width: min(360, size.width * 0.38))

                GamePanel(alignment: .leading) {
                    if itemIDs.isEmpty {
                        GameEmptyStateView(
                            title: "Wardrobe is empty",
                            systemImage: "tshirt",
                            message: "Unlocked reward items will appear here."
                        )
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ],
                                spacing: 12
                            ) {
                                ForEach(itemIDs, id: \.self) { itemID in
                                    WardrobeItemCard(
                                        title: displayTitle(for: itemID),
                                        itemID: itemID,
                                        isEquipped: equippedItemIDs.contains(itemID)
                                    ) {
                                        equip(itemID)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
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
        guard let profile = try? profileRepository.loadProfile() else {
            itemIDs = []
            equippedItemIDs = []
            return
        }
        itemIDs = profile.wardrobe.unlockedItemIDs
        equippedItemIDs = profile.wardrobe.equippedItemIDs
        appearance = profile.character.appearance
    }

    private func equip(_ itemID: WardrobeItemID) {
        do {
            let profile = try equipItemUseCase.equip(itemID: itemID)
            itemIDs = profile.wardrobe.unlockedItemIDs
            equippedItemIDs = profile.wardrobe.equippedItemIDs
            appearance = profile.character.appearance
            errorMessage = nil
            eventBus.post(.itemEquipped(itemID))
            eventBus.post(.profileUpdated(profile))
            eventBus.post(.firstSessionProgressUpdated(profile.onboarding))
        } catch {
            errorMessage = "This item is still locked."
        }
    }

    private func displayTitle(for itemID: WardrobeItemID) -> String {
        switch itemID {
        case "wardrobe_leaf_cape":
            "Leaf Cape"
        default:
            itemID
        }
    }
}

private struct WardrobeItemCard: View {
    let title: String
    let itemID: WardrobeItemID
    let isEquipped: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                DesignImageView(assetID: itemID, contentMode: .fit) {
                    Image(systemName: "tshirt.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.green)
                }
                .frame(width: 58, height: 58)

                Text(title)
                    .font(.headline)
                    .lineLimit(1)

                Label(
                    isEquipped ? "Equipped" : "Try On",
                    systemImage: isEquipped ? "checkmark.circle.fill" : "plus.circle"
                )
                .font(.caption.bold())
                .foregroundStyle(isEquipped ? Color.green : Color.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 144)
            .padding(12)
            .background(Color.white.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
