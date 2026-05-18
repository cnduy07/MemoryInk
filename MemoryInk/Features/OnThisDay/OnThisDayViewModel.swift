import Foundation

@MainActor
final class OnThisDayViewModel: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []

    private let service: OnThisDayService

    init(service: OnThisDayService) {
        self.service = service
    }

    func refresh() {
        service.refresh()
        entries = service.entries
    }
}
