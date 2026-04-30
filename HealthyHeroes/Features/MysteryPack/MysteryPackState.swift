import Foundation

enum MysteryPackState: Equatable {
    case closed
    case opening(step: Int)
    case revealed(Reward)
    case finished
}
