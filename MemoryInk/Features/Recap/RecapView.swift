import SwiftUI

struct RecapView: View {
    @EnvironmentObject private var recapService: RecapService
    @StateObject private var viewModel: RecapViewModel

    init(recapService: RecapService? = nil) {
        if let recapService {
            _viewModel = StateObject(wrappedValue: RecapViewModel(recapService: recapService))
        } else {
            _viewModel = StateObject(wrappedValue: RecapViewModel(recapService: PreviewRecapService.make()))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Weekly recap")
                .font(MemoryInkTypography.subtitle)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            Text(viewModel.recap?.recap ?? viewModel.message ?? "Your weekly recap will appear here when there is enough to reflect on.")
                .font(MemoryInkTypography.narrative)
                .foregroundStyle(MemoryInkColors.ink)
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(MemoryInkColors.paper.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .task {
            await viewModel.generateWeeklyRecap()
        }
    }
}

private enum PreviewRecapService {
    @MainActor
    static func make() -> RecapService {
        let stack = CoreDataStack(inMemory: true)
        let repository = JournalEntryRepository(context: stack.viewContext)
        return RecapService(
            aiService: AIService(),
            repository: repository,
            usageTracker: AIUsageTracker()
        )
    }
}
