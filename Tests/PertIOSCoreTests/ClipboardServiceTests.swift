#if canImport(UIKit)
import XCTest
import UIKit
@testable import PertIOSCore

@MainActor
final class ClipboardServiceTests: XCTestCase {

    func testCopyTextSetsClipboard() {
        let service = ClipboardService()
        let text = "test-clipboard-\(UUID().uuidString)"
        let result = service.copyText(text)
        XCTAssertTrue(result)
        XCTAssertEqual(UIPasteboard.general.string, text)
    }

    func testGetTextReturnsClipboardContent() {
        let service = ClipboardService()
        let text = "get-test-\(UUID().uuidString)"
        UIPasteboard.general.string = text
        XCTAssertEqual(service.getText(), text)
    }

    func testCopyEmptyString() {
        let service = ClipboardService()
        let result = service.copyText("")
        XCTAssertTrue(result)
        XCTAssertEqual(service.getText(), "")
    }

    func testCopySpecialCharacters() {
        let service = ClipboardService()
        let specialText = "Hello 🌍 \n\t \"quotes\" <html> & symbols $#@!"
        let result = service.copyText(specialText)
        XCTAssertTrue(result)
        XCTAssertEqual(service.getText(), specialText)
    }

    func testCopyUnicodeText() {
        let service = ClipboardService()
        let unicodeText = "日本語テキスト العربية 中文 한국어"
        let result = service.copyText(unicodeText)
        XCTAssertTrue(result)
        XCTAssertEqual(service.getText(), unicodeText)
    }

    func testCopyLargeText() {
        let service = ClipboardService()
        let largeText = String(repeating: "X", count: 100_000)
        let result = service.copyText(largeText)
        XCTAssertTrue(result)
        XCTAssertEqual(service.getText(), largeText)
    }

    func testCopyOverwritesPreviousContent() {
        let service = ClipboardService()
        _ = service.copyText("first")
        _ = service.copyText("second")
        XCTAssertEqual(service.getText(), "second")
    }

    func testMultilineText() {
        let service = ClipboardService()
        let multiline = """
        Line 1
        Line 2
        Line 3
        """
        let result = service.copyText(multiline)
        XCTAssertTrue(result)
        XCTAssertEqual(service.getText(), multiline)
    }
}
#else
import XCTest

final class ClipboardServiceStubTests: XCTestCase {
    func testPlatformNotSupported() {
        // ClipboardService requires UIKit (iOS). This stub ensures compilation on macOS.
    }
}
#endif
