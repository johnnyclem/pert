import Foundation

public struct LLMConfig: Codable {
    public let baseURL: String
    public let apiKey: String
    public let modelName: String?
    
    public init(baseURL: String, apiKey: String, modelName: String? = nil) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.modelName = modelName
    }
}



public struct OutputValidationResult {
    public let outputText: String
    public let errorMessage: String?
    public let rawResponse: String?
    public let isValid: Bool
}

public enum OutputFormatValidator {
    public static func validate(response: String, format: OutputFormat) -> OutputValidationResult {
        let sanitized = sanitize(response)
        switch format {
        case .plainText, .markdown:
            return OutputValidationResult(outputText: sanitized, errorMessage: nil, rawResponse: sanitized, isValid: true)
        case .ralphWiggumPRD:
            guard let jsonCandidate = extractJSONArray(from: sanitized) else {
                let message = "Formatting error: Expected a JSON array payload."
                return OutputValidationResult(
                    outputText: "\(message)\n\nRaw response (sanitized):\n\(sanitized)",
                    errorMessage: message,
                    rawResponse: sanitized,
                    isValid: false
                )
            }

            do {
                let data = Data(jsonCandidate.utf8)
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                guard let array = jsonObject as? [Any] else {
                    let message = "Formatting error: JSON payload is not an array."
                    return OutputValidationResult(
                        outputText: "\(message)\n\nRaw response (sanitized):\n\(jsonCandidate)",
                        errorMessage: message,
                        rawResponse: jsonCandidate,
                        isValid: false
                    )
                }

                for (index, element) in array.enumerated() {
                    guard let item = element as? [String: Any] else {
                        let message = "Formatting error: Item \(index) is not an object."
                        return OutputValidationResult(
                            outputText: "\(message)\n\nRaw response (sanitized):\n\(jsonCandidate)",
                            errorMessage: message,
                            rawResponse: jsonCandidate,
                            isValid: false
                        )
                    }

                    let requiredKeys = ["category", "description", "dependencies", "status", "notes"]
                    for key in requiredKeys where item[key] == nil {
                        let message = "Formatting error: Item \(index) missing key '\(key)'."
                        return OutputValidationResult(
                            outputText: "\(message)\n\nRaw response (sanitized):\n\(jsonCandidate)",
                            errorMessage: message,
                            rawResponse: jsonCandidate,
                            isValid: false
                        )
                    }

                    guard item["category"] is String,
                          item["description"] is String,
                          item["status"] is String,
                          item["notes"] is String else {
                        let message = "Formatting error: Item \(index) has invalid string fields."
                        return OutputValidationResult(
                            outputText: "\(message)\n\nRaw response (sanitized):\n\(jsonCandidate)",
                            errorMessage: message,
                            rawResponse: jsonCandidate,
                            isValid: false
                        )
                    }

                    guard let dependencies = item["dependencies"] as? [Any],
                          dependencies.allSatisfy({ $0 is Int || $0 is NSNumber }) else {
                        let message = "Formatting error: Item \(index) dependencies must be an array of integers."
                        return OutputValidationResult(
                            outputText: "\(message)\n\nRaw response (sanitized):\n\(jsonCandidate)",
                            errorMessage: message,
                            rawResponse: jsonCandidate,
                            isValid: false
                        )
                    }
                }

                let normalizedData = try JSONSerialization.data(withJSONObject: array, options: [.prettyPrinted, .sortedKeys])
                let normalizedOutput = String(data: normalizedData, encoding: .utf8) ?? jsonCandidate
                return OutputValidationResult(outputText: normalizedOutput, errorMessage: nil, rawResponse: normalizedOutput, isValid: true)
            } catch {
                let message = "Formatting error: Invalid JSON payload."
                return OutputValidationResult(
                    outputText: "\(message)\n\nRaw response (sanitized):\n\(jsonCandidate)",
                    errorMessage: message,
                    rawResponse: jsonCandidate,
                    isValid: false
                )
            }
        }
    }

    private static func sanitize(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            if CharacterSet.controlCharacters.contains(scalar) {
                if scalar == "\n" || scalar == "\r" || scalar == "\t" {
                    scalars.append(scalar)
                }
            } else {
                scalars.append(scalar)
            }
        }
        return String(scalars)
    }

    private static func extractJSONArray(from text: String) -> String? {
        if let regex = try? NSRegularExpression(pattern: "```(?:json)?\\s*([\\s\\S]*?)\\s*```", options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            let fenced = String(text[range])
            if fenced.contains("[") && fenced.contains("]") {
                return fenced
            }
        }

        guard let start = text.firstIndex(of: "["),
              let end = text.lastIndex(of: "]"),
              start < end else {
            return nil
        }
        return String(text[start...end])
    }
}

public enum LLMError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
}

public class LLMService {
    
    public init() {}
    
    // Check for local availability (LMStudio or Ollama)
    // Returns the config if found, nil otherwise
    public func detectLocalService() async -> LLMConfig? {
        // Check LMStudio
        if await checkService(url: "http://localhost:1234/v1/models") {
            return LLMConfig(baseURL: "http://localhost:1234/v1", apiKey: "lm-studio")
        }
        
        // Check Ollama
        if await checkService(url: "http://localhost:11434/api/tags") { // Ollama check
             // Ollama v1 compat
            return LLMConfig(baseURL: "http://localhost:11434/v1", apiKey: "ollama")
        }
        
        return nil
    }
    
    private func checkService(url: String) async -> Bool {
        guard let url = URL(string: url) else { return false }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0 // Fast timeout check
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return true
            }
        } catch {
            return false
        }
        return false
    }
    
    public func fetchModels(config: LLMConfig) async throws -> [String] {
        guard let url = URL(string: "\(config.baseURL)/models") else { return [] }
        
        var request = URLRequest(url: url)
        request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Basic parsing structure for OpenAI compatible /models endpoint
        struct ModelResponse: Decodable {
            struct Model: Decodable {
                let id: String
            }
            let data: [Model]
        }
        
        // For Ollama it might be slightly different depending on if using v1 compat or native
        // Assuming v1 compat for simplicity as we set baseURL to .../v1
        
        let response = try JSONDecoder().decode(ModelResponse.self, from: data)
        return response.data.map { $0.id }
    }
    
    // Naive selection logic - in a real app we'd parse param size from name or metadata if available
    public func selectBestModel(models: [String]) -> String {
        // Heuristic: look for explicit size strings.
        // User wants "largest (up to and including 30B parameter) model available"
        // We prioritize 30b down to 3b. We exclude >30b to respect the "up to" constraint.
        
        let sizePriorities = ["30b", "27b", "20b", "14b", "13b", "11b", "8b", "7b", "3b"]
        
        for size in sizePriorities {
            if let match = models.first(where: { $0.lowercased().contains(size) }) {
                return match
            }
        }
        
        // If no size found, or only larger models found (unlikely to be the only ones), fallback.
        // If we want to be strict, we might want to filter out known large sizes (70b), but for now this priority list prefers valid ones.
        return models.first ?? "gpt-3.5-turbo" // Fallback
    }

    public func conditionPrompt(_ userPrompt: String, outputFormat: OutputFormat, config: LLMConfig, model: String) async throws -> String {
        //let systemInstruction = """
        //[SYSTEM INSTRUCTION: DEEP ANALYSIS MODE] You are an expert AI system designed for one-shot success. Your task is to interpret the user's following request, identify the implicit intent, and execute it with maximum detail and precision. Analyze: Break down the request to understand the core goal. Expand: Internally generate a more detailed version of the user's prompt that includes specific constraints, expert context, and logical steps required for a 10/10 quality response. Execute: Provide the final output based on this optimized internal prompt. Do not ask clarifying questions; assume the most effective context and proceed.
        //"""

        let systemInstruction = """
        You are an expert assistant. Follow the output format instructions strictly.
        \(outputFormat.formatInstruction)
        Do not include explanations, code fences, or additional commentary.

        [INSTRUCTION: STEP-BY-STEP REASONING] I am going to give you a prompt. Before providing the final answer, I want you to "think out loud" effectively. First, draft a comprehensive plan for how to solve the prompt, ensuring you cover edge cases and required depth. Second, critique that plan to find potential flaws or missing details. Third, execute the refined plan. Your goal is a highly detailed, error-free output that requires no further iteration.
        \(outputFormat.systemInstruction)
        """        
        // let finalPrompt = "[USER REQUEST]: \(userPrompt)" // We will send this as user message
        
        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemInstruction],
                ["role": "user", "content": "[USER REQUEST]: \(userPrompt)"]
            ],
            "temperature": 0.7
        ]
        
        guard let url = URL(string: "\(config.baseURL)/chat/completions") else { throw LLMError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.timeoutInterval = 120 // Allow thinking time
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorText = String(data: data, encoding: .utf8) {
                throw LLMError.serverError("Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0) - \(errorText)")
            }
             throw LLMError.serverError("Unknown server error")
        }
        
        struct ChatCompletionResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }
        
        do {
            let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            return completion.choices.first?.message.content ?? ""
        } catch {
             throw LLMError.decodingError
        }
    }
}
