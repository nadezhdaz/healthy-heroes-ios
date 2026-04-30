import SwiftUI

struct FoodLogView: View {
    @StateObject private var viewModel: FoodLogViewModel

    init(viewModel: FoodLogViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Log one healthy choice")
                .font(.title.bold())
            Text("One tap equals one progress action. Parents decide what counts.")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                ForEach(viewModel.categories) { category in
                    Button {
                        viewModel.log(category)
                    } label: {
                        Label(category.title, systemImage: iconName(for: category))
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLogging)
                }
            }

            if let result = viewModel.lastResult {
                ResultSummary(result: result)
            }

            Spacer()
        }
        .padding(20)
        .navigationTitle("Food Log")
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
