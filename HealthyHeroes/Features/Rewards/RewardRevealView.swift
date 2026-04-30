import SwiftUI

struct RewardRevealView: View {
    @State private var reward: Reward?

    let rewardID: RewardID
    let openMysteryPackUseCase: any OpenMysteryPackUseCase
    let router: AppRouter

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gift.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text(reward?.title ?? "Reward")
                .font(.title.bold())
            Text(reward?.type.rawValue ?? rewardID)
                .foregroundStyle(.secondary)
            Button("Close") {
                router.dismissSheet()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .task {
            reward = try? openMysteryPackUseCase.open(rewardID: rewardID)
        }
    }
}
