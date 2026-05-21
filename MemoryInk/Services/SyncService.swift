import Combine
import Foundation

enum SyncServiceState: Equatable {
    case idle
    case notConfigured
    case localOnly
    case signedOut
    case syncing
    case completed(Date)
    case failed(String)
}

struct SupabaseSyncConfiguration {
    let baseURL: URL?
    let anonKey: String?

    static var current: SupabaseSyncConfiguration {
        SupabaseSyncConfiguration(
            baseURL: Self.stringValue(for: "SupabaseURL").flatMap(URL.init(string:)),
            anonKey: Self.stringValue(for: "SupabaseAnonKey")
        )
    }

    var isConfigured: Bool {
        baseURL != nil && anonKey?.isEmpty == false
    }

    private static func stringValue(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

@MainActor
final class SyncService: ObservableObject {
    @Published private(set) var state: SyncServiceState

    private let configuration: SupabaseSyncConfiguration
    private let repository: JournalEntryRepository
    private let subscriptionManager: SubscriptionManager
    private let authService: AuthService
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        configuration: SupabaseSyncConfiguration = .current,
        repository: JournalEntryRepository,
        subscriptionManager: SubscriptionManager,
        authService: AuthService,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.repository = repository
        self.subscriptionManager = subscriptionManager
        self.authService = authService
        self.session = session

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = ISO8601DateFormatter.memoryInkWithFractionalSeconds.date(from: value)
                ?? ISO8601DateFormatter.memoryInk.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format."
            )
        }
        self.decoder = decoder

        self.state = configuration.isConfigured ? .idle : .notConfigured
    }

    var isConfigured: Bool {
        configuration.isConfigured
    }

    func syncMetadataIfAllowed() async {
        guard canAttemptMetadataSync else {
            state = .localOnly
            log("Sync unavailable: local-only plan")
            return
        }

        guard isConfigured else {
            state = .notConfigured
            log("Sync unavailable: configuration missing")
            return
        }

        guard
            case let .signedIn(accountSession) = authService.state,
            let accessToken = authService.currentAccessToken
        else {
            state = .signedOut
            log("Sync unavailable: signed out")
            return
        }

        state = .syncing
        let pendingEntries = repository.pendingLocalEntries()
        let pendingIds = pendingEntries.map(\.id)
        repository.markSyncing(pendingIds)
        log("Sync started: pending_records=\(pendingEntries.count)")

        do {
            if !pendingEntries.isEmpty {
                try await upload(entries: pendingEntries, userId: accountSession.userId, accessToken: accessToken)
                repository.markSyncCompleted(pendingIds)
            }

            let remoteRecords = try await fetchRemoteMetadata(accessToken: accessToken)
            remoteRecords.forEach { record in
                repository.applyRemoteMetadataUpdate(record)
            }

            state = .completed(Date())
            log("Sync succeeded: pending_records=\(pendingEntries.count), remote_records=\(remoteRecords.count)")
        } catch {
            repository.markSyncFailed(pendingIds)
            state = .failed("Couldn't sync right now. Try again.")
            log("Sync failed: pending_records=\(pendingEntries.count)")
        }
    }

    func metadataPayload(userId: String) -> [SyncMetadataRecord] {
        repository.entries.map { entry in
            SyncMetadataRecord(entry: entry, userId: userId)
        }
    }

    private var canAttemptMetadataSync: Bool {
        subscriptionManager.canUseMetadataSync
    }

    private func upload(entries: [JournalEntry], userId: String, accessToken: String) async throws {
        let records = entries.map { entry in
            metadataOnlyRecord(for: entry, userId: userId)
        }

        var request = try restRequest(
            path: "rest/v1/journal_entries",
            method: "POST",
            accessToken: accessToken
        )
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(records)

        _ = try await data(for: request, accepting: 200..<300)
    }

    private func metadataOnlyRecord(for entry: JournalEntry, userId: String) -> SyncMetadataRecord {
        // Privacy boundary: never include local media paths, image blobs, EXIF, GPS, or voice files.
        SyncMetadataRecord(entry: entry, userId: userId, syncStatus: .completed)
    }

    private func fetchRemoteMetadata(accessToken: String) async throws -> [SyncMetadataRecord] {
        let select = [
            "id",
            "user_id",
            "created_at",
            "updated_at",
            "deleted_at",
            "raw_note",
            "mood",
            "narrative_style",
            "ai_narrative",
            "ai_generation_date",
            "is_favorite",
            "sync_status",
            "local_photo_exists",
            "local_voice_exists"
        ].joined(separator: ",")
        let query = "select=\(select)&order=updated_at.desc"
        let request = try restRequest(
            path: "rest/v1/journal_entries",
            query: query,
            method: "GET",
            accessToken: accessToken
        )

        let data = try await data(for: request, accepting: 200..<300)
        return try decoder.decode([SyncMetadataRecord].self, from: data)
    }

    private func restRequest(
        path: String,
        query: String? = nil,
        method: String,
        accessToken: String
    ) throws -> URLRequest {
        guard let baseURL = configuration.baseURL, let anonKey = configuration.anonKey else {
            throw SyncServiceError.missingConfiguration
        }

        var url = baseURL.appendingPathComponent(path)
        if let query {
            url = URL(string: "\(url.absoluteString)?\(query)") ?? url
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func data(for request: URLRequest, accepting range: Range<Int>) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, range.contains(httpResponse.statusCode) else {
            throw SyncServiceError.requestFailed
        }

        return data
    }

    private func log(_ message: String) {
        print("[MemoryInk][Sync] \(message)")
    }
}

private enum SyncServiceError: Error {
    case missingConfiguration
    case requestFailed
}

private extension ISO8601DateFormatter {
    static let memoryInk: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let memoryInkWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
