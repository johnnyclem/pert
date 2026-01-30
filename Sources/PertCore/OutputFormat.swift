import Foundation

public enum OutputFormat: String, CaseIterable, Identifiable, Codable {
    case plainText
    case ralphWiggumPRD
    case markdown

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .plainText:
            return "Plain text"
        case .ralphWiggumPRD:
            return "Ralph Wiggum PRD (md task list format)"
        case .markdown:
            return "Markdown/Rich text"
        }
    }

    public var systemInstruction: String {
        switch self {
        case .plainText:
            return "Respond in plain text only. Do not use Markdown, JSON, or code fences."
        case .ralphWiggumPRD:
            return """
            Respond with only a JSON array of task objects. Each object must include:
            category (string), description (string), dependencies (array of integers), status (string), notes (string).
            Do not include any additional text, Markdown, or code fences.
            """
        case .markdown:
            return "Respond in Markdown suitable for rich text rendering. Use headings and lists where helpful."
        }
    }
}
