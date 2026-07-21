import SwiftUI

struct MysteryPackView: View {
    @State private var state: MysteryPackState = .closed
    @State private var errorMessage: String?

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
                HStack(spacing: 24) {
                    DesignImageView(assetID: imageAssetID, contentMode: .fit) {
                        Image(systemName: imageName)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.green)
                    }
                    .frame(width: min(210, size.width * 0.26), height: min(210, size.height * 0.52))

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

                            if let reward = revealedReward, reward.type == .wardrobeItem {
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
            }
            .frame(maxWidth: min(760, size.width * 0.74), maxHeight: min(320, size.height * 0.72))
        }
        .onAppear {
            if case .closed = state {
                state = .opening(step: 0)
            }
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
            "Finish"
        case .finished:
            "Close"
        }
    }

    private func advance() async {
        switch state {
        case .closed:
            state = .opening(step: 0)
        case let .opening(step):
            if step < 1 {
                state = .opening(step: step + 1)
            } else {
                await revealFirstReward()
            }
        case .revealed:
            state = .finished
        case .finished:
            router.dismissSheet()
        }
    }

    private func revealFirstReward() async {
        guard let rewardID = rewardIDs.first,
              let reward = try? openMysteryPackUseCase.open(rewardID: rewardID) else {
            state = .finished
            return
        }

        if let profile = try? await markRewardOpenedUseCase.markOpened(rewardID: rewardID) {
            eventBus.post(.profileUpdated(profile))
            eventBus.post(.firstSessionProgressUpdated(profile.onboarding))
        }

        state = .revealed(reward)
    }

    private func equipReward(_ reward: Reward) async {
        do {
            let profile = try await equipItemUseCase.equip(itemID: reward.id)
            eventBus.post(.itemEquipped(reward.id))
            eventBus.post(.profileUpdated(profile))
            eventBus.post(.firstSessionProgressUpdated(profile.onboarding))
            state = .finished
        } catch {
            errorMessage = "Could not try on this reward."
        }
    }
}
