enum NarrativeStyle: String, CaseIterable, Identifiable {
    case warm
    case minimal
    case reflective

    var id: String { rawValue }
}
