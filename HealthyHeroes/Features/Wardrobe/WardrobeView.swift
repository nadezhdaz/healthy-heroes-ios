import SwiftUI

struct WardrobeView: View {
    @State private var profile: ChildProfile?
    @State private var catalog: [WardrobeItemDefinition] = []
    @State private var selectedCategory: WardrobeCategory = .head
    @State private var errorMessage: String?
    @State private var isEquipping = false

    let profileRepository: any ProfileRepository
    let equipItemUseCase: any EquipItemUseCase
    let eventBus: AppEventBus

    var body: some View {
        LandscapeGameScreen(title: "Wardrobe", backgroundAssetID: "wardrobe_background") { size in
            let portrait = size.width < 600
            let layout = portrait ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 18))
            layout {
                HeroArtwork(
                    appearance: profile?.character.appearance ?? CharacterAppearance(),
                    equippedItemIDs: profile?.wardrobe.equippedItemIDs ?? [],
                    selectedClass: profile?.character.selectedClass
                )
                .frame(width: portrait ? size.width : size.width * 0.42)
                .frame(height: portrait ? min(230, size.height * 0.35) : nil)
                .accessibilityLabel("Your equipped hero")

                VStack(spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(WardrobeCategory.allCases) { category in
                                Button { selectedCategory = category } label: {
                                    Text(category.rawValue)
                                        .frame(minWidth: 44, minHeight: 44)
                                        .contentShape(Rectangle())
                                }
                                    .buttonStyle(.borderedProminent)
                                    .tint(category == selectedCategory ? GameDesign.green : .gray)
                                    .accessibilityAddTraits(category == selectedCategory ? .isSelected : [])
                            }
                        }
                    }
                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                        Button("Retry") { Task { await load() } }
                    }
                    ScrollView {
                        let items = catalog.filter { ($0.category ?? .accessories) == selectedCategory }
                        if items.isEmpty {
                            Text("Your starter outfit is ready. New rewards will appear here.")
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(GameDesign.cream, in: RoundedRectangle(cornerRadius: 14))
                        }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
                            ForEach(items) { item in
                                itemButton(item)
                            }
                        }
                    }
                }
            }
        }
        .task { await load() }
        .onReceive(eventBus.events) { event in
            if case let .profileUpdated(updatedProfile) = event { profile = updatedProfile }
        }
    }

    private func itemButton(_ item: WardrobeItemDefinition) -> some View {
        let unlocked = profile?.wardrobe.unlockedItemIDs.contains(item.id) == true
        let equipped = profile?.wardrobe.equippedItemIDs.contains(item.id) == true
        return Button { Task { await equip(item.id) } } label: {
            VStack(spacing: 10) {
                DesignImageView(assetID: item.assetID, contentMode: .fit) {
                    Image(systemName: "tshirt.fill").resizable().scaledToFit()
                }
                .frame(height: 76)
                .opacity(unlocked ? 1 : 0.35)
                Text(item.title).font(.headline)
                Label(equipped ? "Equipped" : unlocked ? "Try On" : "Locked", systemImage: equipped ? "checkmark.circle.fill" : unlocked ? "plus.circle" : "lock.fill")
                    .font(.caption.bold())
            }
            .foregroundStyle(GameDesign.green)
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 170)
            .background(GameDesign.cream, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(GameImageButtonStyle())
        .disabled(!unlocked || equipped || isEquipping)
        .accessibilityElement(children: .combine)
    }

    @MainActor
    private func load() async {
        do {
            catalog = try BundledConfigLoader().decode([WardrobeItemDefinition].self, fileName: "wardrobe_items")
            profile = try await profileRepository.loadProfile()
            errorMessage = nil
        } catch {
            errorMessage = "Could not load your wardrobe. Please try again."
        }
    }

    @MainActor
    private func equip(_ itemID: WardrobeItemID) async {
        guard !isEquipping,
              profile?.wardrobe.equippedItemIDs.contains(itemID) != true else { return }
        isEquipping = true
        defer { isEquipping = false }
        do {
            let updated = try await equipItemUseCase.equip(itemID: itemID)
            profile = updated
            errorMessage = nil
            eventBus.post(.rewardEquipped(itemID))
            eventBus.post(.itemEquipped(itemID))
            eventBus.post(.profileUpdated(updated))
            eventBus.post(.firstSessionProgressUpdated(updated.onboarding))
        } catch {
            errorMessage = "Could not equip this item. Please try again."
        }
    }
}
