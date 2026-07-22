import Foundation

enum AppRoute: Hashable {
    case start
    case characterCreation
    case classSelection
    case mainHub
    case foodLog
    case map
    case quests
    case rewards
    case wardrobe
    case stickerAlbum
    case miniGames
    case settings
    case mysteryPack([RewardID])
}

enum AppSheet: Identifiable, Hashable {
    case mysteryPack([RewardID])
    case reward(RewardID)

    var id: String {
        switch self {
        case let .mysteryPack(ids):
            "mysteryPack-\(ids.joined(separator: "-"))"
        case let .reward(id):
            "reward-\(id)"
        }
    }
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var path: [AppRoute] = []
    @Published var sheet: AppSheet?

    func show(_ route: AppRoute) {
        path.append(route)
    }

    func replaceStack(with route: AppRoute) {
        path = [route]
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    func present(_ sheet: AppSheet) {
        self.sheet = sheet
    }

    func dismissSheet() {
        sheet = nil
    }
}
