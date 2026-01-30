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
            return "Ralph Wiggum PRD"
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
            Respond with a PRD in markdown format. Start with a title heading "# PRD - [Feature Name]".
            Organize tasks into sections using ## headings (e.g., "## Project Setup", "## iOS Implementation - Core Features").
            List tasks as checkboxes using the format "- [ ] [Task description]".
            After the task sections, include a "## Usage" section with examples of how to run/use the feature.
            After that, include a "## Technical Notes" section with implementation details, constraints, and considerations.
            Do not include code fences or JSON formatting.
            """
        case .markdown:
            return "Respond in Markdown suitable for rich text rendering. Use headings and lists where helpful."
        }
    }

    public var formatInstruction: String {
        switch self {
        case .plainText:
            return "Return only plain text."
        case .ralphWiggumPRD:
            return """
            Return ONLY a PRD in markdown format with the following structure:
            - Title heading: "# PRD - [Feature Name]"
            - Multiple sections with ## headings for task categories
            - Tasks as checkboxes: "- [ ] [Task description]"
            - A "## Usage" section with command examples
            - A "## Technical Notes" section with implementation details
            Do not add code fences or JSON formatting.
            """
        case .markdown:
            return "Return only markdown/rich text."
        }
    }
}
