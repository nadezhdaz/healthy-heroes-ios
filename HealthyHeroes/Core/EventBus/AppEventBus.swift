import Combine
import Foundation

@MainActor
final class AppEventBus {
    let events = PassthroughSubject<AppEvent, Never>()

    func post(_ event: AppEvent) {
        events.send(event)
    }
}
