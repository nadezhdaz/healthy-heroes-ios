import SwiftUI

struct MysteryPackView: View {
    @State private var state: MysteryPackState = .closed
    @State private var errorMessage: String?
    @State private var rewardIndex = 0
    @State private var isSaving = false
    @State private var isEquipped = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let rewardIDs: [RewardID]
    let openMysteryPackUseCase: any OpenMysteryPackUseCase
    let markRewardOpenedUseCase: any MarkRewardOpenedUseCase
    let equipItemUseCase: any EquipItemUseCase
    let profileRepository: any ProfileRepository
    let eventBus: AppEventBus
    let router: AppRouter

    var body: some View {
        LandscapeGameScreen(
            title: "Mystery Pack",
            backgroundAssetID: "mystery_pack_background",
            fallbackColor: Color.green.opacity(0.12)
        ) { size in
            GamePanel {
                (size.width < 600 ? AnyLayout(VStackLayout(spacing: 16)) : AnyLayout(HStackLayout(spacing: 24))) {
                    DesignImageView(assetID: revealedReward?.assetID ?? imageAssetID, contentMode: .fit) {
                        Image(systemName: imageName)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.green)
                    }
                    .frame(width: min(210, size.width * 0.60), height: min(210, size.height * 0.36))

                    VStack(alignment: .leading, spacing: 14) {
                        Text(title)
                            .font(.title.bold())
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                        Text(subtitle)
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Button(buttonTitle) {
                                Task {
                                    await advance()
                                }
                            }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)

                            if let reward = revealedReward, reward.type == .wardrobeItem, !isEquipped {
                                Button("Try On") {
                                    Task {
                                        await equipReward(reward)
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.callout)
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: 420, alignment: .leading)
                }
                .disabled(isSaving)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: imageAssetID)
            }
            .frame(maxWidth: min(760, size.width), maxHeight: size.width < 600 ? min(560, size.height) : min(350, size.height))
        }
        .task(id: rewardIndex) {
            await loadCurrentReward()
        }
    }

    private var revealedReward: Reward? {
        if case let .revealed(reward) = state {
            reward
        } else {
            nil
        }
    }

    private var imageName: String {
        switch state {
        case .closed, .opening:
            "shippingbox.fill"
        case .revealed:
            "gift.fill"
        case .finished:
            "checkmark.seal.fill"
        }
    }

    private var imageAssetID: String {
        switch state {
        case .closed:
            "mystery_pack_closed"
        case let .opening(step):
            step < 1 ? "mystery_pack_closed" : "mystery_pack_half_opened"
        case .revealed, .finished:
            "mystery_pack_opened"
        }
    }

    private var title: String {
        switch state {
        case .closed:
            "Mystery Pack"
        case let .opening(step):
            step < 1 ? "Opening..." : "Almost there..."
        case let .revealed(reward):
            reward.title
        case .finished:
            "Reward added"
        }
    }

    private var subtitle: String {
        switch state {
        case .closed, .opening:
            "A completed quest unlocked a reward."
        case .revealed:
            "Added to your collection."
        case .finished:
            "You can find unlocked items in rewards or wardrobe."
        }
    }

    private var buttonTitle: String {
        switch state {
        case .closed, .opening:
            "Reveal"
        case .revealed:
            rewardIndex + 1 < rewardIDs.count ? "Next reward" : "Finish"
        case .finished:
            "Close"
        }
    }

    private func advance() async {
        guard !isSaving else { return }
        switch state {
        case .closed:
            state = .opening(step: 0)
        case let .opening(step):
            if step < 1 {
                state = .opening(step: step + 1)
            } else {
                await revealReward()
            }
        case .revealed:
            finishCurrentReward()
        case .finished:
            dismiss()
        }
    }

    private func finishCurrentReward() {
        if rewardIndex + 1 < rewardIDs.count {
            rewardIndex += 1
            state = .closed
            isEquipped = false
            errorMessage = nil
        } else {
            state = .finished
        }
    }

    private func revealReward() async {
        guard rewardIDs.indices.contains(rewardIndex), !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let rewardID = rewardIDs[rewardIndex]
            guard let reward = try openMysteryPackUseCase.open(rewardID: rewardID) else {
                errorMessage = "This reward could not be loaded. Please try again."
                return
            }
            let profile = try await markRewardOpenedUseCase.markOpened(rewardID: rewardID)
            isEquipped = profile.wardrobe.equippedItemIDs.contains(rewardID)
            eventBus.post(.rewardOpened(rewardID))
            eventBus.post(.profileUpdated(profile))
            eventBus.post(.firstSessionProgressUpdated(profile.onboarding))
            errorMessage = nil
            state = .revealed(reward)
        } catch {
            errorMessage = "Could not save this reward. Tap Reveal to try again."
        }
    }

    private func loadCurrentReward() async {
        guard rewardIDs.indices.contains(rewardIndex) else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let rewardID = rewardIDs[rewardIndex]
            let profile = try await profileRepository.loadProfile()
            isEquipped = profile?.wardrobe.equippedItemIDs.contains(rewardID) == true
            if profile?.openedRewardIDs?.contains(rewardID) == true,
               let reward = try openMysteryPackUseCase.open(rewardID: rewardID) {
                state = .revealed(reward)
            } else {
                state = .closed
            }
            errorMessage = nil
        } catch {
            errorMessage = "Could not load this gift. Close and try again."
        }
    }

    private func equipReward(_ reward: Reward) async {
        guard !isSaving, !isEquipped else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let profile = try await equipItemUseCase.equip(itemID: reward.id)
            isEquipped = true
            eventBus.post(.rewardEquipped(reward.id))
            eventBus.post(.itemEquipped(reward.id))
            eventBus.post(.profileUpdated(profile))
            eventBus.post(.firstSessionProgressUpdated(profile.onboarding))
            finishCurrentReward()
        } catch {
            errorMessage = "Could not try on this reward."
        }
    }
}
