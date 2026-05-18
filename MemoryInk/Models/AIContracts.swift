import Foundation

struct NarrativeGenerationRequest: Codable {
    let entryId: UUID
    let sceneLabels: [String]
    let mood: String
    let note: String?
    let narrativeStyle: String
    let locale: String

    enum CodingKeys: String, CodingKey {
        case entryId = "entry_id"
        case sceneLabels = "scene_labels"
        case mood
        case note
        case narrativeStyle = "narrative_style"
        case locale
    }
}

struct NarrativeGenerationData: Codable {
    let narrative: String
    let generatedAt: Date
    let model: String
    let cached: Bool

    enum CodingKeys: String, CodingKey {
        case narrative
        case generatedAt = "generated_at"
        case model
        case cached
    }
}

struct NarrativeGenerationResponse: Codable {
    let success: Bool
    let data: NarrativeGenerationData?
    let error: AIServiceErrorPayload?
}

struct RecapGenerationRequest: Codable {
    let recapId: UUID
    let entryIds: [UUID]
    let memories: [RecapMemoryPayload]
    let locale: String

    enum CodingKeys: String, CodingKey {
        case recapId = "recap_id"
        case entryIds = "entry_ids"
        case memories
        case locale
    }
}

struct RecapMemoryPayload: Codable {
    let entryId: UUID
    let createdAt: Date
    let sceneLabels: [String]
    let mood: String
    let note: String?
    let aiNarrative: String?

    enum CodingKeys: String, CodingKey {
        case entryId = "entry_id"
        case createdAt = "created_at"
        case sceneLabels = "scene_labels"
        case mood
        case note
        case aiNarrative = "ai_narrative"
    }
}

struct RecapGenerationData: Codable {
    let recap: String
    let generatedAt: Date
    let model: String
    let cached: Bool

    enum CodingKeys: String, CodingKey {
        case recap
        case generatedAt = "generated_at"
        case model
        case cached
    }
}

struct RecapGenerationResponse: Codable {
    let success: Bool
    let data: RecapGenerationData?
    let error: AIServiceErrorPayload?
}

struct AIServiceErrorPayload: Codable {
    let code: AIServiceErrorCode
    let message: String
}

enum AIServiceErrorCode: String, Codable {
    case rateLimitReached = "RATE_LIMIT_REACHED"
    case networkUnavailable = "NETWORK_UNAVAILABLE"
    case aiTimeout = "AI_TIMEOUT"
    case validationFailed = "VALIDATION_FAILED"
    case serviceUnavailable = "SERVICE_UNAVAILABLE"
}
