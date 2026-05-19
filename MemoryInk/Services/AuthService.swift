import Combine
import Foundation

struct SupabaseAuthConfiguration {
    let baseURL: URL?
    let anonKey: String?

    static var current: SupabaseAuthConfiguration {
        SupabaseAuthConfiguration(
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
final class AuthService: ObservableObject {
    @Published private(set) var state: AuthState

    private enum Key {
        static let provider = "auth_provider"
        static let email = "auth_email"
        static let userId = "auth_user_id"
        static let accessToken = "auth_access_token"
        static let refreshToken = "auth_refresh_token"
        static let expiresAt = "auth_expires_at"
    }

    private let configuration: SupabaseAuthConfiguration
    private let defaults: UserDefaults
    private let session: URLSession
    private var accessToken: String?
    private var refreshToken: String?

    init(
        configuration: SupabaseAuthConfiguration = .current,
        defaults: UserDefaults = .standard,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.defaults = defaults
        self.session = session

        let storedProvider = defaults.string(forKey: Key.provider).flatMap(AuthProvider.init(rawValue:))
        let storedEmail = defaults.string(forKey: Key.email)
        let storedUserId = defaults.string(forKey: Key.userId)
        self.accessToken = defaults.string(forKey: Key.accessToken)
        self.refreshToken = defaults.string(forKey: Key.refreshToken)

        if let storedProvider, let storedEmail, let storedUserId {
            self.state = .signedIn(
                AccountSession(
                    userId: storedUserId,
                    provider: storedProvider,
                    email: storedEmail
                )
            )
        } else if configuration.isConfigured {
            self.state = .signedOut
        } else {
            self.state = .unavailableMissingConfig
        }
    }

    var isConfigured: Bool {
        configuration.isConfigured
    }

    var currentAccessToken: String? {
        accessToken
    }

    func restoreSession() async {
        guard configuration.isConfigured else { return }
        guard
            let refreshToken,
            !refreshToken.isEmpty,
            case .signedIn = state
        else {
            return
        }

        do {
            let session = try await refreshSupabaseSession(refreshToken: refreshToken)
            persist(session: session, provider: .email)
            state = .signedIn(
                AccountSession(
                    userId: session.user.id,
                    provider: .email,
                    email: session.user.email
                )
            )
        } catch {
            clearStoredSession()
            state = .signedOut
        }
    }

    func signInWithApple() async {
        // Boundary only: real Sign in with Apple requires Apple Developer account configuration.
        state = configuration.isConfigured ? .signedOut : .unavailableMissingConfig
    }

    func signInWithGoogle() async {
        // Boundary only: real Google Sign-In requires approved SDK/client ID setup.
        state = configuration.isConfigured ? .signedOut : .unavailableMissingConfig
    }

    func signInWithEmail(_ email: String, password: String) async -> Bool {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(normalizedEmail), !normalizedPassword.isEmpty else { return false }

        guard configuration.isConfigured else {
            signInWithLocalPlaceholder(email: normalizedEmail)
            return true
        }

        do {
            let session = try await signInWithSupabase(email: normalizedEmail, password: normalizedPassword)
            persist(session: session, provider: .email)
            state = .signedIn(
                AccountSession(
                    userId: session.user.id,
                    provider: .email,
                    email: session.user.email
                )
            )
            return true
        } catch {
            state = .error("Couldn't sign in right now. Try again.")
            return false
        }
    }

    func signOut() {
        clearStoredSession()
        state = configuration.isConfigured ? .signedOut : .unavailableMissingConfig
    }

    func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@")
        guard parts.count == 2 else { return false }
        let domainParts = parts[1].split(separator: ".")
        return !parts[0].isEmpty && domainParts.count >= 2 && domainParts.allSatisfy { !$0.isEmpty }
    }

    private func signInWithLocalPlaceholder(email: String) {
        let userId = "local-email:\(email)"
        defaults.set(AuthProvider.email.rawValue, forKey: Key.provider)
        defaults.set(email, forKey: Key.email)
        defaults.set(userId, forKey: Key.userId)
        defaults.removeObject(forKey: Key.accessToken)
        defaults.removeObject(forKey: Key.refreshToken)
        defaults.removeObject(forKey: Key.expiresAt)
        accessToken = nil
        refreshToken = nil

        state = .signedIn(
            AccountSession(
                userId: userId,
                provider: .email,
                email: email
            )
        )
    }

    private func signInWithSupabase(email: String, password: String) async throws -> SupabaseAuthSession {
        do {
            return try await passwordGrant(email: email, password: password)
        } catch {
            return try await signUp(email: email, password: password)
        }
    }

    private func passwordGrant(email: String, password: String) async throws -> SupabaseAuthSession {
        var request = try request(path: "auth/v1/token", query: "grant_type=password", method: "POST")
        request.httpBody = try JSONEncoder().encode(AuthCredentials(email: email, password: password))
        return try await decoded(SupabaseAuthSession.self, from: request)
    }

    private func signUp(email: String, password: String) async throws -> SupabaseAuthSession {
        var request = try request(path: "auth/v1/signup", method: "POST")
        request.httpBody = try JSONEncoder().encode(AuthCredentials(email: email, password: password))
        return try await decoded(SupabaseAuthSession.self, from: request)
    }

    private func refreshSupabaseSession(refreshToken: String) async throws -> SupabaseAuthSession {
        var request = try request(path: "auth/v1/token", query: "grant_type=refresh_token", method: "POST")
        request.httpBody = try JSONEncoder().encode(RefreshRequest(refreshToken: refreshToken))
        return try await decoded(SupabaseAuthSession.self, from: request)
    }

    private func request(path: String, query: String? = nil, method: String) throws -> URLRequest {
        guard let baseURL = configuration.baseURL, let anonKey = configuration.anonKey else {
            throw AuthServiceError.missingConfiguration
        }

        var url = baseURL.appendingPathComponent(path)
        if let query {
            url = URL(string: "\(url.absoluteString)?\(query)") ?? url
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private func decoded<T: Decodable>(_ type: T.Type, from request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw AuthServiceError.requestFailed
        }

        return try JSONDecoder().decode(type, from: data)
    }

    private func persist(session: SupabaseAuthSession, provider: AuthProvider) {
        defaults.set(provider.rawValue, forKey: Key.provider)
        defaults.set(session.user.email, forKey: Key.email)
        defaults.set(session.user.id, forKey: Key.userId)
        defaults.set(session.accessToken, forKey: Key.accessToken)
        defaults.set(session.refreshToken, forKey: Key.refreshToken)
        defaults.set(session.expiresAt, forKey: Key.expiresAt)
        accessToken = session.accessToken
        refreshToken = session.refreshToken
    }

    private func clearStoredSession() {
        defaults.removeObject(forKey: Key.provider)
        defaults.removeObject(forKey: Key.email)
        defaults.removeObject(forKey: Key.userId)
        defaults.removeObject(forKey: Key.accessToken)
        defaults.removeObject(forKey: Key.refreshToken)
        defaults.removeObject(forKey: Key.expiresAt)
        accessToken = nil
        refreshToken = nil
    }
}

private enum AuthServiceError: Error {
    case missingConfiguration
    case requestFailed
}

private struct AuthCredentials: Encodable {
    let email: String
    let password: String
}

private struct RefreshRequest: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

private struct SupabaseAuthSession: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Int?
    let user: SupabaseAuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case user
    }
}

private struct SupabaseAuthUser: Decodable {
    let id: String
    let email: String?
}
