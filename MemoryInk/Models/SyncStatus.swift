enum SyncStatus: String, CaseIterable, Identifiable {
    case pending
    case syncing
    case completed
    case failed

    var id: String { rawValue }
}
