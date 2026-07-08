import SwiftUI

struct RewardRevealView: View {
    @State private var reward: Reward?

    let rewardID: RewardID
    let openMysteryPackUseCase: any OpenMysteryPackUseCase
    let router: AppRouter

    var body: some View {
        LandscapeGameScreen(title: "Reward", fallbackColor: Color.green.opacity(0.1), showsBackButton: false) { size in
            GamePanel {
                HStack(spacing: 24) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: min(100, size.height * 0.24)))
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(reward?.title ?? "Reward")
                            .font(.title.bold())
                            .lineLimit(2)
                        Text(reward?.type.rawValue ?? rewardID)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Button("Close") {
                            router.dismissSheet()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: 420, alignment: .leading)
                }
            }
            .frame(maxWidth: min(680, size.width * 0.7), maxHeight: min(260, size.height * 0.58))
        }
        .task {
            reward = try? openMysteryPackUseCase.open(rewardID: rewardID)
        }
    }
}
