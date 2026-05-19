import Combine
import Foundation

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published private(set) var plan: SubscriptionPlan
    @Published private(set) var hasPremiumEntitlement: Bool
    @Published private(set) var isRevenueCatConfigured: Bool
    @Published private(set) var isPaywallEligible: Bool

    private enum Key {
        static let plan = "subscription_plan"
        static let firstEmotionalMomentSeen = "first_emotional_moment_seen"
    }

    private let revenueCatService: RevenueCatService
    private let defaults: UserDefaults

    init(
        revenueCatService: RevenueCatService = RevenueCatService(),
        defaults: UserDefaults = .standard
    ) {
        self.revenueCatService = revenueCatService
        self.defaults = defaults
        self.isRevenueCatConfigured = revenueCatService.isConfigured

        let storedPlan = defaults.string(forKey: Key.plan).flatMap(SubscriptionPlan.init(rawValue:)) ?? .free
        self.plan = storedPlan
        self.hasPremiumEntitlement = storedPlan != .free
        self.isPaywallEligible = defaults.bool(forKey: Key.firstEmotionalMomentSeen)
    }

    var dailyNarrativeLimit: Int {
        plan.dailyNarrativeLimit
    }

    var canUseMetadataSync: Bool {
        hasPremiumEntitlement && plan.allowsMetadataSync
    }

    var canUseVoiceJournaling: Bool {
        hasPremiumEntitlement && plan.allowsVoiceJournaling
    }

    var canUsePremiumRecapStyles: Bool {
        hasPremiumEntitlement && plan.allowsPremiumRecapStyles
    }

    func refreshEntitlements() async {
        guard revenueCatService.isConfigured else { return }

        do {
            let customerState = try await revenueCatService.currentCustomerState()
            apply(customerState)
        } catch {
            return
        }
    }

    func loadDefaultOffering() async {
        await revenueCatService.loadDefaultOffering()
    }

    func markFirstEmotionalMomentSeen() {
        defaults.set(true, forKey: Key.firstEmotionalMomentSeen)
        isPaywallEligible = true
    }

    func purchase(_ plan: SubscriptionPlan) async {
        guard let productId = plan.productId else { return }

        log("Purchase button tapped: \(plan.title) (\(productId))")

        do {
            let customerState = try await revenueCatService.purchase(productId: productId)
            apply(customerState)
            log("Purchase success: \(plan.title), premiumActive=\(customerState.hasPremiumEntitlement)")
        } catch {
            log("Purchase failure: \(plan.title), error=\(error.localizedDescription)")
            return
        }
    }

    func restorePurchases() async {
        do {
            let customerState = try await revenueCatService.restorePurchases()
            apply(customerState)
        } catch {
            return
        }
    }

    private func apply(_ customerState: RevenueCatCustomerState) {
        hasPremiumEntitlement = customerState.hasPremiumEntitlement
        plan = customerState.preferredPlan

        defaults.set(plan.rawValue, forKey: Key.plan)
    }

    private func log(_ message: String) {
        print("[MemoryInk][RevenueCat] \(message)")
    }
}
