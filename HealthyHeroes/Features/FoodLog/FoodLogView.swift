import SwiftUI

struct FoodLogView: View {
    @StateObject private var viewModel: FoodLogViewModel

    init(viewModel: FoodLogViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        LandscapeGameScreen(
            title: "Food Log",
            backgroundAssetID: "food_log_background",
            fallbackColor: Color.orange.opacity(0.1)
        ) { size in
            HStack(spacing: 18) {
                GamePanel(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Log healthy food")
                            .font(.title2.bold())
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                        Text("One tap gives progress.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)

                        if let result = viewModel.lastResult {
                            ResultSummary(result: result)
                                .frame(maxHeight: 128)
                        } else {
                            Spacer(minLength: 0)
                            Image(systemName: "fork.knife")
                                .font(.system(size: min(72, size.height * 0.16), weight: .semibold))
                                .foregroundStyle(.green.opacity(0.72))
                                .frame(maxWidth: .infinity)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(width: min(260, size.width * 0.28))

                HStack(spacing: 12) {
                    ForEach(viewModel.categories) { category in
                        Button {
                            viewModel.log(category)
                        } label: {
            FoodCategoryTile(
                title: category.title,
                assetID: assetID(for: category),
                iconName: iconName(for: category)
            )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isLogging)
                    }
                }
            }
            .frame(maxHeight: min(210, size.height * 0.52))
        }
        .overlay(alignment: .bottom) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
            }
        }
    }

    private func iconName(for category: FoodCategory) -> String {
        switch category {
        case .fruit:
            "apple.logo"
        case .vegetable:
            "leaf.fill"
        case .water:
            "drop.fill"
        case .healthyMeal:
            "fork.knife"
        case .custom:
            "plus.circle"
        }
    }

    private func assetID(for category: FoodCategory) -> String {
        switch category {
        case .fruit:
            "fruit_icon"
        case .vegetable:
            "vegetable_icon"
        case .water:
            "water_icon"
        case .healthyMeal:
            "healthy_meal_icon"
        case .custom:
            "healthy_meal_icon"
        }
    }
}

private struct FoodCategoryTile: View {
    let title: String
    let assetID: String
    let iconName: String

    var body: some View {
        GamePanel {
            VStack(spacing: 8) {
                DesignImageView(assetID: assetID, contentMode: .fit) {
                    Image(systemName: iconName)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.green)
                }
                .frame(width: 42, height: 42)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(minWidth: 106, maxHeight: 156)
    }
}

private struct ResultSummary: View {
    let result: LogFoodResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("+\(result.smallProgressAwarded + result.bigProgressAwarded) XP")
                .font(.title3.bold())
            if result.didAdvanceOnMap {
                Label("Hero advanced on the map", systemImage: "map")
            }
            if !result.completedQuestIDs.isEmpty {
                Label("Quest completed", systemImage: "checkmark.seal.fill")
            }
            if !result.unlockedRewardIDs.isEmpty {
                Label("Reward unlocked", systemImage: "gift.fill")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blue.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
