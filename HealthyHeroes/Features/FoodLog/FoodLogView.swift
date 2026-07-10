import SwiftUI

struct FoodLogView: View {
    @StateObject private var viewModel: FoodLogViewModel
    @State private var selectedTab: FoodTab = .all
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    init(viewModel: FoodLogViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var visibleFoods: [FoodChoice] {
        FoodChoice.catalog.filter { choice in
            (selectedTab == .all || choice.tab == selectedTab) &&
            (searchText.isEmpty || choice.title.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        LandscapeGameScreen(
            backgroundAssetID: "food_log_background",
            fallbackColor: Color(red: 0.78, green: 0.94, blue: 0.25),
            showsBackButton: false
        ) { size in
            VStack(spacing: 8) {
                FoodLogHeader(
                    selectedTab: $selectedTab,
                    searchText: $searchText,
                    onBack: { dismiss() }
                )
                .fixedSize(horizontal: false, vertical: true)
                .zIndex(2)

                ZStack(alignment: .bottom) {
                    DesignImageView(assetID: "food_diary_field", contentMode: .fill) {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(GameDesign.cream)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

                    ScrollView {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6),
                            spacing: 10
                        ) {
                            ForEach(visibleFoods) { food in
                                Button {
                                    viewModel.log(food.category)
                                } label: {
                                    FoodChoiceCard(choice: food)
                                }
                                .buttonStyle(.plain)
                                .disabled(viewModel.isLogging)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 16)
                        .padding(.bottom, 80)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(1)

                }
                .zIndex(1)
                .frame(maxWidth: .infinity)
                .frame(height: max(160, size.height - 145), alignment: .top)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay(alignment: .bottom) {
                    FoodSearchBar(text: $searchText)
                        .padding(.horizontal, size.width * 0.18)
                        .padding(.bottom, 12)
                }
            }
            .frame(height: max(280, size.height - 31), alignment: .top)
        }
        .overlay(alignment: .bottom) {
            if let result = viewModel.lastResult {
                FoodLogResultToast(result: result)
                    .padding(.bottom, 18)
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(GameDesign.font(14, weight: .bold))
                    .foregroundStyle(GameDesign.green)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(GameDesign.cream)
                    .clipShape(Capsule())
                    .padding(.bottom, 18)
            }
        }
    }
}

private enum FoodTab: String, CaseIterable, Identifiable {
    case all = "ALL", fruits = "FRUITS", vegetables = "VEGES", meal = "MEAL", sweets = "SWEETS", other = "OTHER"
    var id: String { rawValue }
}

private struct FoodChoice: Identifiable {
    let id: String
    let title: String
    let assetID: String
    let category: FoodCategory
    let tab: FoodTab

    static let catalog: [FoodChoice] = [
        .init(id: "misc", title: "Other", assetID: "food_card_misc", category: .custom, tab: .other),
        .init(id: "water200", title: "Water 200 ml", assetID: "food_card_water200", category: .water, tab: .other),
        .init(id: "water300", title: "Water 300 ml", assetID: "food_card_water300", category: .water, tab: .other),
        .init(id: "water500", title: "Water 500 ml", assetID: "food_card_water500", category: .water, tab: .other),
        .init(id: "grape", title: "Grape", assetID: "food_card_grape", category: .fruit, tab: .fruits),
        .init(id: "orange", title: "Orange", assetID: "food_card_orange", category: .fruit, tab: .fruits),
        .init(id: "broccoli", title: "Broccoli", assetID: "food_card_broccoli", category: .vegetable, tab: .vegetables),
        .init(id: "beans", title: "Beans", assetID: "food_card_beans", category: .vegetable, tab: .vegetables),
        .init(id: "banana", title: "Banana", assetID: "food_card_banana", category: .fruit, tab: .fruits),
        .init(id: "tomato", title: "Tomato", assetID: "food_card_tomato", category: .vegetable, tab: .vegetables),
        .init(id: "strawberry", title: "Strawberry", assetID: "food_card_strawberry", category: .fruit, tab: .fruits),
        .init(id: "peas", title: "Peas", assetID: "food_card_peas", category: .vegetable, tab: .vegetables),
        .init(id: "carrot", title: "Carrot", assetID: "food_card_carrot", category: .vegetable, tab: .vegetables),
        .init(id: "eggs", title: "Eggs", assetID: "food_card_eggs", category: .healthyMeal, tab: .meal),
        .init(id: "cucumber", title: "Cucumber", assetID: "food_card_cucumber", category: .vegetable, tab: .vegetables),
        .init(id: "chicken", title: "Chicken", assetID: "food_card_chicken", category: .healthyMeal, tab: .meal),
        .init(id: "cheese", title: "Cheese", assetID: "food_card_cheese", category: .healthyMeal, tab: .meal),
        .init(id: "apple", title: "Apple", assetID: "food_card_apple", category: .fruit, tab: .fruits)
    ]
}

private struct FoodLogHeader: View {
    @Binding var selectedTab: FoodTab
    @Binding var searchText: String
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
            Button(action: onBack) {
                DesignImageView(assetID: "back_button", contentMode: .fit) {
                    Image(systemName: "chevron.left")
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }
                .frame(width: 54, height: 54)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()
            Text("HERO'S FOOD")
                .font(GameDesign.font(28, weight: .black))
                .foregroundStyle(GameDesign.green)
            Spacer()

            DesignImageView(assetID: "settings_button", contentMode: .fit) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                    .background(Color.purple.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .frame(width: 54, height: 54)
            }
            HStack(spacing: 0) {
                ForEach(FoodTab.allCases) { tab in
                    Button(tab.rawValue) { selectedTab = tab }
                        .font(GameDesign.font(13, weight: .bold))
                        .foregroundStyle(GameDesign.green)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? GameDesign.cream : GameDesign.cream.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 4)
    }
}

private struct FoodChoiceCard: View {
    let choice: FoodChoice

    var body: some View {
        DesignImageView(assetID: choice.assetID, contentMode: .fit) {
            VStack(spacing: 5) {
                Image(systemName: "leaf.fill")
                    .font(.title)
                    .foregroundStyle(GameDesign.green)
                Text(choice.title)
                    .font(GameDesign.font(13, weight: .bold))
                    .foregroundStyle(GameDesign.green)
            }
            .padding(10)
            .background(GameDesign.cream)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(GameDesign.cream)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.13), radius: 4, y: 2)
    }
}

private struct FoodSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.title3.bold())
                .foregroundStyle(GameDesign.green)
            TextField("Search", text: $text)
                .font(GameDesign.font(15))
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 18)
        .frame(height: 48)
        .background(Color(red: 0.91, green: 0.89, blue: 0.72))
        .clipShape(Capsule())
    }
}

private struct FoodLogResultToast: View {
    let result: LogFoodResult

    var body: some View {
        Text("+\(result.smallProgressAwarded + result.bigProgressAwarded) XP")
            .font(GameDesign.font(18, weight: .black))
            .foregroundStyle(GameDesign.green)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(GameDesign.cream)
            .clipShape(Capsule())
            .shadow(radius: 5)
    }
}
