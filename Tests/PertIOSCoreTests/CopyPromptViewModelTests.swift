#if canImport(UIKit)
import XCTest
import AVFoundation
@testable import PertIOSCore
import PertCore

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
        let vm = CopyPromptViewModel()
        vm.copyToClipboard()
        // Should not show toast when prompt is empty
        XCTAssertFalse(vm.showToast)
    }

    func testCopyToClipboardWithContent() {
        let vm = CopyPromptViewModel()
        vm.setConditionedPrompt("Copy me")
        vm.copyToClipboard()
        XCTAssertTrue(vm.showToast)
        XCTAssertEqual(vm.toastMessage, "Copied to clipboard")
        // Verify clipboard content
        XCTAssertEqual(UIPasteboard.general.string, "Copy me")
    }

    func testOnConditioningComplete() {
        let vm = CopyPromptViewModel()
        vm.onConditioningComplete(prompt: "Conditioned result")
        XCTAssertEqual(vm.conditionedPrompt, "Conditioned result")
        XCTAssertTrue(vm.isConditioned)
        XCTAssertTrue(vm.showToast)
        XCTAssertEqual(vm.toastMessage, "Prompt automatically copied to clipboard")
        XCTAssertEqual(UIPasteboard.general.string, "Conditioned result")
    }

    func testAnimateCopyButton() {
        let vm = CopyPromptViewModel()
        vm.animateCopyButton()
        XCTAssertTrue(vm.isCopyButtonPressed)
    }

    func testCopyToClipboardUpdatesClipboard() {
        let vm = CopyPromptViewModel()
        let testString = "Unique test string \(UUID().uuidString)"
        vm.setConditionedPrompt(testString)
        vm.copyToClipboard()
        XCTAssertEqual(UIPasteboard.general.string, testString)
    }

    func testMultipleCopiesOverwrite() {
        let vm = CopyPromptViewModel()
        vm.setConditionedPrompt("First")
        vm.copyToClipboard()
        XCTAssertEqual(UIPasteboard.general.string, "First")

        vm.setConditionedPrompt("Second")
        vm.copyToClipboard()
        XCTAssertEqual(UIPasteboard.general.string, "Second")
    }

    func testLargePromptCopy() {
        let vm = CopyPromptViewModel()
        let largePrompt = String(repeating: "A", count: 100_000)
        vm.setConditionedPrompt(largePrompt)
        vm.copyToClipboard()
        XCTAssertEqual(UIPasteboard.general.string, largePrompt)
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
