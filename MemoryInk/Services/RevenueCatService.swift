import Foundation

#if canImport(RevenueCat)
import RevenueCat
#endif

struct RevenueCatConfiguration {
    let apiKey: String?
    let apiKeySource: String?
    let entitlementId: String
    let offeringId: String
    let productIds: [String]

    static var placeholder: RevenueCatConfiguration {
        let resolvedAPIKey = Self.resolvedAPIKey()

        return RevenueCatConfiguration(
            apiKey: resolvedAPIKey.value,
            apiKeySource: resolvedAPIKey.source,
            entitlementId: PremiumEntitlement.id,
            offeringId: PremiumEntitlement.defaultOfferingId,
            productIds: [
                PremiumEntitlement.monthlyProductId,
                PremiumEntitlement.yearlyProductId
            ]
        )
    }

    var isConfigured: Bool {
        apiKey?.isEmpty == false
    }

    private static func resolvedAPIKey() -> (value: String?, source: String?) {
        [
            "RevenueCatAPIKey",
            "INFOPLIST_KEY_RevenueCatAPIKey"
        ]
        .lazy
        .compactMap { key -> (String, String)? in
            guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
                return nil
            }

            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedValue.isEmpty else {
                return nil
            }

            return (trimmedValue, key)
        }
        .first
        .map { (value: $0.0, source: $0.1) } ?? (nil, nil)
    }
}

struct RevenueCatCustomerState {
    let activeEntitlements: Set<String>
    let activeProductIds: Set<String>

    static let empty = RevenueCatCustomerState(
        activeEntitlements: [],
        activeProductIds: []
    )

    var hasPremiumEntitlement: Bool {
        activeEntitlements.contains(PremiumEntitlement.id)
    }

    var preferredPlan: SubscriptionPlan {
        guard hasPremiumEntitlement else {
            return .free
        }

        if activeProductIds.contains(PremiumEntitlement.yearlyProductId) {
            return .yearly
        }

        if activeProductIds.contains(PremiumEntitlement.monthlyProductId) || hasPremiumEntitlement {
            return .monthly
        }

        return .free
    }
}

enum RevenueCatServiceError: LocalizedError {
    case notConfigured
    case sdkUnavailable
    case offeringUnavailable
    case packageUnavailable

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "RevenueCat is not configured."
        case .sdkUnavailable:
            return "RevenueCat SDK is unavailable."
        case .offeringUnavailable:
            return "RevenueCat offering default could not be loaded."
        case .packageUnavailable:
            return "RevenueCat package could not be found."
        }
    }
}

final class RevenueCatService {
    private let configuration: RevenueCatConfiguration

#if canImport(RevenueCat)
    private var cachedOffering: Offering?
#endif

    init(configuration: RevenueCatConfiguration = .placeholder) {
        self.configuration = configuration
        configurePurchasesIfPossible()
    }

    var isConfigured: Bool {
        configuration.isConfigured && isSDKAvailable
    }

    var isSDKAvailable: Bool {
#if canImport(RevenueCat)
        return true
#else
        return false
#endif
    }

    func currentCustomerState() async throws -> RevenueCatCustomerState {
        guard isConfigured else { throw RevenueCatServiceError.notConfigured }

#if canImport(RevenueCat)
        let customerInfo = try await Purchases.shared.customerInfo()
        return customerState(from: customerInfo)
#else
        throw RevenueCatServiceError.sdkUnavailable
#endif
    }

    func loadDefaultOffering() async {
        guard isConfigured else {
            log("Skipping default offering load because RevenueCat is not configured.")
            return
        }

#if canImport(RevenueCat)
        do {
            cachedOffering = try await defaultOffering()
        } catch {
            log("Failed to load offering \"\(configuration.offeringId)\": \(error.localizedDescription)")
        }
#endif
    }

    func purchase(productId: String) async throws -> RevenueCatCustomerState {
        log("Purchase attempt started for productId=\(productId)")

        guard configuration.productIds.contains(productId), isConfigured else {
            log("Purchase attempt blocked for productId=\(productId): \(RevenueCatServiceError.notConfigured.localizedDescription)")
            throw RevenueCatServiceError.notConfigured
        }

#if canImport(RevenueCat)
        let offering = try await defaultOffering()
        guard let package = package(for: productId, in: offering) else {
            log("Purchase failed before StoreKit sheet for productId=\(productId): \(RevenueCatServiceError.packageUnavailable.localizedDescription)")
            throw RevenueCatServiceError.packageUnavailable
        }

        let result = try await Purchases.shared.purchase(package: package)
        log("Purchase success for productId=\(productId), premiumActive=\(result.customerInfo.entitlements[configuration.entitlementId]?.isActive == true)")
        return customerState(from: result.customerInfo)
#else
        log("Purchase failed for productId=\(productId): \(RevenueCatServiceError.sdkUnavailable.localizedDescription)")
        throw RevenueCatServiceError.sdkUnavailable
#endif
    }

    func restorePurchases() async throws -> RevenueCatCustomerState {
        guard isConfigured else {
            throw RevenueCatServiceError.notConfigured
        }

#if canImport(RevenueCat)
        let customerInfo = try await Purchases.shared.restorePurchases()
        return customerState(from: customerInfo)
#else
        throw RevenueCatServiceError.sdkUnavailable
#endif
    }

    private func configurePurchasesIfPossible() {
        guard let apiKey = configuration.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines),
              !apiKey.isEmpty else {
            log("RevenueCatAPIKey source: none")
            log("RevenueCatAPIKey exists: false")
            log("Purchases configured: false")
            return
        }

        log("RevenueCatAPIKey source: \(configuration.apiKeySource ?? "unknown")")
        log("RevenueCatAPIKey exists: true")

#if canImport(RevenueCat)
        if !Purchases.isConfigured {
            Purchases.configure(withAPIKey: apiKey)
        }

        log("Purchases configured: \(Purchases.isConfigured)")
#else
        log("Purchases configured: false")
#endif
    }

#if canImport(RevenueCat)
    private func defaultOffering() async throws -> Offering {
        if let cachedOffering {
            logOffering(cachedOffering)
            return cachedOffering
        }

        let offerings = try await Purchases.shared.offerings()
        guard let offering = offerings.offering(identifier: configuration.offeringId) else {
            log("Offering \"\(configuration.offeringId)\" loaded: false")
            throw RevenueCatServiceError.offeringUnavailable
        }

        cachedOffering = offering
        logOffering(offering)
        return offering
    }

    private func package(for productId: String, in offering: Offering) -> Package? {
        if productId == PremiumEntitlement.monthlyProductId, let monthlyPackage = offering.monthly {
            return monthlyPackage
        }

        if productId == PremiumEntitlement.yearlyProductId, let annualPackage = offering.annual {
            return annualPackage
        }

        return offering.availablePackages.first {
            $0.storeProduct.productIdentifier == productId
        }
    }

    private func customerState(from customerInfo: CustomerInfo) -> RevenueCatCustomerState {
        let activeEntitlements = customerInfo.entitlements[configuration.entitlementId]?.isActive == true
            ? Set([configuration.entitlementId])
            : []

        return RevenueCatCustomerState(
            activeEntitlements: activeEntitlements,
            activeProductIds: Set(customerInfo.activeSubscriptions)
        )
    }

    private func logOffering(_ offering: Offering) {
        let monthlyIdentifier = offering.monthly.map {
            "\($0.identifier) / \($0.storeProduct.productIdentifier)"
        } ?? "missing"
        let annualIdentifier = offering.annual.map {
            "\($0.identifier) / \($0.storeProduct.productIdentifier)"
        } ?? "missing"

        log("Offering \"\(configuration.offeringId)\" loaded: true")
        log("Packages loaded: \(offering.availablePackages.count)")
        log("Monthly package identifier: \(monthlyIdentifier)")
        log("Yearly package identifier: \(annualIdentifier)")
    }
#endif

    private func log(_ message: String) {
        print("[MemoryInk][RevenueCat] \(message)")
    }
}
