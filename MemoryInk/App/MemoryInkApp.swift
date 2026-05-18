import SwiftUI

@main
struct MemoryInkApp: App {
    private let coreDataStack: CoreDataStack

    @StateObject private var router = AppRouter()
    @StateObject private var imagePipeline = ImagePipelineService()
    @StateObject private var repository: JournalEntryRepository

    init() {
        let coreDataStack = CoreDataStack()
        self.coreDataStack = coreDataStack
        _repository = StateObject(
            wrappedValue: JournalEntryRepository(context: coreDataStack.viewContext)
        )
    }

    var body: some Scene {
        WindowGroup {
            TimelineView()
                .environmentObject(router)
                .environmentObject(repository)
                .environmentObject(imagePipeline)
        }
    }
}
