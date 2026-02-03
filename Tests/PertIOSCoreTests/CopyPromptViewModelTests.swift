#if canImport(UIKit)
import XCTest
import AVFoundation
@testable import PertIOSCore
import PertCore

/// Mock clipboard for testing without side effects on UIPasteboard.general.
final class MockClipboardService: ClipboardServiceProtocol {
    var storedText: String?
    var shouldFail: Bool = false
    var copyCallCount: Int = 0

    func copyText(_ text: String) -> Bool {
        copyCallCount += 1
        if shouldFail { return false }
        storedText = text
        return true
    }

    func getText() -> String? {
        return storedText
    }
}

@MainActor
final class CopyPromptViewModelTests: XCTestCase {

    func testInitialState() {
        let vm = CopyPromptViewModel()
        XCTAssertEqual(vm.conditionedPrompt, "")
        XCTAssertFalse(vm.isConditioned)
        XCTAssertFalse(vm.showToast)
        XCTAssertEqual(vm.toastMessage, "Copied to clipboard")
        XCTAssertFalse(vm.isCopyButtonPressed)
    }

    func testSetConditionedPrompt() {
        let vm = CopyPromptViewModel()
        vm.setConditionedPrompt("Test prompt")
        XCTAssertEqual(vm.conditionedPrompt, "Test prompt")
        XCTAssertTrue(vm.isConditioned)
    }

    func testSetConditionedPromptEmpty() {
        let vm = CopyPromptViewModel()
        vm.setConditionedPrompt("")
        XCTAssertEqual(vm.conditionedPrompt, "")
        XCTAssertTrue(vm.isConditioned)
    }

    func testCopyToClipboardWithEmptyPrompt() {
        let mock = MockClipboardService()
        let vm = CopyPromptViewModel(clipboardService: mock)
        vm.copyToClipboard()
        // Should not show toast when prompt is empty
        XCTAssertFalse(vm.showToast)
        XCTAssertEqual(mock.copyCallCount, 0)
    }

    func testCopyToClipboardWithContent() {
        let mock = MockClipboardService()
        let vm = CopyPromptViewModel(clipboardService: mock)
        vm.setConditionedPrompt("Copy me")
        vm.copyToClipboard()
        XCTAssertTrue(vm.showToast)
        XCTAssertEqual(vm.toastMessage, "Copied to clipboard")
        XCTAssertEqual(mock.storedText, "Copy me")
    }

    func testCopyToClipboardFailure() {
        let mock = MockClipboardService()
        mock.shouldFail = true
        let vm = CopyPromptViewModel(clipboardService: mock)
        vm.setConditionedPrompt("Copy me")
        vm.copyToClipboard()
        XCTAssertTrue(vm.showToast)
        XCTAssertEqual(vm.toastMessage, "Failed to copy to clipboard")
        XCTAssertNil(mock.storedText)
    }

    func testOnConditioningComplete() {
        let mock = MockClipboardService()
        let vm = CopyPromptViewModel(clipboardService: mock)
        vm.onConditioningComplete(prompt: "Conditioned result")
        XCTAssertEqual(vm.conditionedPrompt, "Conditioned result")
        XCTAssertTrue(vm.isConditioned)
        XCTAssertTrue(vm.showToast)
        XCTAssertEqual(vm.toastMessage, "Prompt automatically copied to clipboard")
        XCTAssertEqual(mock.storedText, "Conditioned result")
    }

    func testOnConditioningCompleteFailure() {
        let mock = MockClipboardService()
        mock.shouldFail = true
        let vm = CopyPromptViewModel(clipboardService: mock)
        vm.onConditioningComplete(prompt: "Conditioned result")
        XCTAssertEqual(vm.conditionedPrompt, "Conditioned result")
        XCTAssertTrue(vm.isConditioned)
        XCTAssertTrue(vm.showToast)
        XCTAssertEqual(vm.toastMessage, "Failed to copy to clipboard")
    }

    func testAnimateCopyButton() {
        let vm = CopyPromptViewModel()
        vm.animateCopyButton()
        XCTAssertTrue(vm.isCopyButtonPressed)
    }

    func testCopyToClipboardUpdatesClipboard() {
        let mock = MockClipboardService()
        let vm = CopyPromptViewModel(clipboardService: mock)
        let testString = "Unique test string \(UUID().uuidString)"
        vm.setConditionedPrompt(testString)
        vm.copyToClipboard()
        XCTAssertEqual(mock.storedText, testString)
    }

    func testMultipleCopiesOverwrite() {
        let mock = MockClipboardService()
        let vm = CopyPromptViewModel(clipboardService: mock)
        vm.setConditionedPrompt("First")
        vm.copyToClipboard()
        XCTAssertEqual(mock.storedText, "First")

        vm.setConditionedPrompt("Second")
        vm.copyToClipboard()
        XCTAssertEqual(mock.storedText, "Second")
    }

    func testLargePromptCopy() {
        let mock = MockClipboardService()
        let vm = CopyPromptViewModel(clipboardService: mock)
        let largePrompt = String(repeating: "A", count: 100_000)
        vm.setConditionedPrompt(largePrompt)
        vm.copyToClipboard()
        XCTAssertEqual(mock.storedText, largePrompt)
    }

    func testCopyCallCount() {
        let mock = MockClipboardService()
        let vm = CopyPromptViewModel(clipboardService: mock)
        vm.setConditionedPrompt("Test")
        vm.copyToClipboard()
        vm.copyToClipboard()
        vm.copyToClipboard()
        XCTAssertEqual(mock.copyCallCount, 3)
    }

    // MARK: - ClipboardService integration tests

    func testRealClipboardServiceCopyAndGet() {
        let service = ClipboardService()
        let testString = "clipboard-test-\(UUID().uuidString)"
        let success = service.copyText(testString)
        XCTAssertTrue(success)
        XCTAssertEqual(service.getText(), testString)
    }

    func testRealClipboardServiceOverwrite() {
        let service = ClipboardService()
        _ = service.copyText("first")
        _ = service.copyText("second")
        XCTAssertEqual(service.getText(), "second")
    }

    // MARK: - Sound Asset Tests

    func testCopySoundAssetExists() {
        let url = Bundle.module.url(forResource: "copy", withExtension: "mp3")
        XCTAssertNotNil(url, "copy.mp3 should be bundled in PertIOSCore resources")
    }

    func testCopySoundAssetIsValidAudio() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "copy", withExtension: "mp3"))
        let data = try Data(contentsOf: url)
        XCTAssertGreaterThan(data.count, 0, "copy.mp3 should not be empty")
    }

    func testCopySoundAssetIsLoadable() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "copy", withExtension: "mp3"))
        let player = try AVAudioPlayer(contentsOf: url)
        XCTAssertGreaterThan(player.duration, 0, "copy.mp3 should have a positive duration")
    }
}
#else
import XCTest

// Stub tests for non-iOS platforms so the test target compiles
final class CopyPromptViewModelStubTests: XCTestCase {
    func testPlatformNotSupported() {
        // PertIOSCore requires UIKit (iOS). These tests run on iOS simulator only.
        // This stub ensures the test target compiles on macOS.
    }
}
#endif
