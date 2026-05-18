import Foundation

@MainActor
final class RecapViewModel: ObservableObject {
    @Published private(set) var recap: WeeklyRecap?
    @Published private(set) var message: String?

    private let recapService: RecapService

    init(recapService: RecapService) {
        self.recapService = recapService
        self.recap = recapService.latestRecap
        self.message = recapService.errorMessage
    }

    func generateWeeklyRecap() async {
        await recapService.generateWeeklyRecapIfPossible()
        recap = recapService.latestRecap
        message = recapService.errorMessage
    }
}
