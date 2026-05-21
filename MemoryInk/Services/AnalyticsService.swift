import Foundation
import SwiftUI

enum AnalyticsEvent: String {
    case firstEntryCreated
    case firstNarrativeGenerated
    case firstRecapOpened
    case entriesPerWeek
    case onThisDayOpened
    case recapOpened
    case timelineSessionStarted
    case paywallShown
    case trialStarted
    case monthlyConverted
    case yearlyConverted
}

final class AnalyticsService: ObservableObject {
    func track(_ event: AnalyticsEvent, properties: [String: String] = [:]) {
        // No analytics. Intentional product decision.
        _ = (event, properties)
    }
}
