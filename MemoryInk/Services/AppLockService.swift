import Foundation
import LocalAuthentication

/// Keeps the journal behind Face ID / Touch ID / the device passcode when the user asks for it.
///
/// Off by default — MemoryInk is private, not paranoid, and a lock the user didn't ask for is a
/// wall between them and their own memories. Nothing here talks to the network, and no biometric
/// data is ever seen by the app: `LAContext` only ever answers yes or no.
@MainActor
final class AppLockService: ObservableObject {
    /// True when the journal is currently hidden behind the lock screen.
    @Published private(set) var isLocked: Bool
    @Published private(set) var isAuthenticating = false
    /// Set when an attempt fails for a reason worth telling the user about.
    @Published var message: String?

    @Published private(set) var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Self.enabledKey) }
    }

    private static let enabledKey = "app_lock_enabled"
    private let defaults: UserDefaults
    private let contextProvider: () -> LAContext

    init(defaults: UserDefaults = .standard, contextProvider: @escaping () -> LAContext = { LAContext() }) {
        self.defaults = defaults
        self.contextProvider = contextProvider

        let enabled = defaults.bool(forKey: Self.enabledKey)
        self.isEnabled = enabled
        // Start locked when the feature is on, so the journal is never briefly visible at launch.
        self.isLocked = enabled
    }

    /// Whether this device can lock at all (biometrics *or* a passcode).
    var isAvailable: Bool {
        contextProvider().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    /// "Face ID", "Touch ID", or a neutral fallback — used in UI copy so it matches the device.
    var biometryName: String {
        let context = contextProvider()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)

        switch context.biometryType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "your passcode"
        }
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        // Turning it off shouldn't leave the user staring at a lock screen.
        if !enabled {
            isLocked = false
            message = nil
        }
    }

    /// Called when the app leaves the foreground.
    func lockIfNeeded() {
        guard isEnabled else { return }
        isLocked = true
    }

    func unlock() async {
        guard isLocked, !isAuthenticating else { return }

        isAuthenticating = true
        message = nil
        defer { isAuthenticating = false }

        let context = contextProvider()
        context.localizedFallbackTitle = "Use Passcode"

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock your journal"
            )
            if success {
                isLocked = false
            }
        } catch {
            // Deliberately quiet: a cancelled prompt isn't an error worth a message, and we
            // never surface the underlying framework error text.
            let code = (error as NSError).code
            let userStopped = code == LAError.userCancel.rawValue
                || code == LAError.systemCancel.rawValue
                || code == LAError.appCancel.rawValue

            message = userStopped ? nil : "Couldn't unlock. Try again."
        }
    }
}
