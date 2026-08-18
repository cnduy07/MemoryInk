import CoreGraphics

enum MemoryInkSpacing {
    static let screenHorizontal: CGFloat = 20
    static let cardGap: CGFloat = 32
    static let cardPadding: CGFloat = 18
    static let cardCornerRadius: CGFloat = 22

    /// Gap between major sections within a screen (headers, cards, groups).
    /// Matches the most common top-level VStack spacing already in use.
    static let sectionGap: CGFloat = 24

    /// Corner radius scale. Screens currently hardcode values from 10–26pt ad hoc;
    /// new UI should pick from this scale instead of a bespoke number.
    /// Small: chips, pills, compact controls, capsule-adjacent shapes.
    static let radiusSmall: CGFloat = 14
    /// Medium: buttons, text inputs, list rows, standard containers.
    static let radiusMedium: CGFloat = 18
    /// Large: hero cards, photo frames, prominent containers.
    /// (Photo/card frames that must match Timeline exactly should keep using
    /// `cardCornerRadius` — this is for other large containers.)
    static let radiusLarge: CGFloat = 24
}
