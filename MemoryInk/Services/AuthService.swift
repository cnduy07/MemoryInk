import Combine
import Foundation

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var state: AuthState

    private enum Key {
        static let provider = "auth_provider"
        static let email = "auth_email"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if
            defaults.string(forKey: Key.provider) == AuthProvider.email.rawValue,
            let email = defaults.string(forKey: Key.email)
        {
            self.state = .signedIn(
                AccountSession(
                    userId: "email:\(email)",
                    provider: .email,
                    email: email
                )
            )
        } else {
            self.state = .signedOut
        }
    }

    func signInWithApple() async {
        // Placeholder until Apple developer Sign in with Apple setup is configured.
        state = .signedOut
    }

    func signInWithGoogle() async {
        // Placeholder until Google Sign-In SDK and client ID are approved and configured.
        state = .signedOut
    }

    func signInWithEmail(_ email: String, password: String) async -> Bool {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidEmail(normalizedEmail), !normalizedPassword.isEmpty else { return false }

        // Real email accounts will be stored in Supabase Auth during real auth implementation.
        state = .signedIn(
            AccountSession(
                userId: "email:\(normalizedEmail)",
                provider: .email,
                email: normalizedEmail
            )
        )
        defaults.set(AuthProvider.email.rawValue, forKey: Key.provider)
        defaults.set(normalizedEmail, forKey: Key.email)
        return true
    }

    func signOut() {
        state = .signedOut
        defaults.removeObject(forKey: Key.provider)
        defaults.removeObject(forKey: Key.email)
    }

    func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@")
        guard parts.count == 2 else { return false }
        let domainParts = parts[1].split(separator: ".")
        return !parts[0].isEmpty && domainParts.count >= 2 && domainParts.allSatisfy { !$0.isEmpty }
    }
}
