import ImageIO
import SwiftUI
import UIKit

struct DesignAsset: Equatable {
    var resourceName: String
    var fileExtension: String = "png"
    var maxPixelSize: Int = 1_024
}

struct AssetResolver {
    private let imageLoader = DesignImageLoader.shared

    func asset(for assetID: String) -> DesignAsset? {
        switch assetID {
        case "start_background":
            DesignAsset(resourceName: "Start-screen", maxPixelSize: 2_048)
        case "back_button":
            DesignAsset(resourceName: "Back")
        case "settings_button":
            DesignAsset(resourceName: "Settings")
        case "start_logo":
            DesignAsset(resourceName: "Logo-Start-screen")
        case "logo":
            DesignAsset(resourceName: "logo-kid-nobackgrnd")
        case "main_forest_background":
            DesignAsset(resourceName: "Forest-background", maxPixelSize: 2_048)
        case "rewards_background":
            DesignAsset(resourceName: "Rewards-background", maxPixelSize: 2_048)
        case "wardrobe_background":
            DesignAsset(resourceName: "customize-background", maxPixelSize: 2_048)
        case "menu_food":
            DesignAsset(resourceName: "Food diary tab")
        case "menu_quests":
            DesignAsset(resourceName: "Quests tab")
        case "menu_map":
            DesignAsset(resourceName: "Map tab")
        case "menu_rewards":
            DesignAsset(resourceName: "Rewards")
        case "menu_wardrobe":
            DesignAsset(resourceName: "Customize")
        case "menu_stickers":
            DesignAsset(resourceName: "Stickers_Log")
        case "food_log_background":
            DesignAsset(resourceName: "Food_log-background", maxPixelSize: 2_048)
        case "map_background":
            DesignAsset(resourceName: "map-screen", maxPixelSize: 2_048)
        case "mystery_pack_closed":
            DesignAsset(resourceName: "Mystery-pack-closed")
        case "mystery_pack_background":
            DesignAsset(resourceName: "Rewards-Mystery-Pack-background", maxPixelSize: 2_048)
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
        case "food_diary_field":
            DesignAsset(resourceName: "Food Diary_Field background", maxPixelSize: 2_048)
        case "food_card_misc": DesignAsset(resourceName: "Card_Misc")
        case "food_card_water200": DesignAsset(resourceName: "Card_Water200")
        case "food_card_water300": DesignAsset(resourceName: "Card_Water300")
        case "food_card_water500": DesignAsset(resourceName: "Card_Water500")
        case "food_card_grape": DesignAsset(resourceName: "Card_Grape")
        case "food_card_orange": DesignAsset(resourceName: "Card_Orange")
        case "food_card_broccoli": DesignAsset(resourceName: "Card_Broccoli")
        case "food_card_beans": DesignAsset(resourceName: "Card_Beans")
        case "food_card_banana": DesignAsset(resourceName: "Card_Banana")
        case "food_card_tomato": DesignAsset(resourceName: "Card_Tomato")
        case "food_card_strawberry": DesignAsset(resourceName: "Card_Strawberry")
        case "food_card_peas": DesignAsset(resourceName: "catg_Peas")
        case "food_card_carrot": DesignAsset(resourceName: "Card_Carrot")
        case "food_card_eggs": DesignAsset(resourceName: "Card_Eggs")
        case "food_card_cucumber": DesignAsset(resourceName: "Card_Cucumber")
        case "food_card_chicken": DesignAsset(resourceName: "Card_Chicken")
        case "food_card_cheese": DesignAsset(resourceName: "Card_Cheese")
        case "food_card_apple": DesignAsset(resourceName: "Card_Apple")
        case "quests_background":
            DesignAsset(resourceName: "Quests-background", maxPixelSize: 2_048)
        case "quest_icon_fruit":
            DesignAsset(resourceName: "Icon_Eat a fruit")
        case "quest_icon_vegetable":
            DesignAsset(resourceName: "Icon_Eat a veg")
        case "quest_icon_water":
            DesignAsset(resourceName: "Dring water")
        case "quest_icon_meal":
            DesignAsset(resourceName: "Log 3 meals")
        case "quest_icon_five_day":
            DesignAsset(resourceName: "Icon_5 day")
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

    func uiImage(for assetID: String) async -> UIImage? {
        guard let asset = asset(for: assetID) else { return nil }
        return await imageLoader.image(for: asset)
    }
}

private actor DesignImageLoader {
    static let shared = DesignImageLoader()

    private let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 64
        cache.totalCostLimit = 64 * 1_024 * 1_024
        return cache
    }()

    func image(for asset: DesignAsset) -> UIImage? {
        let cacheKey = "\(asset.resourceName).\(asset.fileExtension)-\(asset.maxPixelSize)" as NSString
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        guard let url = Bundle.main.url(
            forResource: asset.resourceName,
            withExtension: asset.fileExtension
        ) else {
            return nil
        }

        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            return nil
        }

        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: asset.maxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
            return nil
        }

        let image = UIImage(cgImage: cgImage)
        cache.setObject(
            image,
            forKey: cacheKey,
            cost: cgImage.bytesPerRow * cgImage.height
        )
        return image
    }
}

struct DesignImageView<Placeholder: View>: View {
    let assetID: String
    let contentMode: ContentMode
    @ViewBuilder var placeholder: () -> Placeholder

    @State private var image: UIImage?
    private let resolver = AssetResolver()

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
            }
        }
        .task(id: assetID) {
            image = nil
            image = await resolver.uiImage(for: assetID)
        }
    }
}
