import Foundation

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case free
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free:
            return "Free"
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }

    var productId: String? {
        switch self {
        case .free:
            return nil
        case .monthly:
            return "memoryink_monthly"
        case .yearly:
            return "memoryink_yearly"
        }
    }

    var dailyNarrativeLimit: Int {
        switch self {
        case .free:
            return 3
        case .monthly:
            return 15
        case .yearly:
            return 30
        }
    }

    var allowsMetadataSync: Bool {
        self != .free
    }

    var allowsVoiceJournaling: Bool {
        self != .free
    }

    var allowsPremiumRecapStyles: Bool {
        self != .free
    }
}

enum PremiumEntitlement {
    static let id = "premium"
    static let defaultOfferingId = "default"
    static let monthlyProductId = "memoryink_monthly"
    static let yearlyProductId = "memoryink_yearly"
}
