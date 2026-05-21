import Foundation

enum AppRoute: Hashable {
    case timeline
    case memoryDetail(id: UUID)
    case memoryViewer(entryId: UUID)
    case recap
    case onThisDay
    case yearlyReview
    case calendar
    case browse
    case settings
    case subscription
    case subscriptionPreview
}

final class AppRouter: ObservableObject {
    @Published var path: [AppRoute] = []

    func openMemory(id: UUID) {
        path.append(.memoryDetail(id: id))
    }

    func popToRoot() {
        path.removeAll()
    }
}
