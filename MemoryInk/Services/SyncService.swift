import Combine
import Foundation

enum SyncServiceState: Equatable {
    case idle
    case notConfigured
    case localOnly
    case syncing
    case completed(Date)
    case failed(String)
}

struct SupabaseSyncConfiguration {
    let baseURL: URL?
    let anonKey: String?

    static var placeholder: SupabaseSyncConfiguration {
        SupabaseSyncConfiguration(
            baseURL: (Bundle.main.object(forInfoDictionaryKey: "MemoryInkSupabaseURL") as? String).flatMap(URL.init(string:)),
            anonKey: Bundle.main.object(forInfoDictionaryKey: "MemoryInkSupabaseAnonKey") as? String
        )
    }

    var isConfigured: Bool {
        baseURL != nil && anonKey?.isEmpty == false
    }
}

@MainActor
final class SyncService: ObservableObject {
    @Published private(set) var state: SyncServiceState = .idle

    private let configuration: SupabaseSyncConfiguration
    private let repository: JournalEntryRepository
    private let subscriptionManager: SubscriptionManager
    private let authService: AuthService

    init(
        configuration: SupabaseSyncConfiguration = .placeholder,
        repository: JournalEntryRepository,
        subscriptionManager: SubscriptionManager,
        authService: AuthService
    ) {
        self.configuration = configuration
        self.repository = repository
        self.subscriptionManager = subscriptionManager
        self.authService = authService
    }

    var isConfigured: Bool {
        configuration.isConfigured
    }

    func syncMetadataIfAllowed() async {
        guard subscriptionManager.canUseMetadataSync else {
            state = .localOnly
            return
        }

        guard isConfigured else {
            state = .notConfigured
            return
        }

        guard case let .signedIn(session) = authService.state else {
            state = .failed("Sign in to sync metadata.")
            return
        }

        state = .syncing
        _ = metadataPayload(userId: session.userId)

        // Placeholder until Supabase SDK/client setup is approved.
        state = .completed(Date())
    }

    func metadataPayload(userId: String) -> [SyncMetadataRecord] {
        repository.entries.map { entry in
            SyncMetadataRecord(entry: entry, userId: userId)
        }
    }
}
