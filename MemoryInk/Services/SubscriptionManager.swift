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
        let entitlements = await revenueCatService.currentEntitlements()
        apply(entitlements: entitlements)
    }

    func markFirstEmotionalMomentSeen() {
        defaults.set(true, forKey: Key.firstEmotionalMomentSeen)
        isPaywallEligible = true
    }

    func purchase(_ plan: SubscriptionPlan) async {
        guard let productId = plan.productId else { return }

        do {
            let entitlements = try await revenueCatService.purchase(productId: productId)
            apply(entitlements: entitlements)
        } catch {
            apply(entitlements: [])
        }
    }

    func restorePurchases() async {
        let entitlements = await revenueCatService.restorePurchases()
        apply(entitlements: entitlements)
    }

    private func apply(entitlements: Set<String>) {
        hasPremiumEntitlement = entitlements.contains(PremiumEntitlement.id)

        if hasPremiumEntitlement {
            plan = .monthly
        } else {
            plan = .free
        }

        defaults.set(plan.rawValue, forKey: Key.plan)
    }
}
