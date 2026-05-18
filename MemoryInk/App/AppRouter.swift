import Foundation

enum AppRoute: Hashable {
    case timeline
    case memoryDetail(id: UUID)
    case recap
    case onThisDay
    case settings
    case subscription
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
