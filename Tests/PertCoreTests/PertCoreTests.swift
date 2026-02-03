import XCTest
@testable import PertCore

final class PertCoreTests: XCTestCase {

    // MARK: - OutputFormat Tests

    func testOutputFormatPlainTextDisplayName() {
        XCTAssertEqual(OutputFormat.plainText.displayName, "Plain text")
    }

    func testOutputFormatRalphWiggumPRDDisplayName() {
        XCTAssertEqual(OutputFormat.ralphWiggumPRD.displayName, "Ralph Wiggum PRD")
    }

    func testOutputFormatMarkdownDisplayName() {
        XCTAssertEqual(OutputFormat.markdown.displayName, "Markdown/Rich text")
    }

    func testOutputFormatAllCasesCount() {
        XCTAssertEqual(OutputFormat.allCases.count, 3)
    }

    func testOutputFormatIdentifiable() {
        for format in OutputFormat.allCases {
            XCTAssertEqual(format.id, format.rawValue)
        }
    }

    func testOutputFormatSystemInstructionNonEmpty() {
        for format in OutputFormat.allCases {
            XCTAssertFalse(format.systemInstruction.isEmpty)
        }
    }

    func testOutputFormatFormatInstructionNonEmpty() {
        for format in OutputFormat.allCases {
            XCTAssertFalse(format.formatInstruction.isEmpty)
        }
    }

    // MARK: - OutputFormatValidator Tests

    func testValidatePlainTextAlwaysValid() {
        let result = OutputFormatValidator.validate(response: "Hello world", format: .plainText)
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
        XCTAssertEqual(result.outputText, "Hello world")
    }

    func testValidateMarkdownAlwaysValid() {
        let result = OutputFormatValidator.validate(response: "# Title\n- item", format: .markdown)
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testValidateRalphWiggumPRDValid() {
        let validPRD = """
        # PRD - Test Feature
        ## Section One
        - [ ] Task one
        - [ ] Task two
        """
        let result = OutputFormatValidator.validate(response: validPRD, format: .ralphWiggumPRD)
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func testValidateRalphWiggumPRDMissingTitle() {
        let invalidPRD = """
        ## Section One
        - [ ] Task one
        """
        let result = OutputFormatValidator.validate(response: invalidPRD, format: .ralphWiggumPRD)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }

    func testValidateRalphWiggumPRDMissingCheckboxes() {
        let invalidPRD = """
        # PRD - Test
        ## Section One
        Some description without checkboxes
        """
        let result = OutputFormatValidator.validate(response: invalidPRD, format: .ralphWiggumPRD)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }

    func testValidateSanitizesControlCharacters() {
        let input = "Hello\u{0001}World\nNewline\tTab"
        let result = OutputFormatValidator.validate(response: input, format: .plainText)
        XCTAssertTrue(result.isValid)
        XCTAssertFalse(result.outputText.contains("\u{0001}"))
        XCTAssertTrue(result.outputText.contains("\n"))
        XCTAssertTrue(result.outputText.contains("\t"))
    }

    // MARK: - LLMConfig Tests

    func testLLMConfigInit() {
        let config = LLMConfig(baseURL: "http://localhost:1234/v1", apiKey: "test-key")
        XCTAssertEqual(config.baseURL, "http://localhost:1234/v1")
        XCTAssertEqual(config.apiKey, "test-key")
        XCTAssertNil(config.modelName)
    }

    func testLLMConfigWithModelName() {
        let config = LLMConfig(baseURL: "http://localhost:1234/v1", apiKey: "test-key", modelName: "gpt-4")
        XCTAssertEqual(config.modelName, "gpt-4")
    }

    // MARK: - LLMService Model Selection Tests

    func testSelectBestModelPrefers30B() {
        let service = LLMService()
        let models = ["llama-7b", "llama-30b", "llama-3b"]
        XCTAssertEqual(service.selectBestModel(models: models), "llama-30b")
    }

    func testSelectBestModelPrefers8BOver3B() {
        let service = LLMService()
        let models = ["llama-3b", "llama-8b"]
        XCTAssertEqual(service.selectBestModel(models: models), "llama-8b")
    }

    func testSelectBestModelFallsBackToFirst() {
        let service = LLMService()
        let models = ["custom-model", "another-model"]
        XCTAssertEqual(service.selectBestModel(models: models), "custom-model")
    }

    func testSelectBestModelEmptyListFallback() {
        let service = LLMService()
        let models: [String] = []
        XCTAssertEqual(service.selectBestModel(models: models), "gpt-3.5-turbo")
    }

    // MARK: - LLMConfig Codable Tests

    func testLLMConfigCodable() throws {
        let config = LLMConfig(baseURL: "http://localhost:1234/v1", apiKey: "test-key", modelName: "llama-8b")
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(LLMConfig.self, from: data)
        XCTAssertEqual(decoded.baseURL, config.baseURL)
        XCTAssertEqual(decoded.apiKey, config.apiKey)
        XCTAssertEqual(decoded.modelName, config.modelName)
    }

    func testOutputFormatCodable() throws {
        for format in OutputFormat.allCases {
            let data = try JSONEncoder().encode(format)
            let decoded = try JSONDecoder().decode(OutputFormat.self, from: data)
            XCTAssertEqual(decoded, format)
        }
    }
}
