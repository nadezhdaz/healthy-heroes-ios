import Combine
import Foundation

@MainActor
final class AppAnalytics {
    private static let storageKey = "healthyHeroes.analytics.events"
    private static let completionKey = "healthyHeroes.analytics.firstSessionCompleted"
    private static let funnelKey = "healthyHeroes.analytics.firstSessionEvents"

    private let defaults: UserDefaults
    private var cancellable: AnyCancellable?

    init(eventBus: AppEventBus, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        cancellable = eventBus.events.sink { [weak self] event in
            self?.record(event)
        }
        record(name: "app_opened")
    }

    var eventNames: [String] {
        defaults.stringArray(forKey: Self.storageKey) ?? []
    }

    // Preserve the first occurrence of each funnel step beyond the rolling log.
    var firstSessionEventNames: [String] {
        defaults.stringArray(forKey: Self.funnelKey) ?? []
    }

    private func record(_ event: AppEvent) {
        switch event {
        case .appOpened: record(name: "app_opened")
        case .playTapped: record(name: "play_tapped")
        case .characterCreated: record(name: "character_created")
        case .classSelected: record(name: "class_selected")
        case .profileUpdated: break
        case .foodLogged: record(name: "food_logged")
        case .firstFoodLogged: record(name: "first_food_logged")
        case .questCompleted: record(name: "quest_completed")
        case .rewardsUnlocked: break
        case .rewardOpened: record(name: "reward_opened")
        case .rewardEquipped: record(name: "reward_equipped")
        case .itemEquipped: break
        case let .firstSessionProgressUpdated(state):
            guard state.hasFinishedFirstSessionLoop,
                  !defaults.bool(forKey: Self.completionKey) else { return }
            record(name: "first_session_completed")
            defaults.set(true, forKey: Self.completionKey)
        }
    }

    private func record(name: String) {
        if !defaults.bool(forKey: Self.completionKey) {
            var funnel = firstSessionEventNames
            if !funnel.contains(name) {
                funnel.append(name)
                defaults.set(funnel, forKey: Self.funnelKey)
            }
        }
        var names = eventNames
        names.append(name)
        defaults.set(Array(names.suffix(500)), forKey: Self.storageKey)
    }
}
