import Combine
import Foundation

enum AnalyticsEvent: String, CaseIterable {
    case firstEntryCreated = "first_entry_created"
    case firstNarrativeGenerated = "first_narrative_generated"
    case firstRecapOpened = "first_recap_opened"
    case entriesPerWeek = "entries_per_week"
    case onThisDayOpened = "on_this_day_opened"
    case recapOpened = "recap_opened"
    case timelineSessionStarted = "timeline_session_started"
    case paywallShown = "paywall_shown"
    case trialStarted = "trial_started"
    case monthlyConverted = "monthly_converted"
    case yearlyConverted = "yearly_converted"
}

struct MixpanelConfiguration {
    let token: String?

    static var placeholder: MixpanelConfiguration {
        MixpanelConfiguration(
            token: Bundle.main.object(forInfoDictionaryKey: "MemoryInkMixpanelToken") as? String
        )
    }

    var isConfigured: Bool {
        token?.isEmpty == false
    }
}

final class AnalyticsService: ObservableObject {
    private let configuration: MixpanelConfiguration

    init(configuration: MixpanelConfiguration = .placeholder) {
        self.configuration = configuration
    }

    var isConfigured: Bool {
        configuration.isConfigured
    }

    func track(_ event: AnalyticsEvent, properties: [String: String] = [:]) {
        guard isConfigured else { return }

        // Placeholder until Mixpanel SDK is approved and configured.
        _ = (event, properties)
    }
}
