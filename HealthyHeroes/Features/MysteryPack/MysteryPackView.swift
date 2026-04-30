import SwiftUI

struct MysteryPackView: View {
    @State private var state: MysteryPackState = .closed

    let rewardIDs: [RewardID]
    let openMysteryPackUseCase: any OpenMysteryPackUseCase
    let profileRepository: any ProfileRepository
    let eventBus: AppEventBus
    let router: AppRouter

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: imageName)
                .font(.system(size: 88))
                .foregroundStyle(.green)
            Text(title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text(subtitle)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button(buttonTitle, action: advance)
                .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .navigationTitle("Mystery Pack")
        .onAppear {
            if case .closed = state {
                state = .opening(step: 0)
            }
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
        case let .revealed(reward):
            "Type: \(reward.type.rawValue)"
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

    private func advance() {
        switch state {
        case .closed:
            state = .opening(step: 0)
        case let .opening(step):
            if step < 1 {
                state = .opening(step: step + 1)
            } else {
                revealFirstReward()
            }
        case .revealed:
            state = .finished
        case .finished:
            router.dismissSheet()
        }
    }

    private func revealFirstReward() {
        guard let rewardID = rewardIDs.first,
              let reward = try? openMysteryPackUseCase.open(rewardID: rewardID) else {
            state = .finished
            return
        }

        if var profile = try? profileRepository.loadProfile() {
            profile.onboarding.hasOpenedFirstReward = true
            profile.onboarding.isFirstSessionCompleted = profile.onboarding.hasCompletedFirstFoodLog
                && profile.onboarding.hasCompletedFirstQuest
                && profile.onboarding.hasOpenedFirstReward
            try? profileRepository.saveProfile(profile)
            eventBus.post(.profileUpdated(profile))
            eventBus.post(.firstSessionProgressUpdated(profile.onboarding))
        }

        state = .revealed(reward)
    }
}
