import SwiftUI

@main
struct MemoryInkApp: App {
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            TimelineView()
                .environmentObject(router)
        }
    }
}
