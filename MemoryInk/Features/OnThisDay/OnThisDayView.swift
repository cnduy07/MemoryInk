import SwiftUI

struct OnThisDayView: View {
    @EnvironmentObject private var service: OnThisDayService
    @StateObject private var viewModel: OnThisDayViewModel

    init(service: OnThisDayService? = nil) {
        if let service {
            _viewModel = StateObject(wrappedValue: OnThisDayViewModel(service: service))
        } else {
            _viewModel = StateObject(wrappedValue: OnThisDayViewModel(service: PreviewOnThisDayService.make()))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("On this day")
                .font(MemoryInkTypography.subtitle)
                .foregroundStyle(MemoryInkColors.tertiaryInk)
                .textCase(.uppercase)

            if viewModel.entries.isEmpty {
                Text("No memories from this day yet.")
                    .font(MemoryInkTypography.narrativeCompact)
                    .foregroundStyle(MemoryInkColors.secondaryInk)
            } else {
                ForEach(viewModel.entries) { entry in
                    Text(entry.aiNarrative ?? "A memory from this day is waiting quietly.")
                        .font(MemoryInkTypography.narrativeCompact)
                        .foregroundStyle(MemoryInkColors.ink)
                }
            }
        }
        .padding(20)
        .background(MemoryInkColors.paper.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: MemoryInkSpacing.cardCornerRadius, style: .continuous))
        .onAppear {
            viewModel.refresh()
        }
    }
}

private enum PreviewOnThisDayService {
    @MainActor
    static func make() -> OnThisDayService {
        let stack = CoreDataStack(inMemory: true)
        let repository = JournalEntryRepository(context: stack.viewContext)
        return OnThisDayService(repository: repository)
    }
}
