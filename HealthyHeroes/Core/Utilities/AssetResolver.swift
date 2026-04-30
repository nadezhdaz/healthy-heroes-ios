import Foundation

struct AssetResolver {
    func imageName(for assetID: String) -> String {
        assetID
    }

    func rewardImageName(for reward: Reward) -> String {
        imageName(for: reward.assetID)
    }
}
