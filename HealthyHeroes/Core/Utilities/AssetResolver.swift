import SwiftUI
import UIKit

struct DesignAsset: Equatable {
    var resourceName: String
    var fileExtension: String = "png"
}

struct AssetResolver {
    func asset(for assetID: String) -> DesignAsset? {
        switch assetID {
        case "start_background":
            DesignAsset(resourceName: "Start-screen")
        case "start_logo":
            DesignAsset(resourceName: "Logo-Start-screen")
        case "logo":
            DesignAsset(resourceName: "logo-kid-nobackgrnd")
        case "main_forest_background":
            DesignAsset(resourceName: "Forest-background")
        case "food_log_background":
            DesignAsset(resourceName: "Food_log-background")
        case "map_background":
            DesignAsset(resourceName: "map-screen-clear")
        case "mystery_pack_closed":
            DesignAsset(resourceName: "Mystery-pack-closed")
        case "mystery_pack_background":
            DesignAsset(resourceName: "Rewards-Mystery-Pack-background")
        case "mystery_pack_half_opened":
            DesignAsset(resourceName: "Mystery-pack-Half-opened")
        case "mystery_pack_opened":
            DesignAsset(resourceName: "Mystery-pack-opened")
        case "class_knight":
            DesignAsset(resourceName: "Class_knight_icon")
        case "class_fairy":
            DesignAsset(resourceName: "Class_fairy_icon")
        case "class_wizard":
            DesignAsset(resourceName: "Class_wizard_icon")
        case "hero_body":
            DesignAsset(resourceName: "MAIN-bolvanka-ver3")
        case "hero_head_1":
            DesignAsset(resourceName: "Head-bolvanka-Orig")
        case "hero_head_2":
            DesignAsset(resourceName: "Head-bolvanka-2")
        case "hero_head_3":
            DesignAsset(resourceName: "Head-bolvanka-3")
        case "fruit_icon":
            DesignAsset(resourceName: "apple")
        case "vegetable_icon":
            DesignAsset(resourceName: "carrot")
        case "water_icon":
            DesignAsset(resourceName: "water-300")
        case "healthy_meal_icon":
            DesignAsset(resourceName: "chicken")
        case "reward_leaf_cape", "wardrobe_leaf_cape":
            DesignAsset(resourceName: "hat1")
        case "reward_star_sticker", "sticker_star":
            DesignAsset(resourceName: "Sticker_Apple")
        case "reward_explorer_badge", "class_explorer_badge":
            DesignAsset(resourceName: "Class_fairy_icon")
        default:
            nil
        }
    }

    func rewardImageName(for reward: Reward) -> String {
        reward.assetID
    }

    func uiImage(for assetID: String) -> UIImage? {
        guard let asset = asset(for: assetID),
              let path = Bundle.main.path(
                forResource: asset.resourceName,
                ofType: asset.fileExtension
              ) else {
            return nil
        }
        return UIImage(contentsOfFile: path)
    }
}

struct DesignImageView<Placeholder: View>: View {
    let assetID: String
    let contentMode: ContentMode
    @ViewBuilder var placeholder: () -> Placeholder

    private let resolver = AssetResolver()

    var body: some View {
        if let image = resolver.uiImage(for: assetID) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else {
            placeholder()
        }
    }
}
