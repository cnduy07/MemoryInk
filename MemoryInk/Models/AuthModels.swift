import Foundation

enum AuthProvider: String, CaseIterable, Identifiable {
    case apple
    case email

    var id: String { rawValue }

    var title: String {
        switch self {
        case .apple:
            return "Sign in with Apple"
        case .email:
            return "Email"
        }
    }
}

struct AccountSession: Equatable {
    let userId: String
    let provider: AuthProvider
    let email: String?
}

enum AuthState: Equatable {
    case signedOut
    case signedIn(AccountSession)
    case unavailableMissingConfig
    case error(String)
}

enum AuthMode {
    case signIn
    case createAccount
}

enum AuthResult {
    case success
    case failure(String)
}
