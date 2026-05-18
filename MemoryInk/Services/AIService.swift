import Foundation

struct AIServiceConfiguration {
    let baseURL: URL?
    let apiKey: String?

    static var placeholder: AIServiceConfiguration {
        let baseURLString = Bundle.main.object(forInfoDictionaryKey: "MemoryInkAIBaseURL") as? String
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "MemoryInkAIAPIKey") as? String

        return AIServiceConfiguration(
            baseURL: baseURLString.flatMap(URL.init(string:)),
            apiKey: apiKey
        )
    }

    var isConfigured: Bool {
        baseURL != nil
    }
}

enum AIServiceError: Error, Equatable {
    case notConfigured
    case rateLimitReached
    case networkUnavailable
    case timeout
    case validationFailed
    case serviceUnavailable
    case malformedResponse

    var userMessage: String {
        switch self {
        case .notConfigured, .networkUnavailable:
            return "Your memory is saved."
        case .timeout:
            return "Narrative generation is taking longer than expected."
        case .rateLimitReached:
            return "You've reached today's AI limit."
        case .validationFailed, .serviceUnavailable, .malformedResponse:
            return "Couldn't generate a narrative right now."
        }
    }

    var shouldRetrySilently: Bool {
        switch self {
        case .networkUnavailable, .serviceUnavailable:
            return true
        case .notConfigured, .timeout, .rateLimitReached, .validationFailed, .malformedResponse:
            return false
        }
    }
}

final class AIService {
    private let configuration: AIServiceConfiguration
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        configuration: AIServiceConfiguration = .placeholder,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    var isConfigured: Bool {
        configuration.isConfigured
    }

    func generateNarrative(_ request: NarrativeGenerationRequest) async throws -> NarrativeGenerationData {
        let response: NarrativeGenerationResponse = try await post(
            request,
            path: "/v1/narratives/generate"
        )

        guard response.success, let data = response.data else {
            throw mapError(response.error)
        }

        return data
    }

    func generateRecap(_ request: RecapGenerationRequest) async throws -> RecapGenerationData {
        let response: RecapGenerationResponse = try await post(
            request,
            path: "/v1/recaps/generate"
        )

        guard response.success, let data = response.data else {
            throw mapError(response.error)
        }

        return data
    }

    private func post<Request: Encodable, Response: Decodable>(
        _ body: Request,
        path: String
    ) async throws -> Response {
        guard let baseURL = configuration.baseURL else {
            throw AIServiceError.notConfigured
        }

        let url = baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let apiKey = configuration.apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try encoder.encode(body)

        return try await performWithRetry(request)
    }

    private func performWithRetry<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        var lastError: Error?

        for attempt in 0..<3 {
            do {
                return try await perform(request)
            } catch let error as AIServiceError {
                lastError = error

                guard error.shouldRetrySilently, attempt < 2 else {
                    throw error
                }

                try await Task.sleep(nanoseconds: UInt64(500_000_000 * (attempt + 1)))
            } catch {
                lastError = error
                throw error
            }
        }

        throw lastError ?? AIServiceError.serviceUnavailable
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.malformedResponse
            }

            switch httpResponse.statusCode {
            case 200..<300:
                return try decoder.decode(Response.self, from: data)
            case 408, 504:
                throw AIServiceError.timeout
            case 429:
                throw AIServiceError.rateLimitReached
            case 400, 422:
                throw AIServiceError.validationFailed
            default:
                throw AIServiceError.serviceUnavailable
            }
        } catch let error as AIServiceError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw AIServiceError.timeout
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost:
                throw AIServiceError.networkUnavailable
            default:
                throw AIServiceError.serviceUnavailable
            }
        } catch {
            throw AIServiceError.malformedResponse
        }
    }

    private func mapError(_ payload: AIServiceErrorPayload?) -> AIServiceError {
        switch payload?.code {
        case .rateLimitReached:
            return .rateLimitReached
        case .networkUnavailable:
            return .networkUnavailable
        case .aiTimeout:
            return .timeout
        case .validationFailed:
            return .validationFailed
        case .serviceUnavailable:
            return .serviceUnavailable
        case .none:
            return .malformedResponse
        }
    }
}
