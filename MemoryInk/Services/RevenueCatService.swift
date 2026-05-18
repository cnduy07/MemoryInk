import Foundation

struct RevenueCatConfiguration {
    let apiKey: String?
    let entitlementId: String
    let productIds: [String]

    static var placeholder: RevenueCatConfiguration {
        RevenueCatConfiguration(
            apiKey: Bundle.main.object(forInfoDictionaryKey: "MemoryInkRevenueCatAPIKey") as? String,
            entitlementId: PremiumEntitlement.id,
            productIds: [
                PremiumEntitlement.monthlyProductId,
                PremiumEntitlement.yearlyProductId
            ]
        )
    }

    var isConfigured: Bool {
        apiKey?.isEmpty == false
    }
}

final class RevenueCatService {
    private let configuration: RevenueCatConfiguration

    init(configuration: RevenueCatConfiguration = .placeholder) {
        self.configuration = configuration
    }

    var isConfigured: Bool {
        configuration.isConfigured
    }

    func currentEntitlements() async -> Set<String> {
        guard isConfigured else { return [] }

        // Placeholder until the RevenueCat SDK is approved and configured.
        return []
    }

    func purchase(productId: String) async throws -> Set<String> {
        guard configuration.productIds.contains(productId) else {
            return []
        }

        // Placeholder until the RevenueCat SDK is approved and configured.
        return []
    }

    func restorePurchases() async -> Set<String> {
        // Placeholder until the RevenueCat SDK is approved and configured.
        return []
    }
}
