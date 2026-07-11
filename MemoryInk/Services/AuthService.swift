import Combine
import AuthenticationServices
import Foundation
import UIKit

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
final class AuthService: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    @Published private(set) var state: AuthState
    var presentationAnchor: ASPresentationAnchor?

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
    private var appleContinuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

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

        super.init()
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

        let storedProvider = defaults.string(forKey: Key.provider)
            .flatMap(AuthProvider.init(rawValue:)) ?? .email

        do {
            let session = try await refreshSupabaseSession(refreshToken: refreshToken)
            persist(session: session, provider: storedProvider)
            state = .signedIn(
                AccountSession(
                    userId: session.user.id,
                    provider: storedProvider,
                    email: session.user.email
                )
            )
        } catch {
            clearStoredSession()
            state = .signedOut
        }
    }

    func signInWithApple() async -> AuthResult {
        do {
            let credential = try await requestAppleCredential()
            guard let identityToken = credential.identityToken,
                  let idToken = String(data: identityToken, encoding: .utf8)
            else {
                throw AuthServiceError.requestFailed
            }

            guard configuration.isConfigured else {
                signInWithLocalApplePlaceholder(credential: credential)
                return .success
            }

            let session = try await exchangeAppleToken(idToken: idToken)
            persist(session: session, provider: .apple)
            state = .signedIn(
                AccountSession(
                    userId: session.user.id,
                    provider: .apple,
                    email: session.user.email
                )
            )
            return .success
        } catch let error as ASAuthorizationError where error.code == .canceled {
            // User dismissed the sheet — no state change, no toast
            return .failure("")
        } catch {
            let message = "Couldn't sign in with Apple. Try again."
            state = .error(message)
            return .failure(message)
        }
    }

    func signInWithEmail(_ email: String, password: String) async -> AuthResult {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(normalizedEmail) else {
            let message = "Enter a valid email address."
            state = .error(message)
            return .failure(message)
        }

        guard isValidPassword(normalizedPassword) else {
            let message = "Password must be at least 6 characters."
            state = .error(message)
            return .failure(message)
        }

        guard configuration.isConfigured else {
            signInWithLocalPlaceholder(email: normalizedEmail)
            return .success
        }

        do {
            let session = try await passwordGrant(email: normalizedEmail, password: normalizedPassword)
            persist(session: session, provider: .email)
            state = .signedIn(
                AccountSession(
                    userId: session.user.id,
                    provider: .email,
                    email: session.user.email
                )
            )
            return .success
        } catch {
            let message = userFacingMessage(for: error)
            state = .error(message)
            return .failure(message)
        }
    }

    func createAccount(email: String, password: String) async -> AuthResult {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(normalizedEmail) else {
            let message = "Enter a valid email address."
            state = .error(message)
            return .failure(message)
        }

        guard isValidPassword(normalizedPassword) else {
            let message = "Password must be at least 6 characters."
            state = .error(message)
            return .failure(message)
        }

        guard configuration.isConfigured else {
            signInWithLocalPlaceholder(email: normalizedEmail)
            return .success
        }

        do {
            let session = try await signUp(email: normalizedEmail, password: normalizedPassword)
            persist(session: session, provider: .email)
            state = .signedIn(
                AccountSession(
                    userId: session.user.id,
                    provider: .email,
                    email: session.user.email
                )
            )
            return .success
        } catch {
            let message = userFacingMessage(for: error)
            state = .error(message)
            return .failure(message)
        }
    }

    func signOut() {
        clearStoredSession()
        state = configuration.isConfigured ? .signedOut : .unavailableMissingConfig
    }

    func deleteAccount() async -> AuthResult {
        let failureMessage = "Couldn't delete account. Try again."

        guard configuration.isConfigured, let accessToken else {
            return .failure(failureMessage)
        }

        do {
            var req = try request(path: "functions/v1/delete-account", method: "DELETE")
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            let (_, response) = try await session.data(for: req)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
#if DEBUG
                print("[MemoryInk][Auth] Delete account request failed with status \((response as? HTTPURLResponse)?.statusCode ?? -1)")
#endif
                return .failure(failureMessage)
            }

            clearStoredSession()
            state = .signedOut
            return .success
        } catch {
#if DEBUG
            print("[MemoryInk][Auth] Delete account request could not complete")
#endif
            return .failure(failureMessage)
        }
    }

    func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@")
        guard parts.count == 2 else { return false }
        let domainParts = parts[1].split(separator: ".")
        return !parts[0].isEmpty && domainParts.count >= 2 && domainParts.allSatisfy { !$0.isEmpty }
    }

    func isValidPassword(_ password: String) -> Bool {
        password.trimmingCharacters(in: .whitespacesAndNewlines).count >= 6
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

    private func signInWithLocalApplePlaceholder(credential: ASAuthorizationAppleIDCredential) {
        let userId = "local-apple:\(credential.user)"
        defaults.set(AuthProvider.apple.rawValue, forKey: Key.provider)
        defaults.set(credential.email, forKey: Key.email)
        defaults.set(userId, forKey: Key.userId)
        defaults.removeObject(forKey: Key.accessToken)
        defaults.removeObject(forKey: Key.refreshToken)
        defaults.removeObject(forKey: Key.expiresAt)
        accessToken = nil
        refreshToken = nil

        state = .signedIn(
            AccountSession(
                userId: userId,
                provider: .apple,
                email: credential.email
            )
        )
    }

    private func requestAppleCredential() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            appleContinuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.email, .fullName]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    private func exchangeAppleToken(idToken: String) async throws -> SupabaseAuthSession {
        var request = try request(path: "auth/v1/token", query: "grant_type=id_token", method: "POST")
        request.httpBody = try JSONEncoder().encode(OAuthTokenRequest(provider: "apple", idToken: idToken))
        return try await decoded(SupabaseAuthSession.self, from: request)
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
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthServiceError.requestFailed
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
#if DEBUG
            print("[MemoryInk][Auth] HTTP \(httpResponse.statusCode): \(String(data: data, encoding: .utf8) ?? "n/a")")
#endif
            let authError = try? JSONDecoder().decode(SupabaseAuthErrorResponse.self, from: data)
            throw AuthServiceError.authRejected(authError?.userFacingMessage ?? "Couldn't sign in right now. Try again.")
        }

        return try JSONDecoder().decode(type, from: data)
    }

    private func userFacingMessage(for error: Error) -> String {
        if case let AuthServiceError.authRejected(message) = error {
            return message
        }

        return "Couldn't sign in right now. Try again."
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

    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            presentationAnchor
                ?? UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap(\.windows)
                    .first { $0.isKeyWindow }
                ?? ASPresentationAnchor()
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                appleContinuation?.resume(throwing: AuthServiceError.requestFailed)
                appleContinuation = nil
                return
            }

            appleContinuation?.resume(returning: credential)
            appleContinuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            appleContinuation?.resume(throwing: error)
            appleContinuation = nil
        }
    }
}

private enum AuthServiceError: Error {
    case missingConfiguration
    case requestFailed
    case authRejected(String)
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

private struct OAuthTokenRequest: Encodable {
    let provider: String
    let idToken: String

    enum CodingKeys: String, CodingKey {
        case provider
        case idToken = "id_token"
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

private struct SupabaseAuthErrorResponse: Decodable {
    let message: String?
    let msg: String?
    let error: String?
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case message
        case msg
        case error
        case errorDescription = "error_description"
    }

    var userFacingMessage: String {
        let rawMessage = [message, msg, errorDescription, error]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()

        if rawMessage.contains("rate") || rawMessage.contains("too many") {
            return "Please wait a moment and try again."
        }

        if rawMessage.contains("invalid")
            || rawMessage.contains("credential")
            || rawMessage.contains("password")
            || rawMessage.contains("email")
            || rawMessage.contains("registered") {
            return "That email or password didn't work."
        }

        return "Couldn't sign in right now. Try again."
    }
}
